# Review profile

Copy to `.claude/review-profile.md` in the target repository and fill in every section. The review agents and `spec-planner` read this first and treat it as fact about the repository. Anything left as a placeholder makes them fall back to generic behaviour and say that they did.

Keep it short. This is the file that stops the agents from inventing a boundary the repository does not have.

## Boundary

> The one architectural rule that matters here, and how it is enforced.

Example: imports run `app` to `features` to `domain` to `shared`, enforced by the linter.
Example: `core/` knows nothing of the host application, and everything it needs arrives as a callback.
Example: no rule worth naming. Say so plainly rather than leaving this blank.

## Excluded paths

> Directories and files the agents never touch: generated code, vendored code, lockfiles, scratch.

- `node_modules/`
- `dist/`
- `*.local.md`
- `_todo/`, `_done/`, `_tmp/` (gitignored scratch; `spec-planner` owns the first two)

## Functional directives

> Suppression comments that are load-bearing here. The agents never delete or weaken one.

Example: `biome-ignore`, `eslint-disable`, `ts-expect-error`.
Example: `NOLINT`, `shellcheck disable`, `clang-format off`.

## Doc comments

> Whether a docstring, a JSDoc block or the language's equivalent is judged like any other comment, or whether a convention or a linter requires one regardless. Say which, because the reaper's default is to cut anything that restates a signature.

Example: judged as a comment. Nothing requires them, so there is no floor.
Example: every exported symbol keeps a one-line summary, because the linter fails without it. The body is still judged.

## Documentation map

> Which of these files exist here, who opens each one, and the single job it has. `doctrine/documentation.md` holds the rule they all follow: the code and its tests are the primary documentation, and markdown is for what those two cannot express. Delete any row for a file this repository does not have, and do not invent one.

| file | audience | its job |
|---|---|---|
| `README.md` | whoever consumes that folder, which changes with the folder | what this is |
| `CONTRIBUTING.md` | contributors, human and agent | how to work here. Every agent that writes code reads this |
| `ARCHITECTURE.md` | a developer | how the pieces fit and why the boundaries sit there |
| `CLAUDE.md` | agents | what an agent has to do differently here, and nothing that applies to a person too |

## Where an external fact belongs

> When a comment turns out to hold a fact about an outside system, the reaper moves it here rather than deleting it.

Example: `ARCHITECTURE.md`.
Example: `docs/api.md` for anything the upstream service returns.

## Commands

> Targeted forms only. The agents are forbidden from running a full suite. Give what each one costs, measured, because that decides where it gets run. Where a narrower form saves nothing, because the cost is compiling rather than running, say so, and the agents run the whole of it.

| | command | cost |
|---|---|---|
| lint | `pnpm lint` | 1s |
| types | `pnpm typecheck` | 2s |
| one test file | `pnpm test path/to/file.spec.ts` | 5s |

## What cannot be verified here

> Code that does not build or run on a normal development machine, so a change to it is reviewed rather than tested. Write "nothing" if that does not apply.

Example: platform-specific sources that only compile on another operating system.

## Voice

> Which persona governs prose written into this repository. `house` unless there is a reason.

- Documentation and comments: `house`
- Text posted under a person's name: `house`

## Product decisions

> Who decides what this software does for a user, and what the agents do when a diff makes such a decision without them.

Example: the owner decides. An agent that finds an unasked product decision in the diff reports it as a finding and does not implement it.
