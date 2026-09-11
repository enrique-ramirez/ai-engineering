# Install

Two modes. Pick one per repository.

**Plugin.** The agents, skills, hooks, voice files, doctrine and templates stay here, and every repository points at them. One update reaches all of them. Needs the plugin installed in Claude Code.

**Copy.** Everything lands inside the repository's own `.claude/`, so it works with no plugin and travels with a clone. Updates mean re-running the installer.

Both modes write the same per-repository files, and neither runs git.

## Plugin mode

```
/plugin marketplace add ~/Projects/personal/ai-engineering
/plugin install review-kit@ai-engineering
```

Then, from anywhere:

```
~/Projects/personal/ai-engineering/bin/install.sh <target-repo>
```

Once this repository has a remote, the marketplace line takes the URL instead of the path, and the same two commands work on any machine.

## Copy mode

```
~/Projects/personal/ai-engineering/bin/install.sh <target-repo> --mode copy
```

## What the installer writes

| | |
|---|---|
| `.claude/review-profile.md` | the template, to be filled in |
| `.claude/style-patterns.local.txt` | local hostnames and machine names, gitignored |
| `.claude/register.local.txt` | repository-local register additions, and switches for the built-in checks |
| `.claude/style-exempt.txt` | paths the hook skips |
| `.claude/settings.json` | the `PostToolUse` hook, merged into whatever is already there, with a `.bak` beside it |
| `.gitignore` | seven entries, appended if absent: the local and backup files, plus `_todo/`, `_done/` and `_tmp/` |

In copy mode it also writes `.claude/hooks/`, `.claude/agents/`, `.claude/skills/`, `.claude/voice/`, `.claude/doctrine/` and `.claude/templates/`.

It does not create `_todo/`. `spec-planner` does that the first time `/plan` runs.

Existing files are kept, not overwritten. Pass `--force` to replace them.

## Refreshing a copy-mode repository

Copy mode duplicates the kit into each repository, so each one drifts until it is refreshed. Give the repository whatever entry point it already has:

| | |
|---|---|
| a Node project | `"sync-kit": "\"${AI_ENGINEERING:-../ai-engineering}/bin/install.sh\" . --mode copy --force"` in `package.json` |
| anything else | a two-line `sync-kit.sh` calling the same thing |

`AI_ENGINEERING` defaults to a sibling checkout, so it only needs setting when the kit lives elsewhere.

### What it does about edited files

`.claude/.review-kit.manifest` records the checksum of every file the installer wrote, which is how a refresh tells a local edit from a kit update.

| state | without `--force` | with `--force` |
|---|---|---|
| matches the kit | silent | silent |
| the kit moved on | reported, left alone | replaced |
| edited locally | reported, left alone | replaced, and the local version saved to `<name>.local.bak` |
| `review-profile.md` | never touched | never touched |
| dropped from the kit | removed if untouched, reported if not | removed if untouched, reported if not |

Nothing written locally is dropped. A rule worth keeping belongs in the kit, so every repository gets it; `.claude/register.local.txt` and `.claude/style-exempt.txt` are the places for something genuinely local, and neither is kit-managed.

The manifest and the `.local.bak` files are gitignored.

## Then fill in the profile

This is the part that matters. `.claude/review-profile.md` is where every agent learns the repository's boundary rule, its excluded paths, its functional directives, who reads each documentation file, and which commands they may run. Placeholders left in place make the agents fall back to generic behaviour, and they will say so in their reports.

The `review-profile` skill fills most of it by reading the repository, and leaves the two judgement calls open.

## Check that the hook fires

```
printf 'A note about the cache — it holds rows.\n' > /tmp/probe.md
echo '{"tool_input":{"file_path":"/tmp/probe.md"}}' | .claude/hooks/check-style.sh
```

Expect a report about the dash and exit code 2. A hook that does not fire is worse than no hook, because it reads as a guarantee.

## Uninstall

Delete the `.claude/` files the installer listed and remove the `PostToolUse` entry from `.claude/settings.json`. The `.bak` beside it is the state from before the install.

## Notes

The hook binds to the session's project directory, not to the repository a file belongs to. Editing another checkout from inside a session applies this repository's rules to it, which is usually noise. Keep a session in one repository, or widen `.claude/style-exempt.txt`.

`check-style.sh` needs `python3` and `git` on the path. It runs on bash 3.2, which is what macOS ships.
