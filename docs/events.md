# Events

The `events` standard library provides synchronous, in-process event emitters.
It is useful when a producer should notify several listeners without depending
on them directly.

```cosmos
require('events', events)

bus=events.new()
bus.on('damage', rel(payload) print(payload.amount), damageSubscription)
bus.emit('damage', {amount=10}, called)
```

An event carries one Cosmos value. Use a table or list when an event needs more
than one field.

## API

- `events.new(emitter)` creates an independent emitter.
- `emitter.on(event, callback, subscription)` adds a listener at priority `0`.
- `emitter.onPriority(event, callback, priority, subscription)` adds a listener
  at a numeric priority. Higher priorities run first; equal priorities preserve
  subscription order.
- `emitter.once(event, callback, subscription)` adds a priority `0` listener
  that is removed before its first call.
- `emitter.oncePriority(event, callback, priority, subscription)` combines
  one-shot behavior and priority ordering.
- `emitter.off(subscription, removed)` removes a subscription. `removed` is `1`
  when it was active and `0` when it had already been removed.
- `emitter.emit(event, payload, count)` synchronously calls active listeners and
  returns the number called in `count`.
- `emitter.clear(event, removed)` removes listeners for one event and returns
  the number removed.
- `emitter.clearAll(removed)` removes every listener and returns the number
  removed.
- `emitter.listenerCount(event, count)` returns the active listener count.

Subscriptions made during an emission are deferred until the next emission.
Removing a subscription during an emission prevents a listener whose turn has
not arrived from running. Callback failure or errors propagate to the emitter's
caller.
