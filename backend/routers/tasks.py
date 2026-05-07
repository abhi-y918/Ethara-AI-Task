# pyrefly: ignore [missing-import]
from fastapi import APIRouter, Depends, HTTPException, status
# pyrefly: ignore [missing-import]
from sqlalchemy.orm import Session
from database import get_db
from dependencies import get_current_user
import models, schemas

router = APIRouter()

def get_project_member(db: Session, project_id: int, user_id: int):
    return db.query(models.ProjectMember).filter(
        models.ProjectMember.project_id == project_id,
        models.ProjectMember.user_id == user_id
    ).first()

# GET /api/tasks/{id}
@router.get("/{task_id}", response_model=schemas.TaskOut)
def get_task(task_id: int, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    task = db.query(models.Task).filter(models.Task.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
        
    member = get_project_member(db, task.project_id, current_user.id)
    if not member:
        raise HTTPException(status_code=403, detail="Not authorized to view this task")
        
    return task

# PATCH /api/tasks/{id}
@router.patch("/{task_id}", response_model=schemas.TaskOut)
def update_task(task_id: int, payload: schemas.TaskUpdate, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    task = db.query(models.Task).filter(models.Task.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
        
    member = get_project_member(db, task.project_id, current_user.id)
    if not member:
        raise HTTPException(status_code=403, detail="Not authorized to update this task")
        
    is_admin = (member.role == models.RoleEnum.admin)
    is_assignee = (task.assigned_to == current_user.id)
    
    # Members can only update status of tasks assigned to them
    if not is_admin:
        if not is_assignee:
            raise HTTPException(status_code=403, detail="Members can only update their assigned tasks")
        
        # Ensure they are only updating status
        if payload.title is not None or payload.description is not None or payload.due_date is not None or payload.priority is not None or payload.assigned_to is not None:
            raise HTTPException(status_code=403, detail="Members can only update task status")
            
    # Update fields
    if payload.title is not None:
        task.title = payload.title
    if payload.description is not None:
        task.description = payload.description
    if payload.due_date is not None:
        task.due_date = payload.due_date
    if payload.priority is not None:
        task.priority = payload.priority
    if payload.status is not None:
        task.status = payload.status
    if payload.assigned_to is not None:
        if payload.assigned_to != task.assigned_to:
            # Check if new assignee is a member
            assignee_member = get_project_member(db, task.project_id, payload.assigned_to)
            if not assignee_member:
                raise HTTPException(status_code=400, detail="New assignee is not a member of the project")
        task.assigned_to = payload.assigned_to
        
    db.commit()
    db.refresh(task)
    return task

# DELETE /api/tasks/{id}
@router.delete("/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_task(task_id: int, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    task = db.query(models.Task).filter(models.Task.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
        
    member = get_project_member(db, task.project_id, current_user.id)
    if not member or member.role != models.RoleEnum.admin:
        raise HTTPException(status_code=403, detail="Only admins can delete tasks")
        
    db.delete(task)
    db.commit()
