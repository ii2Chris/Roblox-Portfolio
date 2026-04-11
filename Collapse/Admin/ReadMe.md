# Admin Command System
Polished w/ AI.

Built a custom admin panel for Collapse (CCRP) using [Cmdr](https://github.com/evaera/Cmdr), a Roblox commander framework.

## Overview

The system is structured as a thin Cmdr interface layer on top of a pre-existing internal admin module. Command files are lightweight wrappers — all core logic lives in the admin module and is accessed through a shared config. This keeps commands clean and easy to add without touching core systems.

## Features

- **Custom UI** — Reskinned Cmdr interface with a custom autocomplete and window layout
- **Permission system** — Server-side `BeforeRun` hook validates each command against per-player permission tables before execution. Unauthorized players are rejected with a descriptive error.
- **Admin gating** — Client-side init checks admin status via a `RemoteFunction` before loading Cmdr at all, preventing the UI from appearing for non-admins
- **Custom types** — `AdminTypes` extends Cmdr's type system with game-specific argument types
- **Command coverage** — Commands cover player management, game state, visual effects, and more

## Architecture
AdminCMDR/
├── Commands/       -- Thin Cmdr wrappers, one file per command
├── Types/          -- Custom argument type definitions
├── Cmdr/           -- Cmdr framework + custom UI
└── Config.lua      -- Connects commands to the internal admin module

## Permission Model

Permissions are defined per-player in `AdminSettings`. Each player has a list of allowed command names, or `"all"` for full access. The `BeforeRun` hook enforces this server-side on every command invocation.

```lua
-- Example AdminSettings entry
["playerName"] = {"kick", "ban", "eyecolor"} -- specific commands only
["adminName"]  = {"all"}                      -- full access
```

## Notes

Command files follow a consistent pattern — server logic is guarded by `RunService:IsServer()` and routed through the admin module. Client and server behavior live in the same file for simplicity.
