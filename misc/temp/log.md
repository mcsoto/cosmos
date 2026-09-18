==
at(alice, tavern).
at(bob, tavern).
owns(bob, key).

can_see(X, Y) :-
    at(X, Room),
    at(Y, Room).

can_take(X, Item) :-
    at(X, Room),
    at(Item, Room),
    \+ owns(_, Item).
==
POST https://api.openai.com/v1/responses
Authorization: Bearer YOUR_KEY
local json = require("dkjson")
local http = require("socket.http")
local ltn12 = require("ltn12")...
Content-Type: application/json
{
  "model": "gpt-5.6",
  "input": "What should this NPC do?"
}
const response = await openai.responses.create({
  model: "gpt-5.6",
  input: "You see a goblin. What do you do?"
});

console.log(response.output_text);
==
local Agent = {}

function Agent.think(npc, observation)
    local prompt = [[
You are controlling an NPC in a MUD.

Name: ]] .. npc.name .. [[

Goals:
]] .. table.concat(npc.goals, "\n") .. [[

Current observation:
]] .. observation .. [[

Return ONE command only.
]]

    return llm.request(prompt)
end
==
initiates(
    socialize(A, B),
    socialCooldown(A)
)

socialCooldown(A)
    → not availableForSocializing(A)
==
socialize(A, B) @ t

→ A cannot initiate another interaction until t + Δ
==
OBSERVE
  │
  ├─ current time
  ├─ current room
  ├─ schedule
  ├─ current event
  ├─ energy/focus
  └─ nearby agents ───────────────┐
                                  ↓
THINK                         SOCIAL MODEL
  │                               │
  ├─ class due?                   ├─ relationship
  ├─ event active?                ├─ interaction count
  ├─ tired?                       ├─ cooldown
  └─ opportunity to socialize? ←─┘
          │
          ↓
ACT
  ├─ move
  ├─ rest
  ├─ attend class
  ├─ cast spell
  └─ socialize
==
             WORLD / main.lua
                   │
       ┌───────────┴───────────┐
       │ positions / rooms     │
       │ time / nearby agents  │
       └───────────┬───────────┘
                   ↓
               Agent:observe()
                   ↓
               Agent:think()
                   ↓
                intention
                   │
             "socialize Mira"
                   ↓
               Agent:act()
                   │
                   ↓
             WORLD EFFECT
              ╱          ╲
 relationship change    visual effect
 =

 relationship = {
    familiarity = 0.72,
    friendship = 0.48,
    trust = 0.31,
    rivalry = 0.12,
    attraction = 0.00,

    interactions = 17,

    memories = {
        "studied together",
        "lost duel against Mira",
        "Mira helped during alchemy"
    }
}
==
Fire + Fire
    → rivalry grows faster from duels

Water + Water
    → friendship grows faster while studying

high rivalry + Dueling Club
    → seek rival

high friendship + free period
    → seek friend

low familiarity + meal
    → meet unfamiliar student
	 ==
observe:
    Rowan nearby
    Rowan = rival(63)
    current activity = Dueling Club

think:
    "Rowan is here and we're rivals.
     Challenge Rowan."

act:
    approach(Rowan)
    castSpell(...)
==

                  WORLD EVENT
                      │
         ┌────────────┴────────────┐
         ↓                         ↓
     duel(A,B)                study(A,B)
         │                         │
         ↓                         ↓
 rivalry(A,B)+              friendship(A,B)+
 respect(A,B)+                 trust(A,B)+
         │                         │
         └────────────┬────────────┘
                      ↓
                  MEMORY
                      ↓
               future THINK
                      ↓
                 new actions
