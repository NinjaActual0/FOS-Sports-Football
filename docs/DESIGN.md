# FOS Sports Football Design Document

## Overview
FOS Sports Football is a physics-driven American football simulation. No dice rolls, no scripted outcomes.
Results emerge from object interactions, real-world measurables, environment, equipment, health/fatigue, and player input.

## Core Principles
- Object oriented simulation (track all entities: players, ball, officials, field objects)
- Measurables derived from NFL Combine style data
- Physics-first (momentum, forces, collisions, impulses)
- One engine for all modes (Player, Coach Mode, Full Game Sim)
- Simulation and Arcade are tuning sets only
- Cross-platform (Windows, Linux, macOS, Steam Deck)
- Open source MIT

## Player Measurables
Derived from real combine numbers:
- Anthro: height, weight, wingspan, arm_length, hand_size
- Speed/Explosion: forty_yard, ten_yard_split, twenty_yard_shuttle
- Agility: three_cone, short_shuttle
- Power/Athleticism: vertical_jump, broad_jump, bench_press
- Position + handedness

These directly influence acceleration curves, top speed, mass/momentum, change of direction, reach, leverage, etc.

## Physics
- Use Godot Physics with Jolt Physics when available
- Ball is a physics object (trajectory, spin, air resistance)
- Collisions and momentum transfer drive tackles, blocks, catches
- No success % tables
- Forces come from mass, velocity, angles, friction

## Environment
- Weather: rain, snow, wind, fog, temperature, humidity
- Field: natural grass, turf types, mud, wet, ice, snow coverage
- Time of day, altitude
- Affects traction, grip, visibility, ball behavior

## Equipment
- Cleats, gloves, pads affect traction/grip/ball security
- Impacts physics interactions

## Health & Fatigue
- Stamina, fatigue accumulation, soreness
- Injuries affect performance realistically
- Hydration/wear affect output
- Substitutions matter

## Game Modes
- Player vs AI / Player vs Player
- Coach Mode (call plays, watch, jump in anytime)
- Full Game Simulation (same physics, accelerated)

## Input
- Xbox, PlayStation, Keyboard+Mouse
- Dynamic button glyphs (swap based on connected controller)
- Remappable
- Haptics optional

## Modding
- Data driven via JSON/resources
- Mods in mods/ folder
- Playbooks, rules, uniforms, fields, rosters, etc swappable
- Open format

## Rendering
- Start greybox, modular for PBR/photo-real later
