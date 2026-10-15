# Pre-Requisite Assessment: Account Creation & Program Scope

**Date**: 2026-09-23  
**Engagement**: Optus Managed Bug Bounty (Bugcrowd: optus-mbb-og)

---

## 1. Bugcrowd Program Scope (Confirmed)

- **Program URL**: https://bugcrowd.com/engagements/optus-mbb-og
- **In-scope target confirmed**: `https://gateway.optus.com.au/api/ai-search/search/v1`
  - Description: "Optus - AI Search: Generative AI based search capability for the My Optus app"
- **Broader scope**: `*.optus.com.au`, My Optus Mobile Apps
- **Test credentials provided by program**: None — no pre-provisioned researcher accounts
- **Restrictions on account creation**: None explicitly stated; standard Bugcrowd RoE apply

---

## 2. Optus Self-Signup Flow Assessment

### URLs tested (observation only, no data submitted)

| URL | Result |
|-----|--------|
| `https://www.optus.com.au/register` | Redirects → `/my-account-login` |
| `https://www.optus.com.au/join` | Marketing/catalog redirect |
| `https://www.optus.com.au/registration` | "Resend registration email" form |
| `https://www.optus.com.au/my-account` | Login only, no self-signup option |

### Key finding: No standalone self-signup exists

Optus does **not** offer a free online account creation flow for non-customers.
The registration page (`/registration`) only serves to re-send a verification
email to **existing customers** who joined Optus via a service purchase.

It requires:
- Email address
- Date of birth

And states: *"When you first joined Optus, you would've received an email to
verify your email address and set up an online account."*

### Implication

An Optus account can only be obtained by:
1. Purchasing an Optus mobile/SIM/broadband plan (commercial activity)
2. Being an existing Optus customer

Neither constitutes a free "researcher self-signup."

---

## 3. Path Forward

Since no self-signup exists and no test credentials are provided:

### Option A — Contact Program Owner (Recommended)
Submit a message to the Optus Bugcrowd program asking for researcher
test account credentials. This is the correct approach per Bugcrowd
standard practice when no credentials are provided.

Message template:
> "Hi, I am researching the AI Search endpoint
> (https://gateway.optus.com.au/api/ai-search/search/v1) which is
> listed as in-scope. This endpoint appears to require an authenticated
> Optus account. Optus does not offer free self-signup for non-customers.
> Could you please provide researcher test credentials, or confirm an
> alternative approach?"

### Option B — Existing Optus Account
If you currently have or later obtain a legitimate Optus service
(mobile, broadband), you can register and test against your own account.

### Option C — Public Endpoint Only
The `/ai-search-public/search/v1` endpoint (observed in previous session)
does not require authentication. Testing on that endpoint is possible
now without an account, though it is a different endpoint than the
in-scope target.

---

## 4. Confirmed In-Scope Endpoint vs Captured Endpoint

| | Captured (Phase 1) | Bugcrowd In-Scope |
|-|--------------------|-------------------|
| Path | `/api/ai-search-public/search/v1` | `/api/ai-search/search/v1` |
| Auth | x-apikey (static) | Bearer token (authenticated) |
| Account required | No | Yes (Optus customer) |
| Tested | Yes (WAF blocked) | Not yet |

The original hypothesis targets the **authenticated** endpoint.
The browser capture was from the **unauthenticated public** endpoint.
These are two different APIs with different authorization models.

---

## Status

| Item | Status |
|------|--------|
| Bugcrowd program confirmed in-scope | ✅ |
| Self-signup available | ❌ Not available |
| Test credentials from program | ❌ None provided |
| Recommended next action | Contact program owner for credentials |
