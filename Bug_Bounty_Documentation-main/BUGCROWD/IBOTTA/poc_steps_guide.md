# 📸 Ibotta PoC — Beginner Screenshot/Recording Guide

---

## 🔴 PoC #1 — CORS Wildcard on GraphQL (P2) [MOST IMPORTANT]

### What you need
- Firefox or Chrome browser
- The `cors_graphql_poc.html` file you already have
- Terminal (for curl evidence)

---

### Part A — Terminal Screenshot (curl proof)

**Open terminal and run these ONE BY ONE, screenshot each output:**

```bash
# Screenshot 1 — Verify wildcard CORS (OPTIONS preflight)
curl -v -X OPTIONS https://content-server.ibotta.com/graphql \
  -H 'Origin: https://evil.com' \
  -H 'Access-Control-Request-Method: POST' \
  -H 'Access-Control-Request-Headers: Authorization,Content-Type' 2>&1
```

**What to show in screenshot:**
- The `< access-control-allow-origin: *` line (this is your smoking gun)
- The `< access-control-allow-headers: Authorization,Content-Type` line
- The `HTTP/2 204` status

```bash
# Screenshot 2 — Same test on STAGING (shows it's not isolated)
curl -v -X OPTIONS https://content-stage.ibotta.com/graphql \
  -H 'Origin: https://evil.com' \
  -H 'Access-Control-Request-Method: POST' \
  -H 'Access-Control-Request-Headers: Authorization,Content-Type' 2>&1
```

---

### Part B — Browser PoC (Video Recording)

**Steps to record:**

1. Open a terminal and run this to serve the HTML file locally:
   ```bash
   cd /home/prasanth/CYBERBOTS_STUP/Bug_Bounty_Documentation/BUGCROWD/IBOTTA/Proofs/submissions/
   python3 -m http.server 8888
   ```

2. **Open OBS Studio or Kazam for screen recording** (or use `kazam` on Linux):
   ```bash
   # Install kazam if not present
   sudo apt install kazam -y
   kazam &
   ```

3. Open Firefox/Chrome and go to: `http://localhost:8888/cors_graphql_poc.html`

4. **Press F12** to open DevTools → Click **Network** tab → Click **Console** tab (keep both visible)

5. Start screen recording

6. Click **"Test Preflight OPTIONS"** button → **screenshot the result showing `access-control-allow-origin: *`**

7. Click **"Test CORS (No Auth)"** button → screenshot the cross-origin response being readable

8. In DevTools Network tab → click on the graphql request → click **Headers** tab → scroll down to **Response Headers** — screenshot showing `access-control-allow-origin: *`

9. Stop recording

**What the video must show:**
- Your page is at `localhost:8888` (a different origin than `content-server.ibotta.com`)
- The browser successfully reads the response from `content-server.ibotta.com`
- The `access-control-allow-origin: *` header in DevTools Network → Response Headers

---

### Part C — DevTools Screenshot (No Coding Needed)

1. Open Chrome/Firefox
2. Go to **any website** (e.g., `https://google.com`)
3. Press **F12** → **Console** tab
4. Paste this code and press Enter:

```javascript
fetch('https://content-server.ibotta.com/graphql', {
  method: 'OPTIONS',
  headers: {
    'Access-Control-Request-Method': 'POST',
    'Access-Control-Request-Headers': 'Authorization,Content-Type'
  }
}).then(r => {
  console.log('Status:', r.status);
  console.log('ACAO:', r.headers.get('access-control-allow-origin'));
  console.log('ACAM:', r.headers.get('access-control-allow-methods'));
  console.log('ACAH:', r.headers.get('access-control-allow-headers'));
  alert('CORS WILDCARD CONFIRMED!\nAccess-Control-Allow-Origin: ' + r.headers.get('access-control-allow-origin'));
});
```

5. **Screenshot the Console output** showing `ACAO: *`
6. **Screenshot the alert popup** saying `CORS WILDCARD CONFIRMED!`
7. Switch to **Network tab** → find the OPTIONS request → **Response Headers** → Screenshot the `access-control-allow-origin: *`

---

## 🟡 PoC #2 — Kubernetes Pod Disclosure via /healthcheck (P4)

### Terminal Screenshots (Very Easy)

**Screenshot 1 — Single request showing pod name:**
```bash
curl -sk https://api.ibotta.com/healthcheck
```
Screenshot the output: `{"r":"api-deploy-2026.10.02.17.43.43","h":"monolith-api-primary-7b4bbf7fff-twwdn"}`

