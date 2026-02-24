"""
Local testing script for RAG functions
Run: python test_local.py
"""

import os
import json

# Set required environment variables
os.environ["AWS_REGION"] = "us-east-1"
os.environ["VECTOR_BUCKET"] = "test-vector-bucket"
os.environ["COST_TABLE"] = "test-cost-table"

# Mock AWS credentials (for local testing - won't actually call AWS)
os.environ["AWS_ACCESS_KEY_ID"] = "test"
os.environ["AWS_SECRET_ACCESS_KEY"] = "test"

def test_chat_handler():
    """Test the chat handler locally"""
    from chat_handler import lambda_handler
    
    event = {
        "body": json.dumps({
            "question": "What is machine learning?"
        })
    }
    context = {}
    
    try:
        response = lambda_handler(event, context)
        print("✓ Chat handler response:")
        print(json.dumps(response, indent=2))
    except Exception as e:
        print(f"✗ Chat handler error: {e}")

def test_ingest_handler():
    """Test the ingest handler locally"""
    from ingest_handler import lambda_handler
    
    event = {
        "Records": [{
            "s3": {
                "bucket": {"name": "test-bucket"},
                "object": {"key": "test-doc.txt"}
            }
        }]
    }
    context = {}
    
    try:
        response = lambda_handler(event, context)
        print("✓ Ingest handler response:")
        print(json.dumps(response, indent=2))
    except Exception as e:
        print(f"✗ Ingest handler error: {e}")

def test_chunking():
    """Test the chunking function"""
    from chunking import chunk_text
    
    sample_text = """
    Machine learning is a subset of artificial intelligence.
    It focuses on building systems that learn from data.
    Deep learning is a specialized form of machine learning.
    """
    
    chunks = chunk_text(sample_text)
    print(f"✓ Chunking produced {len(chunks)} chunks:")
    for i, chunk in enumerate(chunks):
        print(f"  Chunk {i}: {chunk[:50]}...")

if __name__ == "__main__":
    print("=== Testing RAG Components ===\n")
    
    print("1. Testing Chunking...")
    test_chunking()
    
    print("\n2. Testing Ingest Handler...")
    print("   (Will fail without real AWS credentials)")
    test_ingest_handler()
    
    print("\n3. Testing Chat Handler...")
    print("   (Will fail without real AWS credentials)")
    test_chat_handler()
