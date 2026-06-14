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
│       ├── eks       # Elastic Kubernetes Service
│       ├── r53       # Route 53 DNS
│       ├── alb       # Application Load Balancer
│       ├── cf        # CloudFront
│       ├── iam       # Identity and Access Management
│       ├── sec       # Secrets Manager
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
│       ├── firewall  # VPC Firewall ルール表示
│       ├── sa        # Service Account 表示
│       ├── gcs       # Cloud Storage バケット表示
│       └── clb       # Cloud Load Balancer
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

awst alb ls              # ALB 一覧を表示（Security Groups 含む）
awst alb listener NAME   # ALB のリスナー情報を表示
awst alb tg NAME         # ALB のターゲットグループを表示
awst alb health TG_NAME  # ターゲットグループのヘルスチェック結果

awst iam policy ls       # customer managed policies 一覧
awst iam policy show NAME  # policy 詳細（バージョン、ドキュメント）
awst iam role ls         # role 一覧
awst iam role show NAME  # role 詳細（信頼ポリシー、アタッチ済みポリシー）
awst iam role policies NAME  # role にアタッチされたポリシー一覧
awst iam user ls         # user 一覧
awst iam user show NAME  # user 詳細（アタッチ済みポリシー）
awst iam user policies NAME  # user にアタッチされたポリシー一覧

awst sec ls              # シークレット一覧
awst sec show NAME       # シークレットメタデータ詳細
awst sec get NAME        # シークレット値取得
awst sec create NAME --string "value"  # シークレット作成
awst sec update NAME --string "new-value"  # シークレット更新
awst sec delete NAME     # シークレット削除

awst eks list-clusters           # EKS クラスター一覧
awst eks list-clusters --csv     # EKS クラスター一覧（CSV形式）
awst eks update-kubeconfig NAME          # クラスターの kubeconfig を更新
awst eks update-kubeconfig NAME --dry-run # kubeconfig を標準出力に表示

awst r53 records ZONE                    # Route 53 レコード一覧
awst r53 records --mlr ZONE              # Route 53 レコード一覧（Miller でフォーマット）
```

### GCP CLI (`gcloudt`)

```bash
gcloudt gce ls                      # Compute Engine インスタンス一覧
gcloudt gce ls --csv                # CSV 形式で出力
gcloudt gce show INSTANCE_NAME      # インスタンス詳細情報（SA、ボリューム）
gcloudt gce images                  # イメージ一覧
gcloudt gce templates               # インスタンステンプレート一覧

gcloudt firewall ls                 # VPC Firewall ルール一覧
gcloudt firewall ls --csv           # CSV 形式で出力
gcloudt firewall show RULE_NAME     # 詳細ルール表示

gcloudt sa ls                       # Service Account 一覧
gcloudt sa ls --csv                 # CSV 形式で出力
gcloudt sa show EMAIL               # Service Account 詳細情報

gcloudt gcs ls                                      # Cloud Storage バケット一覧
gcloudt gcs ls --csv                                # CSV 形式で出力
gcloudt gcs ls BUCKET_NAME                         # バケット内のオブジェクト一覧
gcloudt gcs ls BUCKET_NAME --csv                   # オブジェクト一覧（CSV形式）

gcloudt gcs cp gs://BUCKET/OBJECT LOCAL_PATH      # オブジェクトをダウンロード（pull）
gcloudt gcs cp LOCAL_PATH gs://BUCKET/OBJECT      # ローカルファイルをアップロード（push）

gcloudt gcs rm gs://BUCKET/OBJECT                 # オブジェクトを削除
gcloudt gcs rm gs://BUCKET/PREFIX/ -r             # プレフィックス配下を再帰削除
```

### Tencent Cloud CLI (`tcclit`)

```bash
tcclit cvm ls           # CVM インスタンス一覧
tcclit cvm types        # 使用可能なインスタンスタイプ一覧
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

### AWS ALB (`aws-cli/commands/alb`)

- **ls**: ALB 一覧（Name, DNS, Scheme, VpcId, SecurityGroups）
  - Security Group が複数ある場合は `,` で連結して表示
- **listener NAME**: 指定 ALB のリスナー情報（Port, Protocol, DefaultActions, Certificates）
- **tg NAME**: 指定 ALB のターゲットグループ一覧（Name, Port, Protocol, HealthCheckPath）
- **health TG_NAME**: ターゲットグループのヘルスチェック結果（TargetId, Port, State, Reason）
- **rule LISTENER_ARN**: リスナーのルール詳細を表示
- **Helper**: `get_alb_arn_by_name()` で ALB 名から ARN を取得、`get_tg_arn_by_name()` でターゲットグループ名から ARN を取得

### AWS IAM (`aws-cli/commands/iam`)

