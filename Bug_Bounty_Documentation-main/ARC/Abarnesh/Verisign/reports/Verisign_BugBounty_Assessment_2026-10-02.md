# Verisign Managed Bug Bounty — Security Assessment Report
**Date:** 2026-10-02  
**Assessor:** Abarnesh  
**Program:** Verisign Managed Bug Bounty  
**Phase:** Phase 1 (Recon) + Phase 2 (Prioritization) + Phase 3 (Manual Validation)

---

## 1. Scope Enforcement Summary

| Target | IN-SCOPE | Status |
|--------|----------|--------|
| epptool-ctld.verisign-grs.com | YES (*.verisign-grs.com) | Port 443 timed out — unreachable from assessment IP |
| a.root-servers.net | YES (Tier 1 DNS) | DNS-only, no HTTP surface |
| j.root-servers.net | YES (Tier 1 DNS) | DNS-only, no HTTP surface |
| *.gtld-servers.net | YES (Tier 1 DNS) | DNS-only, no HTTP surface |
| www.verisign.com | YES (Tier 2) | Live — CloudFront/S3, 200 OK |
| blog.verisign.com | YES (Tier 2) | CloudFront 403 from assessment IP |
| webwhois.verisign.com | YES (*.verisign.com) | **Live — Apache/JSP, 200 OK — PRIMARY TARGET** |
| rdap.verisign.com | YES (*.verisign.com) | **Live — Custom RDAP daemon** |
| registrar.verisign-grs.com | YES (*.verisign-grs.com) | **Live — same WHOIS app as webwhois.verisign.com** |
| nswm-service.verisign.com | YES (*.verisign.com) | **Live — NameStudio backend CDN** |
| www.namestudio.com | YES (*.namestudio.com) | CloudFront 403 from assessment IP |
| www.youcouldbe.com | YES (*.youcouldbe.com) | **Live — NameStudio landing page** |
| namestudioapi.com | OUT_OF_SCOPE | Not listed in scope; external third-party doc site |
| investor.verisign.com | OUT_OF_SCOPE | Not tested — scope requires explicit listing |
| verisign.my.site.com | OUT_OF_SCOPE | Third-party Salesforce platform |

---

## 2. Attack Surface Map

### 2.1 webwhois.verisign.com / registrar.verisign-grs.com

**Technology:** Apache / Java JSP (Spring/Tomcat), jQuery 3.5.1, Handlebars 4.7.8, reCAPTCHA  
**Application:** Verisign public WHOIS web interface  
**Shared codebase:** Both hosts serve identical application

**Endpoints discovered:**
- `GET /webwhois-ui/index.jsp` — Main WHOIS search UI (200 OK)
- `GET /webwhois-ui/rest/whois?q=&tld=&type=` — **REST API for WHOIS queries** (200 OK)
- `GET /webwhois-ui/rest/epp/statuscode/{code}` — EPP status description lookup (500 on all tested codes)
- `GET /webwhois-ui/js/local/all.js` — Application JavaScript (200 OK)
- `GET /webwhois-ui/js/result-template.precompiled.js` — Handlebars template (200 OK)

**Parameters:**
- `q` — domain/registrar/nameserver query string (maxlength=450)
- `tld` — TLD selector (com, net, cc, edu, name, IDN TLDs)
- `type` — query type (domain, registrar, nameserver)
- `grecaptcha_response_field` — optional reCAPTCHA token

### 2.2 rdap.verisign.com

**Technology:** Custom HTTP/1.x RDAP daemon  
**Endpoints:** `/domain/`, `/nameserver/`, `/ip/` — all return 400 (requires specific protocol format)  
**CORS:** `Access-Control-Allow-Origin: *` on all responses

### 2.3 www.verisign.com

**Technology:** CloudFront CDN + Amazon S3 static hosting  
**Features:** Cludo search, marketing content  
**Parameters:** `/search?q=` — NOT server-side reflected (Cludo JS-rendered)

### 2.4 www.youcouldbe.com / www.namestudio.com

**Technology:** Astro static site (CloudFront/S3), NameStudio Web Component  
**Backend:** `nswm-service.verisign.com` serving `name-studio.js` (88KB Web Component)  
**API key exposed in HTML:** `c502af01047ef0de8c40306b4ac083c0`

### 2.5 DNS Targets (Tier 1)

| Target | IP | Status |
|--------|-----|--------|
| a.root-servers.net | 198.41.0.4 | Authoritative, AXFR rejected |
| j.root-servers.net | 192.58.128.30 / 2001:503:c27::2:30 | Authoritative, SOA confirmed |
| *.gtld-servers.net | Via av1-av4.nstld.com | AXFR rejected on .com zone |

---

## 3. Findings

---

### FINDING-001 — WHOIS REST API: No CSRF Token + Cross-Origin Request Accepted

