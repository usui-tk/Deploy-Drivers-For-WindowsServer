# AMD Chipset Selector Major-Version Comparison — 8.x through 2.x

Development line: `1.2.8-qt-dev`  
Scope: representative releases **8.07.16.1035 → 7.11.26.2142 → 6.10.17.152 → 5.08.02.027 → 4.08.09.2337 → 3.10.08.506**, plus Windows-live static topology evidence for **2.04.04.111**. Exact compiled contracts remain 3.x-8.x.

## Executive result

The six code-level-reversed representatives split into two clearly observable selector generations. **3.x through 6.x** are PE32 x86 Qt5 selectors with Client-only `Info.xml`, no recovered `DevID.xml`, and unmatched OS enum `3`. **7.x and 8.x** are x64 Qt6 selectors with `DevID.xml` and unmatched enum `-1`. The major structural boundary is therefore **6.x → 7.x**. Windows-live evidence now adds 2.x canonical acquisition and static topology, but not code-level predicate proof.

This does not make the older four binaries one interchangeable contract. Every predicate remains exact release + exact selector-SHA-256 scoped. For 3.x-6.x only OS classification and Client XML filtering are code-level proven; hardware predicates remain unresolved.

## Comparison matrix

| Major | Release | Selector architecture / Qt | Selector FileVersion | Products | DevID mappings | INF | Unmatched OS enum | Evidence scope |
|---|---|---|---:|---:|---:|---:|---:|---|
| 2.x | `2.04.04.111` | `Qt_Dependancies/Setup.exe`; architecture/Qt generation unresolved from shared evidence | unresolved | 26 | 0 | 24 | unresolved | canonical acquisition + static topology observed; compiled predicates unresolved |
| 3.x | `3.10.08.506` | x86 / Qt5 | `3.0.0.0` | 27 | 0 | 16 | `3` | OS/XML proven; hardware unresolved |
| 4.x | `4.08.09.2337` | x86 / Qt5 | `3.0.0.0` | 39 | 0 | 24 | `3` | OS/XML proven; hardware unresolved |
| 5.x | `5.08.02.027` | x86 / Qt5 | `3.0.0.0` | 47 | 0 | 27 | `3` | OS/XML proven; hardware unresolved |
| 6.x | `6.10.17.152` | x86 / Qt5 | `6.0.0.0` | 53 | 0 | 28 | `3` | OS/XML proven; hardware unresolved |
| 7.x | `7.11.26.2142` | x64 / Qt6 | `7.0.0.0` | 62 | 38 | 31 | `-1` | OS/XML + FILTERUSB + RYZENPPKG proven |
| 8.x | `8.07.16.1035` | x64 / Qt6 | `7.0.0.0` | 64 | 41 | 31 | `-1` | OS/XML + FILTERUSB + RYZENPPKG proven + 3-host dynamic corroboration |

## Exact selector identities

### 2.04.04.111 (Windows-live static evidence)

- canonical outer ZIP: 52,428,763 bytes; SHA-256 `d23a9cc4be06ab46c88918e523d11a96ca56b132f3b4646d2e8f9e17abf97185`
- acquisition status in all three supplied Windows runs: `Downloaded`, valid ZIP, not HTML
- nested `AMD_Chipset_Software.exe`: SHA-256 `14635145e1ee67c3575f5962338bb5d333a8debcbcda61ce55744063a4e28e5f`, x86 NSIS outer installer
- nested `AMD_Chipset_Drivers.exe`: SHA-256 `735c95df6888212e4856846b135119a4c2e512695b289dee94637d33d3c2f8c2`; ISSetupStream type 3
- recovered MSI SHA-256: `9d7e92a494bf64d033bebcc6cc94ed22ace084f4e5faa0a5e5b6ba901cc4cb08`
- selector candidate path: `Qt_Dependancies/Setup.exe` (historical spelling)
- selector candidate SHA-256: `24cd52cc5a1eff6e082b2408681e4e90d759ef3ddcc8fedd9077fb632cd8bd76`
- `Info.xml`: 26 Product records; Windows 7 / Windows 10 labels; no recovered Brand values; no Server-like records
- one APS XML is byte-identical to the preferred `Info.xml`; no `DevID.xml` is recovered
- 24 INF files extracted; no code-level selector contract is claimed because raw selector bytes are excluded from the shared evidence

### 3.10.08.506

- outer SHA-256: `851c0364acd6ec91c54f260729f875de727541b2acb0f5e8930ab51227ce2f53`
- `Qt_Dependencies/Setup.exe`: 1,605,120 bytes
- selector SHA-256: `4a0cf13c66f873319ff44eba1867f9cc7dc865d0f422c007bcb25c6ced148ee9`
- ImageBase: `0x00400000`
- preferred `Info.xml` SHA-256: `ab1f1262e16764f5168c33bdf4f08da4d4562a8cc3000656a2228599d5372349`
- OS classifier: `0x0040d2b0`
- Client `Info.xml` filter: `0x0040d720`

### 4.08.09.2337

