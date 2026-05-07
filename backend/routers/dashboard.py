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

    base_query = db.query(models.Task).filter(models.Task.project_id.in_(project_ids_subquery))
    
    total_tasks = base_query.count()
    
    # By status
    status_counts = db.query(models.Task.status, func.count(models.Task.id)).filter(
        models.Task.project_id.in_(project_ids_subquery)
    ).group_by(models.Task.status).all()
    
    by_status = {"todo": 0, "in_progress": 0, "done": 0}
    for status, count in status_counts:
        by_status[status.value] = count
        
    # Tasks per user — broken down by status (todo + in_progress)
    # pyrefly: ignore [missing-import]
    from sqlalchemy import case as sa_case
    user_workload = db.query(
        models.User.name,
        models.User.email,
        func.count(sa_case((models.Task.status == models.StatusEnum.todo, 1))).label("todo"),
        func.count(sa_case((models.Task.status == models.StatusEnum.in_progress, 1))).label("in_progress"),
    ).join(
        models.Task, models.User.id == models.Task.assigned_to
    ).filter(
        models.Task.project_id.in_(project_ids_subquery),
        models.Task.status != models.StatusEnum.done
    ).group_by(models.User.name, models.User.email).all()

    tasks_per_user = [
        {"user_name": name, "email": email, "todo": todo, "in_progress": ip, "count": todo + ip}
        for name, email, todo, ip in user_workload
    ]
    
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
        "tasks_per_user": tasks_per_user,
        "overdue_tasks": overdue_tasks,
    }
