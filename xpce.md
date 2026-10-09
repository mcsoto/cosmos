Done. The basic XPCE canvas library works end to end — both demo exes open a `Cosmos Space` window, run their event loops, and draw with zero errors.

## What was built

| File | Role |
|---|---|
| `libs/space_xpce_prolog.pl` | Raw Prolog backend: window, retained-object drawing (rect/circle/ellipse/arc/line/polygon/text), Prolog-side transform stack, scanline polygon fill, fonts, images, timer loop |
| `libs/space_xpce.co` (+ compiled `.pl`/`.cif`) | Cosmos wrapper exposing the `sp` table via `pl::` calls |
| `libs/space.co` | Entry point, now native-only (JS lines kept as comments per your note) |
| `misc/simple_xpce.co`, `misc/demo_space_xpce.co` | Test apps; both built to `.exe` and verified with live windows |
| `XPCE_BACKEND.md` | Full notes incl. every XPCE quirk found by probing |

Supporting fixes in `compiler/platform/driver.pl` + `compiler/swi.pl`: absolute lib templates recorded at build time, `abolish_all_tables` + non-tabled loader in exe entries (fixes standalone runs), XPCE DLL staging next to GUI exes.

## Your earlier questions

- **Process**: `.co` → `cli.pl` compiles to `.pl` → `--main` appends `cosmos_entry_main` → `--exe` runs `qsave_program`. Nothing XPCE-specific except DLL staging below.
- **DLLs**: yes, staged automatically. I dumped the PE import tables (`pl2xpce` → SDL3/cairo/pango/glib/fontconfig/freetype + `libswipl.dll`, 29 files) and the build copies that closure next to Space exes. Console exes are unaffected.
- **Built-in utility**: only `qsave_program`. Two gotchas found empirically: a saved image containing `library(pce)` never starts (backend loads at runtime instead), and XPCE needs no stub emulator — default `stand_alone` exe + DLLs beside it works.

## Limits (documented in XPCE_BACKEND.md)

Input polling stubs return "up"; scissor is recorded-not-enforced; `shear`/line-style are no-ops; one `rel` per table name (no overloading); `require` must stay inside rels for `--main` programs; value-position calls need the out-param last (e.g. `newFont(size,family,style,font)`).

## Verification

- Smoke test drew every primitive clean; both exes run with empty stderr.
- `node --test tests/compiler/compiler.test.mjs`: 22 pass, 7 fail — I confirmed via `git stash` that all 7 fail identically on the pristine tree (missing WASM bundle, `--exe` AV under node spawn, v2/trace/query drift on SWI 10), so no regressions from these changes.

& 'C:\Program Files\swipl\bin\swipl.exe' -q -s D:\Computer\Documents\cosmos\compiler\platform\cli.pl -- D:\Computer\Documents\cosmos\misc\simple_xpce.co D:\Computer\Documents\cosmos\misc\simple_xpce.pl --main --exe 2>&1; echo SIMPLE:$?; & 'C:\Program Files\swipl\bin\swipl.exe' -q -s D:\Computer\Documents\cosmos\compiler\platform\cli.pl -- D:\Computer\Documents\cosmos\misc\demo_space_xpce.co D:\Computer\Documents\cosmos\misc\demo_space_xpce.pl --main --exe 2>&1; echo DEMO:$?
