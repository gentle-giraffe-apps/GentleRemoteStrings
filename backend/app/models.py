from __future__ import annotations

from pydantic import BaseModel, Field


class AccessibilityContent(BaseModel):
    label: str | None = None
    hint: str | None = None


class RemoteStringEntry(BaseModel):
    text: str
    accessibility: AccessibilityContent | None = None


class RemoteStringsPayload(BaseModel):
    schema_version: int = Field(alias="schemaVersion")
    locale: str
    generated_at: str = Field(alias="generatedAt")
    strings: dict[str, RemoteStringEntry]

    model_config = {"populate_by_name": True}
