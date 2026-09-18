.PHONY: all compiler exe installers installer installer-cli installer-legacy test test-compiler

SWIPL ?= swipl
COSMOS_EXE ?= cosmos.exe

all: compiler test

compiler:
	node compiler/build.mjs

# Build the native SWI-Prolog command-line launcher. The compiler target first
# refreshes and verifies the checked-in self-hosted compiler artifacts.
# Usage: make exe
# Override SWI when needed: make exe SWIPL="C:/Program Files/swipl/bin/swipl.exe"
exe: $(COSMOS_EXE)

$(COSMOS_EXE): compiler compiler/platform/repl.pl compiler/platform/session.pl compiler/platform/driver.pl
	$(SWIPL) -q -s compiler/platform/repl.pl -g "use_module(library(dif)),use_module(library(lists)),compiler_load('compiler/generated'),qsave_program('$(COSMOS_EXE)',[goal(main),stand_alone(true),autoload(true),toplevel(halt)])" -t halt

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
