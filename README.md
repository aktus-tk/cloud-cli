# cloud-cli

クラウドの公式 CLI を、AI Agent と人間が効率よく利用するための薄いラッパー集です。

## 目的

1. AI Agent が必要とする入力コンテキストと出力トークンを削減し、skill から利用しやすい安定したコマンド体系を提供する
2. 人間がよく使う CLI 操作とオプションを短いコマンドにまとめ、必要な情報だけを見やすく整形して出力する
3. 実運用で見つかった頻出操作を継続的に取り込み、人間と AI が共同で育てる運用インターフェースとする

公式 CLI の全機能の再実装や、AWS・GCP・Tencent Cloud の差異を完全に抽象化することは目的としません。定型的で利用頻度が高く、入出力の削減・整形に効く操作だけを提供し、それ以外は `aws` / `gcloud` / `tccli` を直接使います。

実運用を通じてコマンドを増やし skill から再利用するリポジトリです。コマンド追加の判断基準・実行ポリシーの詳細・コード変更時の Agent 向け規則は [AGENTS.md](AGENTS.md) を参照してください。

## 設計方針

skill や人間は短く安定したコマンドを呼び出し、cloud-cli が公式 CLI の複雑なオプションと巨大な生出力を肩代わりし、必要最小限に整形して返します。

```
skill / 人間 → cloud-cli → aws / gcloud / tccli → cloud-cli → 整形済み出力
```

- **入力圧縮**: 長い CLI とオプションを毎回プロンプトに書かせない
- **出力圧縮**: 巨大な JSON を Agent に渡さない
- **知識固定**: よく使う情報取得を skill とコマンドに定着させる

認証や AssumeRole は主目的ではなく、この形で使うための基盤です。

| ツール | 公式 CLI | 主な用途 |
|--------|----------|----------|
| `awst` | `aws` | AWS リソースの一覧・詳細・一部変更 |
| `gcloudt` | `gcloud` / `gsutil` | GCP リソースの一覧・詳細・一部変更 |
| `tcclit` | `tccli` | Tencent Cloud リソースの一覧・詳細・一部変更 |

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

認証の詳細:

- **AWS コンソール (Granted)**: [README_granted.md](README_granted.md)
- **Tencent Cloud (`tccli` / `tc-assume`)**: [README_tccli.md](README_tccli.md)
- **セキュリティ・認証情報の扱い**: [SECURITY.md](SECURITY.md)（本ツールは認証情報を保存しません）

## 共通実行ポリシー

`awst` / `gcloudt` / `tcclit` 共通です。

- **Read-only** 操作と**通常の変更**操作は、ネイティブ CLI を直接実行する
- **破壊的・高リスク**な操作は実行せず、**実行予定コマンドのみ表示（実行しない）**
- **`--debug`** では操作を実行せず、実行予定コマンドのみ表示する
- 分類の詳細（データ損失、不可逆性、秘密情報の露出など）は [AGENTS.md](AGENTS.md) を参照

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
awst ec2 stop NAME       # 実行予定コマンドのみ表示（実行しない）
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

# シークレット削除（実行予定コマンドのみ表示・実行しない）
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

#### EKS

```bash
awst eks list-clusters              # クラスター一覧
awst eks list-clusters --csv        # CSV 形式
awst eks update-kubeconfig NAME     # kubeconfig を更新
awst eks update-kubeconfig NAME --dry-run  # kubeconfig を標準出力に表示
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
gcloudt gce group-instances GROUP # グループのメンバー一覧
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
gcloudt clb addresses               # 予約済み Global/Regional IP 一覧
gcloudt clb ssl-certs               # SSL 証明書（compute、旧方式）
gcloudt clb certificates          # Certificate Manager 証明書一覧
gcloudt clb backend-services        # Backend Service 一覧
gcloudt clb target-proxies          # HTTP/HTTPS Target Proxy 一覧
gcloudt clb cert-maps               # Certificate Manager maps 一覧
gcloudt clb cert-map-entries MAP    # Certificate Manager map のエントリ一覧
```

