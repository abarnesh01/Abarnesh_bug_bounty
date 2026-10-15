# Alasco GmbH — Bug Bounty Recon Report

**Program:** YesWeHack — Alasco GmbH  
**Date:** 2026-10-02  
**User-Agent appended:** `-BugBounty-alasco-gmbh-31337`  
**Testing Window:** 08:00–17:00 CET (passive recon performed at ~05:54 CET; active testing to be done within window)

---

## 🎯 Scope Summary

| Asset | Type | Value |
| ------- | ------ | ------- |
| `app.alasco.de` | Web App | **High** |
| `api.alasco.de` | API | **High** |
| `*.alasco.de` | Other | **Medium** |
| `*.alasco.rocks` | Other | **Low** |

> **Key constraint:** Only **non-authenticated** areas are in scope. No credentials will be provided.

---
Alasco GmbH - Bug Bounty Program
Make your real estate projects more successful by managing costs, profits and ESG data from your assets in one software.

Last update on 2026-07-22

Program history
Reward
Bounty
Hall of fame
€50
Low
€50
Medium
€200
High
€600
Critical
€1,000
Program
Avg reward
-

Max reward
-

Scopes
4
Supported languages
English
German
Hacktivity
Reports
172
1st response
< 1 day
Reports last 24h
-

Reports last week
1
Reports this month
-

Program description
Program activity
About Alasco GmbH
Alasco offers state of the art software for financial controlling and ESG management.
Security is very important to us and this Bug Bounty program shall help us meet highest industry standards to offer the most secure service and experience to all parties.

Program Rules
Attention: Business Continuity and Testing Conduct
Maintaining uninterrupted service for our users and partners is absolutely critical. All security testing must be performed with extreme care to avoid any form of business disruption. This includes actions that could degrade performance, interrupt service availability, or affect real customers.

Researchers are expected to act responsibly at all times and prioritize the stability, integrity, and security of Alasco systems above all else. If in doubt, stop testing immediately and seek clarification through the platform’s report discussion thread before proceeding.

Testing Policy and Responsible Disclosure
The below two rule sets form the core foundation of the Alasco Vulnerability Reward Program.

They are designed to protect business continuity, user data, and testing integrity.

Priority Zero Rules are global and non-negotiable. They apply to all testing activities across all targets and take precedence over any other instruction or rule.
Target-specific Program Rules define additional, per-target constraints — such as testing windows, rate limits, allowed endpoints, or isolated environments — to ensure safe and controlled testing for specific systems.
All researchers must review and follow both rule sets before starting any testing.

Violating either may result in disqualification of reports, revocation of bounty eligibility, or, in severe cases, suspension or termination of the entire program if operational damage occurs.

Priority Zero Rules
Please adhere to the following rules while performing research on this program:

Denial of service (DoS) attacks on Alasco GmbH applications, servers, networks, or infrastructure are strictly forbidden.
Tests that could cause degradation or interruption of our services are strictly forbidden.
Do not use automated scanners or tools that generate large amounts of network traffic, or use them in a very gentle way (maximum 1 request per second unless explicitly permitted otherwise).
Do not leak, manipulate, destroy, download, copy, or exfiltrate any user data, company data, or files from our applications, servers, or systems.
Do not alter real data under any circumstances.
No vulnerability disclosure, full, partial, or otherwise, is allowed without explicit written consent from Alasco.
Do not spam registration forms or any public-facing forms on our websites, including but not limited to <https://www.alasco.de/explore/>
You must append the defined user-agent to all web-based requests.
Use dummy/test accounts and clearly identifiable test data whenever possible.
If Alasco’s Security Team requests that you pause or stop testing, you must comply immediately.
If you are unsure whether an action is safe, stop testing and ask first via the report discussion thread.
Target-specific Program Rules
In addition to the Priority Zero Rules above, the following target-specific rules apply where communicated for a given scope:

