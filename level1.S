;  
;    This simple program will run from the MBR of a virtual disk.
;    It will run in real mode, and it will communicate over the serial port.
;    The user will be able to Read, Write or Call 16-bit values using an offset from an array in memory.
;    This is intended as an example of how to shellcode in real mode, with the goal of reading the virtual disk using BIOS APIs.
;  

org 0x7c00
bits 16

setup:
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x9000
    call debug
    jmp main


; These are defined here to make it easier to exploit (COM_BUFFER -> code), for next levels they should be #define'd
USERMEM dw 0x6000
COM_BUFFER dw 0x7000
COM_BUFFER_SIZE dw 64
DEBUG_ACTIVE db 0

debug:
        pusha
        
        cmp byte [DEBUG_ACTIVE], 0
        je debug_end

        call newline
        mov ax, STR_AX
        call puts
        popa
        pusha
        call xprint_word
        call newline

        mov ax, STR_BX
        call puts
        mov ax, bx
        call xprint_word
        call newline

        mov ax, STR_CX
        call puts
        popa
        pusha
        mov ax, cx
        call xprint_word
        call newline

        mov ax, STR_DX
        call puts
        popa
        pusha
        mov ax, dx
        call xprint_word
        call newline

        mov ax, STR_IN
        call puts
        mov bx, COM_BUFFER
        mov ax, word [bx]
        call puts
        call newline



        ; mov ax, 0x41
        ; call putc
        ; call newline
        ; mov ax, 0x41
        ; call xprint_byte
        ; call newline

        ; mov ax, 0x4142
        ; call xprint_word
        ; call newline

        ; mov ax, word [TEST_BUF_0 + 2]
        ; mov dx, word [TEST_BUF_0 + 4]
        ; call hexstr_to_word
        ; call xprint_word

        ; call newline
        ; mov ax, word [TEST_BUF_1 + 0]
        ; mov dx, word [TEST_BUF_1 + 2]
        ; call hexstr_to_word
        ; call xprint_word
        debug_end:
        call newline
        popa
        ret
        STR_AX db "AX-", 0
        STR_BX db "BX-", 0
        STR_CX db "CX-", 0
        STR_DX db "DX-", 0
        STR_IN db "IN>", 0

main:

    call get_command


    mov bx, dx
    shl bx, 1
    add bx, word [USERMEM] ; slot address in bx

    call debug

    cmp al, 0
    je main_read
    cmp al, 1
    je main_write
    cmp al, 2
    je main_call

    main_read:
        mov ax, word [bx]
        call xprint_word
        jmp main
    main_write:
        call get_xword
        mov word [bx], dx
        jmp main
    main_call:
        mov ax, word [bx] ; deref slot content, this is intended to be a code pointer
        call ax
    jmp main

; FUNCTIONS
; Calling convention is param1 = a, param2 = d ; b is preserved
; Params can also be retvals depending on the function

; On next levels, 'X' should not be an option, the user will have to gain control flow by overwriting instructions/stack
CMD_PROMPT db 0x0a, "[R|W|X] [slot_number hexword]> ", 0
get_command:    ; char, short get_command()
                ; returns 0 for read, 1 for write, 2 for call
    push bx
    mov bx, word [COM_BUFFER]
    call newline      
    mov ax, CMD_PROMPT
    call puts
    mov ax, bx
    mov dx, word [COM_BUFFER_SIZE]
    call getsn
    mov al, byte [bx]
    or al, 0x20 ; lowercase
    cmp al, 'r'
    je get_command_read
    cmp al, 'w'
    je get_command_write
    cmp al, 'x'
    je get_command_call
    jmp get_command ; invalid command, try again

    get_command_read:
        mov si, 0
        jmp get_command_get_slot
    get_command_write:
        mov si, 1
        jmp get_command_get_slot
    get_command_call:
        mov si, 2

    get_command_get_slot:
    mov ax, [bx + 2]
    mov dx, [bx + 4]
    call hexstr_to_word
    mov dx, ax
    mov ax, si
    pop bx
    ret

XW_PROMPT db 0x0a, "[hexword]> ", 0
get_xword: ; short get_xword() WARN: returns in dx
    mov ax, XW_PROMPT
    call puts

    mov ax, word [COM_BUFFER]
    mov dx, word [COM_BUFFER_SIZE]
    push bx
    mov bx, ax
    add ax, 2
    sub dx, 2
    call getsn
    jmp get_command_get_slot

xprint_word: ; void xprint_word(short)
    push bx
    mov bx, ax
    shr ax, 8
    call xprint_byte
    mov ax, bx
    call xprint_byte
    pop bx
    ret

xprint_byte: ; void xprint_byte(char)
    push ax
    shr al, 4
    call xprint_byte_nib
    pop ax
    and al, 0x0f
    xprint_byte_nib:
        cmp al, 0xa
        jl xprint_byte_nib_dec
            add al, 0x7
        xprint_byte_nib_dec:
            add al, 0x30
        jmp putc

; This is going to be crude and buggy, who cares lol
hexstr_to_word: ; short hexstr_to_word(char[2] high, char[2] low)
    push bx
    push ax
    call hexstr_to_word_do_byte
    shr ax, 8
    pop dx
    call hexstr_to_word_do_byte
    pop bx
    ret

    hexstr_to_word_do_byte: ; dl(char) -> ah(value)
        mov bl, dh
        call hexstr_to_word_do_nibble
        mov ah, cl
        mov bl, dl
        call hexstr_to_word_do_nibble
        shl cl, 4
        or ah, cl
        ret

    hexstr_to_word_do_nibble: ; bl(char) -> cl(value)
        xor cl, cl
        bt bx, 6 ; if bl is a letter sets CF
        jnc hexstr_to_word_dec_n
            add cl, 9
        hexstr_to_word_dec_n:
            and bl, 0x0f
            add cl, bl
        ret
    

puts: ; void puts(char*)
    push bx
    mov bx, ax
    
    puts_loop:
        mov al, byte [bx]
        cmp al, 0
        je end_puts
        call putc
        inc bx
        jmp puts_loop

    end_puts:
    pop bx
    ret

NEWLINE db 0x0d, 0x0a, 0
newline: ; void newline()
    mov ax, NEWLINE
    jmp puts

getsn: ; short getsn(char*, short)
    push bx
    mov bx, ax
    mov cx, ax
    add cx, dx
    dec cx
    ; WARN: to optimize this, note that getc doesn't clobber cx either
    getsn_loop:
        call getc
        mov byte [bx], al
        cmp al, 0x0d ; CR (serial sends CRLF)
        je end_getsn
        inc bx
        cmp bx, cx
        jne getsn_loop
    end_getsn:
    mov byte [bx], 0
    pop bx
    ret

putc: ; void putc(char)
    mov dx, 0x3f8
    out dx, al
    ret

getc: ; char getc()
    mov dx, 0x3fd
    in al, dx
    bt ax, 0
    jnc getc ; check readiness
    sub dl, 5
    in al, dx
    cmp al, 0x0a ; ignore lf
    je getc
    call putc ; echo
    ret

; Boot sector magic number
times 510-($-$$) db 0
dw 0xaa55

; flag
db "flag{ring0_is_not_so_scary_after_all}"
