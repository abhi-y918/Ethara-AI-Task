# pyrefly: ignore [missing-import]
from fastapi import APIRouter, Depends
# pyrefly: ignore [missing-import]
from sqlalchemy.orm import Session
# pyrefly: ignore [missing-import]
from sqlalchemy import func
from database import get_db
from dependencies import get_current_user
import models
from datetime import date

router = APIRouter()

# GET /api/dashboard/stats
@router.get("/stats")
def get_stats(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    project_ids_subquery = db.query(models.ProjectMember.project_id).filter(
        models.ProjectMember.user_id == current_user.id
    ).subquery()

    base_query = db.query(models.Task).filter(
        models.Task.project_id.in_(project_ids_subquery),
        models.Task.assigned_to == current_user.id
    )
    
    total_tasks = base_query.count()
    
    # By status
    status_counts = db.query(models.Task.status, func.count(models.Task.id)).filter(
        models.Task.project_id.in_(project_ids_subquery),
        models.Task.assigned_to == current_user.id
    ).group_by(models.Task.status).all()
    
    by_status = {"todo": 0, "in_progress": 0, "done": 0}
    for status, count in status_counts:
        by_status[status.value] = count
        
    # Individual tasks for the current user
    my_tasks_db = db.query(
        models.Task, models.Project.name.label("project_name")
    ).join(
        models.Project, models.Task.project_id == models.Project.id
    ).filter(
        models.Task.assigned_to == current_user.id,
        models.Task.status != models.StatusEnum.done
    ).all()

    my_tasks = []
    for t, p_name in my_tasks_db:
        my_tasks.append({
            "project_name": p_name,
            "task_title": t.title,
            "status": t.status.value,
            "todo": 1 if t.status.value == "todo" else 0,
            "in_progress": 1 if t.status.value == "in_progress" else 0,
            "count": 1
        })
    
    # Overdue tasks
    today = date.today()
    overdue_tasks_db = base_query.filter(
        models.Task.due_date < today,
        models.Task.status != models.StatusEnum.done
    ).all()
    
    overdue_tasks = []
    for t in overdue_tasks_db:
        overdue_tasks.append({
            "id": t.id,
            "title": t.title,
            "due_date": t.due_date.isoformat(),
            "priority": t.priority.value,
            "status": t.status.value,
            "project_id": t.project_id
        })

    return {
        "total_tasks": total_tasks,
        "by_status": by_status,
        "my_tasks": my_tasks,
        "overdue_tasks": overdue_tasks,
    }
