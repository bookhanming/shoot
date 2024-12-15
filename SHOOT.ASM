format PE GUI 4.0

include 'win32a.inc'

IDT_TIMER1=1

section '.text' code readable executable

  entry $

        invoke  GetModuleHandle,0
        mov     [wc.hInstance],eax
        invoke  LoadCursor,0,IDC_ARROW
        mov     [wc.hCursor],eax
        invoke  RegisterClass,wc
        invoke  CreateWindowEx,0,_class,_title,WS_VISIBLE or WS_OVERLAPPEDWINDOW or WS_CLIPCHILDREN or WS_CLIPSIBLINGS,16,16,300,300,NULL,NULL,[wc.hInstance],NULL
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
        invoke  SetTimer,[hwnd],IDT_TIMER1,3000,NULL
        or      eax,eax
        jz      .wmcreate.error
        xor     eax,eax
        jmp     .finish
  .wmcreate.error:
        mov     eax, -1
        jmp     .finish
  .wmsize:
        jmp     .processed
  .wmpaint:
        invoke  BeginPaint,[hwnd],ps
        mov     [hdc],eax
        invoke  EndPaint,[hwnd],ps
        xor     eax,eax
        jmp     .finish
  .wmtimer:
        cmp     [wparam],IDT_TIMER1
        jne     .processed
        invoke  Beep, 750, 300
        ;invoke  MessageBeep, MB_OK
        xor      eax,eax
        jmp     .finish
  .wmkeydown:
        ;invoke  Beep, 750, 300
        ;invoke  MessageBeep, MB_OK
        cmp     [wparam],VK_ESCAPE
        jne     .defwndproc
  .wmdestroy:
        invoke  KillTimer,[hwnd],IDT_TIMER1
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

  wc WNDCLASS CS_HREDRAW or CS_VREDRAW,WindowProc,0,0,NULL,NULL,NULL,COLOR_WINDOWFRAME+1,NULL,_class

  _title db 'timer',0
  _class db 'timer',0

align 16
  msg MSG
  ps PAINTSTRUCT
  hwnd dd ?
  hdc dd ?

section '.idata' import data readable writeable

  library kernel,'KERNEL32.DLL',\
          user,'USER32.DLL'

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
         KillTimer, 'KillTimer',\
         LoadCursor,'LoadCursorA',\
         MessageBeep, 'MessageBeep', \
         PostQuitMessage,'PostQuitMessage', \
         RegisterClass,'RegisterClassA',\
         SetTimer, 'SetTimer',\
         TranslateMessage,'TranslateMessage'