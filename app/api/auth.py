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