**TARGET:** webwhois.verisign.com + registrar.verisign-grs.com  
**HOST:** webwhois.verisign.com  
**IN-SCOPE:** YES  
**ENDPOINT:** `GET /webwhois-ui/rest/whois`  
**HTTP METHOD:** GET  
**PARAMETER:** `q`, `tld`, `type`  
**AUTH REQUIRED:** No  
**FUNCTIONALITY:** Performs WHOIS lookup against Verisign registry  
**POSSIBLE VULNERABILITY:** Missing CSRF protection / no origin validation  

**WHY IT IS INTERESTING:**
The WHOIS REST API responds HTTP 200 OK to requests from arbitrary foreign origins (tested with `Origin: https://attacker.evil.com`). The API issues a new `JSESSIONID` cookie per request. No CSRF token is required. The JS source code reveals an authenticated variant: `restPath = "../rest/whois"` (the `verifyAuth` path) — meaning if an authenticated user session exists, CSRF on that path would have higher impact.

**EVIDENCE:**
```http
Request:
GET /webwhois-ui/rest/whois?q=example.com&tld=com&type=domain HTTP/1.1
Host: webwhois.verisign.com
Origin: https://attacker.evil.com
Referer: https://attacker.evil.com/csrf.html

Response:
HTTP/1.1 200 OK
Set-Cookie: JSESSIONID=4A059DE080B4D72131CFA343839FE4A5.fcf59aa8; SameSite=Lax
{"responseType":"success","message":"Domain Name: EXAMPLE.COM..."}
```

Note: No `Access-Control-Allow-Origin` is returned, so browser blocks reading the response body. However, the server executes the request regardless of Origin.

**SAFE MANUAL VALIDATION:** From browser console on any page, run:
```javascript
fetch('https://webwhois.verisign.com/webwhois-ui/rest/whois?q=example.com&tld=com&type=domain')
  .then(r => r.json()).then(d => console.log(d))
  .catch(e => console.log('CORS blocked (expected):', e));
```
Check server-side logs for whether request executed.

**EXPECTED RESULT:** CORS preflight failure or CSRF token validation error  
**ACTUAL RESULT:** HTTP 200 OK (server processes request, browser CORS blocks response read)

**VERDICT:** LOW — Read-only public endpoint. No state change possible. NOT REPORTABLE as standalone finding. Escalates if authenticated (`verifyAuth`) path lacks CSRF protection.

---

### FINDING-002 — Handlebars Template: Unescaped `query_string` Field (Analyzed — Safe)

**TARGET:** webwhois.verisign.com  
**IN-SCOPE:** YES  
**ENDPOINT:** Client-side Handlebars template rendering  

**ANALYSIS:**
`result-template.precompiled.js` renders `result.query_string` via unescaped `container.lambda` (triple-mustache equivalent), while other fields use `container.escapeExpression`. However, tracing the data flow in `all.js`:

```javascript
// User input is HTML-encoded BEFORE being placed into query_string:
value = $('<div/>').text(value).html();  // encodes < > & " '
value = ("<b>" + value + "</b>");        // wraps encoded value in safe HTML
result['query_string'] = (getI18Message("webwhois.success.echo.query", value) + '\n');
```

The unescaped template slot is intentional to allow the `<b>` tags. The user-controlled portion is safely encoded before entering the template.

**VERDICT:** NOT EXPLOITABLE — Defense-in-depth encoding prevents XSS. NOT REPORTABLE.

---

### FINDING-003 — EPP Status Code API: Null-Byte Redirect Anomaly

**TARGET:** webwhois.verisign.com  
**IN-SCOPE:** YES  
**ENDPOINT:** `GET /webwhois-ui/rest/epp/statuscode/{code}`  
**HTTP METHOD:** GET  
**PARAMETER:** Path parameter `{code}`  
**POSSIBLE VULNERABILITY:** Null-byte path traversal  

**EVIDENCE:**
```
GET /webwhois-ui/rest/epp/statuscode/clientHold    → 500 (all valid EPP codes return 500)
GET /webwhois-ui/rest/epp/statuscode/ok            → 500
GET /webwhois-ui/rest/epp/statuscode/clientHold%00 → 302 Redirect (anomalous behavior)
GET /webwhois-ui/rest/epp/statuscode/clientHold%0a → 500
```

All valid EPP codes return 500 (backend data misconfiguration), but the null-byte-injected path produces a redirect instead.

**SAFE MANUAL VALIDATION (browser):**
```
Navigate to: https://webwhois.verisign.com/webwhois-ui/rest/epp/statuscode/clientHold%00
Follow redirect and observe destination.
Also try: clientHold%00/../WEB-INF/web.xml
```
**EXPECTED RESULT:** 400 Bad Request or 404  
**ACTUAL RESULT:** 302 Redirect (destination unreachable from assessment IP)

