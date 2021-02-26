; Echos the input from the terminal to the terminal and the LCD
;
; Serial port code from Ben Eater 6502 https://eater.net/6502
; ACIA code from:
; https://www.grappendorf.net/projects/6502-home-computer/acia-serial-interface-hello-world.html
;
; Additional components:
; 6551 ACIA
; 1.8432Mhz osciallator
; TTL/serial converter
;
; Adding ACIA to BE6502:
; - connect CS1 to A14, CS2B to A13 (note: this wastes a lot of address space)
; - connect oscillator to XTL1
; - connect TXD, RXD to TTL/Serial converter
; - connect reset to reset
; - connect CTS, DCD, DSR to ground
; - connect RW to 6502 RW
; - connect phi2 to the 6502's oscillator
; - connect databus lines to databus

; 6522 VIA
PORTB = $8010
PORTA = $8011 
DDRB = $8012
DDRA = $8013


E  = %10000000
RW = %01000000
RS = %00100000

; 6551 ACIA

ACIA_DATA = $8020
ACIA_STATUS = $8021
ACIA_COMMAND = $8022
ACIA_CONTROL = $8023

    .org $8000

reset:
    ; Set up 6522 VIA for the LCD
    lda #%11111111          ; Set all pins on port B to output
    sta DDRB
    lda #%11100001          ; Set top 3 pins on port A to output
    sta DDRA
    lda #%00111000          ; Set 8-bit mode; 2-line display; 5x8 font
    JSR send_lcd_command
    lda #%00001110          ; Display on; cursor on; blink off
    JSR send_lcd_command
    lda #%00000110          ; Increment and shift cursor; don't shift display
    JSR send_lcd_command

    ; Set up 6551 ACIA
    lda #%00001011          ;No parity, no echo, no interrupt
    sta ACIA_COMMAND
    lda #%00011111          ;1 stop bit, 8 data bits, 19200 baud
    sta ACIA_CONTROL

write:
    LDX #0
next_char:
wait_txd_empty:
    LDA ACIA_STATUS
    AND #$10
    BEQ wait_txd_empty
    LDA text,x
    BEQ read
    STA ACIA_DATA
    INX
    JMP next_char
read:
    LDA ACIA_STATUS
    AND #$08
    BEQ read
    LDX ACIA_DATA
    JSR write_acia
    JSR write_lcd           ; Also send to LCD
    JMP read

write_acia:
    STX ACIA_DATA
    JMP read
    RTS

send_lcd_command:
    STA PORTB
    LDA #0                  ; Clear RS/RW/E bits
    STA PORTA
    LDA #E                  ; Set E bit to send instruction
    STA PORTA
    LDA #0                  ; Clear RS/RW/E bits
    STA PORTA
    NOP
    RTS

write_lcd:
    STX PORTB
    LDX #RS                 ; Set RS; Clear RW/E bits
    STX PORTA
    LDX #(RS|E)             ; Set E bit to send instruction
    STX PORTA
    LDX #RS                 ; Clear E bits
    STX PORTA
    NOP
    RTS

nmi:
    RTI

irq:
    RTI

text:                    ; CR   LF  Null
    .byte "Kello World!", $0d, $0a, $00

    .org $FFFA
    .word nmi
    .word reset
    .word irq
