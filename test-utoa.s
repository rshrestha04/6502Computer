; test-utoa.s
; - testing utoa function
;
; written 18 may 2020 by rwk
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
  ; hex conversion
  ;

  .include        ../Utilities/util-tohex.s

  ;
  ; utoa
  ;

  .include        ../Utilities/util-utoa.s

;==============================================================================
; startup code
;

  .section        rom,"acdrx"
reset:
  ldx   #$ff                            ; initialize the stack pointer
  txs

  lcd16_init_macro                      ; initialize the lcd

test_msg          .equ $0200            ; space to hold asciiz output

  ;
  ; display hex source
  ;

  int2hex_macro   test_msg,test_op_2,#4
  lcd16_puts_macro  test_msg

  lda   #$c0                            ; go to next line
  jsr   lcd16_cmd

  ;
  ; convert to decimal
  ;

  utoa_macro      test_msg,test_op_2,#4

  lda   #'['
  jsr   lcd16_putchar

  lcd16_puts_macro  test_msg

  lda   #']'
  jsr   lcd16_putchar

  stp                                   ; halt the processor

test_op_1:
  .byte   $55,$c8,$94,$d1               ; $55c894d1 = 1439208657
test_op_2:
  .byte   $e6,$07,$e2,$7a               ; $e607e27a = 3859276410
test_op_3:
  .byte   0,0,0,0

;==============================================================================
; vector table
;

  .section        vectors,"adr"
  .word   0                             ; NMI interrupt vector
  .word   reset                         ; CPU reset vector
  .word   0                             ; break / IRQ vector
