import os
import time

import psycopg2
from flask import Flask, jsonify, request

app = Flask(__name__)
ENVIRONMENT = os.getenv("ENVIRONMENT", "unknown")
AWS_REGION = os.getenv("AWS_REGION", "unknown")


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
                        CREATE TABLE IF NOT EXISTS products (
                            id SERIAL PRIMARY KEY,
                            name VARCHAR(100) NOT NULL,
                            price NUMERIC(10, 2) NOT NULL
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
        return jsonify(status="healthy", service="catalog", environment=ENVIRONMENT, region=AWS_REGION), 200
    except Exception as exc:
        return jsonify(status="unhealthy", service="catalog", environment=ENVIRONMENT, region=AWS_REGION, error=str(exc)), 503


@app.get("/products")
def get_products():
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT id, name, price FROM products ORDER BY id")
            rows = cur.fetchall()
    return jsonify([{"id": r[0], "name": r[1], "price": float(r[2])} for r in rows])


@app.post("/products")
def create_product():
    data = request.get_json(silent=True) or {}
    if "name" not in data or "price" not in data:
        return jsonify(error="name and price are required"), 400

    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO products (name, price) VALUES (%s, %s) RETURNING id",
                (data["name"], data["price"]),
            )
            product_id = cur.fetchone()[0]

    return jsonify(id=product_id, name=data["name"], price=data["price"]), 201


if __name__ == "__main__":
    if ENVIRONMENT != "standby":
        init_db_with_retry()
    app.run(host="0.0.0.0", port=8080)
