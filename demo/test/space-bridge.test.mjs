import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import test from 'node:test';
import vm from 'node:vm';

const require = createRequire(import.meta.url);
const SpaceCanvas = require('../space-canvas-host.js');

function fakeCanvas() {
  const context = {
    fillStyle: '#000', strokeStyle: '#000', font: '', lineWidth: 1,
    save() {}, restore() {}, setTransform() {}, clearRect() {}, fillRect() {},
    beginPath() {}, rect() {}, fill() {}, stroke() {}, moveTo() {}, lineTo() {},
    arc() {}, ellipse() {}, closePath() {}, translate() {}, rotate() {}, scale() {},
    clip() {}, fillText() {}, drawImage() {}, measureText() { return { width: 0 }; }
  };
  return {
    width: 320, height: 160,
    getContext(kind) { assert.equal(kind, '2d'); return context; },
    getBoundingClientRect() { return { left: 0, top: 0, width: 320, height: 160 }; },
    addEventListener() {}, removeEventListener() {}
  };
}

test('js::canvas host root exposes the native Canvas2D object', () => {
  const canvas = fakeCanvas();
  const backend = SpaceCanvas.create(canvas, { keyboardTarget: null });
  assert.equal(backend.space.apiVersion, 2);
  assert.throws(() => SpaceCanvas.create(fakeCanvas(), { apiVersion: 3 }), /v3 is not implemented/);
  const nativeCanvas = backend.host.root('js', 'canvas');
  const nativeContext = backend.host.method(nativeCanvas, 'getContext', ['2d']);
  assert.equal(backend.host.get(nativeContext, 'fillStyle'), '#ffffff');
  const legacyCanvas = backend.host.root('js', 'canvasLegacy');
  assert.equal(backend.host.get(legacyCanvas, 'raw').host, nativeCanvas.host);
  backend.dispose();
});

test('Space runner routes canvas-local input and stops on a failed frame', async () => {
  let scheduled = null, disposed = 0, reported = null;
  const listeners = new Map(), events = [];
  const runnerCanvas = {
    tabIndex: -1,
    addEventListener(name, handler) { listeners.set(name, handler); },
    removeEventListener(name) { listeners.delete(name); },
    focus() {}
  };
  const session = {
    attachHost() { return this; },
    async compile() {}, async load() {},
    async run() { return { tag: 'answer', tick: 16, bindings: {} }; },
    async frame(dt) { assert.equal(dt, 16); return { tag: 'failure' }; },
    async event(name, args) { events.push([name, args]); return { tag: 'answer' }; },
    async dispose() { disposed += 1; }
  };
  const context = {
    window: null,
    requestAnimationFrame(callback) { scheduled = callback; return 1; },
    cancelAnimationFrame() { scheduled = null; },
    CosmosSwipl: { createSession: () => session },
    SpaceCanvas: { create: () => ({ host: {}, space: { init() {} }, dispose() {} }) },
    console: { error() {} }
  };
  context.window = context;
  vm.runInNewContext(readFileSync(new URL('../cosmos-space-runner.js', import.meta.url), 'utf8'), context);
  const runner = context.CosmosSpaceRunner.create(runnerCanvas, { onError: error => { reported = error; } });
  await runner.run('export(true)');
  listeners.get('keydown')({ key: 'R' });
  await new Promise(resolve => setImmediate(resolve));
  assert.equal(events.length, 1);
  assert.equal(events[0][0], 'keypressed');
  assert.equal(events[0][1][0], 'r');
  listeners.get('keydown')({ key: 'ArrowLeft' });
  await new Promise(resolve => setImmediate(resolve));
  assert.equal(events[1][1][0], 'left');
  scheduled(20);
  await new Promise(resolve => setImmediate(resolve));
  assert.match(reported?.message || '', /update callback failed/);
  assert.equal(disposed, 1);
  assert.equal(scheduled, null);
});
