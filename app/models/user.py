from sqlalchemy import Column, String, DateTime, Text, Boolean
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
    
    # Garmin OAuth data
    garmin_access_token = Column(Text, nullable=True)
    garmin_refresh_token = Column(Text, nullable=True)
    garmin_token_expires_at = Column(DateTime(timezone=True), nullable=True)
    garmin_user_id = Column(String, nullable=True)  # Garmin's internal user ID
    garmin_connected = Column(Boolean, default=False)
    garmin_connected_at = Column(DateTime(timezone=True), nullable=True)
    garmin_scopes = Column(String, nullable=True)  # Store as comma-separated or JSON string