# Sync format reference

Everything the plugin synchronises is stored as **plain text files** under `src/` (the folder is configurable with `srcDir`
in `rbxsync.json`). Scripts are `.luau`, everything else is JSON. The only binary files are `.rbxm` models (Unions etc.) and
each of them has a readable JSON sidecar.

```
my-game/
├── rbxsync.json                      project configuration (services, binary rules, ignore rules)
├── src/
│   ├── Workspace/                    one directory per synced service
│   ├── ServerScriptService/
│   ├── ServerStorage/
│   ├── ReplicatedStorage/
│   ├── StarterGui/
│   ├── StarterPlayer/
│   ├── StarterPack/
│   └── ...                           ReplicatedFirst, Lighting, SoundService, Teams, TextChatService, ...
├── AGENTS.md  CLAUDE.md  docs/rbxsync/   instructions for AI agents
└── .rbxsync/                         local state and backups (git-ignored, never edit)
```

The **directory tree is the Instance hierarchy**: a directory (or file) inside `Workspace/Map/` is a child of `Workspace.Map`.

## 1. How one Instance is stored

| Instance | Files |
|---|---|
| `Script` without children | `Name.server.luau` (+ optional `Name.meta.json`) |
| `LocalScript` without children | `Name.client.luau` (+ optional `Name.meta.json`) |
| `ModuleScript` without children | `Name.luau` (+ optional `Name.meta.json`) |
| Script **with** children | directory `Name/` with `init.server.luau` / `init.client.luau` / `init.luau`, children beside it, optional `init.meta.json` |
| Any other Instance without children | `Name.instance.json` |
| Any other Instance **with** children | directory `Name/` with `init.meta.json`, children beside it |
| `Folder` | a plain directory (`init.meta.json` only needed for properties/attributes/tags) |
| Opaque binary instance (Union ...) | `Name.rbxm` + `Name.meta.json` |
| Service (`Workspace`, ...) | the directory `src/<Service>/`; its own properties live in `src/<Service>/init.meta.json` |

Rules of thumb for agents:

* **Creating something?** Add a file. `Sword.instance.json` creates one instance, a new directory creates a `Folder`.
* **Giving something children?** Create a directory with the same name (the leaf file may stay; both forms are accepted).
* `.lua` is accepted anywhere `.luau` is; existing `.lua` files keep their extension.
* Dotfiles, `README.md` and unknown extensions inside `src/` are ignored.
* `init.meta.json` for **Roblox-owned containers**: `StarterPlayer/StarterPlayerScripts` and `StarterPlayer/StarterCharacterScripts` are
  recognised automatically (they are *not* Folders). Roblox creates them itself; sync never deletes them.

## 2. Names and keys

The file/directory name (without suffixes) is the **key**; the Instance name is the key unless the metadata says otherwise.

* Characters that file systems reject (`< > : " / \ | ? *`, control chars), trailing dots/spaces, reserved names (`CON`, `NUL`, ...),
  names starting with a dot, `init`, and names ending in a format suffix (`.server`, `.meta`, ...) are replaced; the real name is
  stored as `"name"` in the metadata.
* Siblings with identical names (case-insensitive) become `Name`, `Name~2`, `Name~3`, ...; `"name": "Name"` is stored for the `~N` ones.
* Keys are **sticky**: deleting `Part` does not rename `Part~2` to `Part`.
* Sorting ("alphabetical") is case-insensitive and number-aware: `Part2` < `Part10`.

## 3. Metadata files

`*.instance.json`, `init.meta.json` and `*.meta.json` share one schema. All keys are optional except `className` in `*.instance.json`.

```json
{
  "className": "Part",
  "name": "SpawnPart",
  "properties": { "Size": [10, 1, 10], "Anchored": true, "Material": "Neon", "Color": "#FF8000" },
  "attributes": { "Coins": 5, "Origin": { "$type": "Vector3", "value": [0, 1, 0] } },
  "tags": ["Interactable"],
  "childOrder": ["Zebra", "Apple"]
}
```

* `className`: required in `*.instance.json`; in `init.meta.json` it defaults to `Folder` (or the script class for `init.*.luau`);
  never needed for scripts (the file suffix decides) or services.
