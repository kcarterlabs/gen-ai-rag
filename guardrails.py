"""
Guardrails for RAG system
- Input validation
- Prompt injection detection
- Content filtering
- Token limits
- Cost budgeting
"""

import re
from typing import Dict, Tuple, Optional


class GuardrailViolation(Exception):
    """Raised when a guardrail check fails"""
    pass


# Prompt injection patterns (common attack vectors)
INJECTION_PATTERNS = [
    r"ignore\s+(previous|above|prior)\s+instructions",
    r"disregard\s+(previous|above|prior)",
    r"forget\s+(everything|all|previous)",
    r"new\s+instructions:",
    r"system\s*:\s*",
    r"<\s*script\s*>",
    r"<\s*\/\s*script\s*>",
    r"javascript:",
    r"eval\s*\(",
    r"exec\s*\(",
]

# Sensitive data patterns
PII_PATTERNS = {
    "email": r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b",
    "ssn": r"\b\d{3}-\d{2}-\d{4}\b",
    "credit_card": r"\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b",
    "phone": r"\b\d{3}[-.]?\d{3}[-.]?\d{4}\b",
}


def check_input_length(text: str, max_length: int = 10000) -> None:
    """
    Validate input length
    
    Args:
        text: Input text
        max_length: Maximum allowed length
        
    Raises:
        GuardrailViolation: If text exceeds max_length
    """
    if len(text) > max_length:
        raise GuardrailViolation(
            f"Input exceeds maximum length of {max_length} characters"
        )


def check_prompt_injection(text: str) -> Tuple[bool, Optional[str]]:
    """
    Detect potential prompt injection attempts
    
    Args:
        text: User input to check
        
    Returns:
        Tuple of (is_safe, violation_reason)
    """
    text_lower = text.lower()
    
    for pattern in INJECTION_PATTERNS:
        if re.search(pattern, text_lower, re.IGNORECASE):
            return False, f"Potential injection detected: {pattern}"
    
    return True, None


def detect_pii(text: str) -> Dict[str, list]:
    """
    Detect personally identifiable information
    
    Args:
        text: Text to scan
        
    Returns:
        Dictionary mapping PII type to list of matches
    """
    findings = {}
    
    for pii_type, pattern in PII_PATTERNS.items():
        matches = re.findall(pattern, text)
        if matches:
            findings[pii_type] = matches
    
    return findings


def mask_pii(text: str) -> str:
    """
    Mask PII in text
    
    Args:
        text: Text containing potential PII
        
    Returns:
        Text with PII masked
    """
    masked = text
    
    # Mask emails
    masked = re.sub(
        PII_PATTERNS["email"],
        "[EMAIL_REDACTED]",
        masked
    )
    
    # Mask SSNs
    masked = re.sub(
        PII_PATTERNS["ssn"],
        "[SSN_REDACTED]",
        masked
    )
    
    # Mask credit cards
    masked = re.sub(
        PII_PATTERNS["credit_card"],
        "[CARD_REDACTED]",
        masked
    )
    
    # Mask phone numbers
    masked = re.sub(
        PII_PATTERNS["phone"],
        "[PHONE_REDACTED]",
        masked
    )
    
    return masked


def check_token_budget(
    estimated_tokens: int,
    max_tokens: int = 4000
) -> None:
    """
    Validate token count against budget
    
    Args:
        estimated_tokens: Estimated token count
        max_tokens: Maximum allowed tokens
        
    Raises:
        GuardrailViolation: If tokens exceed budget
    """
    if estimated_tokens > max_tokens:
        raise GuardrailViolation(
            f"Estimated tokens ({estimated_tokens}) exceeds budget ({max_tokens})"
        )


def check_content_safety(text: str, blocked_terms: list = None) -> Tuple[bool, Optional[str]]:
    """
    Check for prohibited content
    
    Args:
        text: Text to check
        blocked_terms: Optional list of blocked terms
        
    Returns:
        Tuple of (is_safe, violation_reason)
    """
    if blocked_terms is None:
        blocked_terms = []
    
    text_lower = text.lower()
    
    for term in blocked_terms:
        if term.lower() in text_lower:
            return False, f"Blocked term detected: {term}"
    
    return True, None


def apply_guardrails(
    user_input: str,
    check_injection: bool = True,
    check_pii: bool = True,
    max_input_length: int = 10000,
    max_tokens: int = 4000,
    blocked_terms: list = None
) -> Dict:
    """
    Apply all guardrails to user input
    
    Args:
        user_input: User's input text
        check_injection: Whether to check for prompt injection
        check_pii: Whether to detect PII
        max_input_length: Maximum input length
        max_tokens: Maximum token budget
        blocked_terms: Optional list of blocked terms
        
    Returns:
        Dictionary with validation results and masked input
        
    Raises:
        GuardrailViolation: If any critical check fails
    """
    results = {
        "safe": True,
        "violations": [],
        "warnings": [],
        "masked_input": user_input,
        "pii_detected": {}
    }
    
    # Check input length
    try:
        check_input_length(user_input, max_input_length)
    except GuardrailViolation as e:
        results["safe"] = False
        results["violations"].append(str(e))
        raise
    
    # Check prompt injection
    if check_injection:
        is_safe, reason = check_prompt_injection(user_input)
        if not is_safe:
            results["safe"] = False
            results["violations"].append(reason)
            raise GuardrailViolation(reason)
    
    # Check content safety
    is_safe, reason = check_content_safety(user_input, blocked_terms)
    if not is_safe:
        results["safe"] = False
        results["violations"].append(reason)
        raise GuardrailViolation(reason)
    
    # Detect and mask PII
    if check_pii:
        pii_found = detect_pii(user_input)
        if pii_found:
            results["pii_detected"] = pii_found
            results["warnings"].append(f"PII detected: {list(pii_found.keys())}")
            results["masked_input"] = mask_pii(user_input)
    
    # Check token budget
    estimated_tokens = len(user_input) // 4  # Rough estimate
    try:
        check_token_budget(estimated_tokens, max_tokens)
    except GuardrailViolation as e:
        results["safe"] = False
        results["violations"].append(str(e))
        raise
    
    return results
