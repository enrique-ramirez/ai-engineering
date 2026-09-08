# Install

Two modes. Pick one per repository.

**Plugin.** The agents, hooks and voice files stay here, and every repository points at them. One update reaches all of them. Needs the plugin installed in Claude Code.

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
| `.claude/review-profile.md` | the template, for you to fill in |
| `.claude/style-patterns.local.txt` | your hostnames and machine names, gitignored |
| `.claude/register.local.txt` | repository-local register additions, and switches for the built-in checks |
| `.claude/style-exempt.txt` | paths the hook skips |
| `.claude/settings.json` | the `PostToolUse` hook, merged into whatever is already there, with a `.bak` beside it |
| `.gitignore` | two entries, appended if absent |

In copy mode it also writes `.claude/hooks/`, `.claude/agents/` and `.claude/voice/`.

Existing files are kept, not overwritten. Pass `--force` to replace them.

## Then fill in the profile

This is the part that matters. `.claude/review-profile.md` is where both agents learn the repository's boundary rule, its excluded paths, its functional directives, what each documentation file is for, and which commands they may run. Placeholders left in place make the agents fall back to generic behaviour, and they will say so in their reports.

The `install-review-kit` skill fills most of it by reading the repository, and leaves the two judgement calls open.

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
