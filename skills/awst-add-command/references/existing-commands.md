# 既存 awst コマンド

`aws-cli/commands/` 配下。参考実装として読む。

| ファイル | 用途 |
|----------|------|
| sqs | 単一リソース ls/show、名前解決 |
| sts | 小さな flat コマンド |
| secrets | CRUD + get --field/--version |
| lambda | function/alias/event ネスト |
| eventbridge | ネスト + 複数 API 合成 show |
| ec2 | lt ネスト、複雑 jq |
| cf | CloudFront、association 表示 |
| identity-center | sso-admin + identitystore |
| dynamodb | list + per-item describe |
| elasticache | 複数 API 合成 |
| ecr | repo/image ネスト |
| iam | policy/role/user 深いネスト |
| alb, sg, vpc, eks, rds, ssm, acm, waf, efs, r53, lightsail, search, open | 各種 |

新規追加時は **同じ複雑度の既存ファイル** を1つ選んで真似る。
