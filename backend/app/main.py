from __future__ import annotations

import hashlib
import json
from pathlib import Path

from fastapi import FastAPI, Request, Response
from fastapi.responses import JSONResponse

from .models import RemoteStringsPayload

CONTENT_DIR = Path(__file__).resolve().parent.parent / "content"

app = FastAPI(
    title="GentleRemoteStrings",
    description="Lightweight remote strings backend",
    version="1.0.0",
)


def _load_payload(locale: str = "en-US") -> tuple[dict, str]:
    """Load the strings file and compute its ETag."""
    path = CONTENT_DIR / f"{locale}.json"
    raw = path.read_text()
    data = json.loads(raw)
    # Validate against the Pydantic model
    RemoteStringsPayload(**data)
    etag = hashlib.sha256(raw.encode()).hexdigest()
    return data, f'"{etag}"'


@app.get("/health")
async def health() -> dict:
    return {"status": "ok"}


@app.get("/v1/strings")
async def get_strings(request: Request) -> Response:
    try:
        data, etag = _load_payload()
    except FileNotFoundError:
        return JSONResponse(
            status_code=503,
            content={"error": "Content file not found"},
        )
    except (json.JSONDecodeError, Exception) as exc:
        return JSONResponse(
            status_code=503,
            content={"error": f"Invalid content: {exc}"},
        )

    # Conditional request — return 304 if client already has this version
    if_none_match = request.headers.get("if-none-match")
    if if_none_match and if_none_match == etag:
        return Response(status_code=304, headers={"ETag": etag})

    return JSONResponse(
        content=data,
        headers={
            "ETag": etag,
            "Cache-Control": "public, no-cache",
        },
    )
