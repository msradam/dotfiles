#!/bin/bash
set -euo pipefail

if command -v uv &>/dev/null; then
    uv python list 2>/dev/null | grep -q "3\.12" || \
        uv python install 3.12 2>&1 | tail -3 || true
fi
