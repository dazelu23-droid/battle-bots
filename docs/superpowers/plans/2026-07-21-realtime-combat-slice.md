# Real-Time Combat Slice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first playable slice of Robot Battler — a top-down 3D arena with one WASD/mouse-controlled robot that can swap between a melee and a ranged weapon and land readable hits on several static dummy targets.

**Architecture:** A single Godot 4.7 scene (`res://robot_battler/arena.tscn`) containing a blockout arena, one `PlayerRobot` (`CharacterBody3D`) and several `DummyTarget` (`StaticBody3D`) instances. The player's attacks spawn short-lived `Area3D` scenes (`melee_hitbox.tscn`, `projectile.tscn`) that call `take_damage()` on whatever they overlap. No parts system, no AI, no save data — see the spec for what's explicitly out of scope.

**Tech Stack:** Godot 4.7, GDScript, the `godot-ai` MCP plugin already installed in this project (`addons/godot_ai/`).

## Global Constraints

- Spec: `docs/superpowers/specs/2026-07-21-realtime-combat-slice-design.md` — every task below implements a section of it.
- All scene/node authoring (creating nodes, setting properties, attaching scripts, cameras, materials) MUST go through the `mcp__godot-ai__*` MCP tools, not hand-written `.tscn` XML — these files are error-prone to author by hand and the tools keep the live editor and the on-disk file in sync.
- All `.gd` script files are written with `mcp__godot-ai__script_create` (full-file overwrite each time a script changes across tasks — no incremental patching, so every step below shows complete file content).
- Project root for all new assets: `res://robot_battler/`.
- Engine: Godot 4.7, Jolt physics, Forward+ rendering (already configured in `project.godot` — do not change).
- **Testing convention for this plan:** there is no pytest/unit-test framework for gameplay code here. Each task's "verify" steps use the live godot-ai MCP session: `mcp__godot-ai__project_run` to launch the game, `mcp__godot-ai__game_manage` (`input_key`, `input_mouse`, `input_action`) to simulate input, `mcp__godot-ai__editor_manage` (`op: "game_eval"`) to run a short GDScript snippet in the running game and read back a value to assert against, and `mcp__godot-ai__editor_screenshot` (`source: "game"`) for a visual sanity check. Stop the running game with `mcp__godot-ai__project_manage` (`op: "stop"`) before making further scene edits — the MCP scene-mutation tools reject writes while the game is playing.
- Collision layers used throughout (bit value): **1 = world** (floor/walls), **2 = player**, **4 = dummy targets**. Melee/ranged hitboxes are `Area3D` with `collision_layer=0`, `collision_mask=4` (they only detect dummies).
- Commit after every task with `git add <files> && git commit -m "..."`.

---

### Task 1: Input actions

**Files:**
- Modified: `project.godot` (via `input_map_manage`, not a direct file edit)

**Interfaces:**
- Produces: input actions `move_forward`, `move_back`, `move_left`, `move_right`, `weapon_swap`, `attack`, consumed by `player_robot.gd` in Task 4+.

- [ ] **Step 1: Create the four movement actions and bind WASD**

Call, in order:
```
mcp__godot-ai__input_map_manage {"op": "add_action", "params": {"action": "move_forward"}}
mcp__godot-ai__input_map_manage {"op": "bind_event", "params": {"action": "move_forward", "event_type": "key", "keycode": "W"}}
mcp__godot-ai__input_map_manage {"op": "add_action", "params": {"action": "move_back"}}
mcp__godot-ai__input_map_manage {"op": "bind_event", "params": {"action": "move_back", "event_type": "key", "keycode": "S"}}
mcp__godot-ai__input_map_manage {"op": "add_action", "params": {"action": "move_left"}}
mcp__godot-ai__input_map_manage {"op": "bind_event", "params": {"action": "move_left", "event_type": "key", "keycode": "A"}}
mcp__godot-ai__input_map_manage {"op": "add_action", "params": {"action": "move_right"}}
mcp__godot-ai__input_map_manage {"op": "bind_event", "params": {"action": "move_right", "event_type": "key", "keycode": "D"}}
```

- [ ] **Step 2: Create the weapon-swap and attack actions**

