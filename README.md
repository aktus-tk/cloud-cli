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

## 共通実行ポリシー

cloud-cli は各クラウドプロバイダーのネイティブ CLI のラッパーです。以下のポリシーが全ツール（`awst`, `gcloudt`, `tcclit`）に適用されます。

### 操作の分類と実行方式

操作を以下の3つに分類し、それぞれの実行方式を決定する。単純なコマンド名（create / delete 等）だけで判断せず、可逆性・データ損失・復旧可能性・影響範囲も考慮する。

| 分類 | 通常実行 | `--debug` 時 |
|------|---------|-------------|
| **Read-only**（list, show, get, describe 等） | 直接実行 | コマンド出力のみ |
| **通常の変更**（create, update, restore 等） | 直接実行 | コマンド出力のみ |
| **破壊的・高リスクな変更**（delete, delete --force, terminate 等） | コマンド出力のみ | コマンド出力のみ |

#### Read-only 操作

ネイティブ CLI を直接実行し、結果を整形して表示する。例: 一覧表示、詳細表示、値の取得。

#### 通常の変更操作

ネイティブ CLI を直接実行する。「変更操作だから」という理由だけで dry-run / print-only にはしない。例: リソース作成、設定更新、復元。

#### 破壊的・高リスクな操作（print only）

cloud-cli からは実行せず、実行予定のネイティブ CLI コマンドを標準出力に出力して終了する。cloud-cli 自身はそのコマンドを一切実行しない。ユーザーが出力されたコマンドを確認し、必要に応じて別途実行する。

分類はコマンド名だけで判断せず、以下を考慮する:
- データ損失の可能性
- 不可逆性（`--force` 等の有無）
- 復旧可能性（復旧可能な delete と即時削除は同じ危険度として扱わない）
- 影響範囲
- 既存リソースや設定への重大な影響

### --debug モード

`--debug` は全操作共通の dry-run / command preview とする。操作分類に関係なく、ネイティブ CLI を実行せず、実行予定だったコマンドのみを出力する。

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
awst ec2 stop NAME       # 停止コマンドを出力（print only）
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

# シークレット作成（直接実行）
awst secrets create my-api-key --string "abc123xyz"
awst secrets create my-db-creds --json '{"username":"admin","password":"pass"}'
awst secrets create my-cert --file cert.pem --description "SSL certificate"

# シークレット更新（直接実行）
awst secrets update my-api-key --string "new-value"
awst secrets update my-db-creds --json '{"username":"admin","password":"newpass"}'

# シークレット削除（print only。コマンドを出力して終了）
awst secrets delete NAME             # 30日間の復旧期間付き削除
awst secrets delete NAME --force     # 即時削除（不可逆）
awst secrets restore NAME            # 削除したシークレットを復元（直接実行）
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
gcloudt clb info NAME               # 詳細情報
gcloudt clb certs                   # SSL 証明書一覧（状態: OK / EXPIRING / EXPIRED）
gcloudt clb certs --csv             # SSL 証明書一覧（CSV）
gcloudt clb proxy-certs             # target-https-proxy ごとの証明書紐付けと状態
gcloudt clb proxy-certs --csv       # 同上（CSV）
```

`certs` / `proxy-certs` の STATUS は証明書の有効期限 (`expireTime`) に基づき、
30 日以内に期限切れのものを `EXPIRING`、期限切れ済みのものを `EXPIRED` と表示する。

### Tencent Cloud CLI (`tcclit`)

#### Cloud Virtual Machine (CVM)

```bash
tcclit cvm ls           # インスタンス一覧
tcclit cvm ls --csv     # CSV 形式
tcclit cvm types        # 使用可能なインスタンスタイプ一覧
tcclit cvm start NAME   # インスタンスを起動
tcclit cvm stop NAME    # 停止コマンドを出力（print only）
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