Test only during approved hours
Limit all testing activities to 08:00–17:00 CET. Do not perform any scans, automation, or manual testing outside this time window unless you have explicit written approval.

Do not disrupt our business
Do not run automation, scans, or tests that could degrade performance, disrupt services, or impact real users. If your activity risks service stability, stop immediately.

Avoid heavy automation
Do not run parallelized or high-volume automated tooling unless you have prior written approval. Default behaviour should be manual or single-threaded, low-rate testing.

No public disclosure without explicit written consent
Do not share findings, screenshots, logs, or artifacts with third parties. Report exclusively through the designated vulnerability disclosure platform. Public disclosure of any vulnerability requires written consent from Alasco — no exceptions.

No altering of real data
Never change, download, or exfiltrate company data — even if you gain access to any.

Use identifiable test data
Use dummy/test accounts and data that can be distinguished from normal traffic and production data.

Follow Security Team instructions immediately
If Alasco’s Security Team requests that you pause or stop testing, comply at once. Their direction takes precedence to protect users and operations.

If in doubt — stop and ask
When unsure about impact, environment, or data, pause testing and ask in the report discussion thread before proceeding.

Reward Eligibility
We are happy to thank everyone who submits valid reports which help us improve the security of Alasco GmbH, however only those that meet the following eligibility requirements may receive a monetary reward:

You must be the first reporter of a vulnerability.
The same vulnerability in different scopes will only count as one vulnerability.
The vulnerability must be a qualifying vulnerability.
The report must contain the following elements:
Clear textual description of the vulnerability, how it can be exploited, the security impact it has on the application, its users, and Alasco GmbH, and remediation advice on fixing the vulnerability.
Proof of exploitation: screenshots demonstrating the exploit was performed, and showing the final impact.
Complete steps with the necessary information to reproduce the exploit, including, if necessary, code snippets, payloads, commands, etc.
You must not break any of the testing policy rules listed above.
You must not be a former or current employee of Alasco GmbH or one of its contractors.
Reward Grid
Reward amounts are based on:

Reward grid of the report's scope
CVSS scoring and actual business impact of the vulnerability upon performing risk analysis
Discretionary judgement of Alasco’s CISO
Reward
Asset value CVSS
Low
CVSS
Medium
CVSS
High
CVSS
Critical
High
€50 €200 €600 €1,000
Medium
€50 €200 €600 €1,000
Low
€50 €200 €600 €1,000
Scopes

Export
Scope Type Asset value 
app.alasco.de
Web application 
High

api.alasco.de
API 
High

*.alasco.de
Other 
Medium

*.alasco.rocks
Other 
Low

