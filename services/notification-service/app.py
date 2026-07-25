import json
import os
import time

import boto3
from botocore.exceptions import BotoCoreError, ClientError

QUEUE_URL = os.getenv("QUEUE_URL")
AWS_REGION = os.getenv("AWS_REGION", "eu-west-1")
ENVIRONMENT = os.getenv("ENVIRONMENT", "unknown")

sqs = boto3.client("sqs", region_name=AWS_REGION)
print(f"Notification service started in {ENVIRONMENT}/{AWS_REGION}", flush=True)

while True:
    try:
        response = sqs.receive_message(
            QueueUrl=QUEUE_URL,
            MaxNumberOfMessages=10,
            WaitTimeSeconds=20,
            VisibilityTimeout=60,
        )
        for message in response.get("Messages", []):
            order = json.loads(message["Body"])
            print(f"Order received: {order}", flush=True)
            print(f"Notification sent for order {order['id']}", flush=True)
            sqs.delete_message(QueueUrl=QUEUE_URL, ReceiptHandle=message["ReceiptHandle"])
    except (BotoCoreError, ClientError, ValueError, KeyError) as exc:
        print(f"Notification worker error: {exc}", flush=True)
        time.sleep(5)
