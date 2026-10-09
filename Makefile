.PHONY: all compiler exe installers installer installer-cli installer-legacy test test-compiler test-canvas clean

SWIPL ?= swipl
COSMOS_EXE ?= cosmos.exe
RM ?= rm

# `make` builds thdde native launcher. Tests stay opt-in via `make test`;
# nothing here needs a JS canvas, Electron, or network access.
all: exe

compiler:
	node compiler/build.mjs

# Build the native SWI-Prolog command-line launcher. The compiler target first
# refreshes and verifies the checked-in self-hosted compiler artifacts.
# The trailing `-- -v` keeps repl.pl's startup dispatch out of the REPL so
# the -g goal actually runs: without program arguments repl.pl would start
# its interactive loop (initialization(main) runs before -g) and the save
# would never happen.
# Usage: make exe
# Override SWI when needed: make exe SWIPL="C:/Program Files/swipl/bin/swipl.exe"
exe: $(COSMOS_EXE)

$(COSMOS_EXE): compiler compiler/platform/repl.pl compiler/platform/session.pl compiler/platform/driver.pl compiler/swi.pl
	$(SWIPL) -q -s compiler/platform/repl.pl -g "use_module(library(dif)),use_module(library(lists)),compiler_load('compiler/generated'),qsave_program('$(COSMOS_EXE)',[goal(main),stand_alone(true),autoload(false),toplevel(halt)])" -t halt -- -v

# X qsave_program('$(COSMOS_EXE)',[...]),compiler_stage_exe('$(COSMOS_EXE)',false)
# One consequence worth stating plainly, since it's a behaviour change beyond "stop creating files": cosmos.exe no longer ships its own kernel DLLs, so it needs SWI reachable at runtime. Verified both ways — in the repo root it runs (exit=0, prints the version banner) because C:\Program Files\swipl\bin is on the machine PATH; copied to an isolated directory with PATH cleared it exits 0xC0000135. That matches every previous release, since none of them staged either.


# Build the lightweight native installer pair.  The setup build stages the
# same compiler/runtime material as `make exe`; CosmosSetup also carries only
# editor source and defers Electron/WASM installation to npm.
# Usage: make installers
installers:
	powershell -NoProfile -ExecutionPolicy Bypass -File .\cs-installer\build.ps1

installer: installers

installer-cli: installers

# The legacy Lua installer is retained as a separately named historical
# artifact. It is not rebuilt by the native installer script.
installer-legacy:
	@if exist cs-installer\dist\CosmosCliSetupLegacy.exe (echo cs-installer\dist\CosmosCliSetupLegacy.exe) else (echo Legacy installer is unavailable.& exit /b 1)

test: test-compiler

test-compiler:
	node --test tests/compiler/compiler.test.mjs

# JS Canvas / SWI-WASM bundle. Needs canvas/prolog-wasm/swipl-bundle.js
# (canvas/editor setup); the tests skip when it is absent. Deliberately
# separate from `test` so the native build never depends on the browser.
test-canvas:
	node --test tests/canvas/canvas.test.mjs

clean:
	$(RM) test/*.pl
	$(RM) test/*.cif
	#$(RM) libs/*.pl
	$(RM) misc/*.pl
	$(RM) misc/*.cif
	
cleandos:
	del test\*.pl
	del test\*.cif
	#del libs\*.pl
	del misc\*.pl
	del misc\*.cif