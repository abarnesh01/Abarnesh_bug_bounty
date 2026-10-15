# eFRAMS3 Passive Recon Report
**Target**: `https://www.outsourcing.optus.net.au/eFRAMS3/`  
**Secondary target**: `https://www.outsourcing2.optus.net.au/eFRAMS3/`  
**Date**: 2026-09-24  
**Method**: Passive observation — direct GET requests only, no auth, no fuzzing, no credentials  
**Engagement**: Optus Managed Bug Bounty (Bugcrowd: optus-mbb-og)

> **Scope note**: `outsourcing.optus.net.au` / `outsourcing2.optus.net.au` fall under
> `*.optus.net.au`. The Bugcrowd program brief covers `*.optus.com.au` explicitly.
> `optus.net.au` is Optus's network/ISP domain — confirm with program owner whether
> this is in-scope before submitting findings.

---

## Architecture Fingerprint (Confirmed)

```
Internet → Akamai Edge (Bot Manager + WAF)
         → Apache reverse proxy (no version on 404 path)
         → Apache Tomcat (Apache-Coyote/1.1 on app paths)
         → Apache Cocoon 2.0.4 (XML publishing pipeline)
         → eFRAMS3 application v3.7.6.0
```

| Layer | Evidence |
|-------|----------|
| CDN/WAF | Akamai (`X-Akamai-Transformed`, `ak_bmsc`, `bm_sz` cookies) |
| Reverse proxy | `Server: Apache` on 404 paths (no version exposed there) |
| App server | `Server: Apache-Coyote/1.1` on `/eFRAMS3/*` responses |
| Framework | `X-Cocoon-Version: 2.0.4` |
| APM | DynaTrace OneAgent (`X-OneAgent-JS-Injection: true`) |
| Load balancer | `LBPRDINTAPPFM1` cookie (outsourcing) / `LBPRDINTAPPFM2` (outsourcing2) |

---

## Check 1 — Non-Existent Path: `/eFRAMS3/doesnotexist12345`

| Field | Value |
|-------|-------|
| Status | `404 Not Found` |
| Server | `Apache` (no version — reverse proxy layer) |
| Body | Standard Apache 404 HTML — **no Tomcat stack trace** |
| HSTS | ❌ Missing |
| X-Frame-Options | ❌ Missing |

**Observation**: Error pages are handled/suppressed at the reverse proxy before
reaching Tomcat. The Tomcat stack trace risk exists only at the app layer — the
404 path is caught by Apache first. However Tomcat IS exposed on valid app paths
(see Check 3).

**Notable**: Injected Akamai Bot Manager challenge script present in 404 body:
```html
<script src="/-tXOwm/chX/8tS/0RPzFZke/9GiOJSQbmVktrX1cki/WGYpAQ/cA1-/RWlJZ2U"></script>
```

---

## Check 2 — Static Resource: `/eFRAMS3/resources/report.js`

| Field | Value |
|-------|-------|
| Status | `200 OK` — **publicly accessible, no auth required** |
| Content-Type | `text/javascript` |
| Size | 7007 bytes (2079 compressed) |
| Last-Modified | **Thu, 06 Jul 2006 07:21:18 GMT** (20-year-old file) |
| ETag | `"2515c6-1b5f-417e4980fd780"` |
| HSTS | ❌ Missing |

### Internal Paths Leaked by report.js

| Path | Description |
|------|-------------|
| `/eFRAMS3/controller.tsv` | TSV report download endpoint |
| `/eFRAMS3/controller.html` | Main report controller (paginated) |
| `/eFRAMS3/downloadOptions.html` | Download options dialog |
| `/eFRAMS3/help/<reportName>.html` | Context-sensitive help pages |
| `servlet/com.cwo.os.eframs.servlet.Dispatch?stack=last` | **Full Java package name + servlet path** |

### Code Quality / Age Indicators

- `navigator.appName == 'Netscape'` branching — Netscape 4.x era code
- `document.all[trObject]` — IE4/IE5 proprietary API
- `alert('Submit This!')` — **debug/test code committed to production**
- Window sizing for `innerHeight` (Netscape 4 API) and `height` (IE)
- Java applet interaction: `document.Toolbar.getEncURL()` — implies Java applets once used

### Full Java Package Name (Information Disclosure)

```
servlet/com.cwo.os.eframs.servlet.Dispatch
```
Confirms: package namespace `com.cwo.os.eframs`, servlet class `Dispatch`.

---

## Check 3 — HTTP Method Handling: GET `/eFRAMS3/authenticate.html`

