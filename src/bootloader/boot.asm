[ORG 0x7C00] ; tells the assmebler where we expect our code to be loaded
[BITS 16]

%define ENDL 0x0D, 0x0A

;
; FAT12 header
;

JMP SHORT start
NOP

bdb_oem:                    DB 'MSWIN4.1'           ; 8 bytes
bdb_bytes_per_sector:       DW 512
bdb_sectors_per_cluster:    DB 1
bdb_reserved_sectors:       DW 1
bdb_fat_count:              DB 2
bdb_dir_entries_count:      DW 0E0h
bdb_total_sectors:          DW 2880                 ; 2880 * 512 = 1.44MB
bdb_media_descriptor_type:  DB 0F0h                 ; F0 = 3.5" floppy disk
bdb_sectors_per_fat:        DW 9                    ; 9 sectors/fat
bdb_sectors_per_track:      DW 18
bdb_heads:                  DW 2
bdb_hidden_sectors:         DD 0
bdb_large_sector_count:     DD 0

; extended boot record
ebr_drive_number:           DB 0                    ; 0x00 floppy, 0x80 hdd, useless
                            DB 0                    ; reserved
ebr_signature:              DB 29h
ebr_volume_id:              DB 12h, 34h, 56h, 78h   ; serial number, value doesn't matter
ebr_volume_label:           DB 'ZIOS'        ; 11 bytes, padded with spaces
ebr_system_id:              DB 'FAT12   '           ; 8 bytes



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
        MOV [bx], al      ; MOVe (al) to the buffer

        MOV si, bx        ; MOVe (bx) to (si) to print the read character
        CALL print

        INC bx            ; increment (bx) to point to the next address in the buffer
        JMP .input_loop

    .done:
        MOV BYTE [bx], 0 ; null-terminator
        POP bx
        POP ax
        RET



;
; Error handlers
;

floppy_error:
    mov si, msg_read_failed
    call print
    jmp wait_key_and_reboot

wait_key_and_reboot:
    mov ah, 0
    int 16h                     ; wait for keypress
    jmp 0FFFFh:0                ; jump to beginning of BIOS, should reboot


main:

    ; setup data segments
    MOV ax, 0       ; can't write to ds/es directly
    MOV ds, ax
    MOV es, ax

    ; setup stack
    MOV ss, ax
    MOV sp, 0x7C00  ; stack grows downwards from where we are loaded in memory


    ; read something from floppy disk
    ; BIOS should set DL to drive number
    mov [ebr_drive_number], dl

    mov ax, 1                   ; LBA=1, second sector from disk
    mov cl, 1                   ; 1 sector to read
    mov bx, 0x7E00              ; data should be after the bootloader
    call disk_read



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





; Parameters:
;   - ax: LBA address
; Returns:
;   - cx [bits 0-5]: sector number
;   - cx [bits 6-15]: cylinder
;   - dh: head
;

lba_to_chs:

    PUSH ax
    PUSH dx

    XOR dx, dx                          ; dx = 0
    DIV word [bdb_sectors_per_track]    ; ax = LBA / SectorsPerTrack
                                        ; dx = LBA % SectorsPerTrack

    INC dx                              ; dx = (LBA % SectorsPerTrack + 1) = sector
    MOV cx, dx                          ; cx = sector

    XOR dx, dx                          ; dx = 0
    DIV word [bdb_heads]                ; ax = (LBA / SectorsPerTrack) / Heads = cylinder
                                        ; dx = (LBA / SectorsPerTrack) % Heads = head
    MOV dh, dl                          ; dh = head
    MOV ch, al                          ; ch = cylinder (lower 8 bits)
    SHL ah, 6
    OR  cl, ah                           ; put upper 2 bits of cylinder in CL

    POP ax
    MOV dl, al                          ; restore DL
    POP ax
    RET


;
; Reads sectors from a disk
; Parameters:
;   - ax: LBA address
;   - cl: number of sectors to read (up to 128)
;   - dl: drive number
;   - es:bx: memory address where to store read data
;
disk_read:

    PUSH ax                             ; save registers we will modify
    PUSH bx
    PUSH cx
    PUSH dx
    PUSH di

    PUSH cx                             ; temporarily save CL (number of sectors to read)
    CALL lba_to_chs                     ; compute CHS
    POP ax                              ; AL = number of sectors to read

    MOV ah, 02h
    MOV di, 3                           ; retry count

.retry:
    PUSHA                               ; save all registers, we don't know what bios modifies
    STC                                 ; set carry flag, some BIOS'es don't set it
    INT 13h                             ; carry flag cleared = success
    JNC .done                           ; jump if carry not set

    ; read failed
    POPA
    CALL disk_reset

    DEC di
    TEST di, di
    JNZ .retry

.fail:
    ; all attempts are exhausted
    JMP floppy_error

.done:
    POPA

    POP di
    POP dx
    POP cx
    POP bx
    POP ax                             ; restore registers modified
    RET


;
; Resets disk controller
; Parameters:
;   dl: drive number
;
disk_reset:
    PUSHA
    MOV ah, 0
    STC
    INT 13h
    JC floppy_error
    POPA
    RET



welcome_msg: DB 'Hi hacker :) what is your name: ', 0
done_msg: DB 'DONE!', ENDL, 0
new_line_string: DB '', ENDL, 0
username: TIMES 10 db 0
msg_read_failed:        db 'Read from disk failed!', ENDL, 0



TIMES 510 - ($ - $$) db 0 ; $  means the beginning of the current (line)
                          ; $$ means the beginning of the current (section)
                          ; ($ - $$) calculates the current offset or position within the section
                          ; times used to repeat instruction number of times (times [count] [instruction])
                          ; the above line of code means that i want to initialize the remaining space with (zeros)
                          ; it can also means ( Pad the rest of the boot sector with zeros up to 510 bytes) this is the same as the above defenition
                          ; the sector is 512 bytes (2 bytes for the signature, 510 for the rest of the code)


DW 0AA55h ; boot signature
