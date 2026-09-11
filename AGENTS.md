# cloud-cli — AI Agent 向け規則

人間向けの利用案内・コマンド一覧の正本は [README.md](README.md) です。本ファイルは Agent が守るべきルールと、リポジトリを変更する際の実装規則を定義します。

## 責務と対象外

**cloud-cli が行うこと**

- 調査に必要な情報を、短く安定したコマンドで取得する
- 公式 CLI の生出力を抽出・正規化し、必要最小限に整形して返す
- 実運用で再利用価値の高い操作だけをコマンドとして追加する

**cloud-cli が行わないこと**

- 公式 CLI の全機能の再実装
- AWS / GCP / Tencent Cloud の差異を完全に抽象化する統合 API
- 調査手順全体や複雑なワークフローの実装（それは skill / runbook の責務）
- 一度きりの処理、顧客・プロジェクト固有の処理の取り込み

## 責務境界

```text
skill
  何を、どの順序で調査するかを定義する

cloud-cli
  調査に必要な情報を短く安定したコマンドで取得し、
  必要最小限に整形して出力する

公式 CLI（aws / gcloud / tccli）
  クラウド API を直接操作する
```

調査手順全体を cloud-cli に実装しない。取り込むのは、複数の skill や調査から再利用できる CLI 操作・情報取得処理のみ。

## コマンド追加の判断基準

次の条件を**複数**満たす操作を追加対象とする。

- 実運用で複数回利用している
- 公式 CLI のオプションが長い、複雑、または覚えにくい
- 公式 CLI の生出力が大きすぎる
- 複数のプロジェクトや調査で共通利用できる
- skill から安定して呼び出したい
- 入力または出力トークンを明確に削減できる
- 人間が日常的に使用する

追加しない例: 一度しか使わない処理、顧客・プロジェクト固有の処理、複数ステップの複雑なワークフロー（公式 CLI または各プロジェクトの skill / runbook で扱う）。

## コマンド設計・命名規則

- エントリポイント: `aws-cli/bin/awst`、`g-cli/bin/gcloudt`、`tc-cli/bin/tcclit`
- サブコマンド: 各 `*/commands/<name>` に実行可能 Bash スクリプト（第1引数で `case` 分岐）
- 一覧は `ls`、詳細は `show` / `get` / `describe` など既存サブコマンドの慣習に合わせる
- 表形式出力に `--csv` を用意する（既存コマンドと同様）
- JSON が必要な場合は `--json` を既存パターンに合わせて付与
- AWS サービス名と CLI 名が異なる場合は既存例に従う（例: EventBridge → `aws events`、ファイル名 `eventbridge`）
- 新規 `awst` サブコマンド追加時は [.cursor/skills/awst-add-command/SKILL.md](.cursor/skills/awst-add-command/SKILL.md) を参照

## 出力の削減・整形・安定性

- Agent がパースしやすい、列やフィールドが安定した出力を優先する
- 不要な ARN・メタデータ・ネスト JSON は落とすか要約する
- 人間向け表は `column` 等で整形（既存実装に合わせる）
- 同じ操作で毎回異なる形式を返さない（破壊的な出力形式変更は避ける）
- シークレット値は `get` 等、明示的に必要なサブコマンドでのみ出力する。一覧・詳細では値を含めない

## 実行ポリシー

`awst` / `gcloudt` / `tcclit` 共通。操作は次の 3 つに分類する。**`create` / `get` / `delete` などの名前だけで判定しない。**

### Read-only 操作

ネイティブ CLI を直接実行し、結果を整形して表示する。例: `ls`, `show`, `get`, `describe`, `list`, `types`。

### 通常の変更操作

ネイティブ CLI を直接実行する。「変更操作だから」という理由だけで dry-run や実行予定コマンド表示にしない。例: `create`, `update`, `restore`, `start`。

### 破壊的・高リスクな操作

cloud-cli からネイティブ CLI を**実行しない**。実行予定のネイティブ CLI コマンドを標準出力に出して終了する（**実行予定コマンドのみ表示（実行しない）**）。

これは「確認プロンプトのあと cloud-cli が実行する」ことを意味しない。ユーザーが出力を確認し、必要なら別途公式 CLI を実行する。

危険度の判断に使う観点:

- データ損失の可能性
- 不可逆性（`--force` 等）
- 秘密情報の露出リスク
- 復旧可能性（復旧可能な delete と即時削除は区別する）
- 影響範囲
- 既存リソースや設定への重大な影響

例: `delete`, `delete --force`, `terminate`, インスタンス `stop`（運用ポリシーで高リスクとみなすもの）。

### `--debug`

操作分類に関係なく、ネイティブ CLI を実行しない。実行予定コマンドのみを出力する（dry-run / command preview）。

## 認証・秘密情報

- cloud-cli は認証情報を保存・管理しない（[SECURITY.md](SECURITY.md)）
- 認証は `aws` / `gcloud` / `tccli` および Tencent の `tc-assume` 連携に委ねる
- コミット・ログ・help 文に秘密情報やアカウント固有の値を埋め込まない
- `secrets get` 等の出力を Agent ログに不必要に残さないよう、実装・利用ともに最小限にする

## 実装構造（変更時の参照）

### メインスクリプト (`bin/*`)

1. シンボリックリンク対応（`$0` の実パス解決）
2. `bin` から `../commands/` を参照
3. 第1引数をサブコマンド名として `commands/` 以下を実行
4. 引数なしのときは該当サブコマンドの `help` を表示

```bash
# awst ec2 ls → aws-cli/commands/ec2 を実行し、ec2 側で ls を処理
```

### サブコマンド (`commands/*`)

- `#!/usr/bin/env bash`、`set -e`（既存ファイルは `set -eo pipefail` も可）
- `cmd=$1` → `shift || true` → `case`
- 共通処理は関数化（例: `ec2_get_id`, `cvm_get_id`, `lb_get_id`）
- 未知の第1引数は help を表示

```bash
#!/usr/bin/env bash
set -e

cmd=$1
shift || true

case "$cmd" in
  ls) … ;;
  *)
    echo "Usage: …"
    ;;
esac
```

### ディレクトリ（ファイル特定用）

```text
cloud-cli/
├── aws-cli/bin/awst, commands/, skills/   # 例: skills/billing/SKILL.md
├── g-cli/bin/gcloudt, commands/
└── tc-cli/bin/tcclit, commands/, bin/tccli（AssumeRole）
```

## 実装後のテストとドキュメント更新

- `bash -n` で対象 `commands/*` スクリプトの構文チェック
- `help` および代表サブコマンドの動作確認（可能な環境で）
- 新規・変更したユーザー向けコマンドは [README.md](README.md) に追記（本ファイルに使用例を二重管理しない）
- コマンド名・引数・CLI 挙動をユーザー依頼なく変更しない

## 専用 Skill へのルーティング

ドメイン固有の手順・API 制約は専用 Skill を正本とする。

| 領域 | Skill |
|------|--------|
| AWS 請求 (Cost Explorer) | [aws-cli/skills/billing/SKILL.md](aws-cli/skills/billing/SKILL.md) |
| `awst` サブコマンドの新規追加 | [.cursor/skills/awst-add-command/SKILL.md](.cursor/skills/awst-add-command/SKILL.md) |

請求分析では Cost Explorer のメトリクス（NetUnblendedCost / BlendedCost）、API 制約、請求書とのズレの原因などを上記 billing Skill に従う。
