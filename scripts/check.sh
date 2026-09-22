#!/usr/bin/env bash
# Single entrypoint for format-check, lint, typecheck and tests.
# Usage: scripts/check.sh [fmt|lint|test|all]   (default: all)
# `fmt` rewrites files; the others only verify. Exits non-zero on first failure.
set -uo pipefail
cd "$(dirname "$0")/.."

mode="${1:-all}"
ran=0
# Every tool invocation goes through run(): `set -e` is unreliable inside && / if chains.
run() {
  printf '\n\033[1m==> %s\033[0m\n' "$*" >&2; ran=1
  "$@" || { printf '\n\033[31mFAILED: %s\033[0m\n' "$*" >&2; exit 1; }
}
want() { [[ "$mode" == all || "$mode" == "$1" ]]; }
fmt() { [[ "$mode" == fmt ]]; }
has_script() { [[ -f package.json ]] && jq -e --arg s "$1" '.scripts[$s]' package.json >/dev/null 2>&1; }
tracked() { [[ -n "$(git ls-files "$@" 2>/dev/null | head -1)" ]]; }

# ---- Node ----
if [[ -f package.json ]]; then
  if [[ -f pnpm-lock.yaml ]]; then P=pnpm; elif [[ -f yarn.lock ]]; then P=yarn; else P=npm; fi
  if fmt; then
    if has_script format; then run $P run format; fi
  else
    if want lint && has_script lint; then run $P run lint; fi
    if want lint && has_script typecheck; then run $P run typecheck; fi
    if want test && has_script test; then run $P test; fi
  fi
fi

# ---- Python ----
if [[ -f pyproject.toml ]] || tracked '*.py'; then
  if fmt; then
    run ruff format .; run ruff check --fix .
  else
    if want lint; then run ruff check .; run ruff format --check .; fi
    if want test && { [[ -d tests ]] || tracked '*test_*.py' '*_test.py'; }; then
      if [[ -f pyproject.toml ]]; then run uv run python -m pytest -q; else run python3 -m pytest -q; fi
    fi
  fi
fi

# ---- Rust ----
if [[ -f Cargo.toml ]]; then
  if fmt; then run cargo fmt
  else
    if want lint; then run cargo fmt --check; run cargo clippy --all-targets -q -- -D warnings; fi
    if want test; then run cargo test -q; fi
  fi
fi

# ---- Go ----
if [[ -f go.mod ]]; then
  if fmt; then run gofmt -w .
  else
    if want lint; then run test -z "$(gofmt -l .)"; run go vet ./...; fi
    if want test; then run go test ./...; fi
  fi
fi

# ---- Shell scripts ----
if ! fmt && want lint; then
  mapfile -t sh < <(git ls-files '*.sh' 2>/dev/null; ls scripts/*.sh 2>/dev/null)
  if (( ${#sh[@]} )); then
    for f in $(printf '%s\n' "${sh[@]}" | sort -u); do run bash -n "$f"; done
    if command -v shellcheck >/dev/null; then run shellcheck "${sh[@]}"; fi
  fi
fi

if [[ $ran == 1 ]]; then printf '\n\033[32mOK (%s)\033[0m\n' "$mode" >&2; else echo "nothing to check" >&2; fi
