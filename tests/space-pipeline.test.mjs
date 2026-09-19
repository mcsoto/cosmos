import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import vm from 'node:vm';

const require = createRequire(import.meta.url);
const SWIPL = require('../canvas/prolog-wasm/swipl-bundle.js');
const SpaceCanvas = require('../canvas/space-canvas-host.js');

test('shipped Space pipeline starts, draws, handles moves, and resets', async () => {
  const previous = globalThis.window;
  let engine;
  globalThis.window = { SWIPL: async options => (engine = await SWIPL(options)) };
  try {
    for (const file of ['cosmos-browser-assets.js', 'cosmos-swipl-assets.js', 'cosmos-swipl-session.js']) {
      vm.runInThisContext(readFileSync(new URL(`../canvas/${file}`, import.meta.url), 'utf8'), { filename: file });
    }
    const calls = [];
    const context = new Proxy({}, {
      get: (object, key) => key in object ? object[key] : (...args) => { calls.push([key, ...args]); }
    });
    const canvas = { width: 300, height: 150, getContext: () => context };
    const backend = SpaceCanvas.create(canvas);
    const session = window.CosmosSwipl.createSession().attachHost(backend.host);
    const start = async source => {
      await session.compile(source);
      const result = await session.run();
      assert.equal(result.tag, 'answer');
      assert.ok(result.tick > 0);
      assert.equal((await session.frame(result.tick)).tag, 'answer');
    };
    const checkState = goal => {
      const result = engine.prolog.query(`cosmos_space_runtime('${session.artifact.prefix}',_,_,S), ${goal}.`).once();
      assert.equal(result.error, undefined, result.message);
      assert.equal(result.success, true, goal);
    };
    const event = async (name, args) => {
      assert.equal((await session.event(name, args)).tag, 'answer');
      assert.equal((await session.frame(16)).tag, 'answer');
    };
    try {
      await start(readFileSync(new URL('../canvas/space_tictactoe.co', import.meta.url), 'utf8'));
      assert.equal(canvas.width, 600);
      assert.equal(canvas.height, 450);
      await event('mousereleased', [20, 20, 1]);
      checkState('getnil(S,"a","o"),getnil(S,"turn","x")');
      await event('mousereleased', [20, 20, 1]);
      checkState('getnil(S,"a","o"),getnil(S,"turn","x")');
      await event('mousereleased', [140, 20, 2]);
      checkState('getnil(S,"b"," ")');
      await event('mousereleased', [140, 20, 1]);
      checkState('getnil(S,"b","x"),getnil(S,"turn","o")');
      await event('mousereleased', [500, 400, 1]);
      await event('keypressed', ['r']);
      checkState('getnil(S,"a"," "),getnil(S,"b"," "),getnil(S,"turn","o")');

      await start(readFileSync(new URL('../canvas/minesweeper.co', import.meta.url), 'utf8'));
      assert.equal(canvas.width, 480);
      assert.equal(canvas.height, 424);
      await event('mousereleased', [20, 20, 1]);
      checkState('getnil(S,"moves",0.0)');
      await event('mousereleased', [24, 64, 1]);
      await event('mousereleased', [24, 64, 1]);
      checkState('getnil(S,"moves",1.0)');
      await event('mousereleased', [72, 112, 1]);
      checkState('getnil(S,"game_over",1.0)');
      await event('keypressed', ['r']);
      checkState('getnil(S,"moves",0.0),getnil(S,"game_over",0.0)');
      const mines = new Set(['2,2','5,1','8,1','4,3','7,3','1,5','6,5','9,6','3,7','8,8']);
      for (let y = 1; y <= 8; y++) for (let x = 1; x <= 10; x++) {
        if (!mines.has(`${x},${y}`)) await event('mousereleased', [(x - .5) * 48, 40 + (y - .5) * 48, 1]);
      }
      checkState('getnil(S,"moves",70.0),getnil(S,"win",fc_Won)');
      await event('keypressed', ['r']);
      checkState('getnil(S,"moves",0.0)');

      calls.length = 0;
      await start(`require('space',sp)
sp.start(16,{rel update(s,n) n=s
rel draw(s)
    sp.graphics.setColor('#abc')
    sp.graphics.rectangle('fill',1,2,3,4)
    c=js::canvas
    ctx=c.getContext('2d')
    ctx.fillStyle='#def'
    ctx.fillRect(5,6,7,8)
},0)`);
      assert.ok(calls.some(call => call[0] === 'rect' && call[1] === 1));
      assert.ok(calls.some(call => call[0] === 'fillRect' && call[1] === 5));
      assert.equal(context.fillStyle, '#def');
    } finally {
      await session.dispose();
      backend.dispose();
    }
  } finally {
    globalThis.window = previous;
  }
});

