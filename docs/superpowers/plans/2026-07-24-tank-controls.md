# Tank Controls Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace world-axis WASD strafe + mouse-aim turret with tank controls: `W`/`S` move along the robot's current facing, `A`/`D` turn the whole robot, and both weapons fire straight ahead along that facing instead of toward the cursor.

**Architecture:** `player_robot.gd` drops its mouse-raycast aiming code entirely and gains a rotation handler (`rotate_y` driven by `turn_left`/`turn_right`) plus a forward-relative movement handler. `Camera3D` is switched to `top_level = true` with one line of manual position-follow each physics frame, so it keeps tracking the robot without inheriting its new rotation. The `move_left`/`move_right` input actions are renamed to `turn_left`/`turn_right` (same `A`/`D` bindings) to match their new meaning.

**Tech Stack:** Godot 4.7, GDScript, godot-ai MCP tools.

## Global Constraints

- Spec: `docs/superpowers/specs/2026-07-24-tank-controls-design.md`.
- All input-map and script authoring goes through the `mcp__godot-ai__*` MCP tools — script changes via `mcp__godot-ai__script_create` (full-file overwrite), input map changes via `mcp__godot-ai__input_map_manage`.
- `editor_screenshot {"source":"viewport"}` has been unreliable in recent sessions on this project (stale/blank image content, though AABB/framing metadata was still accurate) — use `source:"game"` for any visual check that needs real pixel content.
- `turn_speed` default: `180.0` degrees/sec (a full turn in 2 seconds), `@export`ed on `player_robot.gd` alongside the existing `move_speed`.
- Camera fix: `Camera3D.top_level = true`, position synced every physics frame to `global_position + Vector3(0, 14, 0)`, rotation set once and never touched again.
- Rotation sign is not asserted in advance — Task 2 verifies empirically which sign makes `turn_right` (`D`) visually turn the robot clockwise (as seen from the top-down camera) and corrects it if backwards. This project has twice previously gotten bitten by wrong assumptions about Godot rotation-sign conventions (see prior task reviews) — don't repeat that by trusting a formula without checking it against the live game.
- Commit after each task with git (branch `main`, do NOT push).

---

### Task 1: Rename move_left/move_right to turn_left/turn_right

**Files:**
- Modified: `project.godot` (via `input_map_manage`, not a direct file edit)

**Interfaces:**
- Produces: input actions `turn_left`, `turn_right` (bound to `A`, `D` respectively), replacing `move_left`/`move_right`. Consumed by `player_robot.gd` in Task 2. `move_forward`, `move_back`, `weapon_swap`, `attack` are untouched.

- [ ] **Step 1: Add the new actions with the same key bindings**

```
mcp__godot-ai__input_map_manage {"op": "add_action", "params": {"action": "turn_left"}}
mcp__godot-ai__input_map_manage {"op": "bind_event", "params": {"action": "turn_left", "event_type": "key", "keycode": "A"}}
mcp__godot-ai__input_map_manage {"op": "add_action", "params": {"action": "turn_right"}}
mcp__godot-ai__input_map_manage {"op": "bind_event", "params": {"action": "turn_right", "event_type": "key", "keycode": "D"}}
```

- [ ] **Step 2: Remove the old actions**

```
mcp__godot-ai__input_map_manage {"op": "remove_action", "params": {"action": "move_left"}}
mcp__godot-ai__input_map_manage {"op": "remove_action", "params": {"action": "move_right"}}
```

- [ ] **Step 3: Verify**

```
mcp__godot-ai__input_map_manage {"op": "list", "params": {}}
```
Expected: `move_forward`, `move_back`, `turn_left`, `turn_right`, `weapon_swap`, `attack` — six actions total, no `move_left`/`move_right`. `turn_left` bound to `A`, `turn_right` bound to `D`.

- [ ] **Step 4: Commit**

```bash
git add project.godot
git commit -m "Rename move_left/move_right input actions to turn_left/turn_right"
```

---

### Task 2: Tank-control movement, remove mouse aim, fix camera

**Files:**
- Modify: `res://robot_battler/player_robot.gd` (full-file rewrite)
- Modify: `res://robot_battler/player_robot.tscn` (only `Camera3D.top_level`, via `node_set_property` — no structural node changes)

**Interfaces:**
- Consumes: `turn_left`/`turn_right` input actions (Task 1).
- Removes: `aim_point` (field), `_handle_aim()` (method) — nothing else in the codebase reads these (confirmed: `dummy_target.gd`, `melee_hitbox.gd`, `projectile.gd` never reference `aim_point`; `_attack_melee()` never used it either).
- `turn_speed: float` (new `@export`) and `_handle_rotation(delta)` (new method) are introduced for Task 3+ (future weapon/enemy work, if any) to reference if needed — no other current file depends on them yet.

- [ ] **Step 1: Set the camera to top_level**

