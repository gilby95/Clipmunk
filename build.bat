@echo off
rem Builds Clipmunk-Setup.exe (the installer to send friends) and Clipmunk-windows.zip (portable copy).
setlocal
cd /d "%~dp0"
if not exist ".venv\Scripts\python.exe" (
  py -3 -m venv .venv || (echo Python 3.10+ is needed & pause & exit /b 1)
)
".venv\Scripts\python.exe" -m pip install --disable-pip-version-check -q -r requirements.txt pyinstaller || (pause & exit /b 1)
call "%~dp0tools\get_ffmpeg.bat" || (pause & exit /b 1)
".venv\Scripts\python.exe" tools\make_icon.py || (pause & exit /b 1)

rem ffmpeg is copied next to the exe afterwards (bundling it makes PyInstaller copy its DLLs twice).
".venv\Scripts\python.exe" -m PyInstaller --noconfirm --clean --windowed --distpath release --name Clipmunk ^
  --icon assets\clipmunk.ico ^
  --exclude-module PySide6.QtWebEngineCore --exclude-module PySide6.QtQuick --exclude-module PySide6.QtQml ^
  --exclude-module PySide6.Qt3DCore --exclude-module PySide6.QtCharts --exclude-module PySide6.QtPdf ^
  --exclude-module tkinter ^
  run_clipdrop.py || (pause & exit /b 1)
robocopy bin release\Clipmunk\bin /E /NFL /NDL /NJH /NJS /NP >nul
if errorlevel 8 (echo Copying ffmpeg failed & pause & exit /b 1)
".venv\Scripts\python.exe" tools\export_channels.py || (pause & exit /b 1)

for /f "delims=" %%v in ('call ".venv\Scripts\python.exe" -c "import clipdrop; print(clipdrop.__version__)"') do set VER=%%v
set "ISCC=%LOCALAPPDATA%\Programs\Inno Setup 6\ISCC.exe"
if not exist "%ISCC%" set "ISCC=%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"
if not exist "%ISCC%" (
  echo Inno Setup isn't installed. Get it with:  winget install JRSoftware.InnoSetup --scope user
  pause & exit /b 1
)
"%ISCC%" /Q /DAppVersion=%VER% installer\Clipmunk.iss || (pause & exit /b 1)

if exist Clipmunk-windows.zip del Clipmunk-windows.zip
powershell -NoProfile -Command "Compress-Archive -Path 'release\Clipmunk' -DestinationPath 'Clipmunk-windows.zip'"
echo.
echo Done. Send Clipmunk-Setup.exe to your friends.
pause
