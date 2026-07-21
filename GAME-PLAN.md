# Game plan — Robot Battler (working title)

> A game where you design and customize small robots, then battle them.
> One living document. Fill in the prompts; split into a folder later if it grows.

---

## 1. Concept & vision

- **Pitch:** _(one line — e.g. "Build a small robot from parts, then fight it in turn-based duels.")_
- **Genre / fantasy:** build + battle bots
- **Target player & platform:** _(who, and where — PC / itch.io / mobile?)_
- **Pillars** _(the 2–3 things that must be fun):_
  - Meaningful build choices (trade-offs, not just "bigger = better")
  - Readable, punchy combat
  - _(third pillar?)_

## 2. Core loop & mechanics

- **The loop:** design/upgrade bot → battle → earn rewards → upgrade → next opponent
- **Combat model:** **real-time, direct control** — you drive your robot around the arena and fight
  - **Camera:** top-down (read the whole arena; twin-stick / arena-brawler feel)
  - **Movement:** WASD, aim toward the mouse cursor
  - **Attack:** mouse click; **special/overdrive** on a second key with a cooldown
  - **Weapon decides the style:** melee weapons (buzz saw, hammer) hit at close range; ranged weapons (laser, blaster) fire projectiles toward the cursor — so the workshop choice changes how you play
  - Parts drive it directly: Armor = HP, Weapon = damage + range + melee/ranged, Engine = **movement speed**
  - Optional resource: energy/heat that limits spamming the special (carried over from the earlier design)
- **Modes:** **1v1 duel** and **arena free-for-all** (several bots, last one standing) — player picks
- **Win / lose:** last bot standing wins; your HP to 0 = defeat → back to workshop
- **Controls:** WASD move · mouse aim · click attack · key for special · (dash? block?)

## 3. Robots & parts

- **Slots:** Weapon · Armor · Engine _(more later: sensor, utility, mobility?)_
- **Power budget:** every part costs power; total must stay under budget (currently **20**) — this is the core constraint
- **Stats:** HP (armor), Attack + range + **melee/ranged type (weapon)**, **movement speed (engine)** — Speed matters directly since you drive the bot
- **Parts catalog:** _(list each part + stats + power cost — move to its own file when long)_
- **Enemy roster:** Ironclaw (first opponent) → _(add more, rising difficulty)_

## 4. Progression & economy

- **Currencies:** ⚡ energy/scrap · 🪙 coins
- **Rewards per battle:** _(how much, win vs loss)_
- **Unlocks / leveling:** _(what new parts/bots open up, and how)_
- **Difficulty curve:** _(how enemies scale vs the player's build)_

## 5. Art & audio

- **Visual style:** chunky, readable robots; dark arena + stage lighting
- **3D assets:** blocky bots built from primitives (prototype) → _(later: modeled/textured?)_
- **UI & menus:** main menu → **mode select (duel / arena)** → workshop → battle → results _(menu + workshop mockups done)_
- **Audio:** _(SFX: hits, servos, UI; music: menu vs battle)_

## 6. Tech & architecture

- **Engine:** Godot 4.7
- **Prototype location:** `res://robot_battler/` (`robot_battler.tscn` + `.gd`, self-contained)
  - Menu + workshop designs stand as-is; **battle needs reworking from turn-based → real-time WASD** (CharacterBody3D + input handling, physics movement, hit detection)
- **Note:** this lives *alongside* the separate existing project **"Last Circle"** — keep them isolated; don't repoint the main scene
- **Data model:** parts as data (name / stats / power) — _(move to Resources or a JSON table)_
- **Save data:** _(unlocked parts, currency, current build)_
- **Build & export:** _(targets — Windows / web / itch.io)_

## 7. Production roadmap

- **MVP =** workshop (pick parts under budget) + one winnable **real-time WASD** battle + result screen
  - _(menu/workshop prototype exists; battle currently turn-based — needs the real-time rework)_
- **Milestones:**
  - [ ] Real-time battle: top-down WASD movement + mouse-aim attack + hit detection
  - [ ] Melee vs ranged weapons (projectiles for ranged)
  - [ ] Enemy AI that moves and fights in real time
  - [ ] Two modes: 1v1 duel + arena free-for-all (mode select screen)
  - [ ] Parts catalog with real numbers + balance pass
  - [ ] 3+ enemies with a difficulty ramp
  - [ ] Progression: rewards → unlocks → save/load
  - [ ] Art & audio polish
  - [ ] Export & playtest build
- **Playtest checkpoints:** _(after each milestone — what to watch for)_

## 8. Scope, risks & release

- **Must-have vs nice-to-have:** _(draw the line — what's cut for v1)_
- **Stretch goals:** multiplayer, more slots, cosmetics/paint, campaign
- **Risks:** balancing the power budget; combat staying fun past 5 minutes
- **Release & distribution:** _(itch.io page, pricing/free, marketing)_

---

_Last updated: 2026-07-21_
