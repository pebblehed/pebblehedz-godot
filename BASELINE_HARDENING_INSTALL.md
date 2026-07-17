# Pebble Hedz Baseline Hardening — Installation

This pack contains repository governance and development-environment files only.

It does not replace or modify gameplay scripts.

## Files Added or Updated

```text
.gitattributes
.editorconfig
.vscode/settings.json
README.md
docs/README.md
docs/PEBBLEHEDZ_PRODUCT_TRUTH.md
docs/PEBBLEHEDZ_GAMEPLAY_DESIGN.md
docs/PEBBLEHEDZ_EXPERIENCE_DIRECTION.md
docs/PEBBLEHEDZ_DEVELOPMENT_STATE.md
tools/project-check.ps1
```

## Safe Application

From the Pebble Hedz repository root:

```powershell
git status
```

Confirm the current gameplay changes before copying the hardening pack into the repository.

The pack intentionally does not contain:

```text
TestPebbleCharacter.gd
scripts/LilyPadManager.gd
HookeWater2D.gd
WaterSegmentManager.gd
main.tscn
```

After copying the pack files into the repository, run:

```powershell
.\tools\project-check.ps1
```

Then inspect only the hardening changes:

```powershell
git --no-pager diff -- .vscode/settings.json README.md
git status
```

Review the new files directly before staging them.

## Recommended Commit Boundary

Do not mix the baseline-hardening commit with the current lily-pad survival experiment.

The hardening files should be committed as their own repository-governance checkpoint after review.
