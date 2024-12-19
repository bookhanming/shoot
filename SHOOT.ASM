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
IDT_TIMER2=2
MIN_X = 10
MAX_X = 500
MIN_Y = 15  ;for enemy
MAX_Y = 100 ;for enemy
BULLET_START_Y = 185
GUN_Y = 200
GUN_START_X = 170
MAX_ENEMY = 5
MAX_RAND_NUM = 1024 ;no less than (MAX_ENEMY * 2) + 1, must be even number

section '.text' code readable executable

  entry $

        invoke  CryptAcquireContext,context,0,0,1,0xF0000000
        test    eax,eax
        jz      .done
        invoke  CryptGenRandom,[context],MAX_RAND_NUM,buffer
        invoke  CryptReleaseContext,[context],0
  .done:

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
        invoke  SetTimer,[hwnd],IDT_TIMER2,1000,NULL
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

        ;draw the enemies for the first time (x & y based on random number)
.draw_enemy:
        cmp     [_draw_enemy], 1
        jne     .wmpaint.finish
        mov     ecx, [_rand_id]
        mov     dl, byte [buffer + ecx]
        shr     dl, 2   ;y, make it less than 255 (to fit the upper section of window)
        add     dl, 15  ;avoid _inst line at first row
        mov     ebx, [_enemy_id]
        mov     [_enemy_y + ebx * 4], edx
        mov     dl, byte [buffer + ecx + 1]
        mov     [_enemy_x + ebx * 4], edx
        add     [_enemy_x + ebx * 4], edx
        add     [_rand_id], 2
        invoke  TextOut, [hdc], [_enemy_x + ebx * 4], [_enemy_y + ebx * 4], _enemy, 1
        add     [_enemy_id], 1
        cmp     [_enemy_id], MAX_ENEMY
        je      .wmpaint.finish
        jmp     .draw_enemy

.wmpaint.finish:
        and     [_draw_enemy], 0
        mov     [_enemy_id], 0
        invoke  EndPaint,[hwnd],ps
        xor     eax,eax
        jmp     .finish
  .wmtimer:
        cmp     [wparam],IDT_TIMER1
        jne     .wmtimer.next
        cmp     [_shooting], 1
        jne     .processed
        invoke   TextOut, [hdc], [_bullet_x], [_bullet_y], _space, 1
        sub     [_bullet_y], 20
        cmp     [_bullet_y], 0
        jg      .draw_bullet
        and     [_shooting], 0
        mov     [_bullet_y], BULLET_START_Y
        jmp     .draw_finish

.wmtimer.next:
        cmp     [wparam],IDT_TIMER2
        jne     .processed

.draw_enemy_timer:
        mov     ebx, [_enemy_id]
        invoke  TextOut, [hdc], [_enemy_x + ebx * 4], [_enemy_y + ebx * 4], _space, 2
        ;invoke  Beep,700,300
        ;jmp     .draw_finish

.draw_enemy_y:
        xor     eax, eax
        add     [_rand_id], 1
        cmp     [_rand_id], MAX_RAND_NUM
        jl      .start_y
        mov     [_rand_id],0
        ;cmovge   ecx, eax  ;reset _rand_id
        ;cmovnge  ecx, [_rand_id]
.start_y:
        mov     ecx, [_rand_id]
        mov     dl, byte [buffer + ecx]
        bt      edx, 01000_0000b
        ;cmovc   eax, [_up]
        jc      .continue_y_up
        bt      edx, 00111_1110b
        jc      .continue_y_down
        jmp     .continue_y
.continue_y_up:
        sub     [_enemy_y + ebx * 4], 15
        jmp     .continue_y
.continue_y_down:
        add     [_enemy_y + ebx * 4], 30
.continue_y:
        ;add     [_enemy_y + ebx * 4], eax
        cmp     [_enemy_y + ebx * 4], MIN_Y
        jle     .continue_y_down
        cmp     [_enemy_y + ebx * 4], MAX_Y
        jge     .continue_y_up
        mov     [_rand_id], ecx

.draw_enemy_x:
        xor     eax, eax
        add     [_rand_id], 1
        cmp     [_rand_id], MAX_RAND_NUM
        jl      .start_x
        mov     [_rand_id],0
        ;cmovge   ecx, eax  ;reset _rand_id
        ;cmovnge  ecx, [_rand_id]
.start_x:
        mov     ecx, [_rand_id]
        mov     dl, byte [buffer + ecx]
        bt      edx, 01000_0000b
        ;cmovc   eax, [_up]
        jc      .continue_x_left
        bt      edx, 00111_1110b
        jc      .continue_x_right
        jmp     .continue_x
.continue_x_left:
        sub     [_enemy_x + ebx * 4], 10
        jmp     .continue_x
.continue_x_right:
        add     [_enemy_x + ebx * 4], 20
.continue_x:
        ;add     [_enemy_y + ebx * 4], eax
        cmp     [_enemy_x + ebx * 4], MIN_X
        jle     .continue_x_right
        cmp     [_enemy_x + ebx * 4], MAX_X
        jge     .continue_x_left
        mov     [_rand_id], ecx

        invoke  TextOut, [hdc], [_enemy_x + ebx * 4], [_enemy_y + ebx * 4], _enemy, 1
        add     [_enemy_id], 1
        cmp     [_enemy_id], MAX_ENEMY
        je      .draw_finish
        jmp     .draw_enemy_timer

.draw_bullet:
        invoke   TextOut, [hdc], [_bullet_x], [_bullet_y], _bullet, 1
        ;invoke  Beep, 750, 300
        ;invoke  MessageBeep, MB_OK
.draw_finish:
        mov      [_enemy_id], 0
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
        ;invoke  Beep, 7000, 20
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
  _space db '  '
  _bullet db '|'
  _gun db '^'
  _enemy db '='
  _inst db 'Press Left or Right arrow key to move; Spacebar to shoot; Esc to quit'
  _len_inst = $ - _inst

  _x dd GUN_START_X
  _y dd GUN_Y
  _bullet_x dd 170
  _bullet_y dd BULLET_START_Y
  _shooting dd 0

  _enemy_x rd MAX_ENEMY
  _enemy_y rd MAX_ENEMY
  _enemy_visible rd MAX_ENEMY
  _enemy_id dd 0
  _rand_id dd 0
  _draw_enemy dd 1

  _up dd -15
  _down dd 30
  _right dd 10
  _left dd -10
  _no_move dd 0

  buffer  rb MAX_RAND_NUM
          db 0
  context dd ?

  msg MSG
  ps PAINTSTRUCT
  rc RECT
  hwnd dd ?
  hdc dd ?

section '.idata' import data readable writeable

  library kernel,'KERNEL32.DLL',\
          user,'USER32.DLL',\
          gdi,'GDI32.DLL',\
          advapi,'ADVAPI32.DLL'

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

  import advapi,\
          CryptAcquireContext, 'CryptAcquireContextA',\
          CryptGenRandom, 'CryptGenRandom',\
          CryptReleaseContext, 'CryptReleaseContext'