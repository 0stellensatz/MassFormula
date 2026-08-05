#!/usr/bin/env python3
"""Run this project's `__check__.py` when its rules say to.

`__check__.py` is textual and fast (~40 ms), and it catches the two mistakes a
`lake build` does not report as errors: a source file missing from the root
all-import module, which is then not built, not type-checked, and green, and a
comparator file that has drifted from its `Challenge.lean`.  Both are *multi-file*
invariants, transiently violated by any normal edit sequence---a new file exists
for a moment before its `import` line is added, a Challenge declaration before its
Development twin---so checking after every single edit would fire constantly on
states that are merely half-written.
`../../CLAUDE.md` names the moment instead: run the structural check before
declaring work done.  That is the Stop event.

One entry point serves both hook events, dispatching on `hook_event_name`:

    PostToolUse (Edit|Write)  note that a source file of this project was touched
    Stop                      run `__check__.py` if any was

The project is this file's own---`.claude/hooks/` sits at the package root---so
the hook travels with the repository it checks and needs nothing from whatever
tree the repository happens to be checked out under.  An edit under `.lake/` is
ignored: Mathlib's own sources are not this project's.

The checker reports on stdout, so its output is re-emitted on stderr, where exit
status 2 hands it back for repair.  `stop_hook_active` disarms the gate on a
second consecutive stop, so a failure the model cannot fix never traps the
session; the next turn's edits re-arm it.
"""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from pathlib import Path

# .claude/hooks/__lean_check__.py -> the package root
PROJECT = Path(__file__).resolve().parents[2]
CHECKER = PROJECT / "__check__.py"

STATE_DIR = Path(tempfile.gettempdir()) / "claude-lean-check"


def is_source(file_path: object) -> bool:
    """Whether an edit landed on a Lean source file of this project."""
    if not isinstance(file_path, str) or not file_path.endswith(".lean"):
        return False
    try:
        relative = Path(file_path).resolve().relative_to(PROJECT)
    except (ValueError, OSError):
        return False
    return ".lake" not in relative.parts


def state_file(session_id: str) -> Path:
    safe = "".join(c for c in session_id if c.isalnum() or c in "-_") or "session"
    return STATE_DIR / f"{safe}.{PROJECT.name}"


def record(payload: dict) -> int:
    """PostToolUse: arm the Stop gate if this edit touched a source file."""
    if not is_source((payload.get("tool_input") or {}).get("file_path")):
        return 0

    STATE_DIR.mkdir(parents=True, exist_ok=True)
    state_file(payload.get("session_id", "")).touch()
    return 0


def gate(payload: dict) -> int:
    """Stop: run the checker if the gate is armed, and block if it fails."""
    marker = state_file(payload.get("session_id", ""))
    if not marker.is_file():
        return 0

    # Read once and clear: a stop that blocks is re-armed by the next turn's
    # edits, so the gate never stays armed after its report has been handed back.
    marker.unlink(missing_ok=True)

    if not CHECKER.is_file():
        return 0

    done = subprocess.run(
        [sys.executable, str(CHECKER)],
        capture_output=True,
        text=True,
    )
    if done.returncode == 0 or payload.get("stop_hook_active"):
        return 0

    output = (done.stdout + done.stderr).strip()
    print(
        f"Structural check failed. Fix these, then re-run `python3 __check__.py`:\n\n{output}",
        file=sys.stderr,
    )
    return 2


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0

    event = payload.get("hook_event_name")
    if event == "PostToolUse":
        return record(payload)
    if event == "Stop":
        return gate(payload)
    return 0


if __name__ == "__main__":
    sys.exit(main())
