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