Out of scopes
All other domains or subdomains not listed in the above list of 'Scopes'.
explore.alasco.com
explore.alasco.de
<www.alasco.de>
<www.alasco.com>
alasco.de
alasco.com
lp.alasco.de
lp.alasco.com
support.alasco.de
support.alasco.com
Please note that all non-authenticated areas of our systems are in scope for this program. This means that any vulnerability discovered in a system or service that does not require a login to access is eligible for a reward.
However, any vulnerability discovered in a system or service that requires a login to access is outside the scope of this program.
Alasco will not provide access credentials to any system, not for testing and also not for issue validation.
Attention: Third-party managed infrastructure (e.g. HubSpot, Salesforce, or other SaaS platforms) where Alasco has no ability to remediate vulnerabilities at the infrastructure or platform level, regardless of the subdomain.
Vulnerability types
Qualifying vulnerabilities
SQL Injection (SQLi)
Cross-Site Scripting (XSS)
Remote Code Execution (RCE)
Insecure Direct Object Reference (IDOR)
Horizontal and vertical privilege escalation
Authentication bypass & broken authentication
Business Logic Errors vulnerability with real security impact
Local files access and manipulation (LFI, RFI, XXE, SSRF, XSPA)
Cross-Origin Resource Sharing (CORS) with real security impact
Cross-site Request Forgery (CSRF) with real security impact
Non-qualifying vulnerabilities
Tabnabbing
Missing cookie flags
Content/Text injections
Mixed content warnings
Clickjacking/UI redressing
Denial of Service (DoS) attacks
Known CVEs without working PoC
Open ports without real security impact
Social engineering of staff or contractors
Presence of autocomplete attribute on web forms
Vulnerabilities affecting outdated browsers or platforms
Self-XSS or XSS that cannot be used to impact other users
Outdated libraries without a demonstrated security impact
Any hypothetical flaw or best practices without exploitable PoC
Expired certificate, best practices and other related issues for TLS/SSL certificates
Unexploitable vulnerabilities (ex: XSS or Open Redirect in HTTP Host Header)
Reports with attack scenarios requiring MITM or physical access to victim's device
Missing security-related HTTP headers which do not lead directly to a vulnerability
Unauthenticated / Logout / Login and other low-severity Cross-Site Request Forgery (CSRF)
Invalid or missing SPF (Sender Policy Framework), DKIM, DMARC records
Session expiration policies (no automatic logout, invalidation after a certain time or after a password change)
Disclosure of information without direct security impact (e.g. stack traces, path disclosure, directory listings, software versions, IP disclosure, 3rd party secrets)
CSV injection
HTTP Strict Transport Security Header (HSTS)
Subdomain takeover without a full working PoC
Blind SSRF without direct impact (e.g. DNS pingback)
Lack of rate-limiting, brute-forcing or captcha issues
User enumeration (email, alias, GUID, phone number)
Password requirements policies (length / complexity / reuse)
Ability to spam users (email / SMS / direct messages flooding)
Disclosed / misconfigured Google API key (including Google Maps)
Recently disclosed 0-day vulnerabilities (less than 14 days since patch release)
Password reset token leak on trusted third-party website via Referer header (eg Google Analytics, Facebook…)
Open redirect - unless an additional security impact can be demonstrated
Dynamic Client Registration (DCR) — Our MCP server intentionally supports OAuth Dynamic Client Registration (RFC 7591) for MCP client compatibility. DCR is publicly accessible by design. Registrations are constrained to supported public OAuth clients and validated redirect URI patterns. Findings that rely solely on the ability to register an OAuth client via /mcp/oauth/register are non-qualifying, as this endpoint is intentionally open. Reports must demonstrate a complete, exploitable attack chain beyond client registration itself.
Hunting requirements
Account access
Open to the public: no login required to access in-scope systems and services.

User agent
Please append to your user-agent header the following value: ' -BugBounty-alasco-gmbh-31337 '.

Hunters collaboration

When submitting new report, you can add up to 5 collaborators, and define the reward split ratio.

For more information, see help center.
Note: For reports that have already been rewarded, it is not possible to redistribute the rewards.

Credits
Learn more
Current credits
10
Submission cost
Refunded if your report is valid
2
Remaining after submission
8
Submit report
2
program thumbnail
Alasco GmbH - Bug Bounty Program
Bug bounty description
Rewards
Scopes
Vulnerability types
Hunting requirements
Hunters collaboration
Hall Of Fame
Credits
Learn more
Current credits
10
Submission cost
Refunded if your report is valid
2
Remaining after submission
8
Submit report
2
© YesWeHack 2026
divider
Legal notices
divider
General Conditions of Use
divider
Platform privacy policy
divider
Contact us  

## 🗺️ Subdomain Discovery

### `alasco.de` — Subfinder Results

