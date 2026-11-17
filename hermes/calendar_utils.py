from datetime import datetime


def timestamp(value: str) -> datetime:
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as exc:
        raise ValueError("Use an ISO 8601 date-time with a timezone offset") from exc
    if parsed.tzinfo is None or parsed.utcoffset() is None:
        raise ValueError("Use an ISO 8601 date-time with a timezone offset")
    return parsed


def validate_interval(start: str, end: str, max_results: int, maximum: int) -> tuple[datetime, datetime]:
    start_at, end_at = timestamp(start), timestamp(end)
    if end_at <= start_at:
        raise ValueError("end must be later than start")
    if not 1 <= max_results <= maximum:
        raise ValueError(f"max_results must be between 1 and {maximum}")
    return start_at, end_at


def create_body(summary: str, start: str, end: str, location: str, description: str) -> dict:
    start_at, end_at = validate_interval(start, end, 1, 100)
    if not summary.strip():
        raise ValueError("summary must not be empty")
    body = {
        "summary": summary.strip(),
        "start": {"dateTime": start_at.isoformat()},
        "end": {"dateTime": end_at.isoformat()},
    }
    if location:
        body["location"] = location
    if description:
        body["description"] = description
    return body


def update_body(event_id: str, summary: str, start: str, end: str, location: str, description: str) -> dict:
    if not event_id.strip():
        raise ValueError("event_id must not be empty")
    body = {}
    if summary:
        if not summary.strip():
            raise ValueError("summary must not be empty")
        body["summary"] = summary.strip()
    if bool(start) != bool(end):
        raise ValueError("start and end must be provided together")
    if start:
        start_at, end_at = validate_interval(start, end, 1, 100)
        body["start"] = {"dateTime": start_at.isoformat()}
        body["end"] = {"dateTime": end_at.isoformat()}
    if location:
        body["location"] = location
    if description:
        body["description"] = description
    if not body:
        raise ValueError("provide at least one field to update")
    return body
