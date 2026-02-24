import json
import boto3
import logging
from chunking import chunk_text
from bedrock_client import generate_embedding
from vector_store import store_vector
from security import SecurityContext, sanitize_document_id, create_audit_log_entry
from guardrails import mask_pii

s3 = boto3.client("s3")

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    """
    Enhanced ingest handler with security and audit logging
    """
    request_id = context.request_id if hasattr(context, 'request_id') else 'local'
    
    try:
        record = event["Records"][0]
        bucket = record["s3"]["bucket"]["name"]
        key = record["s3"]["object"]["key"]
        
        logger.info(f"Processing document: s3://{bucket}/{key}")
        
        # Extract tenant_id from S3 path (assumes format: tenant_id/doc_id)
        path_parts = key.split('/')
        if len(path_parts) < 2:
            logger.error(f"Invalid S3 key format: {key}")
            return {"status": "error", "message": "Invalid S3 key format"}
        
        tenant_id = path_parts[0]
        doc_id = '/'.join(path_parts[1:])
        
        # Initialize security context
        sec_context = SecurityContext(tenant_id, "system", request_id)
        sec_context.log_action("ingest_start", {"document": doc_id})
        
        # Sanitize document ID
        safe_doc_id = sanitize_document_id(doc_id)
        
        # Get document from S3
        response = s3.get_object(Bucket=bucket, Key=key)
        text = response["Body"].read().decode("utf-8")
        
        # Mask any PII in the document before processing
        masked_text = mask_pii(text)
        
        # Chunk the text
        sec_context.log_action("chunking_start")
        chunks = chunk_text(masked_text)
        sec_context.log_action("chunking_complete", {"num_chunks": len(chunks)})
        
        logger.info(f"Created {len(chunks)} chunks from document")
        
        # Process each chunk
        successful_chunks = 0
        for idx, chunk in enumerate(chunks):
            try:
                # Generate embedding
                embedding = generate_embedding(chunk["text"])
                
                # Store vector with tenant isolation
                store_vector(
                    doc_id=safe_doc_id,
                    chunk_id=idx,
                    vector=embedding,
                    metadata={
                        "source": safe_doc_id,
                        "tenant_id": tenant_id,
                        "chunk_index": idx,
                        "token_estimate": chunk.get("token_estimate", 0)
                    }
                )
                
                successful_chunks += 1
            
            except Exception as e:
                logger.error(f"Error processing chunk {idx}: {str(e)}")
                continue
        
        sec_context.log_action("ingest_complete", {
            "total_chunks": len(chunks),
            "successful_chunks": successful_chunks
        })
        
        # Create audit log
        audit_entry = create_audit_log_entry(
            tenant_id=tenant_id,
            user_id="system",
            action="ingest",
            metadata={
                "document": safe_doc_id,
                "total_chunks": len(chunks),
                "successful_chunks": successful_chunks,
                "request_id": request_id,
                "security_context": sec_context.to_dict()
            }
        )
        
        logger.info(f"Audit log: {json.dumps(audit_entry)}")
        
        return {
            "status": "ingestion complete",
            "document": safe_doc_id,
            "chunks": len(chunks),
            "successful_chunks": successful_chunks,
            "request_id": request_id
        }
    
    except Exception as e:
        logger.error(f"Error during ingestion: {str(e)}", exc_info=True)
        return {
            "status": "error",
            "message": str(e),
            "request_id": request_id
        }
