;==============================================================================
; include external defs and sections
;
   
   ;including memory map
   
  .include        ../Memory/memory-map.s
;  .include        memory-map.s
  
  ;including the byte to hexconversion file
  
  .include        ../Utilities/util-tohex.s 

  .include          ../Arithmetic/arith-space.s

 
  
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



R = $fffc  
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

page_size = $0100
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
 
; lda Array 
; jsr print_char

; lda Array+1
; jsr print_char
 
 
 
  lda #<text
  sta cstring_ptr
  lda #>text
  sta cstring_ptr+1
  
  jsr print_cstring
  jsr display_cstring
  
 
 ;=================================================MAIN LOOP=================================== 

;the main loop that prints hello world and waits for commands to be passed

main_loop:
  
  cmp #$B   
  beq go
  jmp main_loop
  
  
;only goes to 'go:' when A is loaded with a End command which is '$B' 


go:
  
  jsr copy_instruction
  
  ;set all back to normal for next cyce of operation
  
  stz acia_rd_ptr
  stz acia_wr_ptr
  stz acia_counter
  stz cstring_ptr
  stz command
  stz operand1
  stz operand2
  stz operand3

  
 
  
  jmp main_loop
 
;=======================================================MAIN LOOP END==========================
 
 
;Instruction to set up the LCD display


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
 
;tables to go through the different commands supported by the 6502 montior 
 
table 
 .word table1
 .byte "page", $00
 .word pagecmd
 
table1 
 .word table2
 .byte "reset", $00
 .word resetcmd
 
table2 
 .word table3
 .byte "poke", $00
 .word pokecmd
 
table3 
 .word table4
 .byte "jump", $00
 .word jumpcmd
 
table4 
 .word table5
 .byte "display", $00
 .word displaycmd
 
  
table5 
 .word $0000
 .byte "string", $00
 .word stringcmd
 
 
 

;======================sub-rotine to send in a C String===================== 


;Prints the csting passed in the terminal 
;used for debugging

 
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
 
;=======================================

;Prints the csting passed to the LCD displa
;used for debugging

display_cstring:
 
 phy
 pha
 
 
 
 ldy #0
.send: 

 
 lda (cstring_ptr),y
 beq .exit
 jsr print_char
 iny
 bra .send
 
.exit:
 pla
 ply
 rts
 
 
text: .ascii "Hello, World from 6502!",'x','8',13,10,0 
error: .ascii "Error!Can't find the command",'x','8',13,10,0 
hextable: .ascii "0123456789ABCDEF"

;========================>>>> C...O...M...M...A...N...D...S <<<<=============================================================



 ; =============================================================R...E....S...E...T===================================>
resetcmd: 
 jsr print_command
 
 jmp reset
 rts
 
 
 
 ; =============================================================P...O....K...E===================================>



;function to change the value of the byte in the given address
;takes operand1 as the address whoes value is to be set
;takes operand2 as the value of the byte that is stored in the given address 


pokecmd:
 
 jsr print_command
 
 
 ldx #0
 lda operand2,x

 cmp #$60
 bcc upperx
 ;; lower case character, so subtract $57
 
 sec
 sbc #$57
 jmp nextx
 
 
upperx:
 cmp #$40
 bcc numberx
 
 ;;upper case character, so subtract $37
 
 sec
 sbc #$037
 jmp nextx
 
numberx:
 sec
 sbc #$30
 
nextx: 
 asl
 asl
 asl
 asl
 sta $A4
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
 inx
 lda operand2,x
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
 cmp #$60
 bcc uppery
 ;; lower case character, so subtract $57
 
 sec
 sbc #$57
 jmp nexty
 
 
uppery:
 cmp #$40
 bcc numbery
 
 ;;upper case character, so subtract $37
 
 sec
 sbc #$037
 jmp nexty
 
numbery:
 sec
 sbc #$30
 
nexty: 
 clc
 adc $A4
 sta $A4
  
 jsr get_address
 
 ;;now do the poke
 
 ldx #0
 
 
 
 
 lda $A3
 jsr hex_print

 
 lda $A2
 jsr hex_print
 
 lda $A4
 jsr hex_print
 
 
 lda $A4
 ldx #0
 sta ($A2,x)
 
 
 lda #$0A
 jsr Send_Char
 
 lda #$0D
 jsr Send_Char
 
 rts
; =============================================================D...I....S...P...L...A...Y===================================>

;displays the $16 bytes following the address passed in hex and ASCII if printable
;takes operand1 as the start address

displaycmd:
 
 jsr print_command
 
 
 
 jsr get_address
 
 
;; Print result 
 
 
 ;printing address to be printed
 
  lda $A3
 jsr hex_print

 
 lda $A2
 jsr hex_print
 
 lda #$20                          ; printing space
 jsr Send_Char
 
 lda $A2
 jsr Send_Char
 
 lda #$3a                          ; printing ':' 
 jsr Send_Char
 
 ldx #0
 
