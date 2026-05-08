# pyrefly: ignore [missing-import]
from fastapi import APIRouter, Depends, HTTPException, status
# pyrefly: ignore [missing-import]
from sqlalchemy.orm import Session
from database import get_db
from dependencies import get_current_user
import models, schemas

router = APIRouter()

def verify_superadmin(current_user: models.User):
    if not current_user.is_superadmin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Superadmin privileges required"
        )

@router.get("/users")
def get_all_users(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    """Get all registered users in the platform."""
    verify_superadmin(current_user)
    users = db.query(models.User).all()
    return [
        {
            "id": u.id,
            "name": u.name,
            "email": u.email,
            "is_superadmin": u.is_superadmin,
            "created_at": u.created_at
        } for u in users
    ]

@router.get("/projects")
def get_all_projects(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    """Get all projects across the platform and their member count."""
    verify_superadmin(current_user)
    projects = db.query(models.Project).all()
    result = []
    for p in projects:
        member_count = db.query(models.ProjectMember).filter(models.ProjectMember.project_id == p.id).count()
        task_count = db.query(models.Task).filter(models.Task.project_id == p.id).count()
        creator = db.query(models.User).filter(models.User.id == p.created_by).first()
        
        result.append({
            "id": p.id,
            "name": p.name,
            "description": p.description,
            "created_by": creator.name if creator else "Unknown",
            "member_count": member_count,
            "task_count": task_count,
            "created_at": p.created_at
        })
    return result

@router.post("/make-superadmin/{user_id}")
def make_superadmin(user_id: int, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    """Promote a user to superadmin status."""
    verify_superadmin(current_user)
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user.is_superadmin = True
    db.commit()
    return {"message": f"{user.name} is now a superadmin"}

@router.delete("/users/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_user(user_id: int, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    """Delete a user from the platform (superadmin only)."""
    verify_superadmin(current_user)
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if user.id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot delete yourself")
    db.delete(user)
    db.commit()

@router.put("/users/{user_id}", response_model=schemas.UserOut)
def update_user_name(user_id: int, payload: schemas.UserUpdateName, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    """Update a user's name (superadmin only)."""
    verify_superadmin(current_user)
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.name = payload.name
    db.commit()
    db.refresh(user)
    return user
