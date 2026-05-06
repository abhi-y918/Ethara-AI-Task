# Team Task Manager

> A full-stack collaborative task management web application built with **Flutter Web** and **FastAPI**, powered by **PostgreSQL**, deployed on **Railway**.

![Flutter](https://img.shields.io/badge/Flutter-Web-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-Python-009688?style=for-the-badge&logo=fastapi&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Database-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)
![Railway](https://img.shields.io/badge/Deployed-Railway-0B0D0E?style=for-the-badge&logo=railway&logoColor=white)

---

## Table of Contents

- [Overview](#overview)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Features](#features)
- [Database Schema](#database-schema)
- [API Endpoints](#api-endpoints)
- [Project Structure](#project-structure)
- [Local Setup](#local-setup)
- [Environment Variables](#environment-variables)
- [Deployment on Railway](#deployment-on-railway)
- [Demo Video](#demo-video)

---

## Overview

Team Task Manager is a real-world collaborative tool where teams can:

- Create and manage **projects**
- Assign and track **tasks** with priorities and deadlines
- View a **dashboard** with analytics on task status and team workload
- Control access through **role-based permissions** (Admin / Member)

Think of it as a simplified **Trello** or **Asana** — built from scratch.

---

## Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| Frontend | Flutter Web (Dart) | Cross-platform web UI |
| Backend | FastAPI (Python) | RESTful API server |
| Database | PostgreSQL | Relational data storage |
| Auth | JWT (JSON Web Tokens) | Stateless authentication |
| ORM | SQLAlchemy + Alembic | DB models and migrations |
| State Management | Riverpod | Flutter state management |
| HTTP Client | Dio | API calls from Flutter |
| Routing | go_router | Flutter web routing |
| Charts | fl_chart | Dashboard visualizations |
| Deployment | Railway | Backend + DB hosting |
| Env Config | python-dotenv | Backend env variables |

---

## Architecture

```
Flutter Web (Browser)
        |
    Dio HTTP Client
    (Bearer JWT Token)
        |
   HTTPS REST API
        |
FastAPI Backend (Railway)
  - /auth  /projects  /tasks  /dashboard
  - JWT Middleware + RBAC Checks
  - SQLAlchemy ORM + Alembic Migrations
        |
PostgreSQL Database (Railway)
  - users | projects | project_members | tasks
```

---

## Features

### Authentication

- Signup with Name, Email, Password
- Login returns a signed **JWT token**
- Token stored securely using `flutter_secure_storage`
- All API calls include `Authorization: Bearer <token>` header

### Project Management

- Any user can **create a project** and is auto-assigned as Admin
- Admin can **invite members** by email
- Admin can **remove members**
- Members see only the **projects they belong to**

### Task Management

- Admin creates tasks with Title, Description, Due Date, Priority (Low / Medium / High)
- Tasks are assigned to a project member
- Status flow: `To Do` → `In Progress` → `Done`
- Members can update the status of their assigned tasks
- Admins can edit or delete any task

### Dashboard

- Total tasks count
- Tasks breakdown by status (Pie chart)
- Tasks per user (Bar chart)
- Overdue tasks highlighted in an alert list

### Role-Based Access Control (RBAC)

| Action | Admin | Member |
|---|:---:|:---:|
| Create / Delete Project | Yes | No |
| Add / Remove Members | Yes | No |
| Create / Delete Tasks | Yes | No |
| Assign Tasks | Yes | No |
| View Project and Tasks | Yes | Yes |
| Update Task Status | Yes | Yes (own tasks only) |
| View Dashboard | Yes | Yes |

---

## Database Schema

### users

| Column | Type | Notes |
|---|---|---|
| id | SERIAL | Primary Key |
| name | VARCHAR | Required |
| email | VARCHAR | Unique, Required |
| hashed_password | VARCHAR | bcrypt hashed |
| created_at | TIMESTAMP | Auto |

### projects

| Column | Type | Notes |
|---|---|---|
| id | SERIAL | Primary Key |
| name | VARCHAR | Required |
| description | TEXT | Optional |
| created_by | FK → users.id | Auto-assigned Admin |
| created_at | TIMESTAMP | Auto |

### project_members (Junction Table)

| Column | Type | Notes |
|---|---|---|
| id | SERIAL | Primary Key |
| project_id | FK → projects.id | Cascade Delete |
| user_id | FK → users.id | Cascade Delete |
| role | ENUM | `admin` or `member` |

### tasks

| Column | Type | Notes |
|---|---|---|
| id | SERIAL | Primary Key |
| title | VARCHAR | Required |
| description | TEXT | Optional |
| due_date | DATE | Required |
| priority | ENUM | `low`, `medium`, `high` |
| status | ENUM | `todo`, `in_progress`, `done` |
| project_id | FK → projects.id | Cascade Delete |
| assigned_to | FK → users.id | Nullable |
| created_by | FK → users.id | |
| created_at | TIMESTAMP | Auto |
| updated_at | TIMESTAMP | Auto-update |

**Relationships:**

- `User` and `Project` — Many-to-Many via `project_members`
- `Project` and `Task` — One-to-Many
- `User` and `Task` (assignee) — One-to-Many

---

## API Endpoints

### Auth — `/api/auth`

| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| POST | `/signup` | Register new user | No |
| POST | `/login` | Login, returns JWT | No |
| GET | `/me` | Get current user info | Yes |

### Projects — `/api/projects`

| Method | Endpoint | Description | Role |
|---|---|---|---|
| GET | `/` | List user's projects | Any |
| POST | `/` | Create project | Any (becomes Admin) |
| GET | `/{id}` | Project detail + members | Member+ |
| DELETE | `/{id}` | Delete project | Admin |
| POST | `/{id}/members` | Add member by email | Admin |
| DELETE | `/{id}/members/{uid}` | Remove member | Admin |

### Tasks — `/api/projects/{id}/tasks` and `/api/tasks`

| Method | Endpoint | Description | Role |
|---|---|---|---|
| GET | `/projects/{id}/tasks` | List tasks in project | Member+ |
| POST | `/projects/{id}/tasks` | Create task | Admin |
| GET | `/tasks/{id}` | Task detail | Member+ |
| PATCH | `/tasks/{id}` | Update task | Admin / Member (status only) |
| DELETE | `/tasks/{id}` | Delete task | Admin |

### Dashboard — `/api/dashboard`

| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| GET | `/stats` | Aggregated stats for current user | Yes |

### Health Check

| Method | Endpoint | Description |
|---|---|---|
| GET | `/health` | Server heartbeat for Railway keep-alive |

---

## Project Structure

```
team-task-manager/
|
|-- backend/
|   |-- main.py                  # App entry point, CORS, router registration
|   |-- database.py              # SQLAlchemy engine + session dependency
|   |-- models.py                # ORM models (User, Project, Task, etc.)
|   |-- schemas.py               # Pydantic request/response schemas
|   |-- auth.py                  # JWT creation, decoding, password hashing
|   |-- dependencies.py          # get_current_user(), get_admin_user()
|   |-- routers/
|   |   |-- auth.py
|   |   |-- projects.py
|   |   |-- tasks.py
|   |   └-- dashboard.py
|   |-- alembic/
|   |   └-- versions/
|   |-- alembic.ini
|   |-- requirements.txt
|   |-- Procfile                 # Railway start command
|   └-- .env.example
|
|-- frontend/
|   |-- lib/
|   |   |-- main.dart            # App entry, theme, router setup
|   |   |-- core/
|   |   |   |-- constants.dart   # API base URL, colors, strings
|   |   |   |-- theme.dart       # App-wide dark theme definition
|   |   |   └-- router.dart      # go_router route definitions
|   |   |-- models/
|   |   |   |-- user.dart
|   |   |   |-- project.dart
|   |   |   └-- task.dart
|   |   |-- services/
|   |   |   |-- api_service.dart      # Dio client with JWT interceptor
|   |   |   |-- auth_service.dart
|   |   |   |-- project_service.dart
|   |   |   └-- task_service.dart
|   |   |-- providers/
|   |   |   |-- auth_provider.dart
|   |   |   |-- project_provider.dart
|   |   |   └-- task_provider.dart
|   |   |-- pages/
|   |   |   |-- login_page.dart
|   |   |   |-- signup_page.dart
|   |   |   |-- dashboard_page.dart
|   |   |   |-- projects_page.dart
|   |   |   |-- project_detail_page.dart
|   |   |   └-- task_detail_page.dart
|   |   └-- widgets/
|   |       |-- task_card.dart
|   |       |-- kanban_column.dart
|   |       |-- stat_card.dart
|   |       |-- member_tile.dart
|   |       └-- priority_badge.dart
|   |-- web/
|   |   └-- index.html
|   └-- pubspec.yaml
|
|-- .gitignore
└-- README.md
```

---

## Local Setup

### Prerequisites

- Python 3.11 or higher
- Flutter SDK with web support enabled
- PostgreSQL (local instance or Railway DB URL)

### Backend Setup

```bash
# Navigate to backend directory
cd backend

# Create and activate virtual environment
python -m venv venv
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Copy env example and fill in values
cp .env.example .env

# Run database migrations
alembic upgrade head

# Start the development server
uvicorn main:app --reload --port 8000
```

Backend runs at: `http://localhost:8000`

API docs available at: `http://localhost:8000/docs`

### Frontend Setup

```bash
# Navigate to frontend directory
cd frontend

# Install Flutter packages
flutter pub get

# Update API base URL in lib/core/constants.dart
# const String apiBaseUrl = 'http://localhost:8000';

# Run Flutter web
flutter run -d chrome
```

---

## Environment Variables

### Backend `.env`

```env
DATABASE_URL=postgresql://user:password@localhost:5432/taskmanager
SECRET_KEY=your-super-secret-jwt-key-here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
FRONTEND_URL=http://localhost:PORT
```

On Railway, these are set in the **Variables** tab. `DATABASE_URL` is auto-injected when you add a PostgreSQL plugin.

### Flutter `constants.dart`

```dart
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000',
);
```

Set `API_BASE_URL` to your Railway backend URL before production build.

---

## Deployment on Railway

### Step 1 — Push to GitHub

```bash
git add .
git commit -m "initial commit"
git push origin main
```

### Step 2 — Deploy Backend

1. Go to [railway.app](https://railway.app) and create a New Project
2. Select Deploy from GitHub Repo and choose your repository
3. Set the Root Directory to `backend/`
4. Add a `Procfile` in the backend folder:

```
web: alembic upgrade head && uvicorn main:app --host 0.0.0.0 --port $PORT
```

5. Add a PostgreSQL plugin — Railway auto-sets `DATABASE_URL`
6. Add remaining environment variables in the Variables tab
7. Deploy and note your public backend URL

### Step 3 — Deploy Frontend

1. Update `apiBaseUrl` in `constants.dart` to your Railway backend URL
2. Build Flutter web:

```bash
flutter build web --release
```

3. Add a new Railway static site service pointing to `frontend/build/web/`
4. Deploy and note your public frontend URL

### Step 4 — Final Checklist

- [ ] Signup and login work on live URL
- [ ] CORS on backend allows the frontend Railway domain
- [ ] JWT auth headers are sent correctly from Flutter
- [ ] Dashboard charts render properly
- [ ] Admin vs Member flows tested end-to-end

---

## Dependencies

### Backend `requirements.txt`

```
fastapi>=0.110.0
uvicorn[standard]>=0.29.0
sqlalchemy>=2.0.0
alembic>=1.13.0
psycopg2-binary>=2.9.9
python-jose[cryptography]>=3.3.0
passlib[bcrypt]>=1.7.4
python-dotenv>=1.0.0
python-multipart>=0.0.9
pydantic[email]>=2.6.0
```

### Flutter `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  go_router: ^13.0.0
  flutter_riverpod: ^2.5.0
  dio: ^5.4.3
  flutter_secure_storage: ^9.0.0
  fl_chart: ^0.67.0
  intl: ^0.19.0
```

---

## Demo Video

A 2 to 5 minute walkthrough demonstrating:

- User signup and login
- Creating a project and inviting a member
- Creating and assigning tasks
- Updating task status from the Member view
- Dashboard analytics and charts
- Live deployment on Railway

---

## Author

**Abhinav Yadav**

[GitHub](https://github.com/abhi-y918) · [LinkedIn](https://linkedin.com/in/abhinav-yadav)

---

*Built as part of a full-stack coding assignment.*