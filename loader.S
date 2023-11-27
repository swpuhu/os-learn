%include "boot.S"
section loader vstart=LOADER_BASE_ADDR


jmp loader_start
    GDT_BASE:   
        dd  0x00000000
        dd  0x00000000
    CODE_DESC:
        dd  0x0000ffff
        dd  DESC_CODE_HIGH4
    DATA_STACK_DESC:
        dd  0x0000ffff
        dd  DESC_DATA_HIGH4
    VIDEO_DESC:
        dd  0x80000007; limit=(0xbffff-0xb8000) / 4k = 0x7
        dd  DESC_VIDEO_HIGH4    ;dpl = 0

    GDT_SIZE equ $ - GDT_BASE
    GDT_LIMIT equ GDT_SIZE - 1
    times 60 dq 0 ;预留60个描述符的空位 dq 为8字节  64位

    
    ;; 段选择子  0号段描述符不可用
    SELECTOR_CODE equ (0x001 << 3) + TI_GDT + RPL0
    SELECTOR_DATA equ (0x002 << 3) + TI_GDT + RPL0
    SELECTOR_VIDEO equ (0x003 << 3) + TI_GDT + RPL0

    total_mem_bytes dd 0

    gdt_ptr dw GDT_LIMIT
            dd GDT_BASE

    ; total_mem_bytes4 + gdt_ptr6 + ards_buff244 + ards_nr2 = 256
    ards_buf times 244 db 0
    ards_nr dw 0
    
    lodermsg db '2 loader in real.'


loader_start:
    xor bx, bx
    mov edx, 0x534d4150
    mov di, ards_buf

    .e820_mem_get_loop:
        mov eax, 0x0000e820
        mov ecx, 20
        int 0x15
        add di, cx
        inc word [ards_nr]
        cmp ebx, 0
        jnz .e820_mem_get_loop

        mov cx, [ards_nr]
        mov ebx, ards_buf

        xor edx, edx
    .find_max_mem_area:
        mov eax, [ebx]      ;base_add_low
        add eax, [ebx + 8]  ;length_low
        add ebx, 20         ; next ARDS buffer
        cmp edx, eax
        jge .next_ards
        mov edx, eax
    .next_ards:
        loop .find_max_mem_area
        jmp .mem_get_ok

    .mem_get_ok:
        mov [total_mem_bytes], edx
        mov cx, 17
        mov bp, 0
        mov si, lodermsg
    .print_char:
        mov dl, [cs:si]
        mov dh, 0xc1
        mov word [gs:bp], dx
        add bp, 2
        add si, 1
        loop .print_char
        ;; 打印结束

    ;;------------ 准备进入保护模式--------------
    ;; 1. 打开A20
    ;; 2. 加载GDT表
    ;; 3. 将CR0的PE位置1

    ; 打开A20
    in al, 0x92
    or al, 0000_0010b
    out 0x92, al

    ;; 加载GDT
    lgdt [gdt_ptr]

    ;; cr0 第0位 置1
    mov eax, cr0
    or eax, 0x00000001
    mov cr0, eax

    jmp dword SELECTOR_CODE:p_mode_start ;;刷新流水线

[bits 32]

setup_page:
    ;; 页目录占用的空间逐字节清0
    mov ecx, 4096
    mov esi, 0
    .clear_page_dir:
        mov byte [PAGE_DIR_TABLE_POS + esi], 0
        inc esi
        loop .clear_page_dir

    ;; 创建Page Directory Entry
    .create_pde:
        mov eax, PAGE_DIR_TABLE_POS
        add eax, 0x1000
        mov ebx, eax

        or eax, PG_US_U | PG_RW_W | PG_P
        mov [PAGE_DIR_TABLE_POS + 0x0], eax
        mov [PAGE_DIR_TABLE_POS + 0xc00], eax

        sub eax, 0x1000
        mov [PAGE_DIR_TABLE_POS + 4092], eax ;;使最后一个目录项指向页目录表自己的地址

        mov ecx, 256
        mov esi, 0
        mov edx, PG_US_U | PG_RW_W | PG_P
    .create_pte:
        mov [ebx + esi * 4], edx
        add edx, 4096
        inc esi
        loop .create_pte
    ;; 创建内核其他页表的PDE
        mov eax, PAGE_DIR_TABLE_POS
        add eax, 0x2000
        or edx, PG_US_U | PG_RW_W | PG_P
        mov ebx, PAGE_DIR_TABLE_POS
        mov ecx, 254
        mov esi, 769
    .create_kernel_pde:
        mov [ebx + esi * 4], eax
        inc esi
        add eax, 0x1000
        loop .create_kernel_pde
        ret

p_mode_start:
    mov ax, SELECTOR_DATA
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp, LOADER_STACK_TOP
    mov ax, SELECTOR_VIDEO
    mov gs, ax

    mov byte [gs:160], 'P'
    mov byte [gs:161], 0xc1

    call setup_page
    xchg bx, bx
    sgdt [gdt_ptr]

    mov ebx, [gdt_ptr + 2]
    or dword [ebx + 0x18 + 4], 0xc0000000 
    add dword [gdt_ptr + 2], 0xc0000000 

    add esp, 0xc0000000

;; 把页表地址写入cr3
    mov eax, PAGE_DIR_TABLE_POS
    mov cr3, eax
    ;; 打开cr0的pg位 （第31位）
    mov eax, cr0
    or eax, 0x80000000
    mov cr0, eax

    lgdt [gdt_ptr]
    mov byte [gs:320], 'v'
    mov byte [gs:321], 0xf

    xchg bx, bx
    jmp $