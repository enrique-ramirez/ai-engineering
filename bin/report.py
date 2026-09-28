#!/usr/bin/env python3
"""Counts what the style hook would flag, without the per-file report cap.

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

sys.dont_write_bytecode = True

SKIP = ("node_modules", "third_party", "/sdk/", ".venv", "/dist/", "/build/")


def load(kit: pathlib.Path):
    spec = importlib.util.spec_from_file_location("cp", kit / "hooks" / "check-prose.py")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
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

    claude = root / ".claude"
    rules = checker.load_rules(
        [str(kit / "voice" / "register.txt"), str(claude / "register.local.txt")],
        str(claude / "style-patterns.local.txt"),
    )

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
        hits = len(checker.find_problems(name, raw.decode("utf-8", errors="replace"), rules))
        if hits:
            rows.append((hits, name))

    rows.sort(reverse=True)
    for hits, name in rows:
        print(f"{hits:5}  {name}")
    print(f"\n{sum(h for h, _ in rows)} flagged lines across {len(rows)} files")
    return 0


if __name__ == "__main__":
    sys.exit(main())
