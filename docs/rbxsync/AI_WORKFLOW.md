# AI workflow guide (Claude Code, Codex, Cursor, ...)

You are working on a **live Roblox project** through its repository. The files under `src/` are the project; a companion service
and a Studio plugin keep Roblox Studio identical to them, in both directions.

## The loop

```
1. read          src/**  (and docs/rbxsync/SYNC_FORMAT.md when unsure)
2. edit/create   .luau scripts, *.instance.json, init.meta.json ...
3. commit        git add -A && git commit -m "..."
4. sync          roblox-sync sync        # applies to Studio, waits for Studio's acknowledgement
5. read result   exit code 0 = Synced, 2 = Partially Synced, 3 = conflict, 4 = Studio not connected, 1 = error
```

Always run step 4 at the end and **report the result honestly**. `Synced` is the only fully good result. `Partially Synced`
means something was preserved but needs a human or a fix (the command prints exactly what). Never describe a partial result as done.

`roblox-sync status` shows the same information without syncing; `roblox-sync diff` lists pending changes (`+` added, `-` removed,
`~` modified); `roblox-sync watch` streams the log. `roblox-sync pull` / `push` wrap `git pull` / `git push` plus the Studio sync.

## Where things live

| You want to... | Put it here |
|---|---|
| Server script / system | `src/ServerScriptService/<Name>.server.luau` (shared logic: ModuleScript `<Name>.luau`) |
| Client script | `src/StarterPlayer/StarterPlayerScripts/<Name>.client.luau` or inside a UI/Tool |
| Shared module / config / remotes | `src/ReplicatedStorage/...` (remotes are `*.instance.json` with `className: "RemoteEvent"`) |
| Server-only assets/templates | `src/ServerStorage/...` |
| UI | `src/StarterGui/<ScreenGui>/...` (see below) |
| Tool / weapon | `src/StarterPack/<Tool>/` (directory with `init.meta.json` `{"className":"Tool"}`, `Handle.instance.json`, scripts) |
| Map, models, spawns | `src/Workspace/...` |
| VFX templates | `src/ReplicatedStorage/VFX/<Effect>/...` (clone them at runtime) |
| Lighting / sky / post effects | `src/Lighting/` |
| Sounds | `src/SoundService/` or next to what plays them |

Full format: `docs/rbxsync/SYNC_FORMAT.md`. Worked end-to-end example (sword with animation, VFX, sound, cooldown UI, damage system):
`docs/rbxsync/GAME_CONTENT.md`.

## How to...

**Add a script.** Create `src/ServerScriptService/Shop.server.luau`. Nothing else is needed. Rename the extension to make it a
`LocalScript` (`.client.luau`) or `ModuleScript` (`.luau`). Properties such as `Disabled` go into `Shop.meta.json` -> `"properties"`.

**Change a script.** Edit the file. Studio updates the script source in place (open editors too).

**Add a model.** Create a directory with an `init.meta.json` (`{"className": "Model"}`) and one `*.instance.json` per part:

```
src/Workspace/Crate/init.meta.json                {"className":"Model","properties":{"PrimaryPart":{"$ref":"Workspace/Crate/Box"}}}
src/Workspace/Crate/Box.instance.json             {"className":"Part","properties":{"Size":[4,4,4],"Anchored":true,"Material":"Wood"}}
```

Models with Unions/complex geometry are `.rbxm` files created in Studio: do not edit them, edit their `.meta.json`.

**Change UI.** Each GuiObject is a file; layouts and constraints are siblings:

```
src/StarterGui/ShopUI/init.meta.json              {"className":"ScreenGui","properties":{"ResetOnSpawn":false}}
src/StarterGui/ShopUI/BuyButton.instance.json     {"className":"TextButton","properties":{"Text":"Buy","Size":[[0,140],[0,44]],"BackgroundColor3":"#2E7D32"}}
src/StarterGui/ShopUI/List.instance.json          {"className":"UIListLayout","properties":{"Padding":[0,6],"SortOrder":"LayoutOrder"}}
src/StarterGui/ShopUI/Shop.client.luau            -- LocalScript for the UI
```

**Add VFX.** `ParticleEmitter`, `Beam`, `Trail`, `Attachment`, lights, `Highlight`, `Fire`, `Smoke`, `Sparkles`, `Explosion` are ordinary
`*.instance.json` files. Put reusable effects under `ReplicatedStorage/VFX/<Name>/` and `:Clone()` them from code. Curves
(`NumberSequence`, `ColorSequence`) and ranges are plain arrays (see the format reference). Textures/sounds are assets: reuse an existing
`rbxassetid://` that appears elsewhere in the repository or write `{"$pendingAsset": "description"}`.

**Add animations.** An `Animation` instance is a file with an `AnimationId` property. You cannot author or publish animation clips: write the
`Animation` with `{"$pendingAsset": "..."}` and the code that loads/plays it (`Animator:LoadAnimation`, guard `AnimationId ~= ""`),
then tell the user which clips must be created in the Animation Editor. Tweens, camera effects and UI motion are plain code and fully yours.

**Use references.** Link instances with `{"$ref": "Service/Path/To/Instance"}` (key path). Do not use `rbxassetid` for instances.

**Remove something.** Delete its file or directory. Deleting a script file deletes the script in Studio (a backup is created automatically
and the change is a single Undo step in Studio).

## Rules (do not break these)

1. **Never invent asset ids.** Only reuse ids that already exist in the repository or that the user gave you. Otherwise `$pendingAsset`.
2. Use only real property names, class names and enum item names. Wrong ones are not applied and show up in the status.
3. Do not reformat, rename or move metadata/files you are not changing (every rewritten node is a potential merge conflict).
4. Keep JSON valid at the moment you save; a broken file is never interpreted as a deletion (the instance stays in Studio and the status says why).
5. Do not touch `.rbxm` files or `.rbxsync/`.
6. `Name~2`-style files are duplicate-named siblings; keep their `"name"` field.
7. Services are directories; do not create `src/<something>` that is not a configured service (`rbxsync.json` -> `services`).
8. One task = one commit, then `roblox-sync sync`.

## Conflicts

`Conflict` means the same Instance (or the same lines of the same script) changed in Studio and in the repository. Nothing is overwritten.
Tell the user; they choose in the plugin (CHANGES tab: Keep Roblox / Keep GitHub / Show Diff / Merge). From the CLI:
`roblox-sync resolve <path> <studio|disk|merge>`. Non-overlapping edits (different properties, different script hunks) merge automatically.
A real **git** merge conflict (conflict markers in files after `git pull`) must be resolved in the files, then commit and sync.

## What can and cannot be created from files

Everything representable as Instances, properties, attributes, tags and script source: scripts, modules, remotes, folders, parts and models,
UI, constraints, VFX, lights, sounds (with an asset id), tools, animations *as references*, configuration values, lighting/sky/post effects,
teams, TextChatService content, localization tables.

Not creatable from files (needs Roblox/Studio, so use `$pendingAsset` and say so): animation clips, meshes, textures/images, audio files,
terrain, Unions. See `ARCHITECTURE.md` section "Asset support".
