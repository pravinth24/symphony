#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

if [ -f .env ]; then
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi

if [ -z "${LINEAR_API_KEY:-}" ]; then
  echo "LINEAR_API_KEY is not set. Add it to ~/code/symphony/elixir/.env" >&2
  exit 1
fi

exec ~/.local/bin/mise exec -- ./bin/symphony \
  --i-understand-that-this-will-be-running-without-the-usual-guardrails \
  ./WORKFLOW.local.md "$@"
