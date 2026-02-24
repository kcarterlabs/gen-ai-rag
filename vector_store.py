import boto3
import json
import os
import numpy as np
from typing import List, Dict, Optional

s3 = boto3.client("s3")
VECTOR_BUCKET = os.environ.get("VECTOR_BUCKET")


def store_vector(doc_id: str, chunk_id: int, vector: list, metadata: dict):
    """
    Store vector embedding with metadata
    
    Args:
        doc_id: Document identifier
        chunk_id: Chunk index
        vector: Embedding vector
        metadata: Additional metadata (must include tenant_id)
    """
    tenant_id = metadata.get("tenant_id", "default")
    
    # Use tenant-isolated path
    key = f"{tenant_id}/vectors/{doc_id}/{chunk_id}.json"
    
    payload = {
        "vector": vector,
        "metadata": metadata,
        "chunk_id": chunk_id,
        "doc_id": doc_id
    }
    
    s3.put_object(
        Bucket=VECTOR_BUCKET, 
        Key=key, 
        Body=json.dumps(payload),
        ContentType="application/json"
    )


def cosine_similarity(vec1: list, vec2: list) -> float:
    """
    Calculate cosine similarity between two vectors
    
    Args:
        vec1: First vector
        vec2: Second vector
        
    Returns:
        Cosine similarity score (0-1)
    """
    v1 = np.array(vec1)
    v2 = np.array(vec2)
    
    dot_product = np.dot(v1, v2)
    norm_v1 = np.linalg.norm(v1)
    norm_v2 = np.linalg.norm(v2)
    
    if norm_v1 == 0 or norm_v2 == 0:
        return 0.0
    
    return float(dot_product / (norm_v1 * norm_v2))


def retrieve_similar(
    query_vector: list, 
    top_k: int = 5,
    tenant_id: str = "default",
    min_similarity: float = 0.5
) -> List[Dict]:
    """
    Retrieve similar vectors using cosine similarity
    
    Args:
        query_vector: Query embedding vector
        top_k: Number of top results to return
        tenant_id: Tenant ID for isolation
        min_similarity: Minimum similarity threshold
        
    Returns:
        List of similar chunks with metadata
    """
    # List all vector files for this tenant
    prefix = f"{tenant_id}/vectors/"
    
    try:
        paginator = s3.get_paginator('list_objects_v2')
        pages = paginator.paginate(Bucket=VECTOR_BUCKET, Prefix=prefix)
        
        similarities = []
        
        for page in pages:
            if 'Contents' not in page:
                continue
            
            for obj in page['Contents']:
                if not obj['Key'].endswith('.json'):
                    continue
                
                # Get vector file
                try:
                    response = s3.get_object(Bucket=VECTOR_BUCKET, Key=obj['Key'])
                    data = json.loads(response['Body'].read().decode('utf-8'))
                    
                    # Calculate similarity
                    vector = data.get('vector', [])
                    if not vector:
                        continue
                    
                    similarity = cosine_similarity(query_vector, vector)
                    
                    if similarity >= min_similarity:
                        similarities.append({
                            'similarity': similarity,
                            'text': data.get('metadata', {}).get('text', ''),
                            'metadata': data.get('metadata', {}),
                            'chunk_id': data.get('chunk_id'),
                            'doc_id': data.get('doc_id')
                        })
                
                except Exception as e:
                    # Skip files that can't be processed
                    continue
        
        # Sort by similarity (descending) and return top k
        similarities.sort(key=lambda x: x['similarity'], reverse=True)
        
        return similarities[:top_k]
    
    except Exception as e:
        # If retrieval fails, return empty list
        # In production, should log this error
        return []
