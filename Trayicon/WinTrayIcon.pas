unit WinTrayIcon;

(*
    此为Windows下 FMX 框架下的托盘工具
    当然也可以在VCL使用
    修改自 TTrayIcon 让其可以在FMX使用

    Github: https://github.com/Icy2010/winTrayIcon
    blog: https://zelig.cn
    Delphi 交流群: 118195948
*)

interface
uses
System.SysUtils,
System.Classes,
System.UITypes,
Winapi.ShellAPI,
Winapi.Messages,
Winapi.Windows;

(*----------------------------------------------------------------------------*)

const
  WM_SYSTEM_TRAY_MESSAGE = WM_USER + 1;

type
TBalloonFlags = (bfNone = NIIF_NONE, bfInfo = NIIF_INFO, bfWarning = NIIF_WARNING, bfError = NIIF_ERROR,bfUser = NIIF_USER);
TMouseButton = System.UITypes.TMouseButton;
TOnMouseEvent = TProc<TObject,TMouseButton,TShiftState,TPoint> ;
TOnMouseMoveEvent = TProc<TObject,TShiftState,TPoint>;
TOnNotifyEvent = TProc<TObject>;

{$IFDEF CLR}[RootDesignerSerializerAttribute('', '', False)]{$ENDIF}
TWinTrayIcon = class(TPersistent)
private
  class var
    RM_TaskbarCreated: DWORD;
private
  FBalloonHint: string;
  FBalloonTitle: string;
  FBalloonFlags: TBalloonFlags;
  FIsClicked,
  FSound:         Boolean;
{$IF DEFINED(CLR)}
  FData: TNotifyIconData;
{$ELSE}
  FData: PNotifyIconData;
{$ENDIF}
  FHint: String;
  FVisible: Boolean;
  FOnBalloonClick: TOnNotifyEvent;
  FOnClick: TOnNotifyEvent;
  FOnDblClick: TOnNotifyEvent;
  FOnMouseDown: TOnMouseEvent;
  FOnMouseMove: TOnMouseMoveEvent;
  FOnMouseUp: TOnMouseEvent;
  function GetData: PNotifyIconData;
  procedure SetBalloonIcon(const Value: HIcon);
  function GetIcon: HIcon;
  function GetBalloonIcon: HIcon;
  procedure SetTitle(const Value: string);
  function GetTitle: string;
protected
  procedure SetHint(const Value: string);
  procedure SetBalloonHint(const Value: string);
  function GetBalloonTimeout: Integer;
  procedure SetBalloonTimeout(Value: Integer);
  procedure SetBalloonTitle(const Value: string);
  procedure SetVisible(Value: Boolean); virtual;
  procedure SetIcon(Value: HIcon);
  procedure WindowProc(var Message: TMessage); virtual;
  property Data: PNotifyIconData read GetData;
  function Refresh(Message: Integer): Boolean; overload;
public
  constructor Create(const szTitle: string); virtual;
  destructor Destroy; override;
  procedure Refresh; overload;
  procedure SetDefaultIcon;
  procedure ShowBalloonHint; virtual;
  property Hint: string read FHint write SetHint;
  property BalloonHint: string read FBalloonHint write SetBalloonHint;
  property BalloonTitle: string read FBalloonTitle write SetBalloonTitle;
  property BalloonTimeout: Integer read GetBalloonTimeout write SetBalloonTimeout default 10000;
  property BalloonFlags: TBalloonFlags read FBalloonFlags write FBalloonFlags default bfNone;
  property BalloonIcon: HIcon read GetBalloonIcon write SetBalloonIcon;
  property Icon: HIcon read GetIcon write SetIcon;
  property Visible: Boolean read FVisible write SetVisible default False;
  property Sound: Boolean read FSound write FSound default False;
  property OnBalloonClick: TOnNotifyEvent read FOnBalloonClick write FOnBalloonClick;
  property OnClick: TOnNotifyEvent read FOnClick write FOnClick;
  property OnDblClick: TOnNotifyEvent read FOnDblClick write FOnDblClick;
  property OnMouseMove: TOnMouseMoveEvent read FOnMouseMove write FOnMouseMove;
  property OnMouseUp: TOnMouseEvent read FOnMouseUp write FOnMouseUp;
  property OnMouseDown: TOnMouseEvent read FOnMouseDown write FOnMouseDown;
  property Title: string read GetTitle write SetTitle;
end;

implementation


{ TWinTrayIcon }

constructor TWinTrayIcon.Create;
begin
{$IF NOT DEFINED(CLR)}
  New(FData);
{$ENDIF}
  FBalloonFlags:= bfNone;
  BalloonTimeout:= 10000;
  FSound:= True;

