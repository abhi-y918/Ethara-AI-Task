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

# GET /api/projects
@router.get("/", response_model=list[schemas.ProjectOut])
def list_projects(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    projects = db.query(models.Project).join(models.ProjectMember).filter(
        models.ProjectMember.user_id == current_user.id
    ).all()
    return projects

# POST /api/projects
@router.post("/", response_model=schemas.ProjectOut, status_code=status.HTTP_201_CREATED)
def create_project(payload: schemas.ProjectCreate, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    new_project = models.Project(
        name=payload.name,
        description=payload.description,
        created_by=current_user.id
    )
    db.add(new_project)
    db.commit()
    db.refresh(new_project)
    
    # Add creator as admin
    member = models.ProjectMember(
        project_id=new_project.id,
        user_id=current_user.id,
        role=models.RoleEnum.admin
    )
    db.add(member)
    db.commit()
    return new_project

# GET /api/projects/{id}
@router.get("/{project_id}", response_model=schemas.ProjectOut)
def get_project(project_id: int, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    if not current_user.is_superadmin:
        member = get_project_member(db, project_id, current_user.id)
        if not member:
            raise HTTPException(status_code=403, detail="Not authorized to view this project")
            
    project = db.query(models.Project).filter(models.Project.id == project_id).first()
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    return project

# DELETE /api/projects/{id}
@router.delete("/{project_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_project(project_id: int, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    if current_user.is_superadmin:
        project = db.query(models.Project).filter(models.Project.id == project_id).first()
        if not project:
            raise HTTPException(status_code=404, detail="Project not found")
        db.delete(project)
        db.commit()
        return

    member = get_project_member(db, project_id, current_user.id)
    if not member or member.role != models.RoleEnum.admin:
        raise HTTPException(status_code=403, detail="Only admins can delete projects")
    
    db.delete(member.project)
    db.commit()

# POST /api/projects/{id}/members
@router.post("/{project_id}/members", status_code=status.HTTP_201_CREATED)
def add_member(project_id: int, payload: schemas.AddMember, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    member = get_project_member(db, project_id, current_user.id)
    if not member or member.role != models.RoleEnum.admin:
        raise HTTPException(status_code=403, detail="Only admins can add members")
    
    user_to_add = db.query(models.User).filter(models.User.email == payload.email).first()
    if not user_to_add:
        raise HTTPException(status_code=404, detail="User not found")
        
    existing_member = get_project_member(db, project_id, user_to_add.id)
    if existing_member:
        raise HTTPException(status_code=400, detail="User is already a member")
        
    new_member = models.ProjectMember(
        project_id=project_id,
        user_id=user_to_add.id,
        role=models.RoleEnum.member
    )
    db.add(new_member)
    db.commit()
    return {"message": "Member added successfully"}

# DELETE /api/projects/{id}/members/{user_id}
@router.delete("/{project_id}/members/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_member(project_id: int, user_id: int, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    member_to_remove = get_project_member(db, project_id, user_id)
    if not member_to_remove:
        raise HTTPException(status_code=404, detail="Member not found")
        
    if not current_user.is_superadmin:
        member = get_project_member(db, project_id, current_user.id)
        if not member or member.role != models.RoleEnum.admin:
            raise HTTPException(status_code=403, detail="Only admins can remove members")
        
    if member_to_remove.user_id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot remove yourself")
        
    if current_user.is_superadmin and member_to_remove.role == models.RoleEnum.admin:
        sa_member = get_project_member(db, project_id, current_user.id)
        if not sa_member:
            new_sa_member = models.ProjectMember(
                project_id=project_id,
                user_id=current_user.id,
                role=models.RoleEnum.admin
            )
            db.add(new_sa_member)
        elif sa_member.role != models.RoleEnum.admin:
            sa_member.role = models.RoleEnum.admin
            
    db.delete(member_to_remove)
    db.commit()

# GET /api/projects/{id}/members
@router.get("/{project_id}/members")
def list_members(project_id: int, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    if not current_user.is_superadmin:
        member = get_project_member(db, project_id, current_user.id)
        if not member:
            raise HTTPException(status_code=403, detail="Not authorized")
    
    members = db.query(models.ProjectMember).filter(
        models.ProjectMember.project_id == project_id
    ).all()
    
    return [
        {
            "user_id": m.user_id,
            "name": m.user.name,
            "email": m.user.email,
            "role": m.role.value
        }
        for m in members
    ]

# GET /api/projects/{id}/tasks
@router.get("/{project_id}/tasks", response_model=list[schemas.TaskOut])
def list_tasks(project_id: int, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    if not current_user.is_superadmin:
        member = get_project_member(db, project_id, current_user.id)
        if not member:
            raise HTTPException(status_code=403, detail="Not authorized to view tasks")
        
    tasks = db.query(models.Task).filter(models.Task.project_id == project_id).all()
    return tasks

# POST /api/projects/{id}/tasks
@router.post("/{project_id}/tasks", response_model=schemas.TaskOut, status_code=status.HTTP_201_CREATED)
def create_task(project_id: int, payload: schemas.TaskCreate, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    member = get_project_member(db, project_id, current_user.id)
    if not member or member.role != models.RoleEnum.admin:
        raise HTTPException(status_code=403, detail="Only admins can create tasks")
        
    if payload.assigned_to:
        assignee_member = get_project_member(db, project_id, payload.assigned_to)
        if not assignee_member:
            raise HTTPException(status_code=400, detail="Assignee is not a member of the project")
            
    new_task = models.Task(
        title=payload.title,
        description=payload.description,
        due_date=payload.due_date,
        priority=payload.priority,
        status=models.StatusEnum.todo,
        project_id=project_id,
        assigned_to=payload.assigned_to,
        created_by=current_user.id
    )
    db.add(new_task)
    db.commit()
    db.refresh(new_task)
    return new_task
