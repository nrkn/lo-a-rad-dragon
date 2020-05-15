  processor 6502

  include "vcs.h"
  include "macro.h"

; ------------------------------------------------------------------------------
; Setup variables
; ------------------------------------------------------------------------------

  seg.u Variables
  org $80

PlayerX         byte
PlayerY         byte
OldX            byte
OldY            byte
Random          byte

; ------------------------------------------------------------------------------
; Setup consts
; ------------------------------------------------------------------------------
PLAYER_HEIGHT = 8
SWORD_HEIGHT = 8
SHIELD_HEIGHT = 8
BEER_HEIGHT = 8
HEAL_HEIGHT = 8

WEAPON_Y = 20
ARMOR_Y = 30
INN_Y = 40
HEALER_Y = 50


; ------------------------------------------------------------------------------
; Setup rom
; ------------------------------------------------------------------------------

  seg code
  org $f000       ; define the code origin at $f000 - start of the ROM

Start:
  CLEAN_START

; ------------------------------------------------------------------------------
; Init Variables
; ------------------------------------------------------------------------------
  lda #50
  sta PlayerX
  sta PlayerY

; ------------------------------------------------------------------------------
; Render
; ------------------------------------------------------------------------------
StartFrame:

; ------------------------------------------------------------------------------
; Init VSYNC and VBLANK
; ------------------------------------------------------------------------------

  lda #2
  sta VBLANK
  sta VSYNC

  repeat 3
    sta WSYNC
  repend

  lda #0
  sta VSYNC                 ; turn off VSYNC

; ------------------------------------------------------------------------------
; Calculations run before VBLANK
; ------------------------------------------------------------------------------
  lda PlayerX
  ldy #0
  jsr SetObjectXPos         ; set player0 x position

  sta WSYNC
  sta HMOVE                 ; apply the horizontal offets we just set

; ------------------------------------------------------------------------------
; 37 lines of VBLANK minus 2 used above
; ------------------------------------------------------------------------------

  ldx #35
LoopVBlank:
  sta WSYNC
  dex
  bne LoopVBlank

  lda #0
  sta VBLANK                ; turn off VBLANK

; ------------------------------------------------------------------------------
; 192 visible scanlines
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; 2-line kernel
; ------------------------------------------------------------------------------
  lda #$c6                  ; background
  sta COLUBK

  ldx #96                   ; scanline counter
.EachLine:
.IsPlayer:
  txa
  sec                       ; always set carry before sub
  sbc PlayerY
  cmp PLAYER_HEIGHT
  bcc .DrawPlayer
  lda #0                    ; if not draw empty row from sprite

.DrawPlayer:
  tay
  lda PlayerSprite,Y
  sta GRP0
  lda PlayerColors,Y
  sta COLUP0
  sta WSYNC

.IsHealerHut:
  txa
  sec
  sbc HEALER_Y
  cmp HEAL_HEIGHT
  bcc .DrawHealerHut
  jmp .IsInnHut

.DrawHealerHut:
  tay
  lda HealSprite,Y
  sta GRP1
  lda HealColors,Y
  sta COLUP1
  jmp .DrawHutsDone

.IsInnHut:
  txa
  sec
  sbc INN_Y
  cmp BEER_HEIGHT
  bcc .DrawInnHut
  jmp .IsWeaponHut

.DrawInnHut:
  tay
  lda BeerSprite,Y
  sta GRP1
  lda BeerColors,Y
  sta COLUP1
  jmp .DrawHutsDone

.IsWeaponHut:
  txa
  sec
  sbc WEAPON_Y
  cmp SWORD_HEIGHT
  bcc .DrawWeaponHut
  jmp .IsArmorHut

.DrawWeaponHut:
  tay
  lda SwordSprite,Y
  sta GRP1
  lda SwordColors,Y
  sta COLUP1
  jmp .DrawHutsDone

.IsArmorHut:
  txa
  sec
  sbc ARMOR_Y
  cmp SHIELD_HEIGHT
  bcc .DrawArmorHut
  lda #0

.DrawArmorHut:
  tay
  lda ShieldSprite,Y
  sta GRP1
  lda ShieldColors,Y
  sta COLUP1

.DrawHutsDone
  sta WSYNC
  dex
  bne .EachLine

; ------------------------------------------------------------------------------
; Overscan
; ------------------------------------------------------------------------------

  lda #2
  sta VBLANK

  ldx #30
