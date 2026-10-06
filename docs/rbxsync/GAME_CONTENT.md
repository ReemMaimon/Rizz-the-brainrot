# Game content cookbook (AI agents)

Recipes for building real game content through the repository. Every path below exists in
[`examples/TestProject`](examples/TestProject) - open it next to this document. The sync rules are in `SYNC_FORMAT.md`.

## Worked example: "a sword with an attack animation, slash VFX, sound, UI cooldown and a server-side damage system"

```
Attack
  -> client: Tool.Activated -> play Animation -> spawn VFX (particles + trail + light) -> Tween the glow -> play Sound
  -> client fires RemoteEvent "SwordSlash"
  -> server: validates cooldown + range, applies damage (Humanoid:TakeDamage), tells the client the cooldown
  -> client UI: cooldown bar refills with a Tween
```

| Piece | File(s) | Created by you? |
|---|---|---|
| Shared tuning | `src/ReplicatedStorage/SwordConfig.luau` | yes |
| Remotes | `src/ReplicatedStorage/Remotes/SwordSlash.instance.json`, `SwordCooldown.instance.json` (`RemoteEvent`) | yes |
| Tool | `src/StarterPack/Sword/init.meta.json` (`Tool`), `Handle.instance.json` | yes |
| Client controller | `src/StarterPack/Sword/SwordClient.client.luau` | yes |
| Server damage system | `src/ServerScriptService/SwordService.server.luau` | yes |
| Slash VFX | `src/ReplicatedStorage/VFX/SlashVFX/` (`Root` part, `TipA`/`TipB` Attachments, `Sparks` ParticleEmitter, `SlashTrail` Trail with `$ref`s, `Glow` PointLight) | yes (textures pending) |
| Hit VFX | `src/ReplicatedStorage/VFX/HitEffect/` (`Particles`, `Highlight`) | yes (texture pending) |
| Cooldown UI | `src/StarterGui/CooldownUI/` (`Bar`, `Fill`, `Corner`, `Label`, `CooldownUI.client.luau`) | yes |
| Camera effect | `src/StarterPlayer/StarterPlayerScripts/CameraShake.luau` | yes |
| Attack animation clip | `src/StarterPack/Sword/SlashAnimation.instance.json` -> `AnimationId: {"$pendingAsset": ...}` | **placeholder only** |
| Sound effect | `.../SlashVFX/SlashSound.instance.json` -> `SoundId: {"$pendingAsset": ...}` | **placeholder only** |
| Spark textures | `Sparks.Texture`, `HitEffect/Particles.Texture` -> `$pendingAsset` | **placeholder only** |

After `roblox-sync sync` the project is fully usable in Studio, but the status is **Partially Synced**: 4 pending assets
(`SlashAnimation.AnimationId`, `SlashSound.SoundId`, two particle textures). The agent's final message should list them and what the
user has to do:

1. Animation Editor: author the slash animation, publish it, paste the id into `SlashAnimation.AnimationId`.
2. Upload (or choose) a whoosh sound, paste its id into `SlashSound.SoundId`.
3. Upload spark sprites, paste the ids into the two `Texture` properties.

The sync writes these ids back to the repository; the status then becomes `Synced`. The code already handles the "not yet created" state
(`AnimationId ~= ""`, `SoundId ~= ""` guards), so the game runs meanwhile.

## Recipes

### ParticleEmitter (burst, one-shot)

```json
{
  "className": "ParticleEmitter",
  "properties": {
    "Rate": 0, "Enabled": false,
    "Lifetime": [0.25, 0.5], "Speed": [14, 28], "SpreadAngle": [180, 180], "Rotation": [0, 360], "RotSpeed": [-180, 180],
    "Acceleration": [0, -40, 0], "Drag": 3, "LightEmission": 1, "LightInfluence": 0,
    "Color": [[0, "#FFE6A0"], [0.5, "#FFB432"], [1, "#FF4600"]],
    "Size": [[0, 0.5, 0], [1, 0, 0]],
    "Transparency": [[0, 0, 0], [0.7, 0.2, 0], [1, 1, 0]],
    "Texture": { "$pendingAsset": "soft round spark sprite" }
  }
}
```

