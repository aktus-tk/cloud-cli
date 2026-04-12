# Cloud CLI Helper - プロジェクト構成

AWS、GCP、Tencent Cloud の CLI ラッパーツール集。各CLIの共通オペレーション（インスタンス一覧、起動、停止など）を統一インターフェースで提供。

## ディレクトリ構成

```
cloud-cli/
├── aws-cli/          # AWS CLI ヘルパー
│   ├── bin/
│   │   └── awst      # メインエントリーポイント
│   └── commands/     # サブコマンド定義
│       ├── ec2       # EC2 インスタンス操作
│       ├── r53       # Route 53 DNS
│       ├── alb       # Application Load Balancer
│       ├── cf        # CloudFront
│       ├── lightsail # Lightsail
│       ├── waf       # Web Application Firewall
│       ├── sg        # Security Groups
│       ├── acm       # Certificate Manager
│       └── search    # その他の検索
│
├── g-cli/           # GCP CLI ヘルパー
│   ├── bin/
│   │   └── gcloudt   # メインエントリーポイント
│   └── commands/
│       ├── gce       # Compute Engine インスタンス操作
│       └── firewall  # VPC Firewall ルール表示
│
└── tc-cli/          # Tencent Cloud CLI ヘルパー
    ├── bin/
    │   └── tcclit    # メインエントリーポイント
    └── commands/
        ├── cvm       # Cloud Virtual Machine
        ├── vpc       # Virtual Private Cloud
        └── teo       # Tencent EdgeOne
```

## 動作メカニズム

### メインスクリプト (`bin/*`)

1. **シンボリックリンク対応**: `$0` がシンボリックリンクかどうかを判定
2. **コマンド解決**: `bin` ディレクトリから相対パスで `../commands/` を参照
3. **サブコマンド実行**: 第1引数をサブコマンド名として`commands/`以下の実行可能ファイルを実行
4. **デフォルト help**: 引数がない場合は自動的にサブコマンドの `help` を実行

```bash
# 例：awst ec2 ls
# 1. awst が呼ばれる
# 2. $1 = "ec2", shift
# 3. aws-cli/commands/ec2 を実行
# 4. ec2 の $1 = "ls", その他の引数を渡す
```

### サブコマンド (`commands/*`)

- **Bash スクリプト**: `#!/usr/bin/env bash` で実行可能
- **Case 文**: 最初の引数で処理を分岐
- **関数定義**: 共通処理を関数化（例：`ec2_get_id`, `cvm_get_id`）
- **Help**: デフォルトケース（`*`）で使用可能なサブコマンド一覧を表示

#### サブコマンド構造テンプレート

```bash
#!/usr/bin/env bash
set -e

cmd=$1
shift [|| true]

# ヘルパー関数
function_name() {
  # 実装
}

case "$cmd" in
  subcommand)
    # 処理
    ;;
  *)
    echo "コマンド一覧..."
    ;;
esac
```

## コマンドの使用例

### AWS CLI (`awst`)

```bash
awst ec2 ls              # インスタンス一覧を表示
awst ec2 ls --csv       # CSV 形式で出力
awst ec2 start NAME     # インスタンスを起動
awst ec2 stop NAME      # インスタンスを停止
awst r53 ...            # Route 53 操作
```

### GCP CLI (`gcloudt`)

```bash
gcloudt gce ls                   # Compute Engine インスタンス一覧
gcloudt gce ls --csv             # CSV 形式で出力
gcloudt gce images               # イメージ一覧
gcloudt gce templates            # インスタンステンプレート一覧

gcloudt firewall ls              # VPC Firewall ルール一覧
gcloudt firewall ls --csv        # CSV 形式で出力
gcloudt firewall show RULE_NAME  # 詳細ルール表示
```

### Tencent Cloud CLI (`tcclit`)

```bash
tcclit cvm ls           # CVM インスタンス一覧
tcclit cvm start NAME   # インスタンスを起動
tcclit cvm stop NAME    # インスタンスを停止
tcclit vpc ...          # VPC 操作
```

## 設置方法

各スクリプトは `~/bin/` へのシンボリックリンクで使用：

```bash
ln -s /path/to/cloud-cli/aws-cli/bin/awst ~/bin/awst
ln -s /path/to/cloud-cli/g-cli/bin/gcloudt ~/bin/gcloudt
ln -s /path/to/cloud-cli/tc-cli/bin/tcclit ~/bin/tcclit
```

## 主要なサブコマンド実装

### AWS EC2 (`aws-cli/commands/ec2`)

- **ls**: インスタンス一覧（テーブル/CSV）
- **start/stop**: インスタンス制御
- **sg_rules**: セキュリティグループルール表示
- **Helper**: `ec2_get_id()` でタグ/インスタンス名から ID を検索

### GCP GCE (`g-cli/commands/gce`)

- **ls**: Compute Engine インスタンス一覧（CSV/テーブル）
- **images**: イメージ一覧
- **templates**: インスタンステンプレート一覧
- **groups**: インスタンスグループ一覧
- **Helper**: `gce_ls_csv()` でマシンタイプ情報（vCPU、メモリ）を取得・整形

### GCP Firewall (`g-cli/commands/firewall`)

- **ls**: VPC Firewall ルール一覧（テーブル/CSV）
- **show NAME**: 指定ルールの詳細表示（allowed/denied ルール展開）

### Tencent Cloud CVM (`tc-cli/commands/cvm`)

- **ls**: インスタンス一覧（CSV フォーマット）
- **start/stop**: インスタンス制御（tccli API 呼び出し）
- **Helper**: `cvm_get_id()` でインスタンス名またはタグから ID を検索

## CLI 依存関係

- **AWS**: `aws` CLI がインストール・認証済み
- **GCP**: `gcloud` CLI がインストール・認証済み
- **Tencent Cloud**: `tccli` がインストール・認証済み

各ツールの認証情報は事前に設定されていることを前提としています。

## 開発時の注意

1. **新しいサブコマンド追加**: `commands/` ディレクトリに実行可能ファイルを追加
2. **引数パース**: メインスクリプト側で `shift` 済み、サブコマンドが第1引数を処理
3. **エラーハンドリング**: `set -e` でエラーで即座に終了
4. **CSV 出力**: `column` コマンドやシェル処理で整形（互換性重視）
