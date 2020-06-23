REM Convert a NASSYS Load "L" File to a NASCOM ROM File:
REM ====================================================
REM run with QBASIC.EXE or BASIC Compiler 7.1 BC.EXE
defint a-z
Input "Input  NASCOM LOAD File ...............: ";nas$
Input "Output NASCOM ROM File ................: ";rom$
open nas$ for input as #1
open rom$ for binary as #2
while not eof(1)
  line input #1,a$: a$=ltrim$(a$)
  if left$(a$,1)<>"." and left$(a$,1) <> "T" then
    for i=1 to 8
      buf$=buf$+chr$(val("&H"+mid$(a$, i*3+3,2)))
    next   
  endif
wend
put #2,,buf$
close #2: close #1
end
