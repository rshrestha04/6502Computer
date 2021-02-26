ACIA_DATA = $8020
ACIA_STATUS = $8021
ACIA_COMMAND = $8022
ACIA_CONTROL = $8023

 .org $8000
 .word 0	
 .org $8200
 

reset: 
 jmp main
 
nmi:
 rti
 
irq:
 rti
 
main:

init_acia:
 lda #%00001011   ;Noparity, no echo, no interrupt
 sta ACIA_COMMAND
 lda #%00011111
 sta ACIA_CONTROL   ;1 stop bit, 8 data bits, 19200 baud
 
write:
 ldx #0
 
delay:
 ldx #2
 .loop: dex
 bne .loop
 rts
 
next_char:

wait_txd_empty: 
 pha 
 jmp delay
 pla
 lda text,x
 beq read
 sta ACIA_DATA
 inx
 jmp next_char 
 
read:

wait_rxd_full:
 lda ACIA_STATUS
 and #$08
 beq wait_rxd_full
 lda ACIA_DATA
 jmp write
 
text: .asciiz "Hello World!"

 .org $fffa
 .word nmi
 .word reset
 .word irq
 
 
 
 
