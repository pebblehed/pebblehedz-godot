# Pebble Hedz — Godot Edition

Pebble Hedz is a mobile-first pebble-skipping game focused on emotional water interaction, satisfying launch-and-skip gameplay, survival tension, distance chasing, and immediate replayability.

## Core Loop

```text
Choose angle
→ choose power
→ launch
→ skip / survive
→ environmental intervention
→ gain distance
→ fail
→ instant retry
```

The player controls the throw before launch and does not steer the pebble after launch.

## Current Foundation

- Responsive Hooke-style water
- Ripple propagation and disturbance
- Two-stage angle/power launch
- Throw-quality differentiation
- Progressive skip-energy behaviour
- Late-stage skim and sink flow
- Rolling water world
- Camera and distance tracking
- Reactive visual lily pads
- Lily-pad contact and outcome classification

Lily-pad survival assistance is currently experimental and is not yet a validated baseline feature.

## Development Method

Pebble Hedz follows the PixelSync / NoDrift development workflow:

```text
Repository truth
→ bounded objective
→ ownership-first change
→ validate
→ review diff
→ commit
→ clean repository
→ extend
```

One mechanic is developed and validated at a time. Working baselines and protected systems must not be casually rewritten.

## Project Documentation

Start with:

- `docs/PEBBLEHEDZ_PRODUCT_TRUTH.md`
- `docs/PEBBLEHEDZ_GAMEPLAY_DESIGN.md`
- `docs/PEBBLEHEDZ_EXPERIENCE_DIRECTION.md`
- `docs/PEBBLEHEDZ_DEVELOPMENT_STATE.md`

Original contract sources remain under `docs/contracts/`.

## Engine

Godot 4.6.x
