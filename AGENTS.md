# Rizz-the-brainrot - instructions for AI coding agents

This repository is a **Roblox project synchronised with Roblox Studio** by Roblox Git Sync.
Everything under `src/` is the live content of the place: scripts, models, UI, VFX, animations, sounds and settings.
Edit the files, commit, then run `roblox-sync sync` - the changes appear in Studio with no copy/paste.

**Read first:** [docs/rbxsync/AI_WORKFLOW.md](docs/rbxsync/AI_WORKFLOW.md) (how to work),
[docs/rbxsync/SYNC_FORMAT.md](docs/rbxsync/SYNC_FORMAT.md) (file format reference),
[docs/rbxsync/GAME_CONTENT.md](docs/rbxsync/GAME_CONTENT.md) (recipes: VFX, animations, tools, UI, tweens).

## Rules that must never be broken

1. **Never invent asset ids** (`rbxassetid://...`) for animations, meshes, textures, sounds or images. If an asset has to be
   created in Roblox, write `{"$pendingAsset": "what is needed"}` instead of the id. A human completes it in Studio and the real id flows back.
2. Only use property names and enum item names that exist in Roblox. Unknown ones are reported by the sync and not applied.
3. Do not rename or move files that you do not need to change; do not reformat metadata files you are not editing.
4. Scripts are plain `.luau` files: `Name.server.luau` (Script), `Name.client.luau` (LocalScript), `Name.luau` (ModuleScript).
5. Keep `.rbxm` files untouched (binary models). Edit the readable `.meta.json` next to them instead.
6. After your changes: `git add -A && git commit`, then `roblox-sync sync` and check the result. `Synced` is the only fully good result;
   `Partially Synced` lists what still needs a human; `conflict` means someone changed the same thing in Studio.
