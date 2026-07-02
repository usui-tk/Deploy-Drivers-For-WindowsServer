# AGENTS.md — Operating Guide for AI-Assisted Contributors

> **Cross-repo governance bridge (class (C) vendored copy).** The governance
> **master** for this repository is the central governance repo
> **[`usui-tk/ai-generated-artifacts`](https://github.com/usui-tk/ai-generated-artifacts)**.
> This file exists locally only because agent tooling auto-loads governance from
> the repo it is working in; it embeds **repository-specific operating facts
> only** and **references everything else by absolute URL** — reference, don't
> restate — so the dual-managed surface stays minimal. The cross-repo model
> itself (three file classes: (A) reference / (B) own-and-reconstruct /
> (C) vendored copy) is decided centrally in
> [ADR 0014](https://github.com/usui-tk/ai-generated-artifacts/blob/main/governance/adr/0014-document-governance-model.md);
> the central operating guide is
> [AGENTS.md (central)](https://github.com/usui-tk/ai-generated-artifacts/blob/main/AGENTS.md).
> Keep this file thin: if a rule is not specific to this repository, it belongs
> in the central repo (or in this repo's own SPEC), not here.

## 1. Session Start Contract (read first, every session)

Read, in order — the content lives in those files, not here:

1. **This `AGENTS.md`** — the bridge (this file).
2. **[`README.md`](./README.md)** — operator view of the four deployment
   scripts (bilingual twin: [`README.ja.md`](./README.ja.md)).
3. **[`SPEC.md`](./SPEC.md) Part A** — the repository-wide invariants. In
   particular **[§A.11](./SPEC.md#a11-static-analysis-with-psapy)** (static
   analysis with `psa.py` — the *latest mainline* policy and fetch workflow)
   and **[§A.13](./SPEC.md#a13-development-workflow)** (development workflow +
   revision discipline).
4. **[`TESTING.md`](./TESTING.md) §0** — the current validation-status
   baseline.
5. **[`CHANGELOG.md`](./CHANGELOG.md) head** — the current revision state of
   each script. Current versions are **never** restated here or anywhere else;
   the truth is each script's `$Script:ScriptVersion` banner plus the
   CHANGELOG head.

Before authoring any change, also read the target script's Part B section in
`SPEC.md` and the PR checklist in [`CONTRIBUTING.md`](./CONTRIBUTING.md).

## 2. Repository shape (facts specific to this repo)

- Four **sister scripts** at the repository root
  (`Deploy-AMDChipsetDriverOnWindowsServer.ps1`,
  `Deploy-AMDGraphicsDriverOnWindowsServer.ps1`,
  `Deploy-AMDNpuDriverOnWindowsServer.ps1`,
  `Deploy-MSBthPanInboxOnWindowsServer.ps1`) sharing one 21-phase model.
  Shared-convention changes are mirrored across all four (sister-script
  alignment) or the divergence is justified in the PR — `SPEC.md` Part A is
  the alignment authority.
- The doc-set (`README(.ja)` / `SPEC` / `TESTING` / `CHANGELOG` + dotfiles) is
  **owned by this repository** (cross-repo class (B)); `SPEC.md` and
  `TESTING.md` are English-only, `README` is a bilingual twin kept in
  lock-step ([§A.12](./SPEC.md#a12-documentation-language-policy)).
- There are **no CI workflows** in this repository; the quality gate is local:
  `psa.py` (latest mainline) with the repository-shipped
  [`.psa.config.json`](./.psa.config.json) must report **0 errors / 0 warnings
  / 0 info** on all four scripts (see the CONTRIBUTING checklist).

## 3. Cross-repo rules (the operative bridge)

- **`psa.py` is never bundled here.** Its canonical home is
  [`quality-tools/powershell-static-analyzer/`](https://github.com/usui-tk/ai-generated-artifacts/tree/main/quality-tools/powershell-static-analyzer)
  in the central repo; acquisition and version policy are owned by
  [`SPEC.md` §A.11](./SPEC.md#a11-static-analysis-with-psapy). Its lifecycle is
  governed centrally
  ([ADR 0009](https://github.com/usui-tk/ai-generated-artifacts/blob/main/governance/adr/0009-psa-canonical-lifecycle.md)).
- **Mutations driven from central-governance sessions arrive as user-performed
  PRs**: the agent prepares a verifiable patch (`git format-patch` /
  `git am`), the human applies and pushes. Agents do not push to this
  repository.
- **Governance-class links use absolute URLs** (they must survive the repo
  boundary); links to this repository's own files stay relative.

## 4. ABSOLUTE rules

1. **Never rewrite `CHANGELOG.md` history** — per-revision history lives there
   and only there (no inline `# rNN:` tags, no in-script `REVISION HISTORY`
   blocks; enforced by `PSAP0003`/`PSAP0004`/`PSAP0005`, see
   [§A.13](./SPEC.md#a13-development-workflow)).
2. **Preserve the encoding contract**: `.ps1` = UTF-8 **with BOM** + CRLF;
   docs = LF ([§A.2](./SPEC.md#a2-source-file-format) owns the rules and the
   verification commands).
3. **Never execute the deployment scripts against a real system** as part of
   authoring or verification — they modify driver/system state. Validation
   evidence comes from `TESTING.md` procedures run by a human on designated
   hardware.
4. **Keep this file thin.** Structural changes to the governance bridge are
   reconciled with the central model (ADR 0014) first; repository-local rules
   go to `SPEC.md`.
