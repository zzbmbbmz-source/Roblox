# Flight Hub

Purple-neon, mobile-friendly flight UI for a Roblox experience you own or are authorized to edit.

## Install

1. Open Roblox Studio and open your experience.
2. In Explorer, navigate to `StarterPlayer > StarterPlayerScripts`.
3. Add a `LocalScript` and paste the contents of [FlightHub.client.lua](./FlightHub.client.lua).
4. Press **Play** to test.

## Features

- Flight toggle with active/offline status.
- Ascend and descend buttons, including touch input.
- Adjustable flight speed (20–200 studs/s).
- Flight, Speed, and Settings tabs.
- Draggable panel, minimize control, and hide/reopen button.
- Responsive scaling for smaller viewports.

## Notes

This LocalScript is a client-side prototype for your own Roblox experience. For a production multiplayer game, implement server-side movement validation and integrate flight permissions with your game's server logic. Client-created UI and physics objects do not grant authority over other experiences.
