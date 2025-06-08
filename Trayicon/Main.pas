unit Main;

interface

uses
 System.SysUtils,
 System.Types,
 System.UITypes,
 System.Classes,
 System.Variants,
 FMX.Types,
 FMX.Controls,
 FMX.Forms,
 FMX.Graphics,
 FMX.Dialogs,
 WinTrayIcon,
 FMX.Memo.Types,
 FMX.StdCtrls,
 FMX.Controls.Presentation,
 FMX.ScrollBox,
 FMX.Memo,
 FMX.Edit,
 FMX.Menus;
(*----------------------------------------------------------------------------*)
type
  TForm1 = class(TForm)
    Memo: TMemo;
    Button1: TButton;
    Edit1: TEdit;
    PopupMenu1: TPopupMenu;
    MenuItem1: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure MenuItem1Click(Sender: TObject);
  private
    TrayIcon:  TWinTrayIcon;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation
   uses
   FMX.Platform.Win,
   Winapi.Windows;
{$R *.fmx}

procedure TForm1.Button1Click(Sender: TObject);
begin
  TrayIcon.BalloonTitle:= Edit1.Text;
  TrayIcon.BalloonHint:= Memo.Text;
  TrayIcon.ShowBalloonHint;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  TrayIcon:= TWinTrayIcon.Create(Application.Title);
  TrayIcon.Icon:= LoadIcon(HInstance,'audi') ;
  TrayIcon.BalloonIcon:= TrayIcon.Icon;
  TrayIcon.BalloonFlags:=bfUser;
  TrayIcon.OnMouseUp:= procedure(Sender: TObject;mButton: TMouseButton; sState: TShiftState; P: TPoint)
  begin
    SetForegroundWindow(WindowHandleToPlatform(Handle).Wnd);
    PopupMenu1.Popup(p.X,p.Y)   ;
  end;
  TrayIcon.Visible:= True;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  TrayIcon.Free;
end;

procedure TForm1.MenuItem1Click(Sender: TObject);
begin
  Application.Terminate;
end;

end.
