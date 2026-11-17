import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "hermes"))

from calendar_utils import create_body, update_body, validate_interval


class CalendarIntervalTests(unittest.TestCase):
    def test_accepts_timezone_aware_range(self):
        start, end = validate_interval("2026-11-17T09:00:00+01:00", "2026-11-17T10:00:00+01:00", 20, 100)
        self.assertEqual(start.utcoffset().total_seconds(), 3600)
        self.assertGreater(end, start)

    def test_rejects_timezone_naive_values(self):
        with self.assertRaisesRegex(ValueError, "timezone offset"):
            validate_interval("2026-11-17T09:00:00", "2026-11-17T10:00:00Z", 20, 100)

    def test_rejects_empty_or_reversed_ranges(self):
        with self.assertRaisesRegex(ValueError, "later than start"):
            validate_interval("2026-11-17T10:00:00Z", "2026-11-17T10:00:00Z", 20, 100)

    def test_caps_result_count(self):
        with self.assertRaisesRegex(ValueError, "between 1 and 100"):
            validate_interval("2026-11-17T09:00:00Z", "2026-11-17T10:00:00Z", 101, 100)

    def test_create_body_keeps_only_requested_fields(self):
        body = create_body(" Call ", "2026-11-17T09:00:00Z", "2026-11-17T10:00:00Z", "", "")
        self.assertEqual(body["summary"], "Call")
        self.assertNotIn("location", body)

    def test_update_requires_both_times_and_a_change(self):
        with self.assertRaisesRegex(ValueError, "provided together"):
            update_body("event", "", "2026-11-17T09:00:00Z", "", "", "")
        with self.assertRaisesRegex(ValueError, "at least one field"):
            update_body("event", "", "", "", "", "")


if __name__ == "__main__":
    unittest.main()
