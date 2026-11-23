# Godot 2D Survival Platformer

A 2D survival-horror platformer built with **Godot 4**. You play **Finn**, an ordinary office technician trapped in the Apex Corp tower at the start of a zombie outbreak. You have no military training and very few supplies. You scavenge, sneak, and use hit-and-run tactics to climb floor by floor to the lobby and escape.

> **Status:** early development (prototype). Core movement, stats, HUD, and the wrench attack are working. Enemies, stealth, looting, and trading are in progress.

<!-- Add a screenshot or GIF here once you have one:
![Gameplay](docs/screenshot.png)
-->

## Concept

> A 2D survival platformer where the player gathers scarce resources and uses tactical hit-and-run combat to escape a zombie-infested corporate office building, set in a retro pixel-art dystopian city during a sudden outbreak.

### Design pillars

1. **Resource fragility over power fantasy.** Finn is not a soldier. Weapons wear out, stamina drains fast, and ammo is rare.
2. **Hit-and-run spatial traversal.** Movement is the main defense. No blocking in place and no forced arena lock-ins.
3. **Claustrophobic acoustic realism.** Sound is a game mechanic. Sprinting, breaking doors, and swinging a wrench make noise that pulls zombies in.
4. **Grounded narrative reinforcement.** Every mechanic fits an office technician surviving with office items. The story is told through the environment, not long cutscenes.

### Key mechanics

| Mechanic | Summary |
|---|---|
| Wrench combat | 25 damage per swing, 30 stamina per swing (3 swings per full bar), 1.2 s stagger on enemies |
| Stamina | 100 points; sprint drains 10/s, recharge 20/s after a 1 s pause |
| Acoustic stealth | Crouch (0.5 m noise), walk (2.5 m), sprint (6 m), door break / glass (12 m) |
| Looting | Hold interact for 1.5 s to search; searching makes noise; 12 inventory slots |
| Barter | Trade scrap for bandages, wrench upgrades, keycards, and a makeshift pistol |

## Current progress

- [x] Player movement: walk, crouch, sprint, jump, with coyote time and jump buffering
- [x] HP, stamina, and infection stats with HUD bars
- [x] Central balance resource (`balance.tres`) for tuning
- [x] Wrench attack with windup / active / recovery phases, stagger, exhausted swing, and screen shake
- [x] Training dummy for testing
- [ ] Basic zombie enemy (patrol, chase, attack)
- [ ] Acoustic detection system (noise events, detection meter, vision cone)
- [ ] Looting and 12-slot inventory
- [ ] Safe zone and City Trader barter UI
- [ ] Floors 1-3 level design and keycard progression
- [ ] Story delivery (environmental storytelling, diegetic notes, micro-cutscenes)
- [ ] Art, audio, and polish pass

## Requirements

- **Godot 4.x** (stable). Download from [godotengine.org](https://godotengine.org/download).
- Rendering method: **Compatibility** (recommended for 2D and Steam Deck).

## Getting started

1. Clone the repository:
   ```bash
   git clone https://github.com/<your-username>/<your-repo>.git
   ```
2. Open Godot and click **Import**, then select the project's `project.godot`.
3. Open `scenes/test_level.tscn` and press **F6** to run the current scene.

### Recommended project settings

| Setting | Value |
|---|---|
| Display → Window → Viewport size | 320 × 180 |
| Display → Window → Stretch Mode | `viewport` |
| Display → Window → Stretch Scale Mode | `integer` |
| Rendering → Textures → Default Texture Filter | `Nearest` |
| Physics → Common → Physics Ticks per Second | 60 |

## Controls

| Action | Keyboard / Mouse | Gamepad |
|---|---|---|
| Move | A / D or ← / → | Left stick |
| Jump | Space, W, or ↑ | (planned) |
| Crouch | Ctrl or C | (planned) |
| Sprint | Shift | (planned) |
| Attack (wrench) | X or Left Click | X button |

**Debug keys** (editor and debug builds only): `K` take 20 damage, `J` heal 30, `L` add infection.

## Project structure

```
├── assets/        # sprites, tilesets, audio
├── resources/     # balance.tres and other resources
├── scenes/        # player, dummy, test level
├── scripts/       # GDScript files
│   ├── player.gd
│   ├── balance.gd
│   ├── hud.gd
│   ├── camera_shake.gd
│   └── dummy.gd
├── docs/          # Game Design Document and screenshots
└── project.godot
```

## Tuning the game

All gameplay numbers (HP, stamina, speeds, wrench timings, damage) live in the `Balance` resource at `resources/balance.tres`. Open it in the Inspector and edit values while the game is running to test changes instantly. No code changes are needed.

## Game Design Document

The full design (core loop, mechanic specifications, difficulty pacing, story, and character profiles) is in the GDD, Chapters 1-4, stored in `docs/`.

**Characters:** Finn (player), City Trader, Soldier, Homeless Survivor, Raider, and the Urban Zombie.

## Roadmap

1. Basic zombie with a state machine
2. Noise and stealth system
3. Looting and inventory
4. Trader UI and barter
5. Floors 1-3, progression, and story
6. Art, audio, and polish

## Contributing

This is currently a class / team project. Issues and suggestions are welcome. Please open an issue before making large changes.

## Credits

- Built with [Godot Engine](https://godotengine.org/)
- Inspired by *Dead Cells*, *This War of Mine*, and *Lone Survivor*

## License

*(Choose a license, for example MIT, and add a `LICENSE` file. Check the licenses of any third-party assets you use.)*

