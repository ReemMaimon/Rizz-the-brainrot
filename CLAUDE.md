# Rizz-the-brainrot

This is a Roblox project kept in sync with Roblox Studio (Roblox Git Sync). See `AGENTS.md` for the rules and
`docs/rbxsync/AI_WORKFLOW.md` for the workflow. Short version:

- Edit files under `src/` (scripts are `.luau`, instances are `.instance.json` / `init.meta.json`).
- Never invent `rbxassetid://` ids; use `{"$pendingAsset": "description"}` and tell the user what has to be created in Studio.
- Finish every task with `git commit` then `roblox-sync sync` and report the sync status (`Synced` / `Partially Synced` / conflicts).