| Field | Value |
|-------|-------|
| Status | `200 OK` — **login form served on GET** |
| Server | **`Apache-Coyote/1.1`** (Tomcat HTTP connector exposed) |
| X-Cocoon-Version | **`2.0.4`** |
| Content-Type | `text/html; charset=ISO-8859-1` |
| Response time | ~344ms |
| HSTS | ❌ Missing |
| X-Frame-Options | ❌ Missing — **login page is clickjackable** |

### Technology Stack Disclosed in HTML

XML namespace declarations in the HTML source reveal the full pipeline:

```html
xmlns:eframs-form="http://optus.net.au/eFRAMS/form/1.0"
xmlns:eframs="http://optus.net.au/eFRAMS/1.0"
xmlns:sql="http://apache.org/cocoon/SQL/2.0"          ← SQL pipeline usage
xmlns:java="http://xml.apache.org/xslt/java"          ← Java XSLT extension
xmlns:eframs-nav="http://au.net.optus/ois/eframs3/..."
```

`xmlns:sql="http://apache.org/cocoon/SQL/2.0"` confirms direct SQL database
pipeline in the Cocoon framework — relevant for injection surface analysis.

### Cookies Set on GET `/authenticate.html`

| Cookie | Value excerpt | Flags | Notes |
|--------|--------------|-------|-------|
| `LBPRDINTAPPFM1` | `AjbdRwaVeApwhoQwyvVVew$$` | None | **LB server name leak**: `PRDINTAPPFM1` = production internal app server FM node 1 |
| `JSESSIONID` | `9DBB39AC76863D17B2F82EE1A2EAB553` | `HttpOnly; Path=/eFRAMS3` | ✅ HttpOnly set. ❌ No `Secure` flag — could be sent over HTTP if HTTP redirect exists |
| `_abck` | (Akamai) | `Secure` | Bot Manager cookie |

### DynaTrace APM Config Exposed in Page Source

```
app=ea7c4b59f27d43eb|cuc=sg8g5ivs|owasp=1|mel=100000|expw=1|
featureHash=ICA7NVfqrux|lastModification=1790051674070|
agentUri=/eFRAMS3/ruxitagentjs_ICA7NVfqrux_10345260810170330.js|
reportUrl=/eFRAMS3/rb_bf73405shr|rid=RID_-1960653570|
rpid=-259584338|domain=optus.net.au
```

DynaTrace beacon endpoint: `/eFRAMS3/rb_bf73405shr`

### Additional Internal Information

- **Contact email**: `eframs.feedback@fm.optus.net.au` (internal `fm.` subdomain)
- **App version**: `3.7.6.0` (in page footer)
- **ABN**: `79 055 136 804` (SingTel Optus Pty Ltd)
- **Old Optus Business link**: `http://optusbusiness.com.au/00/00.asp` (dead domain, HTTP not HTTPS)

### Login Form Structure

```html
<form accept-charset="UNKNOWN" action="processlogin.html" method="post">
  <input type="text"     name="user">
  <input type="password" name="pass">
  <input type="submit"   value="Login">
</form>
```

- `accept-charset="UNKNOWN"` — non-standard, likely legacy artefact
- **No CSRF token** on login form
- Form action: `processlogin.html`

---

## Check 4 — processlogin.html (GET, not POST)

| Field | Value |
|-------|-------|
| Status | **`500 Internal Server Error`** |
| Server | `Apache-Coyote/1.1` |
| Response time | ~1832ms (longer — hits backend) |
| Body | Custom error page (no Java stack trace visible) |

**Response body on GET** (application-level error message, not Tomcat default):
```
"There has been a problem delivering your report.
Please try again later.
If the problem persists please contact eFRAMS support and provide the following information:
Error Message: [empty]
Date and Time: 24 Sep 2026 1:25 PM"
```

**Significance**:
- Server returns HTTP 500 rather than 405 Method Not Allowed — method is not
  being validated; the endpoint accepts GET but the pipeline fails without POST data
- Error message is generic/custom — no stack trace leaked in body
- Additional JS file leaked: `frames_body_array.jsd`, `resources/menu.js`
- Cocoon error namespace in HTML: `xmlns:error="http://apache.org/cocoon/error/2.0"`
  (confirms Cocoon error handling pipeline is active)

---

## Check 5 — outsourcing vs outsourcing2 Comparison

### Server Identity

