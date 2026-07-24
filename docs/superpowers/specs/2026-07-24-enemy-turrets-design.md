# Enemy Turrets — Design Spec

> Replaces the four static dummy targets with hostile turrets (built from the
> Kenney Space Kit `turret_single.glb` model) that track and shoot at the
> player. Introduces the player's first damage/health system, since the
> player has been invulnerable until now (the dummies never fought back).
> See `2026-07-21-realtime-combat-slice-design.md` (combat slice) and
> `2026-07-24-tank-controls-design.md` (current controls) for prior context.

## 1. Goal

Turn the arena's passive targets into enemies: each is a turret model that
rotates to face the player and fires projectiles at them on a cooldown when
in range. The player can now take damage, has HP, and respawns (reviving
all turrets) on death. Destroying every turret is the natural "clear the
arena" goal of a run.

## 2. Scope

**In scope:**
- Player health: `max_hp`/`hp`, a `take_damage(amount)` method, an on-screen
  HP bar in the existing HUD, and a respawn-on-death behavior that also
  revives all turrets.
- New `enemy_turret` scene/script replacing `dummy_target`, using
  `turret_single.glb` as the body mesh, retaining the HP / health-bar /
  hit-flash / damage-number system.
- Enemy AI: distance check, `look_at` the player, fire on a cooldown when
  in range, aim at the player's current position.
- New `enemy_projectile` scene reusing the existing `projectile.gd` logic
  but with `collision_mask = 2` (hits player) and a red emissive look.
- Lifecycle: destroyed turrets stay dead; all turrets reset when the player
  dies and respawns.

**Out of scope:**
- Leading/target-prediction aiming (shots aim at current position only).
- A formal win/game-over screen (clearing all turrets is implicit; player
  death just respawns — no overlay, no score).
- Turret-to-turret damage, friendly fire between turrets.
- Multiple turret types or difficulty scaling (all four turrets identical).
- Sound, particle hit effects beyond the existing flash.
- Any change to the player's movement/attack/weapon-swap mechanics.

## 3. Collision layers (unchanged scheme, new uses)

| Entity | layer | mask | Notes |
|---|---|---|---|
| World (floor/walls) | 1 | 0 | unchanged |
| Player (`CharacterBody3D`) | 2 | 5 | unchanged — but now *hittable* by enemy projectiles (mask 2) |
| Enemy turret (`StaticBody3D`) | 4 | 0 | same as the dummies it replaces; player melee/ranged still hit it |
| Player projectile (`Area3D`) | 0 | 4 | unchanged — hits turrets only |
| **Enemy projectile (`Area3D`)** | 0 | 2 | **new** — hits the player only |

The two projectile types never collide with each other or with the wrong
team: player shots only detect layer 4, enemy shots only detect layer 2.

## 4. Player health & respawn

`player_robot.gd` additions:
- `@export var max_hp: float = 100.0`, runtime `var hp: float`.
- `@onready var hp_bar: ProgressBar = $HUD/HPBar` — a screen-space
  `ProgressBar` added under the existing HUD `CanvasLayer` (top of screen),
  updated whenever HP changes.
- `func take_damage(amount: float) -> void`: reduce `hp` (clamped ≥ 0),
  update the bar; if `hp <= 0`, call `_respawn()`.
- `func _respawn() -> void`: restore `hp = max_hp`, move
  `global_position` back to the stored spawn point (captured in `_ready`),
  and tell every enemy turret to `reset()`.
- The duck-typed `take_damage(amount)` contract is identical to the dummies'
  / turrets', so the existing `projectile.gd` `_on_body_entered` needs **no
  change** to damage the player — it already calls `body.take_damage()` on
  whatever it hits. The player is a `CharacterBody3D` on layer 2, which the
  new enemy projectile's `Area3D` (mask 2) will detect via `body_entered`.

## 5. Enemy turret (replaces dummy_target)

- `enemy_turret.tscn`: `StaticBody3D` root, `collision_layer = 4`,
  `collision_mask = 0`. Body mesh = an instance of
  `res://assets/kenney_space-kit/Models/GLTF format/turret_single.glb`,
  likely wrapped in a pivot `Node3D` (same baked-in pivot-offset issue the
  `turret_double` model had — calibrated empirically at build time, same
  approach as the ranged-weapon-visual task). Retains the `HealthBar`
  (background + fill) and the `CollisionShape3D`.
- `enemy_turret.gd`: based on `dummy_target.gd` — keeps `max_hp`/`hp`,
  `take_damage`, `_update_health_bar`, `_flash`, `_spawn_damage_number`,
  and the health-bar/damage-number scenes. **Removes** the auto-reset
  timer; instead, on depletion it sets a `_destroyed` flag, hides, disables
  collision, and **stops shooting**. Adds a public `reset()` that revives
  it (full HP, visible, collision on) — called by the player on respawn.
- **AI** (`_physics_process`):
  - Resolve the player node once (via a group: player joins group
    `"player"`; turret does `get_tree().get_first_node_in_group("player")`).
  - If the player exists and the turret isn't destroyed: measure XZ
    distance; if `<= range`, `look_at` the player's XZ position (whole
    turret turns to face them) and decrement a `_fire_cooldown` timer;
    when it hits zero, spawn an `enemy_projectile` aimed at the player's
    current position and reset the timer to `fire_cooldown`.
  - Aim is the raw direction from the turret's muzzle to the player's
    current position — no velocity leading.

## 6. Enemy projectile

- `enemy_projectile.tscn`: an `Area3D` with `monitoring = true`,
  `monitorable = false`, `collision_layer = 0`, `collision_mask = 2`,
  a `CollisionShape3D` (`SphereShape3D`), and a `MeshInstance3D`
  (`SphereMesh`) with a red emissive `StandardMaterial3D` so incoming fire
  is visually distinct from the player's yellow projectiles. Attaches the
  existing `projectile.gd`.
- `projectile.gd` is **reused unchanged** — its `setup(direction, speed,
  damage, max_distance, attacker)` and duck-typed `take_damage` on
  `body_entered` work for enemy fire as-is (the attacker is the turret, so
  the projectile won't hit its own shooter; it will hit the player, who now
  has `take_damage`).

## 7. Arena changes

- The four `DummyTarget` instances in `arena.tscn` are replaced with four
  `enemy_turret` instances at the same positions (one close for melee, the
  others spread for ranged coverage). `dummy_target.tscn`/`.gd` and
  `damage_number.tscn`/`.gd` are left in place (damage_number is reused by
  the turret; dummy_target is kept for reference/future use, not deleted).

## 8. Numbers (placeholder, `@export`-tunable)

- Player: `max_hp = 100`, respawn at origin.
- Enemy turret: `max_hp = 60`, `fire_cooldown = 1.5s`, `range = 18.0`.
- Enemy projectile: `speed = 12.0` (slower than the player's 18 → dodgeable),
  `damage = 10.0`, `max_distance = 22.0`.

## 9. Testing / verification

Using the godot-ai MCP tools (synchronous `game_eval` where possible — the
known focus-stealing issue makes `await`-based physics-loop checks
unreliable in this session):
- A turret within range rotates to face the player and spawns enemy
  projectiles on the cooldown; out of range, it does not fire.
- An enemy projectile hitting the player reduces `player.hp` by exactly
  `damage` and updates the HP bar.
- Player melee and ranged still damage turrets (regression — exact -25.0 /
  -10.0 deltas) and a destroyed turret stays dead (no shooting, hidden).
- Driving the player's HP to 0 triggers respawn: player back at origin with
  full HP, and previously-destroyed turrets revived.
- Clearing all four turrets leaves them all dead (the implicit win state).
