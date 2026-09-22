# CLAUDE.md

Working agreement for Claude Code in this repo. Keep it short; update it when reality changes.

## Commands (single source of truth)

| Task | Command |
|---|---|
| Install deps (idempotent, auto-runs at session start) | `make setup` |
| Everything CI runs | `make check` |
| Lint / typecheck only | `make lint` |
| Tests only | `make test` |
| Auto-format | `make fmt` |

`scripts/check.sh` auto-detects the stack (Node / Python / Rust / Go / shell) from
`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`. When adding a new stack or
tool, wire it into `scripts/setup.sh` and `scripts/check.sh` — not into ad-hoc docs —
so local, Claude sessions and CI (`.github/workflows/ci.yml`) stay identical.

## Stack defaults (when starting something new)

- Node 22 + pnpm, TypeScript strict. Scripts named `lint`, `typecheck`, `test`, `format`
  are picked up automatically.
- Python 3.11 via `uv` (`pyproject.toml`), `ruff` for lint+format, `pytest` in `tests/`.
- Rust via cargo (`fmt`, `clippy -D warnings`, `test`).

## Workflow rules

- Before every commit: `make check` must pass. Before pushing a CI fix, reproduce the
  failure locally first.
- Small, focused commits. Don't widen a change beyond what was asked.
- Match surrounding code style; no drive-by reformatting of untouched files.
- Never commit secrets; `.env*` is git-ignored and unreadable by Claude (see
  `.claude/settings.json`). Commit a `.env.example` instead.
- Temporary/scratch files go outside the repo.

## Layout

```
.claude/settings.json   permissions allowlist + SessionStart hook (runs scripts/setup.sh)
scripts/setup.sh        dependency install, stack-detecting, idempotent
scripts/check.sh        lint/typecheck/test/fmt entrypoint
Makefile                thin aliases for the scripts
.github/workflows/ci.yml  runs make setup && make check
```
