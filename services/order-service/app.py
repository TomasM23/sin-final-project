import json
import os

import boto3
from flask import Flask, jsonify, request

app = Flask(__name__)

orders = []

QUEUE_URL = os.getenv("QUEUE_URL")

sqs = boto3.client(
    "sqs",
    region_name=os.getenv("AWS_REGION", "eu-west-1"),
)


@app.get("/health")
def health():
    return jsonify({"status": "ok"})


@app.get("/orders")
def get_orders():
    return jsonify(orders)


@app.post("/orders")
def create_order():
    data = request.get_json()

    order = {
        "id": len(orders) + 1,
        "product": data["product"],
        "quantity": data["quantity"],
    }

    orders.append(order)

    if QUEUE_URL:
        sqs.send_message(
            QueueUrl=QUEUE_URL,
            MessageBody=json.dumps(order),
        )

    return jsonify(order), 201


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8081)