from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from database import get_db
from dependencies import get_current_user
import models, schemas

router = APIRouter()


# GET /api/tasks/{id}
@router.get("/{task_id}", response_model=schemas.TaskOut)
def get_task(task_id: int, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    # TODO: fetch task if user is a member of the project
    raise HTTPException(status_code=501, detail="Not implemented yet")


# PATCH /api/tasks/{id}
@router.patch("/{task_id}", response_model=schemas.TaskOut)
def update_task(task_id: int, payload: schemas.TaskUpdate, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    # TODO: admin = full update | member = status only (own tasks)
    raise HTTPException(status_code=501, detail="Not implemented yet")


# DELETE /api/tasks/{id}
@router.delete("/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_task(task_id: int, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    # TODO: admin only
    raise HTTPException(status_code=501, detail="Not implemented yet")


# ── Nested under projects ─────────────────────────────────────
# GET /api/projects/{id}/tasks  and  POST /api/projects/{id}/tasks
# are registered in projects.py router for cleaner nesting
