# Granted / assume

[Granted](https://docs.commonfate.io/granted/getting-started) は AWS SSO プロファイルの切り替えと、ブラウザでの AWS マネジメントコンソール起動を簡単にする CLI です。`assume` コマンドでプロファイルを assume し、`-c` でコンソールを開きます。

このリポジトリでは `awst open` が `assume` のラッパーです。`direnv` で `AWS_PROFILE` を設定したプロジェクトディレクトリから実行する想定です。

## インストール

```bash
curl -OL releases.commonfate.io/granted/v0.36.2/granted_0.36.2_linux_x86_64.tar.gz
sudo tar -zxvf ./granted_0.36.2_linux_x86_64.tar.gz -C /usr/local/bin/
```

`assume` と `granted` が PATH に入っていることを確認します。

```bash
assume --version
```

Granted の SSO 設定は別途行ってください（`granted sso populate` など）。本ドキュメントでは設定済みを前提とします。

## 使い方

### direnv + AWS_PROFILE

```bash
cd ~/github/example/terraform-project
direnv allow   # 初回のみ

# .envrc
# export AWS_PROFILE=example-profile

awst open .                        # デフォルトコンソール
awst open s3                       # S3 コンソール
awst open acm --region us-east-1   # ACM コンソール（リージョン指定）
awst open --servicemap             # 利用可能なサービス一覧
```

`awst open` 単体は `awst` の仕様上ヘルプを表示します。デフォルトコンソールは `awst open .` を使います。

### assume を直接使う場合

```bash
assume $AWS_PROFILE -c
assume $AWS_PROFILE -c -s s3
```

## サービス一覧

```bash
awst open --servicemap
```

Granted 側の定義（[service_map.go](https://github.com/fwdcloudsec/granted/blob/main/pkg/console/service_map.go)）を取得して表示します。

よく使う例:

| 指定 | コンソール |
|------|-----------|
| `s3` | S3 |
| `ec2` | EC2 |
| `rds` | RDS |
| `iam` | IAM |
| `lambda` / `l` | Lambda |
| `ecs` | ECS |
| `eks` | EKS |
| `cf` / `cloudfront` | CloudFront |
| `r53` / `route53` | Route 53 |
| `sm` / `secretsmanager` | Secrets Manager |
| `cw` / `cloudwatch` | CloudWatch |

## WSL でのブラウザ起動

`assume -c` は macOS の `open` コマンドでブラウザを開きます。WSL には `open` がないため、ラッパースクリプトで対応します。

### 現在の方法: Chrome プロファイル指定

AWS SSO 用に Chrome プロファイルを固定する場合:

```bash
sudo tee /usr/local/bin/open <<'EOF'
#!/bin/sh
exec "/mnt/c/Program Files/Google/Chrome/Application/chrome.exe" \
  --profile-directory="Profile 11" "$@"
EOF
sudo chmod +x /usr/local/bin/open
```

プロファイル名は Windows 側の Chrome で確認してください。

```bash
ls "/mnt/c/Users/<USER>/AppData/Local/Google/Chrome/User Data"
```

### 代替案

| 方法 | 特徴 |
|------|------|
| **wslview** (`wslu` パッケージ) | Windows のデフォルトブラウザで開く。設定が最も簡単。`sudo apt install wslu` のあと `ln -sf $(command -v wslview) /usr/local/bin/open` |
| **cmd.exe start** | デフォルトブラウザ起動。`exec cmd.exe /c start "" "$@"` |
| **Chrome ラッパー（上記）** | 特定 Chrome プロファイルを使いたいとき向け（SSO セッション分離など） |

SSO でプロファイルを分けたい場合は Chrome ラッパー、手軽さ優先なら `wslview` がおすすめです。
