# Tasks NNN slug

Each task names its files and the observable that says it is done, and stands on its own as a commit. A builder takes the first unchecked task, does that one, and stops.

- [ ] T1 <what changes> | `path/to/file` | done when: <observable>
- [ ] T2 

## Cleanup

Last, and never skipped. The change is not finished while the scaffolding that built it is still in the tree.

- [ ] Delete what this spec added and no longer uses: flags behind a shipped path, fixtures, commented-out code, scratch scripts under `_tmp/`.
- [ ] Check the acceptance criteria against what was built. Where one drifted, say which side is wrong.
- [ ] Run `/review` over the whole change.
- [ ] Move this bundle to `_done/NNN-slug/` and drop its row from `_todo/INDEX.md`.
