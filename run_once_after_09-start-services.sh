#!/bin/bash
set -euo pipefail

yabai --restart-service 2>/dev/null || true
