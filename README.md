# Cloud CLI Helper

AWS、GCP、Tencent Cloud の CLI ラッパーツール集。各クラウドプロバイダーの共通オペレーション（インスタンス一覧、起動、停止など）を統一インターフェースで提供します。

## インストール

### 1. リポジトリのクローン

GitHub の clone 先にそのまま置きます（例: `~/github/aktus-tk/cloud-cli`）:

```bash
mkdir -p ~/github/aktus-tk
git clone <repository-url> ~/github/aktus-tk/cloud-cli
```

### 2. シンボリックリンクの作成

`~/bin` ディレクトリにシンボリックリンクを作成します:

```bash
mkdir -p ~/bin
ln -sf ~/github/aktus-tk/cloud-cli/aws-cli/bin/awst ~/bin/awst
ln -sf ~/github/aktus-tk/cloud-cli/g-cli/bin/gcloudt ~/bin/gcloudt
ln -sf ~/github/aktus-tk/cloud-cli/tc-cli/bin/tcclit ~/bin/tcclit
```

確認:

```bash
ls -l ~/bin/awst ~/bin/gcloudt ~/bin/tcclit
# 出力例:
# lrwxrwxrwx 1 user user 56 Jun 22 12:00 awst -> ~/github/aktus-tk/cloud-cli/aws-cli/bin/awst
# lrwxrwxrwx 1 user user 57 Jun 22 12:00 gcloudt -> ~/github/aktus-tk/cloud-cli/g-cli/bin/gcloudt
# lrwxrwxrwx 1 user user 57 Jun 22 12:00 tcclit -> ~/github/aktus-tk/cloud-cli/tc-cli/bin/tcclit
```

> **補足**: clone 先のパスが異なる場合は、上記の `ln -sf` のパスを読み替えてください。`git pull` で更新がそのまま反映されます。

### 3. PATH の設定

`~/bin` が PATH に含まれていることを確認します。含まれていない場合は、`~/.bashrc` または `~/.zshrc` に追加:

```bash
export PATH="$HOME/bin:$PATH"
```

## 前提条件

各クラウドプロバイダーの CLI ツールがインストール・認証済みである必要があります:

