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
