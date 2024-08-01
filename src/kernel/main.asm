[org 0x7C00] ; tells the assmebler where we expect our code to be loaded
[bits 16]

%DEFINE ENDL 0X0D, 0x0A

start:
    JMP main

; prints characters to screen in tty mode
print:
    PUSH si
    PUSH ax

    .print_loop:
        LODSB
        OR al, al
        JZ .done

        MOV ah, 0x0E    ; tty mode
        INT 0x10        ; bios video interrupt

        JMP .print_loop

    .done:
        POP ax
        POP si
        RET


; take input from the user
input:
    PUSH ax
    PUSH bx

    MOV bx, si  ; point bx to the buffer (username)

    .input_loop:
        MOV ah, 0x00      ; Read Character
        INT 0x16          ; interrupt for keyboard services
        CMP al, 0x0D      ; compare al to (0x0D -> Enter key)
        JE .done
        MOV [bx], al      ; move (al) to the buffer

        MOV si, bx        ; move (bx) to (si) to print the read character
        CALL print

        INC bx            ; increment (bx) to point to the next address in the buffer
        JMP .input_loop

    .done:
        MOV BYTE [bx], 0 ; null-terminator
        POP bx
        POP ax
        RET

main:

    ; setup data segments
    MOV ax, 0       ; can't write to ds/es directly
    MOV ds, ax
    MOV es, ax

    ; setup stack
    MOV ss, ax
    MOV sp, 0x7C00  ; stack grows downwards from where we are loaded in memory


    ; write text to the screen in tty mode
    MOV si, welcome_msg
    CALL print

    ; take username from the user
    MOV si, username
    CALL input

    MOV si, new_line_string
    CALL print

    MOV si, done_msg
    CALL print

    HLT ; stops cpu from executing

.halt:
    JMP .halt

; if it resumed using for example an interrupt
; it will go to .halt label which will make an infinity loop and jmp to itself ever and ever again


welcome_msg: DB 'Hi what is your name: ', 0
done_msg: DB 'DONE!', ENDL, 0
new_line_string: DB '', ENDL, 0
username: TIMES 10 db 0


TIMES 510 - ($ - $$) db 0 ; $  means the beginning of the current (line)
                          ; $$ means the beginning of the current (section)
                          ; ($ - $$) calculates the current offset or position within the section
                          ; times used to repeat instruction number of times (times [count] [instruction])
                          ; the above line of code means that i want to initialize the remaining space with (zeros)
                          ; it can also means ( Pad the rest of the boot sector with zeros up to 510 bytes) this is the same as the above defenition
                          ; the sector is 512 bytes (2 bytes for the signature, 510 for the rest of the code)


DW 0AA55h ; boot signature
