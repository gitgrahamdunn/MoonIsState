# MoonIsState (Godot 4.x)

Moon base / infrastructure tycoon prototype built in Godot 4.x with an authoritative fixed-tick simulation.

## Architecture Guardrails

All Codex prompts for this repository must include and follow the architecture rules in [`ARCHITECTURE_RULES.md`](ARCHITECTURE_RULES.md).

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
- On first run in dev, the project may auto-generate minimal sample defs under `res://data/` if missing. Commit them to keep CI stable.
- **Autoload singletons are limited to:**
  - `Game` → `res://scripts/core/game.gd`
  - `Sim` → `res://scripts/core/sim.gd`
  - `CommandBus` → `res://scripts/core/command_bus.gd`
  - `DataDB` → `res://scripts/core/data_db.gd`

## Smoke test harness

`Main` triggers a new match, seeds sample entities/resources, and renders:

- Title label (`MoonIsState`)
- Live resources from `Sim.resources_changed`
- Tick counter updated once per simulated second

This gives a working loop for iterative feature development.

## Controls

- **Left click**: Select one unit.
- **Right click**: Issue a move command for selected unit(s).
- **Build Launchpad flow**:
  1. Select a clanker.
  2. Click **Build Launchpad** in the Launch Console.
  3. Left-click in the world to place it.
  4. Wait for construction to complete.
  5. Use Launch Console buttons once the launchpad is complete.
