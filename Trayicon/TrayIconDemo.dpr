program TrayIconDemo;

{$R *.dres}

uses
  System.StartUpCopy,
  FMX.Forms,
  Main in 'Main.pas' {Form1},
  WinTrayIcon in 'WinTrayIcon.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
