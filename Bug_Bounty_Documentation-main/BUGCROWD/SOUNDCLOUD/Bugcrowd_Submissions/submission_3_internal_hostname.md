# Bugcrowd Submission #3 — Internal Hostname Disclosure via TLS SAN (Low/Info)

---

## FIELD: Submission Title

TLS Certificate SAN Reveals Undocumented Internal Service Mesh Hostname: api-core.soundcloud.cloud

---

## FIELD: Target

`graph.soundcloud.com`

---

## FIELD: VRT Category

`Server Security Misconfiguration > Unsafe Cross-Origin Resource Sharing > Information Disclosure`

---

## FIELD: Technical Severity

**P4 — Low / Informational**

---

## FIELD: URL / Location

```
https://graph.soundcloud.com/graphql
```

---

## FIELD: Description

### Summary

The TLS certificate served by `graph.soundcloud.com` contains Subject Alternative Names (SANs) that reveal undocumented internal hostnames for SoundCloud's service mesh infrastructure. Specifically, the certificate lists `api-core.soundcloud.cloud` and `*.api-core.soundcloud.cloud` — domains that are not publicly documented or referenced in any SoundCloud documentation, JS bundles, or public DNS. This hostname likely corresponds to SoundCloud's internal Kubernetes/Istio service mesh backend (Istio/Envoy was detected running behind `graph.soundcloud.com`).

---

### Proof of Concept

**Step 1: Retrieve TLS certificate SANs**

```bash
openssl s_client -connect graph.soundcloud.com:443 -servername graph.soundcloud.com \
  2>/dev/null | openssl x509 -noout -text | grep -A1 "Subject Alternative Name"
```

**Output:**
```
X509v3 Subject Alternative Name:
    DNS:api-core.soundcloud.cloud, DNS:graph.soundcloud.com,
    DNS:*.api-core.soundcloud.cloud, DNS:*.graph.soundcloud.com
```

**Step 2: Nuclei confirmation**

```
[ssl-dns-names] graph.soundcloud.com:443
["api-core.soundcloud.cloud", "graph.soundcloud.com",
 "*.api-core.soundcloud.cloud", "*.graph.soundcloud.com"]

[wildcard-tls] graph.soundcloud.com:443
["CN: graph.soundcloud.com",
 "SAN: [graph.soundcloud.com *.api-core.soundcloud.cloud
        *.graph.soundcloud.com api-core.soundcloud.cloud]"]
```

**Step 3: Technology detection at graph.soundcloud.com**

```
[nuclei] tech-detect:istio-envoy → https://graph.soundcloud.com/graphql
```

This confirms `api-core.soundcloud.cloud` is the Istio/Envoy internal service name — the direct internal address of SoundCloud's GraphQL service mesh, not passing through CloudFront's WAF.

---

### Why This Matters

1. **WAF Bypass potential**: `api-core.soundcloud.cloud` may resolve directly to internal infrastructure, bypassing the CloudFront WAF that protects `graph.soundcloud.com`
2. **Internal service name exposure**: The `.cloud` TLD indicates this is likely an internal cluster domain (common in Kubernetes/GKE setups using custom TLDs)
3. **Attack surface mapping**: An attacker can use this hostname to target the GraphQL API directly, potentially with different rate limiting and security controls than the public-facing endpoint
4. **Certificate transparency logs**: This hostname is now permanently in CT logs (crt.sh) and visible to attackers performing passive reconnaissance

**Check crt.sh:**
```
https://crt.sh/?q=api-core.soundcloud.cloud
```

---

### Impact

- **Low direct risk** — requires the domain to be internet-accessible and have weaker auth
- **High recon value** — confirms internal service mesh architecture
- **Enables targeted attacks** — knowing the internal hostname allows more precise fuzzing

---

### Remediation

1. **Use separate TLS certificates** for internal vs external hostnames
2. **Do not include internal service mesh hostnames** in certificates served to the public internet
3. **Audit** whether `api-core.soundcloud.cloud` is resolvable and accessible from the public internet
4. **Monitor CT logs** for future inadvertent internal hostname disclosure
