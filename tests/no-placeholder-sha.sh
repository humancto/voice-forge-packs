#!/usr/bin/env bash
# Regression guard: refuse to ship packs.json if any pack has a
# PLACEHOLDER tarball_sha256 or zero tarball_size_bytes.
#
# This caught a real bug: the release-pack.yml workflow's
# stash-checkout-cp pattern was clobbering prior packs' sha bumps
# back to PLACEHOLDER (because the stash started from a tag's stale
# packs.json). User-visible failure was:
#
#   $ voiceforge pack install trump
#   voiceforge pack: sha256 mismatch (expected PLACEHOLDER, got <real>)
#
# Run from the repo root:
#   bash tests/no-placeholder-sha.sh

set -Eeuo pipefail
IFS=$'\n\t'

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INDEX="$REPO_ROOT/packs.json"

[[ -f "$INDEX" ]] || { echo "FAIL: missing $INDEX"; exit 1; }

python3 - <<'PYEOF'
import json
import sys

with open("packs.json") as f:
    data = json.load(f)

errors = []
for name, p in data.get("packs", {}).items():
    sha = p.get("tarball_sha256", "")
    sz = p.get("tarball_size_bytes", 0)
    if sha == "PLACEHOLDER" or not sha:
        errors.append(f"{name}: tarball_sha256 is {sha!r} (must be a real 64-char hex)")
    elif len(sha) != 64:
        errors.append(f"{name}: tarball_sha256 has wrong length {len(sha)} (must be 64)")
    if not sz or sz <= 0:
        errors.append(f"{name}: tarball_size_bytes is {sz} (must be > 0)")

if errors:
    print("FAIL: packs.json has invalid pack entries:")
    for e in errors:
        print(f"  - {e}")
    print("")
    print("If a release-pack.yml run produced this, rerun the release for")
    print("the affected pack (the workflow's stash-checkout-cp pattern can")
    print("clobber prior packs' sha bumps back to PLACEHOLDER).")
    sys.exit(1)

print(f"OK: all {len(data.get('packs', {}))} packs have real sha256 + size")
PYEOF
