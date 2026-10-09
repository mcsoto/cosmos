import test from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { readFileSync, writeFileSync, mkdtempSync, existsSync } from 'node:fs';
import { dirname, resolve, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';
import { swiResult, decodeValue } from '../../compiler/platform/swi-result.mjs';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const temporary = mkdtempSync(join(root, 'tests/compiler/work-'));
const swi = process.env.SWIPL || (process.platform === 'win32' && existsSync('C:/Program Files/swipl/bin/swipl.exe')
  ? 'C:/Program Files/swipl/bin/swipl.exe' : 'swipl');
const cli = join(root, 'compiler/platform/cli.pl');
function compile(source, name = 'fixture') {
  const input = join(temporary, `${name}.co`), output = join(temporary, `${name}.pl`);
  writeFileSync(input, source);
  const result = spawnSync(swi, ['-q', '-s', cli, '--', input, output, name], { cwd: temporary, encoding: 'utf8' });
  if (result.error) throw result.error;
  return { ...result, output };
}
test('native compiler executes callbacks, captures, multiple clauses and relational failure', () => {
  const result = spawnSync(swi, ['-q', '-s', cli, '--', 'tests/compiler/semantics.co', 'tests/compiler/semantics.pl'], { cwd: root, encoding: 'utf8' });
  assert.equal(result.status, 0, result.stderr);
  const host = spawnSync(swi, ['-q', '-s', cli, '--', 'tests/compiler/host.co', 'tests/compiler/host.pl'], { cwd: root, encoding: 'utf8' });
  assert.equal(host.status, 0, host.stderr);
  const run = spawnSync(swi, ['-q', '-s', 'tests/compiler/check.pl'], { cwd: root, encoding: 'utf8' });
  assert.equal(run.status, 0, run.stderr);
  assert.match(run.stdout, /Compiler semantics passed/);
});
test('CLI resolves compiler files independently of working directory', () => {
  const result = compile("export('hello')", 'outside');
  assert.equal(result.status, 0, result.stderr);
  assert.match(readFileSync(result.output, 'utf8'), /outside\("hello"\)/);
  const run = spawnSync(swi, ['-q', '-s', join(root, 'compiler/platform/run.pl'), '--', result.output], { cwd: temporary, encoding: 'utf8' });
  assert.equal(run.status, 0, run.stderr);
  assert.equal(run.stdout.trim(), '"hello"');
});
test('colon constructs undeclared functors instead of relation calls', () => {
  const result = compile("x=:F(1,2)\nempty=:Empty\nexport([x,empty])", 'raw_functor');
  assert.equal(result.status, 0, result.stderr);
  const run = spawnSync(swi, ['-q', '-s', join(root, 'compiler/platform/run.pl'), '--', result.output, 'raw_functor'],
    { cwd: temporary, encoding: 'utf8' });
  assert.equal(run.status, 0, run.stderr);
  assert.equal(run.stdout.trim(), '[fc_F(1.0,2.0),fc_Empty]');
});
test('a bracket range lowers to the host slice operation for strings and lists', () => {
  const source = `rel sliced()
    s='hello world'
    l=[10,20,30,40,50]
    f=0
    t=2
    results=[s[0:5],s[6:#s],s[0:3]+'|'+s[3:5],l[1:3],s[3-1:5],s[0:#s],s[f:t]]
    for(result in results)
        print(result)
export({sliced=sliced})`;
  const result = compile(source, 'slice');
  assert.equal(result.status, 0, result.stderr);
  assert.match(readFileSync(result.output, 'utf8'), /slice_\(/);
  const file = result.output.replaceAll('\\', '/').replaceAll("'", "''");
  const run = spawnSync(swi, ['-q', '-s', join(root, 'compiler/platform/driver.pl'), '-g',
    `compiler_load_runtime,consult('${file}'),slice(A),get_(A,"sliced",S),call_cl(S,[]),halt`],
    { cwd: temporary, encoding: 'utf8' });
  assert.equal(run.status, 0, run.error?.message || run.stderr);
  assert.equal(run.stdout.replaceAll('\r', '').trim(),
    'hello\nworld\nhel|lo\n[20.0,30.0]\nllo\nhello world\nhe');
  // A range is only a range at the top level of the brackets: an index keeps
  // working, and a slice is a value like any other expression.
  const nested = compile("rel n()\n    s='abc'\n    x=s[1]\n    y=[s[0:2]]\n    z={k=s[0:1]}\nexport([x,y,z])", 'slice_nested');
  assert.equal(nested.status, 0, nested.stderr);
});

test('removed host namespaces cannot fall back to another compiler runtime', () => {
  const result = compile('host=lua::math\nexport(host)', 'removed_host');
  assert.notEqual(result.status, 0);
});
test('invalid and unsupported programs fail without overwriting a previous artifact', () => {
  for (const [source, message] of [
    ['rel broken(', /Unclosed delimiter/],
    ['rel a(x) true\nrel a(x,y) true', /Inconsistent declaration/],
    ['rel a(x) true\na(1,2)', /Wrong arity/],
    ['next x=1', /next is only valid inside a loop/],
  ]) {
    const previous = compile("export('preserve')");
    assert.equal(previous.status, 0, previous.stderr);
    const artifact = readFileSync(previous.output, 'utf8');
    const result = compile(source);
    assert.notEqual(result.status, 0, source);
    assert.match(result.stderr, message);
    assert.equal(readFileSync(result.output, 'utf8'), artifact);
  }
});
test('v2 modes, state, loops, protocols, constructors and contracts execute', () => {
  const compiled = spawnSync(swi, ['-q','-s',cli,'--','tests/compiler/v2.co','tests/compiler/v2.pl'], { cwd: root, encoding: 'utf8' });
  assert.equal(compiled.status,0,compiled.stderr);
  const executed = spawnSync(swi, ['-q','-s','tests/compiler/v2.plt'], { cwd: root, encoding: 'utf8' });
  assert.equal(executed.status,0,executed.stderr);
  assert.match(executed.stdout,/V2 passed/);
});
test('temporal loops preserve current values, simultaneous updates, branches and nesting', () => {
  const compiled = compile(readFileSync(join(root,'tests/compiler/temporal.co'),'utf8'),'temporal');
  assert.equal(compiled.status,0,compiled.stderr);
  const run = spawnSync(swi,['-q','-s',join(root,'compiler/platform/run.pl'),'--',compiled.output,'temporal'],
    {cwd:temporary,encoding:'utf8',timeout:15000});
  assert.equal(run.status,0,run.error?.message || run.stderr);
  assert.match(run.stdout,/Temporal semantics passed/);
  const alternatives=compile('init i=0\ninit x=0\nwhile(i<1)\n    (next x=1 or next x=2)\n    next i+=1\nexport(x)','temporal_choices');
  assert.equal(alternatives.status,0,alternatives.stderr);
  const path=alternatives.output.replaceAll('\\','/').replaceAll("'","''");
  const answers=spawnSync(swi,['-q','-s',join(root,'compiler/platform/driver.pl'),'-g',
    `compiler_load_runtime,consult('${path}'),findall(X,temporal_choices(X),Xs),Xs=[1.0,2.0],halt`],
    {cwd:root,encoding:'utf8',timeout:15000});
  assert.equal(answers.status,0,answers.error?.message || answers.stderr);
});
test('meta declarations remain unsupported in the lighter current compiler', () => {
  const result = compile(readFileSync(join(root,'tests/compiler/meta.co'),'utf8'),'meta');
  assert.notEqual(result.status,0);
  assert.match(result.stderr,/Parse error/);
});
test('temporal updates reject ambiguous paths and invalid scopes', () => {
  for (const [source,message] of [
    ['next x=1',/only valid inside a loop/],
    ['x=next y',/only valid in a loop body/],
    ['init x=0\nwhile(x<2)\n    next x=x+1\n    next x=x+1',/Multiple next assignments/],
    ['init x=0\nwhile(x<2)\n    if(x=0)\n        next x=1\n    next x=2',/Multiple next assignments/],
    ['for(init i=0;i<2;next i+=1)\n    next i=2',/Multiple next assignments/],
    ['init x=0\nwhile(x<2)\n    !x+=1\n    next x=x+1',/Use init\/next/],
    ['init x=0\nwhile(x<2)\n    callback=rel() next x=1\n    next x=x+1',/only valid inside a loop/],
    ['init x=0\nwhile(x<2)\n    y=next missing\n    next x=x+1',/requires a next assignment/],
    ['init x=0\nwhile(x<2)\n    unsafeNot(next x=1)',/cannot escape negation/],
    ['init x={a=0,b=0}\nwhile(x.a<2)\n    next x.a=1\n    next x.b=2',/Multiple next assignments/],
    ['init x=0\nwhile(x<2)\n    some(y in [1,2]) next x=y',/state-carrying loop/],
  ]) {
    const result=compile(source,'invalid_temporal');
    assert.notEqual(result.status,0,source);
    assert.match(result.stderr,message);
  }
});
test('anonymous and table callable categories and protocol determinism execute', () => {
  const compiled=compile(readFileSync(join(root,'tests/compiler/callables.co'),'utf8'),'callables');
  assert.equal(compiled.status,0,compiled.stderr);
  const path=compiled.output.replaceAll('\\','/').replaceAll("'","''");
  const run=spawnSync(swi,['-q','-s',join(root,'compiler/platform/driver.pl'),'-g',
    `compiler_load_runtime,nb_setval(cosmos_debug_contracts,true),consult('${path}'),callables("Callable semantics passed"),halt`],
    {cwd:root,encoding:'utf8',timeout:15000});
  assert.equal(run.status,0,run.error?.message || run.stderr);
  for (const [source,message] of [
    ['f=function() false\nf()',/cosmos_function_failed/],
    ['f=rel(x) det (x=1 or x=2)\nf(x)',/cosmos_determinism/],
    ['protocol(P,{rel get(x) det true})\nP p={rel get(x) (x=1 or x=2)}\np.get(x)',/cosmos_determinism/],
  ]) {
    const result=compile(source,'bad_callable');
    assert.equal(result.status,0,result.stderr);
    const file=result.output.replaceAll('\\','/').replaceAll("'","''");
    const failure=spawnSync(swi,['-q','-s',join(root,'compiler/platform/driver.pl'),'-g',
      `compiler_load_runtime,nb_setval(cosmos_debug_contracts,true),consult('${file}'),bad_callable(_),halt`],{cwd:root,encoding:'utf8',timeout:15000});
    assert.notEqual(failure.status,0,source);
    assert.match(failure.stderr,message);
  }
});
test('static call checks propagate known types and reject occupied output arguments', () => {
  const declaration='rel increment(In Number x,Out Number y) y=x+1\n';
  for(const source of [
    declaration+"increment('bad',y)",
    declaration+"x='bad'\nincrement(x,y)",
    declaration+'increment(1,2)',
    declaration+'y=2\nincrement(1,y)',
    declaration+'increment(1,y)\nincrement(2,y)',
    declaration+'rel bad(In String s) increment(s,y)',
    declaration+'rel bad(Out Number s) increment(s,y)',
    declaration+"callback=increment\ncallback('bad',y)",
    "callback=rel(In Number x,Out Number y) y=x\ncallback('bad',y)",
    declaration+'callback=rel() true\nincrement(callback,y)',
    `functor(Exp,Functor)
functor(Var,Exp String)
rel take(In Var value) true
take(Exp())`,
    'rel consume(In Number value) true\nNumber value\nconsume(value)',
  ]) {
    const result=compile(source,'static_call');
    assert.notEqual(result.status,0,source);
    assert.match(result.stderr,/No matching type\/mode signature/);
  }
  const valid=compile(declaration+'increment(1,y)\nincrement(y,z)\nexport(z)','static_valid');
  assert.equal(valid.status,0,valid.stderr);
  const freshOutput=compile('rel produce(Out Number value) value=1\nNumber value\nproduce(value)\nexport(value)','fresh_output');
  assert.equal(freshOutput.status,0,freshOutput.stderr);
  const badType=compile('rel bad(In Missing x) true','unknown_annotation');
  assert.notEqual(badType.status,0);
  assert.match(badType.stderr,/Unknown field type/);
  const badSignature=compile('Relation In Out f\nrel f(x) true','signature_arity');
  assert.notEqual(badSignature.status,0);
  assert.match(badSignature.stderr,/Wrong arity in standalone/);
});
test('undeclared calls and contradictory arithmetic types are source diagnostics', () => {
  for (const name of ['unknown_original','renamed_copy']) {
    const missing=compile("x=''\nx=1-2\np(x,y)",name);
    assert.notEqual(missing.status,0);
    assert.match(missing.stderr,/3:1: Cannot find relation p/);
    const mismatch=compile("x=''\nx=1-2",name);
    assert.notEqual(mismatch.status,0);
    assert.match(mismatch.stderr,/2:1: Expected String, got Real/);
  }
  const noncallable=compile("p='text'\np(x)",'bound_noncallable');
  assert.notEqual(noncallable.status,0);
  assert.match(noncallable.stderr,/Value is not callable: p/);
  const overloads=compile("a='item'+1\nb=[1]+[2]\nexport([a,b])",'addition_overloads');
  assert.equal(overloads.status,0,overloads.stderr);
});
test('imported table fields, nested members and callbacks retain types', () => {
  const producer=compile(`rel add(In Number x,Out Number y) y=x+1
title='text'
api={title=title,count=3,add=add,nested={label='nested',add=add}}
export(api)`,'typed_library');
  assert.equal(producer.status,0,producer.stderr);
  const prefix="require('typed_library',api)\nrel number(In Number x) true\n";
  for (const [body,pattern] of [
    ['number(api.title)',/No matching type\/mode signature for number/],
    ['number(api.nested.label)',/No matching type\/mode signature for number/],
    ['x=api.title-1',/Expected Number, got String/],
    ["api.add('bad',x)",/No matching type\/mode signature for api.add/],
    ["api.nested.add('bad',x)",/No matching type\/mode signature for api.nested.add/],
    ['api.title(x)',/Exported field is not callable/],
    ['api.missing(x)',/Unknown imported member/],
    ['x=api.missing',/Unknown imported member/],
    ["f=api.add\nf('bad',x)",/No matching type\/mode signature for f/],
  ]) {
    const result=compile(prefix+body,'typed_consumer');
    assert.notEqual(result.status,0,body);
    assert.match(result.stderr,pattern);
  }
  const valid=compile(prefix+'number(api.count)\napi.add(2,result)\nexport(result)','typed_consumer');
  assert.equal(valid.status,0,valid.stderr);
  const run=spawnSync(swi,['-q','-s',join(root,'compiler/platform/run.pl'),'--',valid.output],{cwd:temporary,encoding:'utf8',timeout:15000});
  assert.equal(run.status,0,run.error?.message||run.stderr);
  assert.equal(run.stdout.trim(),'3.0');
});
test('protocol behavior checks require debug mode and a typed protocol view', () => {
  const source=`Protocol(Moving,{
    Number x
    rel p(Number x)
        x>2
})
Protocol(Readable,{
    rel read(Out Number result) true
})
Protocol(NumberReader,{
    Relation Number read
})
o={x=3,rel p(Number value) true}
o is Moving
Moving checked=o
o.p(1)
reader={rel read(Out Number result) result=3}
reader is Readable
reader is NumberReader
input=1
checked.p(input)
export('interfaces passed')`;
  const compiled=compile(source,'protocol_interface');
  assert.equal(compiled.status,0,compiled.stderr);
  const file=compiled.output.replaceAll('\\','/').replaceAll("'","''");
  for (const debug of [false,true]) {
    const goal=debug
      ? 'catch((protocol_interface(_),fail),error(cosmos_protocol_behavior("Moving","p"),_),true)'
      : 'protocol_interface("interfaces passed")';
    const run=spawnSync(swi,['-q','-s',join(root,'compiler/platform/driver.pl'),'-g',
      `compiler_load_runtime,nb_setval(cosmos_debug_contracts,${debug}),consult('${file}'),${goal},halt`],
      {cwd:root,encoding:'utf8',timeout:15000});
    assert.equal(run.status,0,run.error?.message||run.stderr);
  }
  const debugCli=spawnSync(swi,['-q','-s',join(root,'compiler/platform/repl.pl'),'--','-d','-q',source],
    {cwd:root,encoding:'utf8',timeout:15000});
  assert.notEqual(debugCli.status,0);
  assert.match(debugCli.stderr,/cosmos_protocol_behavior/);
});
test('a protocol body is proven at compile time and deferred whenever an operand is unknown', () => {
  const protocol=`protocol(Positive,{
    Number size
    rel accept(In Number x)
        x>2
})
`;
  const declared=value=>`${protocol}Positive object={size=3,rel accept(x) true}\nobject.accept(${value})\n`;
  // A literal that cannot satisfy the body is rejected before any code exists.
  for (const [value,pattern] of [
    ['1',/Compile error at 7:8: Protocol contract violation: accept requires 1\.0 > 2\.0/],
    ['2',/Protocol contract violation: accept requires 2\.0 > 2\.0/],
    ['0',/Protocol contract violation: accept requires 0\.0 > 2\.0/],
  ]) {
    const result=compile(declared(value),'static_contract');
    assert.notEqual(result.status,0,value);
    assert.match(result.stderr,pattern);
  }
  // Everything the static evaluator cannot decide is left to the runtime check:
  // a satisfying literal, a variable, a computed value, a negated literal and a
  // non-numeric field are all unproven rather than rejected.
  for (const value of ['5','3','value','1+2','-1','size']) {
    const result=compile(declared(value),'static_contract');
    assert.equal(result.status,0,`${value}: ${result.stderr}`);
  }
  // A protocol method reached through a plain name is not resolved either.
  const plain=compile(`${protocol}Positive object={size=3,rel accept(x) true}\nmethod=object.accept\nmethod(1)`,
    'static_contract_alias');
  assert.equal(plain.status,0,plain.stderr);
});
test('trace flag works before and after the file, with nested calls and ordinary output', () => {
  const source='rel q(x) x=1\nrel p(x)\n    q(x)\n    print(x)\np(value)';
  const input=join(temporary,'trace_calls.co');
  writeFileSync(input,source);
  const repl=join(root,'compiler/platform/repl.pl');
  for (const args of [['-t','-l',input],['-l',input,'-t'],['-q',source,'-t']]) {
    const run=spawnSync(swi,['-q','-s',repl,'--',...args],{cwd:temporary,encoding:'utf8',timeout:15000});
    assert.equal(run.status,0,run.stderr);
    assert.match(run.stdout,/^(?:\| )?::main\(\)\r?\n\|p\(#var\d+\)\r?\n\|\|q\(#var\d+\)\r?\n\|\|print\(1\)\r?\n1\.0\r?\n\[\]/);
  }
  assert.match(readFileSync(join(temporary,'trace_calls.pl'),'utf8'),/cosmos_trace_call/);
  const untraced=compile(source,'trace_calls_plain');
  assert.equal(untraced.status,0,untraced.stderr);
  assert.doesNotMatch(readFileSync(untraced.output,'utf8'),/cosmos_trace_call/);
  const plain=spawnSync(swi,['-q','-s',repl,'--','-l',input],{cwd:temporary,encoding:'utf8',timeout:15000});
  assert.equal(plain.status,0,plain.stderr);
  assert.equal(plain.stdout.replaceAll('\r','').trim(),'1.0\n[]');
  const native=spawnSync(swi,['-q','-s',repl,'--','-q',
    "string.size('abc',n)\npl::string('abc')\nprint(n)",'-t'],
    {cwd:temporary,encoding:'utf8',timeout:15000});
  assert.equal(native.status,0,native.stderr);
  assert.match(native.stdout,/\|string\.size\("abc",#var\d+\)/);
  assert.match(native.stdout,/\|pl::string\("abc"\)/);
  assert.match(native.stdout,/\|print\(3\)/);
  // The operand is a variable, so the contract is deferred to the runtime
  // check and still surfaces as cosmos_protocol_behavior.
  const violation='Protocol(P,{rel p(Number x) x>2})\nP o={rel p(Number x) true}\nn=1\no.p(n)';
  const debug=spawnSync(swi,['-q','-s',repl,'--','-q',violation,'-t'],{cwd:temporary,encoding:'utf8',timeout:15000});
  assert.notEqual(debug.status,0);
  assert.match(debug.stderr,/cosmos_protocol_behavior/);
});
test('trace depth survives alternatives, failure, exceptions and pruning without changing bindings', () => {
  const goal=`compiler_load_runtime,nb_setval(cosmos_trace_enabled,true),
    findall(X,cosmos_trace_call("root",[X],(member(X,[1,2]),cosmos_trace_call("leaf",[X],true))),[1,2]),
    \u005c+cosmos_trace_call("fail",[],fail),
    catch(cosmos_trace_call("throw",[],throw(probe)),probe,true),
    once(cosmos_trace_call("once",[Y],member(Y,[1,2]))),Y=1,
    cosmos_trace_call("after",[],true),halt`;
  const run=spawnSync(swi,['-q','-s',join(root,'compiler/platform/driver.pl'),'-g',goal],
    {cwd:temporary,encoding:'utf8',timeout:15000});
  assert.equal(run.status,0,run.stderr);
  assert.match(run.stdout,/^root\(#var\d+\)\r?\n\|leaf\(1\)\r?\n\|leaf\(2\)\r?\nfail\(\)\r?\nthrow\(\)\r?\nonce\(#var\d+\)\r?\nafter\(\)/);
});
test('known is mismatches, missing local fields and reserved new have static diagnostics', () => {
  for(const [source,message] of [
    ['rel move(this,x,y,this2) x=1\nmove is Number',/Expected Number, got Relation/],
    ["object={x=2}\nupdate=object.update\nupdate()",/Field update does not exist in table/],
    ["object={x=2}\nobject.update()",/Field update does not exist in table/],
    ["rel check()\n    t={x=2}\n    y=t.missing",/Field missing does not exist in table/],
    ['Protocol(P,{Number x})\no={}\no is P',/Missing protocol member: x/],
    ["Protocol(P,{Number x})\no={x='bad'}\no is P",/Expected Number, got String/],
    ["t={'new'=new}",/new is a reserved keyword/],
  ]) {
    const result=compile(source,'interface_error');
    assert.notEqual(result.status,0,source);
    assert.match(result.stderr,message);
  }
});
test('typed functors validate nominal parents, arity and known field values', () => {
  const declarations = `functor(Exp,Functor)
functor(Op,Functor)
functor(Binary,Op String Exp Exp)
functor(Var,Exp String)
functor(Call,Exp Exp List)
`;
  const valid = compile(declarations + "export(Binary('+',Var('x'),Call(Var('f'),[])))", 'typed');
  assert.equal(valid.status, 0, valid.stderr);
  for (const [source, message] of [
    [declarations + "export(Binary('+',Var('x')))", /Wrong functor arity/],
    [declarations + "export(Binary('+','x',Var('y')))", /Expected Exp, got String/],
    [declarations + 'export(Var(42))', /Expected String, got Real/],
    ['functor(Binary,Op String)', /Unknown functor subtype/],
    ['functor(A,B)\nfunctor(B,A)', /Cyclic functor subtype/],
    ['functor(A,Functor Missing)', /Unknown field type/],
    ['Factory={}\nexport(new Factory())', /Cannot resolve constructor/],
    ['Factory={new=2}\nexport(new Factory())', /Constructor is not callable/],
    ['Factory={rel new(result,x) result=x}\nexport(new Factory())', /Wrong constructor arity/],
    ['protocol(P,{\nNumber size\n})\nP value={}', /Missing protocol member/],
    ['protocol(P,{\nNumber size\n})\nP value={size="bad"}', /Expected Number, got String/],
    ['protocol(P,{rel put(In Number x) true})\nP p={rel put(Out Number x) x=1}', /Incompatible protocol method mode/],
    ['protocol(P,{rel get(Out Number x) true})\nP p={rel get(In Number x) true}', /Incompatible protocol method mode/],
    ['protocol(P,{rel get(Out Number x) true})\nP p={rel get(Out String x) x="bad"}', /Expected Number, got String/],
  ]) {
    const result = compile(source, 'invalid_type');
    assert.notEqual(result.status, 0, source);
    assert.match(result.stderr, message);
  }
});
test('some succeeds with empty exports and fails only when no item matches', () => {
  for (const [source, status, output] of [
    ['some(x in [1,2]) x>1',0,'[]'],
    ['some(x in [1,2]) x>5',1,''],
  ]) {
    const result = compile(source,'existential');
    assert.equal(result.status,0,result.stderr);
    const run = spawnSync(swi,['-q','-s',join(root,'compiler/platform/run.pl'),'--',result.output],{cwd:temporary,encoding:'utf8'});
    assert.equal(run.status,status,run.stderr);
    assert.equal(run.stdout.trim(),output);
  }
});
test('codec preserves strings, numeric lists, shared variables and empty successes', () => {
  const result = spawnSync(swi, ['-q', '-s', 'tests/compiler/codec.pl'], { cwd: root, encoding: 'utf8' });
  assert.equal(result.status, 0, result.stderr);
  assert.deepEqual(swiResult({ success: false }), { status: 'failure' });
  assert.equal(swiResult({ error: true, success: false, message: 'bad' }).status, 'error');
  assert.equal(swiResult({ success: true, Output: [] }).status, 'success');
  assert.equal(decodeValue({ type: 'string', value: 'AB' }), 'AB');
  assert.deepEqual(decodeValue({ type: 'list', items: [65,66].map(value => ({ type: 'number', value })) }), [65,66]);
  const vars = decodeValue({ type: 'list', items: [{ type: 'variable', id: 0 }, { type: 'variable', id: 0 }] });
  assert.equal(vars[0],vars[1]);
  assert.equal(decodeValue({ type: 'integer', value: '9007199254740993' }), 9007199254740993n);
});
test('compile_query compiles Cosmos fragments with ordered result metadata', () => {
  const driver = join(root, 'compiler/platform/driver.pl');
  const goal = [
    "compiler_load('compiler/generated')",
    'compiler(Api)',
    'get_(Api,"compile_query",CompileQuery)',
    'call_cl(CompileQuery,["x = 2\\ny = x + 1\\n",["y","x"],"query_fixture",Query])',
    'getnil(Query,"module",Module)',
    'getnil(Query,"entry",Entry)',
    'getnil(Query,"variables",Names)',
    'getnil(Query,"prolog",Code)',
    'format("~q~n",[query_metadata(Module,Entry,Names,Code)])',
    'halt',
  ].join(',');
  const result = spawnSync(swi, ['-q', '-s', driver, '-g', goal], { cwd: root, encoding: 'utf8' });
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /query_metadata\("query_fixture","query_fixture",\["y","x"\],/);
  assert.match(result.stdout, /query_fixture\(\[A,B\]\):-B=2\.0/);
  assert.doesNotMatch(result.stdout, /cosmos_trace_call/);
  assert.match(result.stdout, /B=2\.0,add_\(B,1\.0,C\),A=C/);
});
test('Cosmos CLI and REPL use compile_query for selected variables', () => {
  const repl = join(root, 'compiler/platform/repl.pl');
  const plainOneShot = spawnSync(swi, ['-q', '-s', repl, '--', '-q', 'x=2'], { cwd: root, encoding: 'utf8' });
  assert.equal(plainOneShot.status, 0, plainOneShot.stderr);
  assert.equal(plainOneShot.stdout.trim(), '| []');
  const oneShot = spawnSync(swi, ['-q', '-s', repl, '--', '-q', 'x = 2', '--vars', 'x'], { cwd: root, encoding: 'utf8' });
  assert.equal(oneShot.status, 0, oneShot.stderr);
  assert.equal(oneShot.stdout.trim(), '| [2.0]');
  const interactive = spawnSync(swi, ['-q', '-s', repl], {
    cwd: root,
    encoding: 'utf8',
    input: ':vars x\nx = 2\n:quit\n',
  });
  assert.equal(interactive.status, 0, interactive.stderr);
  assert.match(interactive.stdout, /returning: \[x\]/);
  assert.match(interactive.stdout, /\[2\.0\]/);
  const printed = spawnSync(swi, ['-q', '-s', repl, '--', '-q', 'print("streamed")'], { cwd: root, encoding: 'utf8' });
  assert.equal(printed.status, 0, printed.stderr);
  assert.match(printed.stdout, /\| streamed/);
});
test('-l file -q compiles a fragment in the file lexical scope', () => {
  const repl = join(root, 'compiler/platform/repl.pl');
  const result = spawnSync(swi, ['-q', '-s', repl, '--', '-l', 'tests/compiler/query_scope.co', '-q', 'main(x)', '--vars', 'x'], {
    cwd: root, encoding: 'utf8',
  });
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /loaded/);
  assert.match(result.stdout, /\[42\.0\]/);
});
test('--main adds an argv-list entry point for main/1', () => {
  const source = join(root, 'tests/compiler/main_args.co');
  const output = join(temporary, 'main_args.pl');
  const result = spawnSync(swi, ['-q', '-s', cli, '--', source, output, '--main'], { cwd: root, encoding: 'utf8' });
  assert.equal(result.status, 0, result.stderr);
  assert.match(readFileSync(output, 'utf8'), /initialization\(cosmos_entry_main, main\)/);
  const run = spawnSync(swi, ['-q', '-s', output, '--', 'Ada'], { cwd: temporary, encoding: 'utf8' });
  assert.equal(run.status, 0, run.stderr);
  assert.equal(run.stdout.trim(), 'Ada');
});
test('--exe saves a standalone main/1 application', () => {
  const source = join(root, 'tests/compiler/main_args.co');
  const output = join(temporary, 'main_args_exe.pl');
  const result = spawnSync(swi, ['-q', '-s', cli, '--', source, output, '--exe'], { cwd: root, encoding: 'utf8' });
  assert.equal(result.status, 0, result.stderr);
  const executable = output.replace(/\.pl$/, '.exe');
  assert.equal(existsSync(executable), true, executable);
  const run = spawnSync(executable, ['Ada'], { cwd: temporary, encoding: 'utf8' });
  assert.equal(run.status, 0, run.error?.message || run.stderr);
  assert.equal(run.stdout.trim(), 'Ada');
});