LoopOverscan:
  sta WSYNC
  dex
  bne LoopOverscan

  lda #0
  sta VBLANK

; ------------------------------------------------------------------------------
; Input handler
; ------------------------------------------------------------------------------
CheckP0Up:
  lda #%00010000
  bit SWCHA                 ; compare to joy
  bne CheckP0Down
  inc PlayerY

CheckP0Down:
  lda #%00100000
  bit SWCHA
  bne CheckP0Left
  dec PlayerY

CheckP0Left:
  lda #%01000000
  bit SWCHA
  bne CheckP0Right
  dec PlayerX

CheckP0Right:
  lda #%10000000
  bit SWCHA
  bne EndInputCheck
  inc PlayerX

EndInputCheck:

; ------------------------------------------------------------------------------
; Check collisions
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; Next frame
; ------------------------------------------------------------------------------
  jmp StartFrame

; ------------------------------------------------------------------------------
; Subroutines
; ------------------------------------------------------------------------------
; Horizontal Positioning
; A is the desired x coordinate
; Y is the object type
;   0 = player0, 1 = player1, 2 = missile0, 3 = missile1, 4 = ball
; ------------------------------------------------------------------------------
SetObjectXPos subroutine
  sta WSYNC                 ; start new scanline
  sec                       ; ensure carry flag
.Div15Loop
  sbc #15                   ; sub 15 from desired X to get coarse location
  bcs .Div15Loop            ; loop until carry is clear
  eor #7                    ; put in range -8 to 7
  repeat 4                  ; shift left 4 times, only want top 4 bits
    asl
  repend
  sta HMP0,Y                ; store the fine offset
  sta RESP0,Y               ; store the coarse offset
  rts

; ------------------------------------------------------------------------------
; Random using Linear-Feedback Shift Register
; - Generate random number using LFSR
; ------------------------------------------------------------------------------
SetRandom subroutine
  lda Random
  asl
  eor Random
  asl
  eor Random
  asl
  asl
  eor Random
  asl
  rol Random                ; ok we have LFSR random

  rts

; ------------------------------------------------------------------------------
; ROM Data
; ------------------------------------------------------------------------------
; Bitmaps and colors
; ------------------------------------------------------------------------------
PlayerSprite:
  .byte #%00000000
  .byte #%01001000
  .byte #%11111100
  .byte #%01111000
  .byte #%10000000
  .byte #%10101000
  .byte #%10000000
  .byte #%01111000

SwordSprite:
  .byte #%00000000
  .byte #%00010000
  .byte #%00111000
  .byte #%00010000
  .byte #%00010000
  .byte #%00010000
  .byte #%00010000
  .byte #%00010000

ShieldSprite:
  .byte #%00000000
  .byte #%00111000
  .byte #%01111100
  .byte #%01111100
  .byte #%01111100
  .byte #%01111100
  .byte #%01010100
  .byte #%00000000

BeerSprite:
  .byte #%00000000
  .byte #%11111000
  .byte #%10101100
  .byte #%10101010
  .byte #%10101010
  .byte #%10101010
  .byte #%11111100
  .byte #%11111000

HealSprite:
  .byte #%00000000
  .byte #%00110000
  .byte #%00110000
  .byte #%11111100
  .byte #%11111100
  .byte #%00110000
  .byte #%00110000
  .byte #%00000000

PlayerColors:
  .byte $00
  .byte $96
  .byte $96
  .byte $1c
  .byte $1c
  .byte $1c
  .byte $1c
  .byte $1c

SwordColors:
  .byte $00
  .byte $06
  .byte $0a
  .byte $0e
  .byte $0e
  .byte $0e
  .byte $0e
  .byte $0e

ShieldColors:
  .byte $00
  .byte $06
  .byte $08
  .byte $08
  .byte $08
  .byte $08
  .byte $0a
  .byte $00

BeerColors:
  .byte $00
  .byte $1e
  .byte $1e
  .byte $1e
  .byte $1f
  .byte $1f
  .byte $1f
  .byte $0e

HealColors:
  .byte $00
  .byte $36
  .byte $36
  .byte $36
  .byte $38
  .byte $38
  .byte $38
  .byte $00

; ------------------------------------------------------------------------------
; Fill ROM to exactly 4kb
; ------------------------------------------------------------------------------

  org $fffc
  .word Start     ; tell atari where to start when we reset
  .word Start     ; interupt at $fffe - unused by vcs but makes 4kb
