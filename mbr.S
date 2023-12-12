%include "boot.S"
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
    ;; 将起始扇区 0x2 的内容加载到 0x900的位置
    mov eax, LOADER_START_SECTOR
    mov bx, LOADER_BASE_ADDR
    mov cx, 4 ;; 待读入扇区数，读取1个扇区的内容
    call rd_disk_m_16 ;; 调用函数，加载硬盘的内容到内存
    jmp LOADER_BASE_ADDR ;;跳转到从硬盘加载到内存的程序上
    
    rd_disk_m_16:
        mov esi, eax    ;; 暂存eax
        mov di, cx      ;; 暂存cx  读取1个扇区的内容
        ;; 第一步  设置要读取的扇区数 sector count
        ;;用dx寄存器往端口中写入数据，表示操作0x1f2端口
        ;;0x1f2表示操作 Sector count

        mov dx, 0x1f2 
        mov al, cl
        out dx, al ;; out 表示写端口操作

        mov eax, esi    ;; 恢复eax

        ;; 第二步   将LBA地址写入 0x1f3 ~ 0x1f6端口
        ;; 写入 LBA 的 0~7位
        mov dx, 0x1f3
        out dx, al

        ;; 写入 LBA 的 8~15位
        mov dx, 0x1f4
        mov cl, 8
        shr eax, cl
        out dx, al

        ;; 写入 LBA 的 16~23位
        mov dx, 0x1f5
        shr eax, cl
        out dx, al

        mov dx, 0x1f6
        shr eax, cl
        and al, 0x0f
        or al, 0xe0
        out dx, al

        mov dx, 0x1f7
        mov al, 0x20
        out dx, al

    ; xchg bx, bx
    .not_ready:
        nop
        in al, dx
        and al, 0x88
        cmp al, 0x08
        jnz .not_ready

        mov ax, di
        mov dx, 256
        mul dx
        mov cx, ax

        
    .go_on_read:
        ;; 从 0x1f0端口读取数据
        mov dx, 0x1f0
        in ax, dx
        mov [bx], ax
        add bx, 2
        loop .go_on_read
        ret
    times 510 - ($ - $$) db 0
    db 0x55, 0xaa
