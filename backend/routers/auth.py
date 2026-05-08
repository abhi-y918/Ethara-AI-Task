# pyrefly: ignore [missing-import]
from fastapi import APIRouter, Depends, HTTPException, status, Response, Request
# pyrefly: ignore [missing-import]
from sqlalchemy.orm import Session

from database import get_db
from dependencies import get_current_user
from datetime import datetime, timedelta, timezone
import models, schemas, auth as auth_utils, utils
from firebase_admin import auth as firebase_auth

router = APIRouter()


# POST /api/auth/google — Firebase Google Sign-In
@router.post("/google", status_code=status.HTTP_200_OK)
def google_login(payload: dict, response: Response, db: Session = Depends(get_db)):
    id_token = payload.get("id_token")
    if not id_token:
        raise HTTPException(status_code=400, detail="id_token is required")
    try:
        decoded = firebase_auth.verify_id_token(id_token)
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid or expired Firebase token")

    email = decoded.get("email")
    name = decoded.get("name") or (email.split("@")[0] if email else "User")

    if not email:
        raise HTTPException(status_code=400, detail="Google account must have an email")

    # Find or create the user
    user = db.query(models.User).filter(models.User.email == email).first()
    if not user:
        user = models.User(
            name=name,
            email=email,
            hashed_password="",  # No password for Google OAuth users
        )
        db.add(user)
        db.commit()
        db.refresh(user)

    # Issue our own JWT session cookie
    access_token = auth_utils.create_access_token({"sub": str(user.id)})
    response.set_cookie(
        key="access_token",
        value=access_token,
        httponly=True,
        samesite="none",
        secure=True,
        max_age=60 * 60 * 24 * 7,  # 7 days
    )
    return {"message": "Logged in via Google", "user": {"id": user.id, "name": user.name, "email": user.email}}


