PORTB = $8010
PORTA = $8011 
DDRB = $8012
DDRA = $8013

E  = %10000000
RW = %01000000
RS = %00100000

 .org $8000
 .word 0	
 .org $8200

reset:
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
 
 lda #"H"
 jsr print_char
  
 lda #"A"
 jsr print_char
  
 lda #"P"
 jsr print_char

 lda #"P"
 jsr print_char
 
 lda #"Y"
 jsr print_char
 
 lda #"D"
 jsr print_char
 
 lda #"A"
 jsr print_char
 
 lda #"S"
 jsr print_char
 
 lda #"H"
 jsr print_char
 
 lda #"A"
 jsr print_char
 
 lda #"I"
 jsr print_char
 
 lda #"N"
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
 

 
 .org $fffc
 .word reset   
 .word $0000
