#!/usr/bin/env python3
"""Counts what the prose hook would flag, without the per-file report cap.

    report.py [<path> ...]

With no argument it reports on the current repository. A path may be a file or a
directory. Exempt paths from `.claude/style-exempt.txt` are honoured, so the count
matches what the hook would actually say.
"""

import fnmatch
import importlib.util
import pathlib
import subprocess
import sys

SKIP = ("node_modules", "third_party", "/sdk/", ".venv", "/dist/", "/build/")


def load(kit: pathlib.Path):
    spec = importlib.util.spec_from_file_location("cp", kit / "hooks" / "check-prose.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def tracked(root: pathlib.Path) -> list[str]:
    out = subprocess.run(
        ["git", "-C", str(root), "ls-files"], capture_output=True, text=True
    )
    return out.stdout.split()


def main() -> int:
    kit = pathlib.Path(__file__).resolve().parent.parent
    checker = load(kit)
    targets = [pathlib.Path(a).resolve() for a in sys.argv[1:]] or [pathlib.Path.cwd()]

    root = pathlib.Path(
        subprocess.run(
            ["git", "-C", str(targets[0] if targets[0].is_dir() else targets[0].parent),
             "rev-parse", "--show-toplevel"],
            capture_output=True, text=True,
        ).stdout.strip()
        or targets[0]
    )

    registers = [str(kit / "voice" / "register.txt")]
    local = root / ".claude" / "register.local.txt"
    if local.exists():
        registers.append(str(local))
    literals, patterns, disabled = checker.load_register(registers)
    builtins = [c for c in checker.BUILTINS if c[0] not in disabled]

    exempt: list[str] = []
    exempt_file = root / ".claude" / "style-exempt.txt"
    if exempt_file.exists():
        exempt = [
            line.strip()
            for line in exempt_file.read_text(encoding="utf-8").split("\n")
            if line.strip() and not line.startswith("#")
        ]

    rows: list[tuple[int, str]] = []
    for name in tracked(root):
        path = root / name
        if any(part in str(path) for part in SKIP):
            continue
        if not any(str(path).startswith(str(t)) or t == path for t in targets):
            continue
        if any(fnmatch.fnmatch(str(path), glob) for glob in exempt):
            continue
        try:
            raw = path.read_bytes()
        except OSError:
            continue
        if b"\x00" in raw[:8192]:
            continue
        text = raw.decode("utf-8", errors="replace")
        hits = 0
        for _, line in checker.prose_lines(name, text):
            if (
                any(p.search(line) for _, p in literals)
                or any(p.search(line) for p in patterns)
                or any(p.search(line) for _, p, _ in builtins)
            ):
                hits += 1
        if hits:
            rows.append((hits, name))

    rows.sort(reverse=True)
    for hits, name in rows:
        print(f"{hits:5}  {name}")
    print(f"\n{sum(h for h, _ in rows)} flagged lines across {len(rows)} files")
    return 0


if __name__ == "__main__":
    sys.exit(main())