`certs` / `proxy-certs` の STATUS は証明書の有効期限 (`expireTime`) に基づき、
30 日以内に期限切れのものを `EXPIRING`、期限切れ済みのものを `EXPIRED` と表示する。

#### プロジェクト・ネットワーク・DNS

```bash
gcloudt project describe [PROJECT]  # プロジェクト情報
gcloudt project list                # プロジェクト一覧
gcloudt network ls                  # VPC ネットワーク一覧
gcloudt network subnets             # サブネット一覧
gcloudt network routes              # ルート一覧（簡略化）
gcloudt network routers             # Cloud Router 一覧
gcloudt network nat [ROUTER]        # Cloud NAT 設定
gcloudt dns zones                   # Cloud DNS マネージドゾーン一覧
gcloudt dns records ZONE            # ゾーン内のレコードセット一覧
```

### Tencent Cloud CLI (`tcclit`)

`tccli` ラッパーと `tc-assume` による AssumeRole 認証については [README_tccli.md](README_tccli.md) を参照。

#### CAM（認証・権限の確認）

```bash
tcclit cam me          # 現在の caller とロール/ポリシー
tcclit cam account     # アカウントサマリ + AppId
tcclit cam policy ls   # カスタムポリシー一覧
tcclit cam user ls     # サブユーザー一覧
```

`cam me` はロール認証（`CAMRole`）のときロール情報と `ListAttachedRolePolicies` を表示します。

#### Cloud Virtual Machine (CVM)

```bash
tcclit cvm ls           # インスタンス一覧
tcclit cvm ls --csv     # CSV 形式
tcclit cvm types        # 使用可能なインスタンスタイプ一覧
tcclit cvm start NAME   # インスタンスを起動
tcclit cvm stop NAME    # 実行予定コマンドのみ表示（実行しない）
```

#### Tencent EdgeOne (TEO)

```bash
tcclit teo zones                              # EdgeOne ゾーン一覧
tcclit teo acceleration-domains ZONE_ID       # 加速ドメイン一覧
tcclit teo describe-rules ZONE_ID             # ルールエンジン
```

#### CDN

```bash
tcclit cdn ls                    # CDN ドメイン一覧
tcclit cdn config DOMAIN         # ドメイン設定 (HTTPS 証明書等)
```

#### SSL Certificate

```bash
tcclit ssl search QUERY          # 証明書検索 (ドメイン名・ID)
tcclit ssl show CERT_ID          # 証明書詳細
```

#### Load Balancer (CLB)

```bash
tcclit lb ls                     # ロードバランサー一覧
tcclit lb listeners NAME|ID      # リスナー一覧
tcclit lb rules NAME|ID          # SNI ルール一覧 (ドメイン・証明書 ID)
tcclit lb targets NAME|ID        # バックエンド一覧
```

#### VPC

```bash
tcclit vpc sg                    # セキュリティグループ一覧
```

## プロジェクト構造

各ツールは `bin/<name>` が第1引数で `commands/` 以下の実行可能スクリプトを呼び出します。サブコマンドの一覧は各スクリプトの `help` でも確認できます。

```
cloud-cli/
├── aws-cli/
│   ├── bin/awst
│   ├── commands/     # ec2, eks, iam, secrets, alb, r53, billing, …
│   └── skills/       # ドメイン別 Skill（例: billing）
├── g-cli/
│   ├── bin/gcloudt
│   └── commands/     # gce, firewall, sa, gcs, clb, project, network, dns, …
└── tc-cli/
    ├── bin/          # tcclit, tccli（tc-assume 連携）
    └── commands/     # cam, cvm, vpc, teo, cdn, ssl, lb
```

Agent がコードを変更する際の規則とディレクトリの詳細は [AGENTS.md](AGENTS.md) を参照してください。

## セキュリティ

セキュリティに関するベストプラクティスや脆弱性の報告方法については、[SECURITY.md](SECURITY.md) を参照してください。

**重要**: このツールは認証情報を保存・管理しません。認証は各クラウドプロバイダーの CLI ツール（`aws`, `gcloud`, `tccli`）および Tencent Cloud の場合は `tc-assume` によって処理されます。

## ライセンス

MIT License - 詳細は [LICENSE](LICENSE) ファイルを参照してください。

