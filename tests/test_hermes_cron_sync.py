import importlib.util
import json
import os
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SYNC_PATH = ROOT / "hermes/scripts/sync-cron-jobs.py"
DEFINITIONS_PATH = ROOT / "hermes/cron/jobs.json"

spec = importlib.util.spec_from_file_location("sync_cron_jobs", SYNC_PATH)
sync_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sync_module)


class HermesCronSyncTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name) / ".hermes"
        (self.home / "scripts").mkdir(parents=True)
        (self.home / "scripts/pi-memory-hourly-backup.sh").write_text("#!/bin/sh\nexit 0\n")
        previous_home = os.environ.get("HERMES_HOME")
        os.environ["HERMES_HOME"] = str(self.home)
        self.addCleanup(self.restore_hermes_home, previous_home)

    @staticmethod
    def restore_hermes_home(previous_home):
        if previous_home is None:
            os.environ.pop("HERMES_HOME", None)
        else:
            os.environ["HERMES_HOME"] = previous_home

    def test_existing_job_converges_without_resetting_runtime_state(self):
        from cron.jobs import parse_schedule, save_jobs, use_cron_store, load_jobs

        runtime_fields = {
            "last_run_at": "2026-01-02T03:04:05+00:00",
            "last_status": "ok",
            "failure_streak": 2,
            "next_run_at": "2026-01-02T04:00:00+00:00",
        }
        job = {
            "id": "d9392f145e03",
            "name": "Hourly Pi memory GitHub backup",
            "prompt": "Run the configured script-only backup for /home/valentin/.pi/agent/memory. The script commits pending memory changes and pushes them to the repository's configured GitHub origin; report any script failure clearly.",
            "skills": [],
            "script": "old-backup.sh",
            "no_agent": True,
            "schedule": parse_schedule("every 60m"),
            "schedule_display": "every 60m",
            "repeat": {"times": None, "completed": 7},
            "deliver": "local",
            "skill": None,
            "model": None,
            "provider": None,
            "base_url": None,
            "monitor_script": None,
            "monitor_url": None,
            "context_from": None,
            "origin": {"platform": "local", "chat_id": "runtime-only"},
            "enabled_toolsets": None,
            "workdir": None,
            "enabled": True,
            "state": "scheduled",
            "created_at": "2025-01-01T00:00:00+00:00",
            **runtime_fields,
        }
        with use_cron_store(self.home):
            save_jobs([job], replace=True)

        self.assertTrue(sync_module.sync_jobs(DEFINITIONS_PATH))
        with use_cron_store(self.home):
            after_first = load_jobs()[0]
        self.assertEqual(after_first["script"], "pi-memory-hourly-backup.sh")
        self.assertTrue(after_first["enabled"])
        self.assertEqual(after_first["state"], "scheduled")
        self.assertEqual(after_first["repeat"]["completed"], 7)
        for field, value in runtime_fields.items():
            self.assertEqual(after_first[field], value)
        self.assertEqual(after_first["origin"], {"platform": "local", "chat_id": "runtime-only"})
        for field in ("skill", "model", "provider", "base_url", "monitor_script", "monitor_url", "context_from"):
            self.assertIsNone(after_first[field])

        self.assertFalse(sync_module.sync_jobs(DEFINITIONS_PATH))
        with use_cron_store(self.home):
            self.assertEqual(load_jobs()[0], after_first)

    def test_new_definition_is_added_paused(self):
        from cron.jobs import load_jobs, use_cron_store

        definitions = json.loads(DEFINITIONS_PATH.read_text())
        definitions["jobs"].append({
            "id": "future-job-001",
            "name": "Future job",
            "prompt": "Probe",
            "script": "pi-memory-hourly-backup.sh",
            "no_agent": True,
            "schedule": "every 60m",
            "schedule_display": "every 60m",
            "deliver": "local",
        })
        path = self.home / "definitions.json"
        path.write_text(json.dumps(definitions))

        self.assertTrue(sync_module.sync_jobs(path))
        with use_cron_store(self.home):
            jobs = {job["id"]: job for job in load_jobs()}
        self.assertEqual(jobs["future-job-001"]["state"], "paused")
        self.assertFalse(jobs["future-job-001"]["enabled"])
        self.assertFalse(jobs["d9392f145e03"]["enabled"])

    def test_conflicting_id_fails_closed(self):
        from cron.jobs import save_jobs, use_cron_store

        with use_cron_store(self.home):
            save_jobs([{"id": "d9392f145e03", "name": "Unrelated job"}], replace=True)
        with self.assertRaisesRegex(ValueError, "refusing to overwrite"):
            sync_module.sync_jobs(DEFINITIONS_PATH)


if __name__ == "__main__":
    unittest.main()