* `properties`: only properties that differ from the class default are written. **A property you delete from the file is reset to
  its default in Studio.** Services have no default instance, so for them only the properties present are applied.
* `attributes`: strings, booleans and numbers are plain JSON; every other attribute type is tagged `{"$type": "...", "value": ...}`.
* `tags`: CollectionService tags.
* `childOrder`: keys of the children in the order Studio should have them. It is written only when Studio's order is not alphabetical.
  It is an instruction: children not listed keep their place after the listed ones. Remove it to stop enforcing an order.
* Unknown keys are preserved as is (you may add your own notes, e.g. `"comment"`).
* `outline` (only in `.rbxm` sidecars): informational list of what is inside the blob. Do not edit.

## 4. Value encodings

Properties are decoded using the **current type of the property**, so most values need no tag.

| Roblox type | JSON | Example |
|---|---|---|
| `boolean`, `string`, `number` | as is | `true`, `"Buy"`, `0.5` |
| `Vector3` / `Vector2` / `Vector3int16` / `Vector2int16` | array | `[10, 1, 10]` |
| `UDim` | `[scale, offset]` | `[0.5, 0]` |
| `UDim2` | `[[sx, ox], [sy, oy]]` | `[[1, 0], [0, 40]]` |
| `Rect` | `[minX, minY, maxX, maxY]` | `[0, 0, 64, 64]` |
| `Color3` | `"#RRGGBB"`, or `[r, g, b]` floats 0..1 when not 8-bit exact | `"#FFAA33"` |
| `CFrame` | 12 numbers `[x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22]` | `[0, 5, 0, 1,0,0, 0,1,0, 0,0,1]` |
| `NumberRange` | `[min, max]` | `[0.4, 0.9]` |
| `NumberSequence` | `[[time, value, envelope], ...]` | `[[0, 1, 0], [1, 0, 0]]` |
| `ColorSequence` | `[[time, color], ...]` | `[[0, "#FFFFFF"], [1, "#FF4600"]]` |
| `EnumItem` | item name | `"Neon"` |
| `BrickColor` | name | `"Bright red"` |
| `Font` | `{"Family": "...", "Weight": "Bold", "Style": "Normal"}` | |
| `Faces` / `Axes` | names | `["Top", "Front"]`, `["X", "Z"]` |
| `Ray` | `[[ox, oy, oz], [dx, dy, dz]]` | |
| `PhysicalProperties` | **tagged** `{"$type": "PhysicalProperties", "Density": .., "Friction": .., "Elasticity": .., "FrictionWeight": .., "ElasticityWeight": ..}` | |
| `Content` / asset id strings | string | `"rbxassetid://123456"` |
| non-finite numbers | `{"$type": "number", "value": "nan" \| "inf" \| "-inf"}` | |
| `Instance` reference | `{"$ref": "Workspace/Map/House/Door"}` | see 5 |
| pending asset | `{"$pendingAsset": "what is needed"}` | see 6 |

Unsupported types (`SharedTable`, `EditableImage` content, binary strings, `SecurityCapabilities` that differ from default, ...) are
reported as `unsupported-property-type` and not written; they never silently disappear from Studio.

## 5. Instance references

`{"$ref": "<key path>"}` points at another instance by its **key path** from the service: `Workspace/Map/House/Walls`
(directory/file keys, not display names - they differ only for `~N` duplicates and renamed names).
Used by `Model.PrimaryPart`, `Beam.Attachment0/1`, `Trail.Attachment0/1`, `Weld.Part0/1`, `ObjectValue.Value`,
`Highlight.Adornee`, constraints, ... If the target does not exist when the property is applied you get an `unresolved-reference` issue.

## 6. Assets: references, never invented ids

The repository can hold **references** to Roblox assets, not the assets themselves (see the support table in `ARCHITECTURE.md`).

