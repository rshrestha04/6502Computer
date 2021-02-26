; hello4.s
; - version 4, hello world
;
; written 19 april 2020 by rwk
;

;==============================================================================
; include external defs and sections
;

  ;
  ; memory map
  ;

  .include        ../Memory/memory-map.s

  ;
  ; 4-data-line 16x2 LCD
  ;

  .include        ../LCD-16x2/lcd4.s

  ;
  ; unsigned multiply
  ;

  .include        ../Arithmetic/arith-umul3.s

  ;
  ; hex conversion
  ;

  .include        ../Utilities/util-tohex.s

;==============================================================================
; startup code
;

  .section        rom,"acdrx"
reset:
  ldx   #$ff                            ; initialize the stack pointer
  txs

  lcd_init_macro                        ; initialize the lcd

test_msg          .equ $0200            ; space to hold hex values
test_op3          .equ $0220            ; space to hold product

  ;
  ; display operands
  ;

  int2hex_macro   test_msg,test_op1,#2
  lcd_puts_macro  test_msg

  lda   #' '
  jsr   lcd_putchar

  int2hex_macro   test_msg,test_op2,#2
  lcd_puts_macro  test_msg

  lda   #$c0                            ; go to next line
  jsr   lcd_cmd

  ;
  ; compute and display product. answer should be 0x09b01c07
  ;

  umul3_macro     test_op3,test_op1,test_op2,#2

  int2hex_macro   test_msg,test_op3,#4
  lcd_puts_macro  test_msg

  lda   #' '
  jsr   lcd_putchar

  int2hex_macro   test_msg,scratch_space2,#2
  lcd_puts_macro  test_msg

  stp                                   ; halt the processor

test_op1:
  .byte   $62,$83                       ; $6283 = 25219
test_op2:
  .byte   $19,$2d                       ; $192d = 6445

;==============================================================================
; vector table
;

  .section        vectors,"adr"
  .word   0                             ; NMI interrupt vector
  .word   reset                         ; CPU reset vector
  .word   0                             ; break / IRQ vector
