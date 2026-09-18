# Cosmos Cygwin `ncurses` library

This package exposes a Cygwin-ncurses-backed terminal table to Cosmos:

```cosmos
require('ncurses', ncurses)
ncurses.init()
ncurses.printAt(0, 0, 'Hello')
ncurses.refresh()
key = ncurses.getch()
ncurses.close()
```

`demo.co` is a minimal terminal smoke test. It draws two lines, waits for a
key, and returns to the shell.

The foreign DLL and SWI-Prolog must both be Cygwin-native; do not load this
DLL through the standard Windows `swipl.exe` or `cosmos.bat`.

Build `native/cosmos_ncurses.dll` from a Cygwin shell after the Cygwin SWI
build installs `/opt/swipl-cygwin/bin/swipl`:

```sh
cd /cygdrive/d/Computer/Documents/4/userlibs/ncurses/native
bash build-cygwin.sh
```

Then run the demo:

```sh
cd /cygdrive/d/Computer/Documents/4
bash cosmos-cygwin.sh -l userlibs/ncurses/demo.co
```

From Command Prompt or PowerShell, use the wrapper instead:

```bat
cosmos-cygwin.bat -l userlibs\ncurses\demo.co
```
