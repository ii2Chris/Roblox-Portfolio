# Collapse (CCRP)

**Role:** Full-Stack Scripter  
**Period:** March 2026 — Present  
**Status:** Active 🟩

Collapse was my first professional Roblox project and my introduction to Lua/Luau scripting. Coming in with a background in basic Python, I had to quickly learn not just the language but how a large, interconnected Roblox codebase is structured — client-server architecture, remote communication, replication, and working within established systems rather than building from scratch.

## On Using AI
I used AI (Claude) extensively throughout this project as a learning accelerator. This meant using it to understand unfamiliar patterns, debug errors I didn't yet have the instincts to catch, and get explanations for why things work the way they do. Every piece of code in this portfolio I can read, explain, and reason about independently. AI helped me get there faster, but the understanding is mine.

## Contributions

**Admin System**  
Built a Cmdr-based admin panel from the ground up, layered on top of a pre-existing internal admin module. This included a custom terminal UI with autocomplete, a server-side permission hook system, custom Cmdr type definitions for game-specific arguments, and a growing library of admin commands covering player management, game state, and visual effects.

**VFX Scripting**  
Rewrote and optimized several move VFX handlers. Key work includes refactoring a rush move's VFX from a per-frame CFrame update loop to a WeldConstraint-based system, and adapting a third-party lightning VFX module (Zeus) to work within the game's asset and replication architecture. This is ongoing, as I'm constantly learning how to do new moves, handle different mesh types, and more.

**UI Scripting**  
Built a multi-type private message notification system (`messagePMs`) for the admin panel, supporting plain, shaky, and full anxiety-effect message types. The anxiety effect includes camera shake, a red vignette overlay, heartbeat and ear-ringing audio.

**Custom Moves**  
Implemented a server-side tool object for a mouse-aimed lightning ability (Zeus), following the game's established OOP tool architecture. This is ongoing, as I'm learning the difference between serversided, clientsided, and what exactly does what, why, etc.

**General**  
Ongoing work across multiple GUI reworks, move remakes, and command updates to make systems more LT-friendly.

## What I Learned
- Client-server architecture and how Roblox replicates data between them
- Remote communication patterns (RemoteEvent, RemoteFunction, CompleteBridge)
- Working within and extending large pre-existing codebases
- VFX scripting — particle emitters, welds, mesh tweening, timing sequences
- OOP patterns in Lua using metatables
- Admin system design and permission management

If you wish to contact me, please dm copy2 on discord.
