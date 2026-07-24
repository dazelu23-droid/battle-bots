# Enemy Turrets Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the four static dummy targets with hostile `turret_single`-model turrets that track the player and fire projectiles, and give the player an HP/respawn system so getting shot matters.

**Architecture:** A new `enemy_projectile.tscn` reuses the existing `projectile.gd` with `mask=2` (hits player) and a red look. `player_robot.gd` gains HP + `take_damage` + respawn (which resets all turrets) and joins group `"player"`. A new `enemy_turret.tscn`/`.gd` (based on the dummy's HP system, using `turret_single.glb`) adds track-and-fire AI. The arena's four dummies are swapped for four turrets.

**Tech Stack:** Godot 4.7, GDScript, godot-ai MCP tools, `assets/kenney_space-kit/` (CC0).

## Global Constraints

- Spec: `docs/superpowers/specs/2026-07-24-enemy-turrets-design.md`.
- All scene/node/material/script authoring goes through the `mcp__godot-ai__*` MCP tools; `.gd` changes via `mcp__godot-ai__script_create` (full-file overwrite).
- Collision layers: world=1, player=2, turrets=4. Enemy projectile = Area3D `mask=2`; player projectile = Area3D `mask=4` (unchanged).
- `editor_screenshot {"source":"viewport"}` is unreliable in this session — use `source:"game"`. Critically: **`await`-based physics-loop checks hang** because the non-headless game loses OS focus during interleaved tool calls (confirmed in prior verification). All runtime verification MUST use **synchronous** `editor_manage(op="game_eval")` calls — call methods directly, read state back in the same eval, no `await get_tree().physics_frame` / `create_timer`.
- `turret_single.glb` likely has the same baked-in pivot offset as `turret_double.glb` (model geometry sits offset from its node origin). Mitigation: instance the glb inside a `Model` wrapper `Node3D` whose own transform is identity, and do all facing via the turret ROOT (`look_at` on `self`), never by rotating the model/wrapper — this keeps the visual centered on the root origin through rotations. Calibrate scale/position empirically (AABB-based), same procedure as the ranged-weapon-visual plan.
- Commit after each task with git (branch `main`, do NOT push).

---

### Task 1: Enemy projectile scene

**Files:**
- Create: `res://robot_battler/enemy_projectile.tscn` (no new script — reuses `res://robot_battler/projectile.gd`)

**Interfaces:**
- Produces: `enemy_projectile.tscn` — an `Area3D` whose `setup()` is the existing `projectile.gd.setup(direction, speed, damage, max_distance, attacker)`. Consumed by `enemy_turret.gd` in Task 4.

- [ ] **Step 1: Create the scene**

```
mcp__godot-ai__scene_manage {"op": "create", "params": {"path": "res://robot_battler/enemy_projectile.tscn", "root_type": "Area3D", "root_name": "EnemyProjectile"}}
mcp__godot-ai__node_set_property {"path": "/EnemyProjectile", "property": "monitoring", "value": true}
mcp__godot-ai__node_set_property {"path": "/EnemyProjectile", "property": "monitorable", "value": false}
mcp__godot-ai__node_set_property {"path": "/EnemyProjectile", "property": "collision_layer", "value": 0}
mcp__godot-ai__node_set_property {"path": "/EnemyProjectile", "property": "collision_mask", "value": 2}
```
(If any bool `value: true/false` comes back `WRONG_TYPE` — a known quirk where `node_set_property` stringifies bools — route that one write through `mcp__godot-ai__batch_execute` with `{"command":"set_property","params":{"path":"/EnemyProjectile","property":"monitoring","value":true}}`, which preserves the bool type.)

- [ ] **Step 2: Collision + mesh**

```
mcp__godot-ai__node_create {"type": "CollisionShape3D", "parent_path": "", "name": "CollisionShape3D"}
mcp__godot-ai__node_set_property {"path": "/EnemyProjectile/CollisionShape3D", "property": "shape", "value": {"__class__": "SphereShape3D", "radius": 0.15}}
mcp__godot-ai__node_create {"type": "MeshInstance3D", "parent_path": "", "name": "MeshInstance3D"}
mcp__godot-ai__node_set_property {"path": "/EnemyProjectile/MeshInstance3D", "property": "mesh", "value": {"__class__": "SphereMesh", "radius": 0.15, "height": 0.3}}
mcp__godot-ai__material_manage {"op": "apply_to_node", "params": {"node_path": "/EnemyProjectile/MeshInstance3D", "type": "standard", "params": {"albedo_color": "#ff3b3b", "emission_enabled": true, "emission": "#ff3b3b"}}}
```

- [ ] **Step 3: Attach the existing projectile script and save**

```
mcp__godot-ai__script_attach {"path": "/EnemyProjectile", "script_path": "res://robot_battler/projectile.gd"}
mcp__godot-ai__scene_save {}
```

- [ ] **Step 4: Verify the collision mask composition**

```
mcp__godot-ai__node_get_properties {"path": "/EnemyProjectile"}
```
Confirm `collision_layer == 0`, `collision_mask == 2`, `monitoring == true`, `monitorable == false`, and the script is attached. (Layer/mask correctness is the load-bearing property here — it's what makes enemy fire hit the player and only the player.)

- [ ] **Step 5: Commit**

```bash
git add robot_battler/enemy_projectile.tscn
git commit -m "Add enemy projectile scene (reuses projectile.gd, mask=2, red)"
```

---

### Task 2: Player HP, HUD bar, respawn, and "player" group

**Files:**
- Modify: `res://robot_battler/player_robot.tscn` (add `HPBar` ProgressBar under HUD)
- Modify: `res://robot_battler/player_robot.gd` (full-file rewrite)

**Interfaces:**
- Produces: `player_robot.take_damage(amount: float) -> void` (duck-typed, same contract as dummy/turret — `projectile.gd` needs no change to damage the player). Player joins group `"player"` (consumed by `enemy_turret.gd` in Task 4). Player's `reset()`-on-respawn calls `reset()` on every node in group `"enemy_turret"` (produced by Task 3).

- [ ] **Step 1: Add the HP bar to the HUD**

```
mcp__godot-ai__scene_open {"path": "res://robot_battler/player_robot.tscn"}
mcp__godot-ai__node_create {"type": "ProgressBar", "parent_path": "/PlayerRobot/HUD", "name": "HPBar"}
mcp__godot-ai__node_set_property {"path": "/PlayerRobot/HUD/HPBar", "property": "position", "value": {"x": 16, "y": 52}}
mcp__godot-ai__node_set_property {"path": "/PlayerRobot/HUD/HPBar", "property": "size", "value": {"x": 200, "y": 20}}
mcp__godot-ai__node_set_property {"path": "/PlayerRobot/HUD/HPBar", "property": "min_value", "value": 0}
mcp__godot-ai__node_set_property {"path": "/PlayerRobot/HUD/HPBar", "property": "max_value", "value": 100}
mcp__godot-ai__node_set_property {"path": "/PlayerRobot/HUD/HPBar", "property": "value", "value": 100}
mcp__godot-ai__scene_save {}
```
(Position `(16, 52)` puts it just under the existing `WeaponLabel` at `(16, 16)`.)

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
@export var max_hp: float = 100.0

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
@onready var hp_bar: ProgressBar = $HUD/HPBar

var current_weapon: Weapon = Weapon.MELEE
var hp: float = 0.0
var _spawn_point: Vector3 = Vector3.ZERO
var _melee_cooldown_remaining: float = 0.0
var _ranged_cooldown_remaining: float = 0.0


func _ready() -> void:
	add_to_group("player")
	hp = max_hp
	hp_bar.max_value = max_hp
	_spawn_point = global_position
	_update_hp_bar()
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


func take_damage(amount: float) -> void:
	hp = max(0.0, hp - amount)
	_update_hp_bar()
	if hp <= 0.0:
		_respawn()


func _respawn() -> void:
	hp = max_hp
	global_position = _spawn_point
	_update_hp_bar()
	for turret in get_tree().get_nodes_in_group("enemy_turret"):
		turret.reset()


func _update_hp_bar() -> void:
	hp_bar.value = hp
```

- [ ] **Step 3: Verify take_damage, the HP bar, respawn, and the group — all synchronously**

```
mcp__godot-ai__project_run {"mode": "main"}
mcp__godot-ai__editor_manage {"op": "game_eval", "params": {"code": "var p = get_node(\"/root/Arena/PlayerRobot\")\nvar before = p.hp\np.take_damage(30.0)\nreturn {\"in_group\": p.is_in_group(\"player\"), \"hp_before\": before, \"hp_after_30\": p.hp, \"bar_value\": p.hp_bar.value}"}}
```
Expected: `in_group = true`, `hp_before = 100`, `hp_after_30 = 70`, `bar_value = 70`.

- [ ] **Step 4: Verify respawn triggers at 0 HP (and would reset turrets)**

```
mcp__godot-ai__editor_manage {"op": "game_eval", "params": {"code": "var p = get_node(\"/root/Arena/PlayerRobot\")\np.global_position = Vector3(5, 0, 5)\np.take_damage(1000.0)\nreturn {\"hp_after_death\": p.hp, \"pos_after_death\": p.global_position}"}}
```
Expected: `hp_after_death = 100` (respawned to max), `pos_after_death ≈ (0, 0, 0)` (back at spawn). (At this point no `enemy_turret` nodes exist yet, so the reset loop is a no-op — that's fine; the turret-reset path is exercised in Task 5.)

- [ ] **Step 5: Regression-check attacks + movement still work (unchanged code)**

```
mcp__godot-ai__editor_manage {"op": "game_eval", "params": {"code": "var p = get_node(\"/root/Arena/PlayerRobot\")\nreturn {\"move_speed\": p.move_speed, \"turn_speed\": p.turn_speed, \"melee_damage\": p.melee_damage, \"ranged_damage\": p.ranged_damage, \"max_hp\": p.max_hp}"}}
```
Expected: `move_speed=6.0, turn_speed=180.0, melee_damage=25.0, ranged_damage=10.0, max_hp=100.0` — confirms the rewrite preserved all prior values. (Tank-control movement and both attacks are byte-identical to the prior committed `player_robot.gd`; no behavioral re-test needed beyond confirming the constants survived the rewrite.)

```
mcp__godot-ai__project_manage {"op": "stop", "params": {}}
```

- [ ] **Step 6: Commit**

```bash
git add robot_battler/player_robot.gd robot_battler/player_robot.tscn
git commit -m "Add player HP, HUD health bar, take_damage, and respawn-on-death"
```

---

### Task 3: Enemy turret entity (model + HP + destroyed/reset, no AI yet)

**Files:**
- Create: `res://robot_battler/enemy_turret.gd`
- Create: `res://robot_battler/enemy_turret.tscn`

**Interfaces:**
- Produces: `enemy_turret.take_damage(amount)`, `enemy_turret.reset()`, group `"enemy_turret"` membership, fields `max_hp`/`hp`. Consumes `damage_number.tscn` (existing). Task 4 extends this script with AI; Task 5 instances it into the arena and relies on `reset()` being called by the player's respawn.

- [ ] **Step 1: Write enemy_turret.gd (entity only — no AI this task)**

```
mcp__godot-ai__script_create
path: res://robot_battler/enemy_turret.gd
content:
```
```gdscript
extends StaticBody3D

@export var max_hp: float = 60.0

@onready var model: Node3D = $Model
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var health_fill: MeshInstance3D = $HealthBar/Fill

const DAMAGE_NUMBER_SCENE := preload("res://robot_battler/damage_number.tscn")

var hp: float = 0.0
var _flash_tween: Tween = null
var _destroyed: bool = false


func _ready() -> void:
	add_to_group("enemy_turret")
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


func reset() -> void:
	hp = max_hp
	_destroyed = false
	visible = true
	collision_shape.disabled = false
	_update_health_bar()


func _update_health_bar() -> void:
	var ratio: float = clampf(hp / max_hp, 0.0, 1.0) if max_hp > 0.0 else 0.0
	health_fill.scale.x = ratio


func _flash() -> void:
	if _flash_tween != null and _flash_tween.is_running():
		_flash_tween.kill()
	model.scale = Vector3(1.15, 1.15, 1.15)
	_flash_tween = create_tween()
	_flash_tween.tween_property(model, "scale", Vector3.ONE, 0.12)


func _spawn_damage_number(amount: float) -> void:
	var number := DAMAGE_NUMBER_SCENE.instantiate()
	get_tree().current_scene.add_child(number)
	number.global_position = global_position + Vector3(0, 2.6, 0)
	number.setup(amount)


func _on_depleted() -> void:
	_destroyed = true
	visible = false
	collision_shape.disabled = true
```

- [ ] **Step 2: Create the scene skeleton**

```
mcp__godot-ai__scene_manage {"op": "create", "params": {"path": "res://robot_battler/enemy_turret.tscn", "root_type": "StaticBody3D", "root_name": "EnemyTurret"}}
mcp__godot-ai__node_set_property {"path": "/EnemyTurret", "property": "collision_layer", "value": 4}
mcp__godot-ai__node_set_property {"path": "/EnemyTurret", "property": "collision_mask", "value": 0}

mcp__godot-ai__node_create {"type": "CollisionShape3D", "parent_path": "", "name": "CollisionShape3D"}
mcp__godot-ai__node_set_property {"path": "/EnemyTurret/CollisionShape3D", "property": "position", "value": {"x": 0, "y": 0.5, "z": 0}}
mcp__godot-ai__node_set_property {"path": "/EnemyTurret/CollisionShape3D", "property": "shape", "value": {"__class__": "BoxShape3D", "size": {"x": 1.0, "y": 1.0, "z": 1.0}}}

mcp__godot-ai__node_create {"type": "Node3D", "parent_path": "", "name": "HealthBar"}
mcp__godot-ai__node_set_property {"path": "/EnemyTurret/HealthBar", "property": "position", "value": {"x": 0, "y": 1.6, "z": 0}}
mcp__godot-ai__node_create {"type": "MeshInstance3D", "parent_path": "/EnemyTurret/HealthBar", "name": "Background"}
mcp__godot-ai__node_set_property {"path": "/EnemyTurret/HealthBar/Background", "property": "rotation_degrees", "value": {"x": -90, "y": 0, "z": 0}}
mcp__godot-ai__node_set_property {"path": "/EnemyTurret/HealthBar/Background", "property": "mesh", "value": {"__class__": "QuadMesh", "size": {"x": 1.0, "y": 0.16}}}
mcp__godot-ai__material_manage {"op": "apply_to_node", "params": {"node_path": "/EnemyTurret/HealthBar/Background", "type": "standard", "params": {"albedo_color": "#20140f"}}}
mcp__godot-ai__node_create {"type": "MeshInstance3D", "parent_path": "/EnemyTurret/HealthBar", "name": "Fill"}
mcp__godot-ai__node_set_property {"path": "/EnemyTurret/HealthBar/Fill", "property": "position", "value": {"x": 0, "y": 0.01, "z": 0}}
mcp__godot-ai__node_set_property {"path": "/EnemyTurret/HealthBar/Fill", "property": "rotation_degrees", "value": {"x": -90, "y": 0, "z": 0}}
mcp__godot-ai__node_set_property {"path": "/EnemyTurret/HealthBar/Fill", "property": "mesh", "value": {"__class__": "QuadMesh", "size": {"x": 1.0, "y": 0.16}}}
mcp__godot-ai__material_manage {"op": "apply_to_node", "params": {"node_path": "/EnemyTurret/HealthBar/Fill", "type": "standard", "params": {"albedo_color": "#e0533b"}}}

mcp__godot-ai__node_create {"type": "Marker3D", "parent_path": "", "name": "Muzzle"}
mcp__godot-ai__node_set_property {"path": "/EnemyTurret/Muzzle", "property": "position", "value": {"x": 0, "y": 0.5, "z": -0.6}}
```

- [ ] **Step 3: Add and calibrate the turret_single model (the `Model` wrapper)**

```
mcp__godot-ai__filesystem_manage {"op": "scan", "params": {}}
mcp__godot-ai__node_create {"name": "TurretSingleGLB", "parent_path": "", "scene_path": "res://assets/kenney_space-kit/Models/GLTF format/turret_single.glb"}
mcp__godot-ai__node_create {"type": "Node3D", "parent_path": "", "name": "Model"}
mcp__godot-ai__node_manage {"op": "reparent", "params": {"path": "/EnemyTurret/TurretSingleGLB", "new_parent": "/EnemyTurret/Model"}}
mcp__godot-ai__node_set_property {"path": "/EnemyTurret/Model", "property": "position", "value": {"x": 0, "y": 0.0, "z": 0}}
mcp__godot-ai__node_set_property {"path": "/EnemyTurret/Model", "property": "visible", "value": true}
```
(Wrapper pattern: `Model` is the script's `@onready model` — used for the hit-flash scale. The raw glb instance `TurretSingleGLB` lives inside it. Facing is done later by rotating the ROOT in Task 4, never `Model`, so the model's baked-in pivot offset can't throw off rotations.)

- [ ] **Step 4: Measure AABB, set scale, fix the pivot offset**

```
mcp__godot-ai__editor_screenshot {"source": "viewport", "view_target": "/EnemyTurret/Model/TurretSingleGLB", "coverage": true}
```
Read `aabb_size` and `aabb_center` from the response metadata (image pixels may be stale, but AABB metadata is reliable). Target the model's largest AABB dimension to `0.9` units (comparable to the player's turret). Compute `scale = 0.9 / max(aabb_size.x, aabb_size.y, aabb_size.z)` and apply uniformly to `TurretSingleGLB`:
```
mcp__godot-ai__node_set_property {"path": "/EnemyTurret/Model/TurretSingleGLB", "property": "scale", "value": {"x": <scale>, "y": <scale>, "z": <scale>}}
```
Then cancel the pivot offset so the visible mesh centers on `Model`'s origin: set `TurretSingleGLB.position` to the negation of its (scaled) local center. Compute from the AABB: after scaling, the mesh's local offset from its own origin is `aabb_center` (scaled by `scale`); set `TurretSingleGLB.position = -aabb_center * scale` so the geometry sits at the `Model` origin. Apply:
```
mcp__godot-ai__node_set_property {"path": "/EnemyTurret/Model/TurretSingleGLB", "property": "position", "value": {"x": <px>, "y": <py>, "z": <pz>}}
```
(If `aabb_center` is reported in world space rather than the instance's local space, derive the local offset by subtracting the instance's current world position first. If after one correction pass the model still floats visibly off the `CollisionShape3D`'s box in a `source="game"` screenshot, do one more correction pass using the new AABB; stop and report as a concern after two passes.)

- [ ] **Step 5: Recolor to a hostile red and confirm orientation**

Inspect the glb's mesh node paths via `scene_get_hierarchy` (the mesh-bearing `MeshInstance3D` node(s) under `TurretSingleGLB`). For each `<mesh_path>`:
```
mcp__godot-ai__material_manage {"op": "apply_to_node", "params": {"node_path": "<mesh_path>", "type": "standard", "params": {"albedo_color": "#8e3030"}}}
```
Then confirm the model's barrel faces `-Z` (the same direction `Muzzle` points): run the game and check via `game_eval` that the muzzle is at `-Z` relative to the turret and the model isn't facing backwards. If the model's default forward is wrong, set `TurretSingleGLB.rotation_degrees.y` to the value (of 0/90/180/270) that points the barrel toward `-Z`, comparing `source="game"` screenshots.

- [ ] **Step 6: Attach the script and save**

```
mcp__godot-ai__script_attach {"path": "/EnemyTurret", "script_path": "res://robot_battler/enemy_turret.gd"}
mcp__godot-ai__scene_save {}
```

- [ ] **Step 7: Verify the entity (HP, take_damage, stays-dead, reset) — synchronously**

Place a temporary instance in the arena to test, then verify:
```
mcp__godot-ai__scene_open {"path": "res://robot_battler/arena.tscn"}
mcp__godot-ai__node_create {"name": "EnemyTurretTest", "parent_path": "", "scene_path": "res://robot_battler/enemy_turret.tscn"}
mcp__godot-ai__node_set_property {"path": "/Arena/EnemyTurretTest", "property": "position", "value": {"x": 4, "y": 0, "z": 0}}
mcp__godot-ai__scene_save {}
mcp__godot-ai__project_run {"mode": "main"}
mcp__godot-ai__editor_manage {"op": "game_eval", "params": {"code": "var t = get_node(\"/root/Arena/EnemyTurretTest\")\nvar in_group = t.is_in_group(\"enemy_turret\")\nvar hp0 = t.hp\nt.take_damage(30.0)\nvar hp1 = t.hp\nt.take_damage(1000.0)\nvar destroyed = t._destroyed\nvar vis = t.visible\nt.reset()\nreturn {\"in_group\": in_group, \"hp_start\": hp0, \"hp_after_30\": hp1, \"destroyed_after_overkill\": destroyed, \"visible_when_destroyed\": vis, \"hp_after_reset\": t.hp, \"visible_after_reset\": t.visible}"}}
```
Expected: `in_group=true`, `hp_start=60`, `hp_after_30=30`, `destroyed_after_overkill=true`, `visible_when_destroyed=false`, `hp_after_reset=60`, `visible_after_reset=true`.

- [ ] **Step 8: Remove the temporary instance**

```
mcp__godot-ai__project_manage {"op": "stop", "params": {}}
mcp__godot-ai__scene_open {"path": "res://robot_battler/arena.tscn"}
mcp__godot-ai__node_manage {"op": "delete", "params": {"path": "/Arena/EnemyTurretTest"}}
mcp__godot-ai__scene_save {}
```

- [ ] **Step 9: Commit**

```bash
git add robot_battler/enemy_turret.gd robot_battler/enemy_turret.tscn
git commit -m "Add enemy turret entity: turret_single model, HP, destroyed/reset (no AI yet)"
```

---

### Task 4: Enemy turret AI (track player + fire on cooldown)

**Files:**
- Modify: `res://robot_battler/enemy_turret.gd` (full-file rewrite — adds AI fields + `_physics_process`)

**Interfaces:**
- Consumes: group `"player"` (Task 2), `enemy_projectile.tscn` (Task 1), the `Muzzle` marker (Task 3).
- Produces: a turret that, each physics frame, faces and fires at the player when in range.

- [ ] **Step 1: Rewrite enemy_turret.gd with AI**

```
mcp__godot-ai__script_create
path: res://robot_battler/enemy_turret.gd
content:
```
```gdscript
extends StaticBody3D

@export var max_hp: float = 60.0
@export var fire_cooldown: float = 1.5
@export var range: float = 18.0
@export var projectile_speed: float = 12.0
@export var projectile_damage: float = 10.0
@export var projectile_max_distance: float = 22.0

const DAMAGE_NUMBER_SCENE := preload("res://robot_battler/damage_number.tscn")
const ENEMY_PROJECTILE_SCENE := preload("res://robot_battler/enemy_projectile.tscn")

@onready var model: Node3D = $Model
@onready var muzzle: Marker3D = $Muzzle
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var health_fill: MeshInstance3D = $HealthBar/Fill

var hp: float = 0.0
var _flash_tween: Tween = null
var _destroyed: bool = false
var _fire_cooldown_remaining: float = 0.0


func _ready() -> void:
	add_to_group("enemy_turret")
	hp = max_hp
	_update_health_bar()


func _physics_process(delta: float) -> void:
	if _destroyed:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var to_player := player.global_position - global_position
	to_player.y = 0.0
	if to_player.length() > range:
		return
	var look_target := Vector3(player.global_position.x, global_position.y, player.global_position.z)
	if look_target.distance_to(global_position) > 0.01:
		look_at(look_target, Vector3.UP)
	_fire_cooldown_remaining -= delta
	if _fire_cooldown_remaining <= 0.0:
		_fire_cooldown_remaining = fire_cooldown
		_fire_at(player.global_position)


func take_damage(amount: float) -> void:
	if _destroyed:
		return
	hp = max(0.0, hp - amount)
	_update_health_bar()
	_spawn_damage_number(amount)
	_flash()
	if hp <= 0.0:
		_on_depleted()


func reset() -> void:
	hp = max_hp
	_destroyed = false
	visible = true
	collision_shape.disabled = false
	_update_health_bar()


func _update_health_bar() -> void:
	var ratio: float = clampf(hp / max_hp, 0.0, 1.0) if max_hp > 0.0 else 0.0
	health_fill.scale.x = ratio


func _flash() -> void:
	if _flash_tween != null and _flash_tween.is_running():
		_flash_tween.kill()
	model.scale = Vector3(1.15, 1.15, 1.15)
	_flash_tween = create_tween()
	_flash_tween.tween_property(model, "scale", Vector3.ONE, 0.12)


func _spawn_damage_number(amount: float) -> void:
	var number := DAMAGE_NUMBER_SCENE.instantiate()
	get_tree().current_scene.add_child(number)
	number.global_position = global_position + Vector3(0, 2.6, 0)
	number.setup(amount)


func _on_depleted() -> void:
	_destroyed = true
	visible = false
	collision_shape.disabled = true


func _fire_at(target_pos: Vector3) -> void:
	var projectile := ENEMY_PROJECTILE_SCENE.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_transform = muzzle.global_transform
	var direction := target_pos - muzzle.global_position
	direction.y = 0.0
	if direction.length() > 0.01:
		direction = direction.normalized()
	else:
		direction = -muzzle.global_transform.basis.z
	projectile.setup(direction, projectile_speed, projectile_damage, projectile_max_distance, self)
```

- [ ] **Step 2: Place a temporary turret and verify it faces + fires when in range (synchronously)**

```
mcp__godot-ai__scene_open {"path": "res://robot_battler/arena.tscn"}
mcp__godot-ai__node_create {"name": "EnemyTurretTest", "parent_path": "", "scene_path": "res://robot_battler/enemy_turret.tscn"}
mcp__godot-ai__node_set_property {"path": "/Arena/EnemyTurretTest", "property": "position", "value": {"x": 5, "y": 0, "z": 0}}
mcp__godot-ai__scene_save {}
mcp__godot-ai__project_run {"mode": "main"}
mcp__godot-ai__editor_manage {"op": "game_eval", "params": {"code": "var t = get_node(\"/root/Arena/EnemyTurretTest\")\nt._fire_cooldown_remaining = 0.0\nvar before = get_tree().current_scene.get_child_count()\nt._physics_process(t.fire_cooldown + 0.01)\nvar after = get_tree().current_scene.get_child_count()\nvar p = get_node(\"/root/Arena/PlayerRobot\")\nvar fwd = -t.global_transform.basis.z\nfwd.y = 0.0\nfwd = fwd.normalized()\nvar to_p = p.global_position - t.global_position\nto_p.y = 0.0\nto_p = to_p.normalized()\nreturn {\"children_before\": before, \"children_after\": after, \"spawned_projectile\": after > before, \"forward_to_player_alignment\": fwd.dot(to_p)}"}}
```
Expected: `spawned_projectile = true` (calling `_physics_process` with delta ≥ `fire_cooldown` triggers `_fire_at`, adding an `EnemyProjectile` child to the scene), and `forward_to_player_alignment` close to `1.0` (the turret's forward vector points at the player — this verifies the `look_at` faced the right way *without* asserting a specific yaw sign, which this project has gotten backwards before). (If `spawned_projectile` is false, the most likely cause is the player not being in group `"player"` — re-check Task 2 — or `_fire_cooldown_remaining` not reaching ≤ 0; the explicit `= 0.0` set above rules out the latter.)

- [ ] **Step 3: Verify out-of-range suppression and destroyed-suppression (synchronously)**

```
mcp__godot-ai__editor_manage {"op": "game_eval", "params": {"code": "var t = get_node(\"/root/Arena/EnemyTurretTest\")\nvar p = get_node(\"/root/Arena/PlayerRobot\")\nvar saved = p.global_position\np.global_position = Vector3(50, 0, 50)\nt._fire_cooldown_remaining = 0.0\nvar before = get_tree().current_scene.get_child_count()\nt._physics_process(t.fire_cooldown + 0.01)\nvar after_far = get_tree().current_scene.get_child_count()\np.global_position = saved\nt.take_damage(1000.0)\nt._fire_cooldown_remaining = 0.0\nvar before2 = get_tree().current_scene.get_child_count()\nt._physics_process(t.fire_cooldown + 0.01)\nvar after_dead = get_tree().current_scene.get_child_count()\nreturn {\"fired_when_far\": after_far > before, \"fired_when_destroyed\": after_dead > before2}"}}
```
Expected: `fired_when_far = false` (player at 50 units > range 18 → no shot), `fired_when_destroyed = false` (destroyed turrets don't fire).

- [ ] **Step 4: Verify the spawned projectile is aimed at the player and would hit layer 2**

```
mcp__godot-ai__editor_manage {"op": "game_eval", "params": {"code": "var t = get_node(\"/root/Arena/EnemyTurretTest\")\nt.reset()\nvar p = get_node(\"/root/Arena/PlayerRobot\")\nt._fire_at(p.global_position)\nvar proj = null\nfor c in get_tree().current_scene.get_children():\n\tvar s = c.get_script()\n\tif s != null and s.resource_path == \"res://robot_battler/projectile.gd\":\n\t\tproj = c\n\t\tbreak\nvar mask = proj.collision_mask if proj != null else null\nreturn {\"found_enemy_projectile\": proj != null, \"projectile_mask\": mask, \"player_layer\": p.collision_layer}"}}
```
Expected: `found_enemy_projectile = true`, `projectile_mask = 2`, `player_layer = 2` — confirming the enemy projectile's mask matches the player's layer, so a live collision will damage the player. (The actual `take_damage`-on-hit path is already verified in Task 2 and `projectile.gd` is unchanged/reused, so mask+layer composition is the remaining load-bearing fact.)

- [ ] **Step 5: Remove the temporary instance and commit**

```
mcp__godot-ai__project_manage {"op": "stop", "params": {}}
mcp__godot-ai__scene_open {"path": "res://robot_battler/arena.tscn"}
mcp__godot-ai__node_manage {"op": "delete", "params": {"path": "/Arena/EnemyTurretTest"}}
mcp__godot-ai__scene_save {}
```
```bash
git add robot_battler/enemy_turret.gd robot_battler/arena.tscn
git commit -m "Add enemy turret AI: track player and fire on cooldown when in range"
```

---

### Task 5: Swap dummies for turrets in the arena + end-to-end verification

**Files:**
- Modify: `res://robot_battler/arena.tscn` (replace 4 `DummyTarget` instances with 4 `EnemyTurret` instances)

**Interfaces:** none new — assembles Tasks 1-4 into the playable arena.

- [ ] **Step 1: Delete the four dummy instances**

```
mcp__godot-ai__scene_open {"path": "res://robot_battler/arena.tscn"}
mcp__godot-ai__node_manage {"op": "delete", "params": {"path": "/Arena/DummyTarget1"}}
mcp__godot-ai__node_manage {"op": "delete", "params": {"path": "/Arena/DummyTarget2"}}
mcp__godot-ai__node_manage {"op": "delete", "params": {"path": "/Arena/DummyTarget3"}}
mcp__godot-ai__node_manage {"op": "delete", "params": {"path": "/Arena/DummyTarget4"}}
```
(If any path doesn't exist, skip it — note which in the report. `dummy_target.tscn`/`.gd` and `damage_number.tscn`/`.gd` stay on disk, untouched.)

- [ ] **Step 2: Add four enemy turrets at the same positions**

```
mcp__godot-ai__node_create {"name": "EnemyTurret1", "parent_path": "", "scene_path": "res://robot_battler/enemy_turret.tscn"}
mcp__godot-ai__node_set_property {"path": "/Arena/EnemyTurret1", "property": "position", "value": {"x": 0, "y": 0, "z": -1.5}}
mcp__godot-ai__node_create {"name": "EnemyTurret2", "parent_path": "", "scene_path": "res://robot_battler/enemy_turret.tscn"}
mcp__godot-ai__node_set_property {"path": "/Arena/EnemyTurret2", "property": "position", "value": {"x": 6, "y": 0, "z": -6}}
mcp__godot-ai__node_create {"name": "EnemyTurret3", "parent_path": "", "scene_path": "res://robot_battler/enemy_turret.tscn"}
mcp__godot-ai__node_set_property {"path": "/Arena/EnemyTurret3", "property": "position", "value": {"x": -8, "y": 0, "z": -10}}
mcp__godot-ai__node_create {"name": "EnemyTurret4", "parent_path": "", "scene_path": "res://robot_battler/enemy_turret.tscn"}
mcp__godot-ai__node_set_property {"path": "/Arena/EnemyTurret4", "property": "position", "value": {"x": 9, "y": 0, "z": 3}}
mcp__godot-ai__scene_save {}
```

- [ ] **Step 3: Verify the group composition and full damage loop end-to-end (synchronously)**

```
mcp__godot-ai__project_run {"mode": "main"}
mcp__godot-ai__editor_manage {"op": "game_eval", "params": {"code": "var turrets = get_tree().get_nodes_in_group(\"enemy_turret\")\nvar p = get_node(\"/root/Arena/PlayerRobot\")\nvar t1 = get_node(\"/root/Arena/EnemyTurret1\")\nvar hp0 = t1.hp\np.current_weapon = 0\np._update_weapon_display()\np.global_position = t1.global_position + Vector3(0, 0, 1.0)\np.rotation.y = 0.0\np.attack()\nreturn {\"turret_count\": turrets.size(), \"player_in_group\": p.is_in_group(\"player\"), \"turret1_hp_before\": hp0}"}}
```
Expected: `turret_count = 4`, `player_in_group = true`. (The `attack()` here spawns a melee hitbox whose `body_entered` needs a physics step to resolve — which is unreliable under the focus issue — so this step confirms composition only; the melee-damages-turret path was already verified in the original combat slice and the turret's `take_damage` is byte-identical to the dummy's. The next step does a direct `take_damage` call to confirm the loop closes.)

- [ ] **Step 4: Verify destroy → respawn-revives-turrets loop (synchronously)**

```
mcp__godot-ai__editor_manage {"op": "game_eval", "params": {"code": "var t1 = get_node(\"/root/Arena/EnemyTurret1\")\nvar t2 = get_node(\"/root/Arena/EnemyTurret2\")\nt1.take_damage(1000.0)\nt2.take_damage(1000.0)\nvar dead_before = [t1._destroyed, t2._destroyed]\nvar p = get_node(\"/root/Arena/PlayerRobot\")\np.hp = 1.0\np.take_damage(1.0)\nreturn {\"were_destroyed\": dead_before, \"after_respawn\": {\"t1_destroyed\": t1._destroyed, \"t1_hp\": t1.hp, \"t2_destroyed\": t2._destroyed, \"t2_hp\": t2.hp, \"player_hp\": p.hp, \"player_pos\": p.global_position}}"}}
```
Expected: `were_destroyed = [true, true]`, and `after_respawn` shows `t1_destroyed=false, t1_hp=60, t2_destroyed=false, t2_hp=60` (respawn revived both destroyed turrets), `player_hp=100`, `player_pos≈(0,0,0)`.

- [ ] **Step 5: Visual confirmation**

```
mcp__godot-ai__editor_screenshot {"source": "game"}
mcp__godot-ai__project_manage {"op": "stop", "params": {}}
```
Expected screenshot: four red enemy turrets (with health bars) around the arena, the player's HP bar top-left in the HUD.

- [ ] **Step 6: Commit**

```bash
git add robot_battler/arena.tscn
git commit -m "Replace dummy targets with four enemy turrets in the arena"
```

---

## Self-Review Notes

- **Spec coverage:** §3 collision layers → Tasks 1 (enemy proj mask=2), 3 (turret layer=4). §4 player HP/respawn → Task 2. §5 enemy turret entity + AI → Tasks 3 (entity) + 4 (AI). §6 enemy projectile → Task 1. §7 arena swap → Task 5. §8 numbers → embedded as `@export` defaults in Tasks 2/4. §9 testing → each task's verify steps + Task 5 end-to-end.
- **Type/name consistency:** `take_damage(amount: float)` is identical across `player_robot.gd`, `enemy_turret.gd`, and the existing `dummy_target.gd`/`projectile.gd` callers. `reset()` on `enemy_turret` is what `player_robot._respawn()` calls via the `"enemy_turret"` group. Group names `"player"` and `"enemy_turret"` match between producers and consumers. `enemy_turret.gd`'s `@onready` refs (`model`, `muzzle`, `collision_shape`, `health_fill`) match the scene node names created in Task 3 (`Model`, `Muzzle`, `CollisionShape3D`, `HealthBar/Fill`).
- **Verification under the focus constraint:** every runtime check is a synchronous `game_eval` (no `await`), since `await physics_frame`/`create_timer` hang in this session. Projectile-on-hit damage is verified by composition (enemy-proj `mask=2` + player `layer=2` + `projectile.gd`'s already-verified `body_entered`→`take_damage`) rather than a live collision, because live collisions need physics steps that don't advance reliably here.
- **No placeholders:** the turret_single model's scale/pivot-offset numbers can't be known in advance (empirical, same as the prior turret_double calibration), but Task 3 Step 4 gives the exact AABB-based formula and a bounded two-pass correction procedure rather than an open-ended "adjust until it looks right."
