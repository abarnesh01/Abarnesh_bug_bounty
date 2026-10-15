# Zerodha Bug Bounty — Recon Summary
**Date:** 2026-10-02  
**Targets Scanned:** 6 in-scope domains  
**Tools Used:** subfinder, katana, nuclei, httpx, http_repeater (HexStrike MCP)

---

## Subdomains Discovered (80+)
Key findings from subfinder:
- `staging.sensibull.zerodha.com` — staging environment
- `kite-beta.zerodha.com` — beta/test environment
- `kite-uat-api.zerodha.com` — UAT API endpoint
- `websocket-test.zerodha.com` — test WebSocket endpoint
- `algorunner.zerodha.com` — algorithmic trading runner
- `bugbounty.zerodha.com` — program portal

---

## Endpoints Crawled
| Target | Endpoints Found |
|---|---|
| varsitylive.zerodha.com | 664 endpoints |
| sensibull.zerodha.com | 833 endpoints |

---

## Vulnerability Scan Results per Target

### varsitylive.zerodha.com (HIGH engagement)
| Finding | Severity | Confirmed |
|---|---|---|
| CORS Arbitrary Origin + credentials: true | HIGH | YES |
| Hosted on AWS S3 (headers exposed) | INFO | YES |
| Weak HSTS (max-age=15552000, <1yr) | INFO | YES |
| CSP unsafe-eval in script-src | INFO | YES |
| Missing X-Frame-Options | MEDIUM | YES |
| Missing X-Content-Type-Options | MEDIUM | YES |
| Cookies SameSite=None (not Strict) | INFO | YES |

### zerodha.com/varsity (HIGH engagement)
| Finding | Severity | Confirmed |
|---|---|---|
| Weak HSTS (max-age=15552000) | INFO | YES |
| CSP unsafe-eval in script-src | INFO | YES |
| Missing X-Content-Type-Options | MEDIUM | YES |
| Cookies SameSite=None | INFO | YES |

### sensibull.zerodha.com (MODERATE engagement)
| Finding | Severity | Confirmed |
|---|---|---|
| CSP in report-only mode (not enforced) | MEDIUM | YES |
| Missing script-src in CSP | INFO | YES |
| Missing object-src in CSP | INFO | YES |
| Missing SRI on external Google Font | INFO | YES |

### fd.zerodha.com (MODERATE engagement)
| Finding | Severity | Confirmed |
|---|---|---|
| Weak HSTS (max-age=15552000) | INFO | YES |
| CSP unsafe-eval in script-src | INFO | YES |
| Cookies SameSite=None | INFO | YES |

---

## Priority Submissions
1. P3 (Moderate) — CORS Misconfiguration with Credentials on varsitylive.zerodha.com → **REJECTED AS DUPLICATE (see Feedbacks/1st_report.md)**
2. P5 (Informational) — Weak HSTS across multiple targets
3. P5 (Informational) — CSP unsafe-eval allowing dynamic code execution

---

## Follow-up Session: 2026-10-05 (HexStrike v6 API @ :8888)
Full results in [hexstrike_run_20261005/SUMMARY.md](hexstrike_run_20261005/SUMMARY.md).
- New verified lead: **Referer-only access control + ignored x-auth-org on fd.zerodha.com APIs (CWE-290)** — draft report at [../submissions/submission_2_referer_authz_fd_draft.md](../submissions/submission_2_referer_authz_fd_draft.md)
- fd money-path endpoints confirmed session-gated (401); nuclei sweep clean; staging.sensibull DNS dead
- Next: authenticated tests — Kite OAuth redirect_uri on fd, share-via-sms rate-limit/phone-spray, request-callback path