- **policy ls**: Customer Managed Policy 一覧（テーブル/CSV）
- **policy show NAME/ARN**: Policy 詳細情報（バージョン、ポリシードキュメント）
- **policy create NAME <file|--document JSON>**: Customer Managed Policy 作成（JSON ファイルまたは JSON 文字列指定）
- **role ls**: Role 一覧（テーブル/CSV）
- **role show NAME**: Role 詳細情報（AssumeRolePolicyDocument、アタッチ済みポリシー、インラインポリシー）
- **role policies NAME**: Role にアタッチされたポリシー一覧
- **role inline-policies NAME**: Role に埋め込まれたインラインポリシー一覧（ポリシードキュメント付き）
- **user ls**: User 一覧（テーブル/CSV）
- **user show NAME**: User 詳細情報（アタッチ済みポリシー）
- **user policies NAME**: User にアタッチされたポリシー一覧
- **user create NAME [--policy ARN|NAME]...**: User 作成＋ポリシー直接アタッチ（複数対応）
  - Policy ARN または名前（Customer Managed/AWS Managed いずれでも指定可）で指定可能
- **user attach-policy NAME POLICY**: User にポリシーをアタッチ（Policy 名または ARN で指定）
- **access-key show NAME**: User のアクセスキー一覧（AccessKeyId, Status, CreateDate）
- **access-key create NAME**: User 用のアクセスキー作成（AccessKeyId, SecretAccessKey 表示＋レコメンデーション）

<<<<<<< HEAD
### AWS Secrets Manager (`aws-cli/commands/sec`)

- **ls**: シークレット一覧（テーブル/CSV）
- **show NAME**: シークレットメタデータ詳細（ARN、作成日、最終変更日、ローテーション設定、タグなど）
- **get NAME**: シークレット値取得（プレーンテキスト）
- **get NAME --json**: シークレット値取得（JSON形式でパース）
- **create NAME --string VALUE**: 文字列シークレットを作成
- **create NAME --json VALUE**: JSON シークレットを作成
- **create NAME --file PATH**: ファイルからシークレットを作成
- **update NAME --string/--json/--file**: シークレット値を更新
- **delete NAME**: シークレットを削除（30日間の復旧期間）
- **delete NAME --force**: シークレットを即座に削除
- **restore NAME**: 削除したシークレットを復元
=======
### AWS EKS (`aws-cli/commands/eks`)

- **list-clusters**: EKS クラスター一覧（Name, Version, Status, Endpoint, RoleArn, Created）テーブル/CSV
- **update-kubeconfig NAME**: 指定クラスターの kubeconfig をローカルに更新
- **update-kubeconfig NAME --dry-run**: kubeconfig を標準出力に出力（kubeconfig の確認・パイプ処理用）
>>>>>>> 34c33ef (chore: update .gitignore and CLAUDE.md)

### GCP GCE (`g-cli/commands/gce`)

- **ls**: Compute Engine インスタンス一覧（テーブル/CSV）
- **show NAME**: インスタンス詳細情報（Service Account、ボリューム、ネットワーク、タグ、ラベル）
- **images**: イメージ一覧
- **templates**: インスタンステンプレート一覧
- **groups**: インスタンスグループ一覧
- **Helper**: `gce_ls_csv()` でマシンタイプ情報（vCPU、メモリ）を取得・整形

### GCP Firewall (`g-cli/commands/firewall`)

- **ls**: VPC Firewall ルール一覧（テーブル/CSV）
- **show NAME**: 指定ルールの詳細表示（allowed/denied ルール展開）

### GCP Service Account (`g-cli/commands/sa`)

- **ls**: Service Account 一覧（テーブル/CSV）
- **show EMAIL**: Service Account 詳細情報（メール、Display Name、関連キー情報）

### GCP Cloud Storage (`g-cli/commands/gcs`)

- **ls**: バケット一覧（テーブル/CSV）
- **ls BUCKET_NAME**: 指定バケット内のオブジェクト一覧（テーブル/CSV）
- **cp**: GCS オブジェクトのアップロード/ダウンロード（`gsutil cp` ラッパー）
  - pull: `gcloudt gcs cp gs://BUCKET/OBJECT LOCAL_PATH`
  - push: `gcloudt gcs cp LOCAL_PATH gs://BUCKET/OBJECT`
- **Helper**: `gcs_buckets_csv()` でバケット情報を取得、`gcs_objects_csv()` でオブジェクト情報を取得

### Tencent Cloud CVM (`tc-cli/commands/cvm`)

- **ls**: インスタンス一覧（テーブル/CSV）
- **types**: 使用可能なインスタンスタイプ一覧（DescribeInstanceTypeConfigs、テーブル/CSV）
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
