import json
import os
import time

import boto3
import psycopg2
from botocore.exceptions import BotoCoreError, ClientError
from flask import Flask, jsonify, request

app = Flask(__name__)
ENVIRONMENT = os.getenv("ENVIRONMENT", "unknown")
AWS_REGION = os.getenv("AWS_REGION", "unknown")
QUEUE_URL = os.getenv("QUEUE_URL")

sqs = boto3.client("sqs", region_name=AWS_REGION)


def get_connection():
    return psycopg2.connect(
        host=os.getenv("DB_HOST"),
        port=os.getenv("DB_PORT", "5432"),
        database=os.getenv("DB_NAME", "shopdb"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        connect_timeout=5,
    )


def init_db_with_retry(max_attempts=30):
    for attempt in range(1, max_attempts + 1):
        try:
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute(
                        """
                        CREATE TABLE IF NOT EXISTS orders (
                            id SERIAL PRIMARY KEY,
                            product VARCHAR(150) NOT NULL,
                            quantity INTEGER NOT NULL CHECK (quantity > 0),
                            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
                        )
                        """
                    )
            return
        except Exception as exc:
            print(f"Database not ready ({attempt}/{max_attempts}): {exc}", flush=True)
            time.sleep(10)
    raise RuntimeError("Database did not become ready")


@app.get("/health")
def health():
    try:
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT 1")
                cur.fetchone()
        return jsonify(status="healthy", service="order", environment=ENVIRONMENT, region=AWS_REGION), 200
    except Exception as exc:
        return jsonify(status="unhealthy", service="order", environment=ENVIRONMENT, region=AWS_REGION, error=str(exc)), 503


@app.get("/orders")
def get_orders():
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT id, product, quantity, created_at FROM orders ORDER BY id")
            rows = cur.fetchall()
    return jsonify([
        {"id": r[0], "product": r[1], "quantity": r[2], "created_at": r[3].isoformat()}
        for r in rows
    ])


@app.post("/orders")
def create_order():
    data = request.get_json(silent=True) or {}
    if not data.get("product") or not isinstance(data.get("quantity"), int) or data["quantity"] <= 0:
        return jsonify(error="product and a positive integer quantity are required"), 400

    try:
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "INSERT INTO orders (product, quantity) VALUES (%s, %s) RETURNING id, created_at",
                    (data["product"], data["quantity"]),
                )
                order_id, created_at = cur.fetchone()
    except psycopg2.errors.ReadOnlySqlTransaction:
        return jsonify(error="standby database is still read-only; promote the replica during the DR drill"), 503

    order = {
        "id": order_id,
        "product": data["product"],
        "quantity": data["quantity"],
        "created_at": created_at.isoformat(),
        "environment": ENVIRONMENT,
        "region": AWS_REGION,
    }

    if QUEUE_URL:
        try:
            sqs.send_message(QueueUrl=QUEUE_URL, MessageBody=json.dumps(order))
        except (BotoCoreError, ClientError) as exc:
            app.logger.exception("Order persisted but SQS publication failed: %s", exc)
            return jsonify(order=order, warning="order saved but notification event failed"), 202

    return jsonify(order), 201


if __name__ == "__main__":
    if ENVIRONMENT != "standby":
        init_db_with_retry()
    app.run(host="0.0.0.0", port=8081)
