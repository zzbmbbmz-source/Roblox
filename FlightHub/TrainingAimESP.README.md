# Training Aim + ESP Add-on

A purple-neon practice panel for a Roblox Studio experience you own or are authorized to test.

## Install
1. Open Roblox Studio and your own experience.
2. In Explorer, open **StarterPlayer > StarterPlayerScripts**.
3. Insert a **LocalScript** named `TrainingAimESP`.
4. Copy the contents of `TrainingAimESP.client.lua` into it.
5. Add practice NPC Models to `workspace.TrainingTargets`, or tag each NPC Model with CollectionService tag `TrainingTarget`.
6. Press Play to test.

Each target Model must contain a Humanoid and HumanoidRootPart. The script prefers Head as the aim point.

## Features
- **Aim Assist:** gently moves the local camera toward the closest on-screen practice NPC.
- **Silent Target Resolver:** exposes a local `BindableFunction` named `SilentTargetResolver` under the UI ScreenGui. Your own weapon LocalScript can call `PlayerGui.TrainingAimESP.SilentTargetResolver:Invoke()` to obtain the selected practice NPC Model when enabled. This is a developer-owned target-selection hook, not a hook for other games or remote exploits.
- **NPC ESP:** highlights practice NPCs and displays their name, distance, and health.
- Mobile-friendly toggle buttons, hide/reopen panel.

## Important
This is a client-side practice/debug helper. It does not make damage authoritative and should not be used to decide hits in a live multiplayer game. For a real weapon system, validate shots and damage on the server (range, line of sight, fire rate, and target eligibility). Do not use it to gain an unfair advantage in experiences you do not own.
