# Modding

Mods are first class. Anything the base game loads from `data/` can be overridden by a
mod without touching engine code.

## Where mods live

```
mods/
  my-mod/
    mod.json
    plays/
      shotgun-cross.json
    rosters/
      fictional-league.json
    uniforms/
      home.png
```

Each mod folder needs a `mod.json`:

```json
{
  "name": "My Mod",
  "id": "com.yourname.mymod",
  "version": "1.0.0",
  "author": "You",
  "load_order": 100,
  "game_min": "0.1.0"
}
```

`load_order` decides who wins when two mods define the same asset. Higher loads last and
overrides.

## What can be modded

| Type | Path | Notes |
| --- | --- | --- |
| Plays / playbooks | `plays/*.json` | Routes, assignments, formation, motion |
| Rosters | `rosters/*.json` | Players as combine measurables |
| Teams | `teams/*.json` | Name, colors, uniforms, stadium |
| Rulesets | `rules/*.json` | Downs, clock, field size, penalties |
| Tuning | `tuning/*.json` | Sim vs arcade physics parameter sets |
| Assets | `uniforms/`, `fields/`, `stadiums/` | PNG/GLTF, referenced by manifest |

## The one hard rule

**Mods may not introduce outcome-based randomness.**

A mod can change how heavy a player is, how much grip a cleat has, how fast a ball leaves
a hand. A mod may not add "if roll < 0.7 then catch". Pull requests and mods that script
outcomes will be rejected on principle.

Randomness is allowed for *presentation only*: crowd noise, pre-snap animation variety,
ambient commentary lines. It must never touch the simulation state.

## Player data format

Players are defined by measurables, not abstract ratings:

```json
{
  "id": "wr_001",
  "name": "Sample Receiver",
  "position": "WR",
  "height_cm": 185.0,
  "weight_kg": 88.0,
  "wingspan_cm": 191.0,
  "arm_length_cm": 85.0,
  "hand_size_cm": 24.5,
  "forty_yard_s": 4.48,
  "ten_yard_split_s": 1.55,
  "twenty_yard_shuttle_s": 4.20,
  "three_cone_s": 6.85,
  "short_shuttle_s": 4.15,
  "vertical_jump_cm": 92.0,
  "broad_jump_cm": 315.0,
  "bench_press_reps": 12
}
```

Everything the game uses — acceleration, top speed, turn radius, reach, catch radius,
break-tackle resistance — is derived from these numbers in
`src/data/PlayerMeasurables.gd`.

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md).
