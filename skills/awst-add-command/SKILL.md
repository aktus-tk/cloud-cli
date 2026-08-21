---
name: awst-add-command
description: Adds read-only awst subcommands under aws-cli/commands for AWS services. Use when adding awst wrappers (sqs, lambda, eventbridge, secrets, etc.), extending cloud-cli AWS helpers, or implementing ls/show/--csv/--json bash commands in this repository.
---

# awst サブコマンド追加

cloud-cli の `awst` に AWS サービス用の read-only サブコマンドを追加する手順。

## いつ使う

- `awst <service>` を新規追加・拡張するとき
- AWS CLI の情報を bash + jq でラップするとき
- ユーザーが commit/push まで依頼するとき

## 手順

1. **既存実装を読む**（1〜2 ファイルで十分）
   - シンプル: `aws-cli/commands/sqs`, `aws-cli/commands/sts`
   - ネスト subcommand: `aws-cli/commands/lambda`, `aws-cli/commands/eventbridge`
   - 詳細 show + 複数 API: `aws-cli/commands/secrets`, `aws-cli/commands/identity-center`
2. **AWS CLI を確認**
   - `aws <service> help`
   - `aws <service> <operation> help`
   - サービス名と CLI 名が違う例: EventBridge → `aws events`, Identity Center → `aws sso-admin` + `aws identitystore`
3. **ファイル作成**
   - パス: `aws-cli/commands/<name>`（`<name>` = `awst` の第1引数）
   - `chmod +x`
   - 詳細は [references/bash-patterns.md](references/bash-patterns.md)
4. **検証**
   - `bash -n aws-cli/commands/<name>`
   - `aws-cli/commands/<name> help`
5. **commit / push**（依頼があれば）
   - 詳細は [references/git-workflow.md](references/git-workflow.md)

## 命名

| awst 引数 | ファイル | AWS CLI |
|-----------|----------|---------|
| `awst sqs` | `commands/sqs` | `aws sqs` |
| `awst eventbridge` | `commands/eventbridge` | `aws events` |
| `awst identity-center` | `commands/identity-center` | `aws sso-admin`, `aws identitystore` |
| `awst secrets` | `commands/secrets` | `aws secretsmanager` |

エイリアスが必要なら薄い wrapper を追加（例: `commands/sso` → `identity-center` を exec）。

## 実装ルール

- `#!/usr/bin/env bash` + `set -eo pipefail`
- 第1引数 `$sub` で case 分岐、`shift || true`
- `usage()` + `help|--help|-h|""` ケース
- 一覧: `ls [--csv]`、詳細: `show <name> [--json]`
- CSV: ヘッダ行 → `aws ... | jq` → `tr '\t' ','`、表は `column -s, -t`
- show の readable 出力は jq `-r`、JSON は `--json` または raw `jq .`
- 既存コードのスタイルに合わせ、過剰な抽象化はしない
- スコープ外の変更（README, CLAUDE.md）はユーザーが求めたときだけ

## コマンド追加時の実行方式

新しいサブコマンドやオプションを追加する際は、操作を以下の3つに分類し、実装方式を決定する。単純な create/update/delete といった名前だけで判断せず、可逆性・データ損失・復旧可能性・影響範囲を考慮する。

### 1. Read-only 操作

ネイティブ CLI を直接実行してよい。cloud-cli が結果を整形して表示する。例: `ls`, `show`, `get`, `describe`, `list`, `types`。

### 2. 通常の変更操作

ネイティブ CLI を直接実行してよい。dry-run や print-only にはしない。例: `create`, `update`, `restore`, `start`。

### 3. 破壊的・高リスクな操作（print only）

cloud-cli からネイティブ CLI を実行してはならない。実行予定のネイティブコマンドを標準出力に出力して終了する。cloud-cli 自身はそのコマンドを一切実行しない。

**print only は「確認プロンプトを表示してから cloud-cli が実行する」ことを意味しない。** ユーザーが出力されたコマンドを確認し、必要に応じて別途実行する。

分類はコマンド名だけでなく以下を考慮して判断する:

- データ損失の可能性
- 不可逆性（`--force` 等の有無で危険度が変わる）
- 復旧可能性（復旧可能な delete と即時削除は区別する）
- 影響範囲
- 既存リソースや設定への重大な影響

例: `delete`, `delete --force`, `terminate`, `revoke`, `detach --force`。

### `--debug` の実装ルール

`--debug` が指定された場合、操作分類に関係なくネイティブ CLI を実行してはならない。実行予定のコマンドのみを出力する。`--debug` は dry-run として実行予定コマンドを確認するモードとして扱う。

## 既存コマンド一覧

[references/existing-commands.md](references/existing-commands.md) を参照。

## コミットメッセージ

```
awst <service>: <short summary>

<1 line why, not what>
```

例: `awst sqs: add queue inspection subcommands`
