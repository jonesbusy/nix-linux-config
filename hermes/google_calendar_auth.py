#!/usr/bin/env python3
"""Authorize Hermes for event read/write access to the primary Google Calendar."""

import argparse
import json
import os
import shutil
from pathlib import Path

from google_auth_oauthlib.flow import InstalledAppFlow

SCOPE = "https://www.googleapis.com/auth/calendar.events"
HERMES_HOME = Path(os.environ.get("HERMES_HOME", Path.home() / ".hermes"))
CLIENT_SECRET = HERMES_HOME / "google_calendar_client_secret.json"
TOKEN = HERMES_HOME / "google_calendar_token.json"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--client-secret", required=True, help="Downloaded OAuth Desktop client JSON")
    args = parser.parse_args()

    source = Path(args.client_secret).expanduser().resolve(strict=True)
    payload = json.loads(source.read_text(encoding="utf-8"))
    if "installed" not in payload:
        parser.error("Expected a Google OAuth Desktop app client JSON (installed client)")

    HERMES_HOME.mkdir(mode=0o700, parents=True, exist_ok=True)
    shutil.copyfile(source, CLIENT_SECRET)
    CLIENT_SECRET.chmod(0o600)

    flow = InstalledAppFlow.from_client_secrets_file(str(CLIENT_SECRET), scopes=[SCOPE])
    credentials = flow.run_local_server(port=0, access_type="offline", prompt="consent")
    token_data = json.loads(credentials.to_json())
    token_data["scopes"] = [SCOPE]
    temp = TOKEN.with_suffix(".json.tmp")
    temp.write_text(json.dumps(token_data, indent=2), encoding="utf-8")
    temp.chmod(0o600)
    temp.replace(TOKEN)
    print(f"Calendar authorization saved to {TOKEN}")


if __name__ == "__main__":
    main()
