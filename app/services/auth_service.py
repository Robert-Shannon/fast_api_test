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
