* yellow.main
 lst off

* The job of this routine is to
* set the high-bit of $7C in aux zpage.
* (It does it by rotating in a carry set)

slot = $fd
lastrack = $ff

*-------------------------------------------------
*
* HLS APPLE COPY PROTECTION
* COPYRIGHT (C) 1987 HLS DUPLICATION
*
* Modified by Roland Gustafsson 8/25/89
* for Prince of Persia copy protection.
*
*-------------------------------------------------

OBJSCT = $07 ;PHYSICAL SECTOR #

* ZERO PAGE

HDRC = $30
HDRS = HDRC+1
HDRT = HDRC+2
HDRV = HDRC+3 HEADER SECTOR
LSRETRY = HDRC+4 ;NIB READ RETRIES
PRETRY = HDRC+5 ;OBJSCT RETRIES
NPTR = HDRC+6
NPTRH = HDRC+7
MEM1 = HDRC+8
MEM2 = HDRC+9

zpage = HDRC
zpagelen = 33 ;arbitrarily long (only needs 10)

*-------------------------------------------------

* Jordan says: use $A400-ABFF
* Roland says: OK

orgCHECK = $AAAA ;must be highbyte=lowbyte

 org $2000

 da lenCHECK

 dum $A4A4
zpagebuf ds zpagelen
was27 ds 3 ;should be 1 !!!
was2A ds 5 ; ditto
was26 ds 7 ; ditto again
 dend

 org orgCHECK

*-------------------------------------------------

start sta $C008 ;switch to main zpage

 ldx slot
 lda $C089,x ;drive on

 jsr swapzpage

* First seek track zero

 lda #0
 jsr SEEK

* Now check signature

 lda #10
 sta LSRETRY
 ldx slot
 lda $C08E,X
 lda #>:NIBS
 sta NPTRH
 lda #:NIBS
 sta NPTR

:AGAIN lda #$80
 sta PRETRY
:M1 dec PRETRY
 beq :LSFAIL
 jsr RADR16
 bcs :LSFAIL
 lda HDRS
 cmp #OBJSCT
 bne :M1

 ldy #0
:M2 lda $C08C,X
 bpl :M2
 dey
 beq :LSFAIL
 cmp #$D5
 bne :M2
 ldy #0

:M3 lda $C08C,X
 bpl :M3
 dey
 beq :LSFAIL
 cmp #$E7
 bne :M3

:M4 lda $C08C,X
 bpl :M4
 cmp #$E7
 bne :LSFAIL

:M5 lda $C08C,X
 bpl :M5
 cmp #$E7
 bne :LSFAIL

 lda $C08D,X
 ldy #$10
 bit $6 ;3 US. ( FOR //C)
:M6 lda $C08C,X
 bpl :M6
 dey
 beq :LSFAIL
 cmp #$EE
 bne :M6

* NOW AT 1/2 NIBBLES

 ldy #7
:M7 lda $C08C,X * READ DISK DATA
 bpl :M7
 cmp (NPTR),Y * COMPARE AGAINST TABLE
 bne :LSFAIL
 dey
 bpl :M7
 bmi :GOOD
:LSFAIL jmp :LSFAIL1

* A O K

:GOOD jsr swapzpage
 sta $C009-zpagelen,x
 ror $7C-zpagelen,x
 clc
 rts

* FAILED

:LSFAIL1 dec LSRETRY
 beq :ERROR
 jmp :AGAIN

:NIBS db $FC,$EE,$EE,$FC
 db $E7,$EE,$FC,$E7

:ERROR jsr swapzpage
 sta $C009-zpagelen,x
 rts

*-------------------------------------------------
*
* Read address mark
*

RADR16 ldy #$FD
 sty MEM1
:RA1 iny
 bne :RA2
 inc MEM1
 beq :RAEXIT
:RA2 lda $C08C,X
 bpl :RA2
:RA3 cmp #$D5
 bne :RA1
 nop
:RA4 lda $C08C,X
 bpl :RA4
 cmp #$AA
 bne :RA3
 ldy #3
:RA5 lda $C08C,X
 bpl :RA5
 cmp #$96
 bne :RA3
 lda #0
:RA6 sta MEM2
:RA7 lda $C08C,X
 bpl :RA7
 rol
 sta MEM1
:RA8 lda $C08C,X
 bpl :RA8
 and MEM1
 sta HDRC,Y
 eor MEM2
 dey
 bpl :RA6
 tay
 nop
 clc
 rts

:RAEXIT sec
 rts

*-------------------------------------------------
*
* SEEK, a - track
*

SEEK4 lda #4
SEEK sta was2A
 cmp lastrack
 beq :RTS0
 lda #0
 sta was26
:MOVEHEAD lda lastrack
 sta was27
 sec
 sbc was2A
 beq :ISTHERE
 bcs :T0
 eor #$FF
 inc lastrack
 bcc :T1
:T0 adc #$FE
 dec lastrack
:T1 cmp was26
 bcc :T2
 lda was26
:T2 cmp #$C
 bcs :T3
 tay
:T3 sec
 jsr :CHKPOS
 lda ONTBL,Y
 jsr :MSWAIT
 lda was27
 clc
 jsr :CHKPOS2
 lda OFFTBL,Y
 jsr :MSWAIT
 inc was26
 bne :MOVEHEAD
:ISTHERE jsr :MSWAIT
 clc
:CHKPOS lda lastrack
:CHKPOS2 and #3
 rol
 ora slot
 tax
 lda $C080,X
 ldx slot
:RTS0 rts

:MSWAIT ldx #$12
:T21 dex
 bne :T21
 sec
 sbc #1
 bne :MSWAIT
 rts

*-------------------------------------------------

swapzpage ldx #0
:0 ldy zpagebuf,x
 lda zpage,x
 sty zpage,x
 sta zpagebuf,x
 inx
 cpx #zpagelen
 bne :0
 rts

*-------------------------------------------------

ONTBL db $01,$30,$28,$24,$20,$1E,$1D,$1C,$1C,$1C,$1C,$1C
OFFTBL db $70,$2C,$26,$22,$1F,$1E,$1D,$1C,$1C,$1C,$1C,$1C,$FF,$03

*-------------------------------------------------
lenCHECK = *-orgCHECK

 org

*------------------------------------------------- EOF

 sav yellow.main
