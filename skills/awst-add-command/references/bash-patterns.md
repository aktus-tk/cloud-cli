# bash パターン

## 最小テンプレート

```bash
#!/usr/bin/env bash
set -eo pipefail

sub="${1:-}"
shift || true

usage() {
  cat <<EOF
usage: awst SERVICE <command> [args]

commands:
  resource ls [--csv]
  resource show <name> [--json]

examples:
  awst SERVICE resource ls
  awst SERVICE resource show my-resource
EOF
}

resource_ls_csv() {
  echo "Name,Status"
  aws SERVICE list-things --output json | jq -r '
    .Things[]? | [.Name, .Status] | @tsv
  ' | tr '\t' ','
}

resource_show() {
  local name=""
  local fmt="table"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --json) fmt="json"; shift ;;
      *) [[ -z "$name" ]] && name="$1"; shift ;;
    esac
  done
  [[ -n "$name" ]] || { echo "usage: awst SERVICE resource show <name>" >&2; exit 1; }

  local json
  json="$(aws SERVICE describe-thing --name "$name" --output json)"
  [[ "$fmt" == "json" ]] && { echo "$json" | jq .; return; }
  echo "$json" | jq -r '"Name: \(.Name)", "Status: \(.Status)"'
}

case "$sub" in
  resource)
    rc="${1:-}"; shift || true
    case "$rc" in
      ls|list)
        [[ "$1" == "--csv" ]] && resource_ls_csv || resource_ls_csv | column -s, -t ;;
      show|describe) resource_show "$@" ;;
      *) echo "resource commands:"; echo "  ls [--csv]"; echo "  show <name> [--json]" ;;
    esac ;;
  help|--help|-h|"") usage ;;
  *) echo "unknown command: $sub" >&2; usage >&2; exit 1 ;;
esac
```

## ネスト subcommand（lambda / eventbridge 型）

```
awst lambda function ls
awst lambda alias ls my-fn
```

```bash
case "$sub" in
  function)
    cmd="${1:-}"; shift || true
    case "$cmd" in
      ls|list) ... ;;
      show) ... ;;
    esac ;;
esac
```

## jq 注意

- bash シングルクォート内の jq では `\"` を使わない（`join(", ")` と書く）
- 複数ソースの SG 等は `NetworkInterfaces[].Groups` もマージする
- `@base64d` で UserData をデコード

## エイリアス wrapper

```bash
#!/usr/bin/env bash
exec "$(dirname "$0")/identity-center" "$@"
```