- **AWS**: `aws` CLI ([インストールガイド](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html))
- **GCP**: `gcloud` CLI ([インストールガイド](https://cloud.google.com/sdk/docs/install))
- **Tencent Cloud**: `tccli` ([インストールガイド](https://cloud.tencent.com/document/product/440/34011))

## 使い方

### AWS CLI (`awst`)

#### AWS コンソール (Granted)

```bash
awst open .                        # デフォルトコンソール（要 AWS_PROFILE）
awst open s3                       # S3 コンソール
awst open acm --region us-east-1   # ACM コンソール（リージョン指定）
awst open --servicemap             # 利用可能なサービス一覧
```

Granted のセットアップと WSL でのブラウザ起動は [README_granted.md](README_granted.md) を参照。

#### EC2 インスタンス操作

```bash
awst ec2 ls              # インスタンス一覧
awst ec2 ls --csv        # CSV 形式で出力
awst ec2 start NAME      # インスタンスを起動
awst ec2 stop NAME       # インスタンスを停止
awst ec2 sg_rules NAME   # セキュリティグループルール表示
```

#### Application Load Balancer (ALB)

```bash
awst alb ls              # ALB 一覧（Security Groups 含む）
awst alb listener NAME   # リスナー情報
awst alb tg NAME         # ターゲットグループ一覧
awst alb health TG_NAME  # ヘルスチェック結果
awst alb rule LISTENER_ARN  # リスナールール詳細
```

#### IAM

```bash
# ポリシー
awst iam policy ls       # Customer Managed Policies 一覧
awst iam policy show NAME/ARN  # ポリシー詳細
awst iam policy create NAME <file|--document JSON>  # ポリシー作成

# ロール
awst iam role ls         # ロール一覧
awst iam role show NAME  # ロール詳細
awst iam role policies NAME  # アタッチ済みポリシー

# ユーザー
awst iam user ls         # ユーザー一覧
awst iam user show NAME  # ユーザー詳細
awst iam user create NAME [--policy ARN|NAME]...  # ユーザー作成
awst iam user attach-policy NAME POLICY  # ポリシーアタッチ
awst iam user policies NAME  # アタッチ済みポリシー

# アクセスキー
awst iam access-key show NAME    # アクセスキー一覧
awst iam access-key create NAME  # アクセスキー作成
```

#### Secrets Manager

```bash
awst secrets ls                      # シークレット一覧
awst secrets ls --csv                # CSV 形式
awst secrets show NAME               # シークレットメタデータ詳細
awst secrets get NAME                # シークレット値取得
awst secrets get NAME --json         # JSON形式で取得

# シークレット作成
awst secrets create my-api-key --string "abc123xyz"
awst secrets create my-db-creds --json '{"username":"admin","password":"pass"}'
awst secrets create my-cert --file cert.pem --description "SSL certificate"

# シークレット更新
awst secrets update my-api-key --string "new-value"
awst secrets update my-db-creds --json '{"username":"admin","password":"newpass"}'

# シークレット削除・復元
awst secrets delete NAME             # 30日間の復旧期間付き削除
awst secrets delete NAME --force     # 即時削除
awst secrets restore NAME            # 削除したシークレットを復元
```

#### CloudFront

```bash
awst cf ls               # ディストリビューション一覧
awst cf domain ID        # 代替ドメイン名（CNAME）
awst cf origin ID        # オリジン一覧
awst cf behavior ID      # キャッシュビヘイビア（TTL、ポリシー含む）
```

#### Route 53

```bash
awst r53 ls              # ホストゾーン一覧
awst r53 records ZONE    # レコード一覧
```

#### その他

```bash
awst lightsail ls        # Lightsail インスタンス一覧
awst waf ls              # WAF WebACL 一覧
awst sg ls               # セキュリティグループ一覧
awst acm ls              # 証明書一覧
```

### GCP CLI (`gcloudt`)

#### Compute Engine (GCE)

```bash
gcloudt gce ls                      # インスタンス一覧
gcloudt gce ls --csv                # CSV 形式
gcloudt gce show INSTANCE_NAME      # インスタンス詳細
gcloudt gce images                  # イメージ一覧
gcloudt gce templates               # インスタンステンプレート
gcloudt gce groups                  # インスタンスグループ
```

#### VPC Firewall

```bash
gcloudt firewall ls                 # ファイアウォールルール一覧
gcloudt firewall ls --csv           # CSV 形式
gcloudt firewall show RULE_NAME     # ルール詳細
```

#### Service Account

```bash
gcloudt sa ls                       # Service Account 一覧
gcloudt sa ls --csv                 # CSV 形式
gcloudt sa show EMAIL               # 詳細情報
```

#### Cloud Storage (GCS)

```bash
gcloudt gcs ls                              # バケット一覧
gcloudt gcs ls BUCKET_NAME                  # オブジェクト一覧
gcloudt gcs ls --csv                        # CSV 形式

gcloudt gcs cp gs://BUCKET/OBJECT LOCAL     # ダウンロード
gcloudt gcs cp LOCAL gs://BUCKET/OBJECT     # アップロード

gcloudt gcs rm gs://BUCKET/OBJECT           # オブジェクト削除
gcloudt gcs rm gs://BUCKET/PREFIX/ -r       # 再帰削除
```

#### Cloud Load Balancer

```bash
gcloudt clb ls                      # ロードバランサー一覧
gcloudt clb show NAME               # 詳細情報
```

### Tencent Cloud CLI (`tcclit`)

#### Cloud Virtual Machine (CVM)

```bash
tcclit cvm ls           # インスタンス一覧
tcclit cvm ls --csv     # CSV 形式
tcclit cvm types        # 使用可能なインスタンスタイプ一覧
tcclit cvm start NAME   # インスタンス起動
tcclit cvm stop NAME    # インスタンス停止
```

#### VPC

```bash
tcclit vpc ls           # VPC 一覧
tcclit vpc show ID      # VPC 詳細
```

#### Tencent EdgeOne (TEO)

```bash
tcclit teo ls           # EdgeOne ゾーン一覧
tcclit teo show ZONE    # ゾーン詳細
```

## プロジェクト構造

```
cloud-cli/
├── aws-cli/          # AWS CLI ヘルパー
│   ├── bin/awst      # メインエントリーポイント
│   └── commands/     # サブコマンド定義
│       ├── ec2
│       ├── r53
│       ├── alb
│       ├── cf
│       ├── iam
│       ├── secrets
│       ├── lightsail
│       ├── waf
│       ├── sg
│       ├── acm
│       └── search
│
├── g-cli/            # GCP CLI ヘルパー
│   ├── bin/gcloudt   # メインエントリーポイント
│   └── commands/     # サブコマンド定義
│       ├── gce
│       ├── firewall
│       ├── sa
│       ├── gcs
│       └── clb
│
└── tc-cli/           # Tencent Cloud CLI ヘルパー
    ├── bin/tcclit    # メインエントリーポイント
    └── commands/     # サブコマンド定義
        ├── cvm
        ├── vpc
        └── teo
```

## セキュリティ

セキュリティに関するベストプラクティスや脆弱性の報告方法については、[SECURITY.md](SECURITY.md) を参照してください。

**重要**: このツールは認証情報を保存・管理しません。認証は各クラウドプロバイダーの CLI ツール（`aws`, `gcloud`, `tccli`）によって処理されます。

## ライセンス

MIT License - 詳細は [LICENSE](LICENSE) ファイルを参照してください。

