# Review profile

Every kit agent reads this first and treats it as fact about the repository. Fill in every section and keep it short; a placeholder makes the agents fall back to generic behaviour.

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

> Which of these files exist here, who reads each, and its one job, per `doctrine/documentation.md`. Delete a row for a file this repository does not have.

| file | audience | its job |
|---|---|---|
| `README.md` | whoever uses that folder's thing | what it is and how to use it |
| `CONTRIBUTING.md` | developers, human and agent | how to write code here |
| `ARCHITECTURE.md` | developers | how the parts fit |
| `CLAUDE.md` | agents only | pointers, and traps an agent cannot read off the code |

## Where an external fact belongs

> Where the reaper moves a fact about an outside system when it governs more than one file. A fact about one line stays a comment beside it.

Example: `ARCHITECTURE.md`.
Example: `docs/api.md` for anything the upstream service returns.

## Commands

> Targeted forms only; agents never run a full suite. Give each one's cost, which decides where it runs. Where a narrower form saves nothing because the cost is compiling, say so.

| | command | cost |
|---|---|---|
| lint | `pnpm lint` | 1s |
| format | `pnpm format` | 1s |
| types | `pnpm typecheck` | 2s |
| one test file | `pnpm test path/to/file.spec.ts` | 5s |
| one case | `pnpm test path/to/file.spec.ts -t "the title"` | 5s |
| build | `pnpm build` | 20s |
| dev server | `pnpm dev`, port 5173 | stays up |

## What cannot be verified here

> Code that does not build or run on a normal development machine, so a change to it is reviewed rather than tested. For a page, what a test in jsdom cannot see. Write "nothing" if that does not apply.

Example: platform-specific sources that only compile on another operating system.
Example: layout, focus order and rendering, checked by a person in the browser against the dev server.

## User interface

> For a repository with a page or an app: how a component is rendered in a test, where the network is faked, what the look follows, the accessibility bar, the locales and the viewports. Write "none" where there is no user interface.

Example: tests render through `test/render.tsx`, which wraps the query client, the router and the message catalogue; the network is faked at `fetch` with a handler table per test, and hooks are never mocked.
Example: the look follows the neighbouring screen and `src/shared/styles/tokens.css`; no literal colour outside the tokens file.
Example: every control has an accessible name and works from the keyboard; a disabled control says why in its label.
Example: `en` bundled, `es` fetched; every visible string goes through the catalogue, and `test/locales.test.ts` checks the two agree.
Example: desktop and a narrow phone; a criterion that changes with width says which.
Example: none.

## Voice

> Which persona governs prose written into this repository. `house` unless there is a reason.

- Documentation and comments: `house`
- Text posted under a person's name: `house`

## Product decisions

> Who decides what this software does for a user, and what the agents do when a diff makes such a decision without them.

Example: the owner decides. An agent that finds an unasked product decision in the diff reports it as a finding and does not implement it.
