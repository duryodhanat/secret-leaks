"""
Authentication Module
Validates user tokens securely from headers or environment variables.
"""
import os
import hmac
import hashlib

def verify_token(provided_token: str) -> bool:
    """Validate client token against expected secret from environment."""
    expected_secret = os.getenv("API_SECRET_KEY")
    if not expected_secret:
        return False
    return hmac.compare_digest(provided_token, expected_secret)

def generate_signature(payload: str) -> str:
    """Generate SHA256 signature using environment signing key."""
    signing_key = os.getenv("SIGNING_KEY", "default-dev-signing-key")
    return hmac.new(signing_key.encode("utf-8"), payload.encode("utf-8"), hashlib.sha256).hexdigest()
