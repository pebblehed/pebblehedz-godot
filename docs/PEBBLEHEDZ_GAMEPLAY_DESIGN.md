# Pebble Hedz Gameplay Design

**Status:** Authoritative Foundation  
**Project:** Pebble Hedz — Godot Edition  
**Owner:** PixelSync  
**Last reviewed:** 2026-07-17

## Gameplay Promise

Pebble Hedz turns a simple throw into a suspenseful run.

The player makes a meaningful launch decision and then watches the pebble's journey unfold across a living water surface and an increasingly rich environmental ecosystem.

The game should repeatedly create moments such as:

- "That was a great throw."
- "Come on, keep going."
- "That lily pad saved me."
- "I cannot believe that run survived."
- "One more try."

## Launch Phase

The launch phase currently uses two player inputs:

1. Lock launch angle.
2. Lock launch power and launch.

The quality of the selected throw influences the potential length and quality of the run.

The launch system must remain readable, immediate, and suitable for touch input.

## Post-Launch Rule

There is no player steering after launch.

This rule is fundamental because it preserves:

- tension;
- anticipation;
- chance-based environmental interactions;
- the emotional value of near misses and lucky saves;
- the simplicity of the mobile control model.

## Skip and Survival Loop

The current foundation supports:

```text
Launch
→ first water impact
→ skip chain
→ energy decay
→ late-stage skim
→ sink
→ reset
```

Throw quality affects how long useful energy is retained. Poor throws should die sooner. Better throws should earn longer runs.

## Water

Water is active gameplay feedback, not background decoration.

Every water interaction should help the player read what happened and feel the run progressing.

Protected water responsibilities include:

- surface height;
- ripple propagation;
- impact disturbance;
- water response;
- readable interaction feedback.

Changes outside the water system may read water state, but must not casually redefine water behaviour.

## Lily Pads — Survival Layer 1

Lily pads are the first positive environmental intervention.

They are randomly positioned within fair placement constraints. The player cannot steer toward them after launch. Their value comes from the suspense of whether the current trajectory will intersect them.

Contact tiers:

```text
NEAR_MISS
No survival benefit.

GLANCING
Small survival assist.

GOOD
Meaningful survival assist.

DIRECT
Strongest survival assist.
```

The survival assist may combine vertical recovery and replenishment of usable skip energy, provided the result visibly extends or rescues the run.

A lily-pad interaction must be noticeable. If the player cannot tell that the pad helped, the mechanic is not yet doing its job.

The interaction should create hope and excitement without making every run endless or removing the importance of launch quality.

## Future Environmental Layers

### Butterflies

Butterflies are intended as a later environmental layer that adds excitement and special moments beyond the first lily-pad survival system.

### Fish

Fish are intended as a later environmental layer that adds surprise and further memorable run variation.

Neither layer should be implemented until the lily-pad survival loop is validated and the core launch/water/skip experience remains protected.

## Distance

Distance is the primary run metric.

Environmental systems matter because they can create additional survival and therefore additional distance. They should not replace distance with a collection-heavy or menu-heavy progression loop.

## Validation Questions

Every gameplay change should answer at least one of these positively:

- Does this make the run more exciting?
- Does this create more tension or hope?
- Does this make a successful event clearly readable?
- Does this strengthen the desire to retry?
- Does this protect the simplicity of the core loop?
