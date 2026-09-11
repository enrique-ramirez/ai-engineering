# ai-engineering

Claude Code tooling for one person's repositories. Plan a spec, build it with agents that check each other, review what comes out.

Nothing here knows what a repository is for. Everything project-specific lives in that project's own `.claude/review-profile.md`.

## A full pass

```
/plan add passkey login      # interviews the owner, writes _todo/007-passkey-login/
/plan approve 007            # once its guesses have been answered
/build 007                   # builds it task by task, then audits the lot
/review                      # design, then comments
/plan done 007               # cleanup, bundle moves to _done/
```

That's the whole thing. `/build` refuses to start on an unapproved spec, and `/plan approve` refuses a spec that isn't buildable yet, so the order holds itself together.

## Commands

| type this | what happens |
|---|---|
| `/plan <brief>` | drafts a spec bundle from a rough idea, marks every guess, then asks about them |
| `/plan resume <n>` | picks an open bundle back up |
| `/plan approve <n>` | checks the bundle is actually buildable, then records the owner's approval |
| `/plan done <n>` | walks the cleanup and moves the bundle to `_done/` |
| `/build <n>` | builds an approved bundle |
| `/review [target]` | design pass then comments pass. Defaults to uncommitted work |
| `/humanize <path>` | rewrites prose that reads like an assistant wrote it |
| `/review-profile` | fills in this repo's profile by reading the code |

## Where the specs live

Three gitignored folders. None of them are part of the repo:

| | |
|---|---|
| `_todo/` | specs in flight. One folder per unit of work, holding `spec.md`, `plan.md`, `tasks.md`, `research.md` |
| `_done/` | where a bundle goes once it ships |
| `_tmp/` | scratch. Probes, throwaway scripts, anything needed once |

Treat `_todo/` like a board sitting next to the code, not like part of it. Nothing committed references it.

## Who does what during a build

`/build` turns the main agent into a coordinator. It writes no code. It dispatches, checks what comes back, and bounces anything that fails a check:

| | |
|---|---|
| `test-writer` | turns one acceptance criterion into a failing test. Owns the test file |
| `task-builder` | makes that test pass. One task, inside the spec's file scope, and it cannot edit the test |
| `change-auditor` | the last look at the whole change: suite, lint, conformance, seams, defects. Reports, never edits |

The builder only runs the tests for what it built. The full suite runs once, at the end, under the auditor. That's the only moment the whole change exists.

Then `/review`, which is a different question - is this well built, rather than does it work:

| | |
|---|---|
| `style-reviewer` | design, naming, duplication, documentation drift |
| `comment-reaper` | which comments survive |

## The rules they all read

**`doctrine/documentation.md`.** The code and its tests are the primary documentation. Markdown covers what those two can't express, and nothing else. Every agent that writes anything reads this first, so it's a rule at write time rather than something the reaper discovers later.

**`voice/`.** `register.txt` is the words that read as an assistant, `constructions.md` is the shapes, which is the half no word list catches. `personas/` is for text posting under a person's name. Public docs use the house voice.

**`hooks/check-style.sh`.** Mechanical, runs on every write, decides nothing. It only reports what a grep can be certain about, so a hit is a violation rather than a suggestion. Fires on `Edit`, on `Write`, and on `Bash` commands that wrote a file, which is the case most setups miss.

**`.claude/review-profile.md`.** The per-repo half: boundary rule, excluded paths, which commands to run, what can't be verified on this machine. The agents treat it as fact. Leave placeholders in it and they fall back to generic behaviour and say so in their reports.

## Install

Two modes, in [INSTALL.md](INSTALL.md). Plugin, so one update reaches every repo. Or copy, so a repo is self-contained and travels with a clone.

```
bin/install.sh <target-repo> --mode copy
```

Then fill in `.claude/review-profile.md`, or run `/review-profile` and let it read the code instead.

## Why the reaper works the way it does

It doesn't read a comment and judge whether it seems useful, because by then it has already read it. It strips the comments, hands the bare code to a fresh weak model with no repository access, and asks the question the comment claimed to answer.

Recovers the fact from the code? The comment was restating the code. Recovers it from the project's own notes? Second copy. Nothing recovers it? It stays.

The weak model is deliberate. A strong one reconstructs almost anything, which measures the model rather than the code.

Worth reading [COMMENT-REAPER.md](COMMENT-REAPER.md) for why this finds real bugs and not only dead comments.
