# Code of Conduct

## Spirit

This repository hosts a small set of **experimental, lab-grade PowerShell scripts** that patch and re-sign AMD consumer driver INFs (and the Microsoft inbox Bluetooth PAN driver) for Windows Server SKUs. The expectations described here are equivalent to ordinary professional courtesy in a public technical setting, with extra emphasis on the safety implications of self-signed kernel-mode drivers. They are listed explicitly so no one needs to guess.

## Expected behavior

When opening issues, submitting pull requests, posting hardware validation reports, or otherwise interacting with this repository or its maintainer through GitHub:

- **Be specific.** Reference the exact script (`Deploy-AMDChipsetDriverOnWindowsServer.ps1` / `Deploy-AMDGraphicsDriverOnWindowsServer.ps1` / `Deploy-AMDNpuDriverOnWindowsServer.ps1` / `Deploy-MSBthPanInboxOnWindowsServer.ps1`), the revision (`$Script:ScriptVersion`), and the phase ID (P00–I04) being discussed.
- **Be accurate.** Distinguish what you observed (log line text, exit code, Device Manager state) from what you inferred. Mark uncertainty as such. Driver-install diagnostics often have non-obvious failure modes (REBOOT_NEEDED, Phantom OK, exit=259, etc.) — concrete log evidence is far more useful than a paraphrased summary.
- **Be constructive.** If you point out a problem, briefly note what a fix would look like, even if you cannot implement it. If you discover a new platform-specific quirk, share enough log context for the maintainer to add a `SPEC.md` §D entry.
- **Respect the scope.** This repository's purpose is documented in [`README.md`](./README.md) and [`SPEC.md`](./SPEC.md). The target is AMD consumer hardware (Ryzen chipset / Radeon iGPU / Ryzen AI NPU) and one Microsoft inbox driver (BthPan) on Windows Server. Out-of-scope requests (other vendors, server-class EPYC, virtualized environments without the target devices) are politely declined; please do not escalate.
- **Respect the safety implications.** These scripts re-sign kernel-mode drivers with a self-generated certificate, deploy WDAC supplemental policies, and modify the OS driver store. Misuse can cause BSODs, BitLocker recovery prompts, anti-cheat triggers, and unbootable hosts. Treat advice given in issue threads with appropriate caution and do not encourage operators to bypass the disclaimer in [`README.md`](./README.md).
- **Respect the AI-assisted origin.** This repository's documentation (`README.md` / `SPEC.md` / `TESTING.md` and their Japanese versions) was produced with AI assistance and may contain factual errors, hallucinations, or outdated information. Pointing out specific errors is welcome; sweeping critiques of AI-assisted content are off-topic for this issue tracker.

## Unacceptable behavior

The following are not welcome, regardless of motivation:

- Personal attacks, insults, harassment, or discriminatory language directed at the maintainer or any other participant.
- Attempts to pressure the maintainer to accept changes by escalation, mass-tagging, repeated identical messages, or by lobbying through other channels.
- Posting content that is **NDA-protected** (AMD internal driver release notes, leaked Microsoft sample scripts, vendor-internal Windows builds, etc.), or pressuring the maintainer to accept such content.
- Posting **real secrets** (PFX passwords, BitLocker recovery keys, AMD account credentials, API tokens) belonging to anyone — including yourself. Redact before sharing. Log excerpts containing thumbprints can stay; account passwords and recovery keys must be scrubbed.
- Encouraging operators to disable Secure Boot, set `bcdedit /set testsigning on` as a default workflow, run unverified driver binaries, or otherwise bypass the safety guidance in [`README.md`](./README.md) "Disclaimer & at-your-own-risk acknowledgements".
- Spam, advertising, links to unrelated commercial offerings (cracked driver packages, "Windows Server activator" sites, etc.).
- Doxxing, OSINT compilation of the maintainer's personal information, or amplifying such material.

## Enforcement

The maintainer reserves the right to:

- Lock, hide, or delete comments that violate this policy.
- Close issues or pull requests without further engagement.
- Block GitHub accounts that repeatedly violate this policy.

Enforcement decisions are made by the maintainer alone. They are not appealable through this repository; if you believe an enforcement action was unfair, you may contact GitHub Support through their normal channels.

## Scope

This Code of Conduct applies to interactions **within this repository** (Issues, Pull Requests, Security Advisories, Discussions if enabled, and inline review comments). It does not extend to behavior on other platforms, other repositories, or in private channels.
