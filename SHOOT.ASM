;SHOOT.ASM - Windows shooting game prototype V0.02
;Developed by Boo Khan Ming (aka MatQuasar)
;
;Version history: 28 Apr 2024 - Console version introduced (only moving of gun)
;                 12 Nov 2024 - GUI version introduced (only moving of gun)
;                 27 Nov 2024 - @macomics helped to solve Timer problem
;                 18 Dec 2024 - Ver 0.02, moving of gun + moving of single bullet
;

format PE GUI 4.0

include 'win32a.inc'

IDT_TIMER1=1
MAX_X = 500
BULLET_START_Y = 185
GUN_Y = 200
GUN_START_X = 170

section '.text' code readable executable

  entry $

        invoke  GetModuleHandle,0
        mov     [wc.hInstance],eax
        invoke  LoadCursor,0,IDC_ARROW
        mov     [wc.hCursor],eax
        invoke  RegisterClass,wc
        invoke  CreateWindowEx,0,_class,_title,WS_VISIBLE or (WS_OVERLAPPEDWINDOW or WS_SYSMENU) and not (WS_MINIMIZEBOX or WS_MAXIMIZEBOX or WS_THICKFRAME),16,16,600,300,NULL,NULL,[wc.hInstance],NULL
        mov     [hwnd],eax

  msg_loop:
        invoke  GetMessage,msg,NULL,0,0
        or      eax,eax
        jz      end_loop
        invoke  TranslateMessage,msg
        invoke  DispatchMessage,msg
        jmp     msg_loop

  end_loop:
        invoke  ExitProcess,[msg.wParam]

proc WindowProc hwnd,wmsg,wparam,lparam
        push    ebx esi edi
        cmp     [wmsg],WM_CREATE
        je      .wmcreate
        cmp     [wmsg],WM_SIZE
        je      .wmsize
        cmp     [wmsg],WM_PAINT
        je      .wmpaint
        cmp     [wmsg], WM_TIMER
        je      .wmtimer
        cmp     [wmsg],WM_KEYDOWN
        je      .wmkeydown
        cmp     [wmsg],WM_DESTROY
        je      .wmdestroy
  .defwndproc:
        invoke  DefWindowProc,[hwnd],[wmsg],[wparam],[lparam]
        jmp     .finish
  .wmcreate:
        invoke  GetDC,[hwnd]
        mov     [hdc],eax
        invoke  SetTimer,[hwnd],IDT_TIMER1,200,NULL
        or      eax,eax
        jz      .wmcreate.error
        xor     eax,eax
        jmp     .finish
  .wmcreate.error:
        mov     eax, -1
        jmp     .finish
  .wmsize:
        invoke  GetClientRect,[hwnd],rc
        jmp     .finish
  .wmpaint:
        invoke  BeginPaint,[hwnd],ps
        ;mov     [hdc],eax
        invoke  TextOut, [hdc], 0, 0, _inst, _len_inst
        invoke  TextOut, [hdc], [_x], [_y], _gun, 1
        invoke  EndPaint,[hwnd],ps
        xor     eax,eax
        jmp     .finish
  .wmtimer:
        cmp     [wparam],IDT_TIMER1
        jne     .processed
        cmp     [_shooting], 1
        jne     .processed
        invoke   TextOut, [hdc], [_bullet_x], [_bullet_y], _space, 1
        sub     [_bullet_y], 20
        cmp     [_bullet_y], 0
        jg      .draw_bullet
        and     [_shooting], 0
        mov     [_bullet_y], BULLET_START_Y
        jmp     .draw_finish
.draw_bullet:
        invoke   TextOut, [hdc], [_bullet_x], [_bullet_y], _bullet, 1
        ;invoke  Beep, 750, 300
        ;invoke  MessageBeep, MB_OK
.draw_finish:
        xor      eax,eax
        jmp     .finish
  .wmkeydown:
        cmp     [wparam], VK_LEFT
        je      .left
        cmp     [wparam], VK_RIGHT
        je      .right
        cmp     [wparam], VK_SPACE
        je      .shoot
        cmp     [wparam],VK_ESCAPE
        jne     .defwndproc
        jmp     .wmdestroy
.shoot:
        cmp     [_shooting], 1
        je      .defwndproc
        mov     edx, [_x]
        mov     [_bullet_x], edx
        or      [_shooting], 1
        invoke  Beep, 7000, 20
        jmp     .wmpaint
.left:
        cmp     [_x],10
        jl      .defwndproc
        invoke  TextOut, [hdc], [_x], [_y], _space, 1
        sub     [_x],10
        jmp     .wmpaint
.right:
        cmp     [_x],MAX_X
        jg      .defwndproc
        invoke  TextOut, [hdc], [_x], [_y], _space, 1
        add     [_x],10
        jmp     .wmpaint
  .wmdestroy:
        invoke  KillTimer,[hwnd],IDT_TIMER1
        invoke  ReleaseDC,[hwnd],[hdc]
        invoke  PostQuitMessage,0
        xor     eax,eax
        jmp     .finish
  .processed:
        mov     eax,1
  .finish:
        pop     edi esi ebx
        ret
endp

section '.data' data readable writeable

  wc WNDCLASS NULL,WindowProc,0,0,NULL,NULL,NULL,NULL,NULL,_class

  _title db 'shoot',0
  _class db 'shoot',0
  _space db ' '
  _bullet db '|'
  _gun db '^'
  _inst db 'Press Left or Right arrow key to move; Spacebar to shoot; Esc to quit'
  _len_inst = $ - _inst

  _x dd GUN_START_X
  _y dd GUN_Y
  _bullet_x dd 170
  _bullet_y dd BULLET_START_Y
  _shooting dd 0
  msg MSG
  ps PAINTSTRUCT
  rc RECT
  hwnd dd ?
  hdc dd ?

section '.idata' import data readable writeable

  library kernel,'KERNEL32.DLL',\
          user,'USER32.DLL',\
          gdi,'GDI32.DLL'

  import kernel,\
         GetModuleHandle,'GetModuleHandleA',\
         Beep, 'Beep', \
         ExitProcess,'ExitProcess'

  import user,\
         BeginPaint,'BeginPaint',\
         CreateWindowEx,'CreateWindowExA',\
         DefWindowProc,'DefWindowProcA',\
         DispatchMessage,'DispatchMessageA',\
         EndPaint,'EndPaint',\
         GetMessage,'GetMessageA',\
         GetClientRect,'GetClientRect',\
         GetDC,'GetDC',\
         ReleaseDC,'ReleaseDC',\
         KillTimer, 'KillTimer',\
         LoadCursor,'LoadCursorA',\
         MessageBeep, 'MessageBeep', \
         PostQuitMessage,'PostQuitMessage', \
         RegisterClass,'RegisterClassA',\
         SetTimer, 'SetTimer',\
         TranslateMessage,'TranslateMessage'

  import gdi,\
         TextOut, 'TextOutA'