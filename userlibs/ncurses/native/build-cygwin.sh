#!/usr/bin/env bash
# Build from a Cygwin shell after /opt/swipl-cygwin/bin/swipl is installed.
set -euo pipefail

swipl=${SWIPL:-/opt/swipl-cygwin/bin/swipl}
swipl_ld=${swipl%/swipl}/swipl-ld

if [ ! -x "$swipl" ] || [ ! -x "$swipl_ld" ]; then
  printf 'Cygwin SWI-Prolog is required at %s.\n' "$swipl" >&2
  exit 127
fi

"$swipl_ld" -pl "$swipl" -shared -o cosmos_ncurses.dll cosmos_ncurses.c \
  $(pkg-config --cflags --libs ncursesw)
