[Setup]
AppId={{6L903538-42B1-4596-G479-BJ779F21A65D}}
AppVersion={{APP_VERSION}}
AppName=Hiddify
AppPublisher=Hiddify
AppPublisherURL=https://github.com/hiddify/hiddify-next
AppSupportURL=https://github.com/hiddify/hiddify-next
AppUpdatesURL=https://github.com/hiddify/hiddify-next
DefaultDirName={autopf64}\Hiddify
DisableProgramGroupPage=yes
OutputDir=.
OutputBaseFilename=Hiddify-Windows-Setup
Compression=lzma2/ultra64
InternalCompressLevel=ultra
SolidCompression=yes
SetupIconFile=..\..\windows\runner\resources\app_icon.ico
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
CloseApplications=force
RestartApplications=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "portuguese"; MessagesFile: "compiler:Languages\Portuguese.isl"
Name: "turkish"; MessagesFile: "compiler:Languages\Turkish.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: checkedonce
Name: "launchAtStartup"; Description: "{cm:AutoStartProgram,Hiddify}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{{SOURCE_DIR}}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Hiddify"; Filename: "{app}\Hiddify.exe"
Name: "{autodesktop}\Hiddify"; Filename: "{app}\Hiddify.exe"; Tasks: desktopicon
Name: "{userstartup}\Hiddify"; Filename: "{app}\Hiddify.exe"; WorkingDir: "{app}"; Tasks: launchAtStartup

[Run]
Filename: "{app}\Hiddify.exe"; Description: "{cm:LaunchProgram,Hiddify}"; Flags: runascurrentuser nowait postinstall skipifsilent

[Code]
function InitializeSetup(): Boolean;
var
  ResultCode: Integer;
begin
  Exec('taskkill.exe', '/F /IM Hiddify.exe /T', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Exec('net.exe', 'stop HiddifyTunnelService', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Exec('sc.exe', 'delete HiddifyTunnelService', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Result := True;
end;

procedure CurUninstallStepChanged(UintStep: TUninstallStep);
var
  ResultCode: Integer;
begin
  if UintStep = usUninstallProgressForm then
  begin
    Exec('taskkill.exe', '/F /IM Hiddify.exe /T', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    Exec('net.exe', 'stop HiddifyTunnelService', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    Exec('sc.exe', 'delete HiddifyTunnelService', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  end;
end;
