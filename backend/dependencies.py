# pyrefly: ignore [missing-import]
from fastapi import Depends, HTTPException, status, Request
# pyrefly: ignore [missing-import]
from sqlalchemy.orm import Session
from database import get_db
from auth import decode_token
from jose import JWTError
import models

def get_token_from_cookie(request: Request):
    token = request.cookies.get("access_token")
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated"
        )
    return token

def get_current_user(
    token: str = Depends(get_token_from_cookie),
    db: Session = Depends(get_db),
) -> models.User:
    """Validates JWT from cookie and returns the current authenticated user."""
    exc = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
    )
    try:
        payload = decode_token(token)
        user_id = payload.get("sub")
        if user_id is None:
            raise exc
    except JWTError:
        raise exc

    user = db.query(models.User).filter(models.User.id == int(user_id)).first()
    if user is None:
        raise exc
    return user
