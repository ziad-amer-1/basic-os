org 0x7C00 ; tells the assmebler where we expect our code to be loaded
bits 16

%DEFINE ENDL 0x0D, 0x0A

start:
    JMP main

; prints characters to screen in tty mode
print:
    PUSH si
    PUSH ax

    .loop:
        LODSB
        OR al, al
        JZ .done

        MOV ah, 0x0E    ; tty mode
        INT 0x10        ; bios video interrupt

        JMP .loop

    .done:
        POP ax
        POP si
        ret


main:

    ; setup data segments
    MOV ax, 0       ; can't write to ds/es directly
    MOV ds, ax
    MOV es, ax

    ; setup stack
    MOV ss, ax
    MOV sp, 0x7C00  ; stack grows downwards from where we are loaded in memory


    ; write text to the screen in tty mode
    MOV si, msg
    CALL print

    MOV si, msg2
    CALL print


    HLT ; stops cpu from executing

.halt:
    JMP .halt

; if it resumed using for example an interrupt
; it will go to .halt label which will make an infinity loop and jmp to itself ever and ever again


msg: DB 'Hello World!', ENDL, 0
msg2: DB 'Hello my name is ziad', ENDL, 0


TIMES 510 - ($ - $$) db 0 ; $  means the beginning of the current (line)
                          ; $$ means the beginning of the current (section)
                          ; ($ - $$) calculates the current offset or position within the section
                          ; times used to repeat instruction number of times (times [count] [instruction])
                          ; the above line of code means that i want to initialize the remaining space with (zeros)
                          ; it can also means ( Pad the rest of the boot sector with zeros up to 510 bytes) this is the same as the above defenition
                          ; the sector is 512 bytes (2 bytes for the signature, 510 for the rest of the code)


DW 0AA55h ; boot signature
