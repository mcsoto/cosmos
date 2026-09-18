import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import test from 'node:test';

const productionFiles = [
  'canvas/cosmos-space-runner.js',
  'canvas/cosmos-swipl-session.js',
  'canvas/editor.html',
  'canvas/main.js',
  'canvas/os.js',
  'canvas/space-app.js'
];

test('production Space paths contain no program-specific support', async () => {
  const forbiddenProgramIdentities = /minesweeper|tic[ _-]?tac[ _-]?toe|jade[ _-]?frontier|space_welcome\.co/i;
  for (const file of productionFiles) {
    const source = await readFile(file, 'utf8');
    assert.doesNotMatch(source, forbiddenProgramIdentities, file);
  }
});

test('the SWI compiler boundary normalizes Windows line endings', async () => {
  const source = await readFile('canvas/cosmos-swipl-session.js', 'utf8');
  assert.match(source, /replace\(\/\\r\\n\?\/g, '\\n'\)/);
  assert.match(source, /async compile\(source\)[\s\S]*source = normalizeSource\(source\)/);
});
