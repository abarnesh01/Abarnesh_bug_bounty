# Screen-Recording Guide — fd.zerodha.com Referer PoC (Beginner)

**What you'll record:** the terminal script [poc_referer_fd.sh](poc_referer_fd.sh) running on camera (~2 min).
**Recorder:** Spectacle (already installed on your KDE — same one that made `Screencast_20261002_130504.webm`).

---

## BEFORE recording (5 min prep)

1. Open Konsole and go to the PoC folder:
   ```
   cd /home/prasanth/CYBERBOTS_STUP/Bug_Bounty_Documentation/COMOHLO/ZERODHA/Proofs
   ```
2. Make the font BIG (readable in the video):
   - Open Konsole settings: **Ctrl+Shift+,** → Profile → Appearance → font size **16–18**
   - Or press **Ctrl + +** a few times in the terminal window.
3. Make the window WIDE (full-width, ~70% of screen height) so long JSON lines don't wrap ugly.
4. Clear the screen and set the window title to the target:
   ```
   clear
   ```
5. Dry-run the script once **before** recording (so you know the flow):
   ```
   bash poc_referer_fd.sh
   ```
   (It pauses after each step — press Enter. Read each banner. That's the whole demo.)

---

## RECORDING with Spectacle (2 min)

1. Launch Spectacle (menu → type "Spectacle", or `spectacle` in KRunner).
2. Bottom-left, change mode from "Full Screen" to **"Rectangular Region"** — no wait, for video use:
   - In the Spectacle main window, set **"Record Mode" → "Window"** (or "Rectangular Region" if you want just the terminal).
   - Choose **"Capture Mode: Video"** if your version shows it. If Spectacle only offers screenshots, use the fallback below.
3. Click **Record**, drag a rectangle around the terminal window (leave a small margin).
4. Now in the terminal, run:
   ```
   bash poc_referer_fd.sh
   ```
5. Narrate (or it's fine silently — text banners explain everything):
   - Step 1: "Request without Referer → 403, access control exists"
   - Step 2: "Same request, I add a fake Referer → 200, full config data, still no login"
   - Step 4: "Allowlist is strict, but the header is still the only gate"
   - Step 5: "Money paths still need a real session — I'm reporting honestly"
6. Press **Enter** through the 5 pauses; don't rush. When you see **"POC COMPLETE"**, stop the recording (click the stop button / press **Esc** then confirm).
7. Save as: `poc_referer_fd_2026-10-06.webm` into this Proofs folder.

**Fallback if Spectacle won't record video:** Kooha (Flatpak) or OBS Studio (you have OBS installed — Scene + → Window Capture → Konsole → Start Recording; save to the same folder).

---

## AFTER recording

1. Watch it once. Check: every step's output is visible, nothing sensitive is on screen (no passwords, no personal tabs, no notifications).
2. Turn OFF notifications before recording next time: right-click clock → Configure → Do Not Disturb.
3. Optional: rename with date format used by the program portal.

---

## Com Olho submission form — field-by-field

| Field | What to paste |
|---|---|
| **Title** | Referer-Based Access Control on fd.zerodha.com APIs (CWE-290) |
| **Target** | fd.zerodha.com (Zerodha FD — Moderate engagement) |
| **Severity** | P5 (Informational) — or Low if allowed |
| **Vulnerability Type** | Broken Access Control / Authentication Bypass by Alternate Channel |
| **Description** | Copy the Description section from [../submissions/submission_2_referer_authz_fd_draft.md](../submissions/submission_2_referer_authz_fd_draft.md) |
| **Steps to Reproduce** | The script IS the steps. Paste: `bash poc_referer_fd.sh` + mention each curl command shown in the video. Also paste the 3 curl one-liners from the draft's "Steps to Reproduce" |
| **Impact** | Unauthenticated scripted access to partner/issuer config; client-controlled header decides authorization; money-paths unaffected (fair reporting helps credibility) |
| **PoC Video** | Upload `poc_referer_fd_2026-10-06.webm` |
| **Extras** | Attach the script file itself + note "verified 2026-10-06, endpoints live" |

---

## Expectation setting (important)

- This is a **P5/hardening** report. Com Olho's rejection rate is high (your first P3 got dup'd); a clean video + honest impact + a second affected endpoint makes it your **strongest possible single-file submission** from what's verifiable without a login.
- If you want P2/P3-grade: the next tests need a **logged-in** fd.zerodha.com session (OAuth redirect_uri abuse, SMS-sender abuse). See [../recon/hexstrike_run_20261005/SUMMARY.md](../recon/hexstrike_run_20261005/SUMMARY.md) → Next Steps.
