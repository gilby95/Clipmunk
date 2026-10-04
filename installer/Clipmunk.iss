; Clipmunk installer. build.bat compiles this into Clipmunk-Setup.exe.
; Installs per-user (no admin prompt) to %LOCALAPPDATA%\Programs\Clipmunk.
;
; The app was called ClipDrop until 1.6. The AppId below never changes, so an existing
; ClipDrop install is upgraded in place (same folder, settings kept), and the old ClipDrop
; shortcuts and exe are removed so nobody ends up with two icons.

#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif

[Setup]
AppId={{6C1E2F4A-8B57-4D0E-9A3C-C11FD7A0B2E5}
AppName=Clipmunk
AppVersion={#AppVersion}
AppVerName=Clipmunk {#AppVersion}
AppPublisher=Clipmunk
DefaultDirName={localappdata}\Programs\Clipmunk
UsePreviousAppDir=yes
DefaultGroupName=Clipmunk
DisableProgramGroupPage=yes
DisableDirPage=yes
DisableReadyPage=yes
PrivilegesRequired=lowest
OutputDir=..
OutputBaseFilename=Clipmunk-Setup
SetupIconFile=..\assets\clipmunk.ico
UninstallDisplayIcon={app}\Clipmunk.exe
UninstallDisplayName=Clipmunk
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
CloseApplications=yes
RestartApplications=no

[Tasks]
Name: "desktopicon"; Description: "Put a Clipmunk icon on my desktop"; GroupDescription: "Shortcuts:"

[Files]
Source: "..\release\Clipmunk\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[InstallDelete]
; clear out the old program files on update (settings live elsewhere and are kept)
Type: filesandordirs; Name: "{app}\_internal"
; leftovers from when the app was called ClipDrop
Type: files; Name: "{app}\ClipDrop.exe"
Type: files; Name: "{autodesktop}\ClipDrop.lnk"
Type: files; Name: "{autoprograms}\ClipDrop.lnk"

[Icons]
Name: "{autoprograms}\Clipmunk"; Filename: "{app}\Clipmunk.exe"
Name: "{autodesktop}\Clipmunk"; Filename: "{app}\Clipmunk.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\Clipmunk.exe"; Description: "Open Clipmunk now"; Flags: nowait postinstall skipifsilent
; in-app updates install silently, then reopen Clipmunk
Filename: "{app}\Clipmunk.exe"; Flags: nowait skipifnotsilent
