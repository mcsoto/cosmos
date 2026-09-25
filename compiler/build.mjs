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
for (const file of ['src/swi.pl','src/reif.pl','compiler/platform/runtime.pl','compiler/platform/terms.pl','compiler/platform/codec.pl']) {
  hashes[file] = createHash('sha256').update(readFileSync(join(root,file))).digest('hex');
}
writeFileSync(join(root, 'compiler/generated/manifest.json'), JSON.stringify({
  format: 1, sourceLanguage: 'Cosmos', target: 'SWI-Prolog',
  verification: 'stage2 and generated are byte-identical', sha256: hashes,
}, null, 2) + '\n');

// The browser session runs these exact files from SWI-WASM.  Generate the
// bundle as part of the normal compiler build so it cannot silently drift.
const browserFiles = [
  'src/swi.pl', 'src/reif.pl',
  'compiler/platform/driver.pl', 'compiler/platform/runtime.pl', 'compiler/platform/terms.pl',
  'compiler/platform/codec.pl', 'compiler/platform/session.pl',
  ...modules.map(name => `compiler/generated/${name}.pl`)
];
const browserAssets = Object.fromEntries(browserFiles.map(file => {
  const key = file.replace(/^compiler\//, '');
  return [key, readFileSync(join(root, file)).toString('base64')];
}));
//writeFileSync(join(root, 'canvas/cosmos-swipl-assets.js'), `window.CosmosSwiplAssets = Object.freeze(${JSON.stringify(browserAssets, null, 2)});\n`); console.log(`Generated browser SWI assets from ${browserFiles.length} runtime/compiler files.`);
