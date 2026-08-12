# AMD Chipset Driver Research — Historical Reports Index

The top-level documentation describes the stable current v2.0.0 contract. This directory retains generated runtime-report locations and authored historical research/qualification records that explain how specific behaviors were discovered and validated.

Use:

- `../README.md` for the current entry point;
- `../SPEC.md` for normative behavior;
- `../TESTING.md` for current release gates;
- `../RESEARCH-NOTES.md` for consolidated engineering knowledge;
- `../PUBLICATION-POLICY.md` for the generated-output trust boundary.

## Authored design history

`design-history/` contains detailed narratives that are still valuable evidence but are too specialized for the tool top directory.

| Report | Topic |
|---|---|
| `design-history/QT-SELECTOR-REVERSE-ENGINEERING.md` | Detailed major-version Qt selector reverse engineering, exact-binary predicates, and Windows qualification context |
| `design-history/INF-ANALYSIS-SYNC.md` | Historical Chipset/Graphics INF semantic synchronization contract and implementation lessons |

These files were moved from the tool top directory during the v2.0.0 documentation alignment. Their historical content is retained; current stable conclusions are consolidated in `RESEARCH-NOTES.md` and normative requirements in `SPEC.md`.

## Generated runtime reports

The toolkit may generate runtime staging reports beneath `reports/**`. Generated commit-safe reports are published beneath `public/reports/**` according to `PUBLICATION-POLICY.md`.

Runtime generated reports are not automatically repository-tracked merely because they are Markdown.

## Historical-report policy

Historical reports MAY retain development-version terminology, old file locations, and context that was true when a behavior was qualified.

They SHOULD NOT be treated as the current operational/normative contract when they conflict with the current top-level v2.0.0 documents.

New one-off qualification/reverse-engineering narratives SHOULD normally be placed under `reports/**` rather than added to the tool top directory.
