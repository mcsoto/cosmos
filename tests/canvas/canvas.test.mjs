import test from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { dirname, resolve, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';
import { swiResult, decodeValue } from '../../compiler/platform/swi-result.mjs';

// JS Canvas / SWI-WASM test bundle. Unlike `make test` (native only), these
// tests need the shipped browser engine at canvas/prolog-wasm/swipl-bundle.js
// (installed by the canvas/editor setup). When it is absent they skip
// instead of failing, so this bundle is safe to run anywhere:
//   node --test tests/canvas/canvas.test.mjs
const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const bundle = join(root, 'canvas/prolog-wasm/swipl-bundle.js');

function skipWithoutBundle(t) {
  if (!existsSync(bundle)) {
    t.skip(`missing ${bundle}; install the canvas SWI-WASM bundle to run these`);
    return true;
  }
  return false;
}

test('the identical generated compiler runs in the shipped SWI WASM engine', async (t) => {
  if (skipWithoutBundle(t)) return;
  const require = createRequire(import.meta.url);
  const SWIPL = require(join(root, 'canvas/prolog-wasm/swipl-bundle.js'));
  const engine = await SWIPL({ arguments: ['-q'], print() {}, printErr() {} });
  for (const dir of ['/src', '/libs', '/compiler/generated', '/compiler/platform']) engine.FS.mkdir(dir);
  // The runtime lives in compiler/ on disk but is mounted at /src in the WASM
  // filesystem, so the virtual layout is declared explicitly instead of being
  // derived from the repository path.
  const files = {
    '/src/swi.pl': 'compiler/swi.pl',
    '/src/reif.pl': 'compiler/reif.pl',
    '/compiler/platform/terms.pl': 'compiler/platform/terms.pl',
    '/compiler/platform/runtime.pl': 'compiler/platform/runtime.pl',
    '/compiler/platform/codec.pl': 'compiler/platform/codec.pl',
    ...Object.fromEntries(['parser', 'normalize', 'resolve', 'check', 'emit_prolog', 'compiler']
      .map(name => [`/compiler/generated/${name}.pl`, `compiler/generated/${name}.pl`])),
    ...Object.fromEntries(['string', 'list', 'table', 'math', 'logic'].map(name => [`/libs/${name}.pl`, `libs/${name}.pl`]))
  };
  for (const [target, file] of Object.entries(files)) engine.FS.writeFile(target, readFileSync(join(root, file), 'utf8'));
  const query = goal => {
    const answer = engine.prolog.query(goal).once();
    assert.equal(answer.error, undefined, answer.message);
    assert.notEqual(answer.success, false, goal);
    return answer;
  };
  query("consult('/src/swi.pl'),consult('/compiler/platform/terms.pl'),consult('/compiler/platform/runtime.pl'),nb_setval(path,'/compiler/generated/?;/libs/?'),crequire(\"compiler\",_,_)");
  for (const name of ['parser', 'normalize', 'resolve', 'check', 'emit_prolog', 'compiler']) {
    const source = readFileSync(join(root, `compiler/src/${name}.co`), 'utf8');
    const answer = query(`compiler(Api),get_(Api,"compile",Compile),call_cl(Compile,[${JSON.stringify(source)},"${name}",Code])`);
    const code = typeof answer.Code === 'string' ? answer.Code : answer.Code?.v;
    assert.equal(typeof code, 'string', name);
    engine.FS.writeFile('/actual.pl', code);
    engine.FS.writeFile('/expected.pl', readFileSync(join(root, `compiler/generated/${name}.pl`), 'utf8'));
    // SWI versions can parenthesize [] differently. Compare parsed clauses,
    // including variable sharing, rather than version-specific whitespace.
    query("read_file_to_terms('/actual.pl',Actual,[]),read_file_to_terms('/expected.pl',Expected,[]),Actual =@= Expected");
  }
  const temporalSource=readFileSync(join(root,'tests/compiler/temporal.co'),'utf8');
  const temporalAnswer=query(`compiler(Api),get_(Api,"compile",Compile),call_cl(Compile,[${JSON.stringify(temporalSource)},"temporal_wasm",Code])`);
  engine.FS.writeFile('/temporal.pl',typeof temporalAnswer.Code==='string'?temporalAnswer.Code:temporalAnswer.Code.v);
  query('consult(\'/temporal.pl\'),temporal_wasm("Temporal semantics passed")');
  const callableSource=readFileSync(join(root,'tests/compiler/callables.co'),'utf8');
  const callableAnswer=query(`compiler(Api),get_(Api,"compile",Compile),call_cl(Compile,[${JSON.stringify(callableSource)},"callables_wasm",Code])`);
  engine.FS.writeFile('/callables.pl',typeof callableAnswer.Code==='string'?callableAnswer.Code:callableAnswer.Code.v);
  query('consult(\'/callables.pl\'),nb_setval(cosmos_debug_contracts,true),callables_wasm("Callable semantics passed")');
  assert.equal(engine.prolog.query('fail').once().success, false);
  assert.equal(swiResult(engine.prolog.query('throw(codec_failure)').once()).status, 'error');
  assert.equal(swiResult(engine.prolog.query('fail').once()).status, 'failure');
  query("consult('/compiler/platform/codec.pl')");
  const encoded = query('cc_encode_value(["AB",[65,66],[]],Wire)');
  assert.deepEqual(decodeValue(encoded.Wire), ['AB',[65,66],[]]);
});

test('the shipped SWI WASM engine dispatches synchronous Canvas host calls', async (t) => {
  if (skipWithoutBundle(t)) return;
  const require = createRequire(import.meta.url);
  const SWIPL = require(join(root, 'canvas/prolog-wasm/swipl-bundle.js'));
  const previousWindow = globalThis.window;
  const calls = [];
  globalThis.window = {
    CosmosHostBridge: {
      dispatch(operation, args) {
        calls.push([operation, args]);
        return 41;
      }
    }
  };
  try {
    const engine = await SWIPL({ arguments: ['-q'], print() {}, printErr() {} });
    engine.FS.mkdir('/compiler-platform');
    engine.FS.writeFile('/compiler-platform/wasm-host.pl', `
:- use_module(library(wasm)).
:- dynamic cosmos_space_runtime/4.
cosmos_host_op("method", [_, "start", [Tick, Callbacks, State]], true) :- !,
    nb_getval(cosmos_active_prefix, Prefix),
    retractall(cosmos_space_runtime(Prefix, _, _, _)),
    assertz(cosmos_space_runtime(Prefix, Tick, Callbacks, State)).
cosmos_host_op("method", [_, "startCanvas", [Fps, Callbacks, State]], true) :- !,
    Fps > 0,
    Tick is 1000 / Fps,
    nb_getval(cosmos_active_prefix, Prefix),
    retractall(cosmos_space_runtime(Prefix, _, _, _)),
    assertz(cosmos_space_runtime(Prefix, Tick, Callbacks, State)).
cosmos_host_op(Operation, Args, Result) :-
    Result := window.'CosmosHostBridge'.dispatch(Operation, Args).
cosmos_space_info(Prefix, Tick) :- cosmos_space_runtime(Prefix, Tick, _, _).
`);
    const answer = engine.prolog.query("consult('/compiler-platform/wasm-host.pl'), cosmos_host_op(\"root\", [\"js\", \"canvas\"], Result).").once();
    assert.equal(answer.error, undefined, answer.message);
    assert.equal(answer.success, true);
    assert.equal(answer.Result, 41);
    assert.deepEqual(calls, [['root', ['js', 'canvas']]]);
    const scheduled = engine.prolog.query("nb_setval(cosmos_active_prefix, tile_ui), cosmos_host_op(\"method\", [space, \"startCanvas\", [50, callbacks, state]], true), cosmos_space_info(tile_ui, Tick).").once();
    assert.equal(scheduled.error, undefined, scheduled.message);
    assert.equal(scheduled.success, true);
    assert.equal(scheduled.Tick, 20);
    assert.deepEqual(calls, [['root', ['js', 'canvas']]], 'startCanvas must stay inside Prolog rather than passing closures to JavaScript');
  } finally {
    globalThis.window = previousWindow;
  }
});
