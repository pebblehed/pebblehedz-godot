# Pebble Hedz Development State

**Status:** Current Repository Truth  
**Snapshot date:** 2026-07-17  
**Branch:** `main`  
**Repository head at audit:** `f0e8a48` — `Add lily pad lift outcome logging`

## Purpose

This document records the current development checkpoint only.

It must be updated when a meaningful validated milestone is committed. It does not redefine product truth, gameplay design, or engineering contracts.

## Validated Foundation

The repository history establishes the following implemented foundations:

- two-stage angle and power launch selection;
- pebble flight and water impact handling;
- Hooke-style responsive water surface;
- ripple propagation and water disturbance;
- water reset lifecycle;
- rolling single-water-body world support;
- camera follow;
- distance markers;
- throw-quality differentiation;
- quality-based skip-energy retention;
- late-stage skim behaviour;
- visual lily-pad generation;
- random forward lily-pad placement;
- lily-pad water-surface following;
- lily-pad wave-slope visual rotation;
- lily-pad proximity/contact classification;
- lily-pad outcome logging.

## Protected Systems

Until deliberately reopened through a bounded change, protect:

- `HookeWater2D.gd` water behaviour;
- `WaterSegmentManager.gd` rolling/reset lifecycle;
- established launch input flow;
- established throw-quality calculation;
- established skip-energy behaviour;
- instant reset/retry flow.

## Current Experimental Work

The audited ZIP contains uncommitted experimental changes in:

```text
TestPebbleCharacter.gd
scripts/LilyPadManager.gd
```

The experiment attempts to add lily-pad survival assistance through:

- contact-height gating;
- contact-tier-based vertical lift;
- contact-tier-based skip-energy refill;
- a pebble-owned `apply_lily_pad_survival()` method.

This work is **not yet validated** and must not be described as a completed gameplay feature.

## Important Technical Finding

The pebble skim state currently sets:

```gdscript
velocity.y = 0.0
```

on every skim update.

Therefore, a lily-pad vertical survival assist applied while the pebble remains in skim state may be visually overwritten immediately on the next physics frame.

This is the first hypothesis to validate before further tuning of lift values.

## Current Repository Hygiene Finding

The audited ZIP contains widespread line-ending or formatter churn outside the meaningful gameplay experiment.

Repository hardening should establish deterministic LF line endings and project-local GDScript indentation settings before further feature development.

## Exact Next Development Action

After repository baseline hardening is applied and the working tree is reconciled:

1. Re-establish the exact intentional lily-pad survival experiment diff.
2. Remove stale or duplicated survival integration paths.
3. Run the game with explicit event/state diagnostics at lily-pad contact.
4. Determine whether contact occurs during `LAUNCHED`, `is_skimming`, or another state.
5. Validate whether the survival assist is applied and then overwritten.
6. Make one bounded correction based on evidence.
7. Validate the run feel before tuning final values.

## Validation Standard

A lily-pad survival interaction is not considered successful merely because a log line fires.

The player must visibly perceive that the lily pad affected the run.

The desired progression remains:

```text
Glancing → small visible rescue
Good → meaningful visible rescue
Direct → strongest visible rescue
```
