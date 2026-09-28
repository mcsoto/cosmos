import { spawnSync } from 'node:child_process';
import { mkdirSync, readFileSync, existsSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { dirname, resolve, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const modules = ['parser', 'normalize', 'resolve', 'check', 'emit_prolog', 'compiler'];
const swipl = process.env.SWIPL || (process.platform === 'win32' && existsSync('C:/Program Files/swipl/bin/swipl.exe')
  ? 'C:/Program Files/swipl/bin/swipl.exe' : 'swipl');
function run(command, args) {
  const result = spawnSync(command, args, { cwd: root, encoding: 'utf8' });
  if (result.error || result.status !== 0) throw new Error(result.error?.message || result.stderr || result.stdout || `${command} failed`);
}
let stage = 'compiler/seed';
for (const output of ['compiler/stage1', 'compiler/stage2', 'compiler/generated']) {
  mkdirSync(join(root, output), { recursive: true });
  for (const name of modules) run(swipl, ['-q', '-s', 'compiler/platform/build.pl', '--', stage,
    `compiler/src/${name}.co`, `${output}/${name}.pl`, name]);
  stage = output;
}
for (const name of modules) {
  const previous = readFileSync(join(root, `compiler/stage2/${name}.pl`));
  const current = readFileSync(join(root, `compiler/generated/${name}.pl`));
  if (!previous.equals(current)) throw new Error(`Bootstrap did not stabilize: ${name}`);
}
console.log(`Verified: all ${modules.length} Cosmos compiler modules rebuild identically without Lua.`);
const hashes = {};
for (const name of modules) for (const [directory, extension] of [['src', 'co'], ['seed', 'pl'], ['generated', 'pl']]) {
  const file = `compiler/${directory}/${name}.${extension}`;
  hashes[file] = createHash('sha256').update(readFileSync(join(root, file))).digest('hex');
}
for (const file of ['compiler/swi.pl','compiler/reif.pl','compiler/platform/runtime.pl','compiler/platform/terms.pl','compiler/platform/codec.pl']) {
  hashes[file] = createHash('sha256').update(readFileSync(join(root,file))).digest('hex');
}
writeFileSync(join(root, 'compiler/generated/manifest.json'), JSON.stringify({
  format: 1, sourceLanguage: 'Cosmos', target: 'SWI-Prolog',
  verification: 'stage2 and generated are byte-identical', sha256: hashes,
}, null, 2) + '\n');

// Browser and Electron front ends need these same artifacts as base64 bundles,
// but that packaging belongs to the Canvas/editor side of the project rather
// than to the compiler. This build therefore never writes outside compiler/;
// produce any browser bundle from a separate, explicitly invoked step.
