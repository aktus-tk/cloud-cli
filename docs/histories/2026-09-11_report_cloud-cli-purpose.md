# 実装報告: cloud-cli 目的の README / AGENTS 整理

対応プラン: [2026-09-11_plan_cloud-cli-purpose.md](./2026-09-11_plan_cloud-cli-purpose.md)

実施日: 2026-09-11

## 1. README.md に残した内容

- **目的**（3 点）と、全機能再実装・完全抽象化はしない旨
- 実運用で人間と AI が育てるリポジトリであること（詳細は AGENTS へリンク）
- **設計方針**: 一行のデータフロー、入力/出力/知識の 3 価値、認証は基盤であること
- **対応クラウド**と公式 CLI との対応表（`awst` / `gcloudt` / `tcclit`）
- **インストール**（clone、シンボリックリンク、PATH）
- **前提条件**（各公式 CLI のインストールリンク）
- **認証関連ドキュメント**へのリンク（README_granted、README_tccli、SECURITY）
- **共通実行ポリシー**（4 項目の要約 + AGENTS 参照）
- **使い方**（既存のコマンド例をベースに、AGENTS にのみあった例を一部追記）
- **プロジェクト構造**（簡潔なツリー + `help` / AGENTS 参照）
- **セキュリティ**・**ライセンス**

### README への追記（情報欠落防止）

AGENTS から削除する「使用例」にあったが README に無かった項目を README に移した。

- `awst eks`（list-clusters、update-kubeconfig）
- `gcloudt gce group-instances`
- `gcloudt clb` の addresses / ssl-certs / certificates / backend-services / target-proxies / cert-maps / cert-map-entries
- `gcloudt project` / `network` / `dns` セクション

表記統一: 破壊的操作の説明を「実行予定コマンドのみ表示（実行しない）」に揃えた箇所（ec2 stop、secrets delete、tcclit cvm stop）。

## 2. AGENTS.md に移した内容

- cloud-cli の**責務と対象外**
- **skill / cloud-cli / 公式 CLI** の責務境界
- **成長の循環**（フロー図）
- **コマンド追加の判断基準**（条件一覧と追加しない例）
- **コマンド設計・命名規則**（bin/commands 構造、`ls`/`show`/`--csv`、awst-add-command Skill 参照）
- **出力の削減・整形・安定性**（秘密値の扱い含む）
- **実行ポリシー詳細**（Read-only / 通常変更 / 破壊的・高リスク、`--debug`、危険度の判定観点）
- **認証・秘密情報**の Agent 向けルール
- **実装構造**（メインスクリプト、サブコマンドテンプレート、ディレクトリのファイル特定用説明）
- **実装後のテストとドキュメント更新**（README を人間向け正本と明記）
- **専用 Skill ルーティング**（billing、awst-add-command）
- **CLI 依存関係**（短文）

## 3. 重複として削除した内容

**AGENTS.md から削除**

- 冒頭の「Cloud CLI Helper」紹介文（README と重複）
- 全コマンドの**使用例**ブロック（AWS / GCP / Tencent）
- **設置方法**（`~/bin` への symlink 手順）
- **主要なサブコマンド実装**（各サービスの機能一覧・Helper 名の長文）
- 人間向けの詳細**ディレクトリ構成**ツリー（最小限のファイル特定用ツリーに置換）
- README と同等の「開発時の注意」4 行（内容は実行ポリシー・テスト節に統合）

**README.md から削除・短縮**

- 成長の循環の詳細フローと昇格条件チェックリスト → AGENTS
- 設計の流れの多段 ASCII 図 → 一行フローに統合
- 実行ポリシーの表・サブセクション（Read-only / 通常変更 / 破壊的の長文）→ 要約 + AGENTS 参照

## 4. 判断が必要だった点

| 点 | 採用した判断 |
|----|----------------|
| README のコマンド一覧の網羅性 | プランは「有効なコマンド一覧を失わない」ため、AGENTS 使用例にあって README に無かった GCP/EKS 例のみ追記。`aws-cli/commands` に存在するが README にも AGENTS にも無かったサービス（sqs、lambda 等）は今回追加せず（スコープ外・未ドキュメントのまま） |
| セキュリティの認証説明 | 前提条件直後に認証ドキュメントリンクを集約し、文末 SECURITY セクションは維持（重複は短いため許容） |
| `stop` の分類 | 実装は従来どおり print-only。AGENTS の破壊的例に「運用で高リスクとみなす stop」を明記し、名前だけで判定しない旨と整合 |
| awst-add-command のパス | リポジトリ内の実パス `.cursor/skills/awst-add-command/SKILL.md` を AGENTS で参照 |

## 5. CLI 実装を変更していないこと

- `aws-cli/commands/*`、`g-cli/commands/*`、`tc-cli/commands/*` および `bin/*` の Bash 実装には**手を入れていない**
- コマンド名・引数・実行ポリシーの**挙動**は変更していない
- 変更ファイルは **README.md**、**AGENTS.md**、本報告書のみ

## 整合性チェック

- README → AGENTS、AGENTS → README、billing Skill、awst-add-command Skill、README_granted / README_tccli / SECURITY の相互リンクを確認済み
- 人間向けコマンド例の正本は README、Agent 規則の正本は AGENTS と役割を分離

---

## 追記: AGENTS.md 軽量化（2026-09-12）

### 変更内容

`AGENTS.md` から次の 2 セクションのみ削除した。その他の節・文言は変更していない。

| 削除した節 | 理由 |
|------------|------|
| **成長の循環** | 設計背景であり Agent の強制ルールではない。内容は [README.md](../../README.md)（目的・実運用で育てる旨）および本 plan/report に残っている |
| **CLI 依存関係** | [README.md](../../README.md) の「前提条件」と重複 |

### 変更しなかったもの

- `aws-cli/` / `g-cli/` / `tc-cli/` の CLI 実装（`commands/`、`bin/` 等）
- `README.md` および `docs/histories/2026-09-11_plan_cloud-cli-purpose.md`
- `AGENTS.md` の上記以外のすべての節

### 参照の整理

- **成長の循環**（フロー図）: plan / 初回 report §2・§3、README の設計・目的文を参照
- **公式 CLI の前提**: README「前提条件」および認証関連リンクを正本とする
- **コマンド追加の判断基準**: 引き続き `AGENTS.md` にのみ記載（強制ルールとして維持）
