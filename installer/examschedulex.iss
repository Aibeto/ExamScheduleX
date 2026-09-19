; [gen] ExamScheduleX 安装器脚本
; 构建：installer\build.ps1（web 产物 → flutter release → ISCC 编译）
; UI 已回退为 Inno Setup 7 默认外观（无自定义主题）

#define MyAppName "ExamScheduleX"
#define MyAppExeName "examschedulex.exe"
#define MyAppVersion GetVersionNumbersString("..\build\windows\x64\runner\Release\examschedulex.exe")

[Setup]
AppId={{7E2C5F3A-9B41-4D6E-8A20-C58F1B2E6D77}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName}
AppPublisher=ExamScheduleX
UninstallDisplayName={#MyAppName}
UninstallDisplayIcon={app}\{#MyAppExeName}
DefaultDirName={localappdata}\Programs\ExamScheduleX
DefaultGroupName={#MyAppName}
PrivilegesRequired=lowest
DisableProgramGroupPage=yes
DisableWelcomePage=yes
ShowLanguageDialog=no
Compression=lzma2/ultra
SolidCompression=yes
OutputDir=..\dist
OutputBaseFilename=ExamScheduleX-Setup-{#MyAppVersion}
SetupIconFile=..\windows\runner\resources\app_icon.ico

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加任务："; Flags: checkedonce
Name: "startmenu"; Description: "创建开始菜单快捷方式"; GroupDescription: "附加任务："; Flags: checkedonce

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
; 开始菜单与桌面快捷方式均由任务勾选控制
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; Tasks: startmenu
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "启动 ExamScheduleX"; Flags: nowait postinstall skipifsilent