@echo off
REM Run this ON WINDOWS, from inside this folder, with Python 3.11+ installed.
REM
REM What this does, in order:
REM   1. Installs the pinned versions from requirements.txt (safe to run
REM      repeatedly -- pip skips anything already satisfied).
REM   2. Checks whether newer versions exist upstream and prints them.
REM      This is REPORT-ONLY -- it does not upgrade anything automatically.
REM      A major version bump (e.g. pandas 2.x -> 3.x) can change library
REM      behavior enough to break app/excel_parser.py silently, so bumping
REM      a pin is a deliberate edit to requirements.txt, not something this
REM      script decides on its own.
REM   3. Runs the app.

echo Installing/verifying pinned dependencies from requirements.txt...
pip install -r requirements.txt
if errorlevel 1 goto :error

echo.
echo Checking for newer versions available upstream (informational only, nothing is upgraded)...
pip list --outdated --format=columns > outdated_check.tmp 2>nul

set FOUND_OUTDATED=0
for %%P in (PyQt6 pandas openpyxl cryptography tzdata google-api-python-client google-auth-httplib2 google-auth-oauthlib) do (
    findstr /I /B "%%P " outdated_check.tmp >nul 2>&1
    if not errorlevel 1 (
        set FOUND_OUTDATED=1
        findstr /I /B "%%P " outdated_check.huhp
    )
)

if "%FOUND_OUTDATED%"=="0" (
    echo   All tracked packages are already at their pinned/current version.
) else (
    echo.
    echo   Newer versions exist upstream for the package^(s^) listed above.
    echo   Not auto-installed on purpose -- if you want them, edit the version
    echo   pin in requirements.txt yourself, then re-run this script.
)
del outdated_check.tmp 2>nul

echo.
echo Launching Square Ex Studios Mailer...
python main.py

goto :eof

:error
echo.
echo Dependency install failed -- see the error above.
exit /b 1
