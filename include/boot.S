LOADER_BASE_ADDR equ 0x900 
LOADER_START_SECTOR equ 0x2
LOADER_STACK_TOP equ LOADER_BASE_ADDR


;--------------gdt描述符属性------------------
DESC_G_4K   equ     1000_0000_0000_0000_0000_0000b  ;第23位
DESC_D_32   equ     0100_0000_0000_0000_0000_0000b  ;第22位
DESC_L      equ     0000_0000_0000_0000_0000_0000b  ;第21位

DESC_AVL    equ     0000_0000_0000_0000_0000_0000b  ;第20位

DESC_LIMIT_CODE2    equ     1111_0000_0000_0000_0000b    ;第19~16位
DESC_LIMIT_DATA2    equ     DESC_LIMIT_CODE2
DESC_LIMIT_VIDEO2   equ     0000_0000_0000_0000_0000_0000b

DESC_P              equ     1000_0000_0000_0000b     ;第15位
DESC_DPL_0          equ     0000_0000_0000_0000b     ;第14~13位
DESC_DPL_1          equ     0010_0000_0000_0000b    
DESC_DPL_2          equ     0100_0000_0000_0000b    
DESC_DPL_3          equ     0110_0000_0000_0000b    

DESC_S_CODE         equ     0001_0000_0000_0000b    ;第12位
DESC_S_DATA         equ     DESC_S_CODE
DESC_S_sys          equ     0000_0000_0000_0000b
DESC_TYPE_CODE      equ     1000_0000_0000b         ;第11~8位
; x = 1, c = 0, a = 0 代码段是可执行的，非一致性的，不可读，已访问位a清0

DESC_TYPE_DATA      equ     0010_0000_0000b
;x = 0, e = 0, w = 1, a = 0

DESC_CODE_HIGH4     equ     (0x00 << 24) + DESC_G_4K + DESC_D_32 + DESC_L + DESC_AVL + DESC_LIMIT_CODE2 + \
                            DESC_P + DESC_DPL_0 + DESC_S_CODE + DESC_TYPE_CODE + 0x00

DESC_DATA_HIGH4     equ     (0x00 << 24) + DESC_G_4K + DESC_D_32 + DESC_L + DESC_AVL + DESC_LIMIT_DATA2 + \
                            DESC_P + DESC_DPL_0 + DESC_S_DATA + DESC_TYPE_DATA + 0x00
DESC_VIDEO_HIGH4    equ     (0x00 << 24) + DESC_G_4K + DESC_D_32 + DESC_L + DESC_AVL + DESC_LIMIT_VIDEO2 + \
                            DESC_P + DESC_DPL_0 + DESC_S_DATA + DESC_TYPE_DATA + 0x0b

;; 选择子属性
RPL0    equ     00b
RPL1    equ     01b
RPL2    equ     10b
RPL3    equ     11b

TI_GDT  equ     000b
TI_LDT  equ     100b

;; 页表相关属性
PAGE_DIR_TABLE_POS equ 0x100000

PG_P        equ     001b
PG_RW_R     equ     000b
PG_RW_W     equ     010b
PG_US_S     equ     000b
PG_US_U     equ     100b
