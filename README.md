# 🗂️ Team Task Manager

> A full-stack collaborative task management web application — built with **Flutter Web** (frontend) and **FastAPI** (backend), powered by **PostgreSQL** and deployed on **Railway**.

---

## 📌 Table of Contents

- [Overview](#overview)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Features](#features)
- [Database Schema](#database-schema)
- [API Endpoints](#api-endpoints)
- [Project Structure](#project-structure)
- [Local Setup](#local-setup)
- [Environment Variables](#environment-variables)
- [Deployment (Railway)](#deployment-railway)
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
| **Frontend** | Flutter Web (Dart) | Cross-platform web UI |
| **Backend** | FastAPI (Python) | RESTful API server |
| **Database** | PostgreSQL | Relational data storage |
| **Auth** | JWT (JSON Web Tokens) | Stateless authentication |
| **ORM** | SQLAlchemy + Alembic | DB models & migrations |
| **State Management** | Riverpod | Flutter state management |
| **HTTP Client** | Dio | API calls from Flutter |
| **Routing** | go_router | Flutter web routing |
| **Charts** | fl_chart | Dashboard visualizations |
| **Deployment** | Railway | Backend + DB hosting |
| **Env Config** | python-dotenv | Backend env variables |

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     Flutter Web (Browser)                │
│  ┌──────────┐  ┌────────────┐  ┌──────────────────────┐ │
│  │  Auth    │  │  Projects  │  │  Dashboard / Tasks   │ │
│  │  Pages   │  │  & Members │  │  Kanban + Charts     │ │
│  └────┬─────┘  └─────┬──────┘  └──────────┬───────────┘ │
│       │               │                    │             │
│       └───────────────┼────────────────────┘             │
│                   Dio HTTP Client                        │
│              (Authorization: Bearer JWT)                 │
└───────────────────────┼─────────────────────────────────┘
                        │  HTTPS REST API
                        ▼
┌─────────────────────────────────────────────────────────┐
│                  FastAPI Backend (Railway)               │
│                                                         │
│  ┌─────────────────────────────────────────────────┐    │
│  │  Routers: /auth  /projects  /tasks  /dashboard  │    │
│  └─────────────────────────────────────────────────┘    │
│  ┌──────────────┐   ┌──────────────┐                    │
│  │  JWT Auth    │   │  RBAC Checks │                    │
│  │  Middleware  │   │  (Admin/Mbr) │                    │
│  └──────────────┘   └──────────────┘                    │
│  ┌─────────────────────────────────────────────────┐    │
│  │          SQLAlchemy ORM + Alembic                │    │
│  └─────────────────────────────────────────────────┘    │
└───────────────────────┼─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│              PostgreSQL Database (Railway)               │
│         users | projects | project_members | tasks       │
└─────────────────────────────────────────────────────────┘
```

---

## Features

### 🔐 Authentication
- Signup with Name, Email, Password
- Login returns a signed **JWT token**
- Token stored securely in Flutter (`flutter_secure_storage`)
- All API calls include `Authorization: Bearer <token>` header

### 📁 Project Management
- Any authenticated user can **create a project** (auto-assigned as Admin)
- Admin can **invite members** by email
- Admin can **remove members**
- Members only see **projects they belong to**

### ✅ Task Management
- Admin creates tasks with:
  - Title, Description
  - Due Date, Priority (`Low` / `Medium` / `High`)
  - Assign to a project member
- Status flow: `To Do` → `In Progress` → `Done`
- Members can **update status** of their assigned tasks
- Admins can edit/delete any task

### 📊 Dashboard
- Total tasks count
- Tasks breakdown by status (Pie chart)
- Tasks per user (Bar chart)
- Overdue tasks (highlighted alert list)

### 🔒 Role-Based Access Control (RBAC)
| Action | Admin | Member |
|---|:---:|:---:|
| Create/Delete Project | ✅ | ❌ |
| Add/Remove Members | ✅ | ❌ |
| Create/Delete Tasks | ✅ | ❌ |
| Assign Tasks | ✅ | ❌ |
| View Project & Tasks | ✅ | ✅ |
| Update Task Status | ✅ | ✅ (own tasks only) |
| View Dashboard | ✅ | ✅ |

---

## Database Schema

### `users`
| Column | Type | Notes |
|---|---|---|
| id | UUID / SERIAL | Primary Key |
| name | VARCHAR | Required |
| email | VARCHAR | Unique, Required |
| hashed_password | VARCHAR | bcrypt hashed |
| created_at | TIMESTAMP | Auto |

### `projects`
| Column | Type | Notes |
|---|---|---|
| id | SERIAL | Primary Key |
| name | VARCHAR | Required |
| description | TEXT | Optional |
| created_by | FK → users.id | Auto-assigned Admin |
| created_at | TIMESTAMP | Auto |

### `project_members` *(Junction Table)*
| Column | Type | Notes |
|---|---|---|
| id | SERIAL | Primary Key |
| project_id | FK → projects.id | Cascade Delete |
| user_id | FK → users.id | Cascade Delete |
| role | ENUM | `admin` \| `member` |

### `tasks`
| Column | Type | Notes |
|---|---|---|
| id | SERIAL | Primary Key |
| title | VARCHAR | Required |
| description | TEXT | Optional |
| due_date | DATE | Required |
| priority | ENUM | `low` \| `medium` \| `high` |
| status | ENUM | `todo` \| `in_progress` \| `done` |
| project_id | FK → projects.id | Cascade Delete |
| assigned_to | FK → users.id | Nullable |
| created_by | FK → users.id | |
| created_at | TIMESTAMP | Auto |
| updated_at | TIMESTAMP | Auto-update |

**Relationships:**
- `User` ↔ `Project` → Many-to-Many via `project_members`
- `Project` → `Task` → One-to-Many
- `User` → `Task` (assignee) → One-to-Many

---

## API Endpoints

### Auth — `/api/auth`
| Method | Endpoint | Description | Auth |
|---|---|---|---|
| POST | `/signup` | Register new user | ❌ |
| POST | `/login` | Login, returns JWT | ❌ |
| GET | `/me` | Get current user info | ✅ |

### Projects — `/api/projects`
| Method | Endpoint | Description | Role |
|---|---|---|---|
| GET | `/` | List user's projects | Any |
| POST | `/` | Create project | Any (→ Admin) |
| GET | `/{id}` | Project detail + members | Member+ |
| DELETE | `/{id}` | Delete project | Admin |
| POST | `/{id}/members` | Add member by email | Admin |
| DELETE | `/{id}/members/{uid}` | Remove member | Admin |

### Tasks — `/api/projects/{id}/tasks` & `/api/tasks`
| Method | Endpoint | Description | Role |
|---|---|---|---|
| GET | `/projects/{id}/tasks` | List tasks in project | Member+ |
| POST | `/projects/{id}/tasks` | Create task | Admin |
| GET | `/tasks/{id}` | Task detail | Member+ |
| PATCH | `/tasks/{id}` | Update task (status/assign) | Admin / Member* |
| DELETE | `/tasks/{id}` | Delete task | Admin |

> *Member can only update `status` of tasks assigned to them.

### Dashboard — `/api/dashboard`
| Method | Endpoint | Description | Auth |
|---|---|---|---|
| GET | `/stats` | Aggregated stats for current user | ✅ |

### Health — `/health`
| Method | Endpoint | Description |
|---|---|---|
| GET | `/health` | Server heartbeat (Railway keep-alive) |

---

## Project Structure

```
team-task-manager/
│
├── backend/                          ← FastAPI Application
│   ├── main.py                       ← App entry point, CORS, router registration
│   ├── database.py                   ← SQLAlchemy engine + session dependency
│   ├── models.py                     ← ORM models (User, Project, Task, etc.)
│   ├── schemas.py                    ← Pydantic request/response schemas
│   ├── auth.py                       ← JWT creation, decoding, password hashing
│   ├── dependencies.py               ← get_current_user(), get_admin_user()
│   ├── routers/
│   │   ├── auth.py                   ← /api/auth endpoints
│   │   ├── projects.py               ← /api/projects endpoints
│   │   ├── tasks.py                  ← /api/tasks endpoints
│   │   └── dashboard.py              ← /api/dashboard endpoints
│   ├── alembic/                      ← DB migration scripts
│   │   └── versions/
│   ├── alembic.ini
│   ├── requirements.txt
│   ├── Procfile                      ← Railway start command
│   └── .env                          ← Local environment variables (gitignored)
│
├── frontend/                         ← Flutter Web Application
│   ├── lib/
│   │   ├── main.dart                 ← App entry, theme, router setup
│   │   ├── core/
│   │   │   ├── constants.dart        ← API base URL, colors, strings
│   │   │   ├── theme.dart            ← App-wide dark theme definition
│   │   │   └── router.dart           ← go_router route definitions
│   │   ├── models/
│   │   │   ├── user.dart
│   │   │   ├── project.dart
│   │   │   └── task.dart
│   │   ├── services/
│   │   │   ├── api_service.dart      ← Dio client with JWT interceptor
│   │   │   ├── auth_service.dart     ← Login, signup, token storage
│   │   │   ├── project_service.dart
│   │   │   └── task_service.dart
│   │   ├── providers/                ← Riverpod state providers
│   │   │   ├── auth_provider.dart
│   │   │   ├── project_provider.dart
│   │   │   └── task_provider.dart
│   │   ├── pages/
│   │   │   ├── login_page.dart
│   │   │   ├── signup_page.dart
│   │   │   ├── dashboard_page.dart
│   │   │   ├── projects_page.dart
│   │   │   ├── project_detail_page.dart
│   │   │   └── task_detail_page.dart
│   │   └── widgets/
│   │       ├── task_card.dart
│   │       ├── kanban_column.dart
│   │       ├── stat_card.dart
│   │       ├── member_tile.dart
│   │       └── priority_badge.dart
│   ├── web/
│   │   └── index.html
│   └── pubspec.yaml
│
├── README.md
└── .gitignore
```

---

## Local Setup

### Prerequisites
- Python 3.11+
- Flutter SDK (with web enabled)
- PostgreSQL (local) or Railway DB URL

---

### Backend Setup

```bash
# 1. Navigate to backend
cd backend

# 2. Create virtual environment
python -m venv venv
venv\Scripts\activate        # Windows
# source venv/bin/activate   # Mac/Linux

# 3. Install dependencies
pip install -r requirements.txt

# 4. Create .env file (see Environment Variables section)

# 5. Run DB migrations
alembic upgrade head

# 6. Start the server
uvicorn main:app --reload --port 8000
```

Backend runs at: `http://localhost:8000`  
Interactive API docs: `http://localhost:8000/docs`

---

### Frontend Setup

```bash
# 1. Navigate to frontend
cd frontend

# 2. Get Flutter packages
flutter pub get

# 3. Update API base URL in lib/core/constants.dart
#    const String apiBaseUrl = 'http://localhost:8000';

# 4. Run Flutter web
flutter run -d chrome
```

Frontend runs at: `http://localhost:PORT`

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

> On Railway, these are set in the **Variables** tab of your service. `DATABASE_URL` is auto-injected by Railway when you add a PostgreSQL plugin.

### Frontend `constants.dart`

```dart
// lib/core/constants.dart
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000',
);
```

> Set `API_BASE_URL` as a Flutter build arg or hard-code the Railway backend URL before production build.

---

## Deployment (Railway)

### Step 1 — Push to GitHub
```bash
git init
git add .
git commit -m "initial commit"
git remote add origin https://github.com/YOUR_USERNAME/team-task-manager.git
git push -u origin main
```

### Step 2 — Deploy Backend on Railway
1. Go to [railway.app](https://railway.app) → **New Project**
2. Select **Deploy from GitHub Repo** → choose your repo
3. Set the **Root Directory** to `backend/`
4. Railway auto-detects Python → add a `Procfile`:
   ```
   web: alembic upgrade head && uvicorn main:app --host 0.0.0.0 --port $PORT
   ```
5. Add a **PostgreSQL** plugin → Railway auto-sets `DATABASE_URL`
6. Add remaining environment variables in the **Variables** tab
7. Deploy → get your public backend URL (e.g. `https://your-app.up.railway.app`)

### Step 3 — Build & Deploy Frontend on Railway
1. Update `apiBaseUrl` in `constants.dart` to your Railway backend URL
2. Build Flutter web:
   ```bash
   flutter build web --release
   ```
3. Add a new Railway service → **Static Site** or use a `Dockerfile`
4. Point it to the `frontend/build/web/` output directory
5. Deploy → get your public frontend URL

### Step 4 — Final Checks
- [ ] Signup and login work on live URL
- [ ] CORS on backend allows frontend Railway domain
- [ ] JWT auth headers are sent correctly
- [ ] Dashboard charts load properly
- [ ] Admin vs Member flows tested

---

## Backend Dependencies (`requirements.txt`)

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

## Flutter Dependencies (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  go_router: ^13.0.0          # Routing
  flutter_riverpod: ^2.5.0    # State management
  dio: ^5.4.3                  # HTTP client
  flutter_secure_storage: ^9.0.0  # Secure JWT storage
  fl_chart: ^0.67.0            # Charts
  intl: ^0.19.0                # Date formatting
  cached_network_image: ^3.3.1
```

---

## UI Pages Overview

| Page | Route | Description |
|---|---|---|
| Login | `/login` | Email + Password login form |
| Signup | `/signup` | Name, Email, Password registration |
| Dashboard | `/dashboard` | Stats cards + pie/bar charts + overdue list |
| Projects | `/projects` | Grid of all user projects with progress bars |
| Project Detail | `/projects/:id` | Kanban board (To Do / In Progress / Done) |
| Task Detail | `/tasks/:id` | Full task view with edit/status update |

---

## Demo Video

> 📹 A 2–5 minute walkthrough demonstrating:
> - User signup and login
> - Creating a project and inviting a member
> - Creating and assigning tasks
> - Updating task status (Member flow)
> - Dashboard analytics
> - Live deployment on Railway

---

## Author

**Abhinav Yadav**  
Full-Stack Developer  
[GitHub](https://github.com/YOUR_USERNAME) · [LinkedIn](https://linkedin.com/in/YOUR_PROFILE)

---

*Built as part of a full-stack coding assignment. Estimated effort: 8–12 hours.*
#   E t h a r a - A I - T a s k  
 