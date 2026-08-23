# Copilot Instructions for Golf RPG (Godot 4.x)

These instructions define how AI coding assistants should work in this Godot project. Make reliable, minimal changes that preserve the current prototype and its planned expansion into a nine-hole golf RPG.

## Mission

Prioritize:

1. The smallest correct change.
2. Existing scenes, scripts, and data over new systems.
3. Localized edits with no unrelated refactoring.
4. Simple, maintainable Godot 4.x GDScript.
5. The core experience: hit the ball, walk and explore, talk to NPCs, answer a question, and see the course change.

## Before Every Task

Read only the documentation that directly informs the task:

1. `info/Overview.md` for game purpose, gameplay loop, and scope.
2. `info/protytpe_plan.md` for the active one-hole prototype requirements.
3. `info/Plan.md` for broader staged work when the task concerns future systems.
4. `info/shot.md` only for shot-mechanic work.

Then identify the smallest relevant scene and its attached script. Do not scan the whole project.

## Project Map

```text
GolfRPG/
├── project.godot                 # Godot 4.4 configuration; Hole1 is the main scene
├── Scenes/
│   ├── Hole1.tscn                # Current playable hole; world composition and wiring
│   ├── Player.tscn               # Player visual, animations, and follow camera
│   └── ball.tscn                 # Clickable golf ball and collision shape
├── scripts/
│   ├── hole_1.gd                 # Hole setup, ball/player connection, camera limits
│   ├── player.gd                 # Walking, ball approach, aiming, and shot input
│   └── ball.gd                   # Ball launch, rolling, terrain behavior, and aim preview
├── data/
│   └── questions.json            # Survey question data
├── info/                         # Project design and prototype documentation
└── assets/                       # Read-only art and imported resources
```

## Context Management

Before opening a file, ask whether it directly helps solve the current task. If not, do not open it.

For gameplay work, use this order:

1. Relevant `info/` document.
2. Owning `.tscn` scene.
3. Its attached `.gd` script.
4. One directly connected scene or script only when needed.

Never inspect `.godot/`, `.git/`, or import artifacts unless a concrete editor or import issue requires it. Do not inspect files under `assets/` or other binary media without first asking the user; treat assets as read-only.

## Scene and Script Rules

Scenes are sensitive. Modify a `.tscn` only when a required node, exported property, resource reference, or signal connection must change.

Do not rename nodes, reorder nodes, delete existing connections, reset exported values, or rewrite a scene. Prefer the owning script for gameplay behavior.

Current ownership:

- `Hole1.tscn` and `hole_1.gd` coordinate the playable hole.
- `Player.tscn` and `player.gd` own player movement and shot input states.
- `ball.tscn` and `ball.gd` own ball input, motion, and terrain-aware behavior.
- `questions.json` holds survey content; do not hard-code question banks in scripts.

## Godot Conventions

- Use Godot 4.x and typed GDScript where practical.
- Use `snake_case` for files, variables, and functions; `PascalCase` for classes; `UPPER_SNAKE_CASE` for constants.
- Prefer small functions, early returns, clear names, and signals for state changes.
- Use `preload()` for static resources and `load()` for dynamic resources.
- Handle missing nodes and resources visibly; do not silently ignore errors.
- Keep UI and future dialogue/survey code above gameplay objects rather than directly controlling low-level behavior.

## Portability

The game targets web export and may run on Linux. All `res://` paths in scripts, scenes, and configuration must match the exact casing on disk. Treat a case mismatch as a blocker before finishing.

Do not alter `project.godot`, project settings, renderer configuration, or export configuration unless the task explicitly requires it.

## Prototype Scope

The active milestone is deliberately small:

- One short hole with simple walking and aim/power golf shots.
- One NPC encounter and one question loaded from `data/questions.json`.
- Local answer state and one visible course transformation.
- A basic completion state.

Do not introduce nine-hole progression, save/load, online data collection, complex golf physics, large dialogue systems, or broad transformation frameworks unless requested.

## Workflow

1. Locate an existing implementation before creating code.
2. Make the smallest edit that satisfies the request.
3. Check parser errors, missing references, signal connections, and resource-path casing.
4. Update an `info/` document only when a new mechanic, API, or architectural pattern is added.
5. Stop after the requested work is complete.

If a change needs more than three files, explain the files, why each is needed, and the implementation approach before editing.

## Guardrails

Unless explicitly requested, never rename or move files/folders, restructure working systems, change save formats, regenerate imports, change scene hierarchy, modify assets, or refactor unrelated code.

Godot should not be launched for automated testing in this environment. Instead, validate modified scripts and scene references through editor diagnostics and targeted static checks when available.