"""Authentication and authorization."""
from datetime import datetime, timedelta, timezone
from typing import Optional, Dict
try:
    from jose import JWTError, jwt
except ImportError:
    # Fallback if python-jose is installed as jose
    from jose.jwt import JWTError
    import jose.jwt as jwt
from fastapi import HTTPException, status
from config import settings


def create_access_token(data: Dict[str, str], expires_delta: Optional[timedelta] = None) -> str:
    """Create JWT access token."""
    to_encode = data.copy()
    
    now = datetime.now(timezone.utc)
    if expires_delta:
        expire = now + expires_delta
    else:
        expire = now + timedelta(hours=settings.jwt_expiration_hours)
    
    now = datetime.now(timezone.utc)
    to_encode.update({
        "exp": int(expire.timestamp()),
        "iat": int(now.timestamp()),
        "iss": "health-intelligence-platform"
    })
    
    encoded_jwt = jwt.encode(to_encode, settings.jwt_secret, algorithm=settings.jwt_algorithm)
    return encoded_jwt


def verify_token(token: str) -> Dict[str, str]:
    """Verify and decode JWT token."""
    try:
        payload = jwt.decode(
            token,
            settings.jwt_secret,
            algorithms=[settings.jwt_algorithm],
            options={"verify_signature": True, "verify_exp": True, "leeway": 60}
        )
        return payload
    except JWTError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid token: {str(e)}"
        )


def get_tenant_id_from_token(token: str) -> str:
    """Extract tenant_id from JWT token."""
    payload = verify_token(token)
    tenant_id = payload.get("tenant_id")
    
    if not tenant_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token missing tenant_id"
        )
    
    return tenant_id


# Dev login: username = tenant_id
DEV_USERS = {
    "rajasaikatukuri": "rajasaikatukuri",
    # Add more dev users as needed
}


def dev_login(username: str) -> Dict[str, str]:
    """Dev login: username maps directly to tenant_id."""
    if username not in DEV_USERS:
        # Auto-create dev user
        DEV_USERS[username] = username
    
    tenant_id = DEV_USERS[username]
    
    token = create_access_token({
        "sub": username,
        "tenant_id": tenant_id,
        "username": username
    })
    
    return {
        "access_token": token,
        "token_type": "bearer",
        "tenant_id": tenant_id,
        "username": username
    }

