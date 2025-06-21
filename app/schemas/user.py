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
