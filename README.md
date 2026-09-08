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

### Tencent Cloud CLI (`tcclit` / `tccli`)

RHEMS の Tencent Cloud 環境では、顧客アカウントへのアクセスに **CAM ロールのスイッチロール（AssumeRole）** を使います。公式の `tccli` は `~/.tccli/<profile>.credential` に API キーを置く前提なので、そのままでは RHEMS の運用モデルと合いません。

cloud-cli は次の 2 層で Tencent Cloud を扱います。

| コマンド | 役割 |
|----------|------|
| `tcclit` | よく使う操作のサブコマンド（`cvm ls`, `cam me` など） |
| `tccli` | 公式 `tccli` の薄いラッパー（任意の API をそのまま叩く） |

どちらも **Tencent 公式 CLI の実体は変更せず**、必要なとき `tc-assume exec` に委譲して一時認証を取得します。

#### なぜ `tccli` ラッパーが必要か

RHEMS の TC プロジェクト（`cl-workspaces` の `projects/<name>/tc`）では、direnv で `TENCENTCLOUD_PROFILE=<project-name>` が設定されます。各プロジェクトは顧客アカウントの CAM ロール（例: `sw-rhems-aidis-aw`）へスイッチロールする想定です。

公式 `tccli` だけを使うと、次の問題があります。

1. **`~/.tccli/<profile>.credential` が必須になる** — プロファイルごとに API キーを手動管理・更新する必要がある
2. **スイッチロールと相性が悪い** — `tc-assume` で取得した一時認証と、`--profile` による credential 参照が混在しやすい
3. **別プロジェクトの認証が残る** — シェルに `TENCENTCLOUD_SECRET_ID` が残っていると、意図しないアカウントへ接続する恐れがある

ラッパーは `TENCENTCLOUD_PROFILE` が `~/.tc-assume/config` に定義されている場合、**毎回そのプロファイルへ assume してから** 公式 `tccli` を実行します。`~/.tccli/*.credential` は不要です。

#### 認証の流れ

```
direnv (TENCENTCLOUD_PROFILE=aidis-aw)
    ↓
tccli / tcclit ラッパー
    ↓  tc_should_assume() が true
tc-assume exec aidis-aw -- /path/to/real/tccli ...
    ↓  TC_ASSUME_WRAPPED=1, 一時認証を環境変数にセット
公式 tccli (Python) が API 呼び出し
```

判定条件（`_lib/assume.sh`）:

- `TENCENTCLOUD_PROFILE` が設定されている
- `~/.tc-assume/config` に `[profile <name>]` がある
- `TC_ASSUME_WRAPPED` が未設定（再帰防止）

`TENCENTCLOUD_SECRET_ID` の有無は見ません。期限切れや別プロファイルの認証が残っていても、上記を満たせば必ず assume します。

#### PATH の扱い

| 場所 | 使われる `tccli` |
|------|------------------|
| `cl-workspaces` の `projects/*/tc`（direnv 有効） | cloud-cli のラッパー（`tcclit` と同じ `bin/` を PATH 先頭に追加） |
| それ以外 | `~/.local/bin/tccli` など公式 CLI 本体 |

`~/bin` に `tccli` の symlink を置く必要はありません。TC プロジェクトでは `.envrc` が `readlink -f "$(command -v tcclit)"` のディレクトリを PATH に足します。

#### `tc-assume` の設定例

`~/.tc-assume/config` にプロジェクト名と CAM ロールを対応させます（`type = assume_role`）。

```ini
[profile rhems]
type = saml
uin = 200022570412
saml_provider = RHEMS-Google-Workspace
role_arn = qcs::cam::uin/200022570412:roleName/RHEMS-WORKER
# ...

[profile aidis-aw]
type = assume_role
source_profile = rhems
role_arn = qcs::cam::uin/200026321892:roleName/sw-rhems-aidis-aw
region = ap-tokyo
```

`cl-workspaces` で TC プロジェクトに入った状態なら、次のどちらも同じ認証経路になります。

```bash
tccli sts GetCallerIdentity --output json
tcclit cam me
```

TC プロジェクト外で assume したい場合は、明示的にプロファイルを渡します。

```bash
tc-assume exec aidis-aw -- tccli sts GetCallerIdentity
```

#### CAM（認証・権限の確認）

```bash
tcclit cam me          # 現在の caller とロール/ポリシー
tcclit cam account     # アカウントサマリ + AppId
tcclit cam policy ls   # カスタムポリシー一覧
tcclit cam user ls     # サブユーザー一覧
```

`cam me` はロール認証（`CAMRole`）のときロール情報と `ListAttachedRolePolicies`、ユーザー認証のときはユーザー向けポリシーを表示します。

#### Cloud Virtual Machine (CVM)

```bash
tcclit cvm ls           # インスタンス一覧
tcclit cvm ls --csv     # CSV 形式
tcclit cvm types        # 使用可能なインスタンスタイプ一覧
tcclit cvm start NAME   # インスタンスを起動
tcclit cvm stop NAME    # 停止コマンドを出力（print only）
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
    ├── bin/
    │   ├── tcclit    # サブコマンド用エントリーポイント
    │   ├── tccli     # 公式 tccli ラッパー（tc-assume 連携）
    │   ├── _lib/assume.sh
    │   └── _shims/tccli
    └── commands/     # サブコマンド定義
        ├── cam
        ├── cvm
        ├── vpc
        ├── teo
        ├── cdn
        ├── ssl
        └── lb
```

## セキュリティ

セキュリティに関するベストプラクティスや脆弱性の報告方法については、[SECURITY.md](SECURITY.md) を参照してください。

**重要**: このツールは認証情報を保存・管理しません。認証は各クラウドプロバイダーの CLI ツール（`aws`, `gcloud`, `tccli`）および Tencent Cloud の場合は `tc-assume` によって処理されます。

## ライセンス

MIT License - 詳細は [LICENSE](LICENSE) ファイルを参照してください。

