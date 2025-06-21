#!/bin/bash

# FastAPI Railway Test Project Setup Script
echo "🚀 Setting up FastAPI Railway test project..."

# Create main project structure
mkdir -p app/{core,models,schemas,api,services}
mkdir -p alembic/versions
mkdir -p tests

# Create __init__.py files
touch app/__init__.py
touch app/core/__init__.py
touch app/models/__init__.py
touch app/schemas/__init__.py
touch app/api/__init__.py
touch app/services/__init__.py
touch tests/__init__.py

# Create main FastAPI app
cat > app/main.py << 'EOF'
from fastapi import FastAPI
from app.api import auth
from app.core.database import engine
from app.models import user

# Create tables
user.Base.metadata.create_all(bind=engine)

app = FastAPI(title="Fitness Test API", version="0.1.0")

# Health check
@app.get("/health")
async def health_check():
    return {"status": "healthy"}

# Include routers
app.include_router(auth.router, prefix="/auth", tags=["auth"])

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
EOF

# Create config
cat > app/core/config.py << 'EOF'
from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    database_url: str = "postgresql://user:password@localhost/fitness_test"
    workos_api_key: str = ""
    workos_client_id: str = ""
    secret_key: str = "your-secret-key-change-in-production"
    environment: str = "development"
    
    class Config:
        env_file = ".env"

settings = Settings()
EOF

# Create database setup
cat > app/core/database.py << 'EOF'
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from app.core.config import settings

engine = create_engine(settings.database_url)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
EOF

# Create dependencies
cat > app/core/deps.py << 'EOF'
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.services.auth_service import AuthService

security = HTTPBearer()

async def get_current_user(
    token: str = Depends(security),
    db: Session = Depends(get_db)
):
    auth_service = AuthService()
    user = await auth_service.verify_token(token.credentials, db)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials"
        )
    return user
EOF

# Create User model
cat > app/models/user.py << 'EOF'
from sqlalchemy import Column, String, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
import uuid
from app.core.database import Base

