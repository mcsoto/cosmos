# Cosmos

Cosmos is compiled by the self-hosted compiler in [`compiler/src`](compiler/src)
and runs on SWI-Prolog. The active compiler has no Lua dependency.

See the [current compiler user guide](compiler/GUIDE.md) for language syntax,
classes, protocols, modules, applications, the REPL, and host integration.

Compile a program on Windows:

```powershell
cs.cmd input.co output.pl module_name
```

Or invoke the platform directly:

```powershell
swipl -q -s compiler/platform/cli.pl -- input.co output.pl module_name
```

Rebuild and test:

```powershell
node compiler/build.mjs
node --test tests/compiler/compiler.test.mjs
```

The retired Lua compiler and its historical documentation are isolated under
[`legacy/lua-compiler`](legacy/lua-compiler). Nothing in the active compiler,
launcher, tests, or installer requires that folder.
