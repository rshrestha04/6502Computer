;==============================================================================
; include external defs and sections
;
   
   ;including memory map
   
  .include        ../Memory/memory-map.s
;  .include        memory-map.s
  
  ;including the byte to hexconversion file
  
  .include        ../Utilities/util-tohex.s 
;  .include        util-tohex.s 

 
  
;========================================================================================



;=======================================================================================
;ASsigning address to pointers and start of buffer



 
  
;========================================================================================
VIA_PORTB = $8010
VIA_PORTA = $8011 
VIA_DDRB = $8012
VIA_DDRA = $8013


ACIA_DATA = $8020
ACIA_STATUS = $8021
ACIA_COMMAND = $8022
ACIA_CONTROL = $8023

  
E  = %10000000
RW = %01000000 
RS = %00100000

ACIA_STAT_INT = %10000000
ACIA_STAT_DSR = %01000000
ACIA_STAT_DCD = %00100000
ACIA_STAT_TDRE = %00010000
ACIA_STAT_FULL = %00001000
ACIA_STAT_OVER = %00000100
ACIA_STAT_FRAM = %00000010
ACIA_STAT_PAR = %00000001

ACIA_CTRL_1STOP = 0
ACIA_CTRL_2STOP = %10000000
ACIA_CTRL_8BIT = 0
ACIA_CTRL_7BIT = %00100000
ACIA_CTRL_6BIT = %01000000
ACIA_CTRL_5BIT = %01100000
ACIA_CTRL_XCLK = 0
ACIA_CTRL_115K = %00010000
ACIA_CTRL_50 = %00010001
ACIA_CTRL_75 = %00010010
ACIA_CTRL_110 = %00010011
ACIA_CTRL_135 = %00010100
ACIA_CTRL_150 = %00010101
ACIA_CTRL_300 = %00010110
ACIA_CTRL_600 = %00010111
ACIA_CTRL_1200 = %00011000
ACIA_CTRL_1800 = %00011001
ACIA_CTRL_2400 = %00011010
ACIA_CTRL_3600 = %00011011
ACIA_CTRL_4800 = %00011100
ACIA_CTRL_7200 = %00011101
ACIA_CTRL_9600 = %00011110
ACIA_CTRL_19_2 = %00011111

ACIA_CMD_ECHO = %00010000
ACIA_CMD_TIC = %00001000
ACIA_CMD_CLI = %00000010
ACIA_CMD_DTR = %00000001
;===================================================================================

	
 .section rom,"adrw"


reset:
 sei
 ldx #$ff
 txs
 
 

init_acia:
; lda #%00001001   ;Noparity, no echo, interrupt
 lda #(ACIA_CMD_ECHO | ACIA_CMD_TIC | ACIA_CMD_DTR)
 sta ACIA_COMMAND
; lda #%00011111
 lda #(ACIA_CTRL_1STOP | ACIA_CTRL_8BIT | ACIA_CTRL_19_2)
 sta ACIA_CONTROL   ;1 stop bit, 8 data bits, 19200 baud
 stz ACIA_RD_PTR
 stz ACIA_WR_PTR
 
init_via:
 lda #%11111111 ;set all pins on port B to output
 sta VIA_DDRB
 lda #%11100000 ;set top 3 pins on port A to output
 sta VIA_DDRA
 
 cli  ;clear interrupt disable

 lda #%00111000; Set 8-bit mode ; 2-line display; 5X8 font
 jsr lcd_instruction
   
 lda #%00001110 ; Display on ; curson on; blink off
 jsr lcd_instruction
 
 lda #%00000110 ;Increment and shift the curson; don't shift display
 jsr lcd_instruction
 
 lda #%00000001 ;clear display
 jsr lcd_instruction
 
Print_acia: 
 ldy #2
 lda #<Array
 sta util_dest_ptr
 lda #>Array
 sta util_dest_ptr+1
 lda ACIA_STATUS
 jsr byte2hex
 
 lda Array 
 jsr print_char

 lda Array+1
 jsr print_char
  
loop:
  lda ACIA_STATUS
  and #ACIA_STAT_INT
  beq loop
;  lda ACIA_BUFFER 
 ;jsr Get_Char
 lda #"A"
 jsr Send_Char
 
;  lda ACIA_DATA
;  sta ACIA_DATA
;  jsr print_char
  jmp loop
 

 
