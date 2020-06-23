REM Convert a NASCOM ROM Image to NASSYS LOAD "L" File:
REM ===================================================
rem for QBASIC.EXE or BASIC Compiler 7.1 (BC.EXE)
defint a-z
Input "Input NASCOM ROM File ................: ";rom$
Input "Base Adress of ROM File (e.g. &HD000) : "; rombase
Input "Output NASCOM LOAD File ..............: "; nas$
open rom$ for binary as #1
a$=string$(lof(1),0): get #1,,a$
open nas$ for output as #2
for i=1 to len(a$)
  if (i-1) mod 8 = 0 then
    b$=right$("0000" +hex$(rombase),4): print #2, b$;" ";
    chksum=(val("&H"+mid$(b$,1,2)) + val("&H"+mid$(b$,3,2))) and &HFF
    rombase=rombase+8
  endif
  c=asc(mid$(a$,i,1)): chksum=(chksum+c) and &Hff
  print #2,right$("00" + hex$(c),2);" ";
  if (i-1) mod 8 = 7 then 
    print #2,right$("00"+hex$(chksum),2); chr$(8); chr$(8)
    chksum=0
  endif  
next
print #2, ".": close #2: close #1
end
