  processor 6502

  include "vcs.h"
  include "macro.h"

  seg code
  org $f000       ; define the code origin at $f000 - start of the ROM

Start:
  CLEAN_START

; ------------------------------------------------------------------------------
;
; ------------------------------------------------------------------------------



; ------------------------------------------------------------------------------
; Fill ROM to exactly 4kb
; ------------------------------------------------------------------------------

  org $fffc
  .word Start     ; tell atari where to start when we reset
  .word Start     ; interupt at $fffe - unused by vcs but makes 4kb
