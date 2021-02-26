; test-spin.s
; - lcd spinner, used for testing multi-frequency clock
;
; written 5 june 2020 by rwk
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
  ; two-loop wait
  ;

  .include        ../Utilities/util-wait.s

;==============================================================================
; startup code
;

  .section        rom,"acdrx"
reset:
  ldx   #$ff                            ; initialize the stack pointer
  txs

  lcd16_init_macro                      ; initialize the lcd

loop:
  lda   #'-'
  jsr   lcd16_putchar

  lda   #$80                            ; go to home position
  jsr   lcd16_cmd

  lda   #10
.l1:
  ldx   #100
.l2:
  ldy   #100
.l3:
  dey
  bne   .l3
  dex
  bne   .l2
  dec
  bne   .l1

  lda   #'\'
  jsr   lcd16_putchar

  lda   #$80                            ; go to home position
  jsr   lcd16_cmd

  lda   #10
.l4:
  ldx   #100
.l5:
  ldy   #100
.l6:
  dey
  bne   .l6
  dex
  bne   .l5
  dec
  bne   .l4

  lda   #'|'
  jsr   lcd16_putchar

  lda   #$80                            ; go to home position
  jsr   lcd16_cmd

  lda   #10
.l7:
  ldx   #100
.l8:
  ldy   #100
.l9:
  dey
  bne   .l9
  dex
  bne   .l8
  dec
  bne   .l7

  lda   #'/'
  jsr   lcd16_putchar

  lda   #$80                            ; go to home position
  jsr   lcd16_cmd

  lda   #10
.l10:
  ldx   #100
.l11:
  ldy   #100
.l12:
  dey
  bne   .l12
  dex
  bne   .l11
  dec
  bne   .l10

  bra   loop

;==============================================================================
; vector table
;

  .section        vectors,"adr"
  .word   0                             ; NMI interrupt vector
  .word   reset                         ; CPU reset vector
  .word   0                             ; break / IRQ vector
