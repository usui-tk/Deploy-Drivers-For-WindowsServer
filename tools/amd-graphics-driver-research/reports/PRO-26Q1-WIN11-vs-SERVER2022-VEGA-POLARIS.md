Both sibling artifacts use Display Driver version `31.0.21924.61`, but they are not the same driver package.

- Win11 primary INF: `u0197745.inf`, SHA-256 `c0ef638b92af82492f647d183d0ef7a5fea84ba1b2c30c03d9efa2ca3ce96762`
- Server primary INF: `u2197744.inf`, SHA-256 `d88f4b551db22ad12e20157edd3cc6b32514bcf69c2512e09a907a81d521a45d`
- Win11 topology: 343 HWIDs
- Server topology: 314 HWIDs
- All 314 Server HWIDs are contained in the Win11 set.
- Win11 contains 29 additional Display HWIDs; Server contains 0 unique HWIDs not present in Win11.
- Win11 targeting: ProductType 1, minimum build 16299.
- Server targeting: populated ProductType 2/3, minimum build 20348; less-specific Server/DC sections are empty.
- Common INF basenames: `amdafd.inf`, `amdfendr.inf`, `amdocl.inf`; all three are byte-identical by SHA-256 across the two artifacts.
- `amdkmdag.sys` is referenced by both primary Display INFs but its observed SHA-256 differs between the two artifacts.
- The Server INF additionally declares `amdgpuv` / `amdgpuv.sys` evidence.

This confirms that AMD's native Server package is not merely the Win11 INF with ProductType changed: it also narrows HWID coverage and carries a different core Display binary payload while retaining several byte-identical shared component INFs.
