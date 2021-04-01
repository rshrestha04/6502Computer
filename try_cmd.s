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
VIA_T1CL=$8014
VIA_T1CH= $8015
VIA_T1LL= $8016
VIA_T1LH =$8017
VIA_ACR = $801B
VIA_IER =$801E


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

EOS =$00
EOL =$03
;===================================================================================

	
 .section rom,"adrw"


reset:
 sei
 ldx #$ff
 txs
 
 

init_acia:
; lda #%00001001   ;Noparity, no echo, interrupt
 lda #(ACIA_CMD_TIC | ACIA_CMD_DTR)
 sta ACIA_COMMAND
; lda #%00011111
 lda #(ACIA_CTRL_1STOP | ACIA_CTRL_8BIT | ACIA_CTRL_19_2)
 sta ACIA_CONTROL   ;1 stop bit, 8 data bits, 19200 baud
 stz acia_rd_ptr
 stz acia_wr_ptr
 stz acia_counter
 stz cstring_ptr
 stz command
 
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
 
 
 
  lda #<text
  sta cstring_ptr
  lda #>text
  sta cstring_ptr+1
  
  jsr print_cstring
  
 
 ;=================================================MAIN LOOP=================================== 
loop:
  ;lda ACIA_DATA
  ;cmp #$0D
  ;beq .exit_loop
  ;jmp loop
  
  ;.exit_loop:
  lda acia_counter
  beq loop
  
  ;ldx acia_rd_ptr
  ;lda acia_buff,x
  ;inc acia_rd_ptr
  ;dec acia_counter
  
   ;lda #"H"
;  lda ACIA_DATA
;  sta ACIA_DATA

     
   
   ;jsr print_char

  
 
  
  ;lda #<acia_buff
  ;sta cstring_ptr
  ;lda #>acia_buff
  ;sta cstring_ptr+1
  
  ;jsr print_cstring
  
  jmp loop
 
;=======================================================MAIN LOOP END==========================
 
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
 
;=========================================table===========================
 
table 
 .word table1
 .byte "about", $00
 .word aboutcmd
 
table1 
 .word table2
 .byte "reset", $00
 .word resetcmd
 
table2 
 .word table3
 .byte "poke", $00
 .word pokecmd
 
table3 
 .word $0000
 .byte "jump", $00
 .word jumpcmd
 
 
 

;======================sub-rotine to send in a C String===================== 
 
print_cstring:
 
 phy
 pha
 
 
 
 ldy #0
.send: 

 
 lda (cstring_ptr),y
 beq .exit
 ;pha
 ;jsr print_char
 ;pla
 jsr Send_Char
 iny
 bra .send
 
.exit:
 pla
 ply
 rts
 
 
;text: .asciiz "!" 
text: .ascii "Hello, World from 6502!",'x','8',13,10,0 

;========================````````COMMANDS````````````````===================================================================================================

resetcmd: 
 lda #"R"
 jsr Send_Char
 jmp reset
 rts
 
pokecmd:
 
 lda #"P"
 jsr Send_Char
 rts
 
aboutcmd:

 lda #"A"
 jsr Send_Char
 rts
 
jumpcmd:
 
 lda #"J"
 jsr Send_Char
 rts
 
