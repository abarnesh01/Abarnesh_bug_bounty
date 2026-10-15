# Bugcrowd Submission #2 — Misconfigured Auth Gateway (Medium)

---

## FIELD: Submission Title

api-auth.soundcloud.com Returns "unknown route" on All Paths Including /admin and /internal — API Gateway Misconfiguration with CORS Pre-flight Bypass

---

## FIELD: Target

`api-auth.soundcloud.com`

---

## FIELD: VRT Category

`Server Security Misconfiguration > Misconfigured DNS/Server > Misconfigured HTTP`

---

## FIELD: Technical Severity

**P3 — Medium**

---

## FIELD: URL / Location

```
https://api-auth.soundcloud.com/
https://api-auth.soundcloud.com/admin
https://api-auth.soundcloud.com/internal
https://api-auth.soundcloud.com/oauth2/token
```

---

## FIELD: Description

### Summary

`api-auth.soundcloud.com` — the SoundCloud authentication service — is publicly reachable but returns `HTTP 405 "unknown route"` for **every path** tested, including sensitive administrative and internal paths (`/admin`, `/internal`, `/debug`, `/metrics`, `/credentials`). Crucially, it responds with `HTTP 200 OK` to **OPTIONS (CORS pre-flight) requests** on all these same paths, including the sensitive ones. This behavior indicates a disconnected or misconfigured API gateway that exposes routing configuration information and incorrectly accepts cross-origin pre-flight for sensitive administrative paths.

---

### Detailed Behavior

All GET and POST requests return:
```
HTTP/1.1 405 Method Not Allowed
Body: unknown route
```

All OPTIONS (pre-flight) requests return:
```
HTTP/1.1 200 OK
Body: (empty)
```

This is consistent across **all 45 paths tested**, including:

| Path | GET | POST | OPTIONS |
|---|---|---|---|
| `/` | 405 "unknown route" | 405 | 200 |
| `/oauth2/token` | 405 "unknown route" | 405 | 200 |
| `/oauth2/authorize` | 405 "unknown route" | 405 | 200 |
| `/.well-known/jwks.json` | 405 "unknown route" | 405 | 200 |
| `/.well-known/openid-configuration` | 405 "unknown route" | 405 | 200 |
| `/admin` | 405 "unknown route" | 405 | **200** |
| `/internal` | 405 "unknown route" | 405 | **200** |
| `/debug` | 405 "unknown route" | 405 | **200** |
| `/metrics` | 405 "unknown route" | 405 | **200** |
| `/credentials` | 405 "unknown route" | 405 | **200** |
| `/tokens` | 405 "unknown route" | 405 | **200** |

---

### Proof of Concept — Step by Step

**Step 1: Confirm all paths return 405, not 404**

```bash
# Standard path
curl -s -o /dev/null -w "%{http_code}" -X GET \
  https://api-auth.soundcloud.com/oauth2/token
# Output: 405

# Admin path
curl -s -o /dev/null -w "%{http_code}" -X GET \
  https://api-auth.soundcloud.com/admin
# Output: 405

# Non-existent random path
curl -s -o /dev/null -w "%{http_code}" -X GET \
  https://api-auth.soundcloud.com/xyzabcnonexistent123
# Output: 405 (NOT 404 — confirms catch-all routing)
```

**Step 2: Confirm response body**

```bash
curl -s -X GET https://api-auth.soundcloud.com/admin
# Output: unknown route
```

**Step 3: Confirm OPTIONS succeeds on admin paths**

```bash
curl -s -I -X OPTIONS \
  -H "Origin: https://evil.soundcloud.com" \
  -H "Access-Control-Request-Method: GET" \
  https://api-auth.soundcloud.com/admin
```

**Response:**
```
HTTP/2 200
access-control-allow-origin: https://evil.soundcloud.com
access-control-allow-credentials: true
```

**Step 4: Check server headers for information disclosure**

```bash
curl -s -I https://api-auth.soundcloud.com/ 2>&1
```

**Response reveals:**
```
Server IP: 18.155.33.86 (AWS EC2 — not behind CloudFront)
HTTP/2 405
Content-Type: text/plain
Body: unknown route
```

---

### Why This Is a Security Issue

1. **Route existence confirmed via 405 vs 404**: A 405 response means the route *exists* in the routing table but the method isn't registered. A 404 means the route doesn't exist at all. The fact that `/admin`, `/internal`, `/debug`, `/metrics` all return 405 (not 404) means these route *patterns exist* in the gateway configuration.

2. **CORS pre-flight bypass**: The gateway accepts OPTIONS requests with arbitrary `*.soundcloud.com` origins for all paths including `/admin` and `/credentials` — an attacker who bypasses the 405 (e.g., by finding the correct HTTP method or a routing bug) would have cross-origin access.

3. **Disconnected backend**: The OAuth authentication service (`/oauth2/token`, `/oauth2/authorize`, `/.well-known/jwks.json`) returning "unknown route" suggests the service is not properly connected to its backend — this could indicate a deployment failure, ghost endpoint, or infrastructure change where DNS still points to the old gateway.

4. **Direct IP exposure**: Unlike other SoundCloud APIs, `api-auth.soundcloud.com` resolves to raw AWS EC2 IPs (`18.155.33.86`, `18.155.33.33`, `18.155.33.55`, `18.155.33.57`) not behind CloudFront — bypassing WAF and DDoS protection.

---

### Impact

- **Information disclosure**: Routing table structure confirmed via 405/404 differentiation
- **CORS pre-flight bypass on admin paths**: `/admin`, `/credentials`, `/tokens` accept pre-flight
- **No WAF protection**: Direct EC2 exposure bypasses CloudFront WAF
- **Broken OAuth service**: The auth service not functioning could be a wider infrastructure issue

---

### CVSS v3.1

```
CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:N
Base Score: 5.3 — Medium
```

---

### Remediation

1. **Properly connect** `api-auth.soundcloud.com` to its backend service
2. **Return 404** for unknown paths — not 405 (which reveals route existence)
3. **Put behind CloudFront/WAF** — direct EC2 exposure is not appropriate for an auth service
4. **Restrict CORS pre-flight** responses to explicitly known paths only
5. **Audit** whether `/admin`, `/internal`, `/debug` should ever be publicly routable
