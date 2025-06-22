import workos
from sqlalchemy.orm import Session
from app.models.user import User
from app.schemas.user import UserCreate
from app.core.config import settings

# Initialize WorkOS client correctly
workos_client = workos.WorkOSClient(
    api_key=settings.workos_api_key,
    client_id=settings.workos_client_id
)

class AuthService:
    def get_auth_url(self) -> str:
        """Get WorkOS AuthKit URL"""
        authorization_url = workos_client.user_management.get_authorization_url(
            provider="authkit",
            redirect_uri=settings.workos_redirect_uri
        )
        return authorization_url
    
    async def handle_callback(self, code: str, db: Session):
        """Handle the OAuth callback"""
        try:
            # Exchange code for user
            profile_and_token = workos_client.user_management.authenticate_with_code(
                code=code
            )
            
            user_profile = profile_and_token.user
            
            # Find or create user in your database
            user = db.query(User).filter(User.workos_user_id == user_profile.id).first()
            if not user:
                user_data = UserCreate(email=user_profile.email, workos_user_id=user_profile.id)
                user = User(**user_data.dict())
                db.add(user)
                db.commit()
                db.refresh(user)
            
            return user, profile_and_token.access_token
        except Exception as e:
            raise Exception(f"Authentication failed: {str(e)}")