@router.post("/signup", status_code=status.HTTP_200_OK)
def signup(payload: schemas.UserCreate, db: Session = Depends(get_db)):
    """
    Step 1 of registration.
    - Blocks if email already belongs to a verified User.
    - Creates/updates a PendingSignup record and sends OTP.
    - No real User row is created yet.
    """
    # Block if a real (verified) user already exists with this email
    existing_user = db.query(models.User).filter(models.User.email == payload.email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")

    hashed_pwd = auth_utils.hash_password(payload.password)
    otp = utils.generate_otp()
    expires = datetime.now(timezone.utc) + timedelta(minutes=15)

    # Upsert the pending signup (allow resend)
    pending = db.query(models.PendingSignup).filter(models.PendingSignup.email == payload.email).first()
    if pending:
        pending.name = payload.name
        pending.hashed_password = hashed_pwd
        pending.otp_code = otp
        pending.otp_expires_at = expires
    else:
        pending = models.PendingSignup(
            name=payload.name,
            email=payload.email,
            hashed_password=hashed_pwd,
            otp_code=otp,
            otp_expires_at=expires,
        )
        db.add(pending)

    db.commit()

    utils.send_email_via_brevo(
        to_email=payload.email,
        subject="Verify your account - Task Manager",
        html_content=(
            f"<h2>Welcome, {payload.name}!</h2>"
            f"<p>Your one-time verification code is:</p>"
            f"<h1 style='letter-spacing:8px;color:#7C3AED'>{otp}</h1>"
            f"<p>This code expires in 15 minutes.</p>"
        )
    )
    print(f"[OTP] Signup OTP for {payload.email}: {otp}")
    return {"message": "OTP sent to your email. Please verify to complete registration."}


@router.post("/verify-otp")
def verify_otp(payload: schemas.OTPVerify, response: Response, db: Session = Depends(get_db)):
    """
    Step 2 of registration.
    - Validates OTP against PendingSignup.
    - Creates the real User record.
    - Deletes the PendingSignup.
    - Issues access + refresh cookies.
    """
    pending = db.query(models.PendingSignup).filter(models.PendingSignup.email == payload.email).first()
    if not pending:
        raise HTTPException(status_code=404, detail="No pending signup found for this email")

    now_utc = datetime.now(timezone.utc)
    expires_at = pending.otp_expires_at

    if pending.otp_code != payload.otp or expires_at is None or now_utc > expires_at:
        raise HTTPException(status_code=400, detail="Invalid or expired OTP")

    # Create the real verified user
    new_user = models.User(
        name=pending.name,
        email=pending.email,
        hashed_password=pending.hashed_password,
    )
    db.add(new_user)
    db.delete(pending)  # Remove from pending table
    db.commit()
    db.refresh(new_user)

    # Issue auth cookies immediately after verification
    access_token = auth_utils.create_access_token(data={"sub": str(new_user.id)})
    refresh_token = auth_utils.create_refresh_token(data={"sub": str(new_user.id)})
    response.set_cookie(key="access_token", value=access_token, httponly=True, secure=True,samesite="none", max_age=auth_utils.ACCESS_TOKEN_EXPIRE_MINUTES * 60)
    response.set_cookie(key="refresh_token", value=refresh_token, httponly=True, secure=True,samesite="none", max_age=auth_utils.REFRESH_TOKEN_EXPIRE_DAYS * 86400)

    return {"message": "Email verified. Welcome!", "user": schemas.UserOut.model_validate(new_user)}


@router.post("/login")
def login(payload: schemas.UserLogin, response: Response, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == payload.email).first()

    # Check if there is a pending (unverified) signup
    if not user:
        pending = db.query(models.PendingSignup).filter(models.PendingSignup.email == payload.email).first()
        if pending:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Email not verified. Please complete OTP verification first."
            )
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

    if not user.hashed_password or not auth_utils.verify_password(payload.password, user.hashed_password):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

    access_token = auth_utils.create_access_token(data={"sub": str(user.id)})
    refresh_token = auth_utils.create_refresh_token(data={"sub": str(user.id)})
    response.set_cookie(key="access_token", value=access_token, httponly=True, secure=True,samesite="none", max_age=auth_utils.ACCESS_TOKEN_EXPIRE_MINUTES * 60)
    response.set_cookie(key="refresh_token", value=refresh_token, httponly=True, secure=True,samesite="none", max_age=auth_utils.REFRESH_TOKEN_EXPIRE_DAYS * 86400)

    return {"message": "Login successful", "user": schemas.UserOut.model_validate(user)}


@router.post("/forgot-password")
def forgot_password(payload: schemas.ForgotPassword, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == payload.email).first()
    if user:
        otp = utils.generate_otp()
        user.otp_code = otp
        user.otp_expires_at = datetime.now(timezone.utc) + timedelta(minutes=15)
        db.commit()
        utils.send_email_via_brevo(
            to_email=payload.email,
            subject="Password Reset - Task Manager",
            html_content=(
                f"<h2>Password Reset</h2>"
                f"<p>Your OTP is:</p>"
                f"<h1 style='letter-spacing:8px;color:#7C3AED'>{otp}</h1>"
                f"<p>This code expires in 15 minutes.</p>"
            )
        )
        print(f"[OTP] Password reset OTP for {payload.email}: {otp}")
    return {"message": "If that email is registered, an OTP has been sent."}


@router.post("/reset-password")
def reset_password(payload: schemas.ResetPassword, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == payload.email).first()
    now_utc = datetime.now(timezone.utc)
    expires_at = user.otp_expires_at

    if not user or user.otp_code != payload.otp or expires_at is None or now_utc > expires_at:
        raise HTTPException(status_code=400, detail="Invalid or expired OTP")

    user.hashed_password = auth_utils.hash_password(payload.new_password)
    user.otp_code = None
    user.otp_expires_at = None
    db.commit()
    return {"message": "Password reset successfully. Please log in."}


@router.post("/logout")
def logout(response: Response):
    response.delete_cookie("access_token")
    response.delete_cookie("refresh_token")
    return {"message": "Logged out successfully"}


@router.get("/me", response_model=schemas.UserOut)
def me(current_user: models.User = Depends(get_current_user)):
    return current_user
