import enum
from sqlalchemy import Column, Integer, String, Text, Date, Enum, ForeignKey, DateTime, Boolean
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base


class RoleEnum(str, enum.Enum):
    admin = "admin"
    member = "member"


class PriorityEnum(str, enum.Enum):
    low = "low"
    medium = "medium"
    high = "high"


class StatusEnum(str, enum.Enum):
    todo = "todo"
    in_progress = "in_progress"
    done = "done"


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=True)  # Null for Google OAuth users
    google_id = Column(String, unique=True, index=True, nullable=True)
    # Forgot password OTP (reused for reset only, not signup)
    otp_code = Column(String, nullable=True)
    otp_expires_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    memberships = relationship("ProjectMember", back_populates="user")
    assigned_tasks = relationship("Task", foreign_keys="Task.assigned_to", back_populates="assignee")
    created_tasks = relationship("Task", foreign_keys="Task.created_by", back_populates="creator")


class PendingSignup(Base):
    """Temporary record for users who have not yet verified their email.
    A real User is only created after OTP is confirmed."""
    __tablename__ = "pending_signups"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    otp_code = Column(String, nullable=False)
    otp_expires_at = Column(DateTime(timezone=True), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class Project(Base):
    __tablename__ = "projects"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    created_by = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    members = relationship("ProjectMember", back_populates="project", cascade="all, delete")
    tasks = relationship("Task", back_populates="project", cascade="all, delete")


class ProjectMember(Base):
    __tablename__ = "project_members"

    id = Column(Integer, primary_key=True, index=True)
    project_id = Column(Integer, ForeignKey("projects.id", ondelete="CASCADE"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    role = Column(Enum(RoleEnum), nullable=False, default=RoleEnum.member)

    project = relationship("Project", back_populates="members")
    user = relationship("User", back_populates="memberships")


class Task(Base):
    __tablename__ = "tasks"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    due_date = Column(Date, nullable=False)
    priority = Column(Enum(PriorityEnum), nullable=False, default=PriorityEnum.medium)
    status = Column(Enum(StatusEnum), nullable=False, default=StatusEnum.todo)
    project_id = Column(Integer, ForeignKey("projects.id", ondelete="CASCADE"), nullable=False)
    assigned_to = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_by = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    project = relationship("Project", back_populates="tasks")
    assignee = relationship("User", foreign_keys=[assigned_to], back_populates="assigned_tasks")
    creator = relationship("User", foreign_keys=[created_by], back_populates="created_tasks")
