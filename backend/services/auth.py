from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import jwt
import os
from dotenv import load_dotenv

load_dotenv()
JWT_SECRET = os.getenv("SECRET_KEY")
JWT_ALGORITHM = "HS256"
token_auth_scheme = HTTPBearer()

def validate_token(auth: HTTPAuthorizationCredentials = Depends(token_auth_scheme)):
    """Validate JWT token from Authorization header."""
    try:
        payload = jwt.decode(auth.credentials, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        if not payload.get("sub"):
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing token subject")
        return payload
    except jwt.PyJWTError as e:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=f"Invalid token: {str(e)}")