{$IF DEFINED(CLR)}
    FData.cbSize := Marshal.SizeOf(FData);
    FData.Wnd := AllocateHwnd(WindowProc);
    FData.szTip := Application.Title;
{$ELSE}
    FillChar(FData^, SizeOf(FData^), 0);
    FData^.cbSize := FData^.SizeOf; // Use SizeOf method to get platform specific size
    FData^.Wnd := AllocateHwnd(WindowProc);
    StrPLCopy(FData^.szTip, szTitle, Length(FData^.szTip) - 1);
{$ENDIF}
    FData.uID := FData.Wnd;
    FData.uTimeout := 5000;
    FData.uFlags:= NIF_ICON or NIF_MESSAGE;
    FData.uCallbackMessage := WM_SYSTEM_TRAY_MESSAGE;
    if Length(szTitle) > 0 then
       FData.uFlags := FData.uFlags or NIF_TIP;
    Refresh;
end;

destructor TWinTrayIcon.Destroy;
begin
  Refresh(NIM_DELETE);
  DeallocateHWnd(FData.Wnd);
{$IF NOT DEFINED(CLR)}
  Dispose(FData);
{$ENDIF}
  inherited;
end;

procedure TWinTrayIcon.SetVisible(Value: Boolean);
begin
  if FVisible <> Value then
  begin
    FVisible:= Value;

    if FVisible then
      Refresh(NIM_ADD)
    else if not Refresh(NIM_DELETE) then
    raise EOutOfResources.Create('移除系统托盘失败');
  end;
end;


procedure TWinTrayIcon.SetHint(const Value: string);
begin
  if CompareStr(FHint, Value) <> 0 then
  begin
    FHint := Value;
{$IF DEFINED(CLR)}
    FData.szTip:= Hint;
{$ELSE}
    StrPLCopy(FData.szTip, FHint, Length(FData.szTip) - 1);
{$ENDIF}
    if Length(Hint) > 0 then
      FData.uFlags := FData.uFlags or NIF_TIP
    else
      FData.uFlags := FData.uFlags and not NIF_TIP;
    Refresh;
  end;
end;

{$IFDEF CLR}[SecurityPermission(SecurityAction.InheritanceDemand, UnmanagedCode=True)]{$ENDIF}
procedure TWinTrayIcon.WindowProc(var Message: TMessage);

  { Return the state of the shift keys. }
  function ShiftState: TShiftState;
  begin
    Result := [];
    if GetKeyState(VK_SHIFT) < 0 then
      Include(Result, ssShift);
    if GetKeyState(VK_CONTROL) < 0 then
      Include(Result, ssCtrl);
    if GetKeyState(VK_MENU) < 0 then
      Include(Result, ssAlt);
  end;

var
  Point: TPoint;
  Shift: TShiftState;
begin
  case Message.Msg of
    WM_QUERYENDSESSION: Message.Result := 1;
    WM_ENDSESSION:
      if TWmEndSession(Message).EndSession then
        Refresh(NIM_DELETE);
    WM_SYSTEM_TRAY_MESSAGE:
      begin
        case Int64(Message.lParam) of
          WM_MOUSEMOVE:
            if Assigned(FOnMouseMove) then
            begin
              Shift := ShiftState;
              GetCursorPos(Point);
              FOnMouseMove(Self, Shift,Point);
            end;
          WM_LBUTTONDOWN:
            begin
              if Assigned(FOnMouseDown) then
              begin
                Shift := ShiftState + [ssLeft];
                GetCursorPos(Point);
                FOnMouseDown(Self, TMouseButton.mbLeft, Shift, Point);
              end;
              FIsClicked := True;
            end;
          WM_LBUTTONUP:
            begin
              Shift := ShiftState + [ssLeft];
              GetCursorPos(Point);
              if FIsClicked and Assigned(FOnClick) then
              begin
                FOnClick(Self);
                FIsClicked := False;
              end;
              if Assigned(FOnMouseUp) then
                FOnMouseUp(Self, TMouseButton.mbLeft, Shift, Point);
            end;
          WM_RBUTTONDOWN:
            if Assigned(FOnMouseDown) then
            begin
              Shift := ShiftState + [ssRight];
              GetCursorPos(Point);
              FOnMouseDown(Self, TMouseButton.mbRight, Shift, Point);
            end;
          WM_RBUTTONUP:
            begin
              Shift := ShiftState + [ssRight];
              GetCursorPos(Point);
              if Assigned(FOnMouseUp) then
                FOnMouseUp(Self, TMouseButton.mbRight, Shift, Point);
            end;
          WM_LBUTTONDBLCLK, WM_MBUTTONDBLCLK, WM_RBUTTONDBLCLK:
            if Assigned(FOnDblClick) then
              FOnDblClick(Self);
          WM_MBUTTONDOWN:
            if Assigned(FOnMouseDown) then
            begin
              Shift := ShiftState + [ssMiddle];
              GetCursorPos(Point);
              FOnMouseDown(Self, TMouseButton.mbMiddle, Shift, Point);
            end;
          WM_MBUTTONUP:
            if Assigned(FOnMouseUp) then
            begin
              Shift := ShiftState + [ssMiddle];
              GetCursorPos(Point);
              FOnMouseUp(Self, TMouseButton.mbMiddle, Shift, Point);
            end;
          NIN_BALLOONHIDE, NIN_BALLOONTIMEOUT:
            FData.uFlags := FData.uFlags and not NIF_INFO;
          NIN_BALLOONUSERCLICK:
            if Assigned(FOnBalloonClick) then
              FOnBalloonClick(Self);
        end;
      end;
  else
    if (Cardinal(Message.Msg) = RM_TaskBarCreated) and Visible then
      Refresh(NIM_ADD);
  end;