| Subdomain | Notes |
| ----------- | ------- |
| `app.alasco.de` | 🎯 **HIGH VALUE** — Main web app |
| `api.alasco.de` | 🎯 **HIGH VALUE** — Main API |
| `mcp.alasco.de` | 🔥 MCP server (Model Context Protocol + OAuth) |
| `ai.alasco.de` | 🔥 AI endpoint — connection timeout (firewall?) |
| `litellm.alasco.de` | 🔥 LiteLLM proxy — connection timeout |
| `login.alasco.de` | Auth0-based login server |
| `files.alasco.de` | File serving endpoint |
| `dev.alasco.de` | Dev environment — connection timeout |
| `staging.alasco.de` | Staging environment |
| `sandbox.alasco.de` | Sandbox — connection timeout |
| `inside.alasco.de` | ✅ HTTP 200 — publicly accessible! |
| `static.alasco.de` | Static assets |
| `get.alasco.de` | Connection timeout |
| `career.alasco.de` | Careers page |
| `bypass-app.alasco.de` | ⚠️ Suspicious name — possible WAF bypass route |
| `n.alasco.de` / `o1.n.alasco.de` | Unknown service |
| `robin.alasco.de` | Internal service |
| `branding.alasco.de` | Branding assets |
| `internal.alasco.de` | Internal-facing |
| `rds.alasco.de` / `rds-proxy.alasco.de` / `rds-rw.alasco.de` / `rds-proxy-rw.alasco.de` / `rds-read-replica.alasco.de` | ⚠️ RDS database proxies exposed in DNS! |
| `eks-auto.alasco.de` | EKS cluster endpoint |

### `alasco.rocks` — Subfinder Results (Goldmine)

| Subdomain | Notes |
| ----------- | ------- |
| `mcp-bug-bounty.alasco.rocks` | 🎯 Dedicated BB MCP server |
| `app-bug-bounty.alasco.rocks` | 🎯 Dedicated BB app |
| `api-bug-bounty.alasco.rocks` | 🎯 Dedicated BB API |
| `login-bug-bounty.alasco.rocks` | 🎯 Dedicated BB login |
| `files-bug-bounty.alasco.rocks` | 🎯 Dedicated BB file server (404) |
| `robin-bug-bounty.alasco.rocks` | 🎯 Dedicated BB robin service |
| `openwebui.alasco.rocks` | 🔥 Open WebUI (AI chat) — connection timeout |
| `litellm.alasco.rocks` | 🔥 LiteLLM AI proxy — connection timeout |
| `storybook.alasco.rocks` | 🔥 Storybook component library — connection timeout |
| `ui-patterns.alasco.rocks` | HTTP 503 |
| `metabase.alasco.rocks` / `metabase.internal.alasco.rocks` | Analytics dashboard |
| `sonarqube.internal.alasco.rocks` | 🔥 SonarQube code analysis |
| `agentic-assistant-ai.internal.alasco.rocks` | 🔥 AI agent system |
| `devlake-admin.alasco.rocks` | DevLake admin panel |
| `librechat.alasco.rocks` | LibreChat AI interface |
| `staging.alasco.rocks` / `app-staging.alasco.rocks` / `api-staging.alasco.rocks` | Staging env |
| `prod.alasco.rocks` | Production mirror |
| `mcp.alasco.rocks` | HTTP 403 |
| `mcp-staging.alasco.rocks` | MCP staging |
| `finance.alasco.rocks` | Finance module |
| `bricks.alasco.rocks` | Unknown |
| `demo.alasco.rocks` | Demo environment |
| `app-pr9644-wf-2067-public-a.dev.alasco.rocks` | 🔥 PR for "public-a" feature |
| `db-pr9473-plat-1077-cloudf.dev.alasco.rocks` | DB preview env |

---

## 🔍 Live Target Analysis

### MCP OAuth Infrastructure (`mcp.alasco.de` & `mcp-bug-bounty.alasco.rocks`)

**Status:** Both return HTTP 401 on `/mcp` with full `WWW-Authenticate` header:

```
Bearer error="invalid_token", error_description="Missing Authorization header",
resource_metadata="https://mcp.alasco.de/.well-known/oauth-protected-resource"
```

**OIDC Discovery** (`/.well-known/openid-configuration`) — **HTTP 200, fully public**:

