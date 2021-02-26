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
 
 ldy #2
 lda #<Array
 sta util_dest_ptr
 lda #>Array
 sta util_dest_ptr+1
 lda ACIA_STATUS
 jsr byte2hex
 
  
 ldx #$ff
 txs
 
 
 lda #%11111111 ;set all pins on port B to output
 sta DDRB
 lda #%11100000 ;set top 3 pins on port A to output
 sta DDRA
 
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
 rts
 
print_char:
 sta PORTB
 lda #RS        ; Clear RS/RW/E bits
 sta PORTA
 lda #(RS | E)        ;Set E bit to send instruction
 sta PORTA
 lda #RS        ; Clear RS/RW/E bits
 sta PORTA
 rts
 
 .section gpspace,"adrw"
Array .blk 2
 
 .section vectors,"adr"
 .word 0
 .word reset   
 .word 0
 