class User(Base):
    __tablename__ = "users"
    
    user_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String, unique=True, index=True, nullable=False)
    workos_user_id = Column(String, unique=True, index=True, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
EOF

# Create User schemas
cat > app/schemas/user.py << 'EOF'
from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional
import uuid

class UserBase(BaseModel):
    email: EmailStr

class UserCreate(UserBase):
    workos_user_id: str

class UserResponse(UserBase):
    user_id: uuid.UUID
    workos_user_id: str
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True
EOF

# Create auth service
cat > app/services/auth_service.py << 'EOF'
import workos
from sqlalchemy.orm import Session
from app.models.user import User
from app.schemas.user import UserCreate
from app.core.config import settings

class AuthService:
    def __init__(self):
        workos.api_key = settings.workos_api_key
        workos.client_id = settings.workos_client_id
    
    async def verify_token(self, token: str, db: Session) -> User:
        """Verify WorkOS token and return user"""
        try:
            # Verify with WorkOS
            profile = workos.sso.get_profile_and_token(token)
            workos_user_id = profile.profile.id
            email = profile.profile.email
            
            # Find or create user
            user = db.query(User).filter(User.workos_user_id == workos_user_id).first()
            if not user:
                user_data = UserCreate(email=email, workos_user_id=workos_user_id)
                user = User(**user_data.dict())
                db.add(user)
                db.commit()
                db.refresh(user)
            
            return user
        except Exception:
            return None
    
    def get_auth_url(self, redirect_uri: str) -> str:
        """Get WorkOS authentication URL"""
        return workos.sso.get_authorization_url(
            redirect_uri=redirect_uri,
            client_id=settings.workos_client_id
        )
EOF

# Create auth endpoints
cat > app/api/auth.py << 'EOF'
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.deps import get_db, get_current_user
from app.services.auth_service import AuthService
from app.schemas.user import UserResponse

router = APIRouter()

@router.get("/login-url")
async def get_login_url():
    """Get WorkOS login URL"""
    auth_service = AuthService()
    login_url = auth_service.get_auth_url("http://localhost:8000/auth/callback")
    return {"login_url": login_url}

@router.post("/callback")
async def auth_callback(code: str, db: Session = Depends(get_db)):
    """Handle WorkOS auth callback"""
    # This would handle the OAuth callback
    # Simplified for testing
    return {"message": "Auth callback received", "code": code}

@router.get("/me", response_model=UserResponse)
async def get_current_user_info(current_user = Depends(get_current_user)):
    """Get current user information"""
    return current_user
EOF

# Create pyproject.toml
cat > pyproject.toml << 'EOF'
[project]
name = "fitness-test-api"
version = "0.1.0"
description = "FastAPI Railway deployment test"
dependencies = [
    "fastapi>=0.104.0",
    "uvicorn[standard]>=0.24.0",
    "sqlalchemy>=2.0.0",
    "alembic>=1.12.0",
    "psycopg2-binary>=2.9.0",
    "pydantic>=2.5.0",
    "pydantic-settings>=2.1.0",
    "workos>=2.0.0",
    "python-multipart>=0.0.6"
]

[project.optional-dependencies]
dev = [
    "pytest>=7.0.0",
    "pytest-asyncio>=0.21.0",
    "pre-commit>=3.0.0",
    "httpx>=0.25.0"
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
EOF

# Create Dockerfile
cat > Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app

# Install uv
RUN pip install uv

# Copy dependency files
COPY pyproject.toml ./

# Install dependencies
RUN uv pip install --system -e .

# Copy application code
COPY . .

# Expose port
EXPOSE 8000

# Run migrations and start server
CMD ["sh", "-c", "alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port $PORT"]
EOF

# Create railway.toml
cat > railway.toml << 'EOF'
[build]
builder = "dockerfile"

[deploy]
startCommand = "alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port $PORT"
healthcheckPath = "/health"
healthcheckTimeout = 30

[environments.production]
variables = { }

[environments.staging]
variables = { }
EOF

# Create alembic.ini
cat > alembic.ini << 'EOF'
[alembic]
script_location = alembic
prepend_sys_path = .
version_path_separator = os
sqlalchemy.url = 

[post_write_hooks]

[loggers]
keys = root,sqlalchemy,alembic

[handlers]
keys = console

[formatters]
keys = generic

[logger_root]
level = WARN
handlers = console
qualname =

[logger_sqlalchemy]
level = WARN
handlers =
qualname = sqlalchemy.engine

[logger_alembic]
level = INFO
handlers =
qualname = alembic

[handler_console]
class = StreamHandler
args = (sys.stderr,)
level = NOTSET
formatter = generic

[formatter_generic]
format = %(levelname)-5.5s [%(name)s] %(message)s
datefmt = %H:%M:%S
EOF

# Create alembic env.py
cat > alembic/env.py << 'EOF'
from logging.config import fileConfig
from sqlalchemy import engine_from_config, pool
from alembic import context
import os
import sys

# Add the app directory to Python path
sys.path.append(os.path.dirname(os.path.dirname(__file__)))

from app.core.config import settings
from app.models.user import Base

config = context.config
config.set_main_option("sqlalchemy.url", settings.database_url)

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata

def run_migrations_offline() -> None:
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()

def run_migrations_online() -> None:
    connectable = engine_from_config(
        config.get_section(config.config_ini_section),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection, target_metadata=target_metadata
        )

        with context.begin_transaction():
            context.run_migrations()

if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
EOF

# Create script template
cat > alembic/script.py.mako << 'EOF'
"""${message}

Revision ID: ${up_revision}
Revises: ${down_revision | comma,n}
Create Date: ${create_date}

"""
from alembic import op
import sqlalchemy as sa
${imports if imports else ""}

# revision identifiers, used by Alembic.
revision = ${repr(up_revision)}
down_revision = ${repr(down_revision)}
branch_labels = ${repr(branch_labels)}
depends_on = ${repr(depends_on)}


def upgrade() -> None:
    ${upgrades if upgrades else "pass"}


def downgrade() -> None:
    ${downgrades if downgrades else "pass"}
EOF

# Create .env template
cat > .env.example << 'EOF'
DATABASE_URL=postgresql://user:password@localhost/fitness_test
WORKOS_API_KEY=your_workos_api_key
WORKOS_CLIENT_ID=your_workos_client_id
SECRET_KEY=your-secret-key-change-in-production
ENVIRONMENT=development
EOF

# Create .gitignore
cat > .gitignore << 'EOF'
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

.env
.venv
env/
venv/
ENV/
env.bak/
venv.bak/

.pytest_cache/
.coverage
htmlcov/

.DS_Store
.vscode/
.idea/
EOF

# Create README
cat > README.md << 'EOF'
# FastAPI Railway Test Project

Testing deployment pipeline with FastAPI, PostgreSQL, and Railway.

## Setup

1. Install uv: `pip install uv`
2. Create virtual environment: `uv venv`
3. Activate: `source .venv/bin/activate` (Linux/Mac) or `.venv\Scripts\activate` (Windows)
4. Install dependencies: `uv pip install -e .`
5. Copy `.env.example` to `.env` and fill in values
6. Run migrations: `alembic upgrade head`
7. Start server: `uvicorn app.main:app --reload`

## Railway Deployment

1. Connect GitHub repo to Railway
2. Add PostgreSQL service
3. Set environment variables
4. Deploy!

## Testing Migration Workflow

1. Create migration: `alembic revision --autogenerate -m "Description"`
2. Review generated migration
3. Apply: `alembic upgrade head`
4. Test rollback: `alembic downgrade -1`
EOF

echo "✅ Project structure created successfully!"
echo "🔧 Next steps:"
echo "1. cd into your project directory"
echo "2. Copy .env.example to .env and configure"
echo "3. Run: uv venv && source .venv/bin/activate"
echo "4. Run: uv pip install -e ."
echo "5. Run: alembic revision --autogenerate -m 'Initial users table'"
echo "6. Run: alembic upgrade head"
echo "7. Run: uvicorn app.main:app --reload"