```json
{
  "issuer": "https://mcp.alasco.de",
  "authorization_endpoint": "https://app.alasco.de/mcp/oauth/authorize",
  "token_endpoint": "https://login.alasco.de/oauth/token",
  "registration_endpoint": "https://app.alasco.de/mcp/oauth/register",
  "scopes_supported": ["read", "modify", "offline_access"],
  "token_endpoint_auth_methods_supported": ["none"],
  "dpop_signing_alg_values_supported": ["ES256"],
  "resource_parameter_supported": true
}
```

**Bug Bounty Environment** (`mcp-bug-bounty.alasco.rocks`):

```json
{
  "issuer": "https://mcp-bug-bounty.alasco.rocks",
  "authorization_endpoint": "https://app-bug-bounty.alasco.rocks/mcp/oauth/authorize",
  "token_endpoint": "https://login-bug-bounty.alasco.rocks/oauth/token",
  "registration_endpoint": "https://app-bug-bounty.alasco.rocks/mcp/oauth/register"
}
```

**DCR Tests performed:**

- `redirect_uris: ["https://example.com/callback"]` → `{"error": "invalid_redirect_uri", "redirect_uri host is not allowed: example.com"}`
- `redirect_uris: ["https://app-bug-bounty.alasco.rocks/callback"]` → `{"error": "invalid_redirect_uri", "redirect_uri host is not allowed: app-bug-bounty.alasco.rocks"}`

> Note: DCR-only findings are explicitly non-qualifying. Full exploit chain required.

---

### `inside.alasco.de` — HTTP 200 (Unauthenticated!)

Returns HTTP 200 — **publicly accessible without authentication**. Priority investigation target.

### `app-bug-bounty.alasco.rocks` — Auth0 Redirect

302 redirect to:

```
https://login-bug-bounty.alasco.rocks/authorize
  ?client_id=A33On9beOhw3AyCi3IlvBkEIyNG6b0bh
  &redirect_uri=https://app-bug-bounty.alasco.rocks/auth/complete/auth0/
  &state=U8O12xSsNgxxvJmZDuzedtSuLQ3Y1Ili
  &response_type=code
  &scope=openid+profile+email
```

### `api-bug-bounty.alasco.rocks` — DRF API

Returns HTTP 401: `{"detail": "Not authenticated"}` — Django REST Framework.

---

## 🏆 Prioritized Attack Vectors

### 1. 🔥 MCP Server OAuth Flow Security (HIGH/CRITICAL potential)

**Endpoints to test:**

- `https://app.alasco.de/mcp/oauth/authorize` (production, HIGH value)
- `https://app-bug-bounty.alasco.rocks/mcp/oauth/authorize` (BB env)

**Attack checklist:**

- [ ] **PKCE downgrade**: Try auth request without `code_challenge` parameter
- [ ] **State CSRF**: Initiate flow, swap state in callback; is it validated?
- [ ] **Redirect URI bypass**:
  - Test registered host with path traversal: `app.alasco.de/../evil`
  - URL-encoded slashes: `app.alasco.de%2F..%2Fevil`
  - Open redirect chaining on `app.alasco.de`
- [ ] **Token without PKCE**: Exchange auth code without `code_verifier`
- [ ] **Scope escalation**: Request `modify offline_access` — what does `modify` grant?
- [ ] **resource parameter SSRF**: `resource=https://internal.corp` in token request
- [ ] **Authorization code reuse**: Replay a captured code
- [ ] **DPoP bypass**: `dpop_signing_alg_values_supported: ["ES256"]` — is DPoP mandatory?

---

### 2. 🔥 `inside.alasco.de` — Unauthenticated Access (MEDIUM/HIGH)

- [ ] What content is served? Employee portals? Customer data?
- [ ] Any sensitive links or embedded API calls?
- [ ] Test CORS: `Origin: https://evil.com`
- [ ] Test for XSS in any inputs

---

### 3. 🔥 API Enumeration — `api.alasco.de` / `api-bug-bounty.alasco.rocks`

