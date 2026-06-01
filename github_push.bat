@echo off
setlocal enabledelayedexpansion
title GitHub Push
echo.
echo =============================================
echo   OmniEsol GitHub Push (with Tagging)
echo =============================================
echo.
cd /d "E:\GENAIDEWS\Workspace\OmniEsol_MIG_HTML"
git rev-parse --git-dir >nul 2>&1
if not errorlevel 1 goto ALREADY_INIT
echo [Init] Initializing git repository...
git init
git remote add origin https://github.com/DOUZONEDBA/mig_webform_repo.git
git branch -M main
echo [Init] Done.
echo.
:ALREADY_INIT

:: [Security] Remove HTML webform & .gitignore from git tracking (runs silently if already untracked)
for /f "usebackq tokens=*" %%F in (`git ls-files --cached ^| findstr /i "\.html$"`) do (
    git rm --cached "%%F" >nul 2>&1
)
git rm --cached ".gitignore" >nul 2>&1

set MISSING=0
if not exist "version.json" set MISSING=1
if not exist "version_partner.json" set MISSING=1
if !MISSING!==1 (
    echo [ERROR] Required files not found.
    pause
    exit /b 1
)

echo Target files:
echo   - version.json
echo   - version_partner.json
echo   [SKIP] HTML webform files (security policy)
echo   [SKIP] .gitignore (local only)

:: code_mapping directory file list
set CM_COUNT=0
if exist "code_mapping" (
    for %%F in ("code_mapping\*.json" "code_mapping\*.xlsx" "code_mapping\*.xls") do (
        set /a CM_COUNT+=1
        echo   - code_mapping\%%~nxF
    )
)
if !CM_COUNT!==0 (
    echo   - code_mapping\  [no files - skip]
)
echo.

:: 1. Commit message
set COMMIT_MSG=
set /p COMMIT_MSG=Commit message (Enter=auto): 
if "!COMMIT_MSG!"=="" (
    for /f "tokens=1-3 delims=-/ " %%a in ("%date%") do (
        set D1=%%a& set D2=%%b& set D3=%%c
    )
    for /f "tokens=1-3 delims=:. " %%a in ("%time: =0%") do (
        set T1=%%a& set T2=%%b& set T3=%%c
    )
    set COMMIT_MSG=Update !D1!!D2!!D3!!T1!!T2!!T3!
)

:: 2. Tag name
set TAG_NAME=
echo.
set /p TAG_NAME=Version Tag (Enter=Skip, e.g., v1.0.0): 
echo.

echo [Stage] git add...
git add "version.json"
git add "version_partner.json"

:: code_mapping directory - stage all json + excel files
if exist "code_mapping" (
    for %%F in ("code_mapping\*.json" "code_mapping\*.xlsx" "code_mapping\*.xls") do (
        git add "%%F"
        echo   [Staged] %%F
    )
    git add -u "code_mapping/"
)

git diff --cached --quiet
if not errorlevel 1 (
    echo [Info] No changes to commit.
    pause
    exit /b 0
)
echo.
echo [Commit] !COMMIT_MSG!
git commit -m "!COMMIT_MSG!"
echo.

:: 3. Tag (delete and recreate if exists)
if not "!TAG_NAME!"=="" (
    echo [Tag] Creating tag !TAG_NAME!...
    git tag -d !TAG_NAME! >nul 2>&1
    git tag !TAG_NAME!
    echo [Tag] Tag !TAG_NAME! created.
    echo.
)

:: 4. Push main
echo [Push] Pushing to GitHub...
git push origin main --force
if errorlevel 1 (
    echo [ERROR] Push failed. Check credentials.
    pause
    exit /b 1
)

:: 5. Push tag
if not "!TAG_NAME!"=="" (
    echo [Push] Pushing tag !TAG_NAME! to GitHub...
    git push origin !TAG_NAME! --force
    if errorlevel 1 (
        echo [ERROR] Tag push failed.
        pause
        exit /b 1
    )
)

echo.
echo =============================================
echo   [OK] Push successful!  Commit: !COMMIT_MSG!
if not "!TAG_NAME!"=="" echo   [OK] Tag created and pushed: !TAG_NAME!
echo =============================================
echo.
pause
endlocal