import boto3
import json
import os
from decimal import Decimal
from datetime import datetime

# Bedrock runtime client
bedrock_runtime = boto3.client(
    "bedrock-runtime",
    region_name=os.environ.get("AWS_REGION")
)

# CloudWatch client for custom metrics
cloudwatch = boto3.client("cloudwatch", region_name=os.environ.get("AWS_REGION"))

EMBED_MODEL_ID = "amazon.titan-embed-text-v1"
CHAT_MODEL_ID = "anthropic.claude-v2"
PROJECT_NAME = os.environ.get("PROJECT_NAME", "rag-genai")

# Approximate cost per 1,000 tokens (update with real AWS pricing)
MODEL_PRICING = {
    EMBED_MODEL_ID: 0.0001,
    CHAT_MODEL_ID: 0.002
}

# DynamoDB table to log costs
dynamodb = boto3.resource("dynamodb")
COST_TABLE = os.environ.get("COST_TABLE")
table = dynamodb.Table(COST_TABLE)


def _log_cost(model_id: str, tokens_used: int):
    cost_per_1000 = MODEL_PRICING.get(model_id, 0)
    cost = (tokens_used / 1000) * cost_per_1000

    timestamp = int(datetime.utcnow().timestamp())

    # Save to DynamoDB
    table.put_item(
        Item={
            "model_id": model_id,
            "timestamp": Decimal(str(timestamp)),
            "tokens_used": Decimal(str(tokens_used)),
            "estimated_cost": Decimal(str(cost))
        }
    )
    
    # Publish custom CloudWatch metric for token usage alarm
    try:
        cloudwatch.put_metric_data(
            Namespace=PROJECT_NAME,
            MetricData=[
                {
                    'MetricName': 'TokensUsed',
                    'Dimensions': [
                        {
                            'Name': 'ModelId',
                            'Value': model_id
                        }
                    ],
                    'Value': tokens_used,
                    'Unit': 'Count',
                    'Timestamp': datetime.utcnow()
                },
                {
                    'MetricName': 'EstimatedCost',
                    'Dimensions': [
                        {
                            'Name': 'ModelId',
                            'Value': model_id
                        }
                    ],
                    'Value': cost,
                    'Unit': 'None',
                    'Timestamp': datetime.utcnow()
                }
            ]
        )
    except Exception as e:
        # Don't fail the request if metric logging fails
        print(f"Failed to publish CloudWatch metric: {e}")
    
    return cost


def generate_embedding(text: str) -> list:
    response = bedrock_runtime.invoke_model(
        modelId=EMBED_MODEL_ID,
        body=json.dumps({"inputText": text}),
        contentType="application/json"
    )

    body = json.loads(response["body"].read())
    embedding = body.get("embedding", [])
    
    # Approximate token count fallback if not returned
    tokens_used = body.get("tokenCount", max(1, len(text.split())))
    _log_cost(EMBED_MODEL_ID, tokens_used)

    return embedding


def generate_chat_completion(prompt: str) -> str:
    response = bedrock_runtime.invoke_model(
        modelId=CHAT_MODEL_ID,
        body=json.dumps({
            "prompt": prompt,
            "max_tokens_to_sample": 500,
            "temperature": 0.3
        }),
        contentType="application/json"
    )

    body = json.loads(response["body"].read())
    answer = body.get("completion", "")

    tokens_used = body.get("tokenCount", max(1, len(prompt.split()) + 500))
    _log_cost(CHAT_MODEL_ID, tokens_used)

    return answer
