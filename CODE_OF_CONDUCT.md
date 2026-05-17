# Code of Conduct

> 🇯🇵 日本語版は本ファイル下部を参照してください。

## Spirit

This repository hosts a small set of **experimental, lab-grade PowerShell scripts** that patch and re-sign AMD consumer driver INFs (and the Microsoft inbox Bluetooth PAN driver) for Windows Server SKUs. The expectations described here are equivalent to ordinary professional courtesy in a public technical setting, with extra emphasis on the safety implications of self-signed kernel-mode drivers. They are listed explicitly so no one needs to guess.

## Expected behavior

When opening issues, submitting pull requests, posting hardware validation reports, or otherwise interacting with this repository or its maintainer through GitHub:

- **Be specific.** Reference the exact script (`Deploy-AMDChipsetDriverOnWindowsServer.ps1` / `Deploy-AMDGraphicsDriverOnWindowsServer.ps1` / `Deploy-AMDNpuDriverOnWindowsServer.ps1` / `Deploy-MSBthPanInboxOnWindowsServer.ps1`), the revision (`$Script:ScriptVersion`), and the phase ID (P00–I04) being discussed.
- **Be accurate.** Distinguish what you observed (log line text, exit code, Device Manager state) from what you inferred. Mark uncertainty as such. Driver-install diagnostics often have non-obvious failure modes (REBOOT_NEEDED, Phantom OK, exit=259, etc.) — concrete log evidence is far more useful than a paraphrased summary.
- **Be constructive.** If you point out a problem, briefly note what a fix would look like, even if you cannot implement it. If you discover a new platform-specific quirk, share enough log context for the maintainer to add a `SPEC.md` §D entry.
- **Respect the scope.** This repository's purpose is documented in [`README.md`](./README.md) and [`SPEC.md`](./SPEC.md). The target is AMD consumer hardware (Ryzen chipset / Radeon iGPU / Ryzen AI NPU) and one Microsoft inbox driver (BthPan) on Windows Server. Out-of-scope requests (other vendors, server-class EPYC, virtualized environments without the target devices) are politely declined; please do not escalate.
- **Respect the safety implications.** These scripts re-sign kernel-mode drivers with a self-generated certificate, deploy WDAC supplemental policies, and modify the OS driver store. Misuse can cause BSODs, BitLocker recovery prompts, anti-cheat triggers, and unbootable hosts. Treat advice given in issue threads with appropriate caution and do not encourage operators to bypass the disclaimer in [`README.md`](./README.md).
- **Respect the AI-assisted origin.** This repository's documentation (`README.md` / `SPEC.md` / `TESTING.md` and their Japanese versions) was produced with AI assistance and may contain factual errors, hallucinations, or outdated information. Pointing out specific errors is welcome; sweeping critiques of AI-assisted content are off-topic for this issue tracker.

## Unacceptable behavior

The following are not welcome, regardless of motivation:

- Personal attacks, insults, harassment, or discriminatory language directed at the maintainer or any other participant.
- Attempts to pressure the maintainer to accept changes by escalation, mass-tagging, repeated identical messages, or by lobbying through other channels.
- Posting content that is **NDA-protected** (AMD internal driver release notes, leaked Microsoft sample scripts, vendor-internal Windows builds, etc.), or pressuring the maintainer to accept such content.
- Posting **real secrets** (PFX passwords, BitLocker recovery keys, AMD account credentials, API tokens) belonging to anyone — including yourself. Redact before sharing. Log excerpts containing thumbprints can stay; account passwords and recovery keys must be scrubbed.
- Encouraging operators to disable Secure Boot, set `bcdedit /set testsigning on` as a default workflow, run unverified driver binaries, or otherwise bypass the safety guidance in [`README.md`](./README.md) "Disclaimer & at-your-own-risk acknowledgements".
- Spam, advertising, links to unrelated commercial offerings (cracked driver packages, "Windows Server activator" sites, etc.).
- Doxxing, OSINT compilation of the maintainer's personal information, or amplifying such material.

## Enforcement

The maintainer reserves the right to:

- Lock, hide, or delete comments that violate this policy.
- Close issues or pull requests without further engagement.
- Block GitHub accounts that repeatedly violate this policy.

Enforcement decisions are made by the maintainer alone. They are not appealable through this repository; if you believe an enforcement action was unfair, you may contact GitHub Support through their normal channels.

## Scope

This Code of Conduct applies to interactions **within this repository** (Issues, Pull Requests, Security Advisories, Discussions if enabled, and inline review comments). It does not extend to behavior on other platforms, other repositories, or in private channels.

---

# 日本語版

# 行動規範

## 趣旨

本リポジトリは、 AMD コンシューマー向けドライバ INF (および Microsoft inbox Bluetooth PAN ドライバ) を Windows Server SKU 向けにパッチ・再署名する **実験的・ラボグレードの PowerShell スクリプト群** を公開しています。 ここで求められるのは、 公開の技術的な場における通常の専門家としての礼儀作法と同等のものですが、 自己署名カーネルモードドライバの安全性への影響を踏まえ、 通常以上の慎重さが求められます。 誤解を避けるため、 ここに明示します。