```
mcp__godot-ai__scene_open {"path": "res://robot_battler/player_robot.tscn"}
mcp__godot-ai__node_set_property {"path": "/PlayerRobot/Camera3D", "property": "top_level", "value": true}
mcp__godot-ai__scene_save {}
```
(The camera's existing `rotation_degrees = (-90, 0, 0)` and `position = (0, 14, 0)` values are left as-is on the node — `top_level` just changes how Godot *interprets* them, from parent-relative to global-absolute. The script in Step 2 overwrites `global_position` every frame regardless, so the stale absolute interpretation of the old local position value is corrected before it's ever visible.)

- [ ] **Step 2: Rewrite player_robot.gd**

```
mcp__godot-ai__script_create
path: res://robot_battler/player_robot.gd
content:
```
```gdscript
extends CharacterBody3D

@export var move_speed: float = 6.0
@export var turn_speed: float = 180.0

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

var current_weapon: Weapon = Weapon.MELEE

var _melee_cooldown_remaining: float = 0.0
var _ranged_cooldown_remaining: float = 0.0


func _ready() -> void:
	_update_weapon_display()
	_update_camera()


func _physics_process(delta: float) -> void:
	_update_cooldowns(delta)
	_handle_rotation(delta)
	_handle_movement()
	move_and_slide()
	_update_camera()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		attack()
	elif event.is_action_pressed("weapon_swap"):
		swap_weapon()


func _update_cooldowns(delta: float) -> void:
	_melee_cooldown_remaining = maxf(0.0, _melee_cooldown_remaining - delta)
	_ranged_cooldown_remaining = maxf(0.0, _ranged_cooldown_remaining - delta)


func _handle_rotation(delta: float) -> void:
	var turn_input := Input.get_action_strength("turn_right") - Input.get_action_strength("turn_left")
	rotate_y(-turn_input * deg_to_rad(turn_speed) * delta)


func _handle_movement() -> void:
	var move_input := Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	var forward := -global_transform.basis.z
	velocity.x = forward.x * move_input * move_speed
	velocity.z = forward.z * move_input * move_speed


func _update_camera() -> void:
	camera.global_position = global_position + Vector3(0, 14, 0)


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
	var direction := -muzzle.global_transform.basis.z
	projectile.setup(direction, ranged_speed, ranged_damage, ranged_max_distance, self)


func _update_weapon_display() -> void:
	var is_melee := current_weapon == Weapon.MELEE
	weapon_label.text = "Weapon: Melee" if is_melee else "Weapon: Ranged"
	melee_weapon_model.visible = is_melee
	ranged_weapon_model.visible = not is_melee
```

- [ ] **Step 3: Verify rotation direction, correcting the sign if needed**

```
mcp__godot-ai__project_run {"mode": "main"}
mcp__godot-ai__editor_manage {"op": "game_eval", "params": {"code": "return get_node(\"/root/Arena/PlayerRobot\").rotation.y"}}
```
Note the starting value (expect `0.0`). Then:
```
mcp__godot-ai__game_manage {"op": "input_key", "params": {"key": "D", "pressed": true}}
```
Wait briefly (a few hundred ms of real time across a couple of tool round-trips), then:
```
mcp__godot-ai__game_manage {"op": "input_key", "params": {"key": "D", "pressed": false}}
mcp__godot-ai__editor_manage {"op": "game_eval", "params": {"code": "return get_node(\"/root/Arena/PlayerRobot\").rotation.y"}}
mcp__godot-ai__editor_screenshot {"source": "game"}
```
Look at the screenshot: does the robot visually appear to have turned clockwise (as seen from directly above, matching the top-down camera)? If yes, the sign in `_handle_rotation()` is correct — leave it. If the robot turned counterclockwise instead (i.e. `D` turned it left), the sign is backwards: change `rotate_y(-turn_input * ...)` to `rotate_y(turn_input * ...)` in the script (re-run `script_create` with that one-line change) and re-verify with the same test until `D` visibly turns the robot clockwise.

- [ ] **Step 4: Verify movement follows facing, not world axes**

With the robot now facing some rotated direction from Step 3 (not world-forward), record its `global_position`, then:
```
mcp__godot-ai__game_manage {"op": "input_key", "params": {"key": "W", "pressed": true}}
```
Wait briefly, then:
```
mcp__godot-ai__game_manage {"op": "input_key", "params": {"key": "W", "pressed": false}}
mcp__godot-ai__editor_manage {"op": "game_eval", "params": {"code": "var p = get_node(\"/root/Arena/PlayerRobot\")\nreturn {\"position\": p.global_position, \"rotation_y\": p.rotation.y}"}}
```
Expected: the position delta's direction (atan2 of the XZ delta) matches the robot's current facing (`rotation.y`, accounting for forward being -Z), not a straight world -Z movement. Concretely: compute `expected_dir = Vector3(-sin(rotation_y), 0, -cos(rotation_y))` and confirm the measured position delta is (approximately) a positive scalar multiple of that vector.

