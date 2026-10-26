# Controls

## Decision: classic Madden scheme

Default bindings follow the classic Madden layout. It is the most familiar scheme for
most players, so it is the right starting point. Remapping stays fully supported, and
alternative schemes (including our own) can layer on later.

The important part: **the control scheme is only a mapping.** Cuts and spins are physics
events, not button-triggered animation states.

## Ball carrier

| Action | Xbox | PlayStation | Keyboard | Status |
| --- | --- | --- | --- | --- |
| Move | Left stick | Left stick | WASD | Done |
| Sprint | RT | R2 | Shift | Done |
| Spin | B | Circle | Q | Done |
| Cut / plant | Left stick, sharp | Left stick, sharp | WASD, sharp | Done (emergent) |
| Juke | Right stick L/R | Right stick L/R | — | Planned |
| Stiff arm | A | Cross | — | Planned |
| Dive | X | Square | — | Planned |
| Hurdle | Y | Triangle | — | Planned |
| Cover ball | RB | R1 | — | Planned |
| Lateral | LB | L1 | — | Planned |

### Why "cut" has no button

A cut is not an action the player selects. It is what happens when momentum in one
direction gets asked to become momentum in another, faster than the body can do it. You
cut by moving the stick. The system then decides how much speed that costs, based on
angle, current speed, agility (3-cone, shuttle), and traction.

That is why a good player cuts better than a bad one without any dice involved.

### Spin

Spin has a button because it is a *decision*: keep your momentum, give up your steering,
and hope the defender's leverage breaks. It costs speed up front, locks your lateral
acceleration for the duration, and has a cooldown.

## Quarterback / passing (planned)

| Action | Xbox | PlayStation | Keyboard |
| --- | --- | --- | --- |
| Throw to receiver | Receiver icon button | Receiver icon button | — |
| Pump fake | RB | R1 | — |
| Scramble | Left stick | Left stick | WASD |
| Slide | X | Square | — |

Passing will be timing and placement driven. The button selects the target; ball
trajectory, lead, and whether the window is actually open come from physics.

## Defense (planned)

| Action | Xbox | PlayStation | Keyboard |
| --- | --- | --- | --- |
| Move | Left stick | Left stick | WASD |
| Sprint | RT | R2 | Shift |
| Tackle | A | Cross | F |
| Dive | X | Square | — |
| Swat | X | Square | — |
| Intercept | Y | Triangle | — |
| Switch player | B | Circle | — |

## Pre-snap (planned)

| Action | Xbox | PlayStation |
| --- | --- | --- |
| Snap | A | Cross |
| Audible | Y | Triangle |
| Hot route | X | Square |
| Motion | B | Circle |

## Keyboard and mouse

Keyboard is a first-class input, not a fallback. Analog-only controls (sprint trigger,
right-stick juke) get digital equivalents. Gamepad glyphs swap automatically when you
switch devices.

## Adding a control

1. Add the action in **Project Settings → Input Map** (or `project.godot`).
2. Add the glyph string to each set in `src/input/InputManager.gd`.
3. Read it with `Input.is_action_pressed()` / `Input.is_action_just_pressed()`.
4. Update this file.

Never let a button directly decide an outcome. A button should change a physical input
(force, impulse, target point, timing window). The outcome comes out of the simulation.
