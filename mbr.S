SECTION MBR vstart=0x7c00
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax
    mov sp, 0x7c00
    mov ax, 0xb800
    mov gs, ax

; 0x06 号功能，上卷全部行清屏
; INT 0x10 功能号： 0x06    功能描述：上卷窗口
;
; 输入
; AH 功能号 = 0x06
; AL = 上卷的行数（如果为0，则表示全部
; BH = 上卷的属性
; (CL, CH) = 窗口左上角的 (X, Y)的位置
; (DL, DH) = 窗口右下角的 (X, Y)的位置
; 无返回值

    mov ax, 0x600
    mov bx, 0x700
    mov cx, 0
    mov dx, 0x184f ;0x4f为低8位 == 80 ， 0x18为高8位 == 24
    ; VGA 文本模式中，一行只能容纳80个字符，一共25行。下标从0开始，
    int 0x10 ; 调用0x10中断
    ;; 利用文本显示模式打印字符，往0xb8000中写入字符串
    mov byte [gs:0x00], '1'
    mov byte [gs:0x01], 0xa6

    mov byte [gs:0x02], ' '
    mov byte [gs:0x03], 0xa4

    mov byte [gs:0x04], 'M'
    mov byte [gs:0x05], 0xa6

    mov byte [gs:0x06], 'B'
    mov byte [gs:0x07], 0xa4

    mov byte [gs:0x08], 'R'
    mov byte [gs:0x09], 0xa4

    ;; 打印结束

    jmp $ ; 让程序死循环在这里卡住
    times 510 - ($ - $$) db 0
    db 0x55, 0xaa
