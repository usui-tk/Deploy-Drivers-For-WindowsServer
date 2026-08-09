# Deploy-Drivers-For-WindowsServer

AMD のコンシューマー向け Ryzen チップセットドライバ・Radeon グラフィックスドライバ・Ryzen AI NPU (XDNA) ドライバ、 **および Microsoft inbox Bluetooth PAN ドライバ (`bthpan.inf` / `bthpan.sys`)** を **Windows Server 2016 / 2019 / 2022 / 2025** に install できるように、 INF の `ProductType=3` decoration をパッチし、 自己生成証明書で catalog を再署名する PowerShell パイプラインです。

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE) [![PowerShell 5.1+](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://learn.microsoft.com/ja-jp/powershell/) [![Target: Windows Server 2025](https://img.shields.io/badge/Target-Windows%20Server%202025-success.svg)](https://learn.microsoft.com/ja-jp/windows-server/get-started/windows-server-2025)

> **実行する前に必ず最後まで読んでください。** これは *最後の手段としての lab 専用ツール* です。AMD はコンシューマー向け Ryzen プラットフォーム (例: Lenovo ThinkCentre Tiny / ThinkPad / mini-PC に搭載される Cezanne / Renoir / Phoenix APU 等) において Windows Server 2025 を**公式にサポートしていません**。公式ドライバが利用可能な場合は **必ずそちらを優先**してください。本リポジトリは、公式 Server 向けドライバが提供されない狭い局面で、自己署名ドライバチェーンの運用リスクを自分で受け入れた上で利用するためのものです。

> **🆘 NPU スクリプト (`Deploy-AMDNpuDriverOnWindowsServer.ps1`) に関する追加警告:** NPU スクリプトは、チップセット・グラフィックススクリプトと比べて **明らかに危険性が高く、成熟度も大きく劣ります**。**物理 NPU ハードウェアでの検証は本ドキュメント執筆時点で未実施**であり、AMD アカウント自動ダウンロードフローは AMD のフォーム構造変更で**予告なく動作しなくなる**可能性があります。さらに NPU を実際に利用するために必要な Ryzen AI Software (user-mode stack) は **AMD 公式に Windows Server 2025 でサポートされていません**。NPU スクリプトは **実験的・研究用途**のみと位置付けてください。本番運用ツールではありません。詳細は[4 スクリプトのリスク分類](#4-スクリプトのリスク分類)を参照してください。

🇬🇧 **English README is at [README.md](./README.md).**

---

## 目次

- [このリポジトリの存在理由](#このリポジトリの存在理由)
- [⚠️ 免責事項（実行前にお読みください）](#%EF%B8%8F-免責事項実行前にお読みください)
- [現在のステータス: エンドユーザー利用には未対応](#現在のステータス-エンドユーザー利用には未対応)
- [リポジトリの内容物](#リポジトリの内容物)
- [新着情報](#新着情報)
- [4 スクリプトのリスク分類](#4-スクリプトのリスク分類)
- [対応範囲](#対応範囲)
- [リポジトリ構成](#リポジトリ構成)
- [Quick Start](#quick-start)
- [BthPan スクリプト固有の Quick Start](#bthpan-スクリプト固有の-quick-start)
- [NPU スクリプト固有の Quick Start](#npu-スクリプト固有の-quick-start)
- [パイプラインアーキテクチャ (21 phase)](#パイプラインアーキテクチャ-21-phase)
- [パラメータ一覧（スクリプト別）](#パラメータ一覧スクリプト別)
- [出力ファイル](#出力ファイル)
- [UEFI Secure Boot ベースライン](#uefi-secure-boot-ベースライン)
- [コンソール出力フォーマット](#コンソール出力フォーマット)
- [システム要件](#システム要件)
- [自己署名証明書: 有効期限・更新・失効](#自己署名証明書-有効期限更新失効)
- [免責事項・自己責任の確認](#免責事項自己責任の確認)
- [トラブルシューティング](#トラブルシューティング)
- [開発ツール](#開発ツール)
- [開発者向け仕様書](#開発者向け仕様書)
- [ファイルエンコーディング](#ファイルエンコーディング)
- [参考リンク](#参考リンク)
- [ライセンス](#ライセンス)
- [コントリビューション](#コントリビューション)

関連ドキュメント:

- [`CHANGELOG.md`](./CHANGELOG.md) — 時系列のリリースノート（英語のみ、 すべてのリビジョン）
- [`SPEC.md`](./SPEC.md) — 開発者向け仕様書（アーキテクチャ、規約、設計判断の根拠。 **英語のみ**）
- [`TESTING.md`](./TESTING.md) — 物理ハードウェアでの検証結果と回帰テストチェックリスト（**英語のみ**）
- [`CONTRIBUTING.md`](./CONTRIBUTING.md) — Issue の起票・PR の作成・回帰テストの実行方法（**英語のみ**）
- [`README.md`](./README.md) — 本ドキュメントの英語マスター版

---

## このリポジトリの存在理由

コンシューマー向け AMD プラットフォーム (Ryzen 4000 / 5000 / 6000 / 7000 / 8000 mobile / desktop APU、discrete Vega / Polaris / RDNA Radeon GPU、および Ryzen AI 300 / AI Max 300 シリーズの NPU) に Windows Server 2025 をインストールすると、複数の AMD デバイスが **AMD 純正ドライバではなく Microsoft の汎用 in-box ドライバ** (`machine.inf`、`pci.inf`、`hdaudbus.inf`、`display.inf` 等) にバインドされてしまうか、(NPU の場合) 全くバインドされない状態になります。原因は 2 つあります:

1. **AMD の INF ファイルが `[Manufacturer]` decoration に `ProductType=1` (Workstation) 制限を含んでいる**ため、Windows Setup がこれを尊重して Server SKU (`ProductType=3`) ではドライバのバインドを拒否します。
2. **AMD の catalog (.cat) 署名がオリジナルの INF を attest している**ため、INF を編集して Server decoration を追加した時点で署名が無効になり、ドライバが kernel-mode 署名チェックに失敗します。Windows Server 2025 は Secure Boot と HVCI を経由してこれを厳格に enforce します。

本パイプラインは以下の手順で両方の問題を解決します:

- AMD の Workstation `[Manufacturer]` decoration を解析し、**各エントリを `ProductType=3` (Server) で mirror** します (元の Workstation エントリは保持されるため、パッチ後の INF は両 OS 互換になります)。
- `inf2cat /os:Server2025_X64` で新しい `.cat` catalog を生成します。
- **自己生成のコード署名証明書で catalog を署名**し、その証明書を `LocalMachine\Root` + `LocalMachine\TrustedPublisher` に import します。 これが確立するのは **PnP のパッケージ (catalog) 信頼**です — `pnputil` がパッチ済みパッケージを受理するようになります。 これだけで**非 WHQL ドライバをカーネルがロードするようにはなりません**: カーネルイメージ信頼は Code Integrity が独立に評価します。 「WDAC supplemental policy が自己署名証明書を kernel-mode 署名者として認可し Secure Boot ON を維持できる」という本プロジェクト従来の主張は**撤回**しました (SPEC D.58)。 WDAC supplemental policy の配置自体は、 operator が実在を確認済みの base policy を `-WdacBasePolicyGuid` で明示した場合に限り引き続き可能です (SPEC D.58.8)。

---

## ⚠️ 免責事項（実行前にお読みください）

**自己責任でご利用ください。** 本スクリプトは "AS IS" で提供され、 明示・黙示を問わず、 いかなる種類の保証もありません。 作者およびコントリビュータは、 本スクリプトの使用・改変・配布から直接的または間接的に生じる、 損害、 データ消失、 BSOD、 BitLocker recovery prompt、 アカウント停止、 ハードウェア不安定化、 その他いかなる問題に対しても、 一切責任を負いません。

> **🆘 ブリックレベルのリスク (2025 累積観測 + 2026-05-23 単独観測の 2 件)。** WS2019 + Ryzen 5 PRO 4650U (Renoir) における 2 つの独立した実機観測により、 fresh-install の Windows Server SKU に対する `-Action Install` が、 次回起動時にホストを **セーフモードも含めて起動不能**にし、 **OS の再インストールが必要**な状態にし得ることが確認されています。
> - **第 1 観測 (2025)。** `Chipset Install` → `Graphics Install` → `MSBthPan Install` をスクリプト間で **再起動を挟まずに** 連続実行 (当時の Path C WDAC SPF orchestrator を使用) するとブリックしました。 単一の中断なし Install パスで蓄積された kernel-mode driver の置換面の広さ — パッチ済み AMD display driver (`u0201039.inf`、 1066+ HWID variants)、 AMD PSP firmware bindings、 さらに新しい self-signed catalog 群を巻き込んだ boot loader 評価対象の WDAC SPF policy — が相互作用したものと推定されています。
> - **第 2 観測 (2026-05-23)。** その後の fresh-install WS2019 ホストで、 **`Chipset Install` 単独**を Secure Boot ON で実行 (Path C が現存していた時点) しただけで、 同様にブリックしました。 Graphics と MSBthPan は実行していません。 WinRE での `del C:\Windows\System32\CodeIntegrity\SiPolicy.p7b` により起動は復旧し、 I03 で既にインストール済みだった WHQL co-signed AMD driver は **WDAC policy なしでも問題なく load される** こと、 一方で非 WHQL driver (`amdi2c.sys`、 `amdsfhkmdf.sys`) は policy の内容に関わらず kernel CI に拒絶され続けることが、 同時に明らかになりました。
>
> 第 2 観測により「3-script 連続でのみブリック」 という当初の仮説が覆され、 **r70 で Path C 全体を撤回**する判断に至りました。 r70 以降、 4 本の driver script は WS2019 / WS2016 に対してホスト全体の WDAC SPF policy を deploy しません: WHQL co-signed driver は信頼ストア登録のみ (Path A — Secure Boot は ON のままで可) で load され、 非 WHQL driver はオペレーターが firmware で Secure Boot を Disabled にし `-UseTestSigning` で再実行 (Path B) する経路が必要です。 2 件の観測いずれにおいても brick の引き金となった機構 — deploy 済みの `SiPolicy.p7b` を boot loader が新規 install 済みの boot-critical driver 群に対して再評価する挙動 — は、 r70 以降のリリースでは legacy Server SKU に対して**構造的に発生し得ません**。
>
> **ただしリスクはゼロではありません。** Secure Boot ON、 BitLocker 有効、 予備の表示パスなし、 オフライン修復用の予備機なし、 といった本番形態のホストに対する `Install` action は、 **再インストールするまでホストが起動できなくなる確率が無視できない**ものとして扱ってください。 Path A は Path B より安全です。 Path B は firmware での Secure Boot 変更 (BitLocker recovery key の入力を求められる可能性あり — recovery key を必ず手元に) と `-UseTestSigning` 付き再実行の両方を必要とします。 完全なエビデンス連鎖は SPEC §D.30、 2 件の実機インシデントは TESTING §12 を参照してください。

> **🖥️ 物理マシン専用のデプロイモデル。** 本リポジトリの対象は **物理 Windows Server ホスト** (Lenovo M75q Tiny、 ThinkPad X13 Gen 1 AMD 等のコンシューマ Ryzen / Athlon ハードウェア)です。 VM 向けではありません。 **物理マシンにはネイティブの「スナップショット」機構が存在しません** — `-Action Install` の直前に呼び出して数秒でロールバックできる `Hyper-V Checkpoint` も `VMware Revert to Snapshot` もありません。 フルディスクイメージ取得 (Macrium Reflect、 Clonezilla、 Linux Live USB からの dd 等) は可能ですが、 これは **数十分〜数時間かかる、 外部ストレージを要する、 本リポジトリの完全に外側に存在する別ワークフロー**です。 **Windows Server の System Restore は既定で OFF** であり、 有効化したとしても `C:\Windows\System32\CodeIntegrity\SiPolicy.p7b` (ブートローダが System Restore より前に評価する WDAC supplemental policy ファイル) は復元対象に**含まれません**。 結果として、 **物理マシンでの失敗した `-Action Install` には高速ロールバック経路が存在しません**。 復旧手段は WinRE 経由のオフライン修復 ([起動不能状態からの復旧](#起動不能状態からの復旧)を参照) もしくは OS 再インストールに限られます。 **したがってサポート対象のデプロイモデルは「消去・再インストールを受容できる物理マシン」です**。 現在の OS インストール状態を失えない物理ホストでは本スクリプトを実行しないでください。

本スクリプトを実行することにより、 以下を了承したものとみなします:

* AMD End User License Agreement、 Microsoft Windows Software License Terms、 および適用される法令・規制に対する遵守は、 利用者の単独責任である
* AMD の INF をパッチし自己生成証明書で再署名する行為により、 Windows から見た当該ドライバの暗号学的 publisher は AMD でも Microsoft でもなく、 **利用者自身**となる
* 本パイプラインが置換するドライバは **WHQL 認証が無効化される**こと。 対象ハードウェアで Microsoft Premier Support を頼っている場合、 自己署名ドライバ起因の問題はサポート契約の対象外となる可能性がある
* Chipset スクリプトで `-Action Install` を実行する前に **BitLocker 回復キーを記録**する (PSP driver の置換は Platform Security Processor firmware と相互作用し、 次回起動時に回復プロンプトが表示される可能性がある)
* `-Action Install` の後に **ホストが起動できなくなる可能性 (セーフモードを含む) を受容する**。 復旧には WinRE、 インストールメディア、 もしくは別の稼動ホストでオフライン修復が必要となり、 本プロジェクトの第一義的な復旧手段は **OS の再インストール**である。 したがってサポート対象のデプロイモデルは、 **消去・再インストールを受容できる物理マシン**であり、 失えない本番サーバではない。 非破壊的なロールバック経路を確保したい場合は、 `-Action Install` の **前** に事前準備が必要 — 後述の [フルインストール](#フルインストール-chipset-graphics-bthpan) の「Step 0 — 事前準備」を参照。
* **スクリプトは一度に 1 本のみ**を実行し、 再起動の上で `-OnlyPhases V06` で検証してから次のスクリプトを実行する。 `Chipset Install` → `Graphics Install` → `MSBthPan Install` を再起動を挟まずに連続実行することは、 ホストをブリックする結果が実機で観測されている (上記参照)。
* 実行環境を問わず、 スクリプトのソースコードを確認し動作を理解した上で実行する
* **NPU スクリプトに関しては特に**、 実験的・研究用途のツールであることを了承する — 詳細は[4 スクリプトのリスク分類](#4-スクリプトのリスク分類)を参照

本ツールは慎重に運用してください。 **AMD 公式の Server サポート対象ドライバが存在する場合は、 そちらを優先してください**。 本リポジトリは、 公式 Server クラスドライバが提供されておらず、 自己署名ドライバチェーンを自身のハードウェアで運用するリスクを受容できる、 という狭いケースを対象としています。

BitLocker、 アンチチートソフト、 サポート影響、 証明書有効期限などを含む、 完全な自己責任の確認事項は、 後述の[免責事項・自己責任の確認](#免責事項自己責任の確認)を参照してください。 推奨される実行順序と、 ホストが起動不能になった場合の対処については、 [起動不能状態からの復旧](#起動不能状態からの復旧)セクションを参照してください。

---

## 現在のステータス: エンドユーザー利用には未対応

> **🚧 本リポジトリの 5 スクリプトはすべて活発なリファクタリングの途上にあり、
> エンドユーザーが依存してよい状態ではありません。** この節が答える問いは
> ただ 1 つ: 「最新の `main` を取得して、 自分の OS で今日使えるか？」 —
> 答えはどの OS でも **No** です。 その理由を OS ごとに、 そして何が終われば
> 状況が変わるのかを、 ここに明記します。

**リポジトリ全体がこの状態にある理由**: 第三者監査 (2026-08-09) により、
本リポジトリの中心的な署名モデルの主張 — 「WDAC supplemental policy が
自己署名証明書を kernel-mode 署名者として認可し、 Secure Boot は ON のまま」 —
が誤りであると判明し、 **撤回**されました (SPEC D.58)。 この撤回は表現の
問題ではありません: Secure Boot 有効のまま非 WHQL ドライバをロードするとされた、
宣伝上の機構そのものが失われています。 最新リリース時点の是正状況: **P0
(撤回・用語分離・fail-closed な base-policy ゲート) と P1 のウェーブ W1〜W5 が
着地済み**です — Windows Driver Policy とカーネルイメージ信頼の証跡、
非 boolean の信頼分類、 ポリシー有効化の OS 分離と Mode T の明示 opt-in 化、
fail-closed なダウンロード検証と実行ごとの PFX 衛生 (chipset/graphics/BthPan)、
ProjectPreference と実測 PnP rank の分離。 **未完了**: P1 クローズアウト項目
(NPU の PFX 衛生、 カーネル信頼証跡の完成、 ダウンロード上書きの分離、
base policy の機械検証) と P2 の全体。 是正後の実機検証は未実施です。
[TESTING.md](./TESTING.md) に
記録された過去の検証成功はこの訂正および複数の破壊的設計変更より前のものであり、
現在の `main` についての言明として読んではいけません。

### 最新の `main` を自分の OS で今日使えるか？

| OS (build) | エンドユーザー利用可否 | 最新 `main` が実際に行うこと |
|---|---|---|
| Windows Server 2025 (26100) | **❌ 不可 — リファクタリング進行中** | `Install` は証明書を import し pnputil でパッケージを導入します。 自分で実在を検証した base policy を `-WdacBasePolicyGuid` で渡さない限り、 WDAC supplemental policy は**一切**配置されません。 その上でこのパッケージの非 WHQL カーネルドライバがロードされるかは**現行版のどの版でも未検証**であり、 さらに 2026 年 4 月の Windows Driver Policy という、 どの版も実機で対峙したことのないレイヤーが加わっています (SPEC D.58.6)。 |
| Windows Server 2022 (20348) | **❌ 不可 — 実機実行歴なし** | 設計上の挙動は WS2025 と同じですが、 **WS2022 実機でスクリプトが実行されたことは一度もありません** (TESTING §10.6 の capability 行は文書由来)。 |
| Windows Server 2019 (17763) | **❌ 不可** | Secure Boot ON の場合: 現行 AMD パッケージに対して実行は設計どおりの **no-op** で終わります (in-scope 55 INF 中 WHQL co-signature は 0 件のため `-SkipNonCosignedDrivers` は空プランを生成。 フラグなしでは非 WHQL カーネルドライバは kernel CI に拒否されます — WS2019 には supplemental policy の形式自体が存在しません、 SPEC D.39.4)。 Secure Boot OFF の場合: Path B (testsigning) は **lab 専用**の構えであり、 エンドユーザー向け配備ではありません。 |
| Windows Server 2016 (14393) | **❌ 不可** | WS2016 で `Install` が完了したことはありません。 未解決事項が 2 つ: ベンチで遭遇した未解決の **`WDF_VIOLATION` bugcheck ループ調査** (SPEC D.47) と、 構造的な **KMDF 上限** — 現行 AMD ドライバの多くは WS2016 同梱版より新しい KMDF を宣言しており、 どの署名経路でも解決できません (`READY WITH EXCLUSIONS`、 TESTING §37/§39)。 |
| Windows 10 / 11 (Workstation) | **❌ 対象外** | Workstation SKU では `Install` は設計上自動ブロックされ、 `PrepareVerify` のみ実行できます (自己責任の上書きは存在します)。 |

上表に加えてスクリプト別の注記: **NPU** スクリプトは 🆘 experimental で、
どの OS でも物理 NPU ハードウェア上で実行されたことが**一度もありません**
(リスク分類を参照)。 **BthPan** スクリプトはデバイス bind 経路が未検証です
(Bluetooth コントローラのフィクスチャが未整備)。 **証跡コレクタ**は読み取り
専用の随伴ツールで実行自体は安全ですが、 その出力スキーマ自体が監査是正の
リファクタリング途上にあります。

### 何が終わればこの状況が変わるか

1. **P1 監査是正のクローズアウト** — P1 の中核ウェーブは着地済み (ポリシー
   有効化の OS 分離、 カーネルイメージ信頼の証跡、 Windows Driver Policy の
   証跡、 非 boolean の信頼分類、 fail-closed なダウンロード検証、
   chipset/graphics/BthPan の PFX 鍵保護)。 残るのはクローズアウト項目
   (NPU の PFX 衛生、 信頼証跡の完成、 ダウンロード上書きの分離、
   base policy の機械検証)。
2. **P2 監査是正** — E2E カバレッジ表の是正、 lab/production 記述の分離、
   姉妹スクリプト重複の方針。
3. **訂正後モデルに対する OS ごとの実機再検証キャンペーン** — TESTING.md の
   過去の ✅ はすべて訂正前のものであり、 現在には引き継がれません。

これらが完了するまで、 本リポジトリは**開発ツリーおよび研究記録**として
扱ってください。 配備可能なツールではありません。 「何が・いつ実機で実行
されたか」の履歴は TESTING.md が正典です。

---

## リポジトリの内容物

| ファイル | 用途 | 成熟度 |
| --- | --- | --- |
| `Deploy-AMDChipsetDriverOnWindowsServer.ps1` | チップセットドライバパイプライン (GPIO、 SMBus、 PSP、 MicroPEP、 PMF 等)。 ソース: AMD Chipset Software EXE 約 75 MB、 INF 約 67 個。 | **過去実機検証済み** (是正前リビジョン) — M75q Tiny Gen 2 (WS2025) と X13 Gen 1 AMD (Win11 LTSC 2024)。 現行 `main` は再検証待ち。 |
| `Deploy-AMDGraphicsDriverOnWindowsServer.ps1` | グラフィックスドライバパイプライン (Display、 HD Audio、 Audio CoProcessor、 ACP、 USB-C UCSI 等)。 ソース: AMD Adrenalin Edition EXE 約 600 MB、 INF 約 19 個 (Vega-Polaris Legacy ブランチ) または約 67 個 (Phoenix 以降の Main Adrenalin ブランチ)。 | **過去実機検証済み** (是正前リビジョン) — チップセットスクリプトと同一の検証ホスト。 現行 `main` は再検証待ち。 |
| **`Deploy-AMDNpuDriverOnWindowsServer.ps1`** | **NPU (Ryzen AI XDNA) ドライバパイプライン (PHX/HPT/STX/KRK)。** ソース: AMD Ryzen AI Software ZIP 約 250 MB、 EULA gate あり (公開直接 URL なし)。 kernel-mode driver のみ install — Ryzen AI Software user-mode stack は対象外。 | **🆘 実験的・研究用途 — 本番運用不可。** 物理 NPU ハードウェアでの検証は未実施。 AMD アカウント自動ダウンロードは best-effort で AMD 側のフォーム変更で破綻する可能性。 Ryzen AI Software は Windows Server 2025 公式非サポート。 |
| `Deploy-MSBthPanInboxOnWindowsServer.ps1` | **Microsoft inbox Bluetooth PAN ドライバ (`bthpan.inf` / `bthpan.sys`) 有効化パイプライン。** ソース: ホスト自身の `C:\Windows\System32\DriverStore\FileRepository\bthpan.inf_amd64_*` ディレクトリ — **リモートダウンロード不要**。 単一 INF・ 単一 HWID (`BTH\MS_BTHPAN`)。 Phantom OK (bth.inf による代理マッチ) と真の解消 (Class=Net、 Service=BthPan) を Windows Server 上で明示的に区別します。 | **新規** — 初版リリース。 Phase / Secure Boot / WDAC フレームワークは AMD スクリプトと同一を verbatim 継承。 INF パッチ対象が 1 ファイル・ 1 HWID と非常に小さい。 ThinkPad + Intel AX210 + WS2025 build 26100.32860 が第一の物理検証ターゲット予定。 |
| `Collect-WindowsServerConfigurationEvidence.ps1` | **読み取り専用の構成情報エビデンス・コレクタ (r93+)。** OS / デバイス / ドライバストア / 証明書 / ブートセキュリティ / CodeIntegrity / `setupapi` の状態をタイムスタンプ付きエビデンス ZIP に採取し、 PASS / FAIL / REVIEW / INFO 評価レポートを出力する (exit code 0 / 2 / 1)。 単体実行のほか、 デプロイスクリプトの実行時には pre/post ペアとして自動実行される (r94 以降デフォルト。 `-SkipEvidenceCollection` でスキップ可)。 | **New** — 挙動ハーネス検証済み。 実機ホストでの検証は未実施。 |
| `README.md` | 英語版ドキュメント (マスター)。 |  |
| `README.ja.md` | 本ドキュメント (日本語版、 `README.md` と同期翻訳)。 |  |
| `SPEC.md` | 開発者向け仕様書 (スクリプト別詳細、 INF パース戦略、 WDAC policy 構造)。 **英語のみ。** |  |
| `TESTING.md` | 物理ハードウェアでの検証結果。 NPU スクリプトの極めて限定的な検証状況も記載。 **英語のみ。** |  |
| `CHANGELOG.md` | 時系列のリリースノート (すべてのリビジョン)。 **英語のみ。** |  |
| `CONTRIBUTING.md` | Issue・PR ガイドラインと regression test 手順。 **英語のみ。** |  |
| `LICENSE` | MIT License。 |  |

4 つの PowerShell スクリプトは同じ 21 phase アーキテクチャ、 同じ自己署名モデル、 同じ WDAC supplemental-policy パスを共有します。 それぞれ別ワークスペース (`C:\Temp\Workspace_AMD-Chipset`、 `C:\Temp\Workspace_AMD-Graphics`、 `C:\Temp\Workspace_AMD-NPU`、 `C:\Temp\Workspace_Microsoft-BthPan`)、 別の自己署名証明書、 別の WDAC supplemental policy GUID を使用するため、 相互に干渉しません。 4 つのワークスペースはすべて `C:\Temp\Workspace_*` 配下に配置されています (クラスタ管理および一括削除を容易化する目的)。 `C:\Temp` がない場合はスクリプトが自動作成します。 `Collect-WindowsServerConfigurationEvidence.ps1` は読み取り専用の随伴スクリプトとしてこれらの隣に位置し、 専用ワークスペースを持たず、 エビデンスをスクリプトフォルダ (または `C:\Temp`) に書き出します。

---

## 新着情報

**最新リリース: `2026-08-09` — Chipset r117 / Graphics r83** (`project-preference-and-measured-rank`): 監査是正の第 5 ウェーブ (W5) として、 ドライバ選択の物語を「誰の決定か」について正直にしました。 `[C] > [B] > [A]` のカテゴリ override は **ProjectPreference** に改名 — これは自己署名した AMD 固有ドライバを Microsoft 汎用 / ベンダドライバより優先して提出するという*プロジェクトの方針*であり、 客観的なランキングでは**ありません**: Windows はインストール時に独自の rank を計算し、 pnputil は rank の低いドライバをデバイスに強制しません。 V06 は「WILL be replaced」と言うのをやめ、 バケットは **`PROJECT_PREFERS_INSTALL`** (「プランが置換を提出する」) となり、 判定 Reason は自己署名ドライバが「outranks (上回る)」という主張をしなくなりました。 実測側も着地: I04 完了時に `Show-MeasuredDriverRankReport` が `pnputil /enum-devices /drivers` で**実際の PnP 候補リスト**を取得します (fixture テスト済みの新 pure 関数でパース。 `Rank:` は 16進/10進の optional で、 欠落時は「先頭 = best-ranked」という文書化された事実が意味を担います)。 デバイス毎に `[ours]` をマークし、 pnputil ビルドが非対応の場合は捏造せずその事実を表示します。 対象は Chipset/Graphics のみ (決定レイヤーは他に存在しません)。 パーサ fixture は合成であり、 実機検証は operator-pending 項目です (TESTING §43)。 スイート実測: 16 ケース / 680 assertions。

- **`2026-08-09` — Chipset r116 / Graphics r82 / BthPan r64** (`download-verification-and-pfx-hygiene`): 監査是正の第 4 ウェーブ (W4) として、 サプライチェーンと鍵衛生の 2 指摘を是正しました (NPU は対象外 — ダウンロード fallback を持たず、 固定既定パスワードも元々ありません)。 **P1-F**: ダウンロードされる全バイナリを、 実行・展開の直前に **fail-closed の Authenticode 検証**にかけます (**毎回・キャッシュヒット時も含む**) — Windows SDK/WDK インストーラ ('Microsoft Corporation')、 7-Zip MSI ('Igor Pavlov'。 呼び出し側で検証するため canonical なインストーラ unit は非接触)、 AMD インストーラ ('Advanced Micro Devices'。 キャッシュ経路と新規ダウンロード経路の両方。 CDN の癖に対する退避経路として `-Force` は大きな警告付きで続行)。 **P1-G**: 固定の `ChangeMe!2026` PFX パスワードを廃止 — 既定は**実行ごとのランダムパスワード** (32 文字 CSPRNG) となり、 エクスポートされた PFX は Administrators+SYSTEM に ACL 限定、 さらに **Install 完了後に PFX を削除**します (証明書はストアに残り、 P07 が必要時に再生成。 残存 PFX が今回のパスワードで開くかを先に検査します)。 新しい構造契約ケース `Test-DownloadAndPfxHygiene.ps1` を追加 (r115 ツリーに対する陰性対照: 31 件の失敗を名指しで報告)。 スイート実測: 15 ケース / 654 assertions。

- **`2026-08-09` — Chipset r115 / Graphics r81 / NPU r58 / BthPan r63** (`activation-path-os-separation`): 監査是正の第 3 ウェーブ (W3) として、 supplemental policy の有効化経路を OS で分離しました。 一次資料を Microsoft Learn の機能固有節で再検証しています (SPEC D.58.9): **CiTool.exe の同梱は Windows 11 22H2 / Windows Server 2025 から — 本リポジトリが従来主張していた WS2022 には同梱されません** — また supplemental policy は Multiple Policy Format (Windows 10 1903+ / WS2022+) にしか存在しないため、 **WS2016/WS2019 では決して機能しません**。 I02 は single-policy format のホストでは無効な `.cip` を配置する代わりに拒否して return します。 新しい 4 スクリプト共通の pure 関数 `Resolve-SupplementalActivationPlan` (fixture テスト済み) が `citool` / `refreshpolicy-exe` / `wmi-bridge` を選択し、 CIM bridge は「RefreshPolicy.exe の無い WS2022」経路として文書化し直しました。 **Mode T は明示 opt-in になりました**: 従来は WDAC tools が無いホストでは -UseTestSigning を指定しなくても install 実行が BCD testsigning を**暗黙に**有効化しており、 operator が Mode T を求めていないのに boot signing posture が弱められ得ました。 このフォールスルーを廃止し (拒否して return)、 全ての testsigning 書込は `UseTestSigning` 条件節の配下に置かれ、 新ゲート **G-04** ケース `Test-InstallPathMutationGuard.ps1` が AST で機械固定します (あわせて: Windows Driver Policy GUID を削除系コマンドに渡さない・`nointegritychecks` なし・HVCI レジストリ書込なし。 陰性対照は変異コピーで実測)。 裁定 **U3** は条件付きランタイム開示として着地: Windows Driver Policy の evaluation mode 事実の表示は、 policy の実在が証明された Server 2025+ のみ — 2016/2019/2022 には表示しません。 スイート実測: 14 ケース / 615 assertions。

- **`2026-08-09` — Chipset r114 / Graphics r80 / NPU r57 / BthPan r62** (`boot-signing-posture`): 監査是正の第 2 ウェーブ (W2) として、 撤回済み署名モデルのランタイム残滓を一掃しました。 can-load boolean (`EffectiveCanLoadSelfSigned`) は 4 スクリプト全てから削除され、 boot-signing 環境は代わりに **`BootSigningPosture`** を導出します — `testsigning-active` (実測された Mode T lab 経路が開いている) / `supplemental-deployed-unverified` (supplemental App Control policy ファイルは配置済み。 ただし **kernel-load 効果は一切主張しない**) / `closed` — また、 supplemental policy の配置によって install-readiness が READY になることはもうありません。 AS-IS/TO-BE 案内・dry-run・ヘルプ・診断文は正直なモデルに書き換えられました: WHQL/WHCP 署名ドライバはホスト変更なしでロードされ、 プロジェクトの自己署名が確立するのは PackageCatalogTrust のみ、 プロジェクト署名 kernel image の唯一の実測経路は Mode T (`-UseTestSigning`、 Secure Boot OFF、 lab ホスト) です。 `Test-WhqlCoSignature` は P1-D の **`Classification`** 語彙 (`WhcpHdc` / `LegacyCrossSignedNotProven` / `PrivateOrTestSigned` / `Unsigned` / `Unknown`。 AllowListed 値は予約であり決して放出されません — 裁定 Q4) をあわせて出力します。 新オフラインケース `Test-BootSigningPostureSweep.ps1` が gate G-03 をリポジトリ全域で固定します (r113 ツリーに対する陰性対照: 36 件の失敗を名指しで報告)。 スイート実測: 13 ケース / 577 assertions。

- **`2026-08-09` — Chipset r113 / Graphics r79 / NPU r56 / BthPan r61** (`signing-model-correction`): 署名モデルの第三者監査により、 本リポジトリの中心的な主張 — 「Path A は WDAC supplemental policy で自己署名証明書を **kernel-mode** 署名者として認可し、 Secure Boot は ON のまま」 — を裏づける実行記録が本リポジトリに 1 件も存在せず、 実在する実地証拠はむしろ逆の構造を示していること (2026-05-23 の `SiPolicy.p7b` 削除後、 WHQL co-signed ドライバはポリシーが存在しない状態で正常にロードされ、 非 WHQL ドライバはポリシーの有無に関わらず kernel CI に拒否され続けた) が確定しました。 **この主張は撤回します** (SPEC D.58)。 再発防止のため語彙を 3 つに分離: **PackageCatalogTrust** (catalog 自己署名が実際に確立するもの)、 **KernelImageTrust** (Code Integrity が独立に評価)、 **AppControlDecision**。 唯一の挙動変更は撤回のコード化です: supplemental policy はこれまで、 実在を誰も検証していない Windows 標準 base policy GUID を対象にしていました。 **base policy の既定値は廃止**され、 operator が実在を確認済みの base policy (rule option 17 `Enabled:Allow Supplemental Policies` 付きで配置済み) を `-WdacBasePolicyGuid` で明示しない限り、 I02 は supplemental 配置を拒否します — 4 スクリプト byte-identical の admissibility gate で、 拒否はフェーズを閉じて return します (r112 の規律)。 NPU には従来存在しなかった `-WdacBasePolicyGuid` パラメータを追加 (GUID は呼び出し箇所にハードコードされていました)。 新テストケース `Test-SupplementalPolicyGate.ps1` がこれら全てを固定し、 陰性対照は r112 ツリーに対して 23 件の失敗を名指しで報告します。 スイート実測: 9 ケース / 458 assertions。 あわせて是正: 本 README は「PFX はパスワード保護されていない」と記述していましたが、 コードの既定値は `'ChangeMe!2026'` です (監査 L-01)。 Custom Kernel Signers の適用範囲 (Windows 11 24H2+ のみ) と Server 2025+ の Windows Driver Policy は別レイヤーとして文書化: SPEC D.58／再実行の手引き: TESTING §41。

- **`2026-08-09` — Chipset r112 / Graphics r78 / NPU r55 / BthPan r60 / Collector c10** (`gate-before-mutation`): Secure Boot ON のクリーンな Windows Server 2019 での実行結果です。 **I02 は「拒否する」と宣言したうえで処理を続行していました** — `install plan was not fully examined` と表示した直後に経路選択へ落ち、 スクリプト自身が「判定不能」と宣言したばかりのプランがそのまま署名認可へ進んでいました。 このホストでは Path B の前提条件チェックで停止しましたが、 それは Secure Boot についての検査であってプランについてのものではありません。 **もし Secure Boot が OFF だったら、 I02 は空のインストールプランに対して BCD の testsigning を実際に書き込み、 再起動を要求していました。** 拒否ブランチはフェーズを閉じて `return` するようになりました。 また `$Ctx.DegeneratePlan` は P08/P09/V01/V04 では参照されるのに **Install フェーズでは一切参照されていませんでした** — 同じ欠陥の3回目であり、 毎回「そのとき思いついたフェーズ」を追加してきた結果です。 リストに3つ名前を足すのではなく、 **永続状態を変更する全フェーズを単一のゲートの背後に配置**しました。 環境だけで決着する矛盾（Secure Boot ON での `-UseTestSigning`）は起動時に、 `-OnlyPhases I02` による迂回に備えて各フェーズ内でも検査します。 何も変更しなかった Install 実行は、 **何もインストールされず何も変更されていない旨を明示**して終わります — testsigning や信頼ストアへの取り込みは再起動をまたいで残るため、 空プランに対する変更はクリーンインストールでしか元に戻せないからです。 あわせて修正: **全実行が毎回2件の `Get-WinEvent` エラーを出力していました**（健全なマシンで bugcheck イベントが0件なのは good outcome。 PowerShell 5.1 のトランスクリプトは捕捉済みの終了エラーも記録します）。 バナーに `-SkipNonCosignedDrivers` と `-UseTestSigning` を追加しました — これが無いとトランスクリプトを後から解釈できません。 ポストモーテム: SPEC D.57／再実行の手引き: TESTING §40。

- **`2026-08-09` — Chipset r111 / Graphics r77 / NPU r54 / BthPan r59 / Collector c9** (`wdf-observed-vs-documented`): 前リリースは「どのバイナリも保持していない」という理由でホスト UMDF 版の読み取りを停止しました。 正しい判断でしたが不完全でした — 偽陰性を取り除いた一方で、 代わりのものを置かなかったからです。 3つの Windows リリースの実機測定がその欠けた部分を埋めました。 なかでも **Windows Server 2025 で KMDF 1.35 を実測**（Microsoft の公開値は 1.33）したことが決定的でした。 したがって能力表は**訂正するのではなく、 Observed 列と Documented 列に分割**します。 Observed は実測であり優先されます。 Documented は Microsoft が公開する値であり、 **実測値を書き込むことは決してしません** — その列の唯一の用途が実測との比較だからです。 UMDF 要求の判定は復活しますが、 **そのホストの実測 KMDF が文書 KMDF と一致する場合に限ります**。 この一致こそが「公開表がこのビルドに追随できている」ことの観測可能な証拠であり、 隣に並ぶ UMDF 値は同じ表・同じ版から来ているからです。 実測が表を追い越しているビルドでは、 理由を明示したうえで UMDF を未判定とします — Server 2025 はまさにこの出力になります。 あわせて修正: **KMDF 版を PE の誤った側から導出していました**。 ファイルはバージョンを2回保持しており、 両者は食い違います — Server 2019 では同一の `Wdf01000.sys` が数値フィールドで `1.27.17763.1192`、 文字列で `1.27.17763.1` を返します。 導出は数値フィールドを使い、 両方の読みを出力するようにしました。 UMDF 2 ドライバが実際にバインドするライブラリ `WUDFx02000.dll` の存在も実測します。 設計根拠: SPEC D.56／実機での読み方: TESTING §39。

- **`2026-08-09` — Chipset r110 / Graphics r76 / NPU r53 / BthPan r58 / Collector c8** (`degenerate-plan-verify-and-umdf-measurement-fix`): クリーンインストールした Windows Server 2019 での実行1回が、 2件の欠陥を検出しました。 **Verify 側が「正しい空プラン」を失敗として扱っていました** — `-SkipNonCosignedDrivers` が対象 INF のいずれにも WHQL 共署名を見つけず、 P06 は `skipped` で終了し、 P08/P09 もそれを尊重しました。 ここまで設計どおりです。 ところが V01 が「先に前のフェーズを実行せよ」と例外を投げました。 名指しされたフェーズは実行済みで、 正しく判断し、 その旨を出力していたにもかかわらずです。 結果として V02〜V06 が一度も実行されませんでした。 V01 は存在する成果物の検証を続け、 パッチ済み INF の不在は「想定どおり」と報告するようになりました。 V04 は P08/P09 と同様に `skipped` で閉じます。 **ホストの UMDF 版はそもそも測定不能でした** — KMDF を `Wdf01000.sys` から読むのと同じ方法で `WudfRd.sys` から読んでおり、 このホストでは `10.0`、 すなわち**OS のバージョン**が得られていました。 `Wdf01000.sys` は確かに `1.27.…` ですが、 `WudfPf.sys` / `WUDFRd.sys` / `WUDFHost.exe` はいずれも `10.0.17763.9020` であり、 当該ビルドの UMDF 版 2.27 を保持するバイナリは存在しません。 `10.0` は実在するあらゆる要求値より大きく比較されるため、 **すべてのホストで全 UMDF ドライバが黙って「充足」と判定されていました**。 UMDF は「不明」と報告するようになり、 判定できなかった要求は件数を数えて明示します — 尋ねなかった問いは合格ではないからです。 コレクタも同じ導出を持っていたため併せて修正しました。 ポストモーテム: SPEC D.55／再実行の手引き: TESTING §38。

- **`2026-08-08` — Chipset r109 / Graphics r75 / NPU r52 / BthPan r57** (`wdf-requirement-vs-host`): フレームワークの問いは両半分とも揃っていながら、 突き合わせる仕組みがありませんでした — コレクタはホストが提供する版を、 4本のスクリプトは各 INF が要求する版を読みますが、 比較は実行後に2つの成果物を手作業で開くしかなかったのです。 P05 がホストのフレームワーク版を1回読み、 直前に構築したインベントリと突き合わせるようになりました。 ホストが提供する版を超えて要求するパッケージは**全件**、 宣言している版と比較対象の版を添えて列挙します (**切り詰めません**)。 ランタイムが読めない場合、 チェックは**推測せずスキップ**します — 不明を 0 とみなすとホスト上の全 WDF ドライバが該当してしまうためです。 実行サマリには第3の判定語 **`READY WITH EXCLUSIONS`** が加わりました。 `NOT READY` はブート署名の事例 (**何もロードされない**) のために予約された語であり、 WDF の不足は部分的で、 正しい行動は「続行し、 名指しされた一部が入らないことを想定する」ことだからです。 **フェーズのゲートには使いません**: 要求列はフィクスチャでのみ検証済みで、 実際の 55 INF の AMD パッケージに対しては未測定です。 誰も一度も観測していない値でパイプラインをゲートするのは順序が逆になります。 設計根拠: SPEC D.54／実機での読み方: TESTING §37。

- **`2026-08-08` — Chipset r108 / Graphics r74 / NPU r51 / BthPan r56** (`inf-side-wdf-requirement`): c7 でコレクタが**ホスト側**のフレームワーク版を読めるようになりましたが、 比較対象のもう一方が存在しない状態でした。 本リリースはパッケージ側 — **各ドライバ INF が要求する版** — を追加します。 4本すべての `inf_inventory.csv` に5列 (`IsWdfDriver` / `KmdfLibraryVersion` / `UmdfLibraryVersion` / `CoInstallerVersions` / `WdfSectionCount`) が加わります。 対処する障害は静かに起きます: `inf2cat /os:Server2016_X64` はカタログのターゲット OS を設定するだけで、 ドライバの KMDF 要求を**下げません**。 そのため `KmdfLibraryVersion = 1.33` を宣言するパッケージは、 ランタイムが 1.19 のホスト上でも棚卸し・パッチ・カタログ生成・署名まで**全フェーズ緑**で「準備完了」と報告され、 その後ロードに失敗します。 これは署名の問題ではないため、 Path A も Path B も効きません。 directive 名は **INF のテキストから直接**読み取ります。 `KmdfService =` が指すセクションを辿る実装は一見自然ですが、 セクション名の付け方が異なるパッケージでは**一致もエラーも出ず**、 不一致は「WDF ドライバではない」と読めてしまいます — 安全に見える誤答です。 版の比較は5本すべてでバイト同一のヘルパーによる**数値比較**です (文字列では `1.19` が `1.9` より小さくなるため)。 **訂正**: r106 と r107 で公表したアサーション数は実測ではなく算術で更新されていました (実測値は 212 と 271 であり、 204 と 239 ではありません)。 スイート自身が実測値と測定環境を出力するようになりました。 設計根拠: SPEC D.53／測定手順: TESTING §36。

- **`2026-08-08` — r107 / r73 / r50 / r55 / c7** (`winre-tool-compatibility-and-wdf-evidence`): 回復環境用コレクタを実際の回復環境で初めて実行し — 起動できなくなったホスト上で — 段 7 で停止しました。 原因は **WinRE に `findstr` が存在しない**ことです。 段 8〜16 が実行されず、 それを最も必要としていたマシンで証跡を失いました。 誤りは `findstr` を使ったことではなく、 **WinRE がどのコマンドを持つかを仮定した**ことです。 **ツールセンサス**で実在するコマンドを記録するようにしました。 追加分: `dir` 出力だけでなく KMDF/UMDF の**ファイルバージョン**、 名前が示すフレームワーク版を伴う全 `WdfCoInstaller*.dll`、 `Wdf01000` に依存するサービス (`WDF_VIOLATION` 発生時の容疑者プール)、 バンドル内に同梱する 0x10D パラメータ decode 表、 および構成コレクタ側の WDF 評価。 **訂正**: Windows Server 2016 が搭載するのは **KMDF 1.19** であり、 以前のセッションで記憶から述べた 1.15 は Windows 10 1507 の値でした。 なお、 これらは `WDF_VIOLATION` を予測しません — 同エラーはロード済みのドライバがフレームワーク契約に違反したときに発生します。 本機能は容疑者の範囲を絞るものであり、 その旨は JSON 自身に記載されています。 ポストモーテム: SPEC D.52／実行記録: TESTING §35。

- **`2026-08-07` — r93 / r59 / r37 / r41** (`windows-server-configuration-evidence-collector`): **構成情報エビデンス・コレクタ。** デプロイスクリプトが操作対象とする Windows Server の構成領域 (OS 識別、 デバイス、 ドライバストア、 プロジェクト証明書、 ブートセキュリティ、 CodeIntegrity イベント、 `setupapi` ログ、 スクリプト + ワークスペース目録) を、 **読み取り専用** でタイムスタンプ付きエビデンス ZIP に採取し、 色付きの PASS / FAIL / REVIEW / INFO 評価レポートを出力します。 デプロイ 4 本には実行前後で **diff 比較可能な pre/post エビデンスペア** を採取する統合が追加されました (r93 ではオプトインの `-CollectEvidence`。 r94 でデフォルト有効化され、 オプトアウトの `-SkipEvidenceCollection` に置換)。 詳細は後述の 「構成情報エビデンス・コレクタ (r93+)」 節を参照してください。

### 最近のリリース (2026-07 — 2026-08)

- **`2026-08-08` — r106 / r72 / r49 / r54** (`recovery-collector-argument-modifier-fix`): r105 のモード分岐は初回実行で正しく動作しました — `Collection mode : online`、 ハイブは `reg save` で取得、 稼働レジストリをハイブ読み込みなしで照会、 そして **`CrashDumpEnabled = 0x7`** をコンソールに表示。 再起動前にこれを実行した動機である問いに答えが出ました。 その後、 段 12 で停止しました: `CALL` されたサブルーチン内では cmd.exe が**行がコメントかを判断する前に**引数修飾子を 解決し、 `rem` も例外ではありません。 このため r105 で追加した「ファイルの報告サイズが信用できない理由」を説明する コメントが — 説明対象の修飾子そのものを含んでいたために — スクリプトを停止させました。 コメントを書き直し、 サブルーチン内で引数番号を伴わない修飾子を検出する回帰ガードと、 正当な `FOR` 変数形式が残っていることを確認する アサーションを追加しました。 これは本ファイルで実行によってのみ発見された 4 件目の欠陥であり、 cmd.exe が行を 見た目と異なる形で解析することに起因する 3 件目です。 いずれも規律ではなく**形として禁止**する方針で対処しています。 ポストモーテム: SPEC D.51／実行記録: TESTING §34。

- **`2026-08-08` — r105 / r71 / r48 / r53** (`recovery-collector-online-offline-modes`): `Collect-OfflineRecoveryEvidence.cmd` が起動中ホストで 13 段を 完走し、 一貫した欠落パターンを持つバンドルを生成しました。 原因は 1 点 — マシンが起動中であったため、 カーネルがレジストリハイブを排他保持し、 DISM は自身の稼働イメージに対する `/image:` を拒否します。 **重要な欠落は 2 点**: `CrashDumpEnabled` が読めなかったこと、 そして保留中の更新の状態が判明しなかったこと — 再起動前にこれを実行した動機そのものです。 起動中ホストでの実行は誤用ではなく、 妥当な予行演習であり、 **各モードは他方が到達できない情報に到達します**。 スクリプトは `%SystemRoot%` と対象ボリュームの比較で 状況を判定し、 ロックされたハイブのコピーではなく `reg save`、 読み込んだ `ControlSet001` ではなく稼働中の `CurrentControlSet`、 `/image:` ではなく `dism /online` を使うようになりました。 `CrashDumpEnabled` と `AutoReboot` はコンソールにも表示します — 値が `0` なら次の bugcheck でダンプが残らないため、 再起動後ではなく前に知る価値があります。 測定できないファイルサイズは `0 MB` ではなく「不明」と報告し、 コピー自体は試行します。 ポストモーテム: SPEC D.50／実行記録: TESTING §33。

- **`2026-08-08` — r104 / r70 / r47 / r52** (`offline-collector-cmd-parser-fix`): `Collect-OfflineRecoveryEvidence.cmd` の初実行が段 5 の途中で 停止しました。 括弧を含むラベル — `CBS (incl. CBS.persist.log)` — が `if` ブロック内で展開され、 **cmd.exe は括弧ブロックを解析する前に変数を展開する**ため、 `)` がブロックを早期に閉じ、 残りがコマンドとして 解析されていました。 2 段階で修正: ラベルから括弧を除去し、 さらに**サブルーチンで括弧ブロックを一切使わない** 構造 (`goto` 分岐) にしました。 これにより将来 `(`・`&`・`|` を含むラベルが追加されても同じ欠陥は再発しません。 テストスイートが欠陥版を通していたのは、 エンコーディング・`goto` 解決・`reg load` の均衡は検査していた一方で、 cmd.exe の展開順序を一切モデル化していなかったためです。 シェルのパーサをテストで完全に再現することはできませんが、 **欠陥を許す「形」を禁止すること**はできます。 なお部分実行により、 実機での自動検出は正しく動作することが 確認できました: 931 GB のシステムディスクではなく 112 GB のリムーバブルボリュームが、 **プローブ書き込み**に よって選択されています。 ポストモーテム: SPEC D.49／実行記録: TESTING §32。

- **`2026-08-08` — r103 / r69 / r46 / r51** (`offline-collector-microsoft-noboot-coverage`): `Collect-OfflineRecoveryEvidence.cmd` が **マイクロソフトが no-boot 報告時に要求する一式**を収集するようになりました — 公開されている要求リストと 照合したところ、 初版は **17 項目中 13 項目が不足**していました。 傾向を明記します: ドライバ問題の診断に必要な ものは集めていた一方、 **サービシング関連をほぼ全て落としていました**。 更新の中断は、 構成変更の再起動後に Server が起動しなくなる最も一般的な原因の 1 つです。 追加分: システムドライブ全体のファイル一覧、 **全**イベントログ、 `CBS.persist.log`、 `SrtTrail.txt`、 WindowsUpdate / USOShared / DISM ログ、 `ReportingEvents.log`、 SYSTEM / SOFTWARE / COMPONENTS / RegBack ハイブの**生コピー**、 `pagefile.sys`。 **引数なしで実行可能**になりました: config ハイブを目印に Windows ボリュームを検出し (WinRE では通常 `C:` では ありません)、 **プローブファイルを実際に書いて**書き込み可能な出力先を判定します (ブートメディアは読み取り専用で マウントされることが多いため)。 大容量ファイルはサイズ上限で制御し、 途中で USB を埋める代わりに実サイズを記録します。 ファイルの不在もマニフェストに記録します — 不在自体が所見であることが多いためです。 あわせて r102 の `.cmd` が LF で着地した件を修正しました — **本パッチは `git am --keep-cr` で適用してください**。 ポストモーテム: SPEC D.48／手順: TESTING §31。

- **`2026-08-08` — r102 / r68 / r45 / r50 / c6** (`driver-framework-crash-evidence-and-offline-collector`): Windows Server 2016 で発生した `WDF_VIOLATION` の BSOD ループと、 本プロジェクト初の WS2016 実測を受けた対応です。 コレクタが **`driver-framework.json`** を 記録するようになりました — KMDF/UMDF ランタイム版は**天井**であり、 INF がより新しい `KmdfLibraryVersion` を 要求するドライバはロードできません。 これは署名の問題ではないため Path A も Path B も効きません (`inf2cat /os:Server2016_X64` はカタログのターゲットを変えるだけで KMDF 要求は下げません)。 あわせて **`crash-evidence.json`** を追加 — bugcheck イベントは停止コードと 4 つのパラメータを保持し、 `WDF_VIOLATION` では第 1 パラメータが「どの種類のフレームワーク契約に違反したか」を示します。 新規 **`Collect-OfflineRecoveryEvidence.cmd`** は、 **PowerShell が存在しない**回復環境からオフラインの Windows ボリュームを収集します — PowerShell を前提にした収集方式は、 証跡が最も必要な場面でこそ使えないためです。 また、 初の WS2016 ホストが**文書化されていた OS の事実を反証**し (`PS_UpdateAndCompareCIPolicy` は 14393.9339 に存在する)、 独立に **SPEC D.43.3 の `vwifibus` 予測を再現**しました — そのホストが存在する前に 書かれたチェックが、 予測どおりの状態を検出しています。 ポストモーテム: SPEC D.47／実測: TESTING §30。

- **`2026-08-08` — r101 / r67 / r44 / r49 / c5** (`guard-placement-preflight-and-os-capability-evidence`): クリーンインストールした WS2019 で本番 3 スクリプトを 実行したところ、 **r100 の縮退プランガードが誤った関数に入っていた**ことが判明しました — P06 は空のプランを正しく 検出して `SKIPPED` で終了したのに、 ガードが P09 と V03 に着地していたため P08 が「直前に実行済みのフェーズを 先に実行せよ」というエラーで失敗していました。 どちらも構文的に正しく実在のプロパティを参照していたため、 修正が 到達不能なファイルに対して静的ゲートは全て green でした。 配置は PowerShell 自身のパーサに対して assert する方式に 変更し、 テストスイートでも再検査します。 **BthPan は既定動作で P01 失敗**もしていました — `-LogFile` 省略時に `<WorkRoot>\logs\` へ自動配置しておきながら、 「transcript が `-WorkRoot` 内にある」として実行を拒否する チェック (BthPan のみが保持) が原因で、 同じ実行方法で 2 本成功・1 本失敗という状態でした。 予定されている **Windows Server 2016 検証**に向けて、 コレクタに `os-capability.json` (スクリプトが選択するビルド別プロファイル、 14 の cmdlet、 WS2016 に存在しないものを含む 6 の CIM クラス、 `signtool` の有無 — これが無い場合の WHQL 判定は 実測ではなく既定値です) と `archive-capability.json` (`Compress-Archive` を実際に使って動作を証明) を追加しました。 SPEC D.46.4 に OS 差異表を集約、 TESTING §29 が検証手引きです。 なおコレクタ自体は本実行で初めて完走しました: 13 段・失敗 0、 **560 サービス**を記録し `ImagePathExists` は 560/560 埋まっています。

- **`2026-08-08` — r100 / r66 / r43 / r48 / c4** (`evidence-resilience-and-degenerate-plan-handling`): クリーンインストールした WS2019 で前世代を実行したところ、 証跡コレクタが 12 段中 9 段目で異常終了してアーカイブを生成せず、 その後 PrepareVerify も P09 で失敗しました。 コレクタに 3 つの欠陥があり、 いずれも静的解析では検出不能なものでした: 呼び出し先に存在しないパラメータを渡していた (このため c3 で同じブロックに入れた「修正」は依然として何もしておらず、 PASS を報告し続けていた)、 `-like` パターンに閉じられていない `[` 文字クラスが含まれ、 照合前に例外となって実行を停止させた、 12 段すべてを 1 つの `try` で囲みアーカイブもその中にあったため、 1 段の失敗が後続全段**と** ZIP を巻き添えにした。 各段を分離し、 アーカイブを 4 姉妹と同じ top-level `finally` へ移し、 新しい `Collection completeness` 行を レポート先頭に配置しました。 また、 **r99 の分析母集団拡張が答えを返しました: in-scope 55 INF のうち WHQL 共署名を 持つものは 0 件**(signtool は利用可能だったため実測です) — `-SkipNonCosignedDrivers` はこのドライバパッケージでは インストール可能なプランを作れません。 P06 がその旨を説明して正常終了するようになり、 P09 が例外を投げることは なくなりました。 **新規: `tests/`** — リポジトリ初の実行可能テストスイート (3 ケース・55 アサーション・依存なし)。 欠陥版に対して失敗することを確認した陰性対照付き。 ポストモーテム: SPEC D.45／スイート: TESTING §27。

- **`2026-08-08` — Collector c3** (`service-configuration-evidence-and-path-resolution-fix`): コレクタ単独リリース。 **c2 で追加したデバイスロード診断は、 実際には一度も動作していませんでした。** 3 つの文字列リテラルが誤っており (レジストリパス 2 箇所で末尾の区切り文字が欠落、 正規表現でリテラルのバックスラッシュのつもりが `\S` = 非空白文字クラス)、 サービス検索が常に失敗し、 `ServiceBinaryPresent` が一度も設定されず、 評価行 `Driver binary presence` が **バイナリ不在のホストで PASS** を報告していました。 静的ゲートでは検出不能です — `psa.py` もパーサも、 リテラルが構文的に正しいことは検証しますが、 中身が意図どおりかは検証しません。 原因はスクリプトではなく著作ツール側で、 以後は断片を `.ps1` ファイルからバイト単位で複製し、 必須リテラルと禁止リテラルを書き込み前のバイト列に対して照合します。 検証は **22 ケースのランタイムハーネス (22/22) と、 欠陥版 c2 に対して失敗することを確認した陰性対照**。 また、 コレクタはこれまで**サービス構成を一切記録していませんでした** — 当該インシデントの背景そのものであり、 原因は Windows Server の既定構成 (Server SKU では未配置の inbox 無線コンポーネント) でした。 新ステージが `services.json` (**全サービスを絞り込みなしで記録** — ユーザーモード・カーネルドライバ・レジストリのみのキーを含み、 解決済み `ImagePath` とディスク上の実在確認、 逆依存インデックス付き) と `server-feature-services.json` (機能の導入状態と、 その機能が配置するサービスの対応) を出力します。 ポストモーテム: SPEC D.44。

- **`2026-08-08` — r99 / r65 / r42 / r47 / c2** (`plan-coverage-collateral-health-and-load-diagnostics`): 5 回目の WS2019 実地実行で Path A 連鎖が end-to-end で完走し、**pnputil が本パイプラインの自己署名カタログを受理することが実証されました (53/53)**。 しかしその後、 ドライバがロードできず、 それまで動作していた Intel Wi-Fi アダプタも停止していることが判明しました。 3 つの欠陥が重なっていました。 **(1)** `-SkipNonCosignedDrivers` の分析母集団がパッチ対象サブセットのみで、 **119 件のインベントリ中 2 件**しか検査せず、 未検査の 53 ドライバがインストールされた状態で「Secure Boot 安全」と 判定していました。 `NonCoSignedCount = 0` は本来「検査したものに失敗は無い」でしかないのに「プランに非 WHQL は無い」と 読まれていました。 分析母集団を install スコープ全体へ拡張し、 適格判定を判定駆動に変更、 プラン JSON を **SchemaVersion 3** として `PlanUnverifiedCount` を持たせ、 I02 短絡を **fail-closed** にしました。 **(2)** `pnputil /install` の related-drivers パス完了から **32 ミリ秒後**に Intel アダプタが再列挙され、 この Server SKU に存在しないサービスバイナリが原因で再インストールが失敗していました。 `/install` は**意図的に除去していません** (直前に end-to-end で機能が実証された経路であり、 因果は帰属であって証明ではないため)。 代わりに I03 の前後で全システムのデバイス健全性センサスを取り、 AMD 以外も含めて悪化したデバイスを報告します。 **(3)** 同一画面で I04 が「ドライバロードは BLOCKED」と表示しているのに digest は READY を出していました。 digest は boot-signing 状態も参照するようになりました。 **証跡コレクタ**にデバイスロード診断を追加: CM_PROB と NTSTATUS の識別 (署名エラーと、 見た目が同じ API 不一致とを分離)、 デバイス毎のサービス `ImagePath` 実在確認、 setupapi 失敗セクションの抽出。 ポストモーテム: SPEC D.43。 **本リリースの検証は静的ゲートのみで、 ハーネスも 実地実行もまだありません** (TESTING §25)。

- **`2026-08-08` — r98 / r64 / r41 / r46** (`phase-status-and-digest-binder-fixes`): 4 回目の WS2019 実地実行は、 `-SkipNonCosignedDrivers` の Path A 連鎖が先行 2 判定を正しく通過して I02 に到達した初のケースです — **I01 が実行されて証明書が登録され、 I02 short-circuit が発火**しました。 r97 が狙った 2 点が実地で確認されたことになります (構成証跡コレクタの pre/post 証明書ストア対で独立に裏付け)。 その直後、 フェーズを閉じる呼び出しで失敗しました: short-circuit が `Write-PhaseFooter` に `'short-circuit'` を渡していましたが、 canon 側の `ValidateSet` は `done`/`cached`/`skipped`/`failed` のみを許可します — r72 以来の潜在欠陥で、 short-circuit が初めて発火するまで 到達不能でした。 当該ヘルパーは vendored canon リージョンであるため、 修正は枠内本体ではなく 9 箇所の呼び出し側で 行います (short-circuit -> `cached`、 未到達の reboot halt 2 種 -> `skipped`)。 また、 r97 の自己位置特定型封じ込めが readiness digest の例外源をついに特定しました: `System.Collections.Generic.List[object]` に対する `@( )` が バインダ自身で例外を投げます — r92 以来存在していたため、 **r95 (`Get-Variable` probe) と r96 (`variable:` probe) の 原因帰属はいずれも誤りでした** — 4 姉妹すべてで `.ToArray()` に置換したため NPU も r41 になります。 ポストモーテム: SPEC D.42。 canon 検証手順: SPEC A.11.8a。

- **`2026-08-08` — r97 / r63 / r40 / r45** (`path-a-scope-and-digest-fixes`): 3 回目の WS2019 実地実行で `PrepareVerify -SkipNonCosignedDrivers` が初めて end-to-end で完走し、 同日の先行修正に含まれていた 2 つの誤った前提が判明しました: カタログは選択スコープ**全体**に対して再生成・自己署名される (ベンダーカタログは Server OS ターゲットを持たないため破棄される) ので、 縮退プラン以外では I01 は必ず必要 — r96 のゲートはこれを誤ってスキップしていました。 さらにプラン集計がスコープ外の W11x64 変種行まで含んでいたため、 トリム済みの非 co-signed INF 名が残存行から再混入して I02 short-circuit を阻止し、 設計どおりの Path B / Secure Boot abort に落ちていました。 r97 でプラン JSON を install 変種スコープに限定 (SchemaVersion 2・新 `PlanCatalogSignCount`)、 I01 ゲートを「自己署名すべきカタログが無い場合のみ」に是正、 インストールフェーズのメッセージを事実に整合させ、 readiness digest の probe を例外経路を持たない `variable:` プロバイダ形に書き換えて自己位置特定型の封じ込めを追加しました (r95 後も 5.1 で digest 不能が継続していたため。 NPU も今回は対象で r40)。 ポストモーテム: SPEC D.41。 改訂契約: SPEC D.31.17。

- **`2026-08-08` — r96 / r62 / r39 / r44** (`path-a-plan-semantics-fixes`): `-SkipNonCosignedDrivers` の初回実地実行からの修正 — P06 トリムのスキーマ耐性化 (r71 の consumer は実インベントリ行でクラッシュ)、 トリム意味論の是正 (パッチ不要 INF は常に適格)、 分析とトリム後プランの `PrepareVerify` -> `Install` 境界越え永続化、 および初版の I01 ゲート。 ポストモーテム: SPEC D.40。

- **`2026-08-08` — r95 / r61 / r39 / r43** (`ws2019-ps51-field-fixes`): 初の Windows Server 2019 実地実行からの修正 — Windows PowerShell 5.1 のエンジンバグ (存在しない変数への `Get-Variable -Scope`) が r92〜r94 のすべての 5.1 実行で RUN SUMMARY の readiness 判定を欠落させていた問題、 存在確認 probe が caught 済みエラーレコードでトランスクリプトを汚す問題、 および I02 の `PATH B` バナーに「1903 未満のビルド (WS2019 = 1809) では WDAC supplemental パスはそもそも使用不能」と明示する改善。 ポストモーテム: SPEC D.39。

- **`2026-08-07` — r94 / r60 / r38 / r42** (`evidence-collection-default-on`)。 構成情報エビデンス採取が **すべての実行で自動実行** に (`ListPhases` を除く) — オプトインの `-CollectEvidence` はオプトアウトの `-SkipEvidenceCollection` に置換。

- **`2026-08-07` — r92 / r58 / r36 / r40** (`quickedit-guard-readiness-and-artifact-archive`)。 実運用レポートに基づく 3 つの堅牢化: **コンソール QuickEdit ガード** (誤ったテキスト選択がすべてのコンソール出力を凍結させ、 フェーズ途中のハングと見分けがつかない現象。 SPEC D.38 が 18m37s の実測ケースを、 Ctrl-C がスクリプトを停止させずに「ハング解除」する理由も含めて記録)、 RUN SUMMARY 末尾の明示的な **Install readiness 判定**、 および **run-artifact アーカイブ** (実行ごとの診断 ZIP をスクリプトフォルダにコピー。 `*.pfx` 秘密鍵は決して含まれません)。
- **`2026-08-07` — r91 / r57 / r35 / r39** (`auto-run-transcript-and-chipset-url-discovery`)。 すべての実行が **自動でトランスクリプト記録** されるようになりました (`-LogFile` 指定不要)。 また Chipset の URL 探索が AMD の 2026-07 インストーラ改名 (`amd_chipset_software_<v>.exe` → `amd_software_<v>.exe`。 SPEC D.37) に対応し、 probe-miss 時の証跡保存 (`logs\` 配下) が追加されました。
- **`2026-07-03` — wave 1 / 2a / 2b: r88-r90 / r54-r56 / r36-r38 (BthPan) / r32-r34 (NPU)** (`cross-repo-canon-vendored-region-markers-wave-*`)。 クロスリポジトリ共有ヘルパー canon が、 `>>> CANONICAL ... <<<` マーカー付きの機械検証可能な **vendored リージョン** として再構成されました (Chipset / Graphics / BthPan は 32 ユニット、 NPU は 29 ユニット)。 canon は中央リポジトリ [`ai-generated-artifacts`](https://github.com/usui-tk/ai-generated-artifacts) で保守され、 マーカー枠内のコード改善は本リポジトリへの直接編集ではなく中央 canon を経由します。

より古いリリースノート (初回コミット以降のすべてのリリース) は [CHANGELOG.md](./CHANGELOG.md) を参照してください。


## 4 スクリプトのリスク分類

> NPU スクリプトは姉妹スクリプトと比較して明らかにリスクが高いため、 実行前にこのセクションを必ず理解する必要があります。 BthPan スクリプトは 4 スクリプト中で最もリスクが低い: ドライバソースはホスト自身の DriverStore (リモートダウンロードなし)、 INF surface はちょうど 1 ファイル・ 1 HWID、 ドライババイナリ自体は Microsoft が署名済みで、 再署名するのは catalog のみだからです。

| 項目 | チップセットスクリプト | グラフィックススクリプト | **NPU スクリプト** | **BthPan スクリプト** |
| --- | --- | --- | --- | --- |
| **成熟度** | 過去実機検証済み・複数サイクル (是正前)。 再検証待ち | 過去実機検証済み・複数サイクル (是正前)。 再検証待ち | **🆘 実験的 — 物理 NPU ハードウェアでの検証は未実施** | **新規** — 初版リリース。 Phase / Secure Boot / WDAC フレームワークは検証済 verbatim 継承。 単一 INF surface が小さく、 1 セッションで物理検証が完結可能。 |
| **配布形態** | 公開 EXE 直接ダウンロード | 公開 EXE 直接ダウンロード | **EULA gate ZIP、 AMD アカウント必須** | **ダウンロード不要** — `bthpan.inf` はホスト自身の `C:\Windows\System32\DriverStore\FileRepository\bthpan.inf_amd64_*` に既に staging 済み。 |
| **公開ダウンロード URL** | あり (直接) | あり (直接) | **なし — リリースごとに AMD アカウントログインと EULA 受諾が必須** | **該当なし — ドライバはホスト上に存在。** |
| **AMD アカウント自動ダウンロード** | 該当なし | 該当なし | **best-effort、 AMD のフォーム HTML 構造に依存し予告なく破綻する可能性** | **該当なし。** |
| **OS サポートスタンス** | AMD 非公式サポートだがドライバは動作 | AMD 非公式サポートだがドライバは動作 | **kernel driver は Server 2025 で load するが、 AMD ドキュメント上 Ryzen AI Software (user-mode stack) は Server 2025 で動作しない** | **Microsoft inbox driver — Workstation SKU では Microsoft 公式にフルサポート。** Server SKU でフィルタアウトされるのは `NTamd64...1` ProductType decoration が原因のみ。 本スクリプトは Microsoft のバイナリには一切手を加えず、 不足している ProductType=3 decoration のみ供給します。 |
| **ハードウェア入手性** | 一般的 (任意の AMD APU マシン) | 一般的 (任意の AMD GPU/APU マシン) | **限定的 (Ryzen AI 300 / Ryzen AI Max 300 / Ryzen 7040/8040 シリーズのみ)** | 一般的 — Bluetooth host controller が bind 済みで `BTH\MS_BTHPAN` が enumeration されるすべてのマシン。 ほとんどの ThinkPad・ mini-PC・ NUC が該当。 |
| **リポジトリ内のテストフィクスチャ** | M75q Tiny Gen 2、 X13 Gen 1 AMD | M75q Tiny Gen 2、 X13 Gen 1 AMD | **なし — メンテナーの lab に物理 NPU マシンが本ドキュメント執筆時点で存在しない** | ThinkPad + Intel AX210 + WS2025 build 26100.32860 (初回物理検証予定)。 |
| **本スクリプト固有の失敗モード** | PSP / TPM driver 置換による BitLocker 回復プロンプト | 署名済 cat install 時の display reset | NPU device が enumeration されない / Ryzen AI Software が動作しない | **Phantom OK トラップ** — bth.inf が代理マッチして Status=OK を報告するが `bthpan.sys` は **load されていない**。 V06 / I04 は Phantom OK (DriverInfPath=bth.inf、 Class=Bluetooth) と真の解消 (DriverInfPath=oem*.inf、 Class=Net、 Service=BthPan) を明示的に区別。 |
| **推奨用途** | Lab + 慎重な production | Lab + 慎重な production | **Lab / 研究用途のみ。 production ホストには deploy しないこと。** | **Lab + 慎重な production。** ベンダードライバを置換するわけではなく、 Microsoft が publish した inbox driver を Microsoft が同梱対象外と判断した SKU クラスで有効化するだけのため、 リスクは低い。 |
| **推奨 Action モード** | `PrepareVerify` でレビュー後に `Install` | `PrepareVerify` でレビュー後に `Install` | **物理 NPU ハードウェアの存在を確認し、 Ryzen AI Software が Server 2025 で動作しないことを受け入れるまでは `PrepareVerify` のみ** | まず `PrepareVerify` で Phantom-OK と真の解消状態を確認し、 その後 `Install`。 |

**NPU スクリプトを使う際の実践的な経験則**:

1. **ロールバックできないホストでは `-Action Install` を実行しないでください。** Cleanup パスは実装されていますが、driver store からの削除は best-effort で、`pnputil /delete-driver oemNN.inf /force` による手動 cleanup が必要となるケースがあります。
2. **Ryzen AI Software user-mode stack** (Python conda env + ONNX Runtime VitisAI EP + OGA) は **AMD 公式に Windows 11 only** です。Server 2025 で kernel driver が load しても、サポートされたスタックで推論ワークロードを実行することはできません。Server 2025 上で AI ワークロード機能性を期待しないでください。kernel driver は driver bring-up の実験以上のものではありません。
3. **物理 NPU 検証は未完了です。** 現時点での全ての検証は `psa.py` による静的解析と、AMD 公開の `quicktest.py` 検出ロジックを PowerShell に翻訳したコードのレビューに留まります。**実機での挙動は未確認**です。
4. **AMD のアカウント自動ダウンロードフローは予告なく破綻する可能性があります。** AMD は `account.amd.com` のフォーム構造、CSRF token 名、EULA 受諾エンドポイントを定期的に更新します。スクリプトの Tier 2 認証は best-effort です。**再現性が必要な実行は常に Tier 4 (`-OfflineZip`) を優先**してください。

上記を読んだ上でなお NPU スクリプトを実行したい場合: [NPU スクリプト固有の Quick Start](#npu-スクリプト固有の-quick-start) を参照してください。

---

## 対応範囲

### 対応ハードウェア

- **AMD Ryzen Mobile**: Ryzen 4000 (Renoir)、5000 (Cezanne / Lucienne / Barcelo / Barcelo-R)、6000 (Rembrandt)、7000 (Phoenix / Hawk Point)、8000 (Hawk Point refresh)、AI 300 (Strix Point / Krackan Point)、AI Max 300 (Strix Halo)。
- **AMD Ryzen Desktop APU**: Ryzen 5000G / 5000GE (Cezanne)、7000G / 8000G (Phoenix)。
- **AMD Radeon Graphics**: Vega 6 / 7 / 8 / 11 (内蔵、Renoir → Cezanne → Barcelo)、RDNA 3 (Phoenix 780M / 760M)、RDNA 3.5 (Strix Point)、discrete RX 5000 / 6000 / 7000 / 9000 シリーズ。
- **AMD AM4 / AM5 chipset**: X470、X570、X670/X670E、X870/X870E、B450、B550、B650、B850。
- **AMD ACPI device**: GPIO controller (`AMDI0030`、`AMDF030`)、I2C (`AMD0010`)、Micro PEP (`AMD0004`)、HSMP (`AMDI0097`)、PMF (`AMDI0100` / `AMDI0102`)、SFH (`AMDI0080` / `AMDI0011`)、UART (`AMD0020`)、Wireless Button (`AMDI0051`)、Pluton stub (`MSFT0200` / `MSFT0201`)。
- **AMD NPU / XDNA Compute Accelerator** *(実験的、NPU スクリプトのみ)*:
  - **Phoenix / Hawk Point** (`PCI\VEN_1022&DEV_1502&REV_00`) — Ryzen 7040 / 8040 / 8040 PRO mobile シリーズ。ドライバ build `32.0.203.280` (RAI 1.5)。
  - **Strix Point / Strix Halo** (`PCI\VEN_1022&DEV_17F0&REV_00/10/11`) — Ryzen AI 300 / Ryzen AI Max 300 シリーズ。ドライバ build `32.0.203.314` (RAI 1.6.1) 以降。
  - **Krackan Point** (`PCI\VEN_1022&DEV_17F0&REV_20`) — Ryzen AI 200 シリーズ。ドライバ build `32.0.203.314` (RAI 1.6.1) 以降。
- **Microsoft inbox Bluetooth PAN** *(BthPan スクリプトのみ)*:
  - **HWID**: `BTH\MS_BTHPAN` — Microsoft サポート対象の Bluetooth host controller が bind した後、 そのすべての controller が公開する子デバイス。 ベンダー非依存 (Intel AX2xx、 Realtek RTL88xx、 MediaTek MT7xxx、 Broadcom BCM43xx 等すべて該当)。
  - **前提**: Bluetooth host controller のドライバが bind 済みで Device Manager 上 Status=OK を表示していること。 host controller 自体が Unknown device の場合は先にベンダードライバをインストールしてください。 本スクリプトは host controller には対応しません。
  - **本スクリプトが解消する症状**: Windows Server SKU 上で `BTH\MS_BTHPAN` が Unknown Device (code 28) として表示される、 または Status=OK でも `DriverInfPath=bth.inf` ・ `Class=Bluetooth` (Phantom OK; `bthpan.sys` は **load されておらず**、 `BthPan` service も起動していない) となっているケース。
  - **真の解消基準**: `DriverInfPath=oem*.inf`、 `Class=Net`、 `Service=BthPan`、 `C:\Windows\System32\drivers\bthpan.sys` が存在、 `BthPan` service が登録済、 Bluetooth PAN NetAdapter が `Get-NetAdapter` で visible になっていること。

### 対応 OS

4 つの driver script (Chipset、 Graphics、 NPU、 BthPan) は
**モダン Windows Server** (2022 build 20348、 2025 build 26100) と
**レガシー Windows Server** (2019 build 17763、 2016 build 14393)
の両方をサポートします:

| OS | Build | I02 パス | 備考 |
|---|---|---|---|
| Windows Server 2025 | 26100 | Path A — 信頼ストア登録 (パッケージ信頼)。 WDAC supplemental の配置は明示的な `-WdacBasePolicyGuid` 指定時のみ | 主検証ターゲット。 カーネルイメージ信頼はパッケージ信頼から独立に評価されます (Mode S — SPEC D.58.7)。 Server 2025+ には Windows Driver Policy が適用されます (SPEC D.58.6)。 |
| Windows Server 2022 | 20348 | Path A — 信頼ストア登録 (パッケージ信頼)。 WDAC supplemental の配置は明示的な `-WdacBasePolicyGuid` 指定時のみ | **実機実行の記録なし** — WS2025 と同じ Multiple Policy Format ティアとして設計されています (**ただし inbox CiTool はなし** — 有効化はダウンロード配布の RefreshPolicy.exe か WMI bridge。 SPEC D.58.9) が、 WS2022 実機で実行されたことはありません ([現在のステータス](#現在のステータス-エンドユーザー利用には未対応) を参照)。 カーネルイメージ信頼はパッケージ信頼から独立に評価されます (Mode S — SPEC D.58.7)。 |
| Windows Server 2019 | 17763 | **Path A** (信頼ストア登録のみ、 install 予定 driver が全て WHQL co-signed の場合) / **Path B** (`-UseTestSigning`、 firmware で Secure Boot を Disabled にすることが必須) | r70 で従来の WDAC SPF orchestrator 経路を撤回しました (SPEC §D.30 参照)。 WHQL co-signed driver (例: `AmdMicroPEP.sys`、 `amdgpio2.sys`) は信頼ストア登録のみで load されます。 非 WHQL driver (例: `amdi2c.sys`、 `amdsfhkmdf.sys`) は Path B を要します。 r71 で、 Secure Boot ON のまま運用したいホスト向けに非 WHQL driver をスキップする `-SkipNonCosignedDrivers` スイッチを追加しました。 r72 で I02 short-circuit を追加し、 `-SkipNonCosignedDrivers` + Secure Boot ON で firmware 変更なしに end-to-end でインストールが完了できるようにしました (WHQL embedded signature が kernel CI で直接 authorize されるため)。 r96 で、 初の実地実行で判明した Path A プランの欠陥 (スキーマクラッシュ・プランを空にするトリムルール・プロセス境界での分析喪失 — SPEC §D.40) を修正しました。 r97 で、 2 回目の試行で判明したプラン集計スコープと I01 判定基準を是正しました (スコープ外変種行がカウントを汚染・カタログは選択スコープ全体で自己署名されるため I01 のスキップは「自己署名対象ゼロ」のプランのみ — SPEC §D.41)。 詳細は SPEC §D.31、 §D.31.11、 §D.31.17 を参照。 |
| Windows Server 2016 | 14393 | WS2019 と同じ | r70 以降の挙動は WS2019 と同一です。 物理 WS2016 ホストでの実機検証は待機中です。 |
| Windows 10 / 11 (Workstation) | 任意 | PrepareVerify のみ | Install phase は自動的に block されます。 |

レガシー Server ホスト (WS2019 / WS2016) では、 I02 が外部
orchestrator に委譲する経路は r70 で廃止されました (従来の
Path C / WDAC SPF orchestrator は実機検証によりホストを起動不能
にする恐れが明らかになったため。 詳細な根拠は SPEC §D.30 を
参照してください)。 これらのホストでは I02 は、 install 予定の
driver が全て WHQL co-signed であれば Path A (信頼ストア登録
のみ、 Secure Boot は ON のまま可) を使用し、 非 WHQL driver が
1 つでも含まれる場合は Path B (`bcdedit /set TESTSIGNING ON`
+ 再起動。 **事前に firmware で Secure Boot を Disabled
にすることが必須** — SPEC §D.30.4 / F9 参照) を使用します。

### 対応**しない**ハードウェア

- **AMD EPYC server chip** (サーバー級 CPU。クラウドインスタンスや Hetzner AX dedicated 等で利用される): EPYC は別の chipset モデルを使用しており、Microsoft Update 経由で first-party Server 対応ドライバが提供されます。本パイプラインは *コンシューマー* Ryzen 向けで、EPYC は対象外です。
- **リアルタイム GPU compute stack** (ROCm、HIP SDK、Adrenalin パッケージに含まれる user-mode driver 以外の OpenCL): Server 対応については AMD の ROCm ドキュメントを参照してください。
- **Ryzen AI Software user-mode stack** (Python conda env、ONNX Runtime VitisAI Execution Provider、OnnxRuntime GenAI/OGA、Vitis AI Quantizer、Lemonade SDK 等): **NPU スクリプトの対象外。** NPU スクリプトは kernel-mode driver のみ install します。Ryzen AI Software は <https://account.amd.com/en/forms/downloads/xef.html?filename=ryzen-ai-lt-1.7.1.exe> から AMD インストーラを取得し、operator が別途インストールする必要があります。AMD ドキュメントによれば公式サポート OS は Windows 11 build >= 22621.3527 のみです。

---

## リポジトリ構成

`git clone` 直後のリポジトリ構成:

```
Deploy-Drivers-For-WindowsServer/
├── Deploy-AMDChipsetDriverOnWindowsServer.ps1     Chipset ドライバパイプライン (21 phase)
├── Deploy-AMDGraphicsDriverOnWindowsServer.ps1    Graphics ドライバパイプライン (21 phase)
├── Deploy-AMDNpuDriverOnWindowsServer.ps1         NPU (Ryzen AI XDNA) パイプライン (21 phase)
├── Deploy-MSBthPanInboxOnWindowsServer.ps1        Microsoft inbox bthpan パイプライン (21 phase)
├── Collect-WindowsServerConfigurationEvidence.ps1 読み取り専用の構成情報エビデンス・コレクタ (r93+)
├── README.md                                      本ドキュメント (英語版マスター)
├── README.ja.md                                   本ドキュメント (日本語版、 README.md と同期)
├── TESTING.md                                     物理ハードウェアでの検証結果 (英語のみ)
├── SPEC.md                                        開発者向け仕様書 (英語のみ)
├── CHANGELOG.md                                   時系列のリリースノート (英語のみ)
├── CONTRIBUTING.md                                Issue / PR ガイドライン (英語のみ)
├── SECURITY.md                                    脆弱性報告 (英語のみ)
├── CODE_OF_CONDUCT.md                             コミュニティ行動規範 (英語のみ)
├── AGENTS.md                                      エージェント・ガバナンスのブリッジ (正本は中央リポジトリ)
├── CLAUDE.md                                      AGENTS.md へのポインタ
├── LICENSE                                        MIT License
├── .psa.config.json                               psa.py の設定 (PSAP ルール opt-in)
├── .gitattributes                                 Git 改行コード正規化設定
└── .gitignore                                     標準 ignore 設定
```

### スクリプトが生成するもの

`-Action PrepareVerify` (もしくは `-Action All`) 実行後、 各スクリプトは workspace に以下を生成します:

```
C:\Temp\Workspace_AMD-Chipset\   (または C:\Temp\Workspace_AMD-Graphics\・C:\Temp\Workspace_AMD-NPU\・C:\Temp\Workspace_Microsoft-BthPan\)
├── download\              AMD installer EXE / NPU ドライバ ZIP
│                          (BthPan: 空 — ドライバソースは DriverStore のため未使用)
├── extracted\             EXE / ZIP / DriverStore から展開された元 INF とバイナリ
│                          (BthPan: extracted\bthpan\bthpan.inf / .sys / .cat)
├── patched\               ProductType=3 を mirror したパッチ済み INF
│                          + 生成された .cat ファイル + signtool 署名
│                          (BthPan: patched\bthpan\ — 単一 INF ディレクトリ)
├── cert\                  自己署名コード署名証明書 (PFX + CER) +
│                          WDAC supplemental policy XML/CIP
├── logs\                  自動実行トランスクリプト (r91+)・ツールログ・
│                          probe-miss 証跡 html (chipset・r91+)・
│                          run-artifact アーカイブ plan マーカー (r92+)
├── secureboot_ms_sample\  UEFI Secure Boot ベースラインの JSON 証跡
│                          (Microsoft サンプルスクリプト出力)
└── inf_inventory.csv / inf_inventory_report.txt
                           P05 inventory と INF 単位の解析レポート
                           (BthPan: 1 行のみ — INF は 1 ファイル)
```

`-Action Install` (もしくは I01-I04 phase) 実行後、スクリプトは以下を deploy します:

- 証明書を `LocalMachine\Root` + `LocalMachine\TrustedPublisher` に import。
- 実在を確認済みの base policy を `-WdacBasePolicyGuid` で明示した場合に限り: 当該証明書を参照する **WDAC supplemental Code Integrity policy** を `C:\Windows\System32\CodeIntegrity\CiPolicies\Active\` に deploy。 利用可能な環境では `CiTool --update-policy` で有効化されます (Windows Server 2022+ / Windows 11 22H2+ では再起動不要)。 「これにより証明書が **kernel-mode** 署名者として認可される (Secure Boot ON のまま)」という従来の主張は撤回済みです (SPEC D.58) — カーネルイメージ信頼はこのファイルから独立に評価されます。
- パッチ済み + 自己署名済みのドライバを `pnputil /add-driver /install` で install。

以下の 2 系統の成果物は、 ワークスペースではなく **スクリプトと同じフォルダ** に生成されます: 実行ごとの診断アーカイブ `<ScriptName>_<Action>_run-artifacts_<timestamp>_<PID>.zip` (r92+。 `*.pfx`・`download\`・`extracted\`・50 MB 超のファイルは除外)、 および r94 以降すべての実行でデフォルト採取される (`-SkipEvidenceCollection` でスキップ可) コレクタ成果物 `WindowsServerConfigurationEvidence_<stage>[_<invoker>]_<timestamp>` エビデンスディレクトリ + ZIP (r93+)。

---

## Quick Start

### 前提条件

- Windows Server 2025 ホスト (build 26100)、または **検証目的のみ** で Windows 11 24H2 (build 26100) (Workstation OS 上では `Install` 系 phase が自動的にブロックされます。`-AllowWorkstationInstall` で override 可能ですが推奨されません。WS2025 移行前検証の workflow は [TESTING.md](./TESTING.md) を参照してください)。
- PowerShell 5.1 以上 (Desktop または Core)、64-bit、管理者権限で起動。
- インターネット接続 (AMD installer のダウンロードと、Windows SDK / WDK の `winget` 経由インストール用)。
- ワークスペースボリュームに約 5 GB の空き容量 (NPU スクリプトを併用する場合は約 7 GB — Ryzen AI ZIP は約 250 MB、展開後を含めて)。

### スクリプトの取得

```powershell
# 方法 1: リポジトリを clone
git clone https://github.com/usui-tk/Deploy-Drivers-For-WindowsServer.git
cd Deploy-Drivers-For-WindowsServer

# 方法 2: release ZIP を以下からダウンロード
# https://github.com/usui-tk/Deploy-Drivers-For-WindowsServer/releases
```

### ワンショット dry-run (システムには変更を加えません)

```powershell
# 管理者権限の PowerShell セッション内で実行
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

.\Deploy-AMDChipsetDriverOnWindowsServer.ps1   -Action PrepareVerify -CleanWorkRoot
.\Deploy-AMDGraphicsDriverOnWindowsServer.ps1  -Action PrepareVerify -CleanWorkRoot
.\Deploy-MSBthPanInboxOnWindowsServer.ps1      -Action PrepareVerify -CleanWorkRoot

# r94+: すべての実行で読み取り専用の pre/post 構成情報エビデンスペアが自動採取される
# (diff 可能な 2 つのエビデンス ZIP がスクリプトフォルダに生成される。 後述のコレクタ節を参照)
# 採取を止めたい場合のみ -SkipEvidenceCollection を付ける:
.\Deploy-AMDChipsetDriverOnWindowsServer.ps1   -Action PrepareVerify -CleanWorkRoot -SkipEvidenceCollection

# NPU スクリプト — 実機実行には OfflineZip (もしくはその他のダウンロードソース) が必須。
# クリーン環境で -OfflineZip 未指定の場合、 P03 で "All 4 download tiers exhausted" と throw する。
# 詳細パターンは下記の NPU スクリプト固有の Quick Start を参照。
.\Deploy-AMDNpuDriverOnWindowsServer.ps1 -Action PrepareVerify -CleanWorkRoot `
    -OfflineZip .\NPU_RAI1.6.1_314_WHQL.zip -AssumeIfMissing
```

`PrepareVerify` は `P00-P09` (ソース取得・ 展開・ パッチ・ catalog 生成・ 署名) を実行した後、 `V01-V06` (artifact 検証・ dry-run install plan・ ハードウェア影響分析) を行います。 **システム状態は一切変更されません** — 証明書は import されず、 WDAC policy も deploy されず、 ドライバも install されません。 V05 / V06 の出力を読み、 `Install` がどのような変更を加えるかを正確に把握できます。

> **BthPan スクリプト固有の注意**: BthPan スクリプトの P03 (FetchInstaller) は何もダウンロードしません — ホスト自身の `C:\Windows\System32\DriverStore\FileRepository\bthpan.inf_amd64_*` ディレクトリから `bthpan.inf` を locate するのみです。 P03 が失敗するのは inbox driver が意図的に削除されているホスト (極めて稀) のみです。

### フルインストール (chipset・ graphics・ BthPan)

> **🆘 この 3 本を再起動なしで連続実行しないでください**。 WS2019 + Renoir で同じ連続実行を行った結果、 ホストがセーフモードを含めて起動できなくなる事象が直接観測されています。 自動ロールバック機構は存在しません。 サポートされる手順は以下です。

> **物理マシンの現実 (Step 0 の前にお読みください)。** 本リポジトリの対象は物理 Windows Server ホストであり、 VM ではありません。 物理マシンには PowerShell から呼び出せる「スナップショット」機能はなく、 不適切な `Install` から数秒でロールバックできる `Restore-VMSnapshot` のような手段もありません。 Server SKU の System Restore は既定で OFF、 有効化しても `SiPolicy.p7b` は復元対象外です。 フルディスクイメージ取得 (Macrium Reflect、 Clonezilla、 dd 等) は可能ですが、 C: ドライブと同等以上の外部ストレージが必要で、 Windows の外で実行する別ワークフローです。 以下の Step 0 チェックリストは、 **物理マシン上で実際に実行可能かつ効果的な事前準備**を体系化したものです: 復旧手段を **必要になる前**に確保する、 失う可能性のある鍵を記録する、 そしてスクリプトを 1 本ずつ実行することで故障の影響範囲を限定する、 という 3 点です。

```powershell
# ---- 0. 事前準備 (物理マシン) — -Action Install の「前」に完了させる ----
#
#   A. 別の動作マシン上で Windows 復旧 USB を作成する。
#      対象機がブリックしてからでは作成できません。
#         - Windows 10/11/Server 2022+: 動作中のホストで「回復ドライブの
#           作成」(`RecoveryDrive.exe`)を検索。 16 GB 以上の USB を使用。
#           WinRE (コマンドプロンプト、 スタートアップ修復、 システム
#           イメージ復元、 bcdedit) が利用可能になります。
#         - 代替案: Volume Licensing Service Center (VLSC) または
#           Microsoft Evaluation Center から対象ホストのエディションに
#           合った Windows Server 2019/2022/2025 ISO をダウンロードし、
#           Rufus / MediaCreationTool で USB に書き込む。 インストール
#           メディアの最初の画面の「コンピューターを修復する」から
#           WinRE に入れます。
#         - 必要になる前に、 別の正常なマシンで USB が起動するか
#           確認する。
#
#   B. C: に BitLocker が有効ならその回復キーを記録する。
#         manage-bde -protectors -get C: | Out-File C:\BitLockerKeys.txt
#      ファイルを印刷するか、 別のデバイスに保存。 Chipset スクリプト
#      の PSP driver 置換が次回 boot で BitLocker 回復を triggers する
#      可能性があります。
#
#   C. (強く推奨、 ただし任意) システムドライブのフルディスクイメージを
#      外部メディアへ取得する:
#         - Macrium Reflect Free (rescue media boot + USB 接続ドライブ
#           へ C: をイメージ化)、 Clonezilla、 または Linux Live USB
#           からの `dd if=/dev/sdX`。 典型的な NVMe サイズで 20-60 分。
#         - これはブリックした物理ホストを OS 再インストールなしで
#           完全ロールバックできる「唯一の」機構です。 スクリプトが
#           必須要件として要求するわけではありませんが、 「30 分で
#           復元」と「半日かけて再インストール+再設定」を分ける差です。
#
#   D. OS インストール ISO + 対応するライセンスキーが手元にあることを
#      確認する。 A-C 全てが復旧時に失敗した場合、 再インストールは
#      明示的にサポートされる最終手段の復旧パスです。 「その日のうちに
#      ホストを再構築できる」と事前に分かっていることが、 「消去・
#      再インストールを受容できる物理マシン」の意味するところです。
#
#   E. 補足: -CleanWorkRoot はこのリスク対策にはなりません。 Install の
#      破壊的副作用はワークスペースではなく OS そのものにあります。

# ---- 1. 最初に chipset driver をインストールし、 再起動 ----
.\Deploy-AMDChipsetDriverOnWindowsServer.ps1 -Action Install
# 完了後、 I04 の出力を必ず確認:
#   - LOADED, REBOOT_NEEDED, LOAD_FAILED, FAILED の各バケットの件数
#   - LOAD_FAILED > 0 の場合: ここで停止して原因究明 (次に進まない)
#   - REBOOT_NEEDED > 0 の場合: 再起動を実行
Restart-Computer
# 起動後、 ベースラインを確認:
.\Deploy-AMDChipsetDriverOnWindowsServer.ps1 -OnlyPhases V06
# V06 が期待される post-install 状態を報告した場合のみ次に進む

# ---- 2. graphics driver をインストールし、 再起動 ----
.\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Action Install
# I04 確認は step 1 と同じ。 LOAD_FAILED > 0 もしくは Section 2 で
# functional probe failure が出ている場合は停止し、 ここで復旧する。
# 後段で復旧するより遥かに楽です。
Restart-Computer
.\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -OnlyPhases V06

# ---- 3. BthPan をインストール (置換面が最小、 リスクが最低) ----
.\Deploy-MSBthPanInboxOnWindowsServer.ps1 -Action Install
# I04 が "*** TRUE RESOLUTION NOT YET ACHIEVED ***" の場合は
# 再起動して同コマンドを再実行。 PnP rebind は新規 boot を要求する
# ケースがあります。
```

すべてのスクリプトは冪等で、 cleanup-safe です (`-Action Cleanup` でワークスペース削除、 trust store からの証明書削除、 deploy された WDAC policy の削除を行います)。 ただし **Cleanup は OS が起動している状態でないと実行できません**。 `Install` 後にホストが起動不能になった場合は [起動不能状態からの復旧](#起動不能状態からの復旧)を参照してください。

> **全部を 1 パスで実行できないか?** 概念上、 3 本の Install action は最終的に同一の終端状態 (パッチ済み INF が driver store に存在、 自己署名証明書が kernel に信頼される) に収束します。 しかし**実機の故障モード**はそうではありません: 各 Install は次の boot まで顕在化しない regression を導入し得て、 スクリプト個別の post-install 検証 (I04 / V06) は live OS 上で実行されるため、 ブートローダが新しい driver 群に対して kernel CI を再評価した結果までは完全に予測できません。 1 本ずつ実行し再起動を挟むことで、 任意の regression の影響範囲を「最後にインストールしたドライバファミリ」に限定でき、 これは「WinRE で 1 つの driver を rollback すれば済む」と「OS 再インストール」を分ける差です。

> **BthPan スクリプト固有の成否判定**: BthPan スクリプトの `Install` 完了後、 I04 (PostInstallVerification) は Phantom OK と真の解消を明示的に区別します。 `bthpan.sys` が load されかつ `BthPan` サービスが稼働中、 `BTH\MS_BTHPAN` が `Class=Net・Service=BthPan・DriverInfPath=oem*.inf` を報告する場合のみ、 スクリプトは `*** TRUE RESOLUTION ACHIEVED ***` と表示します。 代わりに `*** TRUE RESOLUTION NOT YET ACHIEVED ***` と表示された場合、 再起動が典型的な解決策です (PnP rebind は次回起動時にしか効かないケースがあります)。

> **NPU スクリプトの `Install`**: [NPU スクリプト固有の Quick Start](#npu-スクリプト固有の-quick-start) を参照してください。 `Install` アクションには追加の前提条件 (offline ZIP の所有もしくは AMD アカウント認証情報) が必要で、 **物理 NPU ハードウェアなしでの実行は推奨されません**。

### 起動不能状態からの復旧

`-Action Install` 後の再起動でホストが起動できなくなった (画面非表示、 再起動ループ、 boot 時 BSOD、 **セーフモードも起動不能**等) 場合、 物理マシンで現実的な復旧手段を、 オペレータが実際に試すべき順で以下に示します。 VM の場合とは順序が異なります: 物理ホストのオペレータの大半は事前ディスクイメージを持っていないため、 WinRE 経由のオフライン修復を最優先とします。

1. **WinRE 経由のオフライン修復** (事前ディスクイメージなしの物理マシンでの主経路)。 Step 0A で作成した復旧 USB から起動します。 WinRE → トラブルシューティング → 詳細オプション → コマンドプロンプトに入り、 以下を順に試行 (各ステップの後に再起動して、 復旧したか確認):

   1.1. **WinRE 上でシステムドライブのドライブレターを特定する**。 WinRE は drive letter を再割り当てするので、 動作中 OS での `C:` が WinRE 上では `D:` や `E:` になっていることがあります。 `diskpart`、 `list volume` を実行し Windows インストールがあるボリュームを探してドライブレターを記録、 `exit`。 以下の例では `C:` を使いますが、 実際のドライブレターに置き換えてください。

   1.2. **uncommitted な Setup transaction を取り消す:**
   ```cmd
   dism /image:C:\ /cleanup-image /revertpendingactions
   ```
   失敗した reboot 前に完了しなかった保留中の driver install / servicing 操作を取り消します。 まずこれを試行 — 最もコストが低く、 「install transaction 自体が問題だった」ケースを意味のある割合で解決できます。

   1.3. **本リポジトリのスクリプト群が追加した OEM driver を削除する:**
   ```cmd
   dism /image:C:\ /get-drivers /format:table
   ```
   本リポジトリが公開した `oem<NN>.inf` エントリを特定 (Provider 列に self-signed cert の Subject CN が表示されます。 例: `AMD Chipset Driver Self-Sign (WS2019 Lab, At Own Risk)`)。 各エントリに対して:
   ```cmd
   dism /image:C:\ /remove-driver /driver:oem<NN>.inf
   ```
   問題のある driver-store エントリを、 壊れた OS を起動せずに削除できます。 本リポジトリが公開した全 OEM driver を削除した後、 再起動。

   1.4. **r69 以前からアップグレードした場合、 残置された WDAC SPF policy も削除する**。 r70 で orchestrator は削除され、 4 本の driver script はホスト全体の SPF policy を deploy しなくなりました。 ただし、 r69 以前で Chipset / Graphics / BthPan Install を実行したことのあるホストには、 削除された orchestrator が deploy した `C:\Windows\System32\CodeIntegrity\SiPolicy.p7b` が残っている可能性があります。 そのようなホストの WinRE 復旧時には、 当該ファイルの削除が orchestrator の `-Action Uninstall` と等価な操作になります:
   ```cmd
   del C:\Windows\System32\CodeIntegrity\SiPolicy.p7b
   ```
   **C: で BitLocker が有効な場合、 次回 boot で回復キーが要求されます** — Step 0B が必須となる理由です。 r70 以降のリリースのみで運用してきたホストには当該ファイルは存在しないため、 このステップは no-op になります。

   1.5. **WinRE 側での最終手段としてのスタートアップ修復**: トラブルシューティング → 詳細オプション → スタートアップ修復。 Microsoft の自動修復は boot loader のみの破損の一部を、 上記コマンドが対処しない範囲でカバーします。

2. **Install 前のフルディスクイメージへロールバック** (Step 0C で取得していた場合)。 物理マシンでは、 イメージ取得ツールの rescue media (Macrium / Clonezilla 等)から起動し、 C: イメージを元のドライブへ復元します。 ドライブサイズ次第で 20-60 分。 **イメージがあれば既知の良好状態への最速経路**ですが、 大半の物理マシンオペレータは持っていません。

3. **ディスクを抜き出し、 動作するマシンからオフライン読み取り**。 復旧 USB が何らかの理由で起動しない場合 (失敗したホストの UEFI Secure Boot ポリシーが外部メディアを拒否する等)、 ディスクを物理的に取り外して USB-to-NVMe / SATA アダプタで動作するマシンに接続し、 そのマシンから `dism /image:` や `del` を実行します。 オプション 1 より遅いですが、 失敗したホストが外部メディアを起動できないケースをカバーします。

4. **OS 再インストール** (最終手段)。 オプション 1-3 が失敗もしくは実行不可能 (復旧 USB なし、 予備マシンなし、 ディスクイメージなし) の場合、 Step 0D の媒体から再インストール。 これは本リポジトリの明示的にサポートされる最終手段の復旧パスであり、 免責事項で「消去・再インストールを受容できる物理マシン」を強調している理由です。

本リポジトリは **壊れた OS の内部から実行する復旧スクリプトは提供しません** — 故障モードの性質上、 OS がもう走っていないからです。 提供している保護は完全に予防的です: 上記の Step 0 チェックリスト、 積極的な `-Action PrepareVerify` dry-run 出力、 V05/V06 ハードウェア影響解析、 そして厳格な「再起動を挟む」シーケンシングです。

### 特定 phase のみの実行

```powershell
# 再ダウンロードせずパッチ済み INF と catalog だけ再生成
.\Deploy-AMDChipsetDriverOnWindowsServer.ps1 -Action Prepare -OnlyPhases P05,P06,P08,P09

# 証明書信頼 phase だけ実行
.\Deploy-AMDChipsetDriverOnWindowsServer.ps1 -Action Install -OnlyPhases I01

# BthPan の Phantom-OK readiness 解析のみを実行 (システム変更なし)
.\Deploy-MSBthPanInboxOnWindowsServer.ps1 -OnlyPhases V06

# 全 phase をリスト表示
.\Deploy-AMDChipsetDriverOnWindowsServer.ps1 -Action ListPhases
```

---

## BthPan スクリプト固有の Quick Start

> BthPan スクリプトは 4 スクリプト中最も実行が簡単です。 ドライバソースがホスト自身の DriverStore であり、 ネットワークダウンロード・ AMD アカウント・ EULA-gated ZIP のいずれも不要だからです。

### Step 1 — Bluetooth host controller が bind されていることを確認

BthPan スクリプトが扱うのは `BTH\MS_BTHPAN` (Bluetooth host controller bind 後に公開される Personal Area Network 子デバイス) のみです。 host controller 自体は **本スクリプトの対象外**です。

```powershell
# host controller が "Unknown device" ではなく Status=OK になっていることを確認。
Get-PnpDevice -Class Bluetooth -ErrorAction SilentlyContinue |
    Select-Object FriendlyName, Status, InstanceId

# host controller (例: Intel AX210・ Realtek RTL8852・ MediaTek MT7921 等) が
# "Unknown device" の場合、 先にベンダードライバをインストールしてください。
# 本スクリプトは host controller のドライバは扱いません。
```

### Step 2 — 現在状態を診断 (システム変更なし)

```powershell
.\Deploy-MSBthPanInboxOnWindowsServer.ps1 -OnlyPhases V06
```

V06 はホスト上のすべての `BTH\MS_BTHPAN*` デバイスインスタンスについて per-instance 分類を出力します。 3 種類の状態があります:

| 分類 | 意味 | 推奨される次の操作 |
| --- | --- | --- |
| **Unknown** | Status=Error (code 28)。 ドライバが bind されていない。 | `-Action Install` を実行。 |
| **Phantom** | Status=OK だが `DriverInfPath=bth.inf`・ `Class=Bluetooth`・ `Service=(空)`。 `bthpan.sys` は **load されておらず**、 Device Manager は問題なく見えても PAN networking は機能していない。 | `-Action Install` を実行。 install 後、 I04 が rebind を検証。 |
| **True** | `DriverInfPath=oem*.inf`・ `Class=Net`・ `Service=BthPan`。 `bthpan.sys` は load 済、 BthPan サービスは稼働中。 | 操作不要。 既に真の解消状態にあります。 |

### Step 3 — フルインストール

```powershell
.\Deploy-MSBthPanInboxOnWindowsServer.ps1 -Action All -CleanWorkRoot
```

`-Action All` は 21 phase すべて (`P00-P09` → `V01-V06` → `I00-I04`) を 1 コマンドで実行します。 I03 には `pnputil /scan-devices` が含まれており、 PnP マネージャに `BTH\MS_BTHPAN` の再評価を強制し、 `bth.inf` (Phantom 代理マッチ) からパッチ済み `oem*.inf` (真の解消) への rebind を発生させます。

I04 が `*** TRUE RESOLUTION NOT YET ACHIEVED ***` を報告した場合、 再起動が典型的な解決策です。 PnP rebind は次回起動時にしか効かない場合があります。 同じコマンドを再実行すると、 スクリプトの resume-after-reboot ロジックが新しい状態を検出し、 `*** TRUE RESOLUTION ACHIEVED ***` と報告するはずです。

### Step 4 — Decoration 戦略の選択 (上級者向け)

```powershell
# 戦略 A (デフォルト): NTamd64...3 のみ追加 (ProductType=3 はすべての Server SKU をカバー)。
.\Deploy-MSBthPanInboxOnWindowsServer.ps1 -DecorationStrategy A

# 戦略 B: NTamd64.10.0...14393 / 17763 / 20348 / 26100 も明示的に追加。
# 将来 Microsoft inbox update で Server decoration が追加された場合に、
# わずかに高い PnP-ranking 優位性を提供。 将来の新 Server SKU build には手動更新が必要。
.\Deploy-MSBthPanInboxOnWindowsServer.ps1 -DecorationStrategy B
```

実運用では **戦略 A で十分**です (対応する 4 Server build 14393・ 17763・ 20348・ 26100 すべてをカバー)。 戦略 B は複数の bthpan パッケージが bind スロットを競合しており、 per-build エントリで確定的な tie-break が必要な環境のために存在します。

### Step 5 — 結果検証

```powershell
# bthpan.sys がコピーされたか?
Test-Path C:\Windows\System32\drivers\bthpan.sys

# BthPan サービスが登録・稼働中か?
Get-Service BthPan -ErrorAction SilentlyContinue

# Bluetooth PAN NetAdapter が visible か?
Get-NetAdapter | Where-Object InterfaceDescription -Match 'Bluetooth.*Personal Area Network'

# デバイスレベルの状態 (Class=Net・ Service=BthPan が期待される):
Get-PnpDevice -InstanceId 'BTH\MS_BTHPAN*' |
    Get-PnpDeviceProperty -KeyName DEVPKEY_Device_Class, DEVPKEY_Device_Service, DEVPKEY_Device_DriverInfPath
```

---

## NPU スクリプト固有の Quick Start

> **再掲**: 本スクリプトは実験的です。 続行前に [4 スクリプトのリスク分類](#4-スクリプトのリスク分類) を必ず読んでください。

> **🆘 r17 (2026-05-23, Q-X1) — NPU は legacy Windows Server で Install を拒否します。** r17 以降、 `Deploy-AMDNpuDriverOnWindowsServer.ps1` は **Windows Server 2019 (build 17763) と Windows Server 2016 (build 14393) では `-Action Install` と `-Action All` を拒否** します。 AMD NPU driver pipeline は legacy Server SKU 上で物理ハードウェア検証が一切行われておらず、 これらの OS で Install を実行することは未検証のコードを走らせることになります。 **非破壊 action は引き続き利用可能** (WS2019 / WS2016): `-Action PrepareVerify` (デフォルト)、 `-Action Prepare`、 `-Action Verify`、 `-Action Cleanup`、 `-Action ListPhases`。 WS2019 / WS2016 で NPU を必要とする場合は GitHub Issue を開いてください — 物理機での検証完了後に path を有効化できます。 詳細は SPEC §D.27。

### Step 1 — NPU ドライバ ZIP を取得 (4 つのいずれかの Tier)

NPU スクリプトは優先順位の高い順に **4 段階のダウンロード方式 (Tier)** を実装しています:

| Tier | 方式 | 利用シーン |
| --- | --- | --- |
| **1** | `-InstallerUrl <url>` で URL を明示 | ブラウザセッションで AMD CDN URL (例: `entitlenow.com` のリンク) を取得済みの場合。 |
| **2** | `-AmdAccountUser <email> -AmdAccountPassword <SecureString> -ForceAmdAccountAuth` | EULA 受諾フローを自動実行させたい場合。**❌ 2026-05-10 の検証で `account.amd.com` が JavaScript-driven SPA であることが確認されたため、デフォルト無効化済み。`-ForceAmdAccountAuth` で opt-in 可能 (現状の AMD ポータルでは失敗が想定されます)。** 詳細な検証レポートは `TESTING.md` §3.6 (英語のみ) を参照してください。 |
| **3** | EULA-gated 直接 fetch probe | 自動。ほぼ常にフォールスルーします (AMD は JS-driven submission を要求するため)。 |
| **4** ★ | `-OfflineZip <path>` もしくはスクリプトディレクトリ直下の `NPU_RAI*_WHQL.zip` | **推奨。** ZIP を一度手動でダウンロードし、スクリプト隣に配置。実行間で再現性あり。 |

Tier 4 用の手動ダウンロード手順:

- AMD ドキュメントページ: <https://ryzenai.docs.amd.com/en/latest/inst.html#install-npu-drivers>
- 検出された NPU 用の適切なドライバリンクをクリック (例: STX/KRK には NPU Driver 32.0.203.314、RAI 1.6.1)。
- AMD アカウントでサインインし EULA を受諾、ZIP を手元に保存 (典型的なファイル名: `NPU_RAI1.6.1_314_WHQL.zip`)。

### Step 2 — Dry-run (システムには変更を加えません)

推奨パターンは **`-Action PrepareVerify` + `-OfflineZip`** の組合せです。`-OfflineZip` を指定すると 4-tier resolution はスクリプト 824 行目の Tier 4 priority block で短絡判定し、ローカル ZIP が即座に使用されます — AMD 側へのネットワーク呼び出し無し、フォーム解析の脆弱性無し。

```powershell
# 推奨 — パイプライン健全性検証、システム未変更。
# OfflineZip は Tier 4 priority block で即座に確定 (AMD ネットワーク呼び出し無し)。
# 実機 NPU ホスト (Ryzen AI 300 / AI Max 300 / 7040 / 8040 シリーズ):
.\Deploy-AMDNpuDriverOnWindowsServer.ps1 `
    -Action PrepareVerify `
    -CleanWorkRoot `
    -OfflineZip .\NPU_RAI1.6.1_314_WHQL.zip
```

```powershell
# NPU 不在ホストでのパイプライン健全性チェック用 — 上記に -AssumeIfMissing を追加。
# P03 で NPU デバイス未検出時、エラーで停止せず default Strix Point profile で続行。
# パイプライン機構の検証のみで有効 (デバイスバインドは 0 件になり、実 NPU 挙動の検証にはならない)。
.\Deploy-AMDNpuDriverOnWindowsServer.ps1 `
    -Action PrepareVerify `
    -CleanWorkRoot `
    -OfflineZip .\NPU_RAI1.6.1_314_WHQL.zip `
    -AssumeIfMissing                            # default Strix Point + RAI 1.7.1
```

```powershell
# 非推奨 — クリーン環境で -OfflineZip 無しのパイプライン検証実行。
# このコマンドの内部挙動:
#   Tier 1 (-InstallerUrl)            : skip (未指定)
#   Tier 4 priority (-OfflineZip)     : skip (未指定)
#   Tier 2 (AMD アカウント自動 DL)    : skip (認証情報無し)
#   Tier 3 (EULA-gated direct probe)  : ほぼ常にフォールスルー (HTML フォーム返却)
#   Tier 4 auto-scan                  : スクリプトディレクトリ・./cache・workspace・~/Downloads を検索
# -CleanWorkRoot でワークスペースが削除済みかつ NPU_RAI*_WHQL.zip が auto-scan の
# どのロケーションにも無ければ、P03 で "All 4 download tiers exhausted" と throw する。
.\Deploy-AMDNpuDriverOnWindowsServer.ps1 -Action PrepareVerify -CleanWorkRoot
```

### Step 3 — Install (実機 NPU を持ち、上記の警告を全て理解した場合のみ)

```powershell
# 推奨 — 手動ダウンロード済み offline ZIP を使ったフルインストール。
.\Deploy-AMDNpuDriverOnWindowsServer.ps1 `
    -Action Install `
    -OfflineZip .\NPU_RAI1.6.1_314_WHQL.zip
# I00 で以下の確認のため "I AGREE" の入力が要求されます:
#   1) AMD Ryzen AI EULA の受諾
#   2) Ryzen AI Software が公式に Windows 11 only であること
#   3) kernel-mode driver のみ install (user-mode stack は別途要 install)
#   4) BitLocker recovery key 控え済み
```

インストール成功後、スクリプトは guidance ブロックを表示し、**Ryzen AI Software (Python conda env、OGA、Vitis AI EP) は別途 <https://account.amd.com/en/forms/downloads/xef.html?filename=ryzen-ai-lt-1.7.1.exe> から install する必要がある**こと、user-mode stack は AMD 公式に Windows 11 build >= 22621.3527 only サポート (Windows Server 2025 ではサポートされない) であることを再度通知します。

### NPU 固有の便利オプション

NPU スクリプトは AMD 公式 [Ryzen AI Software インストールドキュメント](https://ryzenai.docs.amd.com/en/latest/inst.html) に従い、**2 つの独立したバージョニング軸**と、それらを評価する **互換性軸 (別軸)** を扱います:

| 軸 | パラメータ | デフォルト | 制御内容 |
|---|---|---|---|
| **A. NPU カーネルモードドライバ** | `-NpuDriverPackage` | `latest` (= `NPU_RAI1.6.1_314`) | スクリプトが対象とする NPU ドライバ ZIP パッケージ。AMD は現状 2 種類のみ公開: `NPU_RAI1.5_280` (driver 32.0.203.280) と `NPU_RAI1.6.1_314` (driver 32.0.203.314)。両者とも全 NPU コードネーム (PHX/HPT/STX/STH/KRK) をカバー。ドライババージョニングはゆっくり進化します。 |
| **B. Ryzen AI Software (ユーザーモードスタック)** | `-RyzenAiSoftwareVersion` | `latest` (= `1.7.1`) | post-install ガイダンスで言及される Ryzen AI Software バージョン (EXE は別途インストール)。AMD は **エンドユーザーワークロードでは常に最新版** を推奨。 |
| **C. 互換性評価** | (自動) | n/a | P03 で A + B から自動算出。現状 AMD は全 RAI バージョンが driver `≥ 32.0.203.280` を要求していることを文書化しているため、`280` および `314` の両方が RAI `1.5`〜`1.7.1` と互換。 |

A 列と B 列のスイッチは **独立** です。バージョンラベルを揃える必要はなく、例えば `-NpuDriverPackage NPU_RAI1.6.1_314 -RyzenAiSoftwareVersion 1.7.1` は AMD 公認の有効な組合せ (新しいドライバ + 最新 RAI Software) です。

これらのスイッチは **挙動を変更するだけで、ZIP のダウンロードソースを提供しません**。常に `-OfflineZip`、`-InstallerUrl`、または `-AmdAccountUser`/`-AmdAccountPassword -ForceAmdAccountAuth` (それぞれ Tier 4 / Tier 1 / Tier 2) と組み合わせて使用してください。

```powershell
# 特定 NPU codename を強制 (CPU 名検出が曖昧な場合。例: PHX vs HPT)
# 動作を予測可能にするため -OfflineZip と組合せて利用:
.\Deploy-AMDNpuDriverOnWindowsServer.ps1 `
    -Action PrepareVerify `
    -OfflineZip .\NPU_RAI1.6.1_314_WHQL.zip `
    -NpuOverride STX                            # PHX | HPT | STX | KRK

# 特定 NPU ドライバパッケージを pin (axis A)。注意: -NpuDriverPackage はスクリプトが
# どのパッケージを前提にロジックを組み立てるかを制御するので、-OfflineZip は同じパッケージ
# のものを指定する必要があります。
.\Deploy-AMDNpuDriverOnWindowsServer.ps1 `
    -Action Install `
    -OfflineZip .\NPU_RAI1.6.1_314_WHQL.zip `
    -NpuDriverPackage NPU_RAI1.6.1_314          # NPU_RAI1.5_280 | NPU_RAI1.6.1_314 | latest

# 特定 Ryzen AI Software バージョンを pin (axis B)。デフォルト 'latest' を推奨。
# このパラメータは post-install guidance メッセージにのみ影響します — Ryzen AI Software
# EXE は AMD ダウンロードページから別途ユーザーがインストールします。
.\Deploy-AMDNpuDriverOnWindowsServer.ps1 `
    -Action Install `
    -OfflineZip .\NPU_RAI1.6.1_314_WHQL.zip `
    -RyzenAiSoftwareVersion latest              # 1.5 | 1.6.1 | 1.7 | 1.7.1 | latest

# AMD アカウント自動ダウンロード (Tier 2 — 2026-05-10 検証によりデフォルト無効化済み。
# opt-in する場合は -ForceAmdAccountAuth を指定。現状の AMD SPA ポータルでは失敗が想定されます。)
$cred = Get-Credential -UserName 'you@example.com' -Message 'AMD アカウントパスワード'
.\Deploy-AMDNpuDriverOnWindowsServer.ps1 `
    -Action Install `
    -ForceAmdAccountAuth `
    -AmdAccountUser $cred.UserName `
    -AmdAccountPassword $cred.Password
```

> **よくある落とし穴**: `-Action Install -NpuOverride STX -NpuDriverPackage NPU_RAI1.6.1_314` を **ダウンロードソース未指定で** 実行すると、Tier 4 auto-scan にフォールスルーし、`~/Downloads` に偶然ある `NPU_RAI*_WHQL.zip` を黙って利用してしまいます — 指定したパッケージと一致するかどうかは保証されません。**常にソースを明示的に固定してください**。

---

## パイプラインアーキテクチャ (21 + 1 phase)

4 スクリプトは 21 phase (P00–P09、V01–V06、I00–I04) を共有します。BthPan スクリプトはこれに加えて、I04 で実機の "詰まりドライバ" を検出した場合 (かつその場合のみ) に再起動なしでドライバ binding を復旧する Install group phase (**`I05`**) を追加実装しています。共通 21 phase は 4 スクリプト全てで実行され、 I05 は BthPan 専用です。

| Group | ID | 名称 | 内容 |
| --- | --- | --- | --- |
| Prep | P00 | Initialize | OS 検出、admin/TLS pre-flight、Workstation 上では WS2025 preview-mode banner 表示。NPU スクリプトでは Ryzen AI Software OS サポート警告も表示 |
| Prep | P01 | PrepareWorkspace | `C:\Temp\Workspace_AMD-{Chipset,Graphics,NPU}\` または `C:\Temp\Workspace_Microsoft-BthPan\` を作成 (`C:\Temp` がない場合は自動作成) |
| Prep | P02 | AcquireTools | 7-Zip、Windows SDK (signtool)、Windows WDK (inf2cat) を `winget` でインストール、失敗時は直接 EXE fallback |
| Prep | P03 | FetchInstaller | ホストの AMD platform 検出、amd.com から最新 installer URL 解決 (chipset/graphics)、もしくは 4-tier 解決 (NPU)、ダウンロード |
| Prep | P04 | ExtractInstaller | 7-Zip による展開。NPU スクリプトはネスト ZIP の検出にも対応 |
| Prep | P05 | AnalyzeInfs | 全 INF を inventory 化、source variant (W11x64 / WTx64 / WT6A_INF / WT64A、NPU では PHX/HPT vs STX/KRK) で分類、ホスト OS / NPU の対応 INF を選択 |
| Prep | P06 | PatchInfs | Server decoration を持たない INF について、各 Workstation `[Manufacturer]` エントリを `ProductType=3` で mirror。最初から Server-compatible な INF も patched フォルダにコピーして install パイプラインで処理されるようにする |
| Prep | P07 | CreateCertificate | RSA 4096 / SHA-384 自己署名コード署名証明書を生成 (有効期間 5 年)、PFX と CER で export |
| Prep | P08 | GenerateCatalogs | 各 patched INF フォルダで `inf2cat /os:Server2025_X64` を実行 |
| Prep | P09 | SignCatalogs | 全 catalog で `signtool sign /fd SHA384 /td SHA384 /tr <timestamp-url>` を実行 |
| Verify | V01 | VerifyArtifacts | 証明書 + パッチ済み INF + catalog の存在確認 |
| Verify | V02 | VerifyCertificate | PFX デコード、EKU・有効期間・鍵長の確認 |
| Verify | V03 | VerifyCatalogs | `signtool verify /pa` (I01 で証明書を信頼するまで失敗が想定) |
| Verify | V04 | VerifyInfs | パッチ済み INF を再 parse し、`ProductType=3` decoration の coverage を確認 |
| Verify | V05 | DryRunInstall | `Win32_PnPSignedDriver` を使って I01-I03 をシミュレート、各 install / skip / upgrade 判定を予測、install plan を出力 |
| Verify | V06 | HardwareImpactAnalysis | ホスト上の AMD ハードウェアを enumerate、AS-IS ドライバとパッチ済み TO-BE ドライバを比較、リスク (HIGH / MEDIUM / LOW) 分類。NPU スクリプトでは Ryzen AI Software user-mode stack 関連の通知も表示 |
| Inst | I00 | PreInstallReview | V06 リスクサマリを表示、operator の確認を要求 (NPU スクリプトでは Ryzen AI EULA への明示的 `I AGREE` 入力も要求) |
| Inst | I01 | TrustCertificate | CER を `LocalMachine\Root` + `LocalMachine\TrustedPublisher` に import |
| Inst | I02 | AuthorizeDriverSigning | 当該証明書を参照する WDAC supplemental policy を build + deploy — **ただし `-WdacBasePolicyGuid` 指定時のみ**。 base policy の既定値は存在せず、 未指定の場合このフェーズは supplemental 配置を拒否します (SPEC D.58.8)。 `-UseTestSigning` 指定時のみ legacy `bcdedit /set testsigning on` 経路に fallback。 supplemental policy の有効化は OS ごとの activation plan に従います (SPEC D.58.9): Windows Server 2025 / Windows 11 22H2+ では inbox の `CiTool.exe`、 WS2022 ではダウンロード配布の `RefreshPolicy.exe` か WMI/CIM 経由の `PS_UpdateAndCompareCIPolicy` bridge、 WS2016/WS2019 では supplemental 経路そのものを**拒否** (single-policy format)。 BCDEdit testsigning は明示的な `-UseTestSigning` 指定時のみ実行します (Mode T、 lab ホスト限定) |
| Inst | I03 | InstallDrivers | 対象 INF 全てに対して `pnputil /add-driver <patched.inf> /install` を実行 |
| Inst | I04 | PostInstallVerification | AMD ハードウェアを再 enumerate、各対象デバイスに `[C] Self-signed` ドライバが bind されたか確認。NPU スクリプトでは Ryzen AI Software user-mode stack インストール guidance も表示。 BthPan スクリプトの本 phase は言語非依存の識別子 (`DriverFileName`、`ComponentID`、`PnPDeviceID`) のみを用いるため、日本語・中国語・ドイツ語などの SKU でも正しく動作します — 詳細は [SPEC §D.19](./SPEC.md) を参照 |
| Inst | **I05** | **ForceRebind** (**BthPan 専用**) | `I04 OverallResult = PartialOrPhantom` の場合に限り (かつその場合のみ) 起動。`Restart-PnpDevice` → `Disable/Enable-PnpDevice` → `pnputil /remove-device /scan-devices` → `Stop/Start-Service BthPan` のエスカレーション順序で再起動なしのドライバ復旧を試行します。WS2016 / WS2019 / WS2022 / WS2025 上で利用可能なコマンドレットを自動検出し、ない場合はそのアテンプトを skip して次へ進みます — 詳細は [SPEC §D.22](./SPEC.md) を参照。成功時は `I04 OverallResult` を `TrueResolution` に昇格させ、pending-reboot marker を消去します |

---

## パラメータ一覧（スクリプト別）

4 スクリプトは `-Action`、 `-OnlyPhases`、 `-CleanWorkRoot`、 `-AllowWorkstationInstall`、 `-UseTestSigning`、 `-WorkRoot`、 `-PfxPassword` を共通パラメータコントラクトとして共有します。 Chipset / Graphics スクリプトはこれに加えて source-discovery と help 用のスイッチを共有、 NPU スクリプトは 4-tier installer 解決と platform override ブロックを追加します。

### 共通パラメータ (Chipset / Graphics / NPU)

| パラメータ                  | デフォルト           | 説明                                                                                              |
| -------------------------- | -------------------- | ------------------------------------------------------------------------------------------------- |
| `-Action`                  | `PrepareVerify`      | `Prepare` / `Verify` / `PrepareVerify` / `Install` / `All` / `Cleanup` / `ListPhases`             |
| `-OnlyPhases`              | `@()`                | Phase ID (例: `P05`、 `P06`、 `P08`、 `P09`) または short name (例: `PatchInfs`); `-Action` を上書き |
| `-CleanWorkRoot`           | (off)                | workspace を実行前に削除 (download/extract を再取得)                                              |
| `-AllowWorkstationInstall` | (off)                | Workstation OS (Win11) での Install phase 実行を許可。 デフォルトは block される (非推奨スイッチ) |
| `-UseTestSigning`          | (off)                | WDAC 補助 policy ではなく `bcdedit /set testsigning on` にフォールバック (非推奨)                 |
| `-WorkRoot`                | スクリプト別         | workspace path を上書き (Chipset: `C:\Temp\Workspace_AMD-Chipset`、 Graphics: `C:\Temp\Workspace_AMD-Graphics`、 NPU: `C:\Temp\Workspace_AMD-NPU`、 BthPan: `C:\Temp\Workspace_Microsoft-BthPan`)。 `C:\Temp\Workspace_*` 配下に配置。 `C:\Temp` がない場合はスクリプトが自動作成 |
| `-LogFile`                 | 自動生成            | コンソール出力全体を `Start-Transcript` / `Stop-Transcript` でキャプチャするトランスクリプトのパス。 **r91+: 省略時 (デフォルト) は自動的にトランスクリプトが常時作成される** (`<WorkRoot>\\logs\\<ScriptName>_<Action>_<yyyyMMdd-HHmmss>_<PID>.log`)。 エントリバナーより前に開始されるため、 バナーと P00 の実行環境レポート全体がログに含まれる (`-CleanWorkRoot` 時は suspend/wipe/resume フローで wipe を生き延びる。 無効化スイッチはなし)。 明示的にパスを渡せば出力先を上書きできる。 ファイル側は全ストリーム (Output / Host / Error / Warning / Verbose / Debug) をプレーンテキストで受け取り、 インタラクティブコンソール側は `Write-Host -ForegroundColor` の色装飾を維持する。 レガシーな `... \\|*>&1 \\| Tee-Object -FilePath ...` イディオムは Write-Host の色情報がパイプ経由で削除されるが、 こちらは色を保持できるため推奨 |
| `-SkipEvidenceCollection`  | (off — 採取は実行される) | **r94+ (4 本共通)。** エビデンス採取は **デフォルト有効**: `ListPhases` を除くすべての実行が、 スクリプトと同じフォルダの `Collect-WindowsServerConfigurationEvidence.ps1` を最初のフェーズ前に stage `pre`、 実行の最終ステップで stage `post` として呼び出し、 diff 可能な読み取り専用エビデンス ZIP をスクリプトフォルダに生成する。 本スイッチ指定時は両方の採取をスキップ。 ベストエフォート: コレクタ側の問題は警告のみでデプロイ実行には影響しない。 (r93 ではオプトインの `-CollectEvidence` として出荷されたが、 常時自動採取という本来要件を満たすため r94 で極性を反転 — PSA6006 がデフォルト `$true` の switch を禁止しているため。) |
| `-PfxPassword`             | スクリプト別         | 自己署名 PFX のパスワード。 Chipset / Graphics / BthPan: **未指定時は実行ごとのランダム 32 文字 CSPRNG** (W4)。 NPU: `''` かつ既知リテラルの export 分岐が残存 — **未解決、 監査 H-05R (W7 予定)** |
| `-WdacPolicyGuid`          | スクリプト別 (固定 UUID v4) | WDAC 補助 policy GUID を上書き。 デフォルトはスクリプト別 (Chipset: `503860EA-…`、 Graphics: `85336828-…`、 NPU: `8B2C4F12-…`)。 レガシー deploy のクリーンアップ、 または並列複数 deploy で使用 |
| `-ForceUnsafe`             | (off)                | **r69+ (Chipset / Graphics / BthPan のみ)。** I00 PreInstallReview で条件 C1 / C2 / C5 / C6 が成立した場合に表示される CRITICAL 承認チェックリスト (シングルディスプレイホストでの display ドライバ置換、 BitLocker ON + AMD PSP ドライバ置換、 ホストが 24+ 時間 reboot されていない、 r71: Secure-Boot-ON ホストでの WHQL co-sign 不足) をバイパス。 CI / CD 自動化用途のみ。 バイパスは `Set-DebugStep` で run transcript に記録される。 **本番では絶対に使用しないこと。** 詳細は SPEC §D.28 と §D.31.4 |
| `-SkipNonCosignedDrivers`  | (off)                | **r71+ (Chipset / Graphics / BthPan のみ)。** インストールプランから非 WHQL co-signed driver をスキップ。 P05 が WHQL co-sign 分析を構築し、 P06 入口で `$Ctx.InfInventory` を Microsoft Windows Hardware Compatibility co-signature を持つ .sys のみを含む INF に絞り込みます。 後続フェーズ (P06 patch / P07 cert / P08 catalog / V03-V06 verify / I03 install) は全て自動的にトリム済みインベントリを参照します。 **r72+**: 本フラグが立っており、トリム後のプランが完全に WHQL co-signed の場合、 I02 が short-circuit して WDAC supplemental policy 配置・ `bcdedit` testsigning・ firmware Secure Boot 変更のいずれも行わずに完了します。 firmware で UEFI Secure Boot を ENABLED のまま運用する必要があるホスト向け。 非 WHQL driver は install されません。 **r96/r97**: トリムはスキーマ耐性化され、 意味論も是正されました — Server 互換でパッチ不要の INF は常に適格で、 WHQL co-sign 分類が要求されるのはパッチ対象サブセットのみです。 P05/P06 が分析とトリム後プランを `whql_cosign_analysis.json` / `whql_cosign_plan.json` (SchemaVersion 2・install スコープ集計・`PlanCatalogSignCount`) としてワークスペースルートに永続化するため、 `PrepareVerify` -> `Install` の分割ワークフローでもプランが参照されます。 I01 のスキップ (信頼ストア無変更) は「パイプラインが自己署名すべきカタログがプランに 1 つも無い」場合のみで、 通常のプランでは I01 は実行されます (全プランカタログが Server OS ターゲット向けに再生成・自己署名されるため)。 詳細は SPEC §D.31、 §D.31.11、 §D.31.17 |

### Chipset / Graphics 固有パラメータ

| パラメータ          | デフォルト                       | 説明                                                                                                |
| ------------------- | -------------------------------- | --------------------------------------------------------------------------------------------------- |
| `-Help` / `-h` / `-?` | (off)                          | フォーマット済みの使用方法情報を表示して終了                                                        |
| `-References`       | (off)                            | 関連 Microsoft Learn ドキュメントリンクの一覧を表示して終了                                          |
| `-InstallerUrl`     | `''`                             | AMD インストーラ EXE の URL を明示指定 — URL 探索 probe を bypass                                    |
| `-AmdLandingUrls`   | スクリプト別デフォルト array     | インストーラ EXE URL を scrape するための landing page (AMD のサイト構造変更時のみ override)         |
| `-AmdFallbackUrl`   | スクリプト別デフォルト URL       | landing page の scraping が失敗した時の last-resort ハードコード URL                                 |
| `-Force`            | (off)                            | 既存 workspace ファイルの強制上書き (要注意)                                                        |
| `-TimestampUrl`     | `http://timestamp.digicert.com`  | `signtool sign /tr` 用 RFC 3161 タイムスタンプサーバ                                                |
| `-WdacBasePolicyGuid` | **(なし)** | WDAC 補助 policy が target とする SupplementsBasePolicyID。 **既定値なし** — 未指定の場合 supplemental 配置は拒否されます。 rule option 17 (`Enabled:Allow Supplemental Policies`) 付きで配置済みであることを確認した base policy の GUID を指定してください。 SPEC D.58.8 |

> **Note**: Chipset / Graphics スクリプトは現状 `-CertValidityYears` を公開していません — デフォルトの 5 年有効期間はハードコードされています。 設定可能なパラメータとして公開しているのは NPU スクリプトのみです。

### NPU 固有パラメータ

| パラメータ               | デフォルト            | 説明                                                                                                              |
| ------------------------ | --------------------- | ----------------------------------------------------------------------------------------------------------------- |
| `-InstallerUrl`          | (なし)                | Tier 1: NPU ドライバ ZIP の URL を明示指定                                                                         |
| `-OfflineZip`            | (なし)                | Tier 4 優先: 事前ダウンロード済み NPU ドライバ ZIP のパス (**推奨パターン**)                                       |
| `-AmdAccountUser`        | (なし)                | Tier 2: AMD アカウントメール (BEST-EFFORT — デフォルト無効)                                                       |
| `-AmdAccountPassword`    | (なし)                | Tier 2: AMD アカウントパスワード (SecureString)                                                                    |
| `-ForceAmdAccountAuth`   | (off)                 | Tier 2 のフォームベース認証を opt-in (現状の AMD JS-driven SPA ポータルに対してはほぼ失敗が予想される)             |
| `-NpuOverride`           | (なし)                | NPU codename を強制: `PHX` / `HPT` / `STX` / `KRK`                                                                |
| `-NpuDriverPackage`      | `latest`              | NPU kernel-mode driver パッケージ: `NPU_RAI1.5_280` / `NPU_RAI1.6.1_314` / `latest` (`NPU_RAI1.6.1_314` に解決される) |
| `-RyzenAiSoftwareVersion`| `latest`              | Ryzen AI Software (user-mode stack) 推奨バージョン: `1.5` / `1.6.1` / `1.7` / `1.7.1` / `latest`                  |
| `-AssumeIfMissing`       | (off)                 | NPU 未検出時にデフォルトプロファイル (Strix Point + NPU driver 32.0.203.314 + RAI Software latest) で続行         |
| `-CertValidityYears`     | `5`                   | 自己署名証明書の有効期間 (年、 NPU スクリプトのみ)                                                                |

> **Note**: NPU ドライバ と Ryzen AI Software のバージョニング軸は **独立**です (AMD ドキュメント <https://ryzenai.docs.amd.com/en/latest/inst.html> 参照)。 `-NpuDriverPackage` と `-RyzenAiSoftwareVersion` は独立スイッチなので、 任意の driver × software 組み合わせが可能 (例: `-NpuDriverPackage NPU_RAI1.6.1_314 -RyzenAiSoftwareVersion 1.7.1`)。

---

## 出力ファイル

各スクリプトは workspace (`C:\Temp\Workspace_AMD-{Chipset,Graphics,NPU}\` または `C:\Temp\Workspace_Microsoft-BthPan\`) 配下に以下のアーティファクトを書き出します:

| パス (workspace からの相対)                  | 内容                                                                                                          |
| -------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| `download\<installer>`                       | AMD インストーラ EXE (Chipset/Graphics) または NPU ドライバ ZIP (NPU)                                          |
| `extracted\`                                 | 展開済みインストーラ内容 (元 INF、 SYS、 DLL、 CAT ファイル)                                                  |
| `patched\<inf>`                              | `ProductType=3` decoration を mirror したパッチ済み INF                                                       |
| `patched\<cat>`                              | 再生成された catalog ファイル (`inf2cat /os:Server2025_X64` 出力)                                              |
| `cert\AMD-Chipset-Driver-CodeSign.pfx` (Chipset) / `cert\AMD-Graphics-Driver-CodeSign.pfx` (Graphics) / `cert\AMD-NPU-Driver-CodeSign.pfx` (NPU) | 自己署名コード署名証明書 (PFX 形式) |
| `cert\AMD-Chipset-Driver-CodeSign.cer` (Chipset) / `cert\AMD-Graphics-Driver-CodeSign.cer` (Graphics) / `cert\AMD-NPU-Driver-CodeSign.cer` (NPU) | 公開証明書 (CER 形式、 trust-store import 用)   |
| `cert\AmdSuppPolicyId.txt` (Chipset/Graphics) | 動的に生成された WDAC supplemental PolicyId をクリーンアップ用に記録するマーカーファイル                       |
| `cert\WDAC-Supplemental-NPU.xml` / `.cip` (NPU) | WDAC 補助 Code Integrity policy (XML ソース + バイナリ、 `C:\Windows\System32\CodeIntegrity\CiPolicies\Active\` に deploy) |
| `cert\MsBthPanSelfSignedSupplementalPolicy.xml` / `.cip` (BthPan) | BthPan 用 WDAC 補助 Code Integrity policy (XML ソース + バイナリ、 `C:\Windows\System32\CodeIntegrity\CiPolicies\Active\` に deploy)。 BthPan 固有 GUID `A6E72D4F-3B98-4C5A-9E1D-7F8B2A4C6E5D` を使用。 |
| `inf_inventory.csv`                          | P05 で生成される INF 単位 inventory (ファイル名、 provider、 class、 HWID 数、 decoration ステータス等)        |
| `inf_inventory_report.txt`                   | P05 INF 解析の人間可読サマリ                                                                                  |
| `logs\inf2cat_bthpan.log` (BthPan)          | inf2cat 詳細ログ。 catalog 生成失敗の診断に有用 |
| `logs\pnputil_bthpan.log` (BthPan)          | pnputil add-driver/install の出力 |
| `logs\pnputil_scan-devices.log` (BthPan)    | pnputil /scan-devices の出力 (I03 が PnP 再バインドを強制) |
| `logs\<ScriptName>_<Action>_<yyyyMMdd-HHmmss>_<PID>.log` | 自動実行トランスクリプト (r91+)。 明示的な `-LogFile` で上書きしない限り、 すべての実行で生成される |
| `logs\amd-landing-probe-*.html` (chipset)   | probe-miss 証跡: URL 探索が 0 件になった際に取得済み AMD ランディングページを保存 (r91+。 SPEC D.37) |
| `logs\run-artifact-archive-plan.txt`        | 予定された run-artifact ZIP 名を記録するマーカー (r92+。 ZIP 自身がこのマーカーを内包し自己識別可能) |
| `secureboot_ms_sample\*.json`               | Microsoft サンプルスクリプトによる UEFI Secure Boot ベースライン証跡 |

### CSV カラム規約

`inf_inventory.csv` は 4 スクリプトで以下のカラム規約に従います:

| カラム                | 型     | 意味                                                                            |
| --------------------- | ------ | ------------------------------------------------------------------------------- |
| `FileName`            | string | INF ファイル名 (例: `kipudrv.inf`)                                              |
| `FullPath`            | string | workspace 内の絶対パス                                                          |
| `Provider`            | string | INF `[Version]` Provider フィールド (例: `AdvancedMicroDevicesInc.`)            |
| `DriverVer`           | string | INF `DriverVer` 行 (例: `07/08/2025,32.0.203.314`)                              |
| `Class`               | string | デバイスクラス (例: `Computer`、 `Display`、 `System`)                          |
| `HwidCount`           | int    | INF が参照する Hardware ID の総数                                               |
| `MatchesTargetNpu`    | bool   | (NPU 限定) INF がターゲット NPU の PCI HWID パターンを参照しているか            |
| `MatchedHwidCount`    | int    | このINF のうちターゲットデバイスにマッチする HWID 数                            |
| `HasServerDecoration` | bool   | INF が既に `ProductType=3` decoration を持つ (パッチ不要)                       |
| `NeedsPatch`          | bool   | INF が Workstation のみの decoration を持ち `ProductType=3` mirror が必要       |
| `SelectedForPipeline` | bool   | スクリプトの filter を通過し、 パッチ/署名パイプラインに入る INF                |

---

## UEFI Secure Boot ベースライン

4 つのスクリプト (Chipset / Graphics / NPU / BthPan) すべては、 ホストの UEFI Secure Boot 証明書ロールアウト状態を P00 で 1 回キャプチャし、 パイプライン全体でそのスナップショットを再利用します。 これは情報提供のみが目的で、 これらスクリプトが操作する OS レイヤの自己署名信頼チェーンは、 ファームウェアレイヤの UEFI Secure Boot 証明書データベースから**独立**しています。 複数の姉妹スクリプトを同じホストで実行する operator は一貫したベースライン情報を確認でき、 UEFI 証明書ロールアウト状況とドライバインストール結果を相関分析できます。

### Windows Server 2025+ の Windows Driver Policy

2026 年 4 月のサービシング以降、 Windows Server 2025 以降には Microsoft 管理の **Windows Driver Policy** が搭載され、 廃止されたクロス署名カーネルドライバへの既定信頼が撤廃されています。 これは本プロジェクトが配置するどのファイルとも別のレイヤーです (SPEC D.58.6)。 識別可能なポリシー GUID (Audit `{784C4414-79F4-4C32-A6A5-F0FB42A51D0D}`、 Enforce `{8F9CB695-5D48-48D6-A329-7202B44607E3}`) を持ち、 EFI システムパーティションの `\EFI\Microsoft\Boot\CiPolicies\Active\` 配下に配置されます。 enforcement への移行前に **250 時間の実使用と、 Server では最低 2 ブートセッション**の評価期間があり、 評価中にブロック対象ドライバがロードされると**両カウンタが 0 にリセット**されます。 本スクリプト群はこのポリシーを無効化しませんし、 今後もしません (受け入れゲート G-04): Microsoft 自身の Custom Kernel Signers 手順が明示的な無効化を要求するほど強いポリシーであり、 自らの成功率のために Microsoft のセキュリティベースラインを黙って弱める配備ツールは operator に害をなします。 このレイヤーの検出と証跡は c11 以降の証跡コレクタが収集します (`windows-driver-policy.json`。 監査 H-06)。 また、 **配置済みの*署名済み* CI ポリシーを有効な代替なしに削除すると Windows は起動不能になります** — 本 README に記載の WinRE `del` による復旧は、 本プロジェクトの未署名アーティファクトにのみ適用されます (SPEC D.30.6、 D.58.6)。

### キャプチャされる内容

スナップショットは 2 つのソースを統合します:

1. **組み込みインベントリ** — `Confirm-SecureBootUEFI`、 `Get-SecureBootUEFI db/kek` で 5 つの正規証明書 (`Windows UEFI CA 2023`、 `Microsoft KEK 2K CA 2023`、 `Microsoft UEFI CA 2011`、 `Microsoft UEFI CA 2023`、 `Microsoft Option ROM UEFI CA 2023`) を直接読み取り。 `HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot{,\Servicing,\Servicing\DeviceAttributes}` レジストリキーと、 `\Microsoft\Windows\PI\Secure-Boot-Update` スケジュールタスクの状態 (ja-JP ホスト上で locale 非依存に動作させるため `Get-ScheduledTask` を使用) を取得。

2. **Microsoft サンプルスクリプト** — `%SystemRoot%\SecureBoot\ExampleRolloutScripts\Detect-SecureBootCertUpdateStatus.ps1` に配備されている場合 (Windows 11 では KB5089549、 Windows 10 では KB5087544 / KB5088863、 WS2025 は 2026-05-12 以降の同等パッチで配信)、 子 PowerShell として起動し、 Microsoft の confidence bucket 判定を取得。 MS スクリプトの入力検証バグ (`:` を含む `-OutputPath` を拒否する。 つまりあらゆる Windows 絶対パスが拒否される) を回避するため stdout-JSON フォールバックを実装。

### 表示箇所

| Phase | 表示形式 | 目的 |
|---|---|---|
| P00 | 1行コンパクト: `Secure Boot baseline: enabled=true UEFI-CA-2023=NotStarted health=Warning [MS-sample=ok]` | operator の即時認知 |
| P05 | `inf_inventory_report.txt` 末尾のテキスト形式アペンディックス | 変更管理ドキュメント |
| V05 | 1行コンパクト `[Dry-Run UEFI Baseline]` ブロック | コミット前の sanity 確認 |
| V06 | 詳細マルチセクション内訳 (Chipset / Graphics は Section 4、 NPU は Section 5) | 詳細フォレンジック |
| I02 | 事前チェック + 計画している WDAC / testsigning パスとの相互参照 | OS レイヤ署名操作前の operator 確認 |

5 箇所すべてで同一のメモリ上スナップショットを再利用し、 MS サンプルスクリプトの呼び出しは 1 ラン当たり最大 1 回に制限されます。

### 健全性判定

- **Healthy** — Secure Boot ON、 UEFI CA 2023 ロールアウトが `Updated` (または対象外)、 ロールアウトエラーなし。
- **Warning** — Secure Boot ON だがロールアウトが進行中 (`NotStarted` / `Started` / `Pending`)、 スケジュールタスクが無効、 または MS サンプルがロールアウトイベント診断を報告。
- **Critical** — Secure Boot OFF (計画した WDAC パスは ON を前提)、 または `UEFICA2023Error` 非ゼロでロールアウトがスタック状態。

I02 では判定結果を提示しますが、 **判定を理由にブロックすることはありません** (両信頼レイヤは独立)。 `Critical` または `Warning` では黄色の advisory が表示され、 operator が続行可否を判断します。

### 診断ファイル

MS サンプルスクリプトが起動された場合、 `<WorkRoot>\secureboot_ms_sample\` 配下に以下のファイルが生成されます:

```
detect_stdout.log                  - キャプチャした raw stdout (Write-Host + JSON)
detect_stdout_extracted.json       - パース済みJSONオブジェクト (BucketId / Confidence / Event1801..1803 カウント)
```

これらはワークスペース成果物の一部として保持され、 `-CleanWorkRoot` を指定しない限り後続ランでも残ります。

---

## コンソール出力フォーマット

スクリプトが出力する全行は、 構造化・タイムスタンプ付きフォーマットに従い、 **4 スクリプト (Chipset / Graphics / NPU / BthPan) で完全に同一**です。 これは意図的な設計で、 複数スクリプトのログを混在して読む operator が同じ語彙とビジュアルレイアウトを認識できるようにするためです。

### マーカーの意味

| マーカー | 色        | 用途     | 例                                                                  |
| -------- | --------- | -------- | ------------------------------------------------------------------- |
| `[*]`    | Cyan      | Step     | `[*] Acquiring signtool, inf2cat, and 7-Zip`                        |
| `[+]`    | Green     | Ok       | `[+] Cert thumbprint: A1B2C3D4...`                                  |
| `[!]`    | Yellow    | Warn     | `[!] Tier 2 (AMD account auto-download) is disabled by default`     |
| `[X]`    | Red       | Fail     | `[X] Top-level error: AMD NPU not detected`                         |
| `[~]`    | DarkGray  | Skip     | `[~] Inventory CSV: C:\Temp\Workspace_AMD-NPU\inf_inventory.csv`     |

セクションバナーテーブル内の継続行 (PowerShell 環境ダンプ、 OS プロファイル、 Secure Boot ベースライン、 INF インベントリ行、 V05/V06/I00 サブブロック等) は `Write-Detail` ヘルパー経由で出力されます。 これはタイムスタンプとマーカー接頭辞を持たない 4 スペースインデント行で、 「すべての行にマーカーを付ける」 規約の唯一の許容例外です。 ログを読む operator は、 4 スペースインデント行を直前のマーカー行の従属的な継続行として扱ってください。 (SPEC §A.5 参照。)

### サンプル出力 (NPU スクリプト、 P00 → P03)

```
========================================================================
 Deploy-AMDNpuDriverOnWindowsServer
 Version: npu-<yyyy.MM.dd>-r<NN>  [<short-kebab-tag>]  SHA256: <12-hex-chars>
 Action : PrepareVerify
 Repo   : https://github.com/usui-tk/Deploy-Drivers-For-WindowsServer
========================================================================

========================================================================
 PHASE P00 - Initialize                 (Prep  )  start: 14:23:05
 script: npu-<yyyy.MM.dd>-r<NN>/<hash12>
========================================================================
[14:23:05]            [*] Running environment and sanity checks
[14:23:05]            [+] Administrator privileges confirmed.
[14:23:05]            [~] TLS protocols enabled: Tls, Tls11, Tls12, Tls13
[14:23:06] [+0.42s]   [+] OS detected     : Microsoft Windows Server 2025 (build 26100)
[14:23:06] [+0.42s]   [~] Profile applied : WS2025
[14:23:06] [+0.42s]   [~] inf2cat /os: switch : Server2025_X64
 PHASE P00 -> DONE     elapsed: 0.45s

========================================================================
 PHASE P03 - FetchInstaller             (Prep  )  start: 14:23:12
========================================================================
[14:23:12]            [*] Detecting NPU platform and resolving installer source (4-tier fallback)
[14:23:12] [+0.18s]   [+] NPU codename         : Strix Point / Strix Halo
[14:23:12] [+0.18s]   [+] NPU short name       : STX
[14:23:12] [+0.18s]   [+] Hardware ID          : PCI\VEN_1022&DEV_17F0&REV_00
[14:23:12] [+0.18s]   [+] NPU driver package   : NPU_RAI1.6.1_314
[14:23:12] [+0.18s]   [+] NPU driver build     : 32.0.203.314
 PHASE P03 -> DONE     elapsed: 1.23s
```

Phase header banner (`=` × 72、 Magenta) は dispatcher が出力し、 phase 関数自身は banner を出しません。 `[+X.XXs]` の elapsed-tag は各 phase エントリで reset され、 **当該 phase 内の経過時間** (スクリプト全体の経過ではない) を表します。

r92 以降、 RUN SUMMARY の末尾には明示的な Install readiness 判定が出力されます (この判定を導入するきっかけとなった実地解析は SPEC D.38 を参照):

```
 Note: [!] lines above are informational / expected-condition notices by
       design (e.g. a baseline check on the unpatched source INF, a
       documented tool fallback, a certificate not yet trusted before
       I01, or a device absent on this host). A real failure marks its
       phase as failed in the timing table.
 Install readiness : READY - no failed phases.
```

---

## 実行ログのキャプチャ (`-LogFile`)

**r91+: すべての実行が自動的にトランスクリプトされます。** `-LogFile` を省略した場合 (デフォルト)、 4 つのスクリプトすべてが次のパスにトランスクリプトを自動生成します:

```
<WorkRoot>\logs\<ScriptName>_<Action>_<yyyyMMdd-HHmmss>_<PID>.log
```

キャプチャは `Start-Transcript` / `Stop-Transcript` 経由で、 トランスクリプトは **エントリバナーより前** に開始されるため、 キャプチャされたファイルにはバナーと P00 の実行環境レポート全体が含まれます。 `-CleanWorkRoot` 指定時、 WorkRoot 内のトランスクリプトは suspend/wipe/resume フローで P01 の wipe を生き延びます: wipe の直前に停止してワークスペース外へ退避し、 ディレクトリ再作成後に戻して `-Append` で再開する — 実行全体が 1 本の連続したファイルでカバーされ、 wipe 自体は従来どおりツリー全体の単純削除のままです。 無効化スイッチは意図的に設けていません (中央 `Update-WindowsServerIso.ps1` プロジェクトのロギング方針に合わせ、 トランスクリプトは常時採取)。

出力先を上書きしたい場合は明示的に `-LogFile <path>` を渡します:

```powershell
# 明示的な上書き: コンソール側は色情報を維持、 ファイル側は全ストリームをプレーンテキストで取得
$ts  = Get-Date -Format 'yyyyMMdd-HHmmss'
$log = "C:\Temp\amd-chipset_PrepareVerify_$ts.log"
.\Deploy-AMDChipsetDriverOnWindowsServer.ps1 -Action PrepareVerify -CleanWorkRoot -LogFile $log
```

主な特性:

- **コンソールは `Write-Host -ForegroundColor` による色装飾を維持** — レガシーな `*>&1 | Tee-Object -FilePath …` イディオムは Write-Host の色情報がパイプ経由で削除されますが、 `-LogFile` ではそれが起きません。
- **ファイル側は全ストリーム (Output / Host / Error / Warning / Verbose / Debug) を UTF-8 プレーンテキストで受信**。
- **親ディレクトリは自動作成** (例: `C:\Temp\` がない場合は作成されます)。
- **Append モード** (`-Append -Force`) — 連続再実行はファイルに追記されます (truncate されません)。
- **クリーンアップは冪等** — `Stop-Transcript` は最上位の `finally` block と `PowerShell.Exiting` engine event handler の両方から呼ばれます。
- **`-WorkRoot` 内の operator 指定パス + `-CleanWorkRoot`** — 明示的な `-LogFile` パスには従来どおり退避ガードが適用されます (トランスクリプトはスクリプト隣へ移動され、 wipe で削除されない)。 WorkRoot 内 suspend/wipe/resume フローを使うのは自動生成トランスクリプトのみです。

明示的な `-LogFile` で **上書きする場合の** 推奨ファイル命名規則:

```
C:\Temp\<scripttag>_<Action>_<yyyyMMdd-HHmmss>.log
```

例:

| スクリプト | 推奨ファイル名                                                 |
| ---------- | -------------------------------------------------------------- |
| Chipset    | `C:\Temp\amd-chipset_PrepareVerify_20260517-143022.log`        |
| Graphics   | `C:\Temp\amd-graphics_Install_20260517-143022.log`             |
| NPU        | `C:\Temp\amd-npu_All_20260517-143022.log`                      |
| BthPan     | `C:\Temp\ms-bthpan_PrepareVerify_20260517-143022.log`          |

### レガシー fallback (`Tee-Object`)

レガシーな `*>&1 | Tee-Object` イディオムも引き続きサポートされており、 ログファイルを後段のツールにパイプで渡したい場合に有用です。 ただし **Write-Host の色情報はストリップされる** ことに注意 (PowerShell のパイプラインは host stream の色情報を伝搬しません):

```powershell
.\Deploy-AMDChipsetDriverOnWindowsServer.ps1 -Action Install *>&1 |
    Tee-Object -FilePath "C:\Temp\amd-chipset_Install_$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
```

ja-JP host でデフォルトのコードページ (932 / Shift-JIS) のまま `-LogFile` あるいは `Tee-Object` で出力をファイルへリダイレクトする場合は、 ファイルエンコーディングを明示的に UTF-8 として扱ってください (二重エンコーディング防止)。 スクリプトは P00 で `Set-Utf8PipelineEncoding` を呼び出して `[Console]::OutputEncoding` を UTF-8 に強制しますが、 キャプチャされたファイルを読むツール (テキストエディタ、 `Get-Content` 等) 側でも UTF-8 として認識させる必要があります。

---

### コンソール QuickEdit ガード・readiness 判定・run-artifact アーカイブ (r92+)

実運用レポートに基づく 3 つの堅牢化が 4 スクリプト共通で追加されました:

- **コンソール QuickEdit ガード。** Windows Server のコンソールはデフォルトで QuickEdit モードが有効で、 誤ったクリックドラッグによるテキスト選択が **すべてのコンソール出力をブロック** します — スクリプトはフェーズ途中でハングしたように見えます (実測 18m37s の凍結事例あり。 SPEC D.38 参照)。 選択 (マーク) モード中の Ctrl-C は *コピー* であり break ではないため、 凍結が解除されて実行はそのまま継続します。 r92+ では実行中 `ENABLE_QUICK_EDIT_MODE` を一時的に無効化し、 終了時に元のコンソールモードへ復元します (ConsoleHost のみ。 全工程 try/catch 内包。 スイッチなし)。
- **Install readiness 判定。** RUN SUMMARY の末尾に、 フェーズごとの status から導出した明示的な `Install readiness : READY - no failed phases.` / `REVIEW REQUIRED - failed: <ids>` 行と、 「`[!]` 行は設計上の情報通知 (パッチ前ソース INF の baseline 測定、 文書化済みツールフォールバック、 I01 前の untrusted-root、 デバイス不在など) である」 旨の注記が出力されます。 実際の失敗はタイミングテーブル上で該当フェーズが `failed` になります。
- **Run-artifact アーカイブ。** サマリ出力とトランスクリプト停止の後、 各実行は `logs\`・`patched\`・`cert\` (公開素材のみ)・`secureboot_ms_sample\`・`inf_inventory.csv` を `<ScriptName>_<Action>_run-artifacts_<yyyyMMdd-HHmmss>_<PID>.zip` に束ね、 **スクリプトと同じフォルダ** に zip をコピーします — 解析用にファイル 1 個を受け渡せます。 **`*.pfx` (秘密鍵) は決して含まれません**。 巨大な `download\` / `extracted\` ツリーと 50 MB 超のファイルも除外されます。 スクリプトフォルダが書き込み不可の場合は WorkRoot 直下 (さらに失敗時は `%TEMP%`) へフォールバックします。 `logs\run-artifact-archive-plan.txt` マーカーが zip 名をアーカイブ自身の中に記録します。 `Cleanup` 実行時 (ワークスペース消去済み) はアーカイブをスキップします。


### 構成情報エビデンス・コレクタ (r93+)

`Collect-WindowsServerConfigurationEvidence.ps1` は、 4 つのデプロイスクリプトが操作対象とする Windows Server の構成領域を **読み取り専用** で採取する単体実行可能な随伴スクリプトです。 タイムスタンプ付きエビデンスディレクトリ + ZIP を生成し、 色付きの PASS / FAIL / REVIEW / INFO 評価レポートを出力します (exit code: 0 = すべて PASS/INFO、 2 = FAIL/REVIEW あり、 1 = 致命エラー)。 iso プロジェクトの post-install コレクタの仕様・設計をベースにしています。

採取領域: OS 識別 (build/UBR)、 pending reboot 状態 (advisory / blocking 分類)、 PnP インベントリ (問題デバイス + AMD/BthPan 対象ファミリ含む)、 ドライバストア (`pnputil /enum-drivers` + `Win32_PnPSignedDriver`)、 Root / TrustedPublisher のプロジェクト自己署名証明書 (**公開プロパティのみ — 秘密鍵は決して読み取りません**)、 ブートセキュリティ (Secure Boot、 UEFI CA 2023 servicing 状態、 testsigning/nointegritychecks、 HVCI、 WDAC `SiPolicy.p7b`、 `CiTool -lp`)、 直近の CodeIntegrity イベント、 `setupapi` ログ (50 MB 上限。 `-SkipSetupApiLog` でスキップ可)、 リポジトリスクリプト目録 (版数 + SHA-256)、 WorkRoot / run-artifact 目録 (名前のみ)。

単体でいつでも実行できます:

```powershell
.\Collect-WindowsServerConfigurationEvidence.ps1
```

r94 以降、 デプロイスクリプトは **すべての実行で pre/post のエビデンスペアを自動採取** します (`ListPhases` を除く) — stage `pre` は最初のフェーズの前、 stage `post` は run-artifact アーカイブ後の実行最終ステップで走り、 stage と呼び出し元スクリプトが ZIP 名に埋め込まれるためペアを diff 比較できます。 採取を止める場合のみ `-SkipEvidenceCollection` を指定してください (r93 では一時的にオプトインの `-CollectEvidence` でしたが、 r94 で極性を反転しました):

```powershell
.\Deploy-AMDChipsetDriverOnWindowsServer.ps1 -Action PrepareVerify -CleanWorkRoot                         # エビデンスペアは自動採取
.\Deploy-AMDChipsetDriverOnWindowsServer.ps1 -Action PrepareVerify -CleanWorkRoot -SkipEvidenceCollection # 採取をスキップ
```

コレクタ側の問題 (ファイル不在・非ゼロ exit・エラー) は警告として報告されるのみで、 デプロイ実行には決して影響しません。 `-OutputRoot` はスクリプトフォルダ (デフォルト) または `C:\Temp` のみ許可されます。


## システム要件

- **CPU**: AMD Ryzen 4000 シリーズ以降 (スクリプトの `Get-AmdChipsetPlatform` heuristic は 4000 → AI 300、AI Max 300 を認識します。それより古い silicon でも動作はしますが未検証)。NPU スクリプト用には Ryzen 7040 / 8040 / AI 300 / AI Max 300 / AI 200 シリーズ (NPU 内蔵) が必要。
- **OS**: Windows Server 2025 (build 26100) が production target。Windows 11 24H2 (build 26100) は *preview* host として対応 ([TESTING.md](./TESTING.md) 参照)。Windows Server 2016 / 2019 / 2022 は OS profile matrix で認識され、inf2cat も対応する `/os:` switch (`Server2016_X64`、`ServerRS5_X64`、`ServerFE_X64`) を選択しますが、これらバージョンでの production 利用は本 README の対象外です。
- **PowerShell**: 5.1 (Windows PowerShell Desktop) または 7.x (PowerShell Core)。スクリプトの `Show-PowerShellEnvironment` phase が認識する互換性 matrix を表示します。
- **ディスク**: ワークスペースボリュームに約 5 GB (NPU スクリプトを併用する場合は約 7 GB)。
- **ネットワーク**: `*.amd.com`、`download.microsoft.com`、`go.microsoft.com`、`aka.ms` (winget)、`timestamp.digicert.com` (署名タイムスタンプ) への outbound HTTPS。NPU スクリプトの Tier 2 を使う場合はさらに `account.amd.com` および `*.entitlenow.com`。
- **権限**: ローカル管理者。ドメイン権限不要。

---

## 自己署名証明書: 有効期限・更新・失効

P07 で生成される証明書は本パイプラインで install する全ドライバの **trust anchor** です。専用セクションで詳しく説明します。

### 証明書のプロパティ

- **Subject**:
  - `CN=AMD Chipset Driver Self-Sign (WS2025 Lab, At Own Risk)` (chipset)
  - `CN=AMD Graphics Driver Self-Sign (WS2025 Lab, At Own Risk)` (graphics)
  - `CN=AMD NPU Driver Self-Sign (WS2025 Lab, At Own Risk)` (NPU)
- **鍵**: RSA 4096-bit、SHA-384 署名アルゴリズム。
- **EKU**: Code Signing (`1.3.6.1.5.5.7.3.3`)。
- **有効期間**: **P07 実行日から 5 年**。スクリプトでハードコードされています。
- **保管場所**: PFX を `C:\AMD-{Chipset,Graphics,NPU}-WS\cert\` に保存。 Chipset / Graphics / BthPan では `-PfxPassword` 未指定時に**実行ごとのランダム 32 文字 CSPRNG パスワード**が使われ (W4)、 エクスポートされた PFX は Administrators+SYSTEM に ACL 限定・**Install 完了後に削除**されます (証明書はストアに残り、 P07 が必要時に再生成)。 NPU スクリプトには空文字列既定と既知リテラルの export 分岐が残っています — 未解決、 監査 H-05R (W7 予定)。 本文書の以前の版は「PFX はパスワード保護されていない」と記述しており、 コードと矛盾していました。 ここに是正します (監査 L-01)。
- **trust anchor の対象**: `patched\` 配下の全 `.cat` ファイル、WDAC supplemental policy、(I01 経由で) `LocalMachine\Root` + `LocalMachine\TrustedPublisher`。

### 5 年経過後の挙動

証明書が失効すると:

- `.cat` ファイルに埋め込まれた catalog 署名は **失効前にインストールされたファイルに対しては有効なまま**です。これは Windows が署名タイムスタンプ (証明書が有効だった時点で署名されたことの証明) をチェックするためで、boot 時点での証明書の有効性ではありません。WHQL 署名されたドライバが AMD / Microsoft の署名証明書 rotate 後も動作し続けるのと同じ仕組みです。
- ただし、**失効した証明書で新しいパッチ済みドライバを `pnputil /add-driver` で追加することは失敗**します。
- **本スクリプトを再実行することがリカバリパス**です。新しい証明書 (異なる thumbprint、同じ subject) を生成し、catalog を再署名し、新証明書を import します。既にインストール済みのドライバはそのまま動作し続けます。

### 更新手順 (5 年ごと、もしくは漏洩が疑われる場合は即座)

```powershell
# 1. 証明書を rotate して再署名
.\Deploy-AMDChipsetDriverOnWindowsServer.ps1  -Action Prepare -OnlyPhases P07,P08,P09
.\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Action Prepare -OnlyPhases P07,P08,P09
.\Deploy-AMDNpuDriverOnWindowsServer.ps1      -Action Prepare -OnlyPhases P07,P08,P09

# 2. 新証明書を信頼 (古い証明書は明示的に削除するまで信頼されたまま)
.\Deploy-AMDChipsetDriverOnWindowsServer.ps1  -Action Install -OnlyPhases I01,I02
.\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Action Install -OnlyPhases I01,I02
.\Deploy-AMDNpuDriverOnWindowsServer.ps1      -Action Install -OnlyPhases I01,I02

# 3. 再署名されたドライバを driver store に追加 (既存デバイスを新署名にバインド)
.\Deploy-AMDChipsetDriverOnWindowsServer.ps1  -Action Install -OnlyPhases I03
.\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Action Install -OnlyPhases I03
.\Deploy-AMDNpuDriverOnWindowsServer.ps1      -Action Install -OnlyPhases I03

# 4. 必要に応じて旧証明書を削除
$old = '前回の-OLD-THUMBPRINT'
Get-ChildItem 'Cert:\LocalMachine\Root', 'Cert:\LocalMachine\TrustedPublisher' |
  Where-Object Thumbprint -EQ $old | Remove-Item
```

### 証明書の失効

PFX が漏洩した疑いがある場合、即座に:

```powershell
# 1. Cleanup — trust store から証明書削除、WDAC policy 削除、ドライバ削除
.\Deploy-AMDChipsetDriverOnWindowsServer.ps1  -Action Cleanup
.\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Action Cleanup
.\Deploy-AMDNpuDriverOnWindowsServer.ps1      -Action Cleanup

# 2. 再起動して WDAC policy unload を確実にする (スクリプトは CiTool --refresh を試みますが、
#    再起動することで kernel に署名権限の残存がないことを保証)
Restart-Computer
```

再起動後、フルパイプラインを再実行して新証明書を生成してください。

### なぜ 5 年? なぜ自己署名?

- **5 年** は Microsoft 自身の kernel-mode 署名証明書の有効期間上限と一致します (実際には 1〜3 年で rotate されますが、最大 5 年で発行)。月次で気にする必要がない程度には長く、漏洩時の影響範囲が無制限にならない程度には短い、という balance。
- **自己署名** にしている理由は、コンシューマー向けドライバを patch する個人の趣味活動に対してコード署名証明書を発行してくれる public CA は存在しないためです。Sectigo / DigiCert 等の EV Code Signing 証明書には法人確認 (年 $300〜600) が必要で、AMD の EULA に違反する可能性のある活動には発行されません。

これは *意図的に* lab ツールです。**本番環境で大規模に deploy する場合は、(a) AMD と直接交渉して Server 対応ドライバを得る、または (b) 適切に管理されたコード署名 CA を使う、のいずれかにすべきです。本自己署名モデルを使うべきではありません。**

---

## 免責事項・自己責任の確認

本スクリプトを実行することは、以下を理解し受諾することを意味します:

1. **無保証**。本スクリプトは MIT License の下で "as is" で提供されます。お使いのハードウェアでの動作、インストール環境への損傷の不在、将来の Windows update での継続サポート、いずれも保証されません。`LICENSE` を参照してください。

2. **発行元はあなた自身**。AMD の INF を patch して自己生成証明書で再署名することは、Windows から見て *AMD でも Microsoft でもなく、あなた自身* がそのドライバの暗号学的発行元になることを意味します。パッチ済みドライバが BSOD・システム不安定・データ損失を引き起こした場合、そのバグはあなたの自己署名証明書に attribute されます。AMD には attribute されません。

3. **AMD の End User License Agreement** はチップセット / グラフィックス / Ryzen AI installer の再配布を特定の条件下で許可しています。INF を編集して再署名する行為は grey area で、お使いの specific package の AMD EULA を読んだ上でご自身の判断を形成してください。**本リポジトリは、あなたの利用が AMD の terms 下で許可されるかについて何ら立場を取りません。** Ryzen AI に関しては、ダウンロード前に <https://account.amd.com/en/forms/downloads/ryzenai-eula-public-xef.html> で EULA 受諾が必須です。NPU スクリプトの I00 phase は明示的な `I AGREE` 確認入力を要求し、この受諾が完了していることを確認します。

4. **Microsoft の Windows Hardware Lab Kit (HLK) 認証は無効化されます**。本パイプラインで置換する全ドライバについて。WHQL 署名ドライバは Microsoft が HLK 通過を attest していますが、自己署名ドライバはそうではありません。当該ハードウェアについて Microsoft Premier Support に依存している場合、自己署名ドライバが原因の問題はサポート契約の対象外になる可能性があります。

5. **BitLocker / TPM / Secure Boot との相互作用**。チップセットスクリプトの PSP ドライバ置換 (`amdpsp.inf`) は Platform Security Processor firmware と相互作用します。BitLocker が有効な system では、PSP ドライバ更新の失敗が次回起動時の BitLocker recovery プロンプト発生を引き起こす可能性があります。**chipset スクリプトで `-Action Install` を実行する前に、必ず BitLocker recovery key を控えてください。**

6. **Anti-cheat ソフトウェア** (Easy Anti-Cheat、BattlEye、Vanguard 等) は自己署名 kernel-mode ドライバを flag する可能性があります。本パイプラインは競技性のあるゲームタイトルでのゲーミングワークロードを想定しておらず、当該用途で利用するとアカウント BAN の可能性があります。

7. **5 年の証明書有効期限は実際に到来します**。production deploy をする場合は 4.5 年目に renewal タスクをカレンダーに登録するか、5 年目以降ドライバインストールが停止することを受け入れてください。

8. **ドライバカテゴリ優先度オーバーライド (破壊的変更)**。 スクリプトのインストール判定ロジックは自己署名ドライバ ([C]) をハードウェアベンダードライバ ([B]) およびマイクロソフト汎用ドライバ ([A]) より優先しま す。ドライバのバージョン値に関係ありません。 クリーンインストール直後の WS2025 ではこれが意図した動作です — マイクロソフトの in-box 汎用ドライバはスクリプトの署名を持つ AMD ベンダードライバに置き換えられます。 トレードオフは、 Windows Update や OEM パッケージで既にインストール済みの AMD ベンダードライバ**も**、 スクリプトの自己署名版で上書きされる点です (バイナリは同じで、 発行者署名のみが異なります)。 ベンダードライバを保持したい場合は、 まず `-Action PrepareVerify` を実行し V06 Section 2 を確認した上で続行を判断してください。 詳細な理論的根拠は SPEC §D.15 を参照してください。

9. **NPU スクリプト (`Deploy-AMDNpuDriverOnWindowsServer.ps1`) は姉妹スクリプトと比較して明らかにリスクが高いです。** 具体的には:
   - **物理 NPU での検証は本ドキュメント執筆時点でメンテナーによって実施されていません。** 全ての検証は `psa.py` による静的解析と、AMD 公開の `quicktest.py` 検出ロジックを PowerShell に翻訳したコードのレビューに留まっています。
   - **AMD アカウント自動ダウンロード (Tier 2) は best-effort で予告なく破綻する可能性があります**。AMD は `account.amd.com` のフォーム構造、CSRF token 名、entitlenow.com CDN URL スキーム等を更新します。再現性のある実行は常に Tier 4 (`-OfflineZip`) を優先してください。
   - **Ryzen AI Software は AMD ドキュメント上 Windows 11 only です** (build >= 22621.3527)。Windows Server 2025 で NPU kernel driver が load しても、user-mode stack (Python conda env、ONNX Runtime VitisAI EP、OGA) は動作することが期待できません。**Server 2025 で AI 推論ワークロードを期待する環境では NPU スクリプトを deploy しないでください。**
   - **Driver store cleanup は best-effort です。** `-Action Install` 後の自己署名 NPU ドライバの driver store からの削除は、`pnputil /delete-driver oemNN.inf /force` の手動実行や Driver Store Explorer (Rapr.exe) の利用が必要となるケースがあります。

10. **本リポジトリで商用サポートは提供されません**。GitHub Issues (<https://github.com/usui-tk/Deploy-Drivers-For-WindowsServer/issues>) はバグ報告と説明要求の best-effort 対応です。Pull request は歓迎しますが、レビューのタイミングは保証されません。

---

## トラブルシューティング

### "OS detected: Windows Server 2025 (build 26100) [WS2025] but ProductType: 1"

Windows 11 24H2 上で実行しています (Win11 24H2 と Windows Server 2025 は NT build 26100 を共有)。スクリプトは意図的に Win11 24H2 を WS2025 profile にマップします (kernel ABI が同一のため)。Workstation OS では `Install` 系 phase がデフォルトでブロックされます。`-Action PrepareVerify` のみを使うか、本当に Win11 上で install したい場合のみ `-AllowWorkstationInstall` を指定してください (警告を先に読んでください)。事前検証 workflow は [TESTING.md](./TESTING.md) を参照してください。

### "P02 で WDK インストールに 2-3 分かかる"

Windows WDK のダウンロードサイズが約 2.5 GB です。マシンごとに一度だけのインストールで、以降の実行ではインストール済みの `inf2cat.exe` を再利用するため、P02 は 1 秒未満で完了します。

### 「Windows Server 2019 (Secure Boot ON) で I02 が PATH B PREREQUISITE NOT MET で中断する」

これは設計どおりのフェイルセーフ動作であり、 WS2019 ではツール追加による回避はできません: WDAC supplemental ポリシーのパスには Windows 10 1903 / build 18362 で導入された multiple-policy format が必要で、 WS2019 は 1809 / build 17763 のため、 CiTool 等を導入しても有効化できません (r95+ のバナーはこれを明示します)。 Secure Boot ON の状態では `bcdedit /set testsigning on` がファームウェアに拒否されるため、 レガシーパスも閉じています。 このホストでの選択肢は 2 つです: (a) ファームウェアで Secure Boot を無効化して `-UseTestSigning` で再実行 (Path B — 事前に BitLocker 回復キーを保存)、 または (b) Secure Boot ON のまま `-SkipNonCosignedDrivers` で再実行し WHQL co-sign 済みサブセットのみをインストール (Path A)。 SPEC D.39.4 参照。


### 「スクリプトがフェーズ途中でハングしたように見え、 Ctrl-C を押すと (停止せずに) 続行する」

それはハングではありません — コンソールが **QuickEdit の選択 (マーク) モード** に入っていました。 Windows のコンソール (Windows Server では QuickEdit がデフォルト ON) は、 テキスト選択中すべてのコンソール出力をブロックするため、 誤ったクリックドラッグで進捗表示が `Write-Host` の途中で止まります。 マークモード中の Ctrl-C は *コピー & 選択解除* であり、 実行を停止させずに凍結を解除します — これがこの障害クラスの診断的シグネチャです。 r92+ は実行中 QuickEdit を無効化し、 終了時に元のコンソールモードへ復元するため、 この現象は発生しなくなりました。 それ以前のリビジョンでは、 実行中にコンソールのテキスト選択を避けてください (またはアップグレード)。 完全なポストモーテム: SPEC D.38 (「7-Zip ハング」として報告された 18m37s の実測凍結事例)。

### 「[!] 警告がいくつか出たのに最終ステートは Done — このまま Install に進んで安全?」

はい — r92+ の RUN SUMMARY 末尾の `Install readiness` 行が `READY` であれば安全です。 `[!]` 行は設計上の情報通知です: ソース INF の baseline 測定 (*パッチ前* INF のエラーは意図した基準値)、 文書化済みのツールフォールバック (例: BthPan の `inf2cat` 22.9.8 拒否 → `makecat`)、 I01 で証明書をインポートする前の untrusted-root、 このホストに対象デバイスが物理的に存在しない場合 (Install はステージのみ) など。 **実際の** 失敗はタイミングテーブルで該当フェーズが `failed` になり、 判定が `REVIEW REQUIRED - failed: <ids>` に変わります。 この判定を導入した実地解析は SPEC D.38.4 を参照。


### "P03 が 'no AMD installer URL resolved' で失敗する"

AMD は support page を定期的に再構成します。スクリプトは 3〜6 個の候補 URL をプローブし、全てが 0 hits を返す場合は parser が壊れています。回避策:

- **2026-07 の AMD インストーラ改名**: AMD は新規公開の chipset インストーラを `amd_chipset_software_<version>.exe` から `amd_software_<version>.exe` へ改名しました。 r91+ は両方の名前を受理し、 全 probe が 0 件の際は取得済みランディングページを `logs\amd-landing-probe-*.html` として保存します。 それ以前のリビジョンは現行の AMD ページで 0 件になります — アップグレードするか、 下記の `-InstallerUrl` を使用してください。 SPEC D.37 参照。
- `-InstallerUrl https://drivers.amd.com/drivers/...` を渡して URL discovery を skip し、特定バージョンを直接ダウンロード。
- P03 出力の `Probe results:` ブロックを開き、各 URL を手動で訪問して AMD のサイト変更を確認。
- Issue を起票: <https://github.com/usui-tk/Deploy-Drivers-For-WindowsServer/issues>

### NPU スクリプト "All 4 download tiers exhausted"

NPU スクリプトで最も頻発する失敗ケースです。EULA-gated AMD フォームはスクリプトで完全にシミュレートできない認証付き AMD アカウントセッションを必要とします。優先度の高い順の回避策:

1. **手動ダウンロード**: <https://ryzenai.docs.amd.com/en/latest/inst.html#install-npu-drivers> から ZIP を取得、スクリプト隣に配置、`-OfflineZip .\NPU_RAI*.zip` で再実行。
2. **`-AmdAccountUser` / `-AmdAccountPassword` を試す**: ただし破綻が予想されます。AMD のフォーム構造変更は告知されません。
3. **手動 EULA 受諾後にブラウザで entitlenow.com URL を捕捉**し、`-InstallerUrl <captured-url>` で渡す。URL に時間制限のある hash が含まれているため、捕捉直後に即時実行してください。

### NPU スクリプト "No AMD NPU detected via pnputil"

ホストに AMD NPU デバイスが存在しません。次のいずれかです:

- 想定通り (NPU 不在ホストでのパイプライン健全性チェック実行): `-AssumeIfMissing` で default Strix Point + RAI 1.7.1 profile に進めます。
- 想定外 (Ryzen AI マシンを所有しているはず): Device Manager で unbound PCI デバイスを確認、Task Manager → Performance に NPU0 エントリがあるか確認、BIOS で NPU が disabled になっていないか確認。

### "V06 で MS-GENERIC ドライバの AMD ハードウェアがパッチ済み INF でカバーされない"

CPU core (`cpu.inf`)、PCI Express ルートポート (`pci.inf`)、ホスト CPU ブリッジ (`machine.inf`)、USB xHCI (`usbxhci.inf`)、HD Audio コントローラー (`hdaudbus.inf`) は **全て Microsoft 汎用ドライバのまま残ることが想定済み**です。これらに対して AMD はベンダードライバを提供していません (core OS subsystem が enumerate するため)。V06 セクション 1 の "ALERT" メッセージは情報提供であってエラーではありません。

### "I02 で WDAC policy が deploy されたが新ドライバが load されない"

`eventvwr` → `アプリケーションとサービスログ` → `Microsoft` → `Windows` → `CodeIntegrity` → `Operational` で event 3076 / 3077 / 3091 を確認してください。block された署名の Issuer / Subject / Thumbprint がご自身の自己署名証明書と一致するはずです。一致しない場合、WDAC policy が正しく deploy されていません。`CiTool -lp` で active policy を listing して確認してください。

### "AMD ドライバが install されたのに Device Manager にはまだ MS 汎用が表示される"

`pnputil /scan-devices` で再 enumeration を強制してください。それでも MS にバインドされたままであれば、パッチ済み INF の HWID がデバイスの PNP ID と完全一致していない可能性があります。V06 セクション 2 ("WILL be replaced" / "have no patched INF") を確認してください。デバイスが後者のカテゴリに入る場合、パッチ済みドライバが当該 HWID を claim していないということで、これは一部のデバイス (USB hub、汎用 xHCI controller 等) では想定通りの挙動です。

### "I02 で 'Converting XML to .cip binary...' から 'Deployed:' まで 60 秒以上 hang する"

**過去の不具合 (現在の main では修正済み)。** CiTool.exe を `--json` フラグなしで呼び出していたため、 console に「続行するには、 Enter キーを押してください」を表示して stdin 入力を待ち、 script が hang していました。 active console window で ENTER を押下すると進行を再開します。 これはすべての CiTool.exe 呼び出しに `--json` を付与することで修正済みです。 これは Microsoft の CiTool 設計における正規の非対話モードフラグで、 ヘルプ出力にも「出力を json として書式設定し、 入力を抑制する」と明記されています。 スクリプトをアップグレードすれば hang は発生しなくなります。 根本原因の解析と検証は SPEC §D.16 を参照してください。

### "CiTool ログ行が '蜃ｦ逅・・謌仙粥縺励∪縺励◆' のような文字化けで表示される"

**過去の不具合 (現在の main では修正済み)。** これは「処理が成功しました」 という UTF-8 バイト列を cp932 (Shift-JIS) として解釈した結果の文字化けです。 CiTool.exe は stdout に UTF-8 を書きますが、 PowerShell はそれを ja-JP の規定値である `[Console]::OutputEncoding` (cp932) でデコードしてしまいました。 SPEC §A.5 / §D.5 では P00 での UTF-8 強制が規定されていましたが、 実装が抜けていました。 P00 内の `Set-ConsoleUtf8` で修正されています。 詳細は SPEC §D.16 を参照してください。

### "同一の Install 実行で I03 が '3 failed' と報告するが I04 では 'Failed: 0' になる"

**過去の不具合 (現在の main では修正済み)。** I03 の分類ロジックは pnputil `exit=259` (`ERROR_NO_MORE_ITEMS`) を failure として扱っていましたが、 I04 PostInstallVerification は実際のデバイス状態を読んで、 これらを `REBOOT_NEEDED` (同じ INF を別パスから呼び出した最初の install で binding が既に queue されている場合) または no-op (ドライバパッケージが driver store に既に存在) として正しく識別していました。 exit=259 のケースは、 通常は重複ソースの INF (例: `Chipset_Software\SMBus Driver\W11x64\SMBUSamd.inf` と `SMBus Driver\W11x64\SMBUSamd.inf` の両方を I03 が呼び出し、 2 回目で 259 が返る) によるものです。 現在の I03 サマリーは `ok` / `need reboot` / `no-op` / `failed` の 4 カテゴリを報告し、 exit=259 は `no-op (already present)` ステータス (Write-Skip / DarkGray) にマップされます。 詳細は SPEC §D.17 を参照してください。

### NPU スクリプト "I04 でデバイスは bind されたが Ryzen AI Software が initialize しない"

これは Windows Server 2025 上での想定通りの挙動です。kernel-mode driver は load しますが、Ryzen AI Software user-mode stack (Python conda env、ONNX Runtime VitisAI EP、OGA) は AMD 公式に Windows 11 only です。Server 2025 上で AI ワークロード機能性を期待しないでください。次のいずれかにしてください:

- 実際の NPU 推論ワークロードには Windows 11 24H2 を使用する。
- Server 2025 への install は kernel driver bring-up のみと位置付ける (lab / 研究)。

### Chipset スクリプト "P08 で CIR Driver フォルダ (もしくは他の INF フォルダ) が '1 failed' と報告される"

**Chipset r66 以降の mainline では自動的に処理されます。** AMD Chipset Software パッケージは、ごく稀に `[SourceDisksFiles]` で参照しているファイルが sub-MSI の cabinet に同梱されていない INF を出荷することがあります。最も再現性の高いケースは Chipset 8.05.04.516 + Renoir + WS2019 における `AmdAppCompat.inf`、`AmdAS4.inf`、`AMDCIR.inf`、`usbfilter.inf` で、いずれも `[SourceDisksFiles]` で宣言されたファイルが sub-MSI cabinet に同梱されていません。このため `inf2cat.exe` が error 22.9.1 ("driver package is missing some files") を出して P08 で失敗していました。上流の原因は sub-MSI の `msiexec /a` ログに見える `SECREPAIR Error: 3` cascade です。

r65 では本欠陥を P05 で検出する仕組みを導入しました (新規ヘルパー `Get-InfReferencedFile` が、すべての patched INF の `[SourceDisksFiles]` を P04 で実際に展開されたファイルと突き合わせます)。結果は `inf_inventory.csv` の新規列 `EligibleForCatalog` に記録され、P06 / P08 / V03 / V04 / V05 / V06 / I03 へ skip 状態が伝播されます。期待される P08 のサマリーは tri-state 形式 (`N ok / 0 failed / K skipped`) となります。

r66 では r65 で残っていた後続の不具合を解消しました。すなわち、P06 が ineligible INF のディレクトリを丸ごとコピーする際に AMD オリジナルの `.cat` ファイルも持ち込んでしまい、P09 がそれを自己署名で再署名していた問題です。r66 では二層の防御を追加しています — P08 が skip 対象ディレクトリの orphan `.cat` を削除し、P09 がさらに ineligible ディレクトリ配下の `.cat` を filter します。結果として V01 の `Catalog files: N` 表示が P08 の `N ok` とぴったり一致し、orphan catalog が `patched/` に残らず、`-OnlyPhases P09` で workspace を再利用しても安全です。

詳細な根本原因解析と二層防御設計は [SPEC §D.24](./SPEC.md)、実装ノートは [CHANGELOG.md](./CHANGELOG.md) の r65 (detect-and-skip) および r66 (orphan cleanup) エントリを参照してください。`submsi-failures-diag.txt` のパターン頻度集計でも、当該 1603 群は `SECREPAIR missing source files` として正しく分類されます (SPEC §D.21)。

r66 以降でなお P08 が fail する場合は、影響を受けている INF が別の failure mode を示している可能性があります。INF 名と `[P08]` コンソールブロック全文を添えて Issue を起票してください。

---

## 開発ツール

### `psa.py` — PowerShell 静的解析ツール

PowerShell パイプラインスクリプトの検証に利用する PowerShell 静的解析ツール `psa.py` は、 **単一の正本 (canonical artifact)** として別レポジトリ [`usui-tk/ai-generated-artifacts`](https://github.com/usui-tk/ai-generated-artifacts) の [`quality-tools/powershell-static-analyzer/`](https://github.com/usui-tk/ai-generated-artifacts/tree/main/quality-tools/powershell-static-analyzer) で管理しています。 本レポジトリにはローカルコピーを同梱**していません**。 利用前に以下のいずれかの方法で `psa.py` を取得してください。

PowerShell の通常 parser では検出しにくい誤りをチェックする、シングルファイルの Python 3 静的解析ツールです。

#### `psa.py` の取得方法

**方法 1 — 正本レポジトリを clone する (継続的な開発で推奨)**

```bash
# 本レポジトリと並列のディレクトリに clone
git clone https://github.com/usui-tk/ai-generated-artifacts.git ../ai-generated-artifacts

# 本レポジトリのルートから実行
python3 ../ai-generated-artifacts/quality-tools/powershell-static-analyzer/psa.py Deploy-AMDChipsetDriverOnWindowsServer.ps1
python3 ../ai-generated-artifacts/quality-tools/powershell-static-analyzer/psa.py Deploy-AMDGraphicsDriverOnWindowsServer.ps1
python3 ../ai-generated-artifacts/quality-tools/powershell-static-analyzer/psa.py Deploy-AMDNpuDriverOnWindowsServer.ps1
```

**方法 2 — 単一ファイルをダウンロードする (one-shot な CI 実行で推奨)**

Linux / macOS (curl):

```bash
curl -sSLO https://raw.githubusercontent.com/usui-tk/ai-generated-artifacts/main/quality-tools/powershell-static-analyzer/psa.py
python3 psa.py Deploy-AMDChipsetDriverOnWindowsServer.ps1
python3 psa.py Deploy-AMDGraphicsDriverOnWindowsServer.ps1
python3 psa.py Deploy-AMDNpuDriverOnWindowsServer.ps1
```

Windows PowerShell (Invoke-WebRequest):

```powershell
Invoke-WebRequest `
    -Uri  "https://raw.githubusercontent.com/usui-tk/ai-generated-artifacts/main/quality-tools/powershell-static-analyzer/psa.py" `
    -OutFile psa.py
python3 psa.py Deploy-AMDChipsetDriverOnWindowsServer.ps1
python3 psa.py Deploy-AMDGraphicsDriverOnWindowsServer.ps1
python3 psa.py Deploy-AMDNpuDriverOnWindowsServer.ps1
```

本ドキュメントおよび `SPEC.md` / `TESTING.md` / `CONTRIBUTING.md` における `python3 psa.py <script>.ps1` 形式のコマンドは、 上記の方法 1 もしくは方法 2 で `psa.py` を取得済みで、 任意のパスからアクセス可能であることを前提としています。

#### 実施チェック

`psa.py` (latest mainline) は `PSA1xxx`〜`PSA9xxx` の汎用ルールに加え、 プロジェクト・パイプライン規約ルール `PSAP0xxx` を含むチェックセットを実装しています。 正確なルール数は upstream で新たな欠陥クラスが productionise されるたびに増加するため、 ここではファミリーと近年の追加分を列挙する形にし、 ルールが追加されるたびにドキュメントツリー全体の書き換えが必要にならないようにしています。 直近の追加:

- **`PSA7003` (`psa.py` 4.2.0 で追加、 非 ASCII スクリプト本体)** — `.ps1` 本体に BOM 以外の非 ASCII 文字 (em / en ダッシュ、 スマートクォート、 section 記号、 三点リーダー、 no-break space 等、 ASCII-only の CI ゲートが弾くソース書式上の欠陥クラス) が含まれると報告する default-on の **warning**。 **本レポジトリは `PSA7003` を意図的に opt-out** しています (`.psa.config.json` で無効化): AMD-family スクリプトはコンソール出力に意図的な日本語ログ文字列と em-dash を埋め込んでいるため、 ここでは非 ASCII 本体は欠陥ではなく想定どおりです。 詳細は `SPEC.md` §A.11.5 を参照。
- **`PSA1004` / `PSA2012` / `PSA2013` (`psa.py` 4.1.0 で追加)** — error severity / default-on の 3 件の静的チェック。 bare `(if/switch/foreach/while/...)` を式として使用するパターン (PSA1004、 PowerShell が `if` というコマンドの呼び出しとしてパースし実行時に失敗)、 `[Parameter(Mandatory)]` N 個の関数を N 個未満の positional 引数で呼び出して unattended セッションが stdin 待ちでハングするパターン (PSA2012)、 `$Script:Foo` を読んでいるがスクリプト全体に代入が無く `$null` として静かに評価されるパターン (PSA2013) を検出。 本レポジトリの 4 スクリプトは r81 / r47 / r29 / r25 ベースライン (`psa-py-v410-three-new-error-rules-baseline`) で全 3 ルールに対して 0 件です。
- **`PSAP0005` (`psa.py` 4.0.0 で追加、 LLM 支援メンテナンスガードレール)** — `PSAP0003` の構造化タグ形式よりも広く、 コメント本体内の任意の `rNN` 参照を検出。 本レポジトリでは Chipset r80 / Graphics r46 / BthPan r28 / NPU r24 リリース (`psa-py-v4-llm-governance-strict`) 以降、 デフォルトの **strict モード**で運用しており、 r76 で採用していた `psap0005_relaxed_mode: true` の移行ベースラインは廃止 (該当キーは `.psa.config.json` から削除済み) です (SPEC §A.13 *Migration roadmap* は `COMPLETED` ステータス、 §D.34 が retrospective)。
- **`PSA2009` (3.8.0 で追加)** — Japanese-locale Windows Server 2019 で発生した `Chipset r72 P05 -> FAILED with "WhqlCoSignAnalysis" property-not-found exception` の静的解析対応ゲート。
- **`PSA2010` / `PSA2011` (3.9.0 で追加)** — r75 §D.33 Defect A (`Split-Path` binder バグ) と §D.32.2 の `Find-Signtool` typo 系統を静的解析時点で捕捉。

PSA2009 / PSA2010 / PSA2011 / PSA1004+2012+2013 のレポジトリ側コメンタリーについては `SPEC.md` §A.11.5c / §A.11.5d / §A.11.5e / §A.11.5f を、 PSAP0005 のレポジトリ側ポリシーについては `SPEC.md` §A.13 を参照してください。 本レポジトリは latest mainline の `psa.py` に対して検証する方針です (特定バージョンへの固定はしません)。 方針の根拠と「新しい `psa.py` への追従」 LLM / AI ワークフローについては `SPEC.md` §A.11 *Version policy* を参照してください。 ルールは以下 10 カテゴリに分類されます:

| カテゴリ                                | コード範囲                | 例                                                                                                                                                                                                                                              |
| --------------------------------------- | ------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 構文の整合性                            | `PSA1001`〜`PSA1004`      | 中括弧 / 丸括弧 / 角括弧のバランス、 bare `(if/switch/foreach/while/...)` を式として使用 (`PSA1004`, 4.1.0 新規)                                                                                                                                |
| 意味解析                                | `PSA2001`〜`PSA2013`      | 未定義変数、 自動変数の shadowing、 bare `$variable` に対する `-match`、 `$null` を `-eq`/`-ne` の右辺に置く問題、 条件式内の代入 / リダイレクト、 パラメーター名が自動変数を shadow (`PSA2007`)、 `$Script:Foo++` の初期化忘れ (`PSA2008`)、 PSCustomObject プロパティを `[pscustomobject]@{...}` イニシャライザに宣言せずに代入 (`PSA2009`)、 未定義関数の呼び出し (`PSA2010`, error)、 PS 5.1 ja-JP で `Split-Path -LiteralPath ... -Parent` が AmbiguousParameterSet 発生 (`PSA2011`, error)、 `[Parameter(Mandatory)]` パラメータが N 個ある関数を N 個未満で positional 呼び出し (`PSA2012`, error, 4.1.0 新規)、 `$Script:Foo` を読んでいるがスクリプト全体に代入が無い (`PSA2013`, error, 4.1.0 新規) |
| コーディングパターン                    | `PSA3001`〜`PSA3006`      | `Start-Process -ArgumentList`、 空行直前の trailing backtick、 空文字列に対する `-match`、 空 `catch` ブロック、 `Start-Transcript -Path` ではなく `-LiteralPath` を使うべき、 `Get-WmiObject` / `Invoke-WmiMethod` 等 (CIM コマンドレット推奨) |
| 衛生                                    | `PSA4001`〜`PSA4004`      | 未完了マーカー (TODO / FIXME / XXX / HACK)、 行末空白、 長い行、 行末セミコロン                                                                                                                                                                 |
| セキュリティ                            | `PSA5001`〜`PSA5004`      | 平文パスワードパラメーター、 `Invoke-Expression`、 壊れたハッシュアルゴリズム、 `ComputerName` ハードコード                                                                                                                                     |
| ベストプラクティス                      | `PSA6001`〜`PSA6008`      | 非承認動詞、 コマンドレットエイリアス、 複数形名詞の関数名、 `$global:` 定義、 必須パラメーターのデフォルト値、 `$true` がデフォルトのスイッチパラメーター、 `[OutputType()]` 宣言の欠落、 属性付き関数で `param()` ブロックの省略                |
| ファイルフォーマット                    | `PSA7001`〜`PSA7002`      | `.ps1` の UTF-8 BOM 欠落 (BOM が無いと Windows PowerShell 5.1 ja-JP は Shift-JIS / cp932 にフォールバック)、 LF-only / 混在行末コード                                                                                                            |
| ファイル間整合性                        | `PSA8001`                 | 同一スキャン対象内における function body のハッシュ drift 検出 — 共有ヘルパー関数 (`Format-Elapsed`、 `Write-Detail`、 `Start-DebugTrace` ファミリ等) が 4 つのパイプラインスクリプト間で byte レベルで同期しつづけることを enforce              |
| 複雑度メトリクス                        | `PSA9001`〜`PSA9002`      | 関数行数の閾値超過 (デフォルト OFF、 `max_function_lines` で調整可)、 `$LASTEXITCODE` チェック無しの外部プロセス呼出し (デフォルト OFF)                                                                                                          |
| プロジェクト・パイプライン規約          | `PSAP0001`〜`PSAP0005`    | phase 関数命名規約 (`Invoke-(Prep\|Verify\|Inst)PhaseNN_Name`)、 必須スクリプト識別子変数 (`$Script:ScriptVersion` / `$Script:ScriptHash` / `$Script:ScriptShortTag`)、 **3.3.0 新規:** インライン `# rNN:` リビジョンタグコメント (`PSAP0003`)、 ファイル末尾の `REVISION HISTORY` ブロック (`PSAP0004`)、 **4.0.0 新規:** `PSAP0003` の構造化タグ形式よりも広い、 コメント本体内の任意の `rNN` 参照 (`PSAP0005`、 本レポジトリでは strict モードで運用)。 **PSAPxxxx ルールはすべてデフォルト OFF**; 本レポジトリは `.psa.config.json` で 5 つすべてに opt-in |

各ルールの正規仕様は、[ai-generated-artifacts](https://github.com/usui-tk/ai-generated-artifacts) レポジトリの [`quality-tools/powershell-static-analyzer/SPEC.md`](https://github.com/usui-tk/ai-generated-artifacts/blob/main/quality-tools/powershell-static-analyzer/SPEC.md) §4 (英語のみ) を参照。

#### 本レポジトリ専用の `.psa.config.json`

本レポジトリではルート直下に専用の `.psa.config.json` を同梱しています。 これは **4 つのパイプラインスクリプトに対する正規の設定** であり、 以下 3 点を実施します:

1. **`PSAP0001` / `PSAP0002` / `PSAP0003` / `PSAP0004` / `PSAP0005` を opt-in**。 21 phase 命名規約 (`Invoke-(Prep|Verify|Inst)PhaseNN_DescriptiveName`)、 スクリプト識別子の三連 (`$Script:ScriptVersion` / `ScriptHash` / `ScriptShortTag`)、 およびリビジョン規律 (`PSAP0003` でインライン `# rNN:` タグを禁止、 `PSAP0004` でスクリプト内 `REVISION HISTORY` ブロックを禁止、 `PSAP0005` strict モードでコメント本体内の `rNN` 記述プローズを禁止 — リビジョン履歴は `CHANGELOG.md` に、 設計の論拠は `SPEC.md` Part D に集約) のすべてを強制。

2. **`PSA8001` (ファイル間 function body drift) の設定**。 `psa8001_ignore_functions` でスクリプト固有な関数 (phase 関数 (regex 一括)、 各ドライバファミリ固有のヘルパー、 `Show-Help` 等) 約 45 個を除外。 ここに記載されていない共有ヘルパーは 4 スクリプト間で byte 一致が必須。

3. **`PSA4003` (長い行) を無効化**。 パイプラインスクリプトは意図的に多句 `-f` フォーマット文字列 (Show-PowerShellEnvironment テーブル、 デバイス別 AS-IS / TO-BE 解析テーブル) を使用しており、 出力可読性のため 120 桁超過を許容しています。

4 つのスクリプトに対する正規の静的解析実行コマンドは下記のとおりです:

```bash
# レポジトリルートから (psa.py は方法 1 または 2 で取得済みであること)
python3 path/to/psa.py --config ./.psa.config.json \
    Deploy-AMDChipsetDriverOnWindowsServer.ps1 \
    Deploy-AMDGraphicsDriverOnWindowsServer.ps1 \
    Deploy-AMDNpuDriverOnWindowsServer.ps1 \
    Deploy-MSBthPanInboxOnWindowsServer.ps1
```

PSA8001 のファイル間解析を動作させるため、 4 つのスクリプトはすべて単一の `psa.py` 呼出しで渡す必要があります (1 ファイルだけ渡しても、 比較対象のピアが居ないため PSA8001 は何も emit しません)。 現時点の検証済みベースラインは [`CHANGELOG.md`](./CHANGELOG.md) を参照してください。

終了コード: `0` = clean、 `1` = warnings のみ、 `2` = errors。 CI で利用可能:

```yaml
# .github/workflows/lint.yml の例 (方法 2 — 単一ファイル DL 方式)
- name: Fetch psa.py from canonical repository
  run: |
    curl -sSLO https://raw.githubusercontent.com/usui-tk/ai-generated-artifacts/main/quality-tools/powershell-static-analyzer/psa.py
- name: Static-analyze PowerShell scripts
  run: |
    python3 psa.py --config ./.psa.config.json \
        Deploy-AMDChipsetDriverOnWindowsServer.ps1 \
        Deploy-AMDGraphicsDriverOnWindowsServer.ps1 \
        Deploy-AMDNpuDriverOnWindowsServer.ps1 \
        Deploy-MSBthPanInboxOnWindowsServer.ps1
```

設計上の根拠、 出力フォーマットの詳細、 CI 統合例の拡張版は、 正本側の README [`quality-tools/powershell-static-analyzer/README.md`](https://github.com/usui-tk/ai-generated-artifacts/blob/main/quality-tools/powershell-static-analyzer/README.md) (リポジトリ: [ai-generated-artifacts](https://github.com/usui-tk/ai-generated-artifacts)) を参照してください。

---

## 開発者向け仕様書

phase アーキテクチャのルール、 banner / log の規約、 パラメータ命名規約、 CSV / JSONL 出力フォーマット、 path-handling ルール (`-LiteralPath`)、 `psa.py` が enforce する品質ゲート — これら開発者向けの完全な仕様書は以下を参照してください:

- [**SPEC.md**](./SPEC.md) — 開発者向け仕様書 (本コードベースの拡張やコントリビューション、 AI アシスタント連携の authoritative reference)。 リポジトリ共通のドキュメント言語ポリシー (SPEC.md §A.12 参照) により **英語のみ** で維持されています。

`SPEC.md` は 3 つの Part 構成です:

- **Part A — 共通仕様。** 4 スクリプト共通のルール (phase アーキテクチャ、 banner / log マーカー、 パラメータ規約、 エラーハンドリング、 CSV カラム規約、 path-handling ルール)。 既存スクリプトを拡張する場合や 5 番目のスクリプトを追加する場合は、 まずここを読んでください。
- **Part B — スクリプト固有仕様。** Chipset / Graphics / NPU 各スクリプトのユニークな platform 検出ロジック、 INF inventory filter、 インストーラソース解決の tier 構成、 既知の platform 固有挙動を、 1 スクリプトにつき 1 セクションで documentation。
- **Part C — 品質ゲートと教訓。** `psa.py` のチェック項目、 `TESTING.md` がカバーする回帰テスト、 現実装に焼き込まれている historical fix (例: 過去のチップセットリビジョンにおける timezone 起因 DriverDate 誤検知) のリスト。

新機能を追加する際の推奨ワークフローは: `SPEC.md` を読む → 対象スクリプトの既存 `Invoke-*Phase*_*` 関数を読む → 変更を加える → `python3 psa.py <script>.ps1` を実行 (取得方法は [開発ツール](#開発ツール) を参照) → 新規回帰シナリオがあれば `TESTING.md` を更新、 です。

---

## ファイルエンコーディング

### PowerShell スクリプト (`*.ps1`)

本リポジトリ内の `*.ps1` ファイルは、 すべてのプラットフォームで **UTF-8 with BOM + CRLF 改行で checkout される**よう設定されています。 これは非 ASCII 文字 (`Write-Skip` / `Write-Caution` 等の呼び出しに含まれる日本語ログ文字列) を含む PowerShell 5.1 + 7.x スクリプトの正規エンコーディングです。 これを強制する `.gitattributes` のルール:

```
*.ps1 text working-tree-encoding=UTF-8 eol=crlf
```

git 内部ストレージの補足: git は commit 時に標準的なテキスト正規化を適用します。 リポジトリ内の blob には **BOM + LF** (改行を LF に正規化) として保存され、 `git clone` / `git checkout` 時には `.gitattributes` の `eol=crlf` ディレクティブによって LF が CRLF に再変換されます。 結果として、 ディスク上のファイルは **BOM + CRLF** となり、 これは Windows PowerShell が期待する形式です。 BOM は両形式でコンテンツバイトとして保持されます。

**Raw ダウンロードに関する注意**: GitHub の「Raw」ボタンや `curl https://raw.githubusercontent.com/.../*.ps1` で `.ps1` ファイルを直接ダウンロードする場合、 受け取るのは blob 形式そのまま (**BOM + LF**) です — git の checkout 時変換は raw blob ダウンロードには適用されません。 PowerShell 5.1 / 7.x はスクリプト内の LF と CRLF を共に正しく扱うため、 ファイル自体は正常に実行されますが、 正規形式 (BOM + CRLF) が必要な場合は個別の raw ファイルダウンロードではなくリポジトリのクローンを行ってください。 実用上の推奨:

- **Windows 上で実行する場合**: リポジトリをクローン (`git clone https://github.com/usui-tk/Deploy-Drivers-For-WindowsServer.git`)。 右クリック → 「Save raw as」での個別ダウンロードは避ける。
- **内容確認やクイックパッチ用途**: raw ダウンロードで OK。 PowerShell は LF 改行を許容します。
- **再公開・ミラーする場合**: スクリプトを別の場所で再ホストする際は、 正規形式と一致するよう BOM + CRLF で再生成してください。

### Markdown ドキュメント (`*.md`)

`*.md` ファイル全般 (`README.md`、 `README.ja.md`、 `TESTING.md`、 `SPEC.md`、 `CHANGELOG.md`、 `CONTRIBUTING.md`、 `SECURITY.md`、 `CODE_OF_CONDUCT.md`) は **UTF-8 without BOM** で **LF** 改行を使用 — GitHub ネイティブの Markdown レンダリング規約に合わせています。 `.gitattributes` のルール:

```
*.md text eol=lf
```

Windows のエディタが `.md` ファイルに自動で BOM を挿入する場合 (一部の古い Notepad++ など) は、 commit 前に BOM を除去するか、 `.gitattributes` の正規化に任せて次回 checkout 時に解消してください。

### コンソール出力と日本語ログ文字列

`.ps1` スクリプト内の日本語ログ文字列は、 UTF-8 (`chcp 65001`) に設定された ja-JP Windows コンソールで正しくレンダリングされるよう設計されています。 コンソールが ja-JP のデフォルトコードページ (932 / Shift-JIS) のままだと日本語が文字化けする可能性があります。 スクリプトは P00 で `[Console]::OutputEncoding = [System.Text.Encoding]::UTF8` を呼び出してこれを強制しますが、 `*>&1 | Tee-Object` 等で出力をファイルへリダイレクトする場合は、 二重エンコーディングを避けるためファイルエンコーディングを明示的に UTF-8 に設定してください。

### プログラムによる `.ps1` コンテンツの生成 (Python ヘルパ、AI エージェント、コードジェネレータ)

Python ヘルパスクリプト、Bash の heredoc、ファイル書き込みを行う AI エージェント、ヘルパ関数を合成するコードジェネレータなど、 **プログラムから `.ps1` コンテンツを生成する場合は、ファイルがディスクに書かれる前に UTF-8 + BOM + CRLF の規約に適合させる必要があります**。 各言語のデフォルト挙動はすべてこの規約に反します — Python の `"""..."""` トリプルクォート文字列、Node のテンプレートリテラル、Go の raw 文字列、shell の heredoc はすべて Linux / macOS では LF-only を出力し、書き込み先ファイルの規約とは無関係に LF を採用します。 改行コードが混在した `.ps1` ファイル (一部の行が CRLF、他の行が LF) は `pwsh -ParseFile` を通過し、視覚的な diff では同一に見えます。 しかしバイト単位の検査でこの欠陥は検出され、 CRLF を厳密に要求するコンシューマ (一部の signtool ビルド、特定の MSI オーサリングツール) では実行時に失敗します。

ファイル種別ごとの規約、是正用ツーリングパターン (Python の `open(..., 'wb')` + 明示的 BOM + `\n` → `\r\n`)、コミット前検証コマンドの正本は **[SPEC §A.2](./SPEC.md#a2-source-file-format)** (サブセクション **A.2.1** 〜 **A.2.4**) です。 本レポジトリで唯一発生したこの欠陥のフォレンジック記録 (`.gitattributes` がコミット時にサイレントに正規化したことで救われた事例) は **[SPEC §D.23](./SPEC.md#d23-mixed-line-endings-in-programmatically-emitted-ps1-content-python-script-defect)** に記載されています。

---

## 参考リンク

### Microsoft Learn (日本語版)

- [INF ファイルのセクションとディレクティブ](https://learn.microsoft.com/ja-jp/windows-hardware/drivers/install/inf-file-sections-and-directives)
- [INF Manufacturer セクション (TargetOSVersion / ProductType)](https://learn.microsoft.com/ja-jp/windows-hardware/drivers/install/inf-manufacturer-section)
- [Server SKU と Client SKU でのドライバインストールの違い](https://learn.microsoft.com/ja-jp/windows-hardware/drivers/install/sku-specific-files-and-installation)
- [Inf2Cat コマンドリファレンス](https://learn.microsoft.com/ja-jp/windows-hardware/drivers/devtest/inf2cat)
- [SignTool コマンドリファレンス](https://learn.microsoft.com/ja-jp/windows/win32/seccrypto/signtool)
- [PnPUtil 概要](https://learn.microsoft.com/ja-jp/windows-hardware/drivers/devtest/pnputil)
- [PnPUtil コマンド構文](https://learn.microsoft.com/ja-jp/windows-hardware/drivers/devtest/pnputil-command-syntax)
- [Windows Defender Application Control (WDAC) の概要](https://learn.microsoft.com/ja-jp/windows/security/application-security/application-control/app-control-for-business/wdac)
- [スクリプト (CiTool) で WDAC policy を deploy する](https://learn.microsoft.com/ja-jp/windows/security/application-security/application-control/app-control-for-business/deployment/deploy-wdac-policies-with-script)
- [Windows Driver Kit (WDK) のインストール](https://learn.microsoft.com/ja-jp/windows-hardware/drivers/download-the-wdk)
- [Windows Software Development Kit (SDK) のダウンロード](https://learn.microsoft.com/ja-jp/windows/win32/devnotes/windows-sdk)
- [Windows のドライバ署名要件](https://learn.microsoft.com/ja-jp/windows-hardware/drivers/install/kernel-mode-code-signing-policy--windows-vista-and-later-)

### AMD

- [AMD チップセットドライバ (ダウンロード)](https://www.amd.com/ja/support/category/chipsets)
- [AMD Adrenalin Edition (ダウンロード)](https://www.amd.com/ja/support/category/graphics)
- [AMD Ryzen AI Software (インストールガイド)](https://ryzenai.docs.amd.com/en/latest/inst.html)
- [AMD Ryzen AI Software (リリースノート)](https://ryzenai.docs.amd.com/en/latest/relnotes.html)
- [AMD Ryzen AI Software (サポート構成)](https://ryzenai.docs.amd.com/en/latest/relnotes.html#supported-configurations)
- [AMD RyzenAI-SW (GitHub examples and source)](https://github.com/amd/RyzenAI-SW)
- [AMD RyzenAI-SW (latest releases)](https://github.com/amd/RyzenAI-SW/releases)

### 本リポジトリ

- [TESTING.md](./TESTING.md) — 物理ハードウェアでの検証結果および NPU スクリプトの極めて限定的な検証状況。 **英語のみ。**
- [SPEC.md](./SPEC.md) — 開発者向け仕様書。 **英語のみ。**
- [CHANGELOG.md](./CHANGELOG.md) — 時系列のリリースノート。 **英語のみ。**
- [CONTRIBUTING.md](./CONTRIBUTING.md) — コントリビューションガイド。
- [README.md](./README.md) — 英語版本ドキュメント (マスター)。
- [`psa.py` 正本配置場所 (ai-generated-artifacts)](https://github.com/usui-tk/ai-generated-artifacts/tree/main/quality-tools/powershell-static-analyzer) — 本レポジトリの CI gate で利用する PowerShell 静的解析ツール。

---

## ライセンス

[MIT License](./LICENSE)。Copyright (c) 2026 contributors。

MIT ライセンスは **本リポジトリの PowerShell スクリプトおよび付属ドキュメントのみに適用**されます。スクリプトは実行時に AMD installer EXE / Ryzen AI ドライバ ZIP をダウンロードしますが、AMD のバイナリ・INF・catalog を再配布はしていません。これらのファイルには AMD の再配布規約が独立に適用されます。

---

## コントリビューション

Issue テンプレート、PR ガイドライン、regression test 実行手順 (`psa.py` の使い方含む) は [CONTRIBUTING.md](./CONTRIBUTING.md) を参照してください。

Issue・Pull Request は以下で受け付けています: <https://github.com/usui-tk/Deploy-Drivers-For-WindowsServer>

その他のコミュニティドキュメント:

- [`CODE_OF_CONDUCT.md`](./CODE_OF_CONDUCT.md) — Issue・Pull Request・Security Advisory でやり取りする際に期待される行動規範。 自己署名カーネルモードドライバの安全性への影響を踏まえた内容になっています
- [`SECURITY.md`](./SECURITY.md) — セキュリティに影響する欠陥 (ドライバ署名の欠陥、 WDAC policy scope エラー、 認証情報露出 等) の報告方法。 **公開 Issue として起票しないでください** — プライベートな Security Advisory チャネルを利用してください
- [`CHANGELOG.md`](./CHANGELOG.md) — 時系列のリリースノート（英語版のみ、 すべてのリビジョン）
