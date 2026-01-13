#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

CMD=${NVIM_CMD:-nvim}

exec "$CMD" --headless -u tests/minirc.vim \
  -c "lua require('plenary.test_harness').test_directory('tests', { minimal_init = 'tests/minimal_init.lua' })" \
  -c qa