* Existing asset: `"Texture": "rbxassetid://1234567"` - keep it exactly as Studio wrote it.
* Needed but not yet created (animation clips, sounds, textures, meshes, images): **do not guess an id**. Write

  ```json
  "AnimationId": { "$pendingAsset": "overhead slash, R15, 0.6 s - author in the Animation Editor and publish" }
  ```

  Studio leaves the property empty, remembers the note in a `GitSyncPending_AnimationId` attribute, and the sync status shows
  `⚠ Partially Synced` with this item. After a human creates the asset and pastes the real id into the property, the marker disappears
  and the real id is committed. If Studio already has a value, it is kept and the marker is ignored (reported).

## 7. Binary models (`.rbxm` + sidecar)

Unions, negations and other instances whose data cannot be expressed as properties are stored as `Name.rbxm` (a Roblox model file produced
by `SerializationService`) plus `Name.meta.json`:

```json
{ "className": "UnionOperation", "properties": { "Transparency": 0.25 }, "attributes": {}, "tags": [], "outline": ["Part Inner"] }
```

* The blob is authoritative for the geometry. `properties`/`attributes`/`tags` are an **editable overlay** for the root instance: edit them
  to change the root without touching the blob.
* Never hand-edit or regenerate `.rbxm` files. Add/replace models by building them in Studio.
* Which instances become binary is configurable: `binaryClasses` (default `UnionOperation`, `NegateOperation`, `BinaryStringValue`) and
  `binaryPaths` (exact name paths such as `"Workspace/Map/Terrain Decor"`).

## 8. `rbxsync.json`

```json
{
  "formatVersion": 1,
  "name": "MyGame",
  "srcDir": "src",
  "services": ["Workspace", "ServerScriptService", "ServerStorage", "ReplicatedStorage", "StarterGui", "StarterPlayer", "StarterPack", "ReplicatedFirst", "Lighting", "SoundService", "Teams", "TextChatService", "LocalizationService", "MaterialService"],
  "binaryClasses": ["UnionOperation", "NegateOperation", "BinaryStringValue"],
  "binaryPaths": [],
  "ignoreClasses": ["Terrain", "Camera"],
  "ignorePaths": [],
  "scriptExtension": "luau",
  "autoMerge": true
}
```

Core services (always recommended): `Workspace, ServerScriptService, ServerStorage, ReplicatedStorage, StarterGui, StarterPlayer, StarterPack`.
Add any other service name that `game:GetService` accepts to `services` (reconnect the plugin afterwards).

## 9. What the sync status means

| Status | Meaning |
|---|---|
| `Synced` | Both sides equal, no issues, Studio acknowledged every operation |
| `Partially Synced` | Preserved but not fully applied: pending assets, refused property writes, unsupported types, unparseable files, ... (listed with reasons) |
| `Conflict` | The same Instance changed on both sides in a way that cannot be merged. Nothing was overwritten |
| `Changes pending` / `Waiting for Studio` | Edits not yet synced / sent but not yet acknowledged |
| `Studio not connected` | Files are saved; they sync when Studio connects |

Issue codes: `pending-asset`, `property-write-failed`, `property-unreadable`, `unsupported-property-type`, `unsupported-instance`,
`unresolved-reference`, `unparseable-file`, `binary-roundtrip`, `asset-local`.

## 10. Plugin <-> companion protocol (for tool authors)

HTTP JSON on `127.0.0.1`, bearer token. The plugin addresses instances by session-local ids; the companion keeps a mirror of Studio.

```
POST /api/v1/p/<project>/studio/connect   -> { session, config: { services, binaryClasses, ignoreClasses, ... } }
POST .../studio/clear   { session, service }
POST .../studio/ops     { session, ops: [
    { "op": "upsert", "id": "p12", "parentId": "svc:Workspace" | "p3",
      "node": { name, className, properties, attributes, tags, source?, rbxm?(base64), outline? },
      "childIds": ["p5", "p9"]?, "issues": [{ code, property, message }]? },
    { "op": "remove", "id": "p12" } ] }
POST .../studio/ready   { session }       snapshot complete
GET  .../studio/events?session&cursor&wait=15   long poll -> { entries: [{ cursor, group, last, ops }] }
POST .../studio/ack     { session, cursor, results: [{ id, issues }] }
```

References in operations are `{"$ref": {"id": "p7", "path": "Workspace/Map/House/Walls"}}`.
