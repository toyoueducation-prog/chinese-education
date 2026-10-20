from typing import Any, Dict, List, Optional, Tuple, Iterable
from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_name: str = "Chinese Education Analytics API"
    api_prefix: str = "/api"
    database_url: str = "postgresql+psycopg2://ce:cepass@db:5432/chinese_education"
    # Local/dev fallback used by pytest when Postgres is unavailable.
    sqlite_fallback_url: str = "sqlite+pysqlite:///:memory:"
    use_sqlite: bool = False

    jwt_secret: str = "change-me-in-production"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 60 * 24 * 7

    # LLM insight provider (DashScope / Qwen / OpenAI-compatible). Empty = rule-based only.
    llm_api_base: str = ""
    llm_api_key: str = ""
    llm_model: str = "qwen-plus"
    llm_enabled: bool = False


@lru_cache
def get_settings() -> Settings:
    return Settings()
