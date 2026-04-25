#!/bin/bash
set -euo pipefail

git pull --ff-only
git submodule sync --recursive
git submodule update --init --recursive --remote

if [ -z "$(git status --porcelain)" ]; then
  echo "No submodule updates"
  exit 0
fi

git add -A
git commit -m "chore: bump submodules"
git push
