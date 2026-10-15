# Zerodha BBP — HexStrike Session Summary (2026-10-05)

**Engine:** HexStrike AI v6.0.0 (REST API on port 8888, driven via curl)
**Tools used:** subfinder, waybackurls/gau, katana archives, curl repeater, nuclei v10.5.0
**Raw artifacts:** this folder (subfinder_raw.json, *.gau.txt, fdjs/, fdmaps/, nuclei_scan.json)

---

## Context
- `submission_1_cors_varsitylive.md` was **rejected as duplicate** by Com Olho.
- Goal: fresh, non-duplicate finding on one of the 6 in-scope targets.

## Recon Results

### Subdomains (85 via subfinder -all)
6 in-scope: sensibull, smallcase, streak, fd, varsitylive, zerodha.com/varsity.
`staging.sensibull.zerodha.com` no longer resolves (dead DNS).

### Verified Findings (this session)

| # | Finding | Severity | Status |
|---|---------|----------|--------|
| 1 | fd.zerodha.com `/api/auth/v1/public/partner/config` + `/api/core/v1/templates/list` and all `/api/core/v1/*` protected by **Referer header check only** (CWE-290). Spoofable via curl; **no CORS impact** (no ACAO reflection) | P5/low | CONFIRMED (curl) |
| 2 | fd.zerodha.com **ignores `x-auth-org` partner header** on `/api/core/v1/*` — random UUID returns partner data | P5/low | CONFIRMED (curl) |
| 3 | fd.zerodha.com error responses: **duplicate security headers** (`Strict-Transport-Security` twice, `Referrer-Policy` twice, `X-Frame-Options` SAMEORIGIN+DENY conflicting) — header-injection smell in middleware | P5/informational | CONFIRMED (curl) |
| 4 | Open Redirect on fd.zerodha.com Kite OAuth `redirect_uri` (arbitrary subdomain accepted) | — | NOT CONFIRMED (needs logged-in flow) |
| 5 | `partners.blostem.com` — same platform, hosts other banks (AU, Unity); out of Com Olho scope | — | intel only |
| 6 | sensibull main bundle lists internal hosts: `api.qa.sensibull.com`, `*.staging.sensibull.xyz`, `api.sensibull.test` — all out of scope | — | intel only |

### Properly Secured (do not submit)
- All fd money-path endpoints (`validate-pan/start`, `check-existing-customer`, `verify-pan`, `otp/email/send`) → **401 without session**.
- Referer allowlist is **strict** (exact host match; `zerodha.com`, sub.*.zerodha.com, substring tricks all 403).
- Nuclei (medium+high+critical, 6 targets): **0 findings**.
- S3 `blostem-assets` listing: AccessDenied. Varsitylive bucket guesses: NoSuchBucket.
- Source-map probe: SPA fallback serves index.html for `/assets/*.map` (fake 200) — no real maps leaked.

## Unauthenticated fd API surface (auth/v1, Referer-gated)
- `GET /api/auth/v1/public/partner/config`
- `GET /api/auth/v1/core/v1/templates/list` (also `GET /api/core/v1/templates/list`)
- `GET /api/auth/v1/utkarsh/validate-pan/start|complete`, `/suryoday/...`, `/shivalik/...`, `POST /api/core/v1/unity-new/verify-pan(/complete)`
- `POST /api/auth/v1/assisted-journey/share-via-sms` → 401 (session required) ✓
- `POST /api/auth/v1/consent/request-callback` → 404 at both prefixes (path/mount unknown)
- Auth group (`user/verify-mobile`, `otp/verify`, `kyc/pan-details`, `kyc/aadhar/web`, ...) requires session ✓

## Next Steps (need logged-in account)
1. **Open redirect / OAuth token interception** on fd Kite login (`redirect_uri` accepts any *.zerodha.com subdomain — test non-zdomain once authenticated).
2. **Assisted-journey SMS/email sender** (`share-via-sms`) — with a session: test for missing rate limit / arbitrary target phone (SMS spoofing under Zerodha brand).
3. **request-callback** — find real mount path via live browsing, then test spam/phone-number spraying.
4. Business-logic on `/utkarsh/update-fd-details` and payment amount fields (enableReversePenny:true hints manual payment matching).

---

## Authenticated Session Round: 2026-10-06 (owner's own account, page-context testing)
Session mapped: HttpOnly session cookie (real auth) + JS-readable `public_token` (32-char, no HttpOnly flag) + `isLogin` flag. OAuth: `GET /api/auth/v1/user/zerodha/login?request_token=...` sets cookies; replay returns 401.

### Tested & SECURE (evidence for report credibility)
| Test | Result |
|---|---|
| OAuth `request_token` replay (second use) | 401 `{loggedIn:false}` — **single-use enforced** ✓ |
| Session auth via `public_token` cookie alone (curl) | 401 — real session is HttpOnly ✓ |
| Token tamper (last char) | 401 ✓ |
| `share-via-sms`, `otp/email/send` w/ session | 400 validation (input-gated) ✓ |
| `POST /user/sso/login` (agent role grant) | 404 for non-agent session — locked ✓ |
| Journey endpoints w/ random fd UUIDs | 404/400 not-found (session-scoped) ✓ |
| `/api/core/v1/*` Referer gate vs partners.blostem.com | 403 — cross-brand rejected ✓ |

### New weak signals (P5, supporting material only)
1. **Calculator skips deposit bounds**: `POST /asset/fixed-deposit/calculation/` computes maturity for ₹500 (below UI min ₹1000) and ₹20,00,000 (above UI max) — server-side validation gap on a pre-booking endpoint (CWE-20, low: booking flow likely re-validates).
2. **`public_token` cookie not HttpOnly** (readable via `document.cookie`) — XSS-hardening gap only.
3. **`vkyc/status/<uuid>` returns 500** leaking upstream text "Unable to connect to bank..." — internal error disclosure.
4. **Verbose Joi errors** on 400s (exact field-rule reflection) — minor.

### Bottom line
No P2/P3 found in authenticated scope. Money paths, agent roles, OAuth, journey objects all properly protected. Best submittable = **P5 chain: Referer-only access control (CWE-290) + ignored x-auth-org + duplicate security headers**, now backed by authenticated evidence that nothing stronger was missed. Test account used only for own-data reads; no FDs created, no messages sent, no other users touched.
