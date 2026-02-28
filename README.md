# Moon RTS (Godot 4.x)

Base project skeleton for a top-down 2D RTS prototype on the moon.

## Requirements

- [Godot Engine 4.x](https://godotengine.org/download)

## Run the project

1. Open Godot 4.x.
2. Click **Import**.
3. Select this repository's `project.godot`.
4. Run the project (F5).

The main scene is `res://scenes/game/Main.tscn`.

## Architecture rules

- **Authoritative simulation** lives in `Sim` (autoload) and advances at fixed ticks (`20 TPS`).
- **Commands only** for gameplay actions: UI/agents enqueue commands through `CommandBus`; simulation drains and applies them.
- **No Node references in simulation state**: `Sim` stores integer entity IDs and dictionaries only.
- **Data-driven stats** are loaded from `.tres` resources under `res://data/` via `DataDB`.
- **Autoload singletons are limited to:**
  - `Game` → `res://scripts/core/game.gd`
  - `Sim` → `res://scripts/core/sim.gd`
  - `CommandBus` → `res://scripts/core/command_bus.gd`
  - `DataDB` → `res://scripts/core/data_db.gd`

## Smoke test harness

`Main` triggers a new match, seeds sample entities/resources, and renders:

- Title label (`Moon RTS`)
- Live resources from `Sim.resources_changed`
- Tick counter updated once per simulated second

This gives a working loop for iterative feature development.

## Controls

- **Left click**: Select one unit.
- **Left click + drag**: Box-select multiple units.
- **Right click**: Issue a move command for selected units.