```
mcp__godot-ai__input_map_manage {"op": "add_action", "params": {"action": "weapon_swap"}}
mcp__godot-ai__input_map_manage {"op": "bind_event", "params": {"action": "weapon_swap", "event_type": "key", "keycode": "Q"}}
mcp__godot-ai__input_map_manage {"op": "add_action", "params": {"action": "attack"}}
mcp__godot-ai__input_map_manage {"op": "bind_event", "params": {"action": "attack", "event_type": "mouse_button", "button": 1}}
```
(`button: 1` is Godot's `MOUSE_BUTTON_LEFT`.)

- [ ] **Step 3: Verify**

```
mcp__godot-ai__input_map_manage {"op": "list", "params": {}}
```
Expected: the response includes all six actions (`move_forward`, `move_back`, `move_left`, `move_right`, `weapon_swap`, `attack`) each with exactly one bound event.

- [ ] **Step 4: Commit**

```bash
git add project.godot
git commit -m "Add WASD/mouse input actions for real-time combat slice"
```

---

### Task 2: Arena scene (floor, walls, light)

**Files:**
- Create: `res://robot_battler/arena.tscn`

**Interfaces:**
- Produces: scene root path `/Arena` (Node3D), used as the parent for `PlayerRobot` and `DummyTarget` instances in later tasks. Sets this scene as the project's main scene.

- [ ] **Step 1: Create the scene**

```
mcp__godot-ai__scene_manage {"op": "create", "params": {"path": "res://robot_battler/arena.tscn", "root_type": "Node3D", "root_name": "Arena"}}
```

- [ ] **Step 2: Floor**

```
mcp__godot-ai__node_create {"type": "StaticBody3D", "parent_path": "", "name": "Floor"}
mcp__godot-ai__node_set_property {"path": "/Arena/Floor", "property": "position", "value": {"x": 0, "y": -0.1, "z": 0}}
mcp__godot-ai__node_set_property {"path": "/Arena/Floor", "property": "collision_layer", "value": 1}
mcp__godot-ai__node_set_property {"path": "/Arena/Floor", "property": "collision_mask", "value": 0}
mcp__godot-ai__node_create {"type": "MeshInstance3D", "parent_path": "/Arena/Floor", "name": "MeshInstance3D"}
mcp__godot-ai__node_set_property {"path": "/Arena/Floor/MeshInstance3D", "property": "mesh", "value": {"__class__": "BoxMesh", "size": {"x": 40, "y": 0.2, "z": 40}}}
mcp__godot-ai__node_create {"type": "CollisionShape3D", "parent_path": "/Arena/Floor", "name": "CollisionShape3D"}
mcp__godot-ai__node_set_property {"path": "/Arena/Floor/CollisionShape3D", "property": "shape", "value": {"__class__": "BoxShape3D", "size": {"x": 40, "y": 0.2, "z": 40}}}
mcp__godot-ai__material_manage {"op": "apply_to_node", "params": {"node_path": "/Arena/Floor/MeshInstance3D", "type": "standard", "params": {"albedo_color": "#4a4a4f"}}}
```

- [ ] **Step 3: Boundary walls (4 segments, thickness 1, height 3, on a 40x40 floor)**

```
mcp__godot-ai__node_create {"type": "StaticBody3D", "parent_path": "", "name": "WallNorth"}
mcp__godot-ai__node_set_property {"path": "/Arena/WallNorth", "property": "position", "value": {"x": 0, "y": 1.5, "z": -20.5}}
mcp__godot-ai__node_set_property {"path": "/Arena/WallNorth", "property": "collision_layer", "value": 1}
mcp__godot-ai__node_set_property {"path": "/Arena/WallNorth", "property": "collision_mask", "value": 0}
mcp__godot-ai__node_create {"type": "MeshInstance3D", "parent_path": "/Arena/WallNorth", "name": "MeshInstance3D"}
mcp__godot-ai__node_set_property {"path": "/Arena/WallNorth/MeshInstance3D", "property": "mesh", "value": {"__class__": "BoxMesh", "size": {"x": 41, "y": 3, "z": 1}}}
mcp__godot-ai__node_create {"type": "CollisionShape3D", "parent_path": "/Arena/WallNorth", "name": "CollisionShape3D"}
mcp__godot-ai__node_set_property {"path": "/Arena/WallNorth/CollisionShape3D", "property": "shape", "value": {"__class__": "BoxShape3D", "size": {"x": 41, "y": 3, "z": 1}}}

mcp__godot-ai__node_create {"type": "StaticBody3D", "parent_path": "", "name": "WallSouth"}
mcp__godot-ai__node_set_property {"path": "/Arena/WallSouth", "property": "position", "value": {"x": 0, "y": 1.5, "z": 20.5}}
mcp__godot-ai__node_set_property {"path": "/Arena/WallSouth", "property": "collision_layer", "value": 1}
mcp__godot-ai__node_set_property {"path": "/Arena/WallSouth", "property": "collision_mask", "value": 0}
mcp__godot-ai__node_create {"type": "MeshInstance3D", "parent_path": "/Arena/WallSouth", "name": "MeshInstance3D"}
mcp__godot-ai__node_set_property {"path": "/Arena/WallSouth/MeshInstance3D", "property": "mesh", "value": {"__class__": "BoxMesh", "size": {"x": 41, "y": 3, "z": 1}}}
mcp__godot-ai__node_create {"type": "CollisionShape3D", "parent_path": "/Arena/WallSouth", "name": "CollisionShape3D"}
mcp__godot-ai__node_set_property {"path": "/Arena/WallSouth/CollisionShape3D", "property": "shape", "value": {"__class__": "BoxShape3D", "size": {"x": 41, "y": 3, "z": 1}}}

mcp__godot-ai__node_create {"type": "StaticBody3D", "parent_path": "", "name": "WallEast"}
mcp__godot-ai__node_set_property {"path": "/Arena/WallEast", "property": "position", "value": {"x": 20.5, "y": 1.5, "z": 0}}
mcp__godot-ai__node_set_property {"path": "/Arena/WallEast", "property": "collision_layer", "value": 1}
mcp__godot-ai__node_set_property {"path": "/Arena/WallEast", "property": "collision_mask", "value": 0}
mcp__godot-ai__node_create {"type": "MeshInstance3D", "parent_path": "/Arena/WallEast", "name": "MeshInstance3D"}
mcp__godot-ai__node_set_property {"path": "/Arena/WallEast/MeshInstance3D", "property": "mesh", "value": {"__class__": "BoxMesh", "size": {"x": 1, "y": 3, "z": 41}}}
mcp__godot-ai__node_create {"type": "CollisionShape3D", "parent_path": "/Arena/WallEast", "name": "CollisionShape3D"}
mcp__godot-ai__node_set_property {"path": "/Arena/WallEast/CollisionShape3D", "property": "shape", "value": {"__class__": "BoxShape3D", "size": {"x": 1, "y": 3, "z": 41}}}

mcp__godot-ai__node_create {"type": "StaticBody3D", "parent_path": "", "name": "WallWest"}
mcp__godot-ai__node_set_property {"path": "/Arena/WallWest", "property": "position", "value": {"x": -20.5, "y": 1.5, "z": 0}}
mcp__godot-ai__node_set_property {"path": "/Arena/WallWest", "property": "collision_layer", "value": 1}
mcp__godot-ai__node_set_property {"path": "/Arena/WallWest", "property": "collision_mask", "value": 0}
mcp__godot-ai__node_create {"type": "MeshInstance3D", "parent_path": "/Arena/WallWest", "name": "MeshInstance3D"}
mcp__godot-ai__node_set_property {"path": "/Arena/WallWest/MeshInstance3D", "property": "mesh", "value": {"__class__": "BoxMesh", "size": {"x": 1, "y": 3, "z": 41}}}
mcp__godot-ai__node_create {"type": "CollisionShape3D", "parent_path": "/Arena/WallWest", "name": "CollisionShape3D"}
mcp__godot-ai__node_set_property {"path": "/Arena/WallWest/CollisionShape3D", "property": "shape", "value": {"__class__": "BoxShape3D", "size": {"x": 1, "y": 3, "z": 41}}}

mcp__godot-ai__material_manage {"op": "apply_to_node", "params": {"node_path": "/Arena/WallNorth/MeshInstance3D", "type": "standard", "params": {"albedo_color": "#2b2b30"}}}
mcp__godot-ai__material_manage {"op": "apply_to_node", "params": {"node_path": "/Arena/WallSouth/MeshInstance3D", "type": "standard", "params": {"albedo_color": "#2b2b30"}}}
mcp__godot-ai__material_manage {"op": "apply_to_node", "params": {"node_path": "/Arena/WallEast/MeshInstance3D", "type": "standard", "params": {"albedo_color": "#2b2b30"}}}
mcp__godot-ai__material_manage {"op": "apply_to_node", "params": {"node_path": "/Arena/WallWest/MeshInstance3D", "type": "standard", "params": {"albedo_color": "#2b2b30"}}}
```

- [ ] **Step 4: Stage lighting**

```
mcp__godot-ai__node_create {"type": "DirectionalLight3D", "parent_path": "", "name": "DirectionalLight3D"}
mcp__godot-ai__node_set_property {"path": "/Arena/DirectionalLight3D", "property": "position", "value": {"x": 0, "y": 10, "z": 0}}
mcp__godot-ai__node_set_property {"path": "/Arena/DirectionalLight3D", "property": "rotation_degrees", "value": {"x": -50, "y": -30, "z": 0}}
mcp__godot-ai__node_set_property {"path": "/Arena/DirectionalLight3D", "property": "light_energy", "value": 1.2}
```

- [ ] **Step 5: Save, set as main scene, verify visually**

```
mcp__godot-ai__scene_save {}
mcp__godot-ai__project_manage {"op": "settings_set", "params": {"key": "application/run/main_scene", "value": "res://robot_battler/arena.tscn"}}
mcp__godot-ai__editor_screenshot {"source": "viewport"}
```
Expected: a screenshot showing a gray floor bounded by four dark walls, no errors returned.

- [ ] **Step 6: Commit**

```bash
git add robot_battler/arena.tscn project.godot
git commit -m "Add blockout arena: floor, walls, stage light"
```

---

### Task 3: Dummy target (HP, hit feedback, damage number, reset)

**Files:**
- Create: `res://robot_battler/damage_number.gd`
- Create: `res://robot_battler/damage_number.tscn`
- Create: `res://robot_battler/dummy_target.gd`
- Create: `res://robot_battler/dummy_target.tscn`
- Modify: `res://robot_battler/arena.tscn` (add one `DummyTarget` instance)

**Interfaces:**
- Produces: `DummyTarget.take_damage(amount: float) -> void` (also called by `melee_hitbox.gd` in Task 5 and `projectile.gd` in Task 6 — any node with a `take_damage(amount)` method is a valid hit target for both weapons).
- Produces: `DamageNumber.setup(amount: float) -> void`.

- [ ] **Step 1: Damage number script**

```
mcp__godot-ai__script_create
path: res://robot_battler/damage_number.gd
content:
```
```gdscript
extends Label3D


func setup(amount: float) -> void:
	text = str(int(round(amount)))
	var target_y := position.y + 1.2
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", target_y, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "modulate:a", 0.0, 0.6).set_delay(0.2)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
```

- [ ] **Step 2: Damage number scene**

(`billboard` uses `1` = `BaseMaterial3D.BILLBOARD_ENABLED` as a raw int — `node_set_property` is not documented to coerce enum names the way `camera_manage`/`material_manage` are.)
```
mcp__godot-ai__scene_manage {"op": "create", "params": {"path": "res://robot_battler/damage_number.tscn", "root_type": "Label3D", "root_name": "DamageNumber"}}
mcp__godot-ai__node_set_property {"path": "/DamageNumber", "property": "billboard", "value": 1}
mcp__godot-ai__node_set_property {"path": "/DamageNumber", "property": "font_size", "value": 64}
mcp__godot-ai__node_set_property {"path": "/DamageNumber", "property": "outline_size", "value": 12}
mcp__godot-ai__node_set_property {"path": "/DamageNumber", "property": "modulate", "value": "#ffe066"}
mcp__godot-ai__script_attach {"path": "/DamageNumber", "script_path": "res://robot_battler/damage_number.gd"}
mcp__godot-ai__scene_save {}
```

- [ ] **Step 3: Dummy target script**

```
mcp__godot-ai__script_create
path: res://robot_battler/dummy_target.gd
content:
```
```gdscript
extends StaticBody3D

@export var max_hp: float = 60.0
@export var reset_delay: float = 1.5

var hp: float = 0.0

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var health_fill: MeshInstance3D = $HealthBar/Fill

const DAMAGE_NUMBER_SCENE := preload("res://robot_battler/damage_number.tscn")

var _flash_tween: Tween = null
var _destroyed: bool = false


func _ready() -> void:
	hp = max_hp
	_update_health_bar()


func take_damage(amount: float) -> void:
	if _destroyed:
		return
	hp = max(0.0, hp - amount)
	_update_health_bar()
	_spawn_damage_number(amount)
	_flash()
	if hp <= 0.0:
		_on_depleted()


func _update_health_bar() -> void:
	var ratio: float = clampf(hp / max_hp, 0.0, 1.0) if max_hp > 0.0 else 0.0
	health_fill.scale.x = ratio


func _flash() -> void:
	if _flash_tween != null and _flash_tween.is_running():
		_flash_tween.kill()
	mesh.scale = Vector3(1.15, 1.15, 1.15)
	_flash_tween = create_tween()
	_flash_tween.tween_property(mesh, "scale", Vector3.ONE, 0.12)


func _spawn_damage_number(amount: float) -> void:
	var number := DAMAGE_NUMBER_SCENE.instantiate()
	get_tree().current_scene.add_child(number)
	number.global_position = global_position + Vector3(0, 2.6, 0)
	number.setup(amount)


func _on_depleted() -> void:
	_destroyed = true
	visible = false
	collision_shape.disabled = true
	get_tree().create_timer(reset_delay).timeout.connect(_reset)


func _reset() -> void:
	hp = max_hp
	_destroyed = false
	visible = true
	collision_shape.disabled = false
	_update_health_bar()
```

- [ ] **Step 4: Dummy target scene**

```
mcp__godot-ai__scene_manage {"op": "create", "params": {"path": "res://robot_battler/dummy_target.tscn", "root_type": "StaticBody3D", "root_name": "DummyTarget"}}
mcp__godot-ai__node_set_property {"path": "/DummyTarget", "property": "collision_layer", "value": 4}
mcp__godot-ai__node_set_property {"path": "/DummyTarget", "property": "collision_mask", "value": 0}

mcp__godot-ai__node_create {"type": "MeshInstance3D", "parent_path": "", "name": "MeshInstance3D"}
mcp__godot-ai__node_set_property {"path": "/DummyTarget/MeshInstance3D", "property": "position", "value": {"x": 0, "y": 0.8, "z": 0}}
mcp__godot-ai__node_set_property {"path": "/DummyTarget/MeshInstance3D", "property": "mesh", "value": {"__class__": "BoxMesh", "size": {"x": 1.0, "y": 1.6, "z": 1.0}}}
mcp__godot-ai__material_manage {"op": "apply_to_node", "params": {"node_path": "/DummyTarget/MeshInstance3D", "type": "standard", "params": {"albedo_color": "#c65a2e"}}}

mcp__godot-ai__node_create {"type": "CollisionShape3D", "parent_path": "", "name": "CollisionShape3D"}
mcp__godot-ai__node_set_property {"path": "/DummyTarget/CollisionShape3D", "property": "position", "value": {"x": 0, "y": 0.8, "z": 0}}
mcp__godot-ai__node_set_property {"path": "/DummyTarget/CollisionShape3D", "property": "shape", "value": {"__class__": "BoxShape3D", "size": {"x": 1.0, "y": 1.6, "z": 1.0}}}

mcp__godot-ai__node_create {"type": "Node3D", "parent_path": "", "name": "HealthBar"}
mcp__godot-ai__node_set_property {"path": "/DummyTarget/HealthBar", "property": "position", "value": {"x": 0, "y": 2.2, "z": 0}}

mcp__godot-ai__node_create {"type": "MeshInstance3D", "parent_path": "/DummyTarget/HealthBar", "name": "Background"}
mcp__godot-ai__node_set_property {"path": "/DummyTarget/HealthBar/Background", "property": "rotation_degrees", "value": {"x": -90, "y": 0, "z": 0}}
mcp__godot-ai__node_set_property {"path": "/DummyTarget/HealthBar/Background", "property": "mesh", "value": {"__class__": "QuadMesh", "size": {"x": 1.0, "y": 0.16}}}
mcp__godot-ai__material_manage {"op": "apply_to_node", "params": {"node_path": "/DummyTarget/HealthBar/Background", "type": "standard", "params": {"albedo_color": "#20140f"}}}

mcp__godot-ai__node_create {"type": "MeshInstance3D", "parent_path": "/DummyTarget/HealthBar", "name": "Fill"}
mcp__godot-ai__node_set_property {"path": "/DummyTarget/HealthBar/Fill", "property": "position", "value": {"x": 0, "y": 0.01, "z": 0}}
mcp__godot-ai__node_set_property {"path": "/DummyTarget/HealthBar/Fill", "property": "rotation_degrees", "value": {"x": -90, "y": 0, "z": 0}}
mcp__godot-ai__node_set_property {"path": "/DummyTarget/HealthBar/Fill", "property": "mesh", "value": {"__class__": "QuadMesh", "size": {"x": 1.0, "y": 0.16}}}
mcp__godot-ai__material_manage {"op": "apply_to_node", "params": {"node_path": "/DummyTarget/HealthBar/Fill", "type": "standard", "params": {"albedo_color": "#4ee06a"}}}

mcp__godot-ai__script_attach {"path": "/DummyTarget", "script_path": "res://robot_battler/dummy_target.gd"}
mcp__godot-ai__scene_save {}
```

Note: `QuadMesh` scaling shrinks from its center, not its left edge — the fill bar shrinks symmetrically as HP drops. That's a fine visual for this prototype slice (no need for pivot tricks).

- [ ] **Step 5: Place one instance in the arena**

```
mcp__godot-ai__scene_open {"path": "res://robot_battler/arena.tscn"}
mcp__godot-ai__node_create {"type": "", "parent_path": "", "name": "DummyTarget1", "scene_path": "res://robot_battler/dummy_target.tscn"}
mcp__godot-ai__node_set_property {"path": "/Arena/DummyTarget1", "property": "position", "value": {"x": 0, "y": 0, "z": -4}}
mcp__godot-ai__scene_save {}
```

- [ ] **Step 6: Verify — HP, damage number, hit flash, and reset all work end to end**

```
mcp__godot-ai__project_run {"mode": "main"}
mcp__godot-ai__editor_manage {"op": "game_eval", "params": {"code": "var d = get_node(\"/root/Arena/DummyTarget1\")\nd.take_damage(20.0)\nreturn d.hp"}}
```
Expected: returns `40.0` (60 max_hp - 20).

```
mcp__godot-ai__editor_manage {"op": "game_eval", "params": {"code": "var d = get_node(\"/root/Arena/DummyTarget1\")\nreturn d.get_node(\"HealthBar/Fill\").scale.x"}}
```
Expected: approximately `0.667` (40/60).

```
mcp__godot-ai__editor_manage {"op": "game_eval", "params": {"code": "var d = get_node(\"/root/Arena/DummyTarget1\")\nd.take_damage(100.0)\nreturn d.visible"}}
```
Expected: `false` (HP hit 0, dummy hides itself).

```
mcp__godot-ai__editor_manage {"op": "game_eval", "params": {"code": "await get_tree().create_timer(1.8).timeout\nvar d = get_node(\"/root/Arena/DummyTarget1\")\nreturn {\"visible\": d.visible, \"hp\": d.hp}"}}
```
Expected: `{"visible": true, "hp": 60.0}` — the dummy has auto-reset after `reset_delay` (1.5s).

```
mcp__godot-ai__editor_screenshot {"source": "game"}
mcp__godot-ai__project_manage {"op": "stop", "params": {}}
```
Expected screenshot: the dummy target visible with a full green health bar, no player robot yet (not built until Task 4).

- [ ] **Step 7: Commit**

```bash
git add robot_battler/damage_number.gd robot_battler/damage_number.tscn robot_battler/dummy_target.gd robot_battler/dummy_target.tscn robot_battler/arena.tscn
git commit -m "Add dummy target: HP, hit flash, floating damage numbers, auto-reset"
```

---

### Task 4: Player robot — movement and mouse aim

**Files:**
- Create: `res://robot_battler/player_robot.gd`
- Create: `res://robot_battler/player_robot.tscn`
- Modify: `res://robot_battler/arena.tscn` (add `PlayerRobot` instance)

**Interfaces:**
- Consumes: input actions `move_forward`, `move_back`, `move_left`, `move_right` (Task 1).
- Produces: `PlayerRobot` scene at `/Arena/PlayerRobot` once instanced; `turret` (`Node3D`, child `Turret`) and `aim_point` (`Vector3`, world-space point the turret is facing), both consumed by Task 5/6.

- [ ] **Step 1: Movement + aim script**

```
mcp__godot-ai__script_create
path: res://robot_battler/player_robot.gd
content:
```
```gdscript
extends CharacterBody3D

@export var move_speed: float = 6.0

@onready var turret: Node3D = $Turret
@onready var camera: Camera3D = $Camera3D

var aim_point: Vector3 = Vector3.ZERO


func _physics_process(_delta: float) -> void:
	_handle_movement()
	_handle_aim()
	move_and_slide()


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
```

- [ ] **Step 2: Player robot scene — body, collision, turret, camera**

```
mcp__godot-ai__scene_manage {"op": "create", "params": {"path": "res://robot_battler/player_robot.tscn", "root_type": "CharacterBody3D", "root_name": "PlayerRobot"}}
mcp__godot-ai__node_set_property {"path": "/PlayerRobot", "property": "collision_layer", "value": 2}
mcp__godot-ai__node_set_property {"path": "/PlayerRobot", "property": "collision_mask", "value": 5}

mcp__godot-ai__node_create {"type": "MeshInstance3D", "parent_path": "", "name": "Body"}
mcp__godot-ai__node_set_property {"path": "/PlayerRobot/Body", "property": "position", "value": {"x": 0, "y": 0.3, "z": 0}}
mcp__godot-ai__node_set_property {"path": "/PlayerRobot/Body", "property": "mesh", "value": {"__class__": "BoxMesh", "size": {"x": 1.0, "y": 0.6, "z": 1.4}}}
mcp__godot-ai__material_manage {"op": "apply_to_node", "params": {"node_path": "/PlayerRobot/Body", "type": "standard", "params": {"albedo_color": "#3f7fbf"}}}

mcp__godot-ai__node_create {"type": "CollisionShape3D", "parent_path": "", "name": "CollisionShape3D"}
mcp__godot-ai__node_set_property {"path": "/PlayerRobot/CollisionShape3D", "property": "position", "value": {"x": 0, "y": 0.3, "z": 0}}
mcp__godot-ai__node_set_property {"path": "/PlayerRobot/CollisionShape3D", "property": "shape", "value": {"__class__": "BoxShape3D", "size": {"x": 1.0, "y": 0.6, "z": 1.4}}}

mcp__godot-ai__node_create {"type": "Node3D", "parent_path": "", "name": "Turret"}
mcp__godot-ai__node_set_property {"path": "/PlayerRobot/Turret", "property": "position", "value": {"x": 0, "y": 0.6, "z": 0}}

mcp__godot-ai__node_create {"type": "MeshInstance3D", "parent_path": "/PlayerRobot/Turret", "name": "TurretMesh"}
mcp__godot-ai__node_set_property {"path": "/PlayerRobot/Turret/TurretMesh", "property": "position", "value": {"x": 0, "y": 0.2, "z": 0}}
mcp__godot-ai__node_set_property {"path": "/PlayerRobot/Turret/TurretMesh", "property": "mesh", "value": {"__class__": "CylinderMesh", "top_radius": 0.35, "bottom_radius": 0.35, "height": 0.4}}
mcp__godot-ai__material_manage {"op": "apply_to_node", "params": {"node_path": "/PlayerRobot/Turret/TurretMesh", "type": "standard", "params": {"albedo_color": "#274863"}}}

mcp__godot-ai__node_create {"type": "Marker3D", "parent_path": "/PlayerRobot/Turret", "name": "Muzzle"}
mcp__godot-ai__node_set_property {"path": "/PlayerRobot/Turret/Muzzle", "property": "position", "value": {"x": 0, "y": 0.2, "z": -0.9}}

mcp__godot-ai__camera_manage {"op": "create", "params": {"parent_path": "", "name": "Camera3D", "type": "3d", "make_current": true}}
mcp__godot-ai__node_set_property {"path": "/PlayerRobot/Camera3D", "property": "position", "value": {"x": 0, "y": 14, "z": 0}}
mcp__godot-ai__node_set_property {"path": "/PlayerRobot/Camera3D", "property": "rotation_degrees", "value": {"x": -90, "y": 0, "z": 0}}
mcp__godot-ai__camera_manage {"op": "configure", "params": {"camera_path": "/PlayerRobot/Camera3D", "properties": {"projection": "orthogonal", "size": 16}}}

mcp__godot-ai__script_attach {"path": "/PlayerRobot", "script_path": "res://robot_battler/player_robot.gd"}
mcp__godot-ai__scene_save {}
```

- [ ] **Step 3: Place the player in the arena**

```
mcp__godot-ai__scene_open {"path": "res://robot_battler/arena.tscn"}
mcp__godot-ai__node_create {"type": "", "parent_path": "", "name": "PlayerRobot", "scene_path": "res://robot_battler/player_robot.tscn"}
mcp__godot-ai__node_set_property {"path": "/Arena/PlayerRobot", "property": "position", "value": {"x": 0, "y": 0, "z": 0}}
mcp__godot-ai__scene_save {}
```

- [ ] **Step 4: Verify movement**

```
mcp__godot-ai__project_run {"mode": "main"}
mcp__godot-ai__editor_manage {"op": "game_eval", "params": {"code": "return get_node(\"/root/Arena/PlayerRobot\").global_position"}}
```
Note the returned position (expect roughly `(0, 0, 0)`), then:
```
mcp__godot-ai__game_manage {"op": "input_key", "params": {"key": "W", "pressed": true}}
```
Wait briefly (this happens automatically as MCP calls round-trip through the running game over ~1 second of real time; if the harness needs an explicit pause, issue two or three more no-op `editor_state` polls a fraction of a second apart), then:
```
mcp__godot-ai__game_manage {"op": "input_key", "params": {"key": "W", "pressed": false}}
mcp__godot-ai__editor_manage {"op": "game_eval", "params": {"code": "return get_node(\"/root/Arena/PlayerRobot\").global_position"}}
```
Expected: `z` is now clearly negative (robot moved forward, i.e. toward -Z, matching where `DummyTarget1` sits at `z=-4`), `x` roughly unchanged.

- [ ] **Step 5: Verify mouse aim (resolution-independent)**

```
mcp__godot-ai__editor_manage {"op": "game_eval", "params": {"code": "return get_viewport().get_visible_rect().size"}}
```
Read the returned `{x, y}` viewport size, call it `(vw, vh)`. Then:
```
mcp__godot-ai__game_manage {"op": "input_mouse", "params": {"event": "motion", "position": {"x": vw * 0.2, "y": vh * 0.5}}}
mcp__godot-ai__editor_manage {"op": "game_eval", "params": {"code": "return get_node(\"/root/Arena/PlayerRobot/Turret\").rotation.y"}}
```
Record this as `rot_left`. Then:
```
mcp__godot-ai__game_manage {"op": "input_mouse", "params": {"event": "motion", "position": {"x": vw * 0.8, "y": vh * 0.5}}}
mcp__godot-ai__editor_manage {"op": "game_eval", "params": {"code": "return get_node(\"/root/Arena/PlayerRobot/Turret\").rotation.y"}}
```
Record as `rot_right`. Expected: `abs(rot_left - rot_right) > 0.5` (the turret visibly rotated to track the mouse from one side of the screen to the other).

```
mcp__godot-ai__editor_screenshot {"source": "game"}
mcp__godot-ai__project_manage {"op": "stop", "params": {}}
```
Expected screenshot: robot visible top-down in the arena near the dummy target.

- [ ] **Step 6: Commit**

```bash
git add robot_battler/player_robot.gd robot_battler/player_robot.tscn robot_battler/arena.tscn
git commit -m "Add player robot: WASD movement, top-down camera, mouse-aim turret"
```

---

### Task 5: Melee attack

**Files:**
- Create: `res://robot_battler/melee_hitbox.gd`
- Create: `res://robot_battler/melee_hitbox.tscn`
- Modify: `res://robot_battler/player_robot.gd` (full-file rewrite, adds melee attack)

**Interfaces:**
- Consumes: input action `attack` (Task 1); `DummyTarget.take_damage()` (Task 3, works for any node with that method).
- Produces: `PlayerRobot.attack() -> void` and `MeleeHitbox.setup(damage: float, reach: float, attacker: Node) -> void`, both extended in Task 6.

- [ ] **Step 1: Melee hitbox script**

```
mcp__godot-ai__script_create
path: res://robot_battler/melee_hitbox.gd
content:
```
```gdscript
extends Area3D

const LIFETIME := 0.15

var _damage: float = 0.0
var _attacker: Node = null
var _hit_bodies: Array[Node] = []


func setup(damage: float, reach: float, attacker: Node) -> void:
	_damage = damage
	_attacker = attacker
	var shape := $CollisionShape3D.shape as BoxShape3D
	shape.size = Vector3(1.6, 1.2, reach)
	translate_object_local(Vector3(0, 0, -reach * 0.5))


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(LIFETIME).timeout.connect(queue_free)


func _on_body_entered(body: Node) -> void:
	if body == _attacker or body in _hit_bodies:
		return
	if body.has_method("take_damage"):
		_hit_bodies.append(body)
		body.take_damage(_damage)
```

- [ ] **Step 2: Melee hitbox scene**

```
mcp__godot-ai__scene_manage {"op": "create", "params": {"path": "res://robot_battler/melee_hitbox.tscn", "root_type": "Area3D", "root_name": "MeleeHitbox"}}
mcp__godot-ai__node_set_property {"path": "/MeleeHitbox", "property": "monitoring", "value": true}
mcp__godot-ai__node_set_property {"path": "/MeleeHitbox", "property": "monitorable", "value": false}
mcp__godot-ai__node_set_property {"path": "/MeleeHitbox", "property": "collision_layer", "value": 0}
mcp__godot-ai__node_set_property {"path": "/MeleeHitbox", "property": "collision_mask", "value": 4}
mcp__godot-ai__node_create {"type": "CollisionShape3D", "parent_path": "", "name": "CollisionShape3D"}
mcp__godot-ai__node_set_property {"path": "/MeleeHitbox/CollisionShape3D", "property": "shape", "value": {"__class__": "BoxShape3D", "size": {"x": 1.6, "y": 1.2, "z": 1.0}}}
mcp__godot-ai__script_attach {"path": "/MeleeHitbox", "script_path": "res://robot_battler/melee_hitbox.gd"}
mcp__godot-ai__scene_save {}
```

- [ ] **Step 3: Wire melee into the player robot (full-file rewrite)**

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

const MELEE_HITBOX_SCENE := preload("res://robot_battler/melee_hitbox.tscn")

@onready var turret: Node3D = $Turret
@onready var muzzle: Marker3D = $Turret/Muzzle
@onready var camera: Camera3D = $Camera3D

var aim_point: Vector3 = Vector3.ZERO
var _melee_cooldown_remaining: float = 0.0


func _physics_process(delta: float) -> void:
	_melee_cooldown_remaining = maxf(0.0, _melee_cooldown_remaining - delta)
	_handle_movement()
	_handle_aim()
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		attack()


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


func attack() -> void:
	_attack_melee()


func _attack_melee() -> void:
	if _melee_cooldown_remaining > 0.0:
		return
	_melee_cooldown_remaining = melee_cooldown
	var hitbox := MELEE_HITBOX_SCENE.instantiate()
	get_tree().current_scene.add_child(hitbox)
	hitbox.global_transform = muzzle.global_transform
	hitbox.setup(melee_damage, melee_range, self)
```

```
mcp__godot-ai__scene_open {"path": "res://robot_battler/arena.tscn"}
mcp__godot-ai__scene_save {}
```

- [ ] **Step 4: Verify melee lands on a dummy**

Move the dummy within guaranteed melee range for a deterministic test, then use `game_eval` to aim and attack directly (this exercises the real `attack()` → hitbox-spawn → collision → `take_damage()` pipeline; it just skips simulating literal mouse movement, which Task 4 already verified separately):

```
mcp__godot-ai__project_run {"mode": "main"}
mcp__godot-ai__editor_manage {"op": "game_eval", "params": {"code": "var player = get_node(\"/root/Arena/PlayerRobot\")\nvar dummy = get_node(\"/root/Arena/DummyTarget1\")\nplayer.turret.look_at(dummy.global_position, Vector3.UP)\nplayer.attack()\nawait get_tree().create_timer(0.05).timeout\nreturn dummy.hp"}}
```
Expected: `35.0` (60 max_hp - 25 melee_damage). `DummyTarget1` sits at `z=-4`, `PlayerRobot` at `z=0`, `melee_range=2.2` — this is a wider gap than melee reach, so if this assertion fails with `hp` unchanged, first check the hitbox actually reaches the dummy; if so, move `DummyTarget1`'s position to `z=-1.5` (well within `melee_range`) via `node_set_property` + `scene_save` while the game is stopped, and re-run this step. Record whichever position change was needed — it feeds directly into Task 9's final dummy placement, which explicitly places one dummy close for melee testing.

```
mcp__godot-ai__editor_manage {"op": "game_eval", "params": {"code": "var player = get_node(\"/root/Arena/PlayerRobot\")\nplayer.attack()\nawait get_tree().create_timer(0.05).timeout\nreturn get_node(\"/root/Arena/DummyTarget1\").hp"}}
```
Expected: still `35.0` — the second attack fires within `melee_cooldown` (0.5s) of the first `game_eval` call completing, so it should be rejected. If this is flaky because too much wall-clock time passed between the two tool calls, that's acceptable — the important assertion is Step 4's first check (melee connects) and Task 5's cooldown behavior is exercised again more deterministically inside Task 9's full playtest pass.

```
mcp__godot-ai__project_manage {"op": "stop", "params": {}}
```

- [ ] **Step 5: Commit**

```bash
git add robot_battler/melee_hitbox.gd robot_battler/melee_hitbox.tscn robot_battler/player_robot.gd robot_battler/arena.tscn
git commit -m "Add melee attack: hitbox spawn, damage on contact, cooldown"
```

---

### Task 6: Ranged attack + weapon swap + HUD label

**Files:**
- Create: `res://robot_battler/projectile.gd`
- Create: `res://robot_battler/projectile.tscn`
- Modify: `res://robot_battler/player_robot.gd` (full-file rewrite, adds ranged weapon, `Weapon` enum, swap, HUD)
- Modify: `res://robot_battler/player_robot.tscn` (add `HUD` CanvasLayer + `WeaponLabel`)

**Interfaces:**
- Consumes: input action `weapon_swap` (Task 1); `DummyTarget.take_damage()` (Task 3).
- Produces: `PlayerRobot.current_weapon: Weapon` (`MELEE` or `RANGED`), `PlayerRobot.swap_weapon() -> void`, `Projectile.setup(direction: Vector3, speed: float, damage: float, max_distance: float, attacker: Node) -> void`.

- [ ] **Step 1: Projectile script**

```
mcp__godot-ai__script_create
path: res://robot_battler/projectile.gd
content:
```
```gdscript
extends Area3D

var _direction: Vector3 = Vector3.FORWARD
var _speed: float = 18.0
var _damage: float = 10.0
var _max_distance: float = 20.0
var _traveled: float = 0.0
var _attacker: Node = null


func setup(direction: Vector3, speed: float, damage: float, max_distance: float, attacker: Node) -> void:
	_direction = direction
	_speed = speed
	_damage = damage
	_max_distance = max_distance
	_attacker = attacker
	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP)


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	var step := _direction * _speed * delta
	global_position += step
	_traveled += step.length()
	if _traveled >= _max_distance:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body == _attacker:
		return
	if body.has_method("take_damage"):
		body.take_damage(_damage)
	queue_free()
```

- [ ] **Step 2: Projectile scene**

```
mcp__godot-ai__scene_manage {"op": "create", "params": {"path": "res://robot_battler/projectile.tscn", "root_type": "Area3D", "root_name": "Projectile"}}
mcp__godot-ai__node_set_property {"path": "/Projectile", "property": "monitoring", "value": true}
mcp__godot-ai__node_set_property {"path": "/Projectile", "property": "monitorable", "value": false}
mcp__godot-ai__node_set_property {"path": "/Projectile", "property": "collision_layer", "value": 0}
mcp__godot-ai__node_set_property {"path": "/Projectile", "property": "collision_mask", "value": 4}
mcp__godot-ai__node_create {"type": "CollisionShape3D", "parent_path": "", "name": "CollisionShape3D"}
mcp__godot-ai__node_set_property {"path": "/Projectile/CollisionShape3D", "property": "shape", "value": {"__class__": "SphereShape3D", "radius": 0.15}}
mcp__godot-ai__node_create {"type": "MeshInstance3D", "parent_path": "", "name": "MeshInstance3D"}
mcp__godot-ai__node_set_property {"path": "/Projectile/MeshInstance3D", "property": "mesh", "value": {"__class__": "SphereMesh", "radius": 0.15, "height": 0.3}}
mcp__godot-ai__material_manage {"op": "apply_to_node", "params": {"node_path": "/Projectile/MeshInstance3D", "type": "standard", "params": {"albedo_color": "#ffcc33", "emission_enabled": true, "emission": "#ffcc33"}}}
mcp__godot-ai__script_attach {"path": "/Projectile", "script_path": "res://robot_battler/projectile.gd"}
mcp__godot-ai__scene_save {}
```

- [ ] **Step 3: Add HUD to the player robot scene**

```
mcp__godot-ai__scene_open {"path": "res://robot_battler/player_robot.tscn"}
mcp__godot-ai__node_create {"type": "CanvasLayer", "parent_path": "", "name": "HUD"}
mcp__godot-ai__node_create {"type": "Label", "parent_path": "/PlayerRobot/HUD", "name": "WeaponLabel"}
mcp__godot-ai__node_set_property {"path": "/PlayerRobot/HUD/WeaponLabel", "property": "position", "value": {"x": 16, "y": 16}}
mcp__godot-ai__node_set_property {"path": "/PlayerRobot/HUD/WeaponLabel", "property": "text", "value": "Weapon: Melee"}
mcp__godot-ai__scene_save {}
```

- [ ] **Step 4: Wire ranged weapon + swap into the player robot (full-file rewrite)**

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

var aim_point: Vector3 = Vector3.ZERO
var current_weapon: Weapon = Weapon.MELEE

var _melee_cooldown_remaining: float = 0.0
var _ranged_cooldown_remaining: float = 0.0


func _ready() -> void:
	_update_weapon_label()


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
	_update_weapon_label()


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


func _update_weapon_label() -> void:
	weapon_label.text = "Weapon: Melee" if current_weapon == Weapon.MELEE else "Weapon: Ranged"
```

```
mcp__godot-ai__scene_open {"path": "res://robot_battler/arena.tscn"}
mcp__godot-ai__scene_save {}
```

- [ ] **Step 5: Verify weapon swap and ranged attack**

```
mcp__godot-ai__project_run {"mode": "main"}
mcp__godot-ai__editor_manage {"op": "game_eval", "params": {"code": "var p = get_node(\"/root/Arena/PlayerRobot\")\nreturn p.weapon_label.text"}}
```
Expected: `"Weapon: Melee"`.

```
mcp__godot-ai__game_manage {"op": "input_key", "params": {"key": "Q", "pressed": true}}
mcp__godot-ai__game_manage {"op": "input_key", "params": {"key": "Q", "pressed": false}}
mcp__godot-ai__editor_manage {"op": "game_eval", "params": {"code": "var p = get_node(\"/root/Arena/PlayerRobot\")\nreturn p.weapon_label.text"}}
```
Expected: `"Weapon: Ranged"`.

```
mcp__godot-ai__editor_manage {"op": "game_eval", "params": {"code": "var player = get_node(\"/root/Arena/PlayerRobot\")\nvar dummy = get_node(\"/root/Arena/DummyTarget1\")\nplayer.turret.look_at(dummy.global_position, Vector3.UP)\nplayer.aim_point = dummy.global_position\nvar hp_before = dummy.hp\nplayer.attack()\nawait get_tree().create_timer(1.5).timeout\nreturn {\"hp_before\": hp_before, \"hp_after\": dummy.hp}"}}
```
Expected: `hp_after < hp_before` (projectile traveled and hit the dummy within the 1.5s wait).

```
mcp__godot-ai__editor_screenshot {"source": "game"}
mcp__godot-ai__project_manage {"op": "stop", "params": {}}
```

- [ ] **Step 6: Commit**

```bash
git add robot_battler/projectile.gd robot_battler/projectile.tscn robot_battler/player_robot.gd robot_battler/player_robot.tscn robot_battler/arena.tscn
git commit -m "Add ranged attack, weapon swap, and weapon HUD label"
```

---

### Task 7: Populate the arena with multiple dummy targets

**Files:**
- Modify: `res://robot_battler/arena.tscn` (add 2–3 more `DummyTarget` instances, reposition for melee/ranged range coverage)

**Interfaces:**
- Consumes: `dummy_target.tscn` (Task 3), whatever final position `DummyTarget1` ended up at from Task 5 Step 4.

- [ ] **Step 1: Add three more dummies at varying range/angle**

```
mcp__godot-ai__scene_open {"path": "res://robot_battler/arena.tscn"}
mcp__godot-ai__node_create {"type": "", "parent_path": "", "name": "DummyTarget2", "scene_path": "res://robot_battler/dummy_target.tscn"}
mcp__godot-ai__node_set_property {"path": "/Arena/DummyTarget2", "property": "position", "value": {"x": 6, "y": 0, "z": -6}}
mcp__godot-ai__node_create {"type": "", "parent_path": "", "name": "DummyTarget3", "scene_path": "res://robot_battler/dummy_target.tscn"}
mcp__godot-ai__node_set_property {"path": "/Arena/DummyTarget3", "property": "position", "value": {"x": -8, "y": 0, "z": -10}}
mcp__godot-ai__node_create {"type": "", "parent_path": "", "name": "DummyTarget4", "scene_path": "res://robot_battler/dummy_target.tscn"}
mcp__godot-ai__node_set_property {"path": "/Arena/DummyTarget4", "property": "position", "value": {"x": 9, "y": 0, "z": 3}}
mcp__godot-ai__scene_save {}
```

Confirm `DummyTarget1` is at whatever close-range position Task 5 Step 4 settled on (within `melee_range` of the origin, e.g. `z=-1.5`) — this keeps one dummy reachable for melee and the other three spread out at longer ranges/angles for ranged testing.

- [ ] **Step 2: Verify layout visually**

```
mcp__godot-ai__project_run {"mode": "main"}
mcp__godot-ai__editor_screenshot {"source": "game"}
mcp__godot-ai__project_manage {"op": "stop", "params": {}}
```
Expected: four dummy targets visible at varying distances/angles from the player's spawn point, all with full health bars.

- [ ] **Step 3: Commit**

```bash
git add robot_battler/arena.tscn
git commit -m "Populate arena with four dummy targets for melee/ranged range coverage"
```

---

### Task 8: Full playtest verification pass

**Files:** none (no code changes — this task only runs the spec's section-8 checklist end to end and fixes anything it finds)

**Interfaces:** none — this exercises everything built in Tasks 1–7 together.

- [ ] **Step 1: Run the full checklist from the spec**

```
mcp__godot-ai__project_run {"mode": "main"}
```

Then, in order, verify each item from `docs/superpowers/specs/2026-07-21-realtime-combat-slice-design.md` section 8:

1. **Movement in all directions** — send `input_key` for `W`, `A`, `S`, `D` individually (press then release each), reading `global_position` via `game_eval` before/after each to confirm it changes along the expected axis.
2. **Turret tracks the mouse** — repeat the two-screen-position check from Task 4 Step 5.
3. **`Q` swaps weapon and the label updates** — repeat Task 6 Step 5's swap check, and swap a second time to confirm it toggles back to `"Weapon: Melee"`.
4. **Melee connects on a nearby dummy without multi-hitting** — with weapon set to melee (swap back if needed), aim at `DummyTarget1` and call `attack()` via `game_eval`, confirm `hp` drops by exactly `melee_damage` (25.0) and a second `attack()` call issued before `melee_cooldown` (0.5s) elapses does not reduce it further.
5. **Projectiles travel and hit a distant dummy** — aim at `DummyTarget3` (the farthest one), swap to ranged, `attack()`, wait, confirm its `hp` dropped.
6. **HP bars and damage numbers appear** — `editor_screenshot {"source": "game"}` immediately after a hit; confirm visually that the health-bar fill shrank and a damage number is visible.
7. **Dummies reset after depletion** — pick one dummy, call `take_damage(1000.0)` via `game_eval` to deplete it in one hit, confirm `visible == false` immediately after, then wait past `reset_delay` (1.5s) and confirm `visible == true` and `hp == max_hp` again.

```
mcp__godot-ai__project_manage {"op": "stop", "params": {}}
```

If any check fails, fix the relevant script or scene property, re-save, and re-run that specific check before moving on — do not proceed to Step 2 with a known-failing check.

- [ ] **Step 2: Final commit**

```bash
git add -A
git commit -m "Verify real-time combat slice end to end against spec section 8"
```

---

## Self-Review Notes

- **Spec coverage:** §3 scene/entity structure → Tasks 2–7. §4 movement/controls → Task 4. §5 attacks → Tasks 5–6. §6 feedback/dummies → Task 3. §7 data model (`@export` stats, no parts system) → Tasks 4–6 exports. §8 testing → Task 8.
- **Type/name consistency checked:** `turret`, `muzzle`, `camera`, `aim_point`, `current_weapon`, `melee_damage/range/cooldown`, `ranged_damage/speed/max_distance/cooldown`, and `weapon_label` are spelled identically everywhere they're declared (Task 4) and later consumed/extended (Tasks 5–6). `take_damage(amount: float)` is the single duck-typed contract both `melee_hitbox.gd` and `projectile.gd` call, matching `dummy_target.gd`'s signature.
- **No placeholders:** every step shows complete script content or a concrete, executable tool call; the one spot with a conditional ("if this check fails, reposition DummyTarget1...") is a real contingency for a distance value that depends on a runtime measurement taken in Task 5, not an unresolved requirement.
