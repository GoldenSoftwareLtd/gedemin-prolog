program gd_pl;

uses
  Forms,
  Main in 'MAIN.PAS' {MainForm},
  gsPLClient in 'gsPLClient.pas',
  PLHeader in 'PLHeader.pas',
  PLIntf in 'PLIntf.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'Gedemin-Prolog';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
