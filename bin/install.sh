#!/usr/bin/env bash
# Installs the review kit into a repository.
#
#   install.sh <target-repo> [--mode copy|plugin] [--force]
#
# copy   puts the agents, hooks and voice files inside the target's own .claude/, so the
#        repository is self-contained and needs no marketplace. Updates mean re-running.
# plugin writes only the per-repository files and leaves the agents, hooks and voice to
#        the installed plugin, so one update reaches every repository.
#
# Never touches git. It writes files and prints what it did.
set -euo pipefail

kit=$(cd "$(dirname "$0")/.." && pwd)
target=${1:-}
mode=plugin
force=no

shift || true
while [ $# -gt 0 ]; do
  case "$1" in
    --mode) mode=${2:-}; shift 2 ;;
    --force) force=yes; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [ -z "$target" ] || [ ! -d "$target" ]; then
  echo "usage: install.sh <target-repo> [--mode copy|plugin] [--force]" >&2
  exit 2
fi
case "$mode" in copy|plugin) ;; *) echo "mode must be copy or plugin" >&2; exit 2 ;; esac

target=$(cd "$target" && pwd)
claude="$target/.claude"
mkdir -p "$claude"
wrote=()
warnings=()

# What this script installed last time, so a file you edited can be told apart from a
# file the kit has since changed. Without it every existing file reads as edited, which
# is the safe way to be wrong.
manifest="$claude/.review-kit.manifest"
staged=$(mktemp)
trap 'rm -f "$staged"' EXIT

sum() { cksum < "$1" 2>/dev/null | cut -d' ' -f1; }

# Silent and empty when there is no manifest yet, which is the first run against a
# repository the kit was copied into by hand. `awk` exits 2 on a missing file and
# `set -e` would take that as fatal.
installed_sum() {
  [ -f "$manifest" ] || return 0
  awk -v p="$1" '$2 == p { print $1; exit }' "$manifest" 2>/dev/null || true
}

# A kit-managed file. Yours to read, not to edit: a local change here is reported, and
# `--force` moves it aside rather than dropping it.
place() {
  local src="$1" dest="$2" rel="${2#"$target/"}" here there before record
  mkdir -p "$(dirname "$dest")"
  there=$(sum "$src")
  # The manifest records what the kit put there, never what is on disk now. Adopting a
  # file this run declined to touch would make the next run treat an edit as installed.
  record="$there"
  if [ ! -e "$dest" ]; then
    cp "$src" "$dest"
    wrote+=("$rel")
  else
    here=$(sum "$dest"); before=$(installed_sum "$rel")
    if [ "$here" = "$there" ]; then
      :
    elif [ -n "$before" ] && [ "$here" = "$before" ]; then
      if [ "$force" = yes ]; then
        cp "$src" "$dest"
        wrote+=("$rel (updated)")
      else
        echo "  kept  $rel (the kit has a newer one; --force takes it)"
        record="$before"
      fi
    elif [ "$force" = yes ]; then
      cp "$dest" "$dest.local.bak"
      cp "$src" "$dest"
      warnings+=("$rel had changes of its own. They are in $rel.local.bak")
    else
      warnings+=("$rel has changes of its own. Left alone; --force replaces it")
      record="$before"
    fi
  fi
  [ -n "$record" ] && printf '%s %s\n' "$record" "$rel" >> "$staged"
}

# A file the repository owns once it exists. Never replaced, whatever the flags say.
place_once() {
  local src="$1" dest="$2" rel="${2#"$target/"}"
  if [ -e "$dest" ]; then
    echo "  kept  $rel (yours)"
    return
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  wrote+=("$rel")
}

if [ "$mode" = copy ]; then
  # hooks.json registers the hook for a plugin install and means nothing in a copy.
  for f in "$kit"/hooks/check-*; do place "$f" "$claude/hooks/$(basename "$f")"; done
  for f in "$kit"/agents/*.md; do place "$f" "$claude/agents/$(basename "$f")"; done
  for f in "$kit"/voice/*.txt "$kit"/voice/*.md; do place "$f" "$claude/voice/$(basename "$f")"; done
  for f in "$kit"/voice/personas/*.md; do place "$f" "$claude/voice/personas/$(basename "$f")"; done
  for f in "$kit"/templates/todo/*.md; do place "$f" "$claude/templates/todo/$(basename "$f")"; done
  for d in "$kit"/skills/*/; do place "$d/SKILL.md" "$claude/skills/$(basename "$d")/SKILL.md"; done
  chmod +x "$claude/hooks/check-style.sh"
  hook_command='$CLAUDE_PROJECT_DIR/.claude/hooks/check-style.sh'
else
  hook_command='${CLAUDE_PLUGIN_ROOT}/hooks/check-style.sh'
fi

place_once "$kit/profile/review-profile.template.md" "$claude/review-profile.md"

