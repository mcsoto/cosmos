import test from 'node:test';
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { resolve } from 'node:path';

const require = createRequire(import.meta.url);
const SpaceCanvas = require(resolve('canvas/space-canvas-host.js'));

function fixture() {
  const calls = [];
  const context = new Proxy({
    fillStyle: '', strokeStyle: '', font: '', lineWidth: 1, textAlign: 'left',
    measureText: text => ({ width: String(text).length * 7 })
  }, { get(object, key) { if (key in object) return object[key]; return (...args) => calls.push([key, ...args]); } });
  const listeners = new Map();
  const canvas = {
    width: 320, height: 160, getContext: () => context,
    addEventListener: (name, fn) => listeners.set(name, fn),
    removeEventListener: name => listeners.delete(name),
    getBoundingClientRect: () => ({ left: 0, top: 0, width: 640, height: 320 })
  };
  return { backend: SpaceCanvas.create(canvas, { keyboardTarget: canvas }), canvas, context, calls, listeners };
}

test('colors accept CSS, normalized and byte components', () => {
  assert.equal(SpaceCanvas.cssColor(['#abc']), '#abc');
  assert.equal(SpaceCanvas.cssColor([1, .5, 0, .25]), 'rgba(255,128,0,0.25)');
  assert.equal(SpaceCanvas.cssColor([255, 128, 0, 128]), 'rgba(255,128,0,0.5019607843137255)');
});

test('portable graphics and relation-friendly canvas reach Canvas2D', () => {
  const { backend, calls, context } = fixture();
  backend.space.graphics.setColor(20, 40, 60);
  backend.space.graphics.rectangle('fill', 1, 2, 30, 40);
  backend.canvas.rect(5, 6, 7, 8, '#f00');
  backend.canvas.line(1, 2, 3, 4, '#00f', 3);
  backend.canvas.circle(12, 13, 4, '#ff0');
  backend.canvas.label('tile', 9, 10, '#0f0');
  assert.equal(context.fillStyle, 'rgba(20,40,60,1)');
  assert.deepEqual(calls.filter(call => call[0] === 'rect').map(call => call.slice(1)), [[1,2,30,40],[5,6,7,8]]);
  assert.equal(calls.filter(call => call[0] === 'fill').length, 3);
  assert.deepEqual(calls.filter(call => call[0] === 'fillText').map(call => call.slice(1)), [['tile',9,24]]);
});

test('provisional graphics exposes dt-friendly facade helpers', () => {
  const { backend, calls, context } = fixture();
  const graphics = backend.space.graphics;
  graphics.setFont(20, 'monospace');
  graphics.point(3, 4);
  graphics.shear(.5, .25);
  graphics.setScissor(0, 0, 10, 10);
  graphics.clearScissor();
  assert.equal(context.font, '20px monospace');
  assert.ok(calls.some(call => call[0] === 'transform'));
  assert.equal(graphics.getScissor(), null);
});

test('input uses logical coordinates and clears held state', () => {
  const { backend, listeners } = fixture();
  listeners.get('keydown')({ key: 'ArrowLeft' });
  listeners.get('pointerdown')({ clientX: 320, clientY: 160, button: 0 });
  assert.equal(backend.space.keyboard.isDown('left'), true);
  assert.equal(backend.space.keyboard.isDown('arrowleft'), true);
  assert.equal(backend.space.mouse.isDown(1), true);
  assert.deepEqual(backend.space.mouse.getPosition(), [160, 80]);
  listeners.get('blur')();
  assert.equal(backend.space.keyboard.isDown('arrowleft'), false);
  assert.equal(backend.space.mouse.isDown(1), false);
});

test('opaque host dispatch resolves roots, properties, setters and methods', () => {
  const { backend, canvas } = fixture();
  const canvasRef = backend.host.dispatch('root', ['js', 'canvas']);
  assert.match(canvasRef, /^@cosmos-host:[1-9][0-9]*$/);
  assert.equal(backend.host.dispatch('get', [canvasRef, 'width']), 320);
  backend.host.dispatch('set', [canvasRef, 'width', 480]);
  assert.equal(canvas.width, 480);
  const spaceRef = backend.host.dispatch('root', ['js', 'space']);
  backend.host.dispatch('method', [spaceRef, 'init', [200, 100]]);
  assert.deepEqual(backend.space.getDimensions(), [200, 100]);
});

test('Space start uses milliseconds and startCanvas converts frames per second', () => {
  const previousRequest = globalThis.requestAnimationFrame;
  const previousCancel = globalThis.cancelAnimationFrame;
  let callback, nextFrame = 0, updates = 0, draws = 0;
  globalThis.requestAnimationFrame = fn => { callback = fn; return ++nextFrame; };
  globalThis.cancelAnimationFrame = () => {};
  try {
    const { backend } = fixture();
    backend.space.start(20, { update: (dt, state) => { assert.equal(dt, 20); updates++; return state + 1; }, draw: () => { draws++; } }, 0);
    callback(1); callback(22);
    assert.equal(updates, 2);
    assert.equal(draws, 2);
    backend.space.startCanvas(50, { update: state => { updates++; return state; }, draw: () => { draws++; } }, 0);
    callback(50); callback(69); callback(71);
    assert.equal(updates, 4);
    assert.equal(draws, 4);
    backend.space.stop();
  } finally {
    globalThis.requestAnimationFrame = previousRequest;
    globalThis.cancelAnimationFrame = previousCancel;
  }
});
