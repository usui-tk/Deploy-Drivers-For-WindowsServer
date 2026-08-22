# NPU Windows Client Signature Qualification — Gate A

> **Accepted historical gate record.** This command and PASS contract apply to
> the `1.2.2-dev` source named below. They are not a pending command for the
> current `3.0.0` source and do not qualify Windows Server runtime or
> deployment. Current minimum gates are defined by `TESTING.md`.

## Purpose

This documents the accepted minimum-sufficient first real-machine gate for NPU
Toolkit `1.2.2-dev`. It tested the implemented Windows Authenticode, catalog and
SignTool paths without installing an AMD driver or modifying a package.

The hypothesis is:

> On Windows Client, the default full-research corpus resolves to all three
> reviewed public artifacts, certificate verification resolves to exactly the
> two current NPU package cases, and every extracted kernel binary is fully
> verified through its correlated catalog for the required kernel and four
> target-OS policies with no static signature integrity failure.

## Prerequisites

- Windows 10 or Windows 11 Client; Windows Server must not be used for Gate A.
- Windows PowerShell 5.1.
- Windows SDK SignTool installed and discoverable by the toolkit.
- 7-Zip installed or an explicit `-SevenZipPath` supplied.
- Internet access to the reviewed AMD publication URLs, unless the exact files
  already exist in the toolkit cache.
- Sufficient free space for all three reviewed packages and extraction.

Do not install AMD drivers, import certificates, enable test signing or disable
Secure Boot for this gate.

## Exact command

Open Windows PowerShell 5.1 in the NPU toolkit directory and run:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

.\Invoke-AmdNpuDriverResearch.ps1 `
  -Stages Test,Discover,Metadata,Acquire,Extract,Inspect,Signature `
  -RequireWindowsClientSignatureQualification `
  -SkipPublicExport `
  -EvidenceLabel NPU-1.2.2-WindowsClient-Signature-Gate-A
```

If automatic 7-Zip discovery fails, repeat only after confirming its path and
add, for example:

```powershell
-SevenZipPath 'C:\Program Files\7-Zip\7z.exe'
```

Do not add `-PackagePath`, `-ArtifactId`, `-SkipEvidenceArchive` or
`-IncludePackagesInEvidence`.

## Accepted result and version binding

The first 1.2.1-dev Gate A attempt failed during `Test` on Windows PowerShell
5.1 because a single selected artifact was unwrapped to a scalar before
`.Count` access. That attempt is diagnostic Evidence only and does not qualify
the signature engine. The corrected 1.2.2-dev run then passed all seven selected
stages with exit 0 and is the accepted Gate A Evidence. Do not submit 1.2.1-dev
as Gate A.

Accepted result summary:

- Windows PowerShell 5.1.26100.9168 / Windows Client;
- three of three reviewed NPU packages acquired, extracted and inspected;
- two current NPU package cases selected for deep certificate verification;
- 169 parsed static signature envelopes, zero parse failures and zero PE digest
  mismatches;
- two of two kernel binaries fully covered by catalog-bound required profiles;
- zero catalog-association gaps and zero required-profile non-zero exits;
- `WindowsClientQualification.Status = Pass`; no package mutation.

Version 1.2.3-dev is a presentation-only follow-up: it clarifies the 3-package
research scope versus 2-package certificate scope and includes final assessment
in the archived transcript. It does not change the accepted decision engine, so
another real-machine Gate A is not required solely for that correction.

## Executable PASS conditions

The run must finish with `FINAL RESULT : Pass` and `EXIT CODE : 0`.
`snapshot/inventory/host/signature-native-verification.json` must contain:

```text
WindowsClientQualification.Requested = true
WindowsClientQualification.Status = Pass
ExecutionContext.ExecutionClass = WindowsClient
Tool.Status = Available
ArtifactSelectionPolicy = NewestWithinEachCurrentNpuTypeCase
CandidateArtifactCount = 3
AnalyzedArtifactIds count = 2
MutationPerformed = false
```

The embedded coverage must report:

```text
KernelFileCount > 0
FullyCoveredKernelCount = KernelFileCount
CoverageGapKernelCount = 0
AssociationUnavailableKernelCount = 0
RequiredProfileNonZeroCount = 0
EnvelopeParseFailureCount = 0
PeDigestMismatchCount = 0
```

## What to return

Return only the generated
`AmdNpuDriverResearchEvidence_*_Windows_NPU-1.2.2-WindowsClient-Signature-Gate-A.zip`.
The raw downloaded AMD packages are not required.

## Hold point disposition

The supplied Client Evidence was reviewed, its exact source/package hashes were
verified and Gate A was accepted. This does not automatically authorize a
Windows Server run: a separate purpose and explicit authorization are still
required before crossing that platform boundary.

A signature-policy PASS is not driver installation, kernel load, Code Integrity
runtime or NPU workload proof.
