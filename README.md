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
