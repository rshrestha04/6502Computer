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
 lda #%11111111 ;set all pins on port B to output
 sta DDRB
 
 lda #%11100000 ;set top 3 pins on port A to output
 sta DDRA
 
 lda #%00111000; Set 8-bit mode ; 2-line display; 5X8 font
 sta PORTB
 lda #0        ; Clear RS/RW/E bits
 sta PORTA
 lda #E        ;Set E bit to send instruction
 sta PORTA
 lda #0        ; Clear RS/RW/E bits
 sta PORTA
 
  
 lda #%00001110; Display on ; curson on; blink off
 sta PORTB
 lda #0        ; Clear RS/RW/E bits
 sta PORTA
 lda #E        ;Set E bit to send instruction
 sta PORTA
 lda #0        ; Clear RS/RW/E bits
 sta PORTA
 
 lda #%00000110 ;Increment and shift the curson; don't shift display
 sta PORTB
 lda #0        ; Clear RS/RW/E bits
 sta PORTA
 lda #E        ;Set E bit to send instruction
 sta PORTA
 lda #0        ; Clear RS/RW/E bits
 sta PORTA
 
 lda #"F"
 sta PORTB
 lda #RS        ; Clear RS/RW/E bits
 sta PORTA
 lda #(RS | E)        ;Set E bit to send instruction
 sta PORTA
 lda #RS        ; Clear RS/RW/E bits
 sta PORTA
  
 .org $fffc
 .word reset   
 .word $0000
