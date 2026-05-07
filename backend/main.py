
# pyrefly: ignore [missing-import]
from fastapi import FastAPI
# pyrefly: ignore [missing-import]
from fastapi.middleware.cors import CORSMiddleware
# pyrefly: ignore [missing-import]
from dotenv import load_dotenv
import os
import firebase_admin
from firebase_admin import credentials

from routers import auth, projects, tasks, dashboard, admin

load_dotenv()

# Initialize Firebase Admin SDK
if not firebase_admin._apps:
    import json
    firebase_creds_env = os.getenv('FIREBASE_CREDENTIALS')
    if firebase_creds_env:
        cred_dict = json.loads(firebase_creds_env)
        cred = credentials.Certificate(cred_dict)
    else:
        cred = credentials.Certificate(os.path.join(os.path.dirname(__file__), 'firebase_service_account.json'))
    firebase_admin.initialize_app(cred)

app = FastAPI(
    title="Team Task Manager API",
    description="RESTful API for Team Task Manager",
    version="1.0.0",
)

ALLOWED_ORIGINS = [
    "http://localhost:5000",
    "http://localhost:8080",
    "http://127.0.0.1:5000",
    "https://ethara-ai-task-production-aefa.up.railway.app",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router,      prefix="/api/auth",      tags=["Auth"])
app.include_router(projects.router,  prefix="/api/projects",  tags=["Projects"])
app.include_router(tasks.router,     prefix="/api/tasks",     tags=["Tasks"])
app.include_router(dashboard.router, prefix="/api/dashboard", tags=["Dashboard"])
app.include_router(admin.router,     prefix="/api/admin",     tags=["Admin"])


@app.get("/health", tags=["Health"])
def health_check():
    return {"status": "ok", "message": "API is running"}
