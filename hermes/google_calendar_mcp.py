#!/usr/bin/env python3
"""Expose bounded event read/create/update tools for Hermes' primary Google Calendar."""

import json
import os
from pathlib import Path

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from mcp.server.fastmcp import FastMCP

from calendar_utils import create_body, update_body, validate_interval

SCOPE = "https://www.googleapis.com/auth/calendar.events"
TOKEN = Path(os.environ.get("HERMES_HOME", Path.home() / ".hermes")) / "google_calendar_token.json"
MAX_RESULTS = 100
mcp = FastMCP("google-calendar")


def _calendar_service():
    if not TOKEN.is_file():
        raise RuntimeError(f"Calendar is not authorized yet; run hermes-google-calendar-auth --client-secret PATH. Missing: {TOKEN}")
    credentials = Credentials.from_authorized_user_file(str(TOKEN))
    if set(credentials.scopes or []) != {SCOPE}:
        raise RuntimeError("Calendar token must have exactly the Calendar events scope; re-run the authorization command")
    if credentials.expired and credentials.refresh_token:
        credentials.refresh(Request())
        TOKEN.write_text(credentials.to_json(), encoding="utf-8")
        TOKEN.chmod(0o600)
    if not credentials.valid:
        raise RuntimeError("Calendar token is invalid; re-run the authorization command")
    return build("calendar", "v3", credentials=credentials, cache_discovery=False)


@mcp.tool()
def list_events(start: str, end: str, max_results: int = 50) -> str:
    """List primary-calendar events in a timezone-aware ISO 8601 interval (maximum 100)."""
    start_at, end_at = validate_interval(start, end, max_results, MAX_RESULTS)

    result = _calendar_service().events().list(
        calendarId="primary",
        timeMin=start_at.isoformat(),
        timeMax=end_at.isoformat(),
        maxResults=max_results,
        singleEvents=True,
        orderBy="startTime",
        fields="items(id,summary,description,location,start,end,status,htmlLink),nextPageToken",
    ).execute()
    return json.dumps(result, ensure_ascii=False)


@mcp.tool()
def create_event(summary: str, start: str, end: str, location: str = "", description: str = "") -> str:
    """Create an event on the primary calendar; start/end must include timezone offsets."""
    body = create_body(summary, start, end, location, description)
    result = _calendar_service().events().insert(calendarId="primary", body=body).execute()
    return json.dumps(result, ensure_ascii=False)


@mcp.tool()
def update_event(
    event_id: str,
    summary: str = "",
    start: str = "",
    end: str = "",
    location: str = "",
    description: str = "",
) -> str:
    """Update supplied fields on a primary-calendar event; provide start and end together."""
    body = update_body(event_id, summary, start, end, location, description)
    result = _calendar_service().events().patch(calendarId="primary", eventId=event_id, body=body).execute()
    return json.dumps(result, ensure_ascii=False)


if __name__ == "__main__":
    mcp.run()
