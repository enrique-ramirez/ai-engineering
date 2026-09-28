# Install

Two modes, one per repository. Neither runs git.

- **Plugin:** the kit stays here and every repository points at it, so one update reaches all of them.
- **Copy:** everything lands in the repository's `.claude/`, so it works without the plugin and travels with a clone. A refresh means re-running the installer.

```
# plugin
/plugin marketplace add <path-to-this-checkout>
/plugin install review-kit@ai-engineering
<path-to-this-checkout>/bin/install.sh <target-repo>

# copy
<path-to-this-checkout>/bin/install.sh <target-repo> --mode copy
```

## What the installer writes

| | |
|---|---|
| `.claude/review-profile.md` | the profile template, never overwritten |
| `.claude/style-patterns.local.txt` | identity patterns that must not reach a commit, and `-regex` allow lines |
| `.claude/register.local.txt` | local register phrases, switches for built-in checks, the `CLAUDE.md` word budgets |
| `.claude/style-exempt.txt` | globs the hook skips |
| `.claude/settings.json` | the `PostToolUse` hook, merged in, with a `.bak` beside it |
| `.gitignore` | the local and backup files, the manifest, and the three bundle folders |

Copy mode also writes `.claude/hooks/`, `agents/`, `skills/`, `voice/`, `doctrine/` and `templates/`. Existing local files are kept.

## Local settings

`.claude/register.local.txt` takes one entry per line:

| line | effect |
|---|---|
| `!phrase` | flags a literal phrase |
| `~regex` | flags a pattern |
| `-name` | switches off a built-in check: `emdash`, `curly`, `emoji`, `measurement`, `history`, `hardwrap` |
| `=claude-budget 400` | prose words allowed in a nested `CLAUDE.md` or `AGENTS.md` |
| `=claude-root-budget 800` | the same for the repository root |

A file over budget fails only when it has grown since `HEAD`, so trimming an old file never blocks. In `.claude/style-patterns.local.txt`, a `-regex` line lets every check pass on a matching line: the way to let a contributing guide quote a banned phrase without exempting the whole file.

## Refreshing a copy install

Give the repository an entry point, such as a `package.json` script:

```
"sync-kit": "\"${AI_ENGINEERING:-../ai-engineering}/bin/install.sh\" . --mode copy --force"
```

`.claude/.review-kit.manifest` records the checksum of every file the installer wrote, which is how a refresh tells a local edit from a kit update:

| state | without `--force` | with `--force` |
|---|---|---|
| matches the kit | silent | silent |
| the kit moved on | reported, left alone | replaced |
| edited locally | reported, left alone | replaced, local version saved as `<name>.local.bak` |
| `review-profile.md` | never touched | never touched |
| dropped from the kit | removed if untouched, reported if not | the same |

## Check that the hook fires

```
printf 'A note about the cache — it holds rows.\n' > /tmp/probe.md
echo '{"tool_input":{"file_path":"/tmp/probe.md"}}' | .claude/hooks/check-style.sh
```

Expect a report about the dash and exit code 2.

## Notes

The hook applies the session's project rules to every file it checks, including files in another checkout. It needs `python3` and `git`, and runs on the bash 3.2 macOS ships.

To uninstall, delete the files the installer listed and the `PostToolUse` entry in `.claude/settings.json`.
