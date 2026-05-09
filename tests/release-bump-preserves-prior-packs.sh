#!/usr/bin/env bash
# Simulation test for release-pack.yml's "Bump packs.json on main"
# step. Builds a tiny git repo with a packs.json that has two packs
# (older=real-sha, newer=PLACEHOLDER), simulates the workflow's
# checkout-main-then-bump logic, and asserts the older pack's real
# sha is preserved while the newer pack's sha gets bumped.
#
# The earlier (broken) cp-packs.json-from-tag pattern would have
# clobbered older's real sha back to PLACEHOLDER.

set -Eeuo pipefail
IFS=$'\n\t'

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

cd "$work"
git init -q -b main
git config user.email "test@local"
git config user.name  "test"

cat > packs.json <<'JSONEOF'
{
  "schema_version": 1,
  "packs": {
    "older": {
      "tarball_url": "https://example.com/older.tar.gz",
      "tarball_sha256": "PLACEHOLDER",
      "tarball_size_bytes": 0,
      "version": "0.1.0"
    },
    "newer": {
      "tarball_url": "https://example.com/newer.tar.gz",
      "tarball_sha256": "PLACEHOLDER",
      "tarball_size_bytes": 0,
      "version": "0.1.0"
    }
  }
}
JSONEOF
git add packs.json
git commit -q -m "initial: both packs PLACEHOLDER"

# Simulate older's release: bump older's sha to a real value on main.
git checkout -q main
python3 - <<PYEOF
import json
with open("packs.json") as f: d = json.load(f)
d["packs"]["older"]["tarball_sha256"] = "a" * 64
d["packs"]["older"]["tarball_size_bytes"] = 12345
with open("packs.json", "w") as f: json.dump(d, f, indent=2); f.write("\n")
PYEOF
git add packs.json
git commit -q -m "release: older v0.1.0 (sha=aaaa...)"

# Now simulate newer's release. The TAG was created earlier (before
# older's release commit), so checking out the tag would show
# older=PLACEHOLDER. The OLD broken workflow:
#   1. checkout tag (older=PLACEHOLDER, newer=PLACEHOLDER)
#   2. update working tree: bump newer's sha
#   3. cp packs.json /tmp/_packs.json.bumped (older=PLACEHOLDER, newer=real)
#   4. checkout main (older=real, newer=PLACEHOLDER)
#   5. cp /tmp/_packs.json.bumped packs.json (CLOBBERS older back to PLACEHOLDER)
# That's the bug.
#
# The NEW workflow: checkout main FIRST, then bump newer's sha on top
# of main's current state. older's real sha is preserved.

# Capture main's tip = the "tag" commit will be the initial commit (older still PLACEHOLDER there).
TAG_COMMIT=$(git rev-parse HEAD~1)

# Pretend we're in detached HEAD on the tag.
git checkout -q "$TAG_COMMIT"
# (detached at the initial-PLACEHOLDER state)

# === NEW WORKFLOW LOGIC ===
git checkout -q main           # switch to main FIRST
# (now we have older=real-sha, newer=PLACEHOLDER)

# Apply newer's bump on top of main's current state.
python3 - <<PYEOF
import json
with open("packs.json") as f: d = json.load(f)
d["packs"]["newer"]["tarball_sha256"] = "b" * 64
d["packs"]["newer"]["tarball_size_bytes"] = 67890
with open("packs.json", "w") as f: json.dump(d, f, indent=2); f.write("\n")
PYEOF

# Assert: older still has its real sha; newer now has its real sha.
python3 - <<PYEOF
import json, sys
with open("packs.json") as f: d = json.load(f)
older_sha = d["packs"]["older"]["tarball_sha256"]
newer_sha = d["packs"]["newer"]["tarball_sha256"]
errors = []
if older_sha != "a" * 64:
    errors.append(f"FAIL: older sha was clobbered: got {older_sha!r}, expected 'aaaa...' (this is the regression we are guarding against)")
if newer_sha != "b" * 64:
    errors.append(f"FAIL: newer sha was not bumped: got {newer_sha!r}, expected 'bbbb...'")
if errors:
    for e in errors: print(e, file=sys.stderr)
    sys.exit(1)
print("OK: older preserved (sha=aaaa...), newer bumped (sha=bbbb...)")
PYEOF
