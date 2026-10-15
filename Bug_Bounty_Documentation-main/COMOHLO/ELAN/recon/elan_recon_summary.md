# ELAN Limited — Recon Summary (Com Olho, Private)

Date: 2026-10-08
Tester: prasanth (prasanthselvaraj1511_e024ae04)
HexStrike: healthy on :8888 (uptime ~5.8 days). All tool runs via HexStrike REST API (`POST /api/tools/{tool}`), low-traffic settings.

## Scope discipline

- **In scope (only target):** `http://www.elanlimited.com` (Web, 3.110.194.222/32, AWS ap-south-1)
- **Out of scope — NOT touched:** helpdesk.elanlimited.com, elannew.elanlimited.com, testapi.elanlimited.com, elan10.remserp.com, 103.21.187.42, 103.248.85.186
- Subfinder found many more subdomains (api, uat, dms, sap, elanmiracle, rpestates, webmail, ...) — **none of them were probed** because the program scope lists only www.elanlimited.com.
- Rules followed: read-only GETs, no brute-force, no DoS-style scanning, no user data access, no account creation attempts.

## Tech fingerprint

- Apache 2, HTTP→HTTPS 301, HTTP/2.
- Main site: **custom PHP** (`about-us.php`, `action.php`, `awards.php`, `contact.php`, ...), Bootstrap 5.2.3, Swiper 11, jQuery 3.7.1, GTM.
- One form on homepage → `action.php` (enquiry handler; returns success page for empty POST too — suspected weak validation, but not verifiable read-only, not reported).
- `curl -I`: has X-Frame-Options SAMEORIGIN, nosniff, XSS header. No CSP, no HSTS observed.

## WordPress discovered at /blogs/

- `https://www.elanlimited.com/blogs/` — WordPress (feed generator string: WordPress 7.0.2), Yoast SEO v28.1, plugin **pro-elements v4.1.0** (a nulled/rebranded Elementor Pro clone — noted, not exploited), wp-login.php reachable (200), wp-admin 302→login, admin-ajax.php open (200 on `action=heartbeat`).
- **xmlrpc.php: 403 (hardened).** `/blogs/wp-content/uploads/` listing: 403. `.git/HEAD`: 403. phpinfo/debug.log/wp-config.bak: 404.

## Tools run (HexStrike)

| Tool | Params | Result |
|---|---|---|
| subfinder | `{"domain":"elanlimited.com"}` | 48 subdomains; only www is in scope |
| katana | `{"url":"https://www.elanlimited.com","additional_args":"-d 3 -jc -rl 5 -timeout 10"}` | full site map; found /blogs/ WP install |
| nuclei (root) | severity critical,high,medium, `-rl 10 -c 10` | no findings |
| nuclei (/blogs/, tags wordpress,fuzz) | severity all incl. low | no findings |
| curl (manual) | — | all findings below |

## FINDING (verified): unauthenticated WP username enumeration + REST-block bypass

- `GET /blogs/wp-json/wp/v2/users` → **404** (host blocks pretty REST permalinks)
- `GET /blogs/index.php?rest_route=/wp/v2/users` → **200 JSON** leaking all users (bypasses the block)
  - Users: **id=1 slug `sandeep`** (likely admin), **id=3 slug `ravi-elan`** ("Elan Group")
- `GET /blogs/?author=1` → **301** → `/blogs/author/sandeep/` (classic ID-iteration leak, also works for id=3)
- `/blogs/readme.html` → 200 (WP version disclosure)

Saved response: `/tmp/elan_users.json` (copy into recon/ if needed).

## Leads not pursued (and why)

- `action.php` accepts any POST and always answers "Enquiry sent successfully" — possible mail-header injection, but testing it spams the sales inbox; left alone per no-spam/no-impact rules.
- pro-elements (nulled Elementor Pro) 4.1.0 — exploitation would require state-changing POSTs; out of rules. Worth mentioning to triage only if they ask.
- sitemap.xml: only marketing pages, nothing hidden.