;========================''''''''COMMANDS''''''''''''''''====================================================================================================

copy_instruction: 

 ldy #0
 
.loop:

 ldx acia_rd_ptr
 lda acia_buff,x
 cmp #$00
 beq .donewithcommand
 sta command,y
 inc acia_rd_ptr
 dec acia_counter
 iny
 jmp .loop 
  
.donewithcommand:
 inc acia_rd_ptr
 dec acia_counter
 lda #$00
 sta command, y
 ldy #0  ; load 0 back
 
 ;check if thats also the end of command line
 ldx acia_rd_ptr
 lda acia_buff,x
 cmp #$B
 beq find
 

 
 
 .getoperand1:
 ldx acia_rd_ptr
 lda acia_buff,x
 cmp #$00
 beq .donewithoperand1
 sta operand1,y
 inc acia_rd_ptr
 dec acia_counter
 iny
 jmp .getoperand1

 
.donewithoperand1:

 inc acia_rd_ptr
 dec acia_counter
 lda #$00
 sta operand1, y
 ldy #0  ; load 0 back
 
 ;check if thats also the end of command line
 ldx acia_rd_ptr
 lda acia_buff,x
 cmp #$B
 beq find
 
 
 

 
 
 
 
.getoperand2:
 ldx acia_rd_ptr
 lda acia_buff,x
 cmp #$00
 beq .donewithoperand2
 sta operand2,y
 inc acia_rd_ptr
 dec acia_counter
 iny
 jmp .getoperand2

 
.donewithoperand2:

 inc acia_rd_ptr
 dec acia_counter
 lda #$00
 sta operand2, y
 ldy #0  ; load 0 back
 
 ;check if thats also the end of command line
 ldx acia_rd_ptr
 lda acia_buff,x
 cmp #$B
 beq find
 
 ;===================================================
 
find:

 lda #"1" 
 jsr Send_Char

matchcommand:

 lda #<table
 sta entry
 lda #>table
 sta entry+1
 
 
;Debuging:

; ldy #0
;.round
; lda (entry),y
; jsr Send_Char
; beq .done
; iny
; jmp .round
;.done
; rts
 
testentry: 

cacheptr:
  ldy #0
  lda (entry),y
  sta $AA
  iny
  lda (entry),y
  sta $AB
  iny
  ldx #0
  
nextchar
 lda command,x
 beq endofword
 cmp (entry), y
 bne nextentry
 inx
 iny
 jmp nextchar
 
 
endofword:
 lda (entry),y
 beq successful
 jmp nextentry
 
  lda #"2" 
 jsr Send_Char
 
successful:
 iny
 lda (entry),y
 sta $AC
 iny
 lda (entry), Y
 sta $AD
 jmp ($AC)
 
 lda #"3" 
 jsr Send_Char
 rts
 
nextentry:
 lda $AA
 sta entry
 lda $AB
 sta entry+1
 ora $AA
 beq nosuccess
 lda #"4" 
 jsr Send_Char
 jmp testentry
 
 
 
 nosuccess: 
  lda #"k"
  jsr Send_Char
  rts
 
 
 
 
 ;===================================================
 lda #"2"
 jsr print_char

 
;.lastcheck

; ldy #0
;.Cloop 
; lda operand2, y
; cmp #$00
; beq .allcheck
; jsr Send_Char
; iny
; jmp .Cloop 
 
 
 
;.allcheck

; ldy #0
;.Bloop 
; lda operand1, y
; cmp #$00
; beq .check
; jsr Send_Char
; iny
; jmp .Bloop 
 
;.check:
; inc acia_rd_ptr
; dec acia_counter

; ldy #0
;.Aloop 
; lda command, y
; cmp #$00
; beq .exit
; jsr Send_Char
; iny
; jmp .Aloop 

;.exit 
; rts
 

 


;=======================Subroutine to print to screen after Enter detection ========================

write:
.loop
 lda acia_counter
 beq .exit


 ldx acia_rd_ptr
 lda acia_buff,x
 inc acia_rd_ptr
 dec acia_counter
  
 jsr Send_Char
 
 jmp .loop
 
 
.exit
  
 rts

 
 
;=================nmi interrupt handler =============================================================


 
 

acia_read_trigger:
 pha
 phx
 
 lda ACIA_STATUS
 and #$08 
 beq service_acia_end
 
 
 ;there is a byte 
 lda ACIA_DATA
 cmp #$0D
 beq .enter_detected
 cmp #$20
 beq .space_detected
 ldx acia_wr_ptr
 sta acia_buff,x
 inc acia_wr_ptr
 inc acia_counter
 
 lda acia_counter
 cmp #$F0
 bcc service_acia_end  
 
; there is only 15 characters left
 lda #$01 
 sta ACIA_COMMAND
 
.enter_detected:

 lda #$00                ;;;insert #$00 string terminator 
 ldx acia_wr_ptr
 sta acia_buff,x
 inc acia_wr_ptr
 inc acia_counter
 
 lda #$B                ;;;insert #$0B command terminator
 ldx acia_wr_ptr
 sta acia_buff,x
 inc acia_wr_ptr
 inc acia_counter
 
 jsr copy_instruction
 ;jsr write
 jmp service_acia_end
 
.space_detected

 lda #$00               ;;;newline
 ldx acia_wr_ptr
 sta acia_buff,x
 inc acia_wr_ptr
 inc acia_counter
 
 
 jmp service_acia_end 
  
service_acia_end:
 plx
 pla
 rti

;getting character from the buffer
Get_Char:
 lda acia_counter
 beq no_char_available
 
char_available: 
 cmp #$E0
 bcs buf_full
 lda #$09
 sta ACIA_COMMAND
 
buf_full:
 phx
 ldx acia_rd_ptr
 lda acia_buff,X
 inc acia_rd_ptr
 dec acia_counter
 plx
 ;; jsr Send char
 sec
 rts
 
no_char_available:
 clc 
 rts
 ;===============================SEND CHAR ==================================
 
;Sending Character to the Terminal 

Send_Char:
 
 pha
 
 and #$7f
 sta ACIA_DATA
 jsr delay
 pla
 
; stz lock
 
; lda #$c0
; sta VIA_IER
; lda #$00
; sta VIA_ACR    ;ACR must be set to 0 for single interupt
; sta VIA_T1LL
; lda #$80        ;delay
; sta VIA_T1CH

; pla
; sta ACIA_DATA
 
;.loop: 
; lda lock
; beq .loop
 
; cli
; wai
; cli  
 rts

 
irq:
 pha
 phx
 lda ACIA_STATUS
 lda #$7f
 sta VIA_IER
 ;lda #'!'
 ;jsr print_char
 lda lock
 inc
 sta lock
 
 plx
 pla
 rti
 
 delay:
  phy
  phx
 
  ldy #1
  
 .outer:
  ldx #$68
 
 .inner:
  dex
  bne .inner
  
  dey
  bne .outer
  
  plx
  ply
  
  rts

;==========================================================================
 .section gpspace,"adrw"
 
Array .blk 2

;text: .asciiz "Hello, Dashian!"
 
 .org $5000
 

 
   
 .org $7f00
  
acia_buff .blk 256
;==========================================================================
 .section        zero_page,"adrw"
 
  zpage     acia_rd_ptr
  zpage     acia_wr_ptr
  zpage     acia_counter
  zpage     cstring_ptr
  zpage     lock
  zpage     command
  zpage     operand1
  zpage     operand2
  zpage     operand3
  zpage     entry
 
  
  
acia_rd_ptr:                    ; read pointer
 blk       1

acia_wr_ptr:                    ; write pointer
 blk       1
  
acia_counter:
 blk       1                   ;counter for number of char in buffer
 
cstring_ptr:
 blk       2                   ;pointer to C-String

lock:
 blk 1
 
command:
 blk       10
 
operand1:
 blk       4
 
operand2:
 blk       10 
operand3:
 blk       5
 
entry:
 blk       10
 
;$00AA-$00AF used for cache
 
 
;=========================================================================


 
;==========================================================================

 
 .section vectors,"adr"
 .word acia_read_trigger	;nmi
 .word reset   
 .word irq	; irq
 
