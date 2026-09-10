---
name: awst-billing
description: awst で AWS 請求情報を取得するときに使う。Cost Explorer API (aws ce) のラッパー。月間サービス別請求 (monthly) と日別推移 (daily) を提供。
---

# awst billing

`awst billing` は AWS Cost Explorer 経由でプロジェクトの請求情報を取得するサブコマンド。

## 使い方

```bash
awst billing monthly 2026 7                # 表形式（デフォルト）
awst billing daily 2026 7                  # 日別推移
awst billing monthly 2026 7 --csv          # CSV 出力
awst billing monthly 2026 7 --json         # JSON 出力
awst billing monthly 2026 7 --service 'Amazon EC2'  # 特定サービスに絞る
```

## 出力の意味

| メトリクス | 用途 |
|-----------|------|
| **Amount** (サービス別) | `NetUnblendedCost`。税前のオンデマンド実質価格。 |
| **Subtotal (pre-tax)** | サービス別 Amount の合計（Tax を除く） |
| **Tax** | `NetUnblendedCost` 上の消費税 |
| **Invoice Total (BlendedCost)** | 別途グループ化なしで取得した `BlendedCost`。AWS 請求書の総計に最も近い値（約 $0.06 差で一致） |

## なぜこの仕組みか（Cost Explorer の制約）

- **サービス別（グループ化あり）で `BlendedCost` は使えない。** AWS は BlendedCost をサービス別に正しく分配しない（グループ化の合計 ≠ 全体の Total）。全体の Total とずれる。
- **`NetUnblendedCost` はサービス別に正確に内訳が出る** が、RI/SP 割引や Marketplace の扱いが請求書と完全一致しない。
- そのため、**サービス内訳は `NetUnblendedCost`、総計はグループ化なしの `BlendedCost` で別クエリ** している。

## Cost Explorer の公式な分類とズレの詳細

- **サービス別の表示** (`NetUnblendedCost`): API 上の全サービス料金をそのまま合算（Tax, Marketplace 含む）。RI/SP 割引の配分前。
- **請求書の総計** (`BlendedCost`, グループ化なし): AWS 請求書の「総計」にほぼ一致。RI/SP 割引適用後の最終額。
- **丸め誤差**: `BlendedCost` と実際の請求書の間で $0.01〜$0.06 程度の差が生じることがある。これは AWS 側の請求計算の丸め方と API のメトリクス計算のわずかな差による。
- **Tax**: 消費税は `NetUnblendedCost` 上では「Tax」というサービス名で別レコードとして表示される。request 書の税額とも一致しない場合がある（AWS の税計算が API とは独立しているため）。
- **Marketplace**: API 上は通常のサービスとして表示され、請求書上は別プロバイダー行として分離される。

## 実装ファイル

`aws-cli/commands/billing`

## 注意

- 課金情報が API に出るまでに 24〜48 時間の遅延がある。直近数日の数値は暫定値（`Estimated: true`）。
- `--debug` を付けると `aws ce` コマンドだけが表示され、API は実行されない。