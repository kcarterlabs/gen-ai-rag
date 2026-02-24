"""
Security utilities for RAG system
- Multi-tenant isolation
- Input sanitization
- Output filtering
- Audit logging
"""

import hashlib
import hmac
import re
import json
from typing import Dict, Optional
from datetime import datetime
from decimal import Decimal


def sanitize_tenant_id(tenant_id: str) -> str:
    """
    Sanitize tenant ID to prevent path traversal
    
    Args:
        tenant_id: Raw tenant identifier
        
    Returns:
        Sanitized tenant ID
        
    Raises:
        ValueError: If tenant_id is invalid
    """
    # Only allow alphanumeric, hyphens, underscores
    if not re.match(r'^[a-zA-Z0-9_-]+$', tenant_id):
        raise ValueError(
            f"Invalid tenant_id: must contain only alphanumeric, hyphens, and underscores"
        )
    
    # Prevent path traversal
    if '..' in tenant_id or '/' in tenant_id:
        raise ValueError("Invalid tenant_id: path traversal detected")
    
    # Limit length
    if len(tenant_id) > 64:
        raise ValueError("Invalid tenant_id: exceeds maximum length of 64")
    
    return tenant_id


def sanitize_document_id(doc_id: str) -> str:
    """
    Sanitize document ID for safe S3 key usage
    
    Args:
        doc_id: Raw document identifier
        
    Returns:
        Sanitized document ID
    """
    # Remove or replace unsafe characters
    safe_doc_id = re.sub(r'[^a-zA-Z0-9_.-]', '_', doc_id)
    
    # Prevent path traversal
    safe_doc_id = safe_doc_id.replace('..', '_')
    
    # Limit length
    if len(safe_doc_id) > 255:
        safe_doc_id = safe_doc_id[:255]
    
    return safe_doc_id


def validate_s3_path(tenant_id: str, doc_id: str) -> str:
    """
    Construct and validate S3 path with tenant isolation
    
    Args:
        tenant_id: Tenant identifier
        doc_id: Document identifier
        
    Returns:
        Safe S3 key path
    """
    safe_tenant = sanitize_tenant_id(tenant_id)
    safe_doc = sanitize_document_id(doc_id)
    
    return f"{safe_tenant}/{safe_doc}"


def sanitize_output(text: str, max_length: int = 50000) -> str:
    """
    Sanitize LLM output before returning to user
    
    Args:
        text: Raw LLM output
        max_length: Maximum allowed length
        
    Returns:
        Sanitized output
    """
    # Remove any potential script tags or HTML
    sanitized = re.sub(r'<script[^>]*>.*?</script>', '', text, flags=re.IGNORECASE | re.DOTALL)
    sanitized = re.sub(r'<iframe[^>]*>.*?</iframe>', '', sanitized, flags=re.IGNORECASE | re.DOTALL)
    
    # Limit output length
    if len(sanitized) > max_length:
        sanitized = sanitized[:max_length] + "...[truncated]"
    
    return sanitized.strip()


def create_audit_log_entry(
    tenant_id: str,
    user_id: str,
    action: str,
    query: str = None,
    cost: float = 0.0,
    tokens_used: int = 0,
    metadata: Dict = None
) -> Dict:
    """
    Create structured audit log entry
    
    Args:
        tenant_id: Tenant identifier
        user_id: User identifier
        action: Action type (e.g., "chat", "ingest")
        query: User query (optional)
        cost: Estimated cost
        tokens_used: Token count
        metadata: Additional metadata
        
    Returns:
        Structured audit log entry
    """
    timestamp = datetime.utcnow().isoformat()
    
    log_entry = {
        "timestamp": timestamp,
        "tenant_id": tenant_id,
        "user_id": user_id,
        "action": action,
        "tokens_used": tokens_used,
        "estimated_cost": cost,
        "metadata": metadata or {}
    }
    
    # Only log query hash, not full query (privacy)
    if query:
        query_hash = hashlib.sha256(query.encode()).hexdigest()[:16]
        log_entry["query_hash"] = query_hash
        log_entry["query_length"] = len(query)
    
    return log_entry


def verify_request_signature(
    payload: str,
    signature: str,
    secret_key: str
) -> bool:
    """
    Verify HMAC signature for webhook/API requests
    
    Args:
        payload: Request payload
        signature: Provided signature
        secret_key: Shared secret key
        
    Returns:
        True if signature is valid
    """
    expected_signature = hmac.new(
        secret_key.encode(),
        payload.encode(),
        hashlib.sha256
    ).hexdigest()
    
    return hmac.compare_digest(signature, expected_signature)


def enforce_rate_limit(
    tenant_id: str,
    action: str,
    limit_per_minute: int = 60,
    cache: Dict = None
) -> bool:
    """
    Simple in-memory rate limiting (production should use Redis/DynamoDB)
    
    Args:
        tenant_id: Tenant identifier
        action: Action being rate limited
        limit_per_minute: Maximum requests per minute
        cache: Optional cache dictionary (for testing)
        
    Returns:
        True if request is allowed, False if rate limit exceeded
    """
    # This is a simplified example - production should use persistent storage
    if cache is None:
        # In real implementation, use Redis or DynamoDB
        return True
    
    key = f"ratelimit:{tenant_id}:{action}"
    current_time = datetime.utcnow()
    
    if key not in cache:
        cache[key] = []
    
    # Remove entries older than 1 minute
    cache[key] = [
        ts for ts in cache[key]
        if (current_time - ts).total_seconds() < 60
    ]
    
    # Check limit
    if len(cache[key]) >= limit_per_minute:
        return False
    
    # Add new request
    cache[key].append(current_time)
    return True


class SecurityContext:
    """Security context for request processing"""
    
    def __init__(
        self,
        tenant_id: str,
        user_id: str = "anonymous",
        request_id: str = None
    ):
        self.tenant_id = sanitize_tenant_id(tenant_id)
        self.user_id = user_id
        self.request_id = request_id or self._generate_request_id()
        self.audit_trail = []
    
    def _generate_request_id(self) -> str:
        """Generate unique request ID"""
        timestamp = datetime.utcnow().isoformat()
        content = f"{self.tenant_id}:{self.user_id}:{timestamp}"
        return hashlib.sha256(content.encode()).hexdigest()[:16]
    
    def log_action(
        self,
        action: str,
        metadata: Dict = None
    ):
        """Log action to audit trail"""
        entry = {
            "timestamp": datetime.utcnow().isoformat(),
            "action": action,
            "metadata": metadata or {}
        }
        self.audit_trail.append(entry)
    
    def get_s3_prefix(self) -> str:
        """Get tenant-isolated S3 prefix"""
        return f"{self.tenant_id}/"
    
    def get_audit_trail(self) -> list:
        """Get audit trail for this request"""
        return self.audit_trail
    
    def to_dict(self) -> Dict:
        """Convert to dictionary for logging"""
        return {
            "tenant_id": self.tenant_id,
            "user_id": self.user_id,
            "request_id": self.request_id,
            "audit_trail_length": len(self.audit_trail)
        }
