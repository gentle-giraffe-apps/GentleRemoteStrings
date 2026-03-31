from __future__ import annotations

import json
from pathlib import Path
from unittest.mock import patch

import pytest
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


class TestHealth:
    def test_returns_ok(self):
        response = client.get("/health")
        assert response.status_code == 200
        assert response.json() == {"status": "ok"}


class TestGetStrings:
    def test_returns_payload(self):
        response = client.get("/v1/strings")
        assert response.status_code == 200
        data = response.json()
        assert data["schemaVersion"] == 1
        assert data["locale"] == "en-US"
        assert "strings" in data
        assert "checkout.continue" in data["strings"]

    def test_returns_etag_header(self):
        response = client.get("/v1/strings")
        assert "etag" in response.headers
        etag = response.headers["etag"]
        assert etag.startswith('"') and etag.endswith('"')

    def test_returns_cache_control_header(self):
        response = client.get("/v1/strings")
        assert response.headers["cache-control"] == "public, no-cache"

    def test_conditional_request_returns_304(self):
        first = client.get("/v1/strings")
        etag = first.headers["etag"]

        second = client.get("/v1/strings", headers={"If-None-Match": etag})
        assert second.status_code == 304

    def test_conditional_request_stale_etag_returns_200(self):
        response = client.get(
            "/v1/strings", headers={"If-None-Match": '"stale-etag"'}
        )
        assert response.status_code == 200

    def test_accessibility_optional(self):
        response = client.get("/v1/strings")
        data = response.json()
        # profile.edit has no accessibility in the content file
        entry = data["strings"]["profile.edit"]
        assert "accessibility" not in entry or entry["accessibility"] is None

    def test_missing_content_file_returns_503(self):
        def bad_path(locale="en-US"):
            raise FileNotFoundError("no file")

        with patch("app.main._load_payload", side_effect=bad_path):
            response = client.get("/v1/strings")
            assert response.status_code == 503

    def test_invalid_json_returns_503(self):
        def bad_json(locale="en-US"):
            raise json.JSONDecodeError("bad", "", 0)

        with patch("app.main._load_payload", side_effect=bad_json):
            response = client.get("/v1/strings")
            assert response.status_code == 503
