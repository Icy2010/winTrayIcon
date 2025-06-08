![](https://github.com/Icy2010/winTrayIcon/blob/main/Trayicon/PixPin_2025-06-08_13-07-47.png)
# winTrayIcon
* Delphi Windows-FMX/VCL TrayIcon
(*
    此为Windows下 FMX 框架下的托盘工具
    当然也可以在VCL使用
    修改自 TTrayIcon 让其可以在FMX使用

    blog: https://zelig.cn
    Delphi 交流群: 118195948
*)

## 使用Demo

* 创建托盘
```pascal
  var TrayIcon:  TWinTrayIcon;

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
```

* 触发提示
```pascal
  TrayIcon.BalloonTitle:= '这是一个提示';
  TrayIcon.BalloonHint:= '写出你想说的';
  TrayIcon.ShowBalloonHint;
```
