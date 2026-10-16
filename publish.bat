@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM Publish SSHD2382 course site to GitHub Pages.
REM Repo: https://github.com/Lazaruschan/2026-1-SSHD2382-DESIGN-FUNDAMENTALS-Combined-Group-A01-A02-
REM
REM Usage: double-click publish.bat, or from this folder run:
REM   publish.bat
REM
REM Token: set GITHUB_TOKEN first, or paste it when asked.
REM The token is used only for this run. It is not written into this file or the repo.
REM After push: Settings - Pages - Deploy from branch - main / (root)

cd /d "%~dp0"
if /i "%~1"=="--no-pause" set "NO_PAUSE=1"

set "REPO_URL=https://github.com/Lazaruschan/2026-1-SSHD2382-DESIGN-FUNDAMENTALS-Combined-Group-A01-A02-.git"
set "BRANCH=main"
set "REMOTE=origin"
set "PAGES_URL=https://lazaruschan.github.io/2026-1-SSHD2382-DESIGN-FUNDAMENTALS-Combined-Group-A01-A02-/"

echo ==^> Publishing from: %CD%
echo ==^> Target: %REPO_URL%

where git >nul 2>&1
if errorlevel 1 goto :no_git

call :load_token
if errorlevel 1 goto :fail

if not exist ".git" (
  echo ==^> git init
  git init
  if errorlevel 1 goto :fail
)

if exist ".git\rebase-merge" goto :rebase_busy
if exist ".git\rebase-apply" goto :rebase_busy
if exist ".git\MERGE_HEAD" goto :rebase_busy

call :ensure_identity
if errorlevel 1 goto :fail

REM Keep ignore list current
> ".gitignore" (
echo node_modules/
echo .DS_Store
echo *.log
echo *.rtf
echo start.rtf
echo .env
echo .env.*
echo *token*
echo *secret*
echo github-token.txt
echo .slide-stage/
echo .worksheet-stage/
)

del /q /f "start.rtf" "*.rtf" >nul 2>&1

echo ==^> Staging site files only ^(explicit allow-list^)
git add --force -- .gitignore .nojekyll index.html auth.js assets slides publish.sh publish.bat export-slides.sh export-slides.py export-worksheets.py embed-slide-assets.py package.json
if errorlevel 1 goto :fail
if exist "README.md" git add --force -- README.md
if exist "package-lock.json" git add --force -- package-lock.json

REM Never publish secrets / tooling junk
git rm -r --cached --ignore-unmatch -- node_modules >nul 2>&1
git rm -r --cached --ignore-unmatch -- .slide-stage >nul 2>&1
git rm --cached --ignore-unmatch -- start.rtf >nul 2>&1
for %%f in (*.rtf) do git rm --cached --ignore-unmatch -- "%%f" >nul 2>&1

echo ==^> Staged files:
git --no-pager status --short

git diff --cached --quiet
if errorlevel 1 goto :do_commit
git rev-parse HEAD >nul 2>&1
if errorlevel 1 goto :nothing
echo ==^> No new changes; will push existing commits.
goto :after_commit

:do_commit
echo ==^> Committing
git commit -m "Publish SSHD2382 Design Fundamentals course website."
if errorlevel 1 goto :fail

:after_commit
git branch -M "%BRANCH%"
if errorlevel 1 goto :fail

git remote get-url "%REMOTE%" >nul 2>&1
if errorlevel 1 (
  echo ==^> Adding remote %REMOTE%
  git remote add "%REMOTE%" "%REPO_URL%"
) else (
  echo ==^> Updating remote %REMOTE%
  git remote set-url "%REMOTE%" "%REPO_URL%"
)
if errorlevel 1 goto :fail

call :sync_and_push
if errorlevel 1 goto :fail

echo.
echo Done.
echo Enable Pages ^(once^): repo Settings -^> Pages -^> Deploy from branch -^> main / ^(root^)
echo Site URL: %PAGES_URL%
echo Site password: 20262382
call :maybe_pause
exit /b 0

:load_token
if defined GITHUB_TOKEN goto :token_ok
echo.
echo Paste a GitHub personal access token for Lazaruschan.
echo It is not saved. Create one at https://github.com/settings/tokens
set /p "GITHUB_TOKEN=Token: "
if not defined GITHUB_TOKEN (
  echo Error: no token entered.
  exit /b 1
)
:token_ok
exit /b 0

:ensure_identity
git config --get user.name >nul 2>&1
if errorlevel 1 git config user.name "Lazaruschan"
git config --get user.email >nul 2>&1
if errorlevel 1 git config user.email "Lazaruschan@users.noreply.github.com"
exit /b 0

:sync_and_push
set "AUTH=AUTHORIZATION: bearer %GITHUB_TOKEN%"
echo ==^> Checking %REMOTE%
git -c http.extraHeader="%AUTH%" ls-remote "%REPO_URL%" "refs/heads/%BRANCH%" > "%TEMP%\sshd2382-remote.txt"
if errorlevel 1 (
  echo Error: could not reach GitHub. Check the token and that the repo exists.
  del /q /f "%TEMP%\sshd2382-remote.txt" >nul 2>&1
  exit /b 1
)
set "HAS_REMOTE="
for /f "usebackq delims=" %%i in ("%TEMP%\sshd2382-remote.txt") do set "HAS_REMOTE=1"
del /q /f "%TEMP%\sshd2382-remote.txt" >nul 2>&1

if not defined HAS_REMOTE (
  echo ==^> Remote branch is empty. Pushing %BRANCH%.
  goto :do_push
)

echo ==^> Syncing with %REMOTE%/%BRANCH%
git -c http.extraHeader="%AUTH%" fetch "%REMOTE%" "%BRANCH%"
if errorlevel 1 exit /b 1

set "BEHIND=0"
for /f %%i in ('git rev-list --count "HEAD..%REMOTE%/%BRANCH%" 2^>nul') do set "BEHIND=%%i"
if not "!BEHIND!"=="0" (
  echo ==^> Remote is ahead by !BEHIND! commit^(s^); rebasing onto %REMOTE%/%BRANCH%
  git rebase "%REMOTE%/%BRANCH%"
  if errorlevel 1 exit /b 1
)

:do_push
echo ==^> Pushing to %REMOTE%/%BRANCH%
git -c http.extraHeader="%AUTH%" push -u "%REMOTE%" "%BRANCH%"
if errorlevel 1 exit /b 1
exit /b 0

:no_git
echo Error: git is not installed. Install Git for Windows first.
call :maybe_pause
exit /b 1

:rebase_busy
echo Error: git rebase/merge in progress. Finish it ^(git rebase --continue^) or abort ^(git rebase --abort^), then re-run.
call :maybe_pause
exit /b 1

:nothing
echo Error: nothing to commit and no previous commits.
call :maybe_pause
exit /b 1

:fail
echo.
echo Publish failed.
call :maybe_pause
exit /b 1

:maybe_pause
if defined NO_PAUSE exit /b 0
echo %cmdcmdline% | findstr /i /c:"%~nx0" >nul
if not errorlevel 1 pause
exit /b 0
