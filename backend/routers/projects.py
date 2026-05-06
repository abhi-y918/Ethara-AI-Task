from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from database import get_db
from dependencies import get_current_user
import models, schemas

router = APIRouter()


# GET /api/projects
@router.get("/", response_model=list[schemas.ProjectOut])
def list_projects(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    # TODO: return projects the user belongs to
    raise HTTPException(status_code=501, detail="Not implemented yet")


# POST /api/projects
@router.post("/", response_model=schemas.ProjectOut, status_code=status.HTTP_201_CREATED)
def create_project(payload: schemas.ProjectCreate, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    # TODO: create project, add creator as admin
    raise HTTPException(status_code=501, detail="Not implemented yet")


# GET /api/projects/{id}
@router.get("/{project_id}", response_model=schemas.ProjectOut)
def get_project(project_id: int, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    # TODO: fetch project if user is a member
    raise HTTPException(status_code=501, detail="Not implemented yet")


# DELETE /api/projects/{id}
@router.delete("/{project_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_project(project_id: int, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    # TODO: admin only
    raise HTTPException(status_code=501, detail="Not implemented yet")


# POST /api/projects/{id}/members
@router.post("/{project_id}/members", status_code=status.HTTP_201_CREATED)
def add_member(project_id: int, payload: schemas.AddMember, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    # TODO: admin only — find user by email, add to project_members
    raise HTTPException(status_code=501, detail="Not implemented yet")


# DELETE /api/projects/{id}/members/{user_id}
@router.delete("/{project_id}/members/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_member(project_id: int, user_id: int, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    # TODO: admin only
    raise HTTPException(status_code=501, detail="Not implemented yet")
