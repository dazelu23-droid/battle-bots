# Tank Controls — Design Spec

> Replaces the player robot's twin-stick control scheme (world-axis WASD
> strafe + independent mouse-aim turret) with classic tank controls
> (W/S move along facing, A/D turn the whole robot) now that the ranged
> weapon has a real model worth aiming deliberately rather than by cursor.
> See `2026-07-21-realtime-combat-slice-design.md` (original combat slice)
> and `2026-07-24-ranged-weapon-visual-design.md` (weapon model) for prior
> context.

## 1. Goal

`A`/`D` turn the whole robot; the turret no longer follows the mouse.
Movement and attack direction both become a function of the robot's facing,
not the cursor.

## 2. Scope

**In scope:**
- Rework movement: `W`/`S` move along current facing, `A`/`D` rotate the
  whole `CharacterBody3D` root at a tunable turn rate.
- Remove mouse-raycast aiming entirely (`_handle_aim()`, `aim_point`, the
  ground-plane raycast) — attacks fire in the robot's facing direction.
- Fix the top-down camera so it keeps following position but no longer
  inherits the robot's new rotation (would otherwise spin the screen).
- Rename the `move_left`/`move_right` input actions to `turn_left`/
  `turn_right` (same `A`/`D` bindings) to match their new meaning.

**Out of scope:**
- Any change to attack damage, cooldowns, hitbox/projectile logic beyond
  how their direction is now sourced.
- Turret-specific visuals (already handled by the ranged-weapon-visual
  work) — this only changes *what drives* the turret's rotation (nothing,
  now, since it's rigid with the body).
- Gamepad/alternate input schemes.
- Enemy AI, workshop/parts system — unrelated, unaffected.

## 3. Movement & rotation model

- `move_forward`/`move_back` (`W`/`S`, unchanged bindings) translate the
  robot along its own local -Z (forward) axis instead of world -Z, since
  facing can now differ from world orientation.
- `turn_left`/`turn_right` (renamed from `move_left`/`move_right`, same
  `A`/`D` bindings) rotate the robot's Y axis at a fixed turn rate
  (`turn_speed`, `@export`ed, defaulting to `180.0` degrees/sec — a full
  turn in 2 seconds, tunable later without a code change).
- Both can be held simultaneously — holding `W` and `A` together arcs the
  robot forward-left, same as any tank-control game. No special-casing
  needed; rotation and translation are independent per-frame updates.
- Strafing is removed — there is no world-axis left/right movement anymore.

## 4. What rotates

The whole `CharacterBody3D` root (body + turret together, as one rigid
piece) turns via `A`/`D`. `Turret` keeps existing as a child node (still
useful for organizing `TurretMesh`, `RangedWeaponModel`, and `Muzzle`), but
it no longer has any rotation logic of its own — it simply inherits the
root's facing.

## 5. Attack aiming

With no independent turret rotation, "aim direction" collapses to "the
robot's facing direction" for both weapons:

- **Melee** already spawns its hitbox from `muzzle.global_transform` with
  no reference to `aim_point` — unaffected.
- **Ranged** currently computes its projectile direction from
  `aim_point - muzzle.global_position`, falling back to
  `-muzzle.global_transform.basis.z` (muzzle-forward) only when `aim_point`
  coincides with the muzzle. That fallback becomes the *only* path —
  `_attack_ranged()` always fires straight along the muzzle's forward
  direction. The `aim_point` variable, `_handle_aim()`, and the
  camera-ray/ground-plane-intersection code are deleted entirely as dead
  code once nothing produces or consumes `aim_point` anymore.
- Left-click still triggers whichever weapon is equipped — it just always
  fires forward now, not toward the cursor.

## 6. Camera

`Camera3D` is currently a direct child of the rotating root with a fixed
local transform (top-down, `rotation_degrees = (-90, 0, 0)`). Left
unchanged, it would inherit the root's new yaw rotation and visibly spin
the whole view as the player turns — unacceptable for a top-down arena
view meant to stay readable.

Fix: set `Camera3D.top_level = true` (Godot's built-in "ignore parent
transform" flag), so the camera's own transform is authoritative and no
longer composed with the parent's rotation. Since `top_level` nodes don't
auto-follow the parent's position either, `_physics_process` gains one
line to keep the camera positioned above the player:
`camera.global_position = global_position + Vector3(0, 14, 0)`. The
camera's rotation is set once (top-down, unchanged) and never touched
again — it stays fixed regardless of how the robot turns.

## 7. Input actions

- Rename `move_left` → `turn_left`, `move_right` → `turn_right` (same `A`/
  `D` key bindings) via the input map, so action names describe rotation
  rather than stale "movement" naming. `move_forward`/`move_back`,
  `weapon_swap`, and `attack` are untouched.

## 8. Testing / verification

Using the godot-ai MCP tools, same pattern as prior slices:
- Confirm `A`/`D` rotate the robot in place (measure `rotation.y` change)
  and no longer cause any XZ position change on their own.
- Confirm `W`/`S` move along the *current* facing after rotating (e.g.
  turn 90°, then move forward, and confirm the resulting position delta
  is along the new facing axis, not world -Z).
- Confirm the camera's rotation stays constant (top-down) while the robot
  turns, and its position still tracks the robot.
- Confirm melee and ranged attacks both still deal their exact configured
  damage, firing along the robot's current facing (aim by turning toward
  a dummy, not by moving the mouse).
- Confirm the weapon-swap visual toggle (from the prior slice) still
  works unchanged — this feature doesn't touch it.
