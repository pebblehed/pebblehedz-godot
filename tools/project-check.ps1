# Pebble Hedz development preflight.
# Read-only: this script does not modify the repository.

$ErrorActionPreference = "Stop"

Write-Host "=== Pebble Hedz Project Check ==="
Write-Host ""

Write-Host "Repository:"
git rev-parse --show-toplevel
Write-Host ""

Write-Host "Branch and status:"
git status --short --branch
Write-Host ""

Write-Host "Diff integrity:"
git diff --check
Write-Host ""

Write-Host "Modified files:"
git diff --name-only
Write-Host ""

Write-Host "Staged files:"
git diff --cached --name-only
Write-Host ""

Write-Host "Recent commits:"
git --no-pager log --oneline -5
