org 0x7C00 ; tells the assmebler where we expect our code to be loaded
bits 16

main:
    hlt ; stops cpu from executing

.halt:
    JMP .halt

; if it resumed using for example an interrupt
; it will go to .halt label which will make an infinity loop and jmp to itself ever and ever again


times 510 - ($ - $$) db 0 ; $  means the beginning of the current (line)
                          ; $$ means the beginning of the current (section)
                          ; ($ - $$) calculates the current offset or position within the section
                          ; times used to repeat instruction number of times (times [count] [instruction])
                          ; the above line of code means that i want to initialize the remaining space with (zeros)
                          ; it can also means ( Pad the rest of the boot sector with zeros up to 510 bytes) this is the same as the above defenition
                          ; the sector is 512 bytes (2 bytes for the signature, 510 for the rest of the code)

dw 0AA55h ; boot signature
