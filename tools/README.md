# Repository research tools

This directory contains standalone research and evidence tooling that supports `Deploy-Drivers-For-WindowsServer` without becoming part of the deployment pipeline itself.

## Layout rule

Each independent research family uses one second-level directory:

```text
tools/<tool-name>/
```

Examples:

- `tools/amd-chipset-driver-research/` — AMD Ryzen chipset release/package/WDF research.
- Future example: `tools/amd-graphics-driver-research/`.

PowerShell tools follow the project policy of aggregating executable logic into a single `.ps1` file whenever practical. Generated evidence, downloaded vendor binaries and extraction workspaces are not source artifacts and should not be committed unless explicitly designated as a reviewed baseline dataset.
