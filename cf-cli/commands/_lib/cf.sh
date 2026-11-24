#!/usr/bin/env bash
# Shared helpers for cft subcommands (thin wrapper around the official cf CLI).

# cf 本体。既存の環境変数 (CLOUDFLARE_API_TOKEN 等) と cf auth プロファイルを尊重する。
CF_BIN="${CLOUD_CLI_CF_BIN:-cf}"

# --debug (CLOUD_CLI_DEBUG=1) 時はネイティブ CLI を実行せず、実行予定コマンドのみ表示する。
# 秘密情報 (CLOUDFLARE_API_TOKEN 等) は環境変数から読むため表示されない。
# パイプラインの外（関数冒頭）で呼ぶこと。
cf_debug_exit() {
  if [[ "${CLOUD_CLI_DEBUG:-0}" == "1" ]]; then
    echo "cf $*"
    exit 0
  fi
}

# cf を実行し JSON (stdout) を返す。出力をそのまま使う場合（--json 等）はこちら。
cf_json() {
  cf_debug_exit "$@"
  "$CF_BIN" "$@"
}

# JSON をテーブル (column) で整形して出力する
# 引数: JSON文字列 を jq に渡す関数呼び出しと組み合わせて使う
cf_table() {
  column -t -s $'\t'
}

# 名前または UUID からトンネル ID を解決する
#   完全一致が 1 件 → ID を出力
#   0 件 / 複数件   → エラー (stderr) して exit 1
tunnel_get_id() {
  local name=$1
  local json id
  json="$(cf_json tunnels list)"
  # UUID として渡された場合はそのまま採用
  id="$(jq -r --arg n "$name" '.result[]? | select(.id == $n) | .id' <<<"$json" | head -1)"
  if [[ -n "$id" ]]; then
    echo "$id"
    return 0
  fi
  local matches
  matches="$(jq -r --arg n "$name" '.result[]? | select(.name == $n) | .id' <<<"$json")"
  local count
  count="$(jq -r --arg n "$name" '.result[]? | select(.name == $n) | .id' <<<"$json" | grep -c . || true)"
  if [[ "$count" -eq 0 ]]; then
    echo "no tunnel: $name" >&2
    exit 1
  elif [[ "$count" -gt 1 ]]; then
    echo "ambiguous tunnel name: $name (matched $count tunnels)" >&2
    echo "$matches" | sed 's/^/  /' >&2
    exit 1
  fi
  echo "$matches"
}

# CSV 安全出力用の簡易 @tsv ラッパー
cf_csv() {
  jq -r '.[] | @csv'
}