print_next: 
 
 cpx #$16
 beq .done
 
 lda #$20
 jsr Send_Char
 
 stx $AF
 ldy $AF
 
 lda ($00A2), y
 jsr hexascii_print 
 
 inx 
 
 bne print_next
 
.done:

 lda #$0A
 jsr Send_Char
 
 lda #$0D
 jsr Send_Char
 
 rts
 
 
 


 

 
 ;===================================================================================S...T...R...I...N...G===================>

;stores the string passed in the address passed to it termininated by null terminator '$00'
;uses operand1 as the address where the string is stored
;used operand2 as the string that needs to be copied


stringcmd:

 jsr print_command

 
 
 jsr get_address
 
 lda $A3
 jsr hex_print

 
 lda $A2
 jsr hex_print
 
 lda #$20                          ; printing space
 jsr Send_Char
 
 ldy #0
.Cloop 
 lda operand2, y
 sta ($A2),y
 cmp #$00
 beq .done
 jsr Send_Char
 iny
 jmp .Cloop 
 
 
 

.done
 
 iny
 lda #$00
 sta ($A2),y
 
 lda #$0A
 jsr Send_Char
 
 lda #$0D
 jsr Send_Char
 
 
 
 
 
 rts
 
 
 ;; =============================================================P...A....G...E===================================>

;Takes the address as operand1 and displays the entire page conataining the address
; in hex and in ASCII if printable (a-z, A-Z, 0-9)





pagecmd:

 jsr print_command
 
 jsr get_address
 
 lsr $A3
 ror $A2
 
 lsr $A3
 ror $A2
 
 lsr $A3
 ror $A2
 
 lsr $A3
 ror $A2
 
 lsr $A3
 ror $A2
 
 lsr $A3
 ror $A2
 
 lsr $A3
 ror $A2
 
 lsr $A3
 ror $A2
 
;A2 holds the low byte which is the page number 

 
 
 lda $A4
 jsr hex_print
 
 lda $A5
 jsr hex_print
 ; to make A2 high byte we need A1 to be low byte
 
 lda #$00
 sta $A1
 
 ;printing address to be printed
 
 
 lda #$20                          ; printing space
 jsr Send_Char
 
 
 lda #$3a                          ; printing ':' 
 jsr Send_Char
 
 ldx #0
 
.print_next 
 
 cpx #$ff
 beq .done
 
 lda #$20
 jsr Send_Char
 
 stx $AF
 ldy $AF
 
 lda ($00A1), y                  ;since A1 is used as low byte and A2 is high byte we are achivening multiplication by $100 giving us base address of the page 
 jsr hexascii_print 
 
 inx 
 
 bne .print_next
 
.done:

 lda #$0A
 jsr Send_Char
 
 lda #$0D
 jsr Send_Char
 
 
 
 
 
 
 
 rts
 
 ;; =============================================================j...U....M...P...===================================>

;Jumps to the address sent as operand1
;completes the instruction in that address and returns to listening

 
jumpcmd:
 
 jsr print_command 
 
 
 
 
 jsr get_address
 
 ;print adressed jumped 
 
 lda $A3
 jsr hex_print

 
 lda $A2
 jsr hex_print
 
 jmp ($A2)
 
 lda #$0A
 jsr Send_Char
 
 lda #$0D
 jsr Send_Char

 rts
 
