```
state(travelling) u. arrive(home)
agent dragon {
    i. state(sleeping)

    hungry ->
        n. state(awake)

    state(flying) u. arrive(volcano)
}
--                 CAgent SOURCE
``````
         i. state(sleeping)

         hungry ->
             n. state(awake)

         state(flying)
             u. arrive(volcano)


                       │ compile
                       ▼


               TEMPORAL IR

    initial state(sleeping)

    hungry(T)
        -> state(awake,T+1)

    flying(T0)
        -> flying persists until arrive(T1)


                       │ execute
                       ▼


                GAME RUNTIME

    current fluents
    scheduled events
    active processes
    dependency-triggered rules
--
process travel {
    state = travelling
    until = arrive(destination)
}
--i.      init / first
n.      next / ○
u.      strong until / U

possibly later:

p.      previous
e.      eventually / ◇
a.      always / □
wu.     weak until
```
