# Publication Policy

## Commit surface

`public/**` is the only generated commit surface.

The following are runtime staging and MUST NOT be automatically committed beyond `.gitkeep`:

- `inventory/**`
- `private/**`
- `work/**`
- generated runtime content under `reports/**`

Reviewed source files such as the PowerShell script, schemas, data contracts, and authored documentation are normal source content outside `public/**`.

## No post-generation editing

Generated `public/**` files MUST NOT be hand edited. Fix the generator or reviewed source data and regenerate.

The generator writes `HandEdited=false` in `public/publication-manifest.json`.

## Byte contract

- JSON: UTF-8, no BOM, LF, compact canonical generator output.
- Markdown: UTF-8, no BOM, LF.
- CSV, if introduced later: UTF-8, no BOM, LF and generator-owned quoting.

A publication run fails on BOM, CR bytes, invalid JSON, manifest hash mismatch, source-script hash mismatch, or an unmanifested generated public file.

## Provenance

The public manifest binds:

`Invoke-AmdNpuDriverResearch.ps1 SHA-256 -> generated public files (path, length, SHA-256)`

Private run evidence separately records runtime, source input paths, and input ZIP hashes. Public release data stores artifact file names and content hashes but not local host paths.

## Vendor payloads

AMD ZIP/EXE/INF/CAT/SYS files are research inputs and are not redistributed by this toolkit preview. The public dataset records hashes and observations only.

## Runtime acquisition and failure evidence

Default no-argument runs may download AMD NPU ZIPs into `inventory/**`. Those files are runtime inputs and are excluded from Git by `.gitignore`; they are not part of `public/**`. Reviewed download URLs/hashes live in `data/published-driver-artifacts.json`.

Private evidence is finalized even when a research stage fails. Failure Evidence ZIPs are diagnostic runtime artifacts and remain outside the commit surface. Vendor ZIPs are excluded from the archive unless the operator explicitly requests `-IncludePackagesInEvidence`.

Public generation is staged under the run workspace and promoted only after validation. A failed candidate must not destroy the previously validated repository `public/**`.

## Collector evidence promotion boundary

`tools/Collect-AmdNpuHardwareIdentityEvidence.ps1` is reviewed source content, but every ZIP/directory it produces is **Private / Runtime / Non-Commit** input. Raw transcripts, OEM INF snapshots, XRT JSON/text, host/user identity metadata, local paths, and service-binary evidence MUST NOT be copied into `public/**`.

Generalized facts MAY be promoted only after review into a source-data contract such as `data/observed-runtime-evidence.json`. The generated public representation is then regenerated from that reviewed source. The promotion process must preserve provenance hashes while excluding unnecessary host-specific/private fields. Client-runtime evidence MUST remain distinct from Windows Server runtime proof.
