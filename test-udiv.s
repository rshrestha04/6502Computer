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

  .include        ../LCD-16x2/lcd16x2-4.s

  ;
  ; unsigned multiply
  ;

  .include        ../Arithmetic/arith-udiv4.s

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

  lcd16_init_macro                      ; initialize the lcd

test_msg          .equ $0200            ; space to hold hex values
test_op_q         .equ $0220            ; space to hold q
test_op_r         .equ $0228            ; space to hold r

  ;
  ; display operands
  ;

  int2hex_macro   test_msg,test_op_n,#4
  lcd16_puts_macro  test_msg

  lda   #' '
  jsr   lcd16_putchar

  int2hex_macro   test_msg,test_op_d,#2
  lcd16_puts_macro  test_msg

  lda   #$c0                            ; go to next line
  jsr   lcd16_cmd

  ;
  ; compute and display product. answers should be 0x43bd and 0x0994
  ;

  udiv4_macro     test_op_n,test_op_d,test_op_q,test_op_r,#2

;  int2hex_macro   test_msg,scratch_space1,#8
;  lcd16_puts_macro  test_msg
;  stp

  int2hex_macro   test_msg,test_op_q,#2
  lcd16_puts_macro  test_msg

  lda   #' '
  jsr   lcd16_putchar

  int2hex_macro   test_msg,test_op_r,#2
  lcd16_puts_macro  test_msg

  stp                                   ; halt the processor

test_op_n:
  .byte   $1a,$63,$14,$29               ; $1a631429 = 442700841
test_op_d:
  .byte   $63,$b9                       ; $63b9 = 25529

;==============================================================================
; vector table
;

  .section        vectors,"adr"
  .word   0                             ; NMI interrupt vector
  .word   reset                         ; CPU reset vector
  .word   0                             ; break / IRQ vector
