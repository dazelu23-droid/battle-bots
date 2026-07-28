# Melee Speedboat Enemy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add two orange, player-chasing, contact-damage speedboats to Open Water in place of two ranged turrets.

**Architecture:** A focused `CharacterBody3D` enemy owns chase, ram, health, and destruction behavior. Turrets and speedboats share an `enemy` group and generic stage callback so mixed encounters complete correctly.

**Tech Stack:** Godot 4.7, GDScript, `.tscn` scenes, headless Godot regression tests.

## Global Constraints

- Use `boat-speed-c.glb` with orange paint and preserved dark details.
- Keep Open Water at six enemies: four turrets and two melee speedboats.
- Use direct XZ chasing without a navigation subsystem.
- Apply difficulty scaling to ram damage.

---

### Task 1: Generic Enemy Completion Contract

**Files:**
- Modify: `robot_battler/enemy_turret.gd`
- Modify: `robot_battler/stage.gd`
- Create: `tests/mixed_enemy_completion_test.gd`
- Create: `tests/mixed_enemy_completion_test.tscn`

**Interfaces:**
- Produces: group `"enemy"` on every combat enemy.
- Produces: `stage.on_enemy_destroyed() -> void`.
- Consumes: `enemy.is_destroyed() -> bool`.

- [ ] **Step 1: Write the failing mixed-enemy completion test**

Create lightweight test enemies in the test script, add them to `"enemy"`,
call `on_enemy_destroyed()`, and assert `_cleared` stays false while one enemy
reports alive and becomes true after both report destroyed.

- [ ] **Step 2: Run the test and verify RED**

Run:
`Godot_v4.7.1-stable_win64_console.exe --headless --path . res://tests/mixed_enemy_completion_test.tscn`

Expected: FAIL because `on_enemy_destroyed()` and the generic group contract
do not exist.

- [ ] **Step 3: Implement the generic contract**

Add turrets to both `"enemy_turret"` and `"enemy"` for compatibility. Rename
the stage callback to `on_enemy_destroyed()`, iterate `"enemy"`, and update
the turret destruction notification to call it.

- [ ] **Step 4: Run the test and existing mouse regression**

Expected: both test scenes exit 0.

- [ ] **Step 5: Commit**

```powershell
git add robot_battler/enemy_turret.gd robot_battler/stage.gd tests/mixed_enemy_completion_test.*
git commit -m "Generalize stage enemy completion"
```

### Task 2: Melee Speedboat Logic

**Files:**
- Create: `robot_battler/melee_enemy.gd`
- Create: `tests/melee_enemy_behavior_test.gd`
- Create: `tests/melee_enemy_behavior_test.tscn`
- Modify: `robot_battler/game_settings.gd`

**Interfaces:**
- Produces: `take_damage(amount: float) -> void`.
- Produces: `is_destroyed() -> bool`.
- Produces: `_chase_direction(target_position: Vector3) -> Vector3`.
- Produces: `_try_ram(player: Node) -> bool`.
- Consumes: `GameSettings.melee_enemy_damage_scale() -> float`.
- Consumes: `player.take_damage(amount: float) -> void`.

- [ ] **Step 1: Write failing chase and ram tests**

Load `melee_enemy.gd`, instantiate it, verify a target to the right produces
normalized `Vector3.RIGHT`, and use a real test player node to verify two
immediate `_try_ram()` calls apply damage only once.

- [ ] **Step 2: Run the test and verify RED**

Expected: FAIL because the melee enemy script and settings scale do not exist.

- [ ] **Step 3: Implement minimal chase, cooldown, health, and destruction**

Create a `CharacterBody3D` script with exported `move_speed`, `turn_speed`,
`max_hp`, `ram_damage`, and `ram_cooldown`; generic enemy group membership;
XZ pursuit; collision-based ram attempts; difficulty-scaled damage; health
updates; damage numbers; hit flash; and `on_enemy_destroyed()` notification.

- [ ] **Step 4: Run behavior and completion tests**

Expected: both exit 0.

- [ ] **Step 5: Commit**

```powershell
git add robot_battler/melee_enemy.gd robot_battler/game_settings.gd tests/melee_enemy_behavior_test.*
git commit -m "Add melee speedboat behavior"
```

### Task 3: Orange Speedboat Scene

**Files:**
- Create: `robot_battler/melee_enemy.tscn`
- Create: `tests/melee_enemy_scene_test.gd`
- Create: `tests/melee_enemy_scene_test.tscn`

**Interfaces:**
- Consumes: `robot_battler/melee_enemy.gd`.
- Consumes: `assets/kenney_watercraft-pack/Models/GLB format/boat-speed-c.glb`.
- Produces: instantiable `res://robot_battler/melee_enemy.tscn`.

- [ ] **Step 1: Write the failing scene contract test**

Load and instantiate the wished-for scene. Assert the root is
`CharacterBody3D`, the model subtree exists, at least one visible mesh has an
orange material override, and collision plus health-bar nodes exist.

- [ ] **Step 2: Run the test and verify RED**

Expected: FAIL because `melee_enemy.tscn` does not exist.

- [ ] **Step 3: Build the scene**

Instance `boat-speed-c.glb` under `Model`, add orange
`StandardMaterial3D` overrides to paint meshes while retaining dark trim,
add a hull `BoxShape3D`, and add background/fill health-bar quads matching
the turret health presentation.

- [ ] **Step 4: Run all focused tests**

Expected: scene, behavior, completion, and mouse regression tests exit 0.

- [ ] **Step 5: Commit**

```powershell
git add robot_battler/melee_enemy.tscn tests/melee_enemy_scene_test.*
git commit -m "Create orange melee speedboat scene"
```

### Task 4: Open Water Integration and Final Verification

**Files:**
- Modify: `robot_battler/open_water.tscn`

**Interfaces:**
- Consumes: `res://robot_battler/melee_enemy.tscn`.

- [ ] **Step 1: Write the failing placement assertions**

Extend the scene contract test to load Open Water and assert exactly four
turret instances and two melee enemy instances, with melee enemies at
`(-8, 0, 8)` and `(8, 0, 8)`.

- [ ] **Step 2: Run the test and verify RED**

Expected: FAIL because Open Water still has six turrets.

- [ ] **Step 3: Replace turret instances**

Add the melee enemy external resource, replace `EnemyTurret4` and
`EnemyTurret5` with `MeleeEnemy1` and `MeleeEnemy2`, preserving transforms.

- [ ] **Step 4: Verify the complete project**

Run every `tests/*.tscn` headlessly, parse the editor project with
`--headless --editor --quit`, run `git diff --check`, and visually inspect
Open Water for orange materials, pursuit, ram damage, and mixed-enemy victory.

- [ ] **Step 5: Commit**

```powershell
git add robot_battler/open_water.tscn tests/melee_enemy_scene_test.gd
git commit -m "Add melee speedboats to open water"
```
