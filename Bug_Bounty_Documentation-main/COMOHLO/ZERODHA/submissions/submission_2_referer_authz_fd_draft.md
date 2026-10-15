# Zerodha BBP — Submission Report #2 (DRAFT — NOT SUBMITTED)

## Referer-Based Access Control on fd.zerodha.com APIs (CWE-290)

**Target:** Zerodha FD (Moderate engagement)
**URL:** https://fd.zerodha.com/api/auth/v1/public/partner/config, https://fd.zerodha.com/api/core/v1/templates/list
**Severity (proposed):** P5 (Informational) — submit only if program accepts hardening reports
**Tools Used:** HexStrike MCP (gau/waybackurls), JS bundle analysis, curl
**Date Found:** 2026-10-05
**Status:** ✅ VERIFIED VIA CURL / ⚠️ LOW IMPACT — see "Submit or hold?" below

---

## Description

The fd.zerodha.com API (white-label "Blostem" FD platform) gates several
unauthenticated API groups using **only the client-controlled `Referer` header**
instead of server-side authorization (CWE-290: Authentication Bypass by
Alternate Name / Channel). Additionally, the `x-auth-org` partner header is
**ignored** on `/api/core/v1/*`, and several responses carry **duplicated,
conflicting security headers** — signs of stacked/legacy middleware.

This was found by extracting the API surface from the app's JS bundles
(index-C4t3wmFA.js: `baseURL:"https://fd.zerodha.com/api"+e`, path vars
`auth/v1`, `core/v1`) and replaying the endpoints with spoofed headers.

## Steps to Reproduce

### 1. Referer is the only gate on partner/issuer data

Without a Referer (blocked):
```
$ curl -s "https://fd.zerodha.com/api/core/v1/templates/list"
{"success":false,"code":403,"message":"Invalid referer",...}
```

With any curl-controlled Referer (allowed — no browser, no session, no CORS):
```
$ curl -s "https://fd.zerodha.com/api/core/v1/templates/list" \
    -H "Referer: https://fd.zerodha.com/"
{"success":true,"data":[{"id":"968d34fe-cf88-464c-8722-c7a032d3602d",
  "partnerId":"06052d8a-...","issuerId":"013962ad-...",
  "aboutIssuer":{"pg":{"nb":true,"upiIntent":true,...,
  "nbMinimumAmount":84999,"upiMaximumAmount":500000}}, ...}]}
```
Same bypass works on `/api/auth/v1/public/partner/config` (returns partner
UUIDs, branding config, S3 asset paths).

The allowlist itself is strict (good): `zerodha.com`, `sub.fd.zerodha.com`,
`fd.zerodha.com.attacker.example`, `fd.zerodha.com@attacker.example` all 403.

### 2. x-auth-org partner header is ignored on /api/core/v1/*

```
$ curl -s "https://fd.zerodha.com/api/core/v1/templates/list" \
    -H "Referer: https://fd.zerodha.com/" \
    -H "x-auth-org: 11111111-2222-3333-4444-555555555555"
{"success":true,"data":[{"partnerId":"06052d8a-..."}]}   ← real partner data anyway
```

### 3. Duplicated/conflicting security headers on error responses

```
strict-transport-security: max-age=15552000     ← twice
referrer-policy: no-referrer                    ← twice
x-frame-options: SAMEORIGIN                     ← conflicts with:
x-frame-options: DENY
x-content-type-options: nosniff                 ← twice
x-xss-protection: 0                             ← conflicts with:
x-xss-protection: 1; mode=block
```

## Impact (honest assessment)

- **No cross-origin read:** responses do NOT reflect attacker `Origin` in
  `Access-Control-Allow-Origin`, so this is **not** a CORS issue and cannot be
  chained from a victim's browser. It only lowers the bar for **unauthenticated,
  scripted enumeration** of partner/issuer configuration data.
- **No money-path bypass:** all sensitive endpoints verified to require a real
  session (`validate-pan/start`, `check-existing-customer`, `verify-pan`,
  `otp/email/send`, `assisted-journey/share-via-sms` → 401 "Please authenticate").
- Net effect: client-controlled-header access control is fragile by design and
  is one config change away from becoming a real bypass (CWE-290 hardening).

## Recommendation

1. Replace Referer-based gating with server-side session/entropy checks
   (signed short-lived token issued on page load, validated server-side).
2. Enforce `x-auth-org` server-side where the JS sends it, or drop it.
3. De-duplicate security-header middleware (conflicting `x-frame-options`
   values are parsed differently by different clients).

---

## Authenticated verification round (2026-10-06, own account)
To rule out stronger impact, authenticated testing was performed on the reporter's own
account only. Results (full log in recon/hexstrike_run_20261005/SUMMARY.md):

- OAuth `request_token` replay: **401 — single-use enforced** (no token interception)
- Session cookie tampering: 401; real session is HttpOnly (only `public_token` helper
  cookie lacks HttpOnly — separate hardening note)
- Money paths (`validate-pan/*`, `verify-pan`, `check-existing-customer`,
  `share-via-sms`, `otp/email/send`): session + input validation enforced
- Agent role grant (`POST /user/sso/login`): 404 for non-agent session — locked
- Journey/FD objects keyed by UUID + session-scoped: no IDOR found
- Cross-brand Referer (`partners.blostem.com`) rejected: 403
- New (same P5 class): pre-booking calculator `POST /asset/fixed-deposit/calculation/`
  computes quotes below UI minimum (₹500 vs ₹1000) and above UI maximum (₹20L) —
  server skips deposit bounds the UI enforces (CWE-20, no booking side effects)

**Conclusion:** no P2/P3 impact chain exists; the Referer-only access control finding
stands as the reportable P5 with verified non-escalability.

---

## Submit or hold? (decision)

- Finding is **real and verified**, but P5/informational. Com Olho's acceptance
  rate is 0.46% and the previous P3 was marked duplicate; a P5 with no
  cross-origin impact may be rejected as "no impact".
- **Stronger chained findings exist but need a logged-in session** (see
  recon/hexstrike_run_20261005/SUMMARY.md → Next Steps):
  1. Kite OAuth `redirect_uri` on fd accepts arbitrary *.zerodha.com
     subdomains → open-redirect / token-interception test while logged in.
  2. `POST /api/auth/v1/assisted-journey/share-via-sms` — session-gated, but
     then test for missing rate limiting / arbitrary target phone number
     (SMS sending under the Zerodha brand).
  3. `consent/request-callback` — real mount path unknown; capture while
     browsing logged-in, then test callback spam.

**Recommendation:** hold this report; complete the authenticated tests; submit
the Referer finding only as a supporting section of a stronger chain report.
