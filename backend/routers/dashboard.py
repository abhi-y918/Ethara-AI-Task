from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import get_db
from dependencies import get_current_user
import models

router = APIRouter()


# GET /api/dashboard/stats
@router.get("/stats")
def get_stats(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    # TODO: return aggregated stats — total tasks, by status, per user, overdue
    return {
        "total_tasks": 0,
        "by_status": {"todo": 0, "in_progress": 0, "done": 0},
        "tasks_per_user": [],
        "overdue_tasks": [],
    }
