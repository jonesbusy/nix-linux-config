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
        (self.home / "scripts/pi-memory-backup.sh").write_text("#!/bin/sh\nexit 0\n")
        (self.home / "scripts/obsidian-vault-backup.sh").write_text("#!/bin/sh\nexit 0\n")
        (self.home / "scripts/hermes-private-drift-backup.sh").write_text("#!/bin/sh\nexit 0\n")
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
        }
        job = {
            "id": "pi-memory-backup",
            "name": "Pi memory GitHub backup",
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
            after_first = {job["id"]: job for job in load_jobs()}
        pi_job = after_first["pi-memory-backup"]
        self.assertEqual(pi_job["script"], "pi-memory-backup.sh")
        self.assertTrue(pi_job["enabled"])
        self.assertEqual(pi_job["state"], "scheduled")
        self.assertEqual(pi_job["repeat"]["completed"], 7)
        for field, value in runtime_fields.items():
            self.assertEqual(pi_job[field], value)
        self.assertEqual(pi_job["origin"], {"platform": "local", "chat_id": "runtime-only"})
        for field in ("skill", "model", "provider", "base_url", "monitor_script", "monitor_url", "context_from"):
            self.assertIsNone(pi_job[field])
        self.assertFalse(after_first["obsidian-vault-backup"]["enabled"])

        self.assertFalse(sync_module.sync_jobs(DEFINITIONS_PATH))
        with use_cron_store(self.home):
            self.assertEqual({job["id"]: job for job in load_jobs()}, after_first)

    def test_new_definition_is_added_paused(self):
        from cron.jobs import load_jobs, use_cron_store

        definitions = json.loads(DEFINITIONS_PATH.read_text())
        definitions["jobs"].append({
            "id": "future-job-001",
            "name": "Future job",
            "prompt": "Probe",
            "script": "pi-memory-backup.sh",
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
        self.assertFalse(jobs["pi-memory-backup"]["enabled"])

    def test_gmail_ingestion_definition_uses_generic_configuration(self):
        definitions = json.loads(DEFINITIONS_PATH.read_text())
        job = next(item for item in definitions["jobs"] if item["id"] == "gmail-obsidian-ingest")
        self.assertIn("OBSIDIAN_VAULT_PATH", job["prompt"])
        self.assertRegex(job["id"], r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
        self.assertIn("gmail-to-obsidian-ingest", job["skills"])
        self.assertIn("productivity/google-workspace", job["skills"])
        self.assertEqual(job["skill"], "productivity/google-workspace")
        self.assertNotIn("google-workspace", job["skills"])
        self.assertNotRegex(job["prompt"], r"/home/[^/]+")

    def test_private_drift_backup_is_script_only_and_imports_paused(self):
        from cron.jobs import load_jobs, use_cron_store

        definitions = json.loads(DEFINITIONS_PATH.read_text())
        job = next(item for item in definitions["jobs"] if item["id"] == "hermes-private-drift-backup")
        self.assertEqual(job["script"], "hermes-private-drift-backup.sh")
        self.assertTrue(job["no_agent"])
        self.assertEqual(job["skills"], [])
        self.assertEqual(job["schedule"], "every 15m")
        wrapper = (ROOT / "hermes/scripts/hermes-private-drift-backup.sh").read_text()
        self.assertIn("backup_skills.py", wrapper)
        self.assertIn("--apply", wrapper)
        self.assertNotIn("git add -A", wrapper)

        self.assertTrue(sync_module.sync_jobs(DEFINITIONS_PATH))
        with use_cron_store(self.home):
            imported = next(job for job in load_jobs() if job["id"] == "hermes-private-drift-backup")
        self.assertEqual(imported["state"], "paused")
        self.assertFalse(imported["enabled"])

    def test_drive_ingestion_definition_is_review_gated_and_routes_unknowns_safely(self):
        from cron.jobs import load_jobs, use_cron_store

        definitions = json.loads(DEFINITIONS_PATH.read_text())
        job = next(item for item in definitions["jobs"] if item["id"] == "drive-obsidian-ingest")
        prompt = job["prompt"]
        self.assertEqual(job["schedule"], "every 60m")
        self.assertEqual(
            job["skills"],
            ["productivity/google-workspace", "note-taking/obsidian", "drive-document-ingestion"],
        )
        self.assertEqual(job["skill"], "productivity/google-workspace")
        self.assertIn("`Unknown`", prompt)
        self.assertNotIn("`unknown`", prompt)
        self.assertIn("do not create new categories or a tax folder/tree", prompt.lower())
        prompt_lower = prompt.lower()
        for required in (
            "`ingest`",
            "obsidian_vault_path",
            "unknown",
            "log.md",
            "pdftotext",
            "read back",
            "configured hermes model receives the extracted text",
            "capabilities.canmoveitemwithindrive",
        ):
            self.assertIn(required, prompt_lower)
        self.assertNotRegex(prompt, r"/home/[^/]+")
        self.assertIn("do not delete", prompt_lower)
        self.assertIn("do not share", prompt_lower)
        hermes_module = (ROOT / "home/agents/hermes.nix").read_text()
        self.assertIn("pkgs.poppler-utils", hermes_module)

        self.assertTrue(sync_module.sync_jobs(DEFINITIONS_PATH))
        with use_cron_store(self.home):
            imported = next(item for item in load_jobs() if item["id"] == "drive-obsidian-ingest")
        self.assertEqual(imported["state"], "paused")
        self.assertFalse(imported["enabled"])

    def test_conflicting_id_fails_closed(self):
        from cron.jobs import save_jobs, use_cron_store

        with use_cron_store(self.home):
            save_jobs([{"id": "pi-memory-backup", "name": "Unrelated job"}], replace=True)
        with self.assertRaisesRegex(ValueError, "refusing to overwrite"):
            sync_module.sync_jobs(DEFINITIONS_PATH)


if __name__ == "__main__":
    unittest.main()