lcd_instruction: 
 sta VIA_PORTB
 lda #0        ; Clear RS/RW/E bits
 sta VIA_PORTA
 lda #E        ;Set E bit to send instruction
 sta VIA_PORTA
 lda #0        ; Clear RS/RW/E bits
 sta VIA_PORTA
 jmp wait_lcd
 
print_char:
 sta VIA_PORTB
 lda #RS        ; Clear RS/RW/E bits
 sta VIA_PORTA
 lda #(RS | E)        ;Set E bit to send instruction
 sta VIA_PORTA
 lda #RS        ; Clear RS/RW/E bits
 sta VIA_PORTA
 
wait_lcd:
 lda #0         ;set PortB to read 
 sta VIA_DDRB
 
 lda #RW   ;set read instruction
 sta VIA_PORTA
 
.wait:
 eor #E        ;toggle E
 sta VIA_PORTA
 
 bpl .skip  ; jumps to skip on 2nd loop
 
 ldx VIA_PORTB      ; load portB
 bra .wait      ;branch to wait
 
.skip            
 cpx #$80     ;check to see if bit 7 is set
 bcs .wait    ; if carry bit is set bit 7 is not clear ; do the loop again
 
 lda #%11111111    ; set DDRB back to write
 sta VIA_DDRB           
 
 inc
 sta VIA_PORTA	; reset RW line to write
 
 rts
 
;==============================================================================

;codes for handling interrups and writing data read to buffer 

;Writing to buffer and incrementing WR pointer
WR_ACIA_BUF:

 ldx ACIA_WR_PTR
 sta ACIA_BUFFER,X
 inc ACIA_WR_PTR 
 rts
 
;Reading from buffer and incrementing read pointer
RD_ACIA_BUF:

 ldx ACIA_RD_PTR
 lda ACIA_BUFFER,X
 inc ACIA_RD_PTR
 rts
 
;Keeping track of difference betweeen WR pointer and RD pointer so We only access valid data
ACIA_BUF_DIF:
 
 lda ACIA_WR_PTR
 sec
 sbc ACIA_RD_PTR
 rts 
 
;nmi interrupt handler 
acia_read_trigger:
 pha
 phx
 
 lda ACIA_STATUS
 and #$08 
 beq service_acia_end
 
 
 ;there is a byte 
 lda ACIA_DATA
 ldx acia_rd_ptr
 lda acia_buffer,x
 inx acia_rd_ptr
 inc acia_counter
 
 
 
 ;Check how manu bytes 
 jsr ACIA_BUF_DIF
 cmp #$F0
 bcc SERVICE_ACIA_END
 
 ;there is only 15 characters left
 lda #$01 
 sta ACIA_COMMAND
 
service_acia_end:
 plx
 pla
 rti

;getting character from the buffer
Get_Char:
 jsr ACIA_BUF_DIF
 beq no_char_available
 
char_available: 
 cmp #$E0
 bcs buf_full
 lda #$09
 sta ACIA_COMMAND
 
buf_full:
 phx
 jsr RD_ACIA_BUF
 plx
 ;; jsr Send char
 sec
 rts
 
no_char_available:
 clc 
 rts
 
;Sending Character to the Terminal 

Send_Char:
 sei    ;disabling interrupt
 pha
 
wait_tx:
 lda ACIA_STATUS
 
 pha 
 and #$08
 beq check_tx
 
 phx
 lda WR_ACIA_BUF
 jsr WR_ACIA_BUF
 
 jsr ACIA_BUF_DIF
 cmp #$F0
 bcc tx_keep_rts_active
 
 lda #$01
 sta ACIA_COMMAND
 
tx_keep_rts_active:
 plx
 
check_tx:
 pla
 and #$10
 beq wait_tx
 
 pla 
 sta ACIA_DATA
 cli 
 rts
 
irq:
 pha
 phx
 
 
 plx
 pla
 rti
 
;==========================================================================
 .section gpspace,"adrw"
 
Array .blk 2

 .org $7f00
 
acia_buff .blk 256
;==========================================================================
 .section        zero_page,"adrw"
 
  zpage     acia_rd_ptr
  zpage     acia_wr_ptr
  zpage     acia_counter
  
acia_rd_ptr:                    ; read pointer
 blk       1

acia_wr_ptr:                    ; write pointer
 blk       1
  
acia_counter:
 blk       1                   ;counter for number of char in buffer
;==========================================================================

 
 .section vectors,"adr"
 .word acia_read_trigger	;nmi
 .word reset   
 .word irq	; irq
 