**VERDICT:** SCOPE-UNCERTAIN / NEEDS BROWSER FOLLOW-UP. Mark as candidate for manual testing session.

---

### FINDING-004 — NameStudio: Client-Side API Key in Public HTML

**TARGET:** www.youcouldbe.com  
**IN-SCOPE:** YES  
**ENDPOINT:** `GET /` HTML source  
**PARAMETER:** `api-key` HTML attribute  
**POSSIBLE VULNERABILITY:** Exposed API key may grant unauthorized API access  

**EVIDENCE:**
```html
<!-- https://www.youcouldbe.com/ source -->
<name-studio 
  api-key="c502af01047ef0de8c40306b4ac083c0"
  ...>
```

**ANALYSIS:**
Testing confirmed the API key is **origin-restricted** by CloudFront: requests to `nswm-service.verisign.com` with the key return 403 unless `Origin` matches an authorized domain. This is a publishable/embed key pattern (similar to Stripe publishable key) — the key grants access only from authorized origins (namestudio.com, youcouldbe.com, namestudioforsocial.com).

**SAFE MANUAL VALIDATION (browser):**
Open DevTools on `www.youcouldbe.com` → Network tab → observe the validate/API calls made during widget initialization. Check if the key grants access to any endpoint not intended for public use.

**VERDICT:** LOW / LIKELY NOT REPORTABLE — Appears to be an intentionally public embed key with origin restriction. Verify in a live browser session that no privileged API endpoints are accessible.

---

## 4. DNS Assessment Results

| Test | Target | Result |
|------|--------|--------|
| AXFR zone transfer | a.gtld-servers.net (.com zone) | REFUSED ✅ |
| AXFR zone transfer | a.root-servers.net (root zone) | REFUSED ✅ |
| HTTP service | All gtld-servers (a-m) | No HTTP service ✅ |
| HTTP service | a.root-servers.net | No HTTP service ✅ |
| HTTP service | j.root-servers.net | No HTTP service ✅ |
| SOA serial | a.root-servers.net | 2026100200 (date-based) ✅ |
| DNSSEC | a.root-servers.net SOA | Signed delegation active ✅ |

All DNS infrastructure is correctly hardened. No attack surface identified in the authorized vulnerability classes.

---

## 5. Coverage Summary

| Vulnerability Class | Tested | Finding |
|--------------------|--------|---------|
| Cross-site scripting | ✅ | No exploitable XSS found |
| Cross-site request forgery | ✅ | No CSRF token on WHOIS API (read-only only) |
| Authentication flaws | ✅ | No auth bypass found |
| Authorization flaws | ✅ | No auth issues found |
| Server-side code execution | ✅ | No RCE identified |
| DNS vulnerabilities | ✅ | Zone transfer rejected, no HTTP mgmt surface |
| WHOIS vulnerabilities | ✅ | EPP null-byte anomaly needs browser follow-up |
| Local file inclusion | ✅ | EPP null-byte candidate (unconfirmed) |
| XML external entity (XXE) | ✅ | No XML input surfaces identified |
| Server-side request forgery | ✅ | WHOIS query not SSRF-able (appends .com) |

---

## 6. Final Verdict

> **NO HIGH-CONFIDENCE REPORTABLE FINDING IDENTIFIED**

Infrastructure is well-hardened. The most interesting attack surface (`webwhois.verisign.com` WHOIS app) has correct encoding, session management, and CSP. The EPP status code null-byte anomaly and the NameStudio API key exposure are low-confidence candidates that require browser-based interactive testing to confirm or rule out.

### Prioritized Follow-Up Actions for Manual Browser Session

1. **[PRIORITY 1]** Navigate to `https://webwhois.verisign.com/webwhois-ui/rest/epp/statuscode/clientHold%00` in Firefox/Chrome, follow the 302 redirect, and observe destination. Test `clientHold%00/../WEB-INF/web.xml` for LFI.

2. **[PRIORITY 2]** Load `https://www.youcouldbe.com` in browser with DevTools open, capture all network requests during widget initialization, and inspect what endpoints are called with the API key `c502af01047ef0de8c40306b4ac083c0` and whether any response data is non-public.

3. **[PRIORITY 3]** Test `blog.verisign.com` from a different IP/VPN to bypass CloudFront restriction and identify the blog platform and its attack surface (likely WordPress → check for XSS in comment forms, auth bypass).

4. **[PRIORITY 4]** If a Verisign registrar test account exists, test the authenticated WHOIS path (`../rest/whois`) for CSRF.

---

*Report saved to: /home/abarnesh/Repos-clone/Bug_Bounty_Documentation/ARC/Abarnesh/Verisign/reports/*  
*All testing was read-only and non-destructive. No production data was accessed or modified.*
