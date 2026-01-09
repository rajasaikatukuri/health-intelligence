"""Configuration for Health Intelligence Platform."""
from pydantic_settings import BaseSettings
from typing import Optional
import os


class Settings(BaseSettings):
    """Application settings."""
    
    # AWS Configuration
    aws_region: str = "us-east-2"
    athena_database: str = "health_data_lake"
    athena_workgroup: str = "health-data-tenant-queries"
    s3_bucket: str = "health-data-lake-640768199126-us-east-2"
    s3_results_bucket: str = "health-data-lake-640768199126-us-east-2"
    s3_results_prefix: str = "athena-results/"
    
    # LLM Configuration
    llm_provider: str = "ollama"  # "ollama" or "openai"
    ollama_base_url: str = "http://localhost:11434"
    ollama_model: str = "llama3"  # or "mistral"
    openai_api_key: Optional[str] = None
    openai_model: str = "gpt-4"
    
    # JWT Configuration
    jwt_secret: str = "dev-secret-change-in-production"
    jwt_algorithm: str = "HS256"
    jwt_expiration_hours: int = 24
    
    # Redis Configuration (for caching)
    redis_host: str = "localhost"
    redis_port: int = 6379
    redis_db: int = 0
    redis_enabled: bool = False  # Set to True if Redis is available
    
    # Query Configuration
    query_cache_ttl: int = 3600  # 1 hour
    max_query_timeout: int = 300  # 5 minutes
    default_lookback_days: int = 30
    
    # Server Configuration
    host: str = "0.0.0.0"
    port: int = int(os.getenv("PORT", "8000"))  # Render provides PORT env var
    debug: bool = False
    
    # CORS Configuration
    cors_origins: str = os.getenv("CORS_ORIGINS", "*")  # Comma-separated list of allowed origins
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = False
        # Allow environment variables to override defaults
        env_prefix = ""  # No prefix needed, use exact names


settings = Settings()

