#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINDIR="${HOME}/.local/bin"

usage() {
  cat <<EOF
Usage: $(basename "$0")

Install awst, gcloudt, and tcclit into ~/.local/bin as symlinks to this repository.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi
if [[ -n "${1:-}" ]]; then
  echo "install.sh: unknown argument: $1" >&2
  usage >&2
  exit 1
fi

canonical_path() {
  local p="$1"
  if [[ -e "$p" ]] || [[ -L "$p" ]]; then
    readlink -f "$p"
  else
    echo "$p"
  fi
}

path_has_bindir() {
  local bindir_canon
  bindir_canon="$(canonical_path "$BINDIR")"
  local IFS=':'
  local entry
  for entry in $PATH; do
    [[ -n "$entry" ]] || continue
    if [[ "$(canonical_path "$entry")" == "$bindir_canon" ]]; then
      return 0
    fi
  done
  return 1
}

is_prior_cloud_cli_link() {
  local name="$1"
  local dest="$2"
  local target
  target="$(readlink "$dest" 2>/dev/null || true)"
  [[ -n "$target" ]] || return 1
  case "$name" in
    awst) [[ "$target" == *"/aws-cli/bin/awst" ]] ;;
    gcloudt) [[ "$target" == *"/g-cli/bin/gcloudt" ]] ;;
    tcclit) [[ "$target" == *"/tc-cli/bin/tcclit" ]] ;;
    *) return 1 ;;
  esac
}

install_link() {
  local name="$1"
  local rel="$2"
  local source="${REPO_ROOT}/${rel}"
  local dest="${BINDIR}/${name}"

  if [[ ! -f "$source" ]]; then
    echo "install.sh: expected file not found: $source" >&2
    exit 1
  fi

  local expected
  expected="$(canonical_path "$source")"

  if [[ -L "$dest" ]]; then
    local current
    current="$(readlink -f "$dest" 2>/dev/null || true)"
    if [[ "$current" == "$expected" ]]; then
      return 0
    fi
    if is_prior_cloud_cli_link "$name" "$dest"; then
      ln -sfn "$source" "$dest"
      return 0
    fi
    echo "install.sh: ${dest} is a symlink to an unexpected target (not updating)" >&2
    exit 1
  fi

  if [[ -e "$dest" ]]; then
    echo "install.sh: ${dest} exists and is not a symlink (not overwriting)" >&2
    exit 1
  fi

  ln -s "$source" "$dest"
}

mkdir -p "$BINDIR"

install_link awst aws-cli/bin/awst
install_link gcloudt g-cli/bin/gcloudt
install_link tcclit tc-cli/bin/tcclit

if ! path_has_bindir; then
  echo "install.sh: warning: ${BINDIR} is not on PATH" >&2
  echo "install.sh: add to your shell rc, for example:" >&2
  echo '  export PATH="$HOME/.local/bin:$PATH"' >&2
fi

echo "install.sh: installed awst, gcloudt, tcclit into ${BINDIR}"
