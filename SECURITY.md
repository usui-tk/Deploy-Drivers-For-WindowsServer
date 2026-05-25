# Security Policy

## Scope

This repository (`Deploy-Drivers-For-WindowsServer`) ships **experimental, lab-grade PowerShell scripts** that patch AMD consumer driver INFs (and Microsoft's inbox Bluetooth PAN driver) to install on Windows Server SKUs, re-sign the resulting catalogs with a host-generated self-signed certificate, and deploy a WDAC supplemental policy to authorise that certificate as a kernel-mode signer. Because the scripts operate inside the OS-layer driver-signing trust chain, security has a high stake here.

This policy covers:

| In scope | Out of scope |
|:---|:---|
| Defects in any of the four scripts (`Deploy-AMDChipsetDriverOnWindowsServer.ps1`, `Deploy-AMDGraphicsDriverOnWindowsServer.ps1`, `Deploy-AMDNpuDriverOnWindowsServer.ps1`, `Deploy-MSBthPanInboxOnWindowsServer.ps1`) that, when executed by a user, introduce a security risk on the user's system (e.g. an INF patch that opens a privilege-escalation path, a `signtool` invocation that signs more than intended, a WDAC policy that authorises broader trust than documented, an insecure download pattern, credential exposure) | Vulnerabilities in **upstream** binaries the scripts re-sign (`amdgpio.sys`, `amdpsp.sys`, `bthpan.sys`, etc.) — report those to AMD or Microsoft via their normal security channels; this repository only re-signs the existing binaries and never modifies them |
| Documentation in `README.md` / `README.ja.md` / `SPEC.md` / `TESTING.md` (per the documentation language policy in `SPEC.md` §A.12, only `README.md` is bilingual; other docs are English only) that, if followed verbatim, would lead a reader to a clearly unsafe operational decision (e.g. instructing operators to disable Secure Boot, run `bcdedit /set testsigning on` permanently, or skip the BitLocker recovery-key capture step) | Generic discussions about self-signed kernel drivers being inherently risky — the [`README.md`](./README.md) Disclaimer section and the [`CODE_OF_CONDUCT.md`](./CODE_OF_CONDUCT.md) Safety section already cover this |
| Real secrets accidentally committed to this repository (PFX passwords, BitLocker recovery keys, AMD account credentials, API tokens that the maintainer intends to keep private) | Cryptographic thumbprints, public-key fingerprints, or WDAC policy GUIDs visible in committed logs — these are not secrets |
| Static-analysis bypasses that allow a malicious PR to pass `psa.py` checks while introducing a security regression | Static-analysis suggestions for hardening rules not yet implemented — file these as feature requests against [`ai-generated-artifacts/scripts/python/powershell-static-analyzer/`](https://github.com/usui-tk/ai-generated-artifacts) instead |

## Reporting a vulnerability

**Please do NOT open a public GitHub Issue for security-impacting reports.** Public disclosure of a defect in driver-signing logic before a fix is published gives a window where operators continue running the vulnerable version unaware.

Instead, use one of the following private channels:

1. **GitHub Security Advisory (preferred)** — open a private security advisory at <https://github.com/usui-tk/Deploy-Drivers-For-WindowsServer/security/advisories/new>. This creates a private discussion thread visible only to you and the maintainer.
2. **Direct contact** — if you cannot use GitHub's security advisory feature, you may contact the maintainer through the email address listed on their GitHub profile (<https://github.com/usui-tk>).

Please include:

- **Affected script and revision** (e.g. `Deploy-AMDChipsetDriverOnWindowsServer.ps1` r57).
- **Affected phase / function** (e.g. P08 `New-SignedDriverCatalog`, I02 `Install-WdacPolicy`).
- **Concrete reproduction** — a command sequence, an input INF, or a step-by-step description. If the issue depends on platform state (Secure Boot policy, BitLocker status, existing WDAC base policy), describe that state.
- **Observed impact** — what an attacker (or unwary operator) could do as a result. Be specific: "could sign arbitrary INFs" is more useful than "signing logic is broken".
- **Suggested fix** if you have one.

## Response expectations

- **Acknowledgement**: best effort, typically within 7 days. No SLA is guaranteed; this is a personal repository.
- **Triage outcome**: the maintainer will reply with one of: *accepted (will fix)*, *accepted (will document in SPEC.md §D, not patch)*, *out of scope (with reason)*, *duplicate*, or *won't fix (with reason)*.
- **Disclosure timeline**: coordinated disclosure is preferred. If a fix is planned, please allow a reasonable window (typically 30–90 days depending on severity) before public discussion. The maintainer will publish a SECURITY ADVISORY on this repository once the fix lands.
- **Credit**: with your permission, the reporter is credited in the relevant commit message, the `TESTING.md` §6 "Discovered bugs and fix history" table, and/or the `SPEC.md` §D entry. You may also request to remain anonymous.

## What this repository does NOT promise

- A defined turnaround time.
- Backported fixes to historical revisions (a fix lands in the current revision only; users on older revisions should upgrade).
- Compensation, bug bounty, or any monetary reward.
- That every reported issue will be acted upon — see "out of scope" above.
- Protection against malicious operators running the scripts on hosts they do not own. The threat model assumes a cooperative operator following the disclaimer.

## Hardening already in place

For completeness, the following are already enforced by the repository:

- **No real secrets in repository or scripts.** PFX passwords default to empty string; operators who want a real password are expected to change `[string]$PfxPassword = ''` in the param block themselves. See [`README.md`](./README.md) "Self-signed certificate".
- **Per-script workspace isolation.** Each script writes to a dedicated workspace path (`C:\AMD-Chipset-WS`, `C:\AMD-Graphics-WS`, `C:\AMD-NPU-WS`, `C:\MSBthPan-WS`) and uses a separate self-signed cert + WDAC supplemental policy GUID to avoid cross-script trust bleed. See [`SPEC.md`](./SPEC.md) §A.1.4 and §B per-script identification.
- **Secure Boot stays ON.** None of the scripts require, suggest, or perform `bcdedit /set testsigning on` (except behind the explicit `-UseTestSigning` opt-in, which is documented in `README.md` as a last-resort lab option). The default path is WDAC supplemental policy authorisation under Secure Boot, which is the supported Microsoft path on Windows Server 2022+ / Windows 11 22H2+.
- **PSP / TPM driver replacement is gated by an explicit BitLocker warning.** P06 never patches `amdpsp.inf` without surfacing the BitLocker recovery-prompt risk. See [`SPEC.md`](./SPEC.md) §B.1.
- **Self-signed certificate authority is scoped, not blanket.** The supplemental policy authorises ONLY the per-script self-signed cert as a kernel-mode signer for the patched INFs — it does NOT add the cert as a global trusted publisher.
- **Static analysis with `psa.py`.** All four scripts are verified with [`psa.py`](https://github.com/usui-tk/ai-generated-artifacts/tree/main/scripts/python/powershell-static-analyzer/) which includes security-class rules (`PSA5xxx`) covering plain-text password parameters, `Invoke-Expression` usage, broken hash algorithms, hardcoded `ComputerName`, and similar foot-guns. See [`SPEC.md`](./SPEC.md) §A.11.
- **Disclaimer surfaced before any execution path.** [`README.md`](./README.md) opens with an explicit at-your-own-risk warning, and `-Action Install` prints a final confirmation banner that operators must accept.
