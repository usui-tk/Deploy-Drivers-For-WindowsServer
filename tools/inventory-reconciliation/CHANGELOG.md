# Changelog — inventory-reconciliation

## 1.0.0 (2026-08-10)

- Initial release: typed reconciliation of the research accepted
  baseline against deployment `inf_inventory.csv` with suffix-versioned
  variant resolution (UTF-16LE no-BOM tolerant), separator-normalized
  name matching, an operator-adjudicated allowlist, SHA-256-pinned
  inputs and the `UnexplainedDeploymentOnly = 0` exit criterion
  (rc-encoded, gate-friendly). Implementation note: `List[object]`
  values are materialized via `.ToArray()` — wrapping the list directly
  in `@()` throws `Argument types do not match` on pwsh 7.4.
