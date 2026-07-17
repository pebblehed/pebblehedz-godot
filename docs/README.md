# Pebble Hedz Project Documents

This directory contains the authoritative product and development context for Pebble Hedz.

## Current Authoritative Documents

- `PEBBLEHEDZ_PRODUCT_TRUTH.md` — what the product is and the non-drift product rules.
- `PEBBLEHEDZ_GAMEPLAY_DESIGN.md` — core loop, player agency, survival ecosystem, and gameplay behaviour.
- `PEBBLEHEDZ_EXPERIENCE_DIRECTION.md` — premium, ASMR, visual, emotional, and mobile-first direction.
- `PEBBLEHEDZ_DEVELOPMENT_STATE.md` — current implemented state, protected systems, experimental work, and exact next action.
- `PEBBLEHEDZ_AI_IMPLEMENTATION_PROTOCOL.md` — governs AI-assisted implementation workflow, file scope, review, validation, and Claude Code execution discipline.

## Existing Contract Sources

The original contract documents remain under `docs/contracts/`:

- `PEBBLEHEDZ_ENGINEERING_CONTRACT.md.docx`
- `PEBBLEHEDZ_PRODUCT_TRUTH.md.docx`
- `PEBBLEHEDZ_WATER_FEEL_CONTRACT.md.docx`

The Markdown documents above consolidate the current working product direction for day-to-day development. The existing contracts remain governing source material and should not be silently contradicted.

## Documentation Rule

Before proposing a meaningful gameplay or architectural change:

1. Read the relevant product/design document.
2. Read `PEBBLEHEDZ_DEVELOPMENT_STATE.md`.
3. Identify the owning subsystem.
4. Define the allowed file scope.
5. Validate after the change.
6. Update development state only after the implementation is validated and committed.
