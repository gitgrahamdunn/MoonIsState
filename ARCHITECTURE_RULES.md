# Moon RTS - Architecture Rules (Codex Guardrails)

- Godot 4.x, 2D top-down only.
- Simulation is authoritative and runs in fixed ticks in Sim (autoload). No gameplay logic in view nodes.
- All player/AI actions go through CommandBus as Commands. UI submits commands; it does not mutate state directly.
- Sim uses integer entity IDs; sim state must not store Node references.
- Unit/building stats are data-driven Resources under res://data/. No hardcoded hp/cost/speed in scripts.
- Allowed autoloads only: Game, Sim, CommandBus, DataDB. Do not add more singletons/autoloads.
- IMPORTANT: Autoload scripts must NOT declare `class_name` (prevents name collisions).
- IMPORTANT: In Sim/core code, no untyped Variant inference from Dictionaries:
  - explicitly type locals, function returns, and casts (Vector2/int/float/etc.)
  - avoid arithmetic directly on Dictionary indexing without `as Type`.
- Use signals only for notifications (spawn/die/resources_changed), not for commands.
- Keep scripts under res://scripts/, scenes under res://scenes/. Follow naming conventions.
If any change would violate these rules, stop and refactor to comply instead.

## Why these exist

These guardrails prevent design drift as the codebase grows, avoid autoload and `class_name` naming collisions in Godot globals, enforce typed GDScript in simulation/core paths to reduce runtime type bugs, and keep Sim authoritative so gameplay remains deterministic and testable.
