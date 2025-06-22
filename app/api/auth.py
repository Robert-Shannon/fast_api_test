from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import RedirectResponse
from sqlalchemy.orm import Session
from app.core.deps import get_db
from app.services.auth_service import AuthService

router = APIRouter()

@router.get("/login")
async def initiate_login():
    """Redirect user to WorkOS AuthKit"""
    auth_service = AuthService()
    login_url = auth_service.get_auth_url()
    return RedirectResponse(url=login_url)

@router.get("/callback")
async def auth_callback(code: str, db: Session = Depends(get_db)):
    """Handle WorkOS callback and authenticate user"""
    auth_service = AuthService()
    try:
        user, access_token = await auth_service.handle_callback(code, db)
        
        # Redirect back to the iOS app with the auth data
        redirect_url = f"zenith-testing://auth/callback?access_token={access_token}&user_email={user.email}"
        return RedirectResponse(url=redirect_url)
        
    except Exception as e:
        # Redirect to app with error
        error_url = f"zenith-testing://auth/callback?error={str(e)}"
        return RedirectResponse(url=error_url)