end;

procedure TWinTrayIcon.Refresh;
begin
  if Visible then
    Refresh(NIM_MODIFY);
end;

function TWinTrayIcon.Refresh(Message: Integer): Boolean;
begin
  Result:= Shell_NotifyIcon(Message, FData);
end;

procedure TWinTrayIcon.SetIcon(Value: HIcon);
begin
  FData.hIcon:= Value;
  Refresh;
end;

procedure TWinTrayIcon.SetTitle(const Value: string);
begin
  FillChar(FData^.szTip,Length(FData^.szTip),#0);
  StrPLCopy(FData^.szTip, Value, Length(FData^.szTip) - 1);
end;

procedure TWinTrayIcon.SetBalloonHint(const Value: string);
begin
  if CompareStr(FBalloonHint, Value) <> 0 then
  begin
    FBalloonHint := Value;
{$IF DEFINED(CLR)}
    FData.szInfo:= FBalloonHint;
{$ELSE}
    StrPLCopy(FData.szInfo, FBalloonHint, Length(FData.szInfo) - 1);
{$ENDIF}
    Refresh(NIM_MODIFY);
  end;
end;

procedure TWinTrayIcon.SetBalloonIcon(const Value: HIcon);
begin
  if FData.hBalloonIcon <> value then
  begin
    FData.hBalloonIcon:= Value;
    Refresh;
  end;
end;

procedure TWinTrayIcon.SetDefaultIcon;
begin
  Refresh;
end;

procedure TWinTrayIcon.SetBalloonTimeout(Value: Integer);
begin
  FData.uTimeout := Value;
end;

function TWinTrayIcon.GetTitle: string;
begin
  Result:= StrPas(FData^.szTip);
end;

function TWinTrayIcon.GetBalloonIcon: HIcon;
begin
  Result:= FData.hBalloonIcon;
end;

function TWinTrayIcon.GetBalloonTimeout: Integer;
begin
  Result := FData.uTimeout;
end;

function TWinTrayIcon.GetData: PNotifyIconData;
begin
  Result:= {$IFDEF CLR}@{$ENDIF}FData;
end;

function TWinTrayIcon.GetIcon: HIcon;
begin
  Result:= FData.hIcon;
end;

procedure TWinTrayIcon.ShowBalloonHint;
begin
  FData.uFlags := FData.uFlags or NIF_INFO;
  case FBalloonFlags of
    bfInfo,
    bfError,
    bfWarning: FData.dwInfoFlags := Cardinal(FBalloonFlags);
    bfUser:
    begin
      if  FData.hBalloonIcon = 0  then
        FData.dwInfoFlags:= NIIF_NONE
      else
      FData.dwInfoFlags:= NIIF_USER or NIIF_LARGE_ICON;

      if not Sound then
         FData.dwInfoFlags:= FData.dwInfoFlags or NIIF_NOSOUND;
    end
  else
    FData.dwInfoFlags:= NIIF_NONE;
  end;

  Refresh(NIM_MODIFY);
end;

procedure TWinTrayIcon.SetBalloonTitle(const Value: string);
begin
  if CompareStr(FBalloonTitle, Value) <> 0 then
  begin
    FBalloonTitle := Value;
{$IF DEFINED(CLR)}
    FData.szInfoTitle := FBalloonTitle;
{$ELSE}
    StrPLCopy(FData.szInfoTitle, FBalloonTitle, Length(FData.szInfoTitle) - 1);
{$ENDIF}
    Refresh(NIM_MODIFY);
  end;
end;
end.