Code: `emitter:Emit(20)`. Continuous effects: `Rate > 0`, `Enabled: true`. Roblox requires `NumberSequence`/`ColorSequence` to have
a keypoint at time 0 and at time 1; other values are reported if refused.

### Beam / Trail between attachments

Create two `Attachment`s (CFrame offsets) and reference them: `"Attachment0": {"$ref": "ReplicatedStorage/VFX/SlashVFX/TipA"}`.
`Trail` follows the moving part; `Beam` connects two points (`Width0/1`, `Segments`, `CurveSize0/1`, `Texture`).

### Lights, Highlight, Fire/Smoke/Sparkles/Explosion

`PointLight` / `SpotLight` / `SurfaceLight`: `Brightness`, `Range`, `Color`, `Angle` (`SpotLight`/`SurfaceLight`), `Face`, `Shadows`.
`Highlight`: `FillColor`, `FillTransparency`, `OutlineColor`, `DepthMode`, `Adornee` (`$ref`). Legacy effects use the same pattern.

### Animation system

* Data: `Animation` instances (`AnimationId` = asset reference or `$pendingAsset`), grouped in a folder per character/tool.
* Config: a ModuleScript mapping state -> animation name/priority/speed (`AnimationConfig.luau`) or attributes on the Animation.
* Code: load once per equip/spawn, cache tracks, guard empty ids:

```lua
local animator = humanoid:FindFirstChildOfClass("Animator")
if animator and animation.AnimationId ~= "" then
	local track = animator:LoadAnimation(animation)
	track.Priority = Enum.AnimationPriority.Action
	track:Play()
end
```

* `KeyframeSequence`/`Keyframe`/`Pose` instances can be stored as files too, but authoring real animations is a Studio task.

### Tweens and motion (all code, fully supported)

```lua
TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
	Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 0,
}):Play()
```

UI: tween `Position`, `Size`, `Rotation`, `BackgroundColor3`, `TextTransparency`, `ImageTransparency`.
World: tween `CFrame`, `Size`, `Transparency`, `Color` of parts, `Brightness` of lights. Sequences: `tween.Completed:Wait()` or `task.delay`.
Camera: `CameraShake.shake(duration, magnitude)` (`StarterPlayerScripts/CameraShake.luau`), FOV tweens on `workspace.CurrentCamera`.

### Ability / combat effect pattern

1. Config in a shared ModuleScript (damage, cooldown, range, VFX name).
2. Client: input -> animation -> local VFX -> `RemoteEvent:FireServer()`.
3. Server: validate (cooldown, range, state), apply the effect, optionally replicate VFX with a `RemoteEvent` to all clients.
4. UI: bind to the cooldown remote, tween the bar.

Always keep the server authoritative; never trust values sent by the client.

### UI screen

See `src/StarterGui/CooldownUI/`: `ScreenGui` (`init.meta.json`) -> `Frame` directory with `UICorner`, a `LocalScript`.
Layouts: `UIListLayout`, `UIGridLayout`, `UIPadding`, `UIScale`, `UIAspectRatioConstraint`, `UIStroke`, `UIGradient` are siblings of the elements they affect.

### Configuration data

`Configuration`, `IntValue`, `StringValue`, `NumberValue`, `BoolValue`, `ObjectValue` (`Value` as `$ref`), or attributes on any instance.
Attribute types other than string/number/boolean are tagged: `{"$type": "Vector3", "value": [0, 3, 0]}`.

## Limits to state clearly to the user

* Animation clips, meshes, textures, audio and terrain cannot be authored from files: they are `$pendingAsset` until created in Studio/Roblox.
* A Union or other binary model can be moved/renamed/tagged via its sidecar but not edited.
* The status says `Partially Synced` until every pending asset has a real id. That is correct behaviour, not an error.
