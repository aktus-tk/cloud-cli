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

## 既存コマンド一覧

[references/existing-commands.md](references/existing-commands.md) を参照。

## コミットメッセージ

```
awst <service>: <short summary>

<1 line why, not what>
```

例: `awst sqs: add queue inspection subcommands`