| | outsourcing | outsourcing2 |
|-|------------|--------------|
| Host | `www.outsourcing.optus.net.au` | `www.outsourcing2.optus.net.au` |
| Server | `Apache-Coyote/1.1` | `Apache-Coyote/1.1` |
| Cocoon version | `2.0.4` | `2.0.4` |
| App version | `3.7.6.0` | `3.7.6.0` |
| DynaTrace app ID | `ea7c4b59f27d43eb` | `ea7c4b59f27d43eb` |
| DT lastModification | `1790051674070` | `1790051674070` |
| DT featureHash | `ICA7NVfqrux` | `ICA7NVfqrux` |
| Akamai config | `akam/13/5dc7de8b` | `akam/13/529575c8` |
| LB cookie name | `LBPRDINTAPPFM1` | `LBPRDINTAPPFM2` |
| DT rpid | `-259584338` | `1156079009` |
| Response size (auth) | 7726 bytes | 7735 bytes |
| Response time (auth) | ~344ms | ~1973ms |

### Key Diff Findings

1. **Identical application** — same Cocoon version, same app version, same DynaTrace
   app ID and feature hash, identical HTML content. These are **active-passive or
   load-balanced pairs** of the same application.

2. **Different load balancer nodes** — `LBPRDINTAPPFM1` vs `LBPRDINTAPPFM2` confirms
   two separate backend app server instances named `FM1` and `FM2`.

3. **Different Akamai configurations** — `5dc7de8b` vs `529575c8` — each hostname
   has its own Akamai property/configuration. This means WAF rules could differ
   between the two, and one may have less restrictive rule sets.

4. **Different DynaTrace RPIDs** — different process IDs, confirming different
   JVM/Tomcat instances.

5. **outsourcing2 is significantly slower** (~1973ms vs ~344ms) — suggests it may
   be a standby/DR node with cold caches, or under different load.

6. **Different bazadebezolkohpepadr values** — `1573379305` vs `1385526867` —
   these are Akamai Bot Manager page-specific challenge tokens, differ per property.

---

## Consolidated Findings Summary

### Confirmed Information Disclosures

| # | Finding | Location | Severity |
|---|---------|----------|----------|
| 1 | Server: `Apache-Coyote/1.1` (Tomcat) | All `/eFRAMS3/*` responses | Low/Info |
| 2 | Framework: `X-Cocoon-Version: 2.0.4` (EOL framework) | All `/eFRAMS3/*` responses | Low/Info |
| 3 | Full Java package: `com.cwo.os.eframs.servlet.Dispatch` | `report.js` | Low/Info |
| 4 | Internal LB names: `PRDINTAPPFM1`, `PRDINTAPPFM2` | Set-Cookie headers | Low/Info |
| 5 | Internal email: `eframs.feedback@fm.optus.net.au` | Login page HTML | Low/Info |
| 6 | App version: `3.7.6.0` | Login page footer | Low/Info |
| 7 | DynaTrace config/agent path fully exposed | Login page `<script>` tag | Low/Info |
| 8 | Internal endpoint paths from `report.js` | `report.js` | Low/Info |
| 9 | `accept-charset="UNKNOWN"` on login form | Login page HTML | Low/Info |
| 10 | Debug code: `alert('Submit This!')` in production JS | `report.js` | Low/Info |

### Security Control Gaps (All Pages)

| Control | Status | Notes |
|---------|--------|-------|
| HSTS | ❌ Missing | All observed responses |
| X-Frame-Options | ❌ Missing | **Login page clickjackable** |
| Content-Security-Policy | ❌ Missing | All observed responses |
| X-Content-Type-Options | ❌ Missing | All observed responses |
| JSESSIONID `Secure` flag | ❌ Missing | Session cookie could be sent over HTTP |
| CSRF protection on login | ❌ None observed | No token in login form |

### Potential Vulnerability Candidates (Require Auth to Confirm)

| Candidate | Basis | Priority |
|-----------|-------|----------|
| Cocoon 2.0.4 known CVEs | EOL framework ~2008, many known vulns | High |
| SQL injection via Cocoon SQL pipeline | `xmlns:sql` in XSLT | Medium |
| Session fixation | JSESSIONID issued before login on GET | Medium |
| Clickjacking on login form | No X-Frame-Options | Low |

---

## Recommended Next Steps

1. **Check `outsourcing2` WAF rule differences** — slightly different Akamai config
   (`529575c8`) may have looser rules than `outsourcing` (`5dc7de8b`).

2. **Research Cocoon 2.0.4 CVEs** — Apache Cocoon 2.0.4 is from ~2004, last patched
   ~2008. Search NVD/Mitre for `apache cocoon` CVEs applicable to this version.

3. **Confirm `outsourcing.optus.net.au` scope** — submit a Bugcrowd message
   confirming `*.optus.net.au` is covered before escalating any findings.

4. **Session fixation test** — JSESSIONID is issued on unauthenticated GET of
   authenticate.html; verify whether this same ID is preserved post-login.

5. **Report.js paths** — try fetching `/eFRAMS3/downloadOptions.html` and
   `/eFRAMS3/help/` directly (unauthenticated access test).
