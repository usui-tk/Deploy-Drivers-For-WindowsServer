# NPU live-source verification correction — 2026-08-21

## Corrected finding

REV65 incorrectly concluded that AMD's live `latest` documentation identified
Ryzen AI Software `1.7.1` and driver `32.0.203.280` as the current production
line. That conclusion was derived from stale search-index material rather than
the authoritative installation page and is retracted by REV66.

The frozen and live sources are:

- <https://ryzenai.docs.amd.com/en/1.8/inst.html> (version-pinned citation)
- <https://ryzenai.docs.amd.com/en/latest/inst.html>

The Ryzen AI 1.8 documentation identifies Ryzen AI Software `1.8.0`. It states driver
`32.0.203.280` or newer as the minimum driver requirement and identifies NPU
driver `32.0.203.376` as the production driver for:

- Phoenix;
- Hawk Point;
- Strix;
- Strix Halo;
- Krackan Point.

## Correct interpretation

The checked-in 1.8.0/376 publication record and AMD's current `latest`
installation page agree. There is no 1.7.1/280 live-publication drift requiring
a special production-policy hold.

Driver 280 remains a retained research and regression line. It is not an
automatic fallback and does not replace the reviewed 376 production-family
preference. The 376 statement remains publication evidence only; it does not
replace normal INF applicability, target-build, signature, runtime or
deployment authorization gates.

## REV66 disposition

REV66 corrects documentation and management records only. PowerShell source,
reviewed data, schemas and generated `public/**` files remain byte-identical to
REV65. No Windows rerun is required for this documentation-only correction.

The original filename is retained so links created by REV65 remain resolvable;
its content now records the correction rather than an active drift finding.

REV68 adds the version-pinned `/en/1.8/` citation because `/en/latest/` is a
moving alias and was observed to produce stale-index ambiguity during both the
REV65 correction and Claude Cycle A review.