**Screenshot 2 — Multiple requests showing different pod names (proves it's real k8s):**
```bash
for i in {1..5}; do curl -sk https://api.ibotta.com/healthcheck; echo; done
```
Screenshot showing 5 different pod names all with `monolith-api-primary-7b4bbf7fff-XXXXX`

**Screenshot 3 — Backend also affected:**
```bash
curl -sk https://backend.ibotta.com/healthcheck
```
Screenshot showing `monolith-api-default-858cfdc89d-XXXXX`

**Screenshot 4 — Browser proof (even simpler):**
- Open Chrome → Address bar → type: `https://api.ibotta.com/healthcheck` → press Enter
- Screenshot the browser showing the JSON response with pod name

---

### Browser Screenshot (Beginner — No Terminal)

1. Open Chrome
2. In address bar type: `https://api.ibotta.com/healthcheck`
3. Press Enter
4. You'll see: `{"r":"api-deploy-2026.10.02.17.43.43","h":"monolith-api-primary-7b4bbf7fff-XXXX"}`
5. **Screenshot the browser + URL bar** visible
6. Press F5 to refresh 3-4 times
7. Screenshot again — the `h` value changes each time (different pods)

---

## 🟡 PoC #3 — Looker Version Disclosure (P4)

### Browser Screenshots (Easiest PoC)

**Screenshot 1 — Unauthenticated version endpoint:**
1. Open Chrome
2. Go to: `https://looker.ibotta.com/api/4.0/versions`
3. You'll see JSON with `"looker_release_version": "26.18.1"`
4. **Screenshot the browser** with URL bar showing the endpoint and version in the response

**Screenshot 2 — Version in login page source:**
1. Go to: `https://looker.ibotta.com/login`
2. Press **F12** → **Elements** tab (or **Ctrl+U** for page source)
3. Press **Ctrl+F** → search for `lookerVersion`
4. **Screenshot the highlighted `lookerVersion: '26.18.1'`** in the source

**Screenshot 3 — Also accessible on API server:**
1. Go to: `https://ibotta.api.looker.com/api/4.0/versions`
2. **Screenshot** showing same version info

### Terminal Screenshots

```bash
# Clean output for the report
curl -sk https://looker.ibotta.com/api/4.0/versions | python3 -m json.tool

# One-liner showing version
curl -sk https://looker.ibotta.com/api/4.0/versions | python3 -c \
  "import json,sys; d=json.load(sys.stdin); print('Version:', d['looker_release_version']); print('API Server:', d['api_server_url'])"

# Version leaked in login page
curl -sk https://looker.ibotta.com/login | grep 'lookerVersion'
```

Screenshot all 3 command outputs.

---

## 🟡 PoC #4 — Missing Security Headers (P4)

### Terminal Screenshot

```bash
# Show missing headers (the absence is the proof)
echo "=== Security Headers Check: api.ibotta.com ===" && \
curl -sk -I https://api.ibotta.com/ | grep -iE \
  '(x-frame-options|content-security-policy|x-content-type|permissions-policy|referrer-policy|x-powered-by)'
```

Screenshot the output — it will only show `x-powered-by: Phusion Passenger(R)` meaning all the security headers are MISSING.

### Online Tool Screenshot (Beginner-Friendly)

1. Go to: `https://securityheaders.com`
2. In the URL field type: `https://api.ibotta.com`
3. Click **Scan**
4. **Screenshot the report** showing missing headers (red F or D grade)

---

## 📱 Screen Recording Tool for Linux

Install and use **Kazam** (simplest):
```bash
sudo apt install kazam
kazam
```
- Click **Screencast** → **Full Screen**
- Click **Capture** (will count down 5 seconds)
- Do your PoC steps
- Click **Finish** icon in system tray
- File saves to `~/Videos/`

Or use **SimpleScreenRecorder**:
```bash
sudo apt install simplescreenrecorder
simplescreenrecorder
```

---

## 📁 File Organization for Submission

```
IBOTTA/Proofs/
├── screenshots/
│   ├── 01_cors_curl_options_wildcard.png      ← Finding #1 (main proof)
│   ├── 02_cors_staging_also_affected.png      ← Finding #1 (bonus)
│   ├── 03_cors_browser_devtools_network.png   ← Finding #1 (browser proof)
│   ├── 04_cors_console_output.png             ← Finding #1 (console proof)
│   ├── 05_healthcheck_pod_names.png           ← Finding #2
│   ├── 06_healthcheck_multiple_pods.png       ← Finding #2 (rotates)
│   ├── 07_looker_version_endpoint.png         ← Finding #3
│   ├── 08_looker_version_in_source.png        ← Finding #3
│   └── 09_missing_headers_terminal.png        ← Finding #4
├── videos/
│   └── cors_poc_browser_demo.mp4              ← Finding #1 (best evidence)
└── submissions/
    └── cors_graphql_poc.html
```

---

## ✅ Quick Screenshot Checklist

### For CORS (P2) — Need ALL of these:
- [ ] Terminal: `curl -v OPTIONS` output showing `access-control-allow-origin: *`
- [ ] Terminal: Same test on staging endpoint
- [ ] Browser: Console JS fetch showing ACAO header value
- [ ] Browser: DevTools → Network → Response Headers screenshot
- [ ] Video: Full browser demo with localhost PoC page

### For Healthcheck (P4):
- [ ] Browser: Navigate to `https://api.ibotta.com/healthcheck` — screenshot URL + response
- [ ] Terminal: Loop showing 5 different pod names

### For Looker (P4):
- [ ] Browser: Navigate to `https://looker.ibotta.com/api/4.0/versions` — screenshot
- [ ] Browser: Ctrl+U on login page → search `lookerVersion` — screenshot

### For Headers (P4):
- [ ] Terminal: `curl -I` showing only `x-powered-by`, missing security headers
- [ ] Optional: securityheaders.com report screenshot