## 期待される行動

本リポジトリ・メンテナと GitHub 上でやり取りする際 (Issue 起票、 Pull Request 提出、 ハードウェア検証レポート投稿など):

- **具体的に**: 対象スクリプト (`Deploy-AMDChipsetDriverOnWindowsServer.ps1` / `Deploy-AMDGraphicsDriverOnWindowsServer.ps1` / `Deploy-AMDNpuDriverOnWindowsServer.ps1` / `Deploy-MSBthPanInboxOnWindowsServer.ps1`)、 リビジョン (`$Script:ScriptVersion`)、 議論対象の phase ID (P00〜I04) を明示してください
- **正確に**: 観測 (ログ行のテキスト、 exit code、 Device Manager の状態) と推測を区別し、 不確実な点は不確実と明示してください。 ドライバインストール診断には自明でない失敗モード (REBOOT_NEEDED、 Phantom OK、 exit=259 等) が多く、 言い換えたサマリよりも具体的なログ証拠の方がはるかに有用です
- **建設的に**: 問題を指摘する際は、 実装できなくても修正案の方向性を簡潔に添えてください。 新規プラットフォーム固有の挙動を発見した場合は、 `SPEC.md` §D エントリ追加に十分なログコンテキストを共有してください
- **スコープを尊重する**: 本リポジトリの目的は [`README.ja.md`](./README.ja.md) および [`SPEC.ja.md`](./SPEC.ja.md) に明記されています。 ターゲットは AMD コンシューマー向けハードウェア (Ryzen chipset / Radeon iGPU / Ryzen AI NPU) と Microsoft inbox ドライバ 1 種 (BthPan) を Windows Server 上で動作させることです。 スコープ外の要望 (他ベンダー、 サーバー級 EPYC、 対象デバイスのない仮想環境等) は丁重にお断りします。 エスカレートはお控えください
- **安全への配慮を尊重する**: 本スクリプトはカーネルモードドライバを自己生成証明書で再署名し、 WDAC supplemental policy を deploy し、 OS のドライバストアを変更します。 誤用は BSOD、 BitLocker リカバリプロンプト、 anti-cheat トリガー、 起動不能ホストを引き起こし得ます。 Issue スレッド内のアドバイスは適切な慎重さをもって扱い、 [`README.ja.md`](./README.ja.md) の免責事項を operator が回避することを助長しないでください
- **AI 支援由来であることを尊重する**: 本リポジトリのドキュメント (`README.md` / `SPEC.md` / `TESTING.md` と各日本語版) は AI 支援で生成されたものであり、 事実誤認・ハルシネーション・情報の陳腐化を含み得ます。 具体的な誤りの指摘は歓迎しますが、 「AI 生成コンテンツ全般への包括的批判」 は本 Issue トラッカーの対象外です

## 容認されない行動

動機の如何を問わず、 以下は受け付けません:

- メンテナや他の参加者に対する個人攻撃、 侮辱、 ハラスメント、 差別的言動
- エスカレーション、 無関係な人物への大量メンション、 同一メッセージの繰り返し送信、 他チャネルでのロビイング等により、 メンテナに変更受け入れを強要する行為
- **NDA で保護された内容** (AMD 内部ドライバリリースノート、 漏洩した Microsoft サンプルスクリプト、 ベンダー社内 Windows ビルド等) の投稿、 またはその受け入れの強要
- **実在の機密情報** (PFX パスワード、 BitLocker リカバリキー、 AMD アカウント認証情報、 API トークン) を含むコンテンツ (誰のものであれ自分のものを含む) の投稿。 共有前に必ずマスクしてください。 thumbprint を含むログ抜粋は構いませんが、 アカウントパスワードとリカバリキーは必ずスクラブしてください
- Secure Boot の無効化、 `bcdedit /set testsigning on` を恒常的なワークフローにすること、 未検証ドライババイナリの実行、 その他 [`README.ja.md`](./README.ja.md) 「免責事項・自己責任の確認」 の安全ガイダンスを operator が回避することの推奨
- スパム、 広告、 無関係な商用案件 (海賊版ドライバパッケージ、 「Windows Server アクティベーター」 サイト等) へのリンク
- メンテナ個人情報の暴露行為、 OSINT による個人情報集成、 またはそれを増幅する行為

## 執行

メンテナは以下の権利を保持します:

- 本規範に違反するコメントのロック、 非表示化、 削除
- 追加対応なしでの Issue / Pull Request クローズ
- 本規範に繰り返し違反する GitHub アカウントのブロック

執行判断はメンテナ単独で行います。 本リポジトリ内での異議申立てプロセスはありません。 執行が不当だと考える場合、 GitHub Support の通常チャネルへお問い合わせください。

## 適用範囲

本行動規範は **本リポジトリ内のやり取り** (Issue、 Pull Request、 Security Advisory、 Discussions (有効化されている場合)、 レビューコメント) に適用されます。 他プラットフォーム・他リポジトリ・プライベートな場での行動には及びません。
