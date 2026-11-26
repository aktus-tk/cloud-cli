#!/usr/bin/env bash
# cft の fixture テスト。
# stub cf (tests/stub/cf) を PATH に置き、公式 cf の JSON を fixture として再現する。
set -e

cd "$(dirname "$0")"
ROOT="$(dirname "$PWD")"

STUB_DIR="$PWD/stub"
FIXTURES="$PWD/fixtures"

fail=0
pass=0

check() {
  local desc=$1 expected=$2 actual=$3
  if [[ "$actual" == *"$expected"* ]]; then
    pass=$((pass+1))
    echo "ok: $desc"
  else
    fail=$((fail+1))
    echo "FAIL: $desc"
    echo "  expected to contain: $expected"
    echo "  actual: $actual"
  fi
}

run() {
  ( set +e; export CLOUD_CLI_CURL="$STUB_DIR/curl" CLOUDFLARE_API_TOKEN=test-token; PATH="$STUB_DIR:$PATH" "$ROOT/bin/cft" "$@" ) 2>&1
  return 0
}

# tunnel list
out=$(run tunnel list)
check "tunnel list header"   $'Name\tID\tStatus' "$out"
check "tunnel list row"      "prod-tunnel" "$out"

# tunnel list --json
out=$(run tunnel list --json)
check "tunnel list json"     '"prod-tunnel"' "$out"

# tunnel show by name
out=$(run tunnel show prod-tunnel)
check "tunnel show status"   "Status:    healthy" "$out"
check "tunnel show colo"     "nrt01" "$out"

# tunnel show by UUID
out=$(run tunnel show ffffffff-1111-2222-3333-444444444444)
check "tunnel show by uuid"  "Name:      prod-tunnel" "$out"

# tunnel show: unknown name
out=$(run tunnel show no-such-tunnel)
check "tunnel show unknown"  "no tunnel: no-such-tunnel" "$out"

# tunnel status
out=$(run tunnel status prod-tunnel)
check "tunnel status"        "Status:    healthy" "$out"

# tunnel --debug (dry-run, stub を実行しない)
out=$(CLOUD_CLI_CF_BIN=cf PATH="$STUB_DIR:$PATH" CLOUD_CLI_DEBUG=1 "$ROOT/bin/cft" tunnel list)
check "tunnel list debug"    "cf tunnels list" "$out"
if [[ "$out" == *"prod-tunnel"* ]]; then
  fail=$((fail+1)); echo "FAIL: --debug should not execute cf"
else
  pass=$((pass+1)); echo "ok: --debug dry-run"
fi

# route list
out=$(run route list)
check "route list row"       "10.0.0.0/8" "$out"

# gateway list
out=$(run gateway list)
check "gateway list row"     "block-social" "$out"

# gateway list dns (filter)
out=$(run gateway list dns)
check "gateway dns filter"   "force-safe-search" "$out"
check "gateway traffic col"  'dns.fqdn in {"social.example.com"}' "$out"
if [[ "$out" == *"block-social"* ]]; then
  fail=$((fail+1)); echo "FAIL: gateway list dns should filter to dns rules"
else
  pass=$((pass+1)); echo "ok: gateway dns filter excludes http rules"
fi

# gateway list --json
out=$(run gateway list --json)
check "gateway json"         '"block-social"' "$out"

# gateway logs (cf logs query SQL)
out=$(run gateway logs http)
check "gateway logs header"   $'Time\tUser\tAction\tTarget\tStatus' "$out"
check "gateway logs block"    "grok.com/api" "$out"
check "gateway logs action"   "block" "$out"

out=$(run gateway logs http --json)
check "gateway logs json"     '"grok.com/api"' "$out"

out=$(CLOUD_CLI_CF_BIN=cf PATH="$STUB_DIR:$PATH" CLOUD_CLI_DEBUG=1 "$ROOT/bin/cft" gateway logs http --action block)
check "gateway logs debug"    "cf logs query" "$out"

# application list
out=$(run application list)
check "application list row"  "redmine" "$out"

# application logs (REST via stub curl)
out=$(run application logs)
check "application logs header" $'Time\tUser\tApp\tAction\tAllowed\tIP' "$out"
check "application logs row"  "redmine" "$out"

# device list
out=$(run device list)
check "device list row"      "macbook-pro" "$out"

# user list
out=$(run user list)
check "user list row"        "user@example.com" "$out"

# raw delegation
out=$(run raw --help)
check "raw delegation"       "The Cloudflare CLI" "$out"

# unknown command
out=$(run tunnel bogus || true)
check "unknown subcommand"   "unknown tunnel command: bogus" "$out"

echo
echo "pass=$pass fail=$fail"
[[ "$fail" -eq 0 ]]
