#!/usr/bin/env bash

# cloud-cli ラッパーの実体パス（tc_real_tccli が自分自身を解決しないための基準）
_tc_wrapper_path() {
  local lib_dir bin_dir
  lib_dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
  bin_dir="$(dirname "$lib_dir")"
  printf '%s' "${bin_dir}/tccli"
}

# Tencent 公式 tccli のみを返す。command -v は使わない（PATH 先頭のラッパーを避ける）。
tc_real_tccli() {
  if [[ -n "${CLOUD_CLI_REAL_TCCLI:-}" ]]; then
    printf '%s' "$CLOUD_CLI_REAL_TCCLI"
    return 0
  fi

  local p resolved wrapper
  wrapper="$(_tc_wrapper_path)"
  for p in /usr/local/bin/tccli "${HOME}/.local/bin/tccli"; do
    [[ -x "$p" ]] || continue
    resolved="$(readlink -f "$p")"
    [[ "$resolved" == "$wrapper" ]] && continue
    # ラッパーへの symlink も除外
    [[ "$(head -1 "$resolved" 2>/dev/null)" == "#!/usr/bin/env bash" ]] \
      && grep -q 'tc_should_assume\|TC_ASSUME_WRAPPED' "$resolved" 2>/dev/null \
      && continue
    printf '%s' "$p"
    return 0
  done

  echo "tccli: real tccli not found (/usr/local/bin/tccli or ~/.local/bin/tccli)" >&2
  return 1
}

tc_assume_has_profile() {
  local profile="${1:-}"
  [[ -n "$profile" ]] || return 1
  [[ -f "${HOME}/.tc-assume/config" ]] || return 1
  grep -q "^\[profile ${profile}\]" "${HOME}/.tc-assume/config" 2>/dev/null
}

# TENCENTCLOUD_PROFILE が tc-assume にあり、まだラッパー内でない場合は必ず assume する。
# 環境変数の TENCENTCLOUD_SECRET_ID の有無は見ない（別プロファイルの期限切れ認証を再利用しない）。
tc_should_assume() {
  [[ -n "${TENCENTCLOUD_PROFILE:-}" ]] || return 1
  [[ -z "${TC_ASSUME_WRAPPED:-}" ]] || return 1
  command -v tc-assume >/dev/null 2>&1 || return 1
  tc_assume_has_profile "${TENCENTCLOUD_PROFILE}"
}

tc_assume_exec() {
  local profile="${TENCENTCLOUD_PROFILE:?TENCENTCLOUD_PROFILE is not set}"
  exec env TC_ASSUME_WRAPPED=1 \
    tc-assume exec "$profile" -- "$@"
}
