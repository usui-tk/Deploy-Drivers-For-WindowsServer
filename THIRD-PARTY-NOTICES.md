# Third-Party Notices

## ISx

The static `ISSetupStream` decoder embedded in
`Deploy-AMDChipsetDriverOnWindowsServer.ps1` (source of truth:
`tools/source-fragments/AmdStaticExtraction.fragment.ps1`) is an in-script
implementation informed by the ISx project by lifenjoiner. ISx documents and
implements `ISSetupStream`, including version 4 support. This repository does
not bundle the ISx executable; the relevant behavior is implemented inside
the single PowerShell deployment script to preserve the repository's
single-script runtime model. The research toolkit carries the same lineage in
its own notices file:
[`tools/amd-chipset-driver-research/THIRD-PARTY-NOTICES.md`](./tools/amd-chipset-driver-research/THIRD-PARTY-NOTICES.md).

Upstream project: `lifenjoiner/ISx`

License: MIT

> MIT License
>
> Copyright (c) 2017 lifenjoiner
>
> Permission is hereby granted, free of charge, to any person obtaining a copy
> of this software and associated documentation files (the "Software"), to deal
> in the Software without restriction, including without limitation the rights
> to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
> copies of the Software, and to permit persons to whom the Software is
> furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in all
> copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
> IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
> FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
> AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
> LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
> OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
> SOFTWARE.
