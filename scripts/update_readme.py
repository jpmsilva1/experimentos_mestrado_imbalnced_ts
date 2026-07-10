#!/usr/bin/env python3
"""
update_readme.py — Regenerate the root README.md experiment table and progress summary.

Scans all experiments/NNN_*/README.md files, extracts the status badge from the
"Replication Status" line, and rebuilds the Experiment Index table and Progress Summary
in the root README.md.

Usage:
    python3 scripts/update_readme.py
    python3 scripts/update_readme.py --check   # Dry-run: print what would change
"""

import os
import re
import sys
from pathlib import Path
from datetime import date

REPO_ROOT = Path(__file__).resolve().parent.parent
EXPERIMENTS_DIR = REPO_ROOT / "experiments"
README_PATH = REPO_ROOT / "README.md"

# Status badge mapping
STATUS_MAP = {
    "⚪": "Pending",
    "🔵": "Setup",
    "🟡": "In Progress",
    "🟢": "Done",
    "🔴": "Blocked",
}


def extract_experiment_data(exp_dir: Path) -> dict | None:
    """Extract metadata from an experiment's README.md."""
    readme = exp_dir / "README.md"
    if not readme.exists():
        return None

    content = readme.read_text(encoding="utf-8")

    # Extract status
    status_match = re.search(r"Replication Status:\s*(⚪|🔵|🟡|🟢|🔴)\s*(\w+)", content)
    status_emoji = status_match.group(1) if status_match else "⚪"
    status_text = STATUS_MAP.get(status_emoji, "Pending")

    # Extract folder number and name
    folder_name = exp_dir.name
    num_match = re.match(r"(\d{3})_(.*)", folder_name)
    if not num_match:
        return None

    num = num_match.group(1)

    return {
        "num": num,
        "folder": folder_name,
        "status_emoji": status_emoji,
        "status_text": status_text,
    }


def rebuild_progress_summary(experiments: list[dict]) -> str:
    """Build the progress summary table."""
    counts = {"🟢": 0, "🟡": 0, "🔵": 0, "⚪": 0, "🔴": 0}
    for exp in experiments:
        emoji = exp["status_emoji"]
        if emoji in counts:
            counts[emoji] += 1

    total = sum(counts.values())
    lines = [
        "| Status | Count |",
        "|--------|-------|",
        f"| 🟢 Done | {counts['🟢']} |",
        f"| 🟡 In Progress | {counts['🟡']} |",
        f"| 🔵 Setup | {counts['🔵']} |",
        f"| ⚪ Pending | {counts['⚪']} |",
        f"| 🔴 Blocked | {counts['🔴']} |",
        f"| **Total** | **{total}** |",
    ]
    return "\n".join(lines)


def main():
    check_mode = "--check" in sys.argv

    # Discover experiments
    exp_dirs = sorted(
        [d for d in EXPERIMENTS_DIR.iterdir() if d.is_dir() and re.match(r"\d{3}_", d.name)]
    )

    experiments = []
    for d in exp_dirs:
        data = extract_experiment_data(d)
        if data:
            experiments.append(data)

    if not experiments:
        print("No experiments found. Nothing to update.")
        return

    # Read current README
    readme_content = README_PATH.read_text(encoding="utf-8")

    # Update progress summary
    new_summary = rebuild_progress_summary(experiments)
    summary_pattern = re.compile(
        r"(\| Status \| Count \|.*?\| \*\*Total\*\* \| \*\*\d+\*\* \|)",
        re.DOTALL,
    )
    if summary_pattern.search(readme_content):
        readme_content = summary_pattern.sub(new_summary, readme_content)

    # Update last updated date
    today = date.today().isoformat()
    readme_content = re.sub(
        r"\*\*Last updated\*\*: \d{4}-\d{2}-\d{2}",
        f"**Last updated**: {today}",
        readme_content,
    )

    # Update status in experiment index table rows
    for exp in experiments:
        # Match the row by experiment number at start of table row
        pattern = re.compile(
            rf"(\| {exp['num']} \|.*?\|.*?\|.*?\| )(⚪ Pending|🔵 Setup|🟡 In Progress|🟢 Done|🔴 Blocked)( \|)"
        )
        replacement = rf"\g<1>{exp['status_emoji']} {exp['status_text']}\g<3>"
        readme_content = pattern.sub(replacement, readme_content)

    if check_mode:
        print("=== DRY RUN — Would write: ===")
        # Just show the summary
        for exp in experiments:
            print(f"  {exp['num']} {exp['folder']}: {exp['status_emoji']} {exp['status_text']}")
        print(f"\nProgress: {new_summary}")
    else:
        README_PATH.write_text(readme_content, encoding="utf-8")
        print(f"✅ README.md updated ({len(experiments)} experiments, last updated: {today})")


if __name__ == "__main__":
    main()
