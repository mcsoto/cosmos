import test, { after } from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const guide = readFileSync(join(root, 'compiler/GUIDE.md'), 'utf8');
const temporary = mkdtempSync(join(root, 'tests/compiler/guide-work-'));
const swi = process.env.SWIPL || (process.platform === 'win32' && existsSync('C:/Program Files/swipl/bin/swipl.exe')
  ? 'C:/Program Files/swipl/bin/swipl.exe' : 'swipl');
const cli = join(root, 'compiler/platform/cli.pl');

after(() => rmSync(temporary, { recursive: true, force: true }));

test('every Cosmos example in the compiler guide compiles', () => {
  const examples = [...guide.matchAll(/```cosmos\s*\r?\n([\s\S]*?)```/g)].map(match => match[1].trimEnd());
  assert.ok(examples.length >= 15, 'expected a substantial executable feature tour');

  examples.forEach((source, index) => {
    const namedFile = source.match(/^\/\/\s*file:\s*([A-Za-z][A-Za-z0-9_-]*)\.co\s*$/m)?.[1]
      ?? source.match(/^\/\/\s*([A-Za-z][A-Za-z0-9_-]*)\.co\s*$/m)?.[1];
    const name = namedFile ?? `guide_${index + 1}`;
    const input = join(temporary, `${name}.co`);
    const output = join(temporary, `${name}.pl`);
    writeFileSync(input, source);
    const result = spawnSync(swi, ['-q', '-s', cli, '--', input, output, name], {
      cwd: temporary,
      encoding: 'utf8',
      timeout: 15000,
    });
    assert.equal(result.status, 0,
      `GUIDE.md Cosmos example ${index + 1} (${name}) did not compile:\n${result.stderr}`);
  });
});
