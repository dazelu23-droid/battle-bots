# Ranged Weapon Visual Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the ranged weapon's placeholder cylinder with a real model (`turret_double.glb` from the Kenney Space Kit), shown only while ranged is equipped, toggled alongside the existing weapon-swap HUD label.

**Architecture:** A new child node (`RangedWeaponModel`, an instance of the imported `turret_double.glb`) sits under `Turret` in `player_robot.tscn`, sibling to the existing `TurretMesh` cylinder. `player_robot.gd`'s existing weapon-display update path toggles which of the two is visible based on `current_weapon`. No attack logic, damage, or collision changes.

**Tech Stack:** Godot 4.7, GDScript, godot-ai MCP tools, `assets/kenney_space-kit/` (CC0).

## Global Constraints

- Spec: `docs/superpowers/specs/2026-07-24-ranged-weapon-visual-design.md`.
- All scene/node/material authoring goes through the `mcp__godot-ai__*` MCP tools, not hand-written `.tscn`/`.gd` files.
- `.gd` script changes use `mcp__godot-ai__script_create` (full-file overwrite).
- `editor_screenshot {"source":"viewport"}` is unreliable in this session (returns stale/default images) — use `source:"game"` for in-game visual checks, or `source:"viewport"` with `view_target`/`coverage` only for the editor-time calibration checks in Task 1, where the game isn't running (this was reliable for AABB/framing metadata in earlier sessions; if it also proves unreliable here, fall back to a `source:"game"` check after a quick `project_run`).
- Model source: `res://assets/kenney_space-kit/Models/GLTF format/turret_double.glb`.
- Existing robot blue: `#274863` (used on `Body` and `TurretMesh`) — the new model is recolored to match.
- Melee stays untouched: `TurretMesh` (the existing cylinder) continues to represent melee.
- Commit after each task with git (branch `main`, do NOT push).

---

### Task 1: Import and calibrate the ranged weapon model

**Files:**
- Modify: `res://robot_battler/player_robot.tscn` (adds `RangedWeaponModel` node under `Turret`, no script changes)

**Interfaces:**
- Produces: `/PlayerRobot/Turret/RangedWeaponModel` — a correctly scaled, oriented, positioned, and recolored instance of `turret_double.glb`, left `visible = false` at the end of this task (matching the current default melee-equipped look). Task 2 consumes this node by path and adds the script-driven visibility toggle.

- [ ] **Step 1: Make sure the editor has picked up the asset**

```
mcp__godot-ai__filesystem_manage {"op": "scan", "params": {}}
```
Expected: `scan_completed: true`. This project's `assets/` folder was added outside the editor and has no `.import` sidecar files yet — this scan generates them.

- [ ] **Step 2: Open the player robot scene and instance the model**

