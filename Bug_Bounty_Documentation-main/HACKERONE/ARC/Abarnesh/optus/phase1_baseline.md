# Phase 1 — Baseline: Optus AI Search Public Endpoint

**Date**: 2026-09-23  
**Tester**: BUGCROWD: <MY_BUGCROWD_USERNAME>  
**Scope**: `gateway.optus.com.au` (single host, no subdomains)

---

## Target

| Field | Value |
|-------|-------|
| URL | `https://gateway.optus.com.au/api/ai-search-public/search/v1` |
| Method | POST |
| Auth mechanism | `x-apikey` (static, client-embedded) |
| Personal token used | N/A — public endpoint, no Bearer token required |

> **Key observation**: The captured endpoint is `/ai-search-public/search/v1`,
> **not** the authenticated `/ai-search/search/v1` referenced in the original hypothesis.
> The x-apikey value is a static, client-side API key embedded in the Optus web
> application — not a personal credential.

---

## Baseline Request (Auth/Cookies Redacted)

### Attempt 1 — Minimal body

```http
POST /api/ai-search-public/search/v1 HTTP/2
Host: gateway.optus.com.au
Content-Type: application/json
x-apikey: <REDACTED>
Origin: https://www.optus.com.au
Referer: https://www.optus.com.au/
User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36

{
  "channel": "OCA",
  "context": {},
  "query": "internet not working",
  "queryId": "53749cd4-134c-4f3e-85e9-25a11b2ff53a",
  "sessionId": ""
}
```

### Attempt 2 — With context fields

```json
{
  "channel": "OCA",
  "context": { "currentPage": "landing", "customerSegment": "CONSUMER" },
  "query": "internet not working",
  "queryId": "53749cd4-134c-4f3e-85e9-25a11b2ff53a",
  "sessionId": ""
}
```

---

## Responses

### Both Attempts

| Field | Attempt 1 | Attempt 2 |
|-------|-----------|-----------|
| HTTP Status | **400** | **400** |
| Response body | *(empty)* | *(empty)* |
| Content-Length | 0 | 0 |
| Response time | ~565ms | ~571ms |
| Server | Apache/2.4.65 + OpenSSL/1.0.2k-fips | same |

---

## Diagnosis: Akamai Bot Manager Block

Both attempts returned HTTP 400 with **zero-byte empty body**.
This is the signature of **Akamai Bot Manager silently rejecting** non-browser requests.

**Evidence:**
1. `server-timing: ak_p` header — confirms Akamai edge
2. `ak_bmsc` cookie issued in browser session — Bot Manager challenge cookie
3. `bm_sz` cookie — Bot Manager session token  
4. Empty 400, no error body — Akamai silent block (not an application error)
5. Successful browser request had `content-length: 125`; tool request lacks
   valid bot manager cookies and matching TLS JA3 fingerprint

**Bot Manager validates:**
- TLS JA3/JA4 fingerprint (browser vs scripted tool)
- `ak_bmsc` / `bm_sz` cookie validity
- Behavioral signals
- `sec-ch-ua` header consistency

---

## Baseline Status

| Check | Result |
|-------|--------|
| Baseline reproducible from automated tool? | ❌ WAF blocked |
| Endpoint confirmed to exist (200 in browser)? | ✅ Yes |
| Auth mechanism confirmed? | ✅ x-apikey (static, client-embedded) |
| Personal credentials needed? | ❌ No (public endpoint) |
| Phases 2–5 can proceed from tool? | ❌ Requires browser session cookies |

---

## Next Steps to Unblock

### Option A — Capture full cookie jar from DevTools
From DevTools → Application → Cookies → optus.com.au, copy:
- `ak_bmsc`
- `bm_sz`  
- `dtCookiesg8g5ivs`

Include these in tool requests. Valid ~2h.

### Option B — Browser proxy intercept (Burp/ZAP)
Route real Chrome through Burp; replay modified requests from Burp.
Preserves TLS fingerprint and cookies automatically.

### Option C — Playwright headless browser
Drive Chrome to trigger bot challenge, extract cookies, fire modified requests.

---

## Passive Observations (No Security Finding)

### Architecture

```
Browser → Akamai Edge (Bot Manager + WAF) → Apache/2.4.65 → AI Search Backend
```

- Origin: Apache/2.4.65, OpenSSL/1.0.2k-fips (FIPS mode)
- Origin latency: ~3646ms (from browser Server-Timing)  
- Edge latency: ~40ms  
- CDN: MISS on all responses (dynamic, not cached — expected)
- CORS: `Access-Control-Allow-Origin: https://www.optus.com.au` (strict)
- Credentials: `Access-Control-Allow-Credentials: true`

### Missing Security Headers (Informational Only — Not Reportable)

Observed on the 400 (edge) response path only. The 200 browser response
showed `x-content-type-options: nosniff` — headers are added by origin, not edge.

| Header | 400 path | 200 path (browser) |
|--------|----------|-------------------|
| X-Frame-Options | Missing | Unknown |
| X-Content-Type-Options | Missing | Present (nosniff) |
| Content-Security-Policy | Missing | Unknown |
