# Ranged Weapon Visual — Design Spec

> Small follow-up to the real-time combat slice (see
> `2026-07-21-realtime-combat-slice-design.md`): replace the ranged weapon's
> placeholder look with a real model from the Kenney Space Kit
> (`assets/kenney_space-kit/`, CC0), now that the melee/ranged swap already
> works. Melee's placeholder cylinder is untouched — the kit has no melee-
> shaped model, so that stays a later problem.

## 1. Goal

When the player has the ranged weapon equipped, the turret should visibly
show a real weapon model (`turret_double.glb`) instead of the plain
placeholder cylinder. Melee keeps the existing cylinder. Swapping weapons
(`Q`) should visibly swap which model is shown, alongside the existing HUD
label update.

## 2. Scope

**In scope:**
- Import `assets/kenney_space-kit/Models/GLTF format/turret_double.glb` into
  the project.
- Add it as a new child node under `Turret` in `player_robot.tscn`.
- Recolor it to match the robot's existing blue (`#274863`) via a material
  override, consistent with how `TurretMesh`/`Body` are already colored.
- Toggle its visibility against the existing `TurretMesh` cylinder whenever
  the equipped weapon changes.
- Calibrate scale/rotation so it sits naturally on the turret mount and
  faces the same forward direction (-Z) as the `Muzzle` marker.

**Out of scope:**
- Melee weapon visual (no fitting model in this kit).
- Twin-barrel alternating projectile spawn (`Muzzle` stays a single point).
- Reusing other kit assets (arena dressing, robot chassis) — separate,
  later work per the recommendations already discussed.
- Any change to attack logic, damage, cooldowns, or collision — this is a
  visual-only change layered on top of the already-working ranged attack.

## 3. Approach

Godot can't assign an imported `.glb` directly to a `MeshInstance3D.mesh`
property — it imports as a full `PackedScene`, not a bare `Mesh` resource.
So the model is added as a sibling node under `Turret`, not swapped into
the existing mesh:

- `player_robot.tscn`: under `/PlayerRobot/Turret`, add `RangedWeaponModel`
  — an instance of the imported `turret_double.glb` scene.
- `TurretMesh` (existing cylinder) stays exactly as-is; it now represents
  melee specifically rather than "the turret" generically.
- `RangedWeaponModel` starts hidden (`visible = false`), since the player
  spawns with melee equipped by default.

## 4. Script changes

`player_robot.gd` gains an `@onready` reference to the new node
(`$Turret/RangedWeaponModel`). The existing `_update_weapon_label()` (called
from both `_ready()` and `swap_weapon()`) is extended to also toggle
visibility: `TurretMesh.visible` and `RangedWeaponModel.visible` are set to
opposite values based on `current_weapon`, in the same place the label text
already updates. No other script logic changes — attack behavior, muzzle
position, and projectile spawning are untouched.

## 5. Visual calibration

- **Material:** override with a solid blue (`#274863`) `StandardMaterial3D`
  on the model's mesh surface(s), the same technique already used for
  `TurretMesh` and `Body` — keeps it visually consistent with the rest of
  the robot despite being a more detailed mesh.
- **Scale/rotation:** Kenney models typically need a scale correction (they
  aren't authored at this project's unit scale) and possibly a rotation
  correction to face -Z, matching the `Muzzle` marker's forward convention.
  These values aren't guessed here — they're determined empirically during
  implementation (import, screenshot, adjust) rather than specified as
  fixed numbers in this doc.
- **Muzzle position:** the existing single `Muzzle` marker stays where it
  is unless visual inspection shows the projectile spawning noticeably
  off from the new model's barrel — in which case its local position is
  nudged to roughly align, without introducing dual-barrel logic.

## 6. Testing / verification

Using the godot-ai MCP tools (same pattern as the original combat slice):
- Run the project, confirm `RangedWeaponModel` is hidden and `TurretMesh`
  is visible by default (melee).
- Press `Q`, confirm `RangedWeaponModel` becomes visible and `TurretMesh`
  hides, alongside the HUD label changing to "Weapon: Ranged".
- Press `Q` again, confirm it swaps back.
- Screenshot (`source="game"`) to visually confirm scale/orientation/color
  look reasonable on the robot.
- Confirm the ranged attack itself still functions unchanged (projectile
  spawns and deals damage) — this is a regression check, not new behavior.
