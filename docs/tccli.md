# tccli ラッパー / tc-assume 連携

Tencent Cloud へのアクセスは **CAM ロールの AssumeRole のみ** で行います。`~/.tccli/<profile>.credential` に API キーを置く運用は想定していません。

cloud-cli は次の 2 層で Tencent Cloud を扱います。

| コマンド | 役割 |
|----------|------|
| `tcclit` | よく使う操作のサブコマンド（`cvm ls`, `cam me` など） |
| `tccli` | 公式 `tccli` の薄いラッパー（任意の API をそのまま叩く） |

どちらも **Tencent 公式 CLI の実体は変更せず**、`tc-assume` 経由で一時認証を取得してから実行します。

## 構成の要点

1. **認証は AssumeRole だけ** — ベースプロファイル（SAML 等）から各アカウントの CAM ロールへチェーンする
2. **credential ファイルは使わない** — `~/.tccli/*.credential` は不要。プロファイル定義は `~/.tc-assume/config` に集約する
3. **プロファイル名でアカウントを切り替える** — 作業ディレクトリで `TENCENTCLOUD_PROFILE=<name>` を設定し、対応するロールへ assume する

## なぜ `tccli` ラッパーが必要か

公式 `tccli` だけを使うと、`--profile` が `~/.tccli/<profile>.credential` を参照する前提になり、AssumeRole 運用と混在します。またシェルに残った `TENCENTCLOUD_SECRET_ID` を再利用すると、別アカウントへ接続する恐れがあります。

ラッパーは `TENCENTCLOUD_PROFILE` が `~/.tc-assume/config` にある場合、**毎回そのプロファイルへ assume してから** 公式 `tccli` を実行します。

## 認証の流れ

```
TENCENTCLOUD_PROFILE=project-a
    ↓
tccli / tcclit ラッパー
    ↓  tc_should_assume() が true
tc-assume exec project-a -- /path/to/real/tccli ...
    ↓  TC_ASSUME_WRAPPED=1, 一時認証を環境変数にセット
公式 tccli (Python) が API 呼び出し
```

判定条件（`_lib/assume.sh`）:

- `TENCENTCLOUD_PROFILE` が設定されている
- `~/.tc-assume/config` に `[profile <name>]` がある
- `TC_ASSUME_WRAPPED` が未設定（再帰防止）

`TENCENTCLOUD_SECRET_ID` の有無は見ません。期限切れや別プロファイルの認証が残っていても、上記を満たせば必ず assume します。

## PATH の扱い

| 場所 | 使われる `tccli` |
|------|------------------|
| `TENCENTCLOUD_PROFILE` を設定した作業ディレクトリ（direnv 等） | cloud-cli のラッパー（`tcclit` と同じ `bin/` を PATH 先頭に追加） |
| それ以外 | `~/.local/bin/tccli` など公式 CLI 本体 |

`~/bin` に `tccli` の symlink を置く必要はありません。作業ディレクトリの `.envrc` などで `readlink -f "$(command -v tcclit)"` のディレクトリを PATH に足すと、生の `tccli` コマンドもラッパー経由になります。

## `tc-assume` の設定例

`~/.tc-assume/config` にベース認証と、各アカウント向けの `assume_role` を定義します。

```ini
# ベース認証（SAML / 既存の長期認証など）
[profile base]
type = saml
uin = 200000000001
saml_provider = example-idp
role_arn = qcs::cam::uin/200000000001:roleName/operator
region = ap-tokyo

# 顧客アカウント A
[profile project-a]
type = assume_role
source_profile = base
role_arn = qcs::cam::uin/200000000002:roleName/switch-role-project-a
region = ap-tokyo

# 顧客アカウント B
[profile project-b]
type = assume_role
source_profile = base
role_arn = qcs::cam::uin/200000000003:roleName/switch-role-project-b
region = ap-tokyo
```

`TENCENTCLOUD_PROFILE` を設定した状態では、次のどちらも同じ認証経路になります。

```bash
export TENCENTCLOUD_PROFILE=project-a
tccli sts GetCallerIdentity --output json
tcclit cam me
```

プロファイル未設定のシェルから実行する場合は、明示的に渡します。

```bash
tc-assume exec project-a -- tccli sts GetCallerIdentity
```

## 実装ファイル

```
tc-cli/bin/
├── tcclit          # サブコマンド用エントリーポイント（ラッパー経由で公式 tccli を呼ぶ）
├── tccli           # 公式 tccli ラッパー（tc-assume 連携）
├── _lib/assume.sh  # assume 判定・実行の共通ロジック
└── _shims/tccli    # 公式 tccli 呼び出し用シム
```
