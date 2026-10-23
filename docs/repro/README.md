# Reproductions

Small standalone Cosmos programs for the issues in
[`../ENGINE_ISSUES.md`](../ENGINE_ISSUES.md).  Each one is meant to be read,
compiled and run from the repository root.

| file | issue | how to run |
| --- | --- | --- |
| `quit.co` | 1 - `sp.quit()` orphans the process | `cosmos -l docs/repro/quit.co --xpce` |
| `underscore.co` | 8 - a run of `_` parameters: seen once, not reproducible | `cosmos -l docs/repro/underscore.co -q "t1(r)" --vars r` |
| `choose.co` | 5 - `if` runs its condition twice; `choose` does not | `cosmos -l docs/repro/choose.co -q "t1(r)" --vars r` |
| `cut.co` | 7 - `cut` does not parse | `cosmos -c docs/repro/cut.co` |
| `indexing.co` | 4 - `l[i]` is a table read | `cosmos -l docs/repro/indexing.co -q "t2(r)" --vars r` |

## Notes

* The Space programs need a toolkit: `?- use_module(library(pce)).` must work
  in the local SWI-Prolog.
* `docs/repro/quit.co` opens a window.  It is expected *not* to exit on its
  own - that is the bug.  Stop it with the task manager.
* The headless queries (`-q`) run the file's own top-level goals first, so a
  file with `sp.start` in it will open a window before the query runs.  The
  repro files that are queried headlessly have no top-level goals.
* `indexing.co` shows the three ways to reach an element: `l[i]`,
  `string.at/3` and a hand-written index.  Only the last two are right for
  lists and strings.
