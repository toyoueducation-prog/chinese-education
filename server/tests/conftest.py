import os
import pytest
from fastapi.testclient import TestClient

os.environ["USE_SQLITE"] = "true"
os.environ["JWT_SECRET"] = "test-secret"
os.environ["LLM_ENABLED"] = "false"

from app.config import get_settings
get_settings.cache_clear()

from app import models  # noqa: F401
from app.database import Base, get_engine, init_db
from app.main import create_app


@pytest.fixture()
def client():
    engine = get_engine()
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    app = create_app()
    with TestClient(app) as c:
        yield c
