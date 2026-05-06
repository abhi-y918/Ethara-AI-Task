from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import date, datetime
from models import RoleEnum, PriorityEnum, StatusEnum


# ── Auth ──────────────────────────────────────────────────────

class UserCreate(BaseModel):
    name: str
    email: EmailStr
    password: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserOut(BaseModel):
    id: int
    name: str
    email: str
    google_id: Optional[str] = None
    created_at: datetime
    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"

class OTPVerify(BaseModel):
    email: EmailStr
    otp: str

class ForgotPassword(BaseModel):
    email: EmailStr

class ResetPassword(BaseModel):
    email: EmailStr
    otp: str
    new_password: str


# ── Projects ──────────────────────────────────────────────────

class ProjectCreate(BaseModel):
    name: str
    description: Optional[str] = None

class ProjectOut(BaseModel):
    id: int
    name: str
    description: Optional[str]
    created_by: int
    created_at: datetime
    class Config:
        from_attributes = True

class AddMember(BaseModel):
    email: EmailStr


# ── Tasks ─────────────────────────────────────────────────────

class TaskCreate(BaseModel):
    title: str
    description: Optional[str] = None
    due_date: date
    priority: PriorityEnum = PriorityEnum.medium
    assigned_to: Optional[int] = None

class TaskUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    due_date: Optional[date] = None
    priority: Optional[PriorityEnum] = None
    status: Optional[StatusEnum] = None
    assigned_to: Optional[int] = None

class TaskOut(BaseModel):
    id: int
    title: str
    description: Optional[str]
    due_date: date
    priority: PriorityEnum
    status: StatusEnum
    project_id: int
    assigned_to: Optional[int]
    created_by: int
    created_at: datetime
    updated_at: Optional[datetime]
    class Config:
        from_attributes = True