- [ ] `/api/schema/` — DRF OpenAPI schema (often unauthenticated)
- [ ] `/api/docs/` — DRF Browsable API
- [ ] `/swagger.json`, `/openapi.json`, `/redoc/`
- [ ] `/health/`, `/metrics/`, `/status/`
- [ ] CORS misconfiguration: `Origin: https://evil.com` header test
- [ ] Check for publicly accessible endpoints returning data

---

### 4. 🔥 `bypass-app.alasco.de` — WAF Bypass Route

- [ ] Does it resolve and respond?
- [ ] Does it serve the application without Cloudflare protection?
- [ ] Can it be used to bypass WAF-blocked payloads?

---

### 5. ⚠️ RDS DNS Exposure (INFO/MEDIUM)

DNS entries publicly reveal database infrastructure:

```
rds.alasco.de, rds-proxy.alasco.de, rds-proxy-rw.alasco.de,
rds-rw.alasco.de, rds-read-replica.alasco.de
```

- [ ] `dig rds-proxy.alasco.de` — what IP does it resolve to?
- [ ] If public IP: `nmap -sV -p 5432,3306,1433 <ip>` (check if ports open)
- [ ] Exposed RDS proxy = potential CRITICAL if reachable

---

### 6. CORS Testing (MEDIUM/HIGH)

Targets: `api.alasco.de`, `mcp.alasco.de`, `api-bug-bounty.alasco.rocks`

```bash
curl -s -H "Origin: https://evil.com" \
     -H "User-Agent: Mozilla/5.0 -BugBounty-alasco-gmbh-31337" \
     https://api.alasco.de/ -I
```

Looking for: `Access-Control-Allow-Origin: https://evil.com` or wildcard on credentialed endpoints.

---

### 7. PR Preview Environments (LOW-MEDIUM)

`app-pr9644-wf-2067-public-a.dev.alasco.rocks` — "public" in feature name suggests intentionally unauthenticated feature.

- [ ] What is the "wf-2067-public" feature? (Workflows public access?)
- [ ] Does it expose any data without auth?

---

## 📋 Technology Stack

| Component | Technology |
| ----------- | ----------- |
| Frontend | **Astro v7.3.3** (`/_astro/` path confirmed) |
| Marketing | **WordPress** (Avada theme, WP plugins) |
| Auth | **Auth0** (login.alasco.de) |
| API | **Django REST Framework** |
| CDN/WAF | **Cloudflare** |
| AI Proxy | **LiteLLM** |
| AI Chat | **Open WebUI**, **LibreChat** |
| MCP | Custom MCP server, OAuth 2.1 + PKCE |
| Analytics | **Metabase** |
| Code Quality | **SonarQube** |
| Database | **AWS RDS** (PostgreSQL likely) |
| Infrastructure | **AWS EKS** |

---

## ⏰ Active Testing Schedule (08:00–17:00 CET)

| Priority | Target | Type | Method |
| ---------- | -------- | ------ | -------- |
| P1 | `mcp.alasco.de` OAuth flow | Auth | Manual, low-rate |
| P1 | `inside.alasco.de` | Info disclosure | Manual browse |
| P1 | `api.alasco.de` schema | Info disclosure | Single requests |
| P2 | `bypass-app.alasco.de` | WAF bypass | Manual probe |
| P2 | CORS on `api.alasco.de` | CORS | curl one-liners |
| P2 | RDS DNS resolution | Infra | dig + nmap |
| P3 | `api-bug-bounty.alasco.rocks` | API enum | Gentle wordlist |
| P3 | PR preview envs | Auth | Manual browse |

---

## 🚨 Rules Compliance

- [x] User-Agent: `-BugBounty-alasco-gmbh-31337` on all requests
- [x] No high-volume automation used
- [x] No data exfiltration/modification
- [x] Only passive recon during off-hours
- [ ] Begin active testing at 08:00 CET
- [ ] Max 1 req/sec for any tool
- [ ] Use dummy data for any test accounts
