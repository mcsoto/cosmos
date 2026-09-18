import test from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { existsSync, mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const swi = process.env.SWIPL || (process.platform === 'win32'
  && existsSync('C:/Program Files/swipl/bin/swipl.exe')
  ? 'C:/Program Files/swipl/bin/swipl.exe' : 'swipl');
const cli = resolve(root, 'compiler/platform/cli.pl');

test('events library dispatches and manages subscriptions', () => {
  const output = mkdtempSync(join(tmpdir(), 'cosmos-events-'));
  const generatedLibrary = join(output, 'events.pl');
  const generatedFixture = join(output, 'events-fixture.pl');
  const library = spawnSync(swi, ['-q', '-s', cli, '--', 'libs/events.co', generatedLibrary, 'events'], {
    cwd: root,
    encoding: 'utf8',
  });
  assert.equal(library.status, 0, library.error?.message || library.stderr);

  const fixture = spawnSync(swi, ['-q', '-s', cli, '--', 'tests/events.co', generatedFixture, 'events_test'], {
    cwd: root,
    encoding: 'utf8',
  });
  assert.equal(fixture.status, 0, fixture.error?.message || fixture.stderr);

  const run = spawnSync(swi, ['-q', '-s', 'compiler/platform/run.pl', '--', generatedFixture, 'events_test'], {
    cwd: root,
    encoding: 'utf8',
  });
  assert.equal(run.status, 0, run.error?.message || run.stderr);
  assert.equal(run.stdout.trim(), '"events tests passed"');
});
