import json
import logging
from bedrock_client import generate_embedding, generate_chat_completion
from vector_store import retrieve_similar
from prompt_templates import build_prompt
from guardrails import apply_guardrails, GuardrailViolation
from security import SecurityContext, sanitize_output, create_audit_log_entry
from evaluation import calculate_answer_relevance

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    """
    Enhanced chat handler with security, guardrails, and evaluation
    """
    request_id = context.request_id if hasattr(context, 'request_id') else 'local'
    
    try:
        # Parse request
        body = json.loads(event.get("body", "{}"))
        question = body.get("question", "")
        tenant_id = body.get("tenant_id", "default")
        user_id = body.get("user_id", "anonymous")
        
        if not question:
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "No question provided"})
            }
        
        # Initialize security context
        sec_context = SecurityContext(tenant_id, user_id, request_id)
        sec_context.log_action("chat_request_received", {"question_length": len(question)})
        
        # Apply guardrails
        try:
            guardrail_result = apply_guardrails(
                question,
                check_injection=True,
                check_pii=True,
                max_input_length=5000,
                max_tokens=4000
            )
            
            # Use masked input if PII detected
            safe_question = guardrail_result["masked_input"]
            
            # Log warnings
            if guardrail_result["warnings"]:
                logger.warning(f"Guardrail warnings: {guardrail_result['warnings']}")
                sec_context.log_action("guardrail_warning", {
                    "warnings": guardrail_result["warnings"]
                })
        
        except GuardrailViolation as e:
            logger.error(f"Guardrail violation: {str(e)}")
            sec_context.log_action("guardrail_violation", {"reason": str(e)})
            return {
                "statusCode": 400,
                "body": json.dumps({
                    "error": "Request blocked by security guardrails",
                    "reason": str(e)
                })
            }
        
        # Step 1: Embed query
        sec_context.log_action("embedding_generation_start")
        query_embedding = generate_embedding(safe_question)
        sec_context.log_action("embedding_generation_complete")
        
        # Step 2: Retrieve top-k similar chunks (with tenant isolation)
        sec_context.log_action("retrieval_start")
        context_chunks = retrieve_similar(
            query_embedding, 
            top_k=5,
            tenant_id=tenant_id  # Enforce tenant isolation
        )
        sec_context.log_action("retrieval_complete", {
            "chunks_retrieved": len(context_chunks)
        })
        
        # Step 3: Build prompt
        prompt = build_prompt(context_chunks, safe_question)
        
        # Step 4: Generate chat response
        sec_context.log_action("llm_generation_start")
        answer = generate_chat_completion(prompt)
        sec_context.log_action("llm_generation_complete")
        
        # Step 5: Sanitize output
        safe_answer = sanitize_output(answer)
        
        # Step 6: Calculate evaluation metrics
        relevance_metrics = calculate_answer_relevance(
            question=safe_question,
            answer=safe_answer,
            context_chunks=[c.get("text", "") for c in context_chunks]
        )
        
        # Create audit log
        audit_entry = create_audit_log_entry(
            tenant_id=tenant_id,
            user_id=user_id,
            action="chat",
            query=safe_question,
            metadata={
                "request_id": request_id,
                "chunks_used": len(context_chunks),
                "relevance_metrics": relevance_metrics,
                "security_context": sec_context.to_dict()
            }
        )
        
        logger.info(f"Audit log: {json.dumps(audit_entry)}")
        
        # Return response
        response_body = {
            "answer": safe_answer,
            "metadata": {
                "chunks_used": len(context_chunks),
                "request_id": request_id,
                "relevance_metrics": relevance_metrics
            }
        }
        
        # Include warnings if any
        if guardrail_result.get("warnings"):
            response_body["warnings"] = guardrail_result["warnings"]
        
        return {
            "statusCode": 200,
            "body": json.dumps(response_body),
            "headers": {
                "Content-Type": "application/json",
                "X-Request-ID": request_id
            }
        }
    
    except Exception as e:
        logger.error(f"Error processing request: {str(e)}", exc_info=True)
        return {
            "statusCode": 500,
            "body": json.dumps({
                "error": "Internal server error",
                "request_id": request_id
            })
        }
