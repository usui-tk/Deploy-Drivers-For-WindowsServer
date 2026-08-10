# Inventory Reconciliation Tool

`Compare-ResearchDeploymentInventory.ps1` (1.0.0) joins the research
accepted-baseline inventory (`tools/amd-chipset-driver-research/`, 25 AMD
chipset releases) against a deployment run's `inf_inventory.csv` and
classifies every deployment row. It formalizes the 2026-08-09
reconciliation session (audit v5 R5-H05 / feedback R2), whose analysis
established full metadata coverage of a real field run, into a
re-runnable asset.

## Usage

```powershell
pwsh ./Compare-ResearchDeploymentInventory.ps1 `
    -ResearchInventory   <path to amd-chipset-driver-inventory.csv> `
    -DeploymentInventory <path to inf_inventory.csv from a deploy run> `
    -ExtractionRoot      <optional: extracted installer tree>          `
    -KnownExplanations   <optional: adjudicated-delta allowlist JSON>  `
    -OutputPath          <delta report JSON>
```

Exit code: **0 iff `UnexplainedDeploymentOnly = 0`** (the W11 exit
criterion; also the hard gate for the W12/W15 static-extraction waves),
1 otherwise.

## Classification

| Class | Meaning |
|---|---|
| `MatchedDirect` | name+version present in the research baseline |
| `MatchedVariant` | version found on a suffix-versioned CAB entry (`name.infN`) under `-ExtractionRoot` — the MSI external-CAB multi-version convention |
| `MatchedNormalizedName` | name matches after `-`/`_` separator normalization; version matches |
| `ExplainedDeploymentOnly` | listed in `-KnownExplanations`; every entry requires an operator adjudication `Reason` |
| `DeploymentOnly` | nothing explains the row — counts against the exit criterion |
| `ResearchOnly` | informational: a deploy run sees one release, the baseline sees 25 |

Normalization rules (codified from the session analysis): names are
lowercased with `-`/`_` unified; the version key is the version
component of the composite `DriverVer` (after the last comma); INF reads
under `-ExtractionRoot` tolerate UTF-16LE without BOM, as observed in
real AMD `Data1.cab` payloads.

## Scope — evidence, not policy

The tool is read-only and independent of the deployment pipeline; no
pipeline decision consumes it at run time. Parity is established at the
**metadata level** (normalized name + version). Optional content-hash
upgrade on an operator bench: run `Get-FileHash` over the cached
installer and the extracted INF tree and compare against the baseline's
`InfSha256` column; record the result alongside the delta report.

Reading guide for the delta report: TESTING §46 in the repository root.