;========================''''''''COMMANDS END''''''''''''''''====================================================================================================

;Grabs the address passed, converts it to hex and stores it in $A2 in little endian format
; uses oeprand1 to hold ASCII address
; uses $A2 and $A3 to store the address

get_address:
 
  ;;Turn 1st parameter into an address=======================================
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
 ldx #0
 lda operand1,x
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
  
 cmp #$60
 bcc upper2
 ;; lower case character, so subtract $57
 
 sec
 sbc #$57
 jmp next2
 
 
upper2:
 cmp #$40
 bcc number2
 
 ;;upper case character, so subtract $37
 
 sec
 sbc #$037
 jmp next2
 
number2:
 sec
 sbc #$30
 
next2: 
 asl
 asl
 asl
 asl
 sta $A3
 
 
 
 ;;;;;;;;;;;;;;;;;;;
 inx
 lda operand1,x
 ;;;;;;;;;;;;;;;;;;;
 
 

 
 cmp #$60
 bcc upper3
 ;; lower case character, so subtract $57
 
 sec
 sbc #$57
 jmp next3
 
upper3:
 cmp #$40
 bcc number3
 
 ;;upper case character, so subtract $37
 
 sec
 sbc #$37
 jmp next3
 
number3:
 sec
 sbc #$30
 
next3: 
 clc
 adc $A3
 sta $A3
 

 
 ;;thrid nibble
;;;;;;;;;;;;;;;;;;;;; 
 inx
 lda operand1,x
 
 
 ;;;;;;;;;;;;;;;;;;;;;

 
 
 
 cmp #$60
 bcc upper4
 ;; lower case character, so subtract $57
 
 sec
 sbc #$57
 jmp next4
 
 
upper4:
 cmp #$40
 bcc number4
 
 ;;upper case character, so subtract $37
 
 sec
 sbc #$37
 jmp next4
 
number4:
 sec
 sbc #$30
 
next4: 
 asl
 asl
 asl
 asl
 sta $A2
 

 
 ;fouth nyble
;;;;;;;;;;;;;;;;;;;;;;; 
 inx
 lda operand1,x
;;;;;;;;;;;;;;;;;;;;;;; 
 
 
 cmp #$60
 bcc upper5
 
 
;; lower case character, so subtract $57
 
 sec
 sbc #$57
 jmp next5
 
 
upper5:
 cmp #$40
 bcc number5
 
 ;;upper case character, so subtract $37
 
 sec
 sbc #$37
 jmp next5
 
number5:
 sec
 sbc #$30
 
next5: 
 clc
 adc $A2
 sta $A2
 

 rts
 
;==================================Copy instruction===============


;copies all the parameters passed and stores it in the order it recives
;commands are stored in command, first operand is stored in operand1 and second operand is stored in operand2
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

;compares the command with the command table to find a match to perform the instruction
;if found moves to executing the command else prints error
 
find:

 

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
 
 jmp testentry
 
 
 
 nosuccess: 
  lda #<error
  sta cstring_ptr
  lda #>error
  sta cstring_ptr+1
  jsr print_cstring
  
  
  rts
  
  
;========================P...R...I...N...T.........O...P...E...R...A...N...D============================ 

;prints the operands and commands when necessary
;used for debugging


print_operand2:

 ldy #0
.Cloop 
 lda operand2, y
 beq .exit
 jsr Send_Char
 jmp .Cloop 
.exit
 rts
 
 
 
print_operand1:

 ldy #0
.Bloop 
 lda operand1, y
 beq .exit
 jsr Send_Char
 iny
 jmp .Bloop
.exit
 rts
 
print_command:


 ldy #0
.Aloop 
 lda command, y
 beq .exit
 jsr Send_Char
 iny
 jmp .Aloop 
 
.exit
 lda #$20
 jsr Send_Char
 rts

 
 

 

 


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
 
 
 
;========================PRINT TO HEXXX========================================================

;used to print the values in the address in Hex


hex_print: 

 pha
 
 clc
 and #$f0  ;filter out all but the first 4 bits
 ror
 ror
 ror
 ror
 tay
 lda hextable,y
 jsr Send_Char
 
 
 
 pla
 clc
 and #$0f    ;filter out all but the least 4 bits
 tay
 lda hextable,y
 jsr Send_Char
 
 
 
 ;need space after printing a byte
 lda #$20
 jsr Send_Char
 
 rts
 
;==========================HEX and ASCII PRINT==========
 
;used to print the values in Hex and ASCII if printable 
 
hexascii_print:
 

 
 
 pha
 cmp #$60
 bcc .upper

 
 cmp #$7B
 bcs .notASCII
 
 
 
 jmp .next
 
  

 
 
.upper
 cmp #$40
 bcc .number
 
 cmp #$5B
 bcs .notASCII
 
 jmp .next
 
 
 
.number
 cmp #$30
 bcc .notASCII
 
 cmp #$3a
 bcs .notASCII
 
 jmp .next

 
.notASCII

 
 pla
 pha
 
 clc
 and #$f0  ;filter out all but the first 4 bits
 ror
 ror
 ror
 ror
 tay
 lda hextable,y
 jsr Send_Char
 
 
 
 pla
 clc
 and #$0f    ;filter out all but the least 4 bits
 tay
 lda hextable,y
 jsr Send_Char
 
 
 
 ;need space after printing a byte
 lda #$20
 jsr Send_Char
 jmp .exit
 
 lda #"R"
 jsr Send_Char
 
 
 
.next 
 jsr Send_Char
 pla

.exit

 lda #$20
 jsr Send_Char

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
 
 
 
 
 jmp service_acia_end_signal    ;jump signalling that end of a command has reached 
 
.space_detected

 lda #$00               ;;;newline
 ldx acia_wr_ptr
 sta acia_buff,x
 inc acia_wr_ptr
 inc acia_counter
 
 
 jmp service_acia_end 
 
 
 ; normal acia end
  
service_acia_end:  
 plx
 pla
 rti
 
 ;Acia end when we have to signal end of a command line 
 
service_acia_end_signal:
 plx
 pla
 
 lda #$B 
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
  
  
  
  
  
 ;===========================
  
  ;used to test the jump command
  
  .org $9000
  lda #"T"
  jsr print_char
  
  jmp reset
  
  rts
  
  

;==========================================================================
 .section gpspace,"adrw"
 
 
Array .blk 2

multiplier .blk 4



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
 


 
;==========================================================================

 
 .section vectors,"adr"
 .word acia_read_trigger	;nmi
 .word reset   
 .word irq	; irq
 
