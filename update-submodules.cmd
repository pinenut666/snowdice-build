@echo off
setlocal

git pull --ff-only || exit /b 1
git submodule sync || exit /b 1
git submodule update --init --remote || exit /b 1

git status --porcelain | findstr . >nul
if errorlevel 1 (
  echo No submodule updates
  exit /b 0
)

git add -A || exit /b 1
git commit -m "chore: bump submodules" || exit /b 1
git push || exit /b 1
