from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    supabase_url: str
    supabase_anon_key: str
    supabase_service_role_key: str
    cors_origins: str = "https://aup-viltrumites.onrender.com,http://localhost:5173,http://localhost:3000,http://127.0.0.1:5173"
    port: int = 8001
    ngrok_url: str = ""

    model_config = SettingsConfigDict(
        env_file=("../assets/.env", ".env"),
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    @property
    def cors_origin_list(self) -> list[str]:
        if self.cors_origins.strip() == "*":
            return ["*"]
        origins = [o.strip() for o in self.cors_origins.split(",") if o.strip()]
        if self.ngrok_url.strip() and self.ngrok_url.strip() not in origins:
            origins.append(self.ngrok_url.strip())
        return origins


@lru_cache
def get_settings() -> Settings:
    return Settings()
