from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    database_url: str = "sqlite:///./test.db"
    workos_api_key: str = ""
    workos_client_id: str = ""
    workos_redirect_uri: str = ""
    secret_key: str = "your-secret-key-change-in-production"
    environment: str = "development"
    
    class Config:
        env_file = ".env"

settings = Settings()