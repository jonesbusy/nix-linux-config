#!/usr/bin/env python3
"""Reconcile authored cron definitions into the active Hermes profile."""

import json
from pathlib import Path
import sys


def sync_jobs(definitions_file: Path) -> bool:
    from hermes_constants import get_hermes_home
    from cron.job_definition import JOB_DEFINITION_FIELDS, import_job_definitions, merge_job_definition
    from cron.jobs import _jobs_lock, load_jobs, use_cron_store

    data = json.loads(definitions_file.read_text(encoding="utf-8"))
    definitions = data.get("jobs") if isinstance(data, dict) else None
    if not isinstance(definitions, list):
        raise ValueError("Cron definitions must have a top-level 'jobs' list")

    allowed_fields = JOB_DEFINITION_FIELDS | {"id", "repeat"}
    by_id = {}
    names = set()
    for job in definitions:
        if not isinstance(job, dict):
            raise ValueError("Each cron definition must be an object")
        unknown = set(job) - allowed_fields
        if unknown:
            raise ValueError(f"Unsupported cron definition fields: {', '.join(sorted(unknown))}")
        job_id = job.get("id")
        name = job.get("name")
        if not isinstance(job_id, str) or not job_id or not isinstance(name, str) or not name:
            raise ValueError("Each cron definition needs a non-empty id and name")
        if job_id in by_id or name in names:
            raise ValueError(f"Duplicate cron id or name: {name!r} ({job_id})")
        by_id[job_id] = job
        names.add(name)

        script = job.get("script")
        if script:
            script_dir = (get_hermes_home() / "scripts").resolve()
            script_path = (script_dir / script).resolve()
            try:
                script_path.relative_to(script_dir)
            except ValueError as exc:
                raise ValueError(f"Cron script escapes Hermes scripts directory: {script!r}") from exc
            if not script_path.is_file():
                raise ValueError(f"Cron script does not exist: {script_path}")

    home = get_hermes_home()
    with use_cron_store(home), _jobs_lock():
        current_jobs = load_jobs()
        current_by_id = {job.get("id"): job for job in current_jobs}
        current_by_name = {job.get("name"): job for job in current_jobs}
        changed = False
        import_definitions = {}
        for job_id, definition in by_id.items():
            existing = current_by_id.get(job_id)
            if existing is None:
                if definition["name"] in current_by_name:
                    raise ValueError(
                        f"Cron name {definition['name']!r} already belongs to id "
                        f"{current_by_name[definition['name']].get('id')}; refusing to duplicate it"
                    )
                import_definitions[job_id] = definition
                changed = True
                continue
            if existing.get("name") != definition["name"]:
                raise ValueError(
                    f"Cron id {job_id} belongs to {existing.get('name')!r}, "
                    f"not {definition['name']!r}; refusing to overwrite it"
                )

            effective = dict(definition)
            for field in JOB_DEFINITION_FIELDS:
                if field not in effective and field in existing:
                    effective[field] = existing[field]
            if "repeat" not in effective and "repeat" in existing:
                effective["repeat"] = {"times": existing["repeat"].get("times")}
            import_definitions[job_id] = effective
            if merge_job_definition(existing, effective) != existing:
                changed = True

        if not changed:
            return False
        import_job_definitions(
            import_definitions,
            paused_reason="Imported from the Nix-managed Hermes cron definitions; review, then resume.",
        )
        return True


def main() -> int:
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} DEFINITIONS.json", file=sys.stderr)
        return 2
    try:
        changed = sync_jobs(Path(sys.argv[1]))
    except Exception as exc:
        print(f"Hermes cron sync failed: {exc}", file=sys.stderr)
        return 1
    print("Hermes cron definitions synchronized." if changed else "Hermes cron definitions already current.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