```
mcp__godot-ai__scene_open {"path": "res://robot_battler/player_robot.tscn"}
mcp__godot-ai__node_create {"parent_path": "/PlayerRobot/Turret", "name": "RangedWeaponModel", "scene_path": "res://assets/kenney_space-kit/Models/GLTF format/turret_double.glb"}
mcp__godot-ai__node_set_property {"path": "/PlayerRobot/Turret/RangedWeaponModel", "property": "position", "value": {"x": 0, "y": 0.2, "z": 0}}
```
(`(0, 0.2, 0)` matches the existing `TurretMesh`'s local position — a reasonable starting point since both sit on the same turret mount.)

- [ ] **Step 3: Inspect the imported model's actual size and hierarchy**

```
mcp__godot-ai__node_set_property {"path": "/PlayerRobot/Turret/RangedWeaponModel", "property": "visible", "value": true}
mcp__godot-ai__scene_get_hierarchy {"depth": 5}
mcp__godot-ai__editor_screenshot {"source": "viewport", "view_target": "/PlayerRobot/Turret/RangedWeaponModel", "coverage": true}
```
Note the returned `aabb_size` — this is the model's real-world bounding box in scene units before any scale correction, and it establishes what scale factor is needed. Also note, from `scene_get_hierarchy`, the actual path(s) of the `MeshInstance3D` node(s) inside the imported scene (glTF imports typically nest one or more mesh nodes under the instanced root) — Step 6 needs these exact paths.

- [ ] **Step 4: Correct the scale**

For reference, the existing `TurretMesh` cylinder is roughly `0.7 × 0.4 × 0.7` (diameter × height × diameter). Target the new model's largest AABB dimension to land in the `0.8`–`1.0` unit range — comparable to or slightly larger than the cylinder, so it reads as a heavier ranged weapon without dwarfing the robot body (`1.0 × 0.6 × 1.4`).

Compute a uniform scale factor: `scale = target / max(aabb_size.x, aabb_size.y, aabb_size.z)`, picking `target = 0.9` as the midpoint of that range. Apply it:

```
mcp__godot-ai__node_set_property {"path": "/PlayerRobot/Turret/RangedWeaponModel", "property": "scale", "value": {"x": <scale>, "y": <scale>, "z": <scale>}}
mcp__godot-ai__editor_screenshot {"source": "viewport", "view_target": "/PlayerRobot/Turret/RangedWeaponModel", "coverage": true}
```
Check the new `aabb_size` against the `0.8`–`1.0` target. If it's off by more than ~15%, recompute and reapply once more. Two correction passes should be enough — if it still isn't close after that, stop and report as a concern rather than continuing to iterate blindly.

- [ ] **Step 5: Correct the orientation**

The `Muzzle` marker sits at `Turret`-local `(0, 0.2, -0.9)` — i.e. forward is `-Z`. The imported model's default forward direction is unknown ahead of time. Test the four axis-aligned Y rotations and visually compare each screenshot against where `Muzzle` points:

```
mcp__godot-ai__node_set_property {"path": "/PlayerRobot/Turret/RangedWeaponModel", "property": "rotation_degrees", "value": {"x": 0, "y": 0, "z": 0}}
mcp__godot-ai__editor_screenshot {"source": "viewport", "view_target": "/PlayerRobot/Turret", "elevation": 40}
```
Repeat with `rotation_degrees.y` at `90`, `180`, and `270`, taking a screenshot after each. Look at the four images: pick the rotation where the model's barrel(s) point toward `-Z` (the same direction the existing `TurretMesh`/`Muzzle` already face — i.e. away from the robot body, forward). Apply that final rotation (leave it if `0` was already correct).

- [ ] **Step 6: Recolor to match the robot's blue**

Using the `MeshInstance3D` path(s) found in Step 3's `scene_get_hierarchy` output (substitute the real path(s) for `<mesh_path>` below — there may be more than one if the model has multiple material surfaces; repeat this call for each):

```
mcp__godot-ai__material_manage {"op": "apply_to_node", "params": {"node_path": "<mesh_path>", "type": "standard", "params": {"albedo_color": "#274863"}}}
```

- [ ] **Step 7: Confirm the calibrated look, then hide it for the default state**

```
mcp__godot-ai__editor_screenshot {"source": "viewport", "view_target": "/PlayerRobot/Turret", "elevation": 30}
```
Expected: the model sits on the turret mount, roughly matching the cylinder's footprint, facing the same direction as `Muzzle`, colored `#274863`. If anything looks clearly wrong (floating off the mount, badly clipped into the body, obviously the wrong scale), adjust `position`/`scale` once more and re-screenshot.

Once satisfied:
```
mcp__godot-ai__node_set_property {"path": "/PlayerRobot/Turret/RangedWeaponModel", "property": "visible", "value": false}
mcp__godot-ai__scene_save {}
```

- [ ] **Step 8: Verify the default view is unchanged**

```
mcp__godot-ai__project_run {"mode": "main"}
mcp__godot-ai__editor_screenshot {"source": "game"}
mcp__godot-ai__project_manage {"op": "stop", "params": {}}
```
Expected: identical to the pre-this-task default appearance (robot shows the plain cylinder turret; the new model is present in the scene but hidden).

- [ ] **Step 9: Commit**

```bash
git add robot_battler/player_robot.tscn assets/
git commit -m "Add calibrated turret_double model to player robot (hidden by default)"
```
(`assets/` is included here since this is the first task that actually references files under it — everything under `assets/kenney_space-kit/` plus the `.import` sidecars generated by Step 1's scan.)

---

### Task 2: Toggle the model on weapon swap

**Files:**
- Modify: `res://robot_battler/player_robot.gd` (full-file rewrite)

**Interfaces:**
- Consumes: `/PlayerRobot/Turret/RangedWeaponModel` (Task 1), `/PlayerRobot/Turret/TurretMesh` (existing).
- Renames `_update_weapon_label()` to `_update_weapon_display()` (same two call sites: `_ready()`, `swap_weapon()`) — no other function signatures change.

- [ ] **Step 1: Rewrite player_robot.gd**

```
mcp__godot-ai__script_create
path: res://robot_battler/player_robot.gd
content:
```
```gdscript
extends CharacterBody3D

@export var move_speed: float = 6.0

@export_group("Melee")
@export var melee_damage: float = 25.0
@export var melee_range: float = 2.2
@export var melee_cooldown: float = 0.5

@export_group("Ranged")
@export var ranged_damage: float = 10.0
@export var ranged_speed: float = 18.0
@export var ranged_max_distance: float = 20.0
@export var ranged_cooldown: float = 0.35

enum Weapon { MELEE, RANGED }

const MELEE_HITBOX_SCENE := preload("res://robot_battler/melee_hitbox.tscn")
const PROJECTILE_SCENE := preload("res://robot_battler/projectile.tscn")

@onready var turret: Node3D = $Turret
@onready var muzzle: Marker3D = $Turret/Muzzle
@onready var camera: Camera3D = $Camera3D
@onready var weapon_label: Label = $HUD/WeaponLabel
@onready var melee_weapon_model: MeshInstance3D = $Turret/TurretMesh
@onready var ranged_weapon_model: Node3D = $Turret/RangedWeaponModel

var aim_point: Vector3 = Vector3.ZERO
var current_weapon: Weapon = Weapon.MELEE

var _melee_cooldown_remaining: float = 0.0
var _ranged_cooldown_remaining: float = 0.0


func _ready() -> void:
	_update_weapon_display()


func _physics_process(delta: float) -> void:
	_update_cooldowns(delta)
	_handle_movement()
	_handle_aim()
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		attack()
	elif event.is_action_pressed("weapon_swap"):
		swap_weapon()


func _update_cooldowns(delta: float) -> void:
	_melee_cooldown_remaining = maxf(0.0, _melee_cooldown_remaining - delta)
	_ranged_cooldown_remaining = maxf(0.0, _ranged_cooldown_remaining - delta)


func _handle_movement() -> void:
	var input_dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	)
	var direction := Vector3(input_dir.x, 0.0, input_dir.y)
	if direction.length() > 1.0:
		direction = direction.normalized()
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed


func _handle_aim() -> void:
	var mouse_pos := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_dir := camera.project_ray_normal(mouse_pos)
	if absf(ray_dir.y) < 0.0001:
		return
	var t := -ray_origin.y / ray_dir.y
	if t < 0.0:
		return
	aim_point = ray_origin + ray_dir * t
	var look_target := Vector3(aim_point.x, turret.global_position.y, aim_point.z)
	if look_target.distance_to(turret.global_position) > 0.01:
		turret.look_at(look_target, Vector3.UP)


func swap_weapon() -> void:
	current_weapon = Weapon.RANGED if current_weapon == Weapon.MELEE else Weapon.MELEE
	_update_weapon_display()


func attack() -> void:
	if current_weapon == Weapon.MELEE:
		_attack_melee()
	else:
		_attack_ranged()


func _attack_melee() -> void:
	if _melee_cooldown_remaining > 0.0:
		return
	_melee_cooldown_remaining = melee_cooldown
	var hitbox := MELEE_HITBOX_SCENE.instantiate()
	get_tree().current_scene.add_child(hitbox)
	hitbox.global_transform = muzzle.global_transform
	hitbox.setup(melee_damage, melee_range, self)


func _attack_ranged() -> void:
	if _ranged_cooldown_remaining > 0.0:
		return
	_ranged_cooldown_remaining = ranged_cooldown
	var projectile := PROJECTILE_SCENE.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_transform = muzzle.global_transform
	var direction := aim_point - muzzle.global_position
	direction.y = 0.0
	if direction.length() > 0.01:
		direction = direction.normalized()
	else:
		direction = -muzzle.global_transform.basis.z
	projectile.setup(direction, ranged_speed, ranged_damage, ranged_max_distance, self)


func _update_weapon_display() -> void:
	var is_melee := current_weapon == Weapon.MELEE
	weapon_label.text = "Weapon: Melee" if is_melee else "Weapon: Ranged"
	melee_weapon_model.visible = is_melee
	ranged_weapon_model.visible = not is_melee
```

- [ ] **Step 2: Verify default state, swap toggling, and both directions**

```
mcp__godot-ai__project_run {"mode": "main"}
mcp__godot-ai__editor_manage {"op": "game_eval", "params": {"code": "var p = get_node(\"/root/Arena/PlayerRobot\")\nreturn {\"label\": p.weapon_label.text, \"melee_visible\": p.melee_weapon_model.visible, \"ranged_visible\": p.ranged_weapon_model.visible}"}}
```
Expected: `{"label": "Weapon: Melee", "melee_visible": true, "ranged_visible": false}`.

```
mcp__godot-ai__game_manage {"op": "input_key", "params": {"key": "Q", "pressed": true}}
mcp__godot-ai__game_manage {"op": "input_key", "params": {"key": "Q", "pressed": false}}
mcp__godot-ai__editor_manage {"op": "game_eval", "params": {"code": "var p = get_node(\"/root/Arena/PlayerRobot\")\nreturn {\"label\": p.weapon_label.text, \"melee_visible\": p.melee_weapon_model.visible, \"ranged_visible\": p.ranged_weapon_model.visible}"}}
```
Expected: `{"label": "Weapon: Ranged", "melee_visible": false, "ranged_visible": true}`.

```
mcp__godot-ai__game_manage {"op": "input_key", "params": {"key": "Q", "pressed": true}}
mcp__godot-ai__game_manage {"op": "input_key", "params": {"key": "Q", "pressed": false}}
mcp__godot-ai__editor_manage {"op": "game_eval", "params": {"code": "var p = get_node(\"/root/Arena/PlayerRobot\")\nreturn {\"label\": p.weapon_label.text, \"melee_visible\": p.melee_weapon_model.visible, \"ranged_visible\": p.ranged_weapon_model.visible}"}}
```
Expected: back to `{"label": "Weapon: Melee", "melee_visible": true, "ranged_visible": false}`.

```
mcp__godot-ai__editor_screenshot {"source": "game"}
```
Expected: robot shows the recolored turret model while ranged is equipped (swap to ranged first if the above sequence left it on melee).

- [ ] **Step 3: Regression-check both attacks still work**

```
mcp__godot-ai__editor_manage {"op": "game_eval", "params": {"code": "var player = get_node(\"/root/Arena/PlayerRobot\")\nvar dummy = get_node(\"/root/Arena/DummyTarget1\")\nplayer.current_weapon = 0\nplayer._update_weapon_display()\nplayer.turret.look_at(dummy.global_position, Vector3.UP)\nvar hp_before = dummy.hp\nplayer.attack()\nawait get_tree().create_timer(0.1).timeout\nreturn {\"before\": hp_before, \"after\": dummy.hp}"}}
```
Expected: `after` is exactly `before - 25.0` (melee still deals `melee_damage`, unaffected by the model addition).

```
mcp__godot-ai__editor_manage {"op": "game_eval", "params": {"code": "var player = get_node(\"/root/Arena/PlayerRobot\")\nvar dummy = get_node(\"/root/Arena/DummyTarget3\")\nplayer.current_weapon = 1\nplayer._update_weapon_display()\nplayer.turret.look_at(dummy.global_position, Vector3.UP)\nplayer.aim_point = dummy.global_position\nvar hp_before = dummy.hp\nplayer.attack()\nawait get_tree().create_timer(1.0).timeout\nreturn {\"before\": hp_before, \"after\": dummy.hp}"}}
```
Expected: `after` is exactly `before - 10.0` (ranged still deals `ranged_damage` and the projectile still spawns/travels correctly from `Muzzle`, unaffected by the new sibling model).

```
mcp__godot-ai__project_manage {"op": "stop", "params": {}}
```

- [ ] **Step 4: Commit**

```bash
git add robot_battler/player_robot.gd
git commit -m "Toggle ranged weapon model visibility on weapon swap"
```

---

## Self-Review Notes

- **Spec coverage:** §3 approach (sibling node + visibility toggle, not mesh-resource swap) → Task 1 Step 2 + Task 2 Step 1. §4 script changes → Task 2. §5 visual calibration (material, scale/rotation, muzzle position) → Task 1 Steps 4–7. §6 testing → Task 2 Steps 2–3.
- **Type/name consistency:** `RangedWeaponModel` (node name) and `ranged_weapon_model` (script field) match exactly between Task 1's node creation and Task 2's `@onready` reference. `melee_weapon_model` is a new field pointing at the pre-existing `TurretMesh` node — added because `_update_weapon_display()` needs to toggle it, not because `TurretMesh` itself changes.
- **No placeholders:** Task 1's scale/rotation steps don't know the exact final numbers in advance (the spec explicitly calls this out as empirical), but each step specifies a concrete, bounded procedure (read AABB → compute exact formula → apply; test 4 discrete rotations → pick by visual comparison against a known reference direction) rather than an open-ended "adjust until it looks right." This is the one place in the plan where a number can't be given verbatim, and it's handled by giving the *method* verbatim instead.