if [ ! -e "$claude/style-patterns.local.txt" ]; then
  cat > "$claude/style-patterns.local.txt" <<'TXT'
# Extended regular expressions, one per line, for identity and infrastructure detail
# that must not reach a commit: hostnames, internal addresses, machine names, personal
# paths. This file is gitignored, so it never publishes what it exists to keep out.
#
# Example:
# 10\.0\.0\.
# my-laptop
TXT
  wrote+=(".claude/style-patterns.local.txt")
fi

if [ ! -e "$claude/register.local.txt" ]; then
  cat > "$claude/register.local.txt" <<'TXT'
# Repository-local additions to the register list, read after the shared one.
#
#   !phrase   literal, checked mechanically
#   ~regex    regular expression, checked mechanically
#   -name     switch off a built-in check: emdash, curly, emoji, measurement
TXT
  wrote+=(".claude/register.local.txt")
fi

# The hook must not check the files that state the rules it enforces.
if [ ! -e "$claude/style-exempt.txt" ]; then
  cat > "$claude/style-exempt.txt" <<'TXT'
# Globs exempt from the style hook, one per line, matched against the absolute path.
*/CONTRIBUTING.md
TXT
  wrote+=(".claude/style-exempt.txt")
fi

python3 - "$claude/settings.json" "$hook_command" <<'PY'
import json, os, sys

path, command = sys.argv[1], sys.argv[2]
settings = {}
# Match whatever the file already uses. A formatter set to tabs fails its own lint on a
# file this script reindented.
indent = 2
if os.path.exists(path):
    original = open(path, encoding="utf-8").read()
    settings = json.loads(original)
    for line in original.split("\n"):
        lead = line[: len(line) - len(line.lstrip())]
        if lead:
            indent = "\t" if lead.startswith("\t") else len(lead)
            break
    with open(path + ".bak", "w", encoding="utf-8") as handle:
        handle.write(original)

MATCHER = "Edit|Write|Bash"
hooks = settings.setdefault("hooks", {}).setdefault("PostToolUse", [])

# An existing entry may predate the Bash matcher, which is the one that catches a file
# written by a shell command rather than by the edit tools.
existing = next(
    (
        group
        for group in hooks
        if any(entry.get("command") == command for entry in group.get("hooks", []))
    ),
    None,
)
if existing is None:
    hooks.append({"matcher": MATCHER, "hooks": [{"type": "command", "command": command}]})
    note = "PostToolUse hook added"
elif existing.get("matcher") != MATCHER:
    existing["matcher"] = MATCHER
    note = f"matcher widened to {MATCHER}"
else:
    print("  kept  .claude/settings.json (hook already registered)")
    raise SystemExit(0)

with open(path, "w", encoding="utf-8") as handle:
    json.dump(settings, handle, indent=indent)
    handle.write("\n")
print(f"  wrote .claude/settings.json ({note})")
PY

ignore="$target/.gitignore"
for pattern in '*.local.txt' '*.local.bak' '.claude/settings.json.bak' '.claude/.review-kit.manifest' '_todo/' '_done/' '_tmp/'; do
  if [ -f "$ignore" ] && grep -qxF "$pattern" "$ignore"; then continue; fi
  printf '%s\n' "$pattern" >> "$ignore"
  echo "  wrote .gitignore += $pattern"
done

# Anything the last install wrote that this one did not is a file the kit has dropped or
# renamed. Without this it lingers in every repository as a second, stale copy.
if [ -f "$manifest" ]; then
  while read -r before rel; do
    [ -n "${rel:-}" ] || continue
    grep -q " $rel\$" "$staged" && continue
    gone="$target/$rel"
    [ -e "$gone" ] || continue
    if [ "$(sum "$gone")" = "$before" ]; then
      rm -f "$gone"
      rmdir "$(dirname "$gone")" 2>/dev/null || true
      wrote+=("$rel (removed, no longer in the kit)")
    else
      warnings+=("$rel is no longer in the kit but has changes of its own. Left in place; delete it yourself")
    fi
  done < "$manifest"
fi

mv "$staged" "$manifest"

for f in "${wrote[@]:-}"; do [ -n "$f" ] && echo "  wrote $f"; done

if [ ${#warnings[@]} -gt 0 ]; then
  echo
  echo "Local changes to kit files:"
  for w in "${warnings[@]}"; do echo "  ! $w"; done
  echo "  A change worth keeping belongs in the kit, so every repository gets it."
fi

cat <<EOF

Installed in $mode mode into $target

Next:
  1. Fill in .claude/review-profile.md. Every section. The agents read it as fact.
  2. Put your own hostnames and machine names in .claude/style-patterns.local.txt.
EOF
if [ "$mode" = plugin ]; then
  cat <<EOF
  3. Make sure the review-kit plugin is installed, so the agents and hooks resolve:
       /plugin marketplace add $kit
       /plugin install review-kit@ai-engineering
EOF
fi