- [ ] **Step 5: Verify the camera stays non-rotating and keeps following**

```
mcp__godot-ai__editor_manage {"op": "game_eval", "params": {"code": "return get_node(\"/root/Arena/PlayerRobot/Camera3D\").rotation_degrees"}}
```
Expected: `(-90, 0, 0)`, regardless of how much the robot has turned in Steps 3-4 (the camera's rotation must NOT have changed even though the robot's has).
```
mcp__godot-ai__editor_manage {"op": "game_eval", "params": {"code": "var p = get_node(\"/root/Arena/PlayerRobot\")\nvar c = get_node(\"/root/Arena/PlayerRobot/Camera3D\")\nreturn c.global_position - p.global_position"}}
```
Expected: approximately `(0, 14, 0)` — the camera is still positioned directly above the robot regardless of the robot's rotation.

- [ ] **Step 6: Regression-check both attacks still work, firing along facing**

```
mcp__godot-ai__editor_manage {"op": "game_eval", "params": {"code": "var player = get_node(\"/root/Arena/PlayerRobot\")\nvar dummy = get_node(\"/root/Arena/DummyTarget1\")\nplayer.global_position = dummy.global_position + Vector3(0, 0, 1.0)\nplayer.rotation.y = 0.0\nplayer.current_weapon = 0\nplayer._update_weapon_display()\nvar hp_before = dummy.hp\nplayer.attack()\nawait get_tree().create_timer(0.1).timeout\nreturn {\"before\": hp_before, \"after\": dummy.hp}"}}
```
(This places the player facing world -Z, 1 unit in front of `DummyTarget1` along that axis, then attacks with melee — since there's no more mouse aim, the test controls direction by setting `rotation.y` and position directly rather than simulating mouse input.) Expected: `after` is exactly `before - 25.0`.

```
mcp__godot-ai__editor_manage {"op": "game_eval", "params": {"code": "var player = get_node(\"/root/Arena/PlayerRobot\")\nvar dummy = get_node(\"/root/Arena/DummyTarget3\")\nvar to_dummy = dummy.global_position - player.global_position\nplayer.rotation.y = atan2(-to_dummy.x, -to_dummy.z)\nplayer.current_weapon = 1\nplayer._update_weapon_display()\nvar hp_before = dummy.hp\nplayer.attack()\nawait get_tree().create_timer(1.0).timeout\nreturn {\"before\": hp_before, \"after\": dummy.hp}"}}
```
(Turns the player to face `DummyTarget3` exactly, matching the forward-vector convention from `_handle_movement`/`_handle_rotation`, then fires ranged.) Expected: `after` is exactly `before - 10.0`. If `after` equals `before` (the shot missed), the `atan2(-to_dummy.x, -to_dummy.z)` formula's sign is backwards for this project's actual Y-rotation convention — retry with `atan2(to_dummy.x, to_dummy.z)` instead before concluding anything else is broken; this is the same category of Godot rotation-sign gotcha flagged in the Global Constraints, just surfacing here instead of in Step 3.

```
mcp__godot-ai__project_manage {"op": "stop", "params": {}}
```

- [ ] **Step 7: Commit**

```bash
git add robot_battler/player_robot.gd robot_battler/player_robot.tscn
git commit -m "Switch to tank controls: A/D turn, W/S move along facing, remove mouse aim"
```

---

## Self-Review Notes

- **Spec coverage:** §3 movement/rotation model → Task 2 Steps 2-4. §4 what rotates (whole body, turret logic removed) → Task 2 Step 2 (no turret rotation code at all). §5 attack aiming (mouse system deleted, ranged always fires forward) → Task 2 Step 2 (`_attack_ranged` no longer references `aim_point`). §6 camera fix → Task 2 Steps 1, 5. §7 input rename → Task 1. §8 testing → Task 2 Steps 3-6.
- **Type/name consistency:** `turn_speed`, `_handle_rotation`, `_update_camera` are new; every other field/method name (`move_speed`, `melee_damage`, `turret`, `muzzle`, `camera`, `weapon_label`, `melee_weapon_model`, `ranged_weapon_model`, `current_weapon`, `swap_weapon`, `attack`, `_attack_melee`, `_attack_ranged`, `_update_weapon_display`) is carried over unchanged from the current committed file, confirmed by reading it before writing this plan.
- **Dead code removal confirmed safe:** grepped the intent of every other script in `robot_battler/` (dummy_target.gd, melee_hitbox.gd, projectile.gd, damage_number.gd) — none reference `aim_point` or `_handle_aim`, so removing them from `player_robot.gd` breaks nothing else.
- **No placeholders:** the one place this plan can't assert a fact in advance — which sign makes `D` turn clockwise — is handled by giving an exact test procedure and an exact one-line correction, not a vague "make sure it feels right." This mirrors how this project has handled genuine Godot rotation-convention uncertainty in past plans, rather than repeating the mistake of asserting an unverified sign as fact.
