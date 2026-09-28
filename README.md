# ai-engineering

Claude Code agents, skills and a style hook for planning a spec, building it with agents that check each other, and reviewing the result. Nothing here knows what a repository is for: each project's `.claude/review-profile.md` holds that.

```
/plan add passkey login      # interviews the owner, drafts a bundle
/plan approve 007            # once its guesses are answered
/build 007                   # builds it in parallel lanes, audits it, reviews it
/plan done 007               # cleanup, docs audit, bundle moves out
```

`/build` refuses an unapproved spec and `/plan approve` refuses one that is not buildable.

## Commands

| command | does |
|---|---|
| `/plan <brief>` | drafts a spec bundle, marks every guess, asks about them |
| `/plan resume <n>` | picks an open bundle back up |
| `/plan approve <n>` | checks the bundle is buildable, records the approval |
| `/plan done <n>` | walks the cleanup, audits the docs it touched, closes the bundle |
| `/build <n>` | builds an approved bundle and records what each dispatch cost |
| `/review [target]` | design pass then comment pass, on uncommitted work by default |
| `/review --docs [path]` | audits every `CLAUDE.md`, `README.md`, `CONTRIBUTING.md` and `ARCHITECTURE.md` against the doctrine and the word budget |
| `/humanize <path>` | rewrites prose that reads as machine-written |
| `/review-profile` | fills in the profile by reading the code |

Bundles live in three gitignored folders at the repository root: `_todo` for open specs, `_done` for shipped ones, `_tmp` for scratch.

## Agents

| agent | job |
|---|---|
| `spec-planner` | researches the tree and interviews the owner into a bundle |
| `test-writer` | writes each criterion's failing test and proves it bites. Owns the test files |
| `task-builder` | makes those tests pass inside the file scope, and cannot edit them |
| `style-reviewer` | design, names, duplication, mutation, documentation |
| `change-auditor` | the whole change at the end: suite, conformance, seams, defects. Never edits |
| `comment-reaper` | keeps a comment only if a weak model, given the bare code, cannot recover its fact |

`/build` coordinates and writes no code. Builders run only their own tests; the full suite runs once, under the auditor. Each build writes `build-metrics.md` into its bundle, a row per dispatch with time and tokens.

## Rules the agents read

- `doctrine/agents.md`: what every agent does, from the git rule to how it reports.
- `doctrine/documentation.md`: the code and tests are the documentation; which file each remaining fact goes in.
- `voice/`: `register.txt` lists words that read as an assistant, `constructions.md` the shapes, `personas/` the voices.
- `hooks/check-style.sh`: runs after every `Edit`, `Write`, and `Bash` command that wrote a file. It checks register, dashes, recorded measurements, history, hard wrapping and identity detail everywhere; status and roadmap prose in `CLAUDE.md`, `AGENTS.md` and `README.md`; and a word budget on `CLAUDE.md` and `AGENTS.md`.

## Install

See [INSTALL.md](INSTALL.md), then fill in `.claude/review-profile.md` or run `/review-profile`. [COMMENT-REAPER.md](COMMENT-REAPER.md) shows why the reaper finds bugs as well as dead comments.
