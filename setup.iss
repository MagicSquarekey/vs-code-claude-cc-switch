; ============================================================
; Inno Setup 打包脚本
; 生成 VS Code + Claude Code + CC-Switch 一键安装 EXE
; 需要 Inno Setup 6: https://jrsoftware.org/isinfo.php
; 使用: ISCC.exe setup.iss
; ============================================================

#define MyAppName "VS Code + Claude Code + CC-Switch"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "AI Development Tools"
#define MyAppURL "https://github.com/anthropics/claude-code"
#define SourcePath "."

[Setup]
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={tmp}\VSCodeClaudeCCSetup
DisableDirPage=yes
DisableProgramGroupPage=yes
OutputDir={#SourcePath}\output
OutputBaseFilename=Setup-VSCode-Claude-CC
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
; SetupIconFile={#SourcePath}\assets\icon.ico  ; 可选：放置 .ico 文件后取消注释
Uninstallable=no
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0

[Languages]
Name: "chinesesimp"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
; 核心安装脚本
Source: "{#SourcePath}\install.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourcePath}\install.bat"; DestDir: "{app}"; Flags: ignoreversion

; Node.js 安装包
Source: "{#SourcePath}\node-v24.16.0-x64.msi"; DestDir: "{app}"; Flags: ignoreversion deleteafterinstall

; CC-Switch 安装包
Source: "{#SourcePath}\CC-Switch-v3.16.0-Windows.msi"; DestDir: "{app}"; Flags: ignoreversion deleteafterinstall

; 资源文件
Source: "{#SourcePath}\README.md"; DestDir: "{app}"; Flags: ignoreversion

[Run]
; 执行安装脚本
Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -File ""{app}\install.ps1"""; \
    Flags: runascurrentuser waituntilterminated; \
    Description: "正在安装所有组件..."

[Code]
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    // 安装完成后清理
  end;
end;

// 安装完成后的提示
procedure CurPageChanged(CurPageID: Integer);
begin
  if CurPageID = wpFinished then
  begin
    // 所有安装步骤已完成
  end;
end;
