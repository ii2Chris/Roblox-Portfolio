# Tools

Custom server-side tool objects built for Collapse (CCRP).

## Architecture
Each tool follows an OOP pattern using metatables. When a tool is given to a player, the game's `ToolHelper` module instantiates a new tool object via `NewTool`, passing in the player, character, humanoid, state object, and a dedicated `CommunicationRemote` for client-server communication.
Tool Object Lifecycle: NewTool() → SetUp() → [Equipped/Activated/Deactivated] → Drop()

## Key Components
**CommunicationRemote** — A `RemoteEvent`/`RemoteFunction` pair dedicated to each tool instance. Used for bidirectional communication between server and client. Identified by a GUID so multiple tools don't cross-wire.
**CompleteBridge** — A `RemoteFunction` child of `CommunicationRemote`. The server invokes this to ask the client for real-time data, such as mouse position or target. This is how mouse-aimed abilities get their aim data server-side without trusting the client to fire it unsolicited.
**StateObject** — A per-character state manager that tracks blocking, stunning, ragdoll, cooldowns, global cooldown, and more. All tools check state before activating.
**InternalCooldown** — Handles server-side cooldown tracking. Synced to the client via `GlobalTime` so the UI displays an accurate countdown regardless of latency.

## Activation Flow
Client clicks → Tool.Activated fires → Server Activated() → State checks (blocking, stunned, cooldown, etc.) → CompleteBridge:InvokeClient() → Client returns mouse data → Validate input (range, type checks) → Apply effects / fire VFX remote to client → Set cooldown, GlobalCooldown

## Security
- Every `OnServerEvent` connection verifies the firing player matches the tool owner — mismatches result in a kick
- Mouse target data returned from the client is fully validated server-side (type check, range check, instance check) before any effect is applied
- Cooldowns are enforced server-side regardless of client state

## Example
See `Zeus.lua` for a complete implementation — a mouse-aimed lightning ability that validates target position, enforces a 500 stud range limit, and fires VFX to the client via `CommunicationRemote`.

