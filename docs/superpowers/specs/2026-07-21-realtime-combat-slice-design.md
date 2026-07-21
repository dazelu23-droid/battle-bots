# Real-Time Combat Slice — Design Spec

> First buildable slice of Robot Battler (see `GAME-PLAN.md`), scoped to milestone 1 of the
> production roadmap: real-time WASD movement + mouse-aim attack + hit detection, validated
> against static dummy targets. No workshop, parts system, or enemy AI yet — those are later
> milestones.

## 1. Goal

Prove out the core combat feel (movement, aiming, melee vs. ranged attacks, hit feedback)
before investing in the workshop/parts system on top of it. Success = a single controllable
robot in an arena that can move, aim, swap between a melee and a ranged weapon, and land
readable hits on multiple static dummy targets.

## 2. Scope

**In scope:**
- Top-down 3D arena with boundary walls
- Player-controlled robot: WASD movement, mouse-aim rotation, weapon swap, melee attack,
  ranged (projectile) attack
- Multiple static dummy targets at varying range/angle, each with HP, hit feedback, and
  auto-reset after depletion
- Placeholder/tunable stats via `@export` vars (no data-driven parts system yet)

**Out of scope (later milestones):**
- Workshop / parts picking / power budget
- Enemy AI (dummies do not move or fight back)
- Special/overdrive ability
- Progression, save/load, art & audio polish, duel/arena modes

## 3. Scene & entity structure

- `res://robot_battler/arena.tscn` — main scene for this slice. Flat blockout-gray floor,
  boundary walls, a top-down `Camera3D` that follows the player robot, one `PlayerRobot`
  instance, and 3–4 `DummyTarget` instances placed at varying distances/angles (some close
  for melee testing, some far for ranged testing).
- `res://robot_battler/player_robot.tscn` — `CharacterBody3D` root built from primitive
  meshes (box body + cylinder turret that rotates to face the mouse-aim point). Script
  handles movement, aiming, weapon swap, and attacks.
- `res://robot_battler/dummy_target.tscn` — `StaticBody3D` with a hit-detection `Area3D`,
  an HP value, a world-space health bar, flash-on-hit feedback, and auto-reset when depleted.
- `res://robot_battler/melee_hitbox.tscn` — reusable `Area3D` wedge/box hitbox spawned by
  the player's melee attack.
- `res://robot_battler/projectile.tscn` — reusable `Area3D` projectile spawned by the
  player's ranged attack.

## 4. Movement & controls

- **Move:** WASD drives `CharacterBody3D.velocity` on the XZ plane at a fixed placeholder
  speed via `move_and_slide()`.
- **Aim:** raycast from the camera through the mouse position onto the ground plane (y=0);
  the robot/turret rotates to face that point every frame.
- **Weapon swap:** `Q` toggles the equipped weapon between melee and ranged; an on-screen
  label shows which is currently active.
- **Attack:** left click fires whichever weapon is currently equipped.

## 5. Attacks

- **Melee:** on click, spawn `melee_hitbox.tscn` positioned in front of the robot, enabled
  for a short swing window (~0.15s), then freed. Tracks already-hit bodies per swing so a
  single swing can't multi-hit the same target. Short cooldown after each swing prevents
  spamming.
- **Ranged:** on click, spawn `projectile.tscn` at the robot's muzzle position, moving
  toward the aimed point at a fixed speed in `_physics_process`. Its `Area3D` deals damage
  on contact and frees itself on hit or after a max travel distance/lifetime. Short cooldown
  between shots.
- Placeholder numbers for now (e.g. melee: higher damage / short range; ranged: lower
  damage / long range, faster projectile) — to be replaced by real part stats when the
  workshop milestone lands.

## 6. Feedback & dummy targets

- **On hit:** dummy flashes color (brief `modulate` tween on its mesh material), HP bar
  updates, a small floating damage number (`Label3D`) rises and fades, then frees itself.
- **On depletion:** dummy plays a brief "destroyed" flash/scale-down, then after a short
  delay resets to full HP and reappears — keeps the arena usable indefinitely without a
  manual reset.

## 7. Data model

Stats (HP, melee damage/range, ranged damage/speed/range, move speed) live as `@export`
vars directly on the robot/weapon scripts, tunable from the Inspector. No Resource/JSON
parts system yet — that's introduced with the workshop milestone.

## 8. Testing / verification

Run via the godot-ai `project_run` tool in the Godot editor and confirm:
- Robot moves smoothly in all directions
- Turret/facing tracks the mouse cursor
- `Q` swaps weapon and the on-screen label updates
- Melee connects on nearby dummies; a single swing doesn't multi-hit
- Projectiles travel visibly and hit distant dummies
- HP bars and floating damage numbers appear correctly on hit
- Dummies reset to full HP after a short delay following depletion

Use `editor_screenshot` at checkpoints to visually confirm scene state during development.
