#!/bin/bash
set -uo pipefail

cd "$(dirname "$0")/.."
fail=0

ok()   { echo "ok  - $1"; }
bad()  { echo "FAIL- $1"; fail=1; }

# 1) syntax check em todos os scripts
for f in init.sh lib/*.sh partials/*.sh; do
  [[ -f "$f" ]] || continue
  if bash -n "$f" 2>/dev/null; then ok "bash -n $f"; else bad "bash -n $f"; fi
done

# 2) selecao --dry-run
out=$(./init.sh --dry-run --only node 2>/dev/null | sed 's/^  //' || true)
if grep -qx 'node' <<<"$out" && ! grep -qx 'ghostty' <<<"$out"; then
  ok "--only node seleciona node e exclui ghostty"
else
  bad "--only node"; echo "$out"
fi

out=$(./init.sh --dry-run --core 2>/dev/null | sed 's/^  //' || true)
if grep -qx 'node' <<<"$out" && ! grep -qx 'ghostty' <<<"$out"; then
  ok "--core inclui node e exclui opcional ghostty"
else
  bad "--core"; echo "$out"
fi

out=$(./init.sh --dry-run --full 2>/dev/null | sed 's/^  //' || true)
if grep -qx 'ghostty' <<<"$out"; then
  ok "--full inclui opcional ghostty (mac)"
else
  bad "--full"; echo "$out"
fi

exit $fail
