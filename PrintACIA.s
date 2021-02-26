;==============================================================================
; include external defs and sections
;
   
   ;including memory map
   
  .include        ../Memory/memory-map.s
  
  ;including the byte to hexconversion file
  
  .include        ../Utilities/util-tohex.s 
  
  ;include ACIA
  
  .include        ../Memory/65c22.s 
  
;========================================================================================
PORTB = $8010
PORTA = $8011 
DDRB = $8012
DDRA = $8013
ACIA_DATA = $8020
ACIA_STATUS = $8021
ACIA_COMMAND = $8022
ACIA_CONTROL = $8023

  
E  = %10000000
RW = %01000000 
RS = %00100000
	
 .section rom,"adrw"


reset:
 ldx #$ff
 txs
 

init_acia:
 lda #%00001001   ;Noparity, no echo, interrupt
 sta ACIA_COMMAND
 lda #%00011111
 sta ACIA_CONTROL   ;1 stop bit, 8 data bits, 19200 baud
 
init_via:
 lda #%11111111 ;set all pins on port B to output
 sta DDRB
 lda #%11100000 ;set top 3 pins on port A to output
 sta DDRA
 
 

Print_acia: 
 ldy #2
 lda #<Array
 sta util_dest_ptr
 lda #>Array
 sta util_dest_ptr+1
 lda ACIA_STATUS
 jsr byte2hex
 
  
 
 lda #%00111000; Set 8-bit mode ; 2-line display; 5X8 font
 jsr lcd_instruction
 
  
 lda #%00001110 ; Display on ; curson on; blink off
 jsr lcd_instruction
 
 lda #%00000110 ;Increment and shift the curson; don't shift display
 jsr lcd_instruction
 
 lda Array 
 jsr print_char

 lda Array+1
 jsr print_char
  
loop:
  jmp loop
 

 
 lcd_instruction: 
 sta PORTB
 lda #0        ; Clear RS/RW/E bits
 sta PORTA
 lda #E        ;Set E bit to send instruction
 sta PORTA
 lda #0        ; Clear RS/RW/E bits
 sta PORTA
 jmp wait_lcd
 rts
 
print_char:
 sta PORTB
 lda #RS        ; Clear RS/RW/E bits
 sta PORTA
 lda #(RS | E)        ;Set E bit to send instruction
 sta PORTA
 lda #RS        ; Clear RS/RW/E bits
 sta PORTA
 jmp wait_lcd
 rts
 
wait_lcd:
 lda #0         ;set PortB to read 
 sta DDRB
 
 lda #RW   ;set read instruction
 sta PORTA
 
.wait:
 eor #E        ;toggle E
 sta PORTA
 
 bpl .skip  ; jumps to skip on 2nd loop
 
 ldx PORTB      ; load portB
 bra .wait      ;branch to wait
 
.skip            
 cpx #$80     ;check to see if bit 7 is set
 bcs .wait    ; if carry bit is set bit 7 is not clear ; do the loop again
 
 lda #%11111111    ; set DDRB back to write
 sta DDRB           
 
 inc
 rts
 
 
 
nmi:
 rti
 
irq:
 rti
 
 
 .section gpspace,"adrw"
Array .blk 2

 
 .section vectors,"adr"
 .word nmi
 .word reset   
 .word irq
 
