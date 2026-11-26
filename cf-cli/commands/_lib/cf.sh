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

# cf を実行し stdout を返す。stderr（Loading spinner 等の進行表示）は成功時は
# 非表示、失敗時のみ表示する。-q (--quiet) で result_info 等の非本質出力も抑制する。
_cf_capture() {
  local err_file out rc=0
  err_file=$(mktemp "${TMPDIR:-/tmp}/cft.err.XXXXXX")
  out=$("$CF_BIN" -q "$@" 2>"$err_file") || rc=$?
  if [ "$rc" -ne 0 ]; then
    cat "$err_file" >&2
  fi
  rm -f "$err_file"
  [ "$rc" -eq 0 ] || return "$rc"
  printf '%s\n' "$out"
}

# cf を実行し JSON (stdout) を返す。出力をそのまま使う場合（--json 等）はこちら。
cf_json() {
  cf_debug_exit "$@"
  _cf_capture "$@"
}

# cf list 系コマンドを実行し、item の JSON 配列に正規化して stdout へ返す。
# cf v1.0.0-rc 系は bare JSON 配列を返すが、API envelope ({result: [...]}) 形式も許容する。
cf_list_json() {
  cf_debug_exit "$@"
  _cf_capture "$@" | jq -c 'if type == "array" then . else (.result // []) end'
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
  json="$(cf_list_json tunnels list)"
  # UUID として渡された場合はそのまま採用
  id="$(jq -r --arg n "$name" '.[] | select(.id == $n) | .id' <<<"$json" | head -1)"
  if [[ -n "$id" ]]; then
    echo "$id"
    return 0
  fi
  local matches
  matches="$(jq -r --arg n "$name" '.[] | select(.name == $n) | .id' <<<"$json")"
  local count
  count="$(jq -r --arg n "$name" '.[] | select(.name == $n) | .id' <<<"$json" | grep -c . || true)"
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

# ---------------------------------------------------------------------------
# REST 直接呼び出し (cf CLI が公開していないエンドポイント用・読み取り専用)
# ---------------------------------------------------------------------------

cf_api_base() {
  printf '%s' "${CLOUDFLARE_API_BASE:-https://api.cloudflare.com/client/v4}"
}

cf_rest_curl() {
  printf '%s' "${CLOUD_CLI_CURL:-curl}"
}

# REST 呼び出しには CLOUDFLARE_API_TOKEN が必須（cf auth プロファイルは使えない）。
cf_require_token() {
  if [[ -z "${CLOUDFLARE_API_TOKEN:-}" ]]; then
    echo "CLOUDFLARE_API_TOKEN is required for this subcommand" >&2
    return 1
  fi
}

# cf_rest_get <path> : アカウント REST API (GET) を呼び JSON を stdout へ返す。
cf_rest_get() {
  cf_require_token || return 1
  "$(cf_rest_curl)" -sS -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
    "$(cf_api_base)/$1"
}

# cf_account_id : CLOUDFLARE_ACCOUNT_ID があればそれを、無ければ token の
# アクセスできる最初のアカウント ID を返す。
cf_account_id() {
  if [[ -n "${CLOUDFLARE_ACCOUNT_ID:-}" ]]; then
    printf '%s\n' "$CLOUDFLARE_ACCOUNT_ID"
    return 0
  fi
  cf_rest_get "accounts" | jq -r '.result[0].id // empty'
}
