from __future__ import annotations
from datetime import datetime, timedelta
from hashlib import sha256
from typing import Optional, List, Dict, Tuple, Any, Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
import hashlib
import hmac

from sqlalchemy.orm import Session

from .config import get_settings
from .database import get_db
from .models import APIToken, Teacher

bearer = HTTPBearer(auto_error=False)


def hash_password(password: str) -> str:
    salt = "ce-analytics-v1"
    digest = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt.encode("utf-8"), 120000)
    return digest.hex()


def verify_password(password: str, password_hash: str) -> bool:
    return hmac.compare_digest(hash_password(password), password_hash)


def create_access_token(subject: str, role: str, extra: Optional[dict] = None) -> str:
    settings = get_settings()
    payload = {
        "sub": subject,
        "role": role,
        "exp": datetime.utcnow() + timedelta(minutes=settings.access_token_expire_minutes),
    }
    if extra:
        payload.update(extra)
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def hash_token(raw: str) -> str:
    return sha256(raw.encode("utf-8")).hexdigest()


def decode_token(token: str) -> dict:
    settings = get_settings()
    try:
        return jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
    except JWTError as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token") from exc


def require_auth(
    creds: Annotated[Optional[HTTPAuthorizationCredentials], Depends(bearer)],
    db: Annotated[Session, Depends(get_db)],
) -> dict:
    if creds is None or not creds.credentials:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing bearer token")
    raw = creds.credentials
    # Prefer JWT; fall back to opaque API token table for device installs.
    try:
        return decode_token(raw)
    except HTTPException:
        token = db.query(APIToken).filter(APIToken.token_hash == hash_token(raw), APIToken.revoked.is_(False)).first()
        if not token:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
        return {
            "sub": f"token:{token.id}",
            "role": "teacher" if token.teacher_id else "device",
            "teacher_id": token.teacher_id,
            "student_id": token.student_id,
        }


def require_teacher(auth: Annotated[dict, Depends(require_auth)], db: Annotated[Session, Depends(get_db)]) -> Teacher:
    if auth.get("role") != "teacher":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Teacher role required")
    teacher_id = auth.get("teacher_id")
    email = auth.get("sub")
    teacher = None
    if teacher_id:
        teacher = db.get(Teacher, teacher_id)
    if teacher is None and email:
        teacher = db.query(Teacher).filter(Teacher.email == email).first()
    if teacher is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Teacher not found")
    return teacher
