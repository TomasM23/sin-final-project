import json
import os
import time

import boto3

QUEUE_URL = os.getenv("QUEUE_URL")

sqs = boto3.client(
    "sqs",
    region_name=os.getenv("AWS_REGION", "eu-west-1")
)

print("Notification service started", flush=True)

while True:
    response = sqs.receive_message(
        QueueUrl=QUEUE_URL,
        MaxNumberOfMessages=1,
        WaitTimeSeconds=10
    )

    messages = response.get("Messages", [])

    for message in messages:
        order = json.loads(message["Body"])

        print(f"Order received: {order}", flush=True)
        print(
            f"Notification sent for order {order['id']}",
            flush=True
        )

        sqs.delete_message(
            QueueUrl=QUEUE_URL,
            ReceiptHandle=message["ReceiptHandle"]
        )

    time.sleep(1)
