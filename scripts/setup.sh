#!/usr/bin/env bash
# Idempotent dependency setup. Detects the stack(s) present and installs deps.
# Run by the SessionStart hook; safe to run by hand any time.
set -euo pipefail
cd "$(dirname "$0")/.."

log() { printf '[setup] %s\n' "$*" >&2; }

# Node: pick the package manager from the lockfile.
if [[ -f package.json ]]; then
  if   [[ -f pnpm-lock.yaml ]]; then log "pnpm install"; pnpm install --frozen-lockfile || pnpm install
  elif [[ -f yarn.lock ]];      then log "yarn install"; corepack enable >/dev/null 2>&1 || true; yarn install
  elif [[ -f package-lock.json ]]; then log "npm ci"; npm ci
  else log "npm install"; npm install
  fi
fi

# Python: prefer uv.
if [[ -f pyproject.toml || -f requirements.txt ]]; then
  if [[ -f uv.lock || -f pyproject.toml ]]; then log "uv sync"; uv sync --all-extras 2>/dev/null || uv sync
  else log "uv pip install -r requirements.txt"; uv venv -q .venv 2>/dev/null || true; uv pip install -q -r requirements.txt
  fi
fi

[[ -f Cargo.toml ]] && { log "cargo fetch"; cargo fetch; }
[[ -f go.mod ]]     && { log "go mod download"; go mod download; }

# Dev tools that check.sh relies on (CI runners have shellcheck preinstalled).
command -v shellcheck >/dev/null || { log "uv tool install shellcheck-py"; uv tool install -q shellcheck-py; }

# Persist the venv on PATH for the rest of the Claude session.
if [[ -d .venv && -n "${CLAUDE_ENV_FILE:-}" ]]; then
  echo "export PATH=\"$PWD/.venv/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi

log "done"
