from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import os

from routers import auth, projects, tasks, dashboard

load_dotenv()

app = FastAPI(
    title="Team Task Manager API",
    description="RESTful API for Team Task Manager",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[os.getenv("FRONTEND_URL", "http://localhost")],
    allow_origin_regex=r"^https?://localhost:\d+$", # Allows any localhost port (e.g. Flutter web)
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router,      prefix="/api/auth",      tags=["Auth"])
app.include_router(projects.router,  prefix="/api/projects",  tags=["Projects"])
app.include_router(tasks.router,     prefix="/api/tasks",     tags=["Tasks"])
app.include_router(dashboard.router, prefix="/api/dashboard", tags=["Dashboard"])


@app.get("/health", tags=["Health"])
def health_check():
    return {"status": "ok", "message": "API is running"}
