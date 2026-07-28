# Melee Speedboat Enemy Design

## Goal

Add an orange melee enemy based on `boat-speed-c.glb`. Two instances replace
two turrets in the Open Water stage. They chase the player and deal damage by
ramming.

## Enemy Architecture

The melee speedboat is a standalone `CharacterBody3D` scene with its own
script. It belongs to a new shared `enemy` group alongside ranged turrets.
Stage completion checks this group so a mixed encounter ends only after every
enemy type has been destroyed.

The new enemy exposes tunable movement speed, turn speed, maximum health,
ram damage, and ram cooldown values. Difficulty scaling applies to its ram
damage through `GameSettings`, following the existing turret damage pattern.

## Visuals and Collision

The scene instances
`assets/kenney_watercraft-pack/Models/GLB format/boat-speed-c.glb`. Its main
paint surfaces receive orange material overrides while dark trim and other
readable details remain distinct where the imported mesh hierarchy permits.

A body collision shape approximates the speedboat hull. A world-space health
bar follows the existing enemy turret presentation. Taking damage produces
the existing floating damage number and a brief scale flash.

## Chase and Ram Behavior

During physics processing, a living speedboat finds the player, flattens the
direction to the XZ plane, turns toward the player, and moves forward using
`move_and_slide()`. It does not use navigation or obstacle avoidance; Open
Water is unobstructed and does not justify a navigation subsystem.

When a slide collision contains the player, the speedboat calls
`player.take_damage(ram_damage)`. A ram cooldown prevents repeated damage on
every physics frame while the boats remain in contact. The boat continues
chasing during the cooldown.

Destroyed boats stop processing, hide, and disable collision. Their
`take_damage(amount)`, `is_destroyed()`, and destruction notification behavior
match the contract used by existing combat code.

## Stage Integration

`EnemyTurret` and the new melee speedboat both join the `enemy` group.
`stage.gd` replaces turret-specific victory counting with a generic enemy
destruction callback and checks every node in the `enemy` group.

The Open Water stage keeps `EnemyTurret1`, `EnemyTurret2`, `EnemyTurret3`, and
`EnemyTurret6`. `EnemyTurret4` and `EnemyTurret5`, currently at
`(-8, 0, 8)` and `(8, 0, 8)`, are replaced by melee speedboats at the same
positions. The encounter therefore remains six enemies total: four ranged
turrets and two melee boats.

## Testing and Verification

Focused headless tests cover:

- A speedboat turns and produces velocity toward the player.
- Contact applies the configured ram damage once and respects the cooldown.
- Mixed turret/speedboat encounters do not trigger victory until all enemies
  report destroyed.
- The melee enemy scene loads with the speedboat model, orange material
  overrides, collision, and health UI.

The project is also parsed headlessly after implementation, and Open Water is
run for a visual check of placement, coloring, chase behavior, damage, and
victory completion.
