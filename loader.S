%include "boot.S"
section loader vstart=LOADER_BASE_ADDR

    mov cx, 17
    mov bp, 0
    mov si, message
.print_char:
    mov dl, [cs:si]
    mov dh, 0xc1
    mov word [gs:bp], dx
    add bp, 2
    add si, 1
    loop .print_char
    jmp $

    message db "2 Here is Loader!"
    ;; 打印结束