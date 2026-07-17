# Pebble Hedz Product Truth

**Status:** Authoritative Foundation  
**Project:** Pebble Hedz — Godot Edition  
**Owner:** PixelSync  
**Last reviewed:** 2026-07-17

## Product Definition

Pebble Hedz is a solo-first, mobile-first pebble-skipping game built around emotional water interaction, satisfying launch-and-skip gameplay, survival tension, distance chasing, and immediate replayability.

The game exists to create:

- a strong emotional connection with water;
- tactile and readable moment-to-moment feedback;
- tension after launch because the player cannot steer the pebble;
- moments of hope and surprise created by the environment;
- a strong "one more go" compulsion after every failure;
- a calm, premium atmosphere with competitive undertones.

## Core Product Objective

Pebble Hedz must be an addictive game first.

Water, animation, sound, environmental systems, and technical architecture exist to strengthen gameplay feel, retention, emotional response, and replayability.

Technical sophistication is not a product objective by itself.

## Core Loop

```text
Choose launch angle
→ choose launch power
→ launch pebble
→ watch the run unfold
→ skip / survive / receive environmental help
→ gain distance
→ fail or continue
→ instant retry
```

## Player Agency

The player controls the throw before launch through timing, angle, and power.

After launch, the player does not steer the pebble.

The excitement comes from watching the selected throw interact with water and the environment, creating unpredictable runs, near misses, saves, and memorable outcomes.

## Product Priorities

Highest to lowest:

1. Water feel
2. Skip feel
3. Emotional response
4. Replayability and retention
5. Environmental survival interactions
6. Premium visual and audio presentation
7. Meta systems

## Survival Ecosystem

Environmental systems progressively add hope, surprise, and run extension without replacing the core throw-and-watch loop.

The intended progression is:

```text
Water and skipping
→ lily pads
→ butterflies
→ fish
→ later retention and challenge systems
```

Lily pads are the first survival layer. They are not decorative-only objects and they are not player-steered targets. Random placement and the trajectory of the launched pebble determine whether an interaction occurs.

A stronger lily-pad contact should produce a stronger survival benefit:

```text
Near miss → no benefit
Glancing contact → small survival assist
Good contact → meaningful survival assist
Direct contact → strongest survival assist
```

## Non-Drift Rules

- Water remains the hero mechanic.
- Distance remains the primary run metric.
- Instant retry must remain protected.
- No post-launch steering.
- Environmental interactions must strengthen survival, tension, hope, or memorable moments.
- Do not add mechanics that reduce readability or dilute the core loop.
- No real-time multiplayer as a core requirement.
- No pay-to-win systems.
- Protect simple presentation.
- Gameplay value outranks technical novelty.

## Success Metric

The defining success signal is simple:

> After a run ends, the player immediately wants another throw.
