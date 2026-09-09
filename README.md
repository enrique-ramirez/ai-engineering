# ai-engineering

Reusable Claude Code tooling: two review agents, a prose hook, and a voice system. Nothing here knows what a repository is for. Everything specific to a project lives in that project's own `.claude/review-profile.md`.

## What is in it

| | |
|---|---|
| `agents/style-reviewer.md` | reviews changed code for design, naming, duplication and documentation drift |
| `agents/comment-reaper.md` | decides which comments survive, by testing each one against a reader who has not seen it |
| `hooks/check-style.sh` | catches the register and formatting regressions a grep can be sure about |
| `hooks/check-prose.py` | separates prose from code, then applies the register list and the built-in checks |
| `voice/register.txt` | words and phrases that read as an assistant |
| `voice/constructions.md` | the shapes that read as an assistant, which no word list can catch |
| `voice/personas/` | who is speaking, for text that posts under a person's name |
| `profile/` | the template a target repository fills in |
| `skills/` | run a review pass, fill in a repository's profile, humanize a file |
| `bin/install.sh` | copies the kit into a repository and merges the hook into its settings |

## The two halves

The **hook** is mechanical and runs on every write. It decides nothing: it only reports what a grep can be certain about, so a hit is a violation rather than a suggestion. It fires on `Edit`, on `Write`, and on `Bash` commands that wrote a file, which is the case most setups miss.

The **agents** are judgement and run when someone asks. They are not triggered by the hook and never have been. An agent that has been editing runs them before asking for a commit; a person can also point them at a commit or a path.

Order matters. `style-reviewer` settles structure, then `comment-reaper` describes what is left.

## Why the reaper works the way it does

It does not read a comment and decide whether it seems useful, because by then it has already read it. It strips the comments, hands the bare code to a fresh weak model with no repository access, and asks the question the comment claimed to answer. If the reader recovers the fact from the code, the comment was restating the code. If it recovers the fact from the project's own notes, the comment was a second copy. If nothing recovers it, the comment stays.

The weak model is deliberate. A strong one reconstructs almost anything, which measures the model rather than the code.

## Install

See [INSTALL.md](INSTALL.md). Two modes: as a plugin, so one update reaches every repository, or copied into a repository so it is self-contained.

## The voice files

A word list catches vocabulary. It does not catch shape, and shape is what gives an assistant away: uniform sentence length, an em dash at every joint, a bolded pronouncement opening every paragraph. `voice/constructions.md` is that second list, and it is the one that changes how prose reads.

Personas are for text posted under a person's name, such as pull request comments. Public documentation uses the house voice, which has no personality on purpose.