- outer SHA-256: `833fa334cf50d91db0eece9d44636b7c598ae2f8178a8f21ddcc9a6f1cb964b0`
- `Qt_Dependencies/Setup.exe`: 1,609,216 bytes
- selector SHA-256: `95d0428ea90bee14704bf556a3ad6c91971e63d6d63c0807e9e7a8791d024160`
- ImageBase: `0x00400000`
- preferred `Info.xml` SHA-256: `1b0630b099a15b2f9bcb7ca3e7bb8dd5c2ac13cb6ffa0bf76f6afa713bfc85ac`
- OS classifier: `0x0040cfa0`
- Client `Info.xml` filter: `0x0040d3f0`

### 5.08.02.027

- outer SHA-256: `4bd9580842b8beb17cea3fdafa87b047117447656bbbeeb9a31a3f090d43cbeb`
- `Qt_Dependencies/Setup.exe`: 1,623,448 bytes
- selector SHA-256: `8f4e0f27397786275db0a45282b05bf39da1f16ee9379712a75544fdb49460cf`
- ImageBase: `0x00400000`
- preferred `Info.xml` SHA-256: `6051a7aa6d2021e30a667041f5e8f1abe9049e97d64376595bacb6b93d9d736f`
- OS classifier: `0x0040cfa0`
- Client `Info.xml` filter: `0x0040d3f0`

### 6.10.17.152

- outer SHA-256: `e5bb2e43218248103a0aa8841b906ae96c7391598de416e51373b255819554bf`
- `Qt_Dependencies/Setup.exe`: 1,631,440 bytes
- selector SHA-256: `83d82a4775c0793ace86b1b07f98eadfc262f22d4c275fab2d74b9d86f19379a`
- ImageBase: `0x00400000`
- preferred `Info.xml` SHA-256: `dc9d761a4fbe7c938cfa57690e8dcda50e1f4449bbf4d64dbb92c8186526c9d4`
- OS classifier: `0x0040d8d0`
- Client `Info.xml` filter: `0x0040dd20`

### 7.11.26.2142

- outer SHA-256: `1acd6dadcc3b4bca9451ff170d7a5a049309b827f74cf54b2a3684bf16a34856`
- `Qt_Dependencies/Setup.exe`: 1,391,880 bytes
- selector SHA-256: `7b3714b3ff5c6add70987e0aacb0c5b5a2d523ea13ddf39bf0ac02b5f79d2b1a`
- ImageBase: `0x140000000`
- preferred `Info.xml` SHA-256: `45028b87c8bb4cb960d5782449fbc7b5f1554ed17d1b2d6e112744f8f0709e63`
- OS classifier: `release-scoped x64 VA`
- Client `Info.xml` filter: `release-scoped x64 VA`

### 8.07.16.1035

- outer SHA-256: `1b55dd2dd661d19c5ea4d49bd53b673783e673db9e427b709d404bb1bae66bdb`
- `Qt_Dependencies/Setup.exe`: 1,411,336 bytes
- selector SHA-256: `9b8411b3f77312a770bdac35756081e77c74fb22b7c4c4f367db4f6e5ddf5462`
- ImageBase: `0x140000000`
- preferred `Info.xml` SHA-256: `8a9c31f6ef9874280baeb44e2488b4dc61cdeaa3d565775bd038ac6da2f4a65e`
- OS classifier: `0x140017130`
- Client `Info.xml` filter: `0x1400178e0`

## 3.x → 6.x continuity

Across 3.10.08.506, 4.08.09.2337, 5.08.02.027 and 6.10.17.152, static extraction consistently recovers the NSIS outer package, `Qt_Dependencies/Setup.exe`, Qt5 runtime files, Client-only Windows 10/11 x64 `Info.xml`, one byte-identical APS XML, and no `DevID.xml`. Product records grow `27 → 39 → 47 → 53`. The compiled Caption classifier keeps the unmatched/internal initial value `3` and maps Windows 7/10/11 to `0/1/2`.

The binary addresses are not globally stable: 3.x uses `0x0040d2b0` / `0x0040d720`; 4.x and 5.x use `0x0040cfa0` / `0x0040d3f0`; 6.x moves to `0x0040d8d0` / `0x0040dd20`. This is why the toolkit stores separate exact-hash contracts instead of a broad “Qt5 rule”.

## 6.x → 7.x boundary

7.x changes architecture from x86 to x64, Qt5 to Qt6, introduces `DevID.xml` (38 mappings), changes unmatched OS enum from `3` to `-1`, and expands the product/SET vocabulary. 8.x remains in this newer family and grows to 41 DevID mappings / 64 products.

## Hardware-predicate boundary

The exact 7.x/8.x binaries expose the later `DEV_...` / `REV_...` vocabulary used to prove `SETFILTERUSB` and `SETRYZENPPKG`. The 3.x-6.x representatives do not provide enough equivalent static evidence for those exact rules, so those hardware predicates remain explicitly `Unresolved`.

## 2.x boundary

The Windows-live evidence changes the prior artifact-availability conclusion: all three runs acquired the expected canonical 2.04.04.111 ZIP, and two 7-Zip-capable hosts completed static extraction. Therefore the outer/nested container topology, 24-INF payload, XML contract and `Qt_Dependancies/Setup.exe` selector candidate are now evidence-backed.

The boundary is still deliberate: the evidence ZIP excludes third-party binary payloads, so the selector bytes are not available in this review workspace for disassembly. Consequently 2.x OS classification, architecture/Qt generation of the selector itself, and hardware predicates remain `Unresolved`; 3.x rules are not projected backward.
