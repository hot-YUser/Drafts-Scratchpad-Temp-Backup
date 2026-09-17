@echo off
chcp 932 >nul
setlocal
rem ---- find the WORKING installer engine (the 1,229,312-byte build from the base-game disc) ----
set "ENG="
for /f "delims=" %%F in ('dir /b /s /a-d "C:\Users\YUser\Downloads\BGIForInstalling.exe" 2^>nul') do (
  for %%Z in ("%%~fF") do if %%~zZ EQU 1229312 set "ENG=%%~fF"
)
rem ---- find the mounted EXTRA1 disc folder (any drive E:..K: that has BGIForInstalling.exe) ----
set "SRC="
for %%L in (E F G H I J K) do if not defined SRC if exist "%%L:\" for /d %%D in ("%%L:\*") do if not defined SRC if exist "%%~fD\BGIForInstalling.exe" set "SRC=%%~fD"

if /i "%~1"=="--check" (
  if defined SRC (echo CHECK: source folder OK) else (echo CHECK: source folder NOT FOUND ^(mount the ISO first^))
  if defined ENG (echo CHECK: working engine OK) else (echo CHECK: working engine NOT FOUND)
  if exist "%SRC%\BGIForInstalling.exe" echo CHECK: source exe OK
  exit /b 0
)
if not defined SRC  ( echo [x] No mounted EXTRA1 disc found ^(looked at E:..K:^). Mount the ISO first. & pause & exit /b 1 )
if not defined ENG  ( echo [x] Working installer engine not found under Downloads. & pause & exit /b 1 )
tasklist | findstr /i "bgi0" >nul && ( echo [!] An installer is already running - close it first. & pause & exit /b 1 )
copy /y "%ENG%" "%TEMP%\bgi00001.exe" >nul || ( echo [x] Copy failed & pause & exit /b 1 )
echo Starting EXTRA1 installer ...
start "" /d "%TEMP%" "%TEMP%\bgi00001.exe" "%SRC%" "Execute as a launcher."
exit /b 0
