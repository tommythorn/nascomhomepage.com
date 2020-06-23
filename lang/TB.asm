;****************************************************
; NASCOM 2K TINY BASIC

;Assembly file and annotations by Dennis Wray 
;constructed in 2007 using original Wang annotations and my own notes 
;****************************************************

;Assemble with TASM
;Start Tiny Basic: execute from 0D50H to initialise properly

;Adapted by Nascom in the 1970s from Wang's original Tiny Basic for 8080
;Works with Nasbug T2 and Nasbug T4 (not Nassys)

; this is the original heading by Wang:
;**************************************************************
;* 
;*                TINY BASIC FOR INTEL 8080
;*                      VERSION 1.0
;*                    BY LI-CHEN WANG
;*                     10 JUNE, 1976 
;*                       @COPYLEFT 
;*                  ALL WRONGS RESERVED
;* 
;**************************************************************
; Wang originally used restarts instead of subroutines as follows:
;TSTC   RST 1
;OUTC   RST 2
;EXPR   RST 3
;COMP   RST 4
;IGNBLK RST 5
;FINISH RST 6
;TSTV   RST 7

;**************************************************************
; this is for RAM
	.ORG 0000H; dummy so TASM starts at 0000H
	NOP

       .ORG 0C0CH ; lines in Nasbug
ARG1:   .DS  2 ; 0C0CH ;  low area of available mem
ARG2:   .DS  2 ; 0C0EH ;  upper limit of available mem
ARG3:   .DS  2 ; 0C10H ;  no. of lines to list on screen

	.ORG 0C4AH; more lines in Nasbug
_CRT:	.DS	3 ; print reflection
_KBD:	.DS	3 ; keyboard reflection

;Tiny Basic definitions
MACODE: .EQU $ ; put machine code here
        .DS 30H ;bytes for machine code
INITC3: .DS  1 ; should be set to 00 before initialisation
VARBGN: .EQU $ ;variable @(0)
        .DS 36H ; space for variables
CURRNT: .DS  2  ; 0CB7H; points to current line
STKGOS: .DS  2 ; 0CB9H; saves SP in GOSUB
VARNXT: .DS  2 ; 0CBBH ; was 08BB; temp storage
LOPVAR: .DS  2 ; 0CBDH ; 'FOR' loop save area
LOPINC: .DS  2 ; 0CBFH ; was 08BF; increment
LOPLMT: .DS  2 ; 0CC1H ; was 08C1; limit
LOPLN:  .DS  2 ; 0CC3H ; was 08C3; line number
LOPPT:  .DS  2 ; 0CC5H ; was 08C5; text pointer
RANPNT: .DS  1 ; 0CC7H ; was 08C7; lsb for random number pointer
RANMSB: .DS  1 ; 0CC8H ; was 08C8; msb of random number pointer
	.DS  1 ; not used
BUFFER: .EQU $ ; 0CCAH ; start input buffer
        .DS 85H ; space for input buffer
BUFEND: .EQU $ ; 0D4FH ; end input buffer

	.ORG 0D50H ; execute tiny basic from here
	LD HL, TXTUNF
	LD (ARG1), HL
	LD HL, 4FFFH ; upperlimit of ram
	LD (ARG2), HL
	LD HL, 000BH ; no.lines on screen for list
	LD (ARG3), HL
	LD A, 00H; initialise mem
	LD (INITC3), A
	JP 0F800H ; and run tiny basic!


STKLMT: .EQU 0D7AH  ; limit for stack
	.DS 086H ;for stack
BSTACK  .EQU 0E00H ; upper limit for stack

TXTUNF: .EQU 1000H  ;points to unfilled text area, 1000H
TXTBGN: .EQU 1006H ; begin text save area, 1006H

;***************************************************************
;this is for 2k ROM
	.ORG 0F800H
RETCODE: .EQU 1FH  
BACKCODE: .EQU 1DH

;initialisation stuff 
STARTBAS: LD      SP,BSTACK
        CALL    CRLF; display output
; check if already initialised:
        LD      HL,INITC3; this is 00 if not initialised
        LD      A,0C3H
        CP      (HL); test character; C3 if tiny basic already initialised
        JP      Z,RSTART; jump if already initialised
        LD      (HL),A ; character INITC3 initialised to C3
;set end of mem:
        LD      HL,(ARG2); ARG2, end of mem
        LD      (VARBGN),HL; ARG2 sent to VARBGN
;initialise msb of random number pointer:
        LD      A,STARTBAS>>8 & 0FFH 
        LD      (RANMSB),A; F8 to (RANMSB), init. msb of random no. pointer
;set end of text pointer:
LF81B:  LD      HL,TXTBGN
        LD      (TXTUNF),HL;  txtunf, end of text; 
;set end of text marker:
        LD      H,0FFH
        LD      (TXTUNF+2),HL; ; FF marks end of text
;print welcome screen:
RSTART: LD      DE,BBASIC ; points to line to print
        CALL    PRTSTG1; print the line
        JP      STARTB; start basic

BBASIC:	.DB	"B-BASIC V1.1",RETCODE
MCODE:	 JP      MACODE; put machine code here
OK:	.DB	"OK",RETCODE
WHAT:	.DB	"WHAT?", RETCODE
HOW:	.DB	"HOW?", RETCODE
SORRY:	.DB	"SORRY", RETCODE


;**************************************************************
;* 
;* *** MAIN ***
;* 
;* THIS IS THE MAIN LOOP THAT COLLECTS THE TINY BASIC PROGRAM
;* AND STORES IT IN THE MEMORY.
;* 
;* AT START, IT PRINTS OUT "(CR)OK(CR)", AND INITIALIZES THE 
;* STACK AND SOME OTHER INTERNAL VARIABLES.  THEN IT PROMPTS 
;* ">" AND READS A LINE.  IF THE LINE STARTS WITH A NON-ZERO 
;* NUMBER, THIS NUMBER IS THE LINE NUMBER.  THE LINE NUMBER
;* (IN 16 BIT BINARY) AND THE REST OF THE LINE (INCLUDING CR)
;* IS STORED IN THE MEMORY.  IF A LINE WITH THE SAME LINE
;* NUMBER IS ALREaDY THERE, IT IS REPLACED BY THE NEW ONE.  IF
;* THE REST OF THE LINE CONSISTS OF A CR ONLY, IT IS NOT STORED
;* AND ANY EXISTING LINE WITH THE SAME LINE NUMBER IS DELETED. 
;* 
;* AFTER A LINE IS INSERTED, REPLACED, OR DELETED, THE PROGRAM 
;* LOOPS BACK AND ASK FOR ANOTHER LINE.  THIS LOOP WILL BE 
;* TERMINATED WHEN IT READS A LINE WITH ZERO OR NO LINE
;* NUMBER; AND CONTROL IS TRANSFERED TO "DIRECT".
;* 
;* TINY BASIC PROGRAM SAVE AREA STARTS AT THE MEMORY LOCATION
;* LABELED "TXTBGN" AND ENDED AT "TXTEND".  WE ALWAYS FILL THIS
;* AREA STARTING AT "TXTBGN", THE UNFILLED PORTION IS POINTED
;* BY THE CONTENT OF A MEMORY LOCATION LABELED "TXTUNF". 
;* 
;* THE MEMORY LOCATION "CURRNT" POINTS TO THE LINE NUMBER
;* THAT IS CURRENTLY BEING INTERPRETED.  WHILE WE ARE IN 
;* THIS LOOP OR WHILE WE ARE INTERPRETING A DIRECT COMMAND 
;* (SEE NEXT SECTION), "CURRNT" SHOULD POINT TO A 0. 
;* 
  
STARTB: LD      SP,BSTACK
        LD      HL,DUMMY2+1 ;so current points to 0
        LD      (CURRNT),HL; currnt points to current line
DUMMY2: LD      HL,0000H
        LD      (LOPVAR),HL ;'FOR' loop save area
        LD      (STKGOS),HL ;saves SP in 'GOSUB'
        LD      DE,OK; for string "OK"
        CALL    PRTSTG1; display string until CR
ST3:    LD      A,3EH; prompt > , main loop to here
        CALL    GETLN;read a line
        PUSH    DE;DE to end of line
        LD      DE,BUFFER; DE to beginning of line
        CALL    TSTNUM; test if it is a number
        CALL    IGNBLK
        LD      A,H; HL=value of the no or
        OR      L; 0 if no number found
        POP     BC;BC to end of line
        JP      Z,DIRECT
        DEC     DE;backup DE and save
        LD      A,H;value of line no. there
        LD      (DE),A
        DEC     DE
        LD      A,L
        LD      (DE),A
        PUSH    BC; BC begin, DE end
        PUSH    DE
        LD      A,C
        SUB     E
        PUSH    AF; A is no of bytes in line
        CALL    FNDLN; find this line in save
LF88E:  PUSH    DE; DE save area
        JP      NZ,ST4; NZ, not found, insert
        PUSH    DE ;Z found, delete it
        CALL    FNDNXT; find next line, DE to next line
        POP     BC; BC to line to be deleted
        LD      HL,(TXTUNF); HL to unfilled save area, TXTUNF
        CALL    MVUP; move up to delete
        LD      H,B;TXTUNF to unfilled area
        LD      L,C
        LD      (TXTUNF),HL;update
ST4:    POP     BC; get ready to insert
        LD      HL,(TXTUNF); but first check if
        POP     AF; length of the new line
        PUSH    HL; is 3 (line no. and CR)
        CP      03H; then do not insert
        JP      Z,STARTB; must clear the stack
        ADD     A,L; compute new TXTUNF
        LD      E,A
        LD      A,00H
        ADC     A,H
	LD	D,A 
	LD	HL, (VARBGN)
        EX      DE,HL 
        CALL    COMP;  check if enough space
        JP      NC,QSORRY; sorry no room for it
        LD      (TXTUNF),HL;ok, update TXTUNF
        POP     DE; DE to old unfilled area
        CALL    MVDOWN; MVDOWN
        POP     DE;DE to begin, HL to end
        POP     HL
        CALL    MVUP; move new line to save
        JP      ST3; area


;**************************************************************
;* 
;* *** TABLES *** DIRECT *** & EXEC ***
;* 
;* THIS SECTION OF THE CODE TESTS A STRING AGAINST A TABLE.
;* WHEN A MATCH IS FOUND, CONTROL IS TRANSFERED TO THE SECTION 
;* OF CODE ACCORDING TO THE TABLE. 
;* 
;* AT 'EXEC', DE SHOULD POINT TO THE STRING AND HL SHOULD POINT
;* TO THE TABLE-1.  AT 'DIRECT', DE SHOULD POINT TO THE STRING,
;* HL WILL BE SET UP TO POINT TO TAB1-1, WHICH IS THE TABLE OF 
;* ALL DIRECT AND STATEMENT COMMANDS.
;* 
;* A '.' IN THE STRING WILL TERMINATE THE TEST AND THE PARTIAL 
;* MATCH WILL BE CONSIDERED AS A MATCH.  E.G., 'P.', 'PR.',
;* 'PRI.', 'PRIN.', OR 'PRINT' WILL ALL MATCH 'PRINT'. 
;* 
;* THE TABLE CONSISTS OF ANY NUMBER OF ITEMS.  EACH ITEM 
;* IS A STRING OF CHARACTERS WITH BIT 7 SET TO 0 AND 
;* A JUMP ADDRESS STORED HI-LOW WITH BIT 7 OF THE HIGH 
;* BYTE SET TO 1.
;* 
;* END OF TABLE IS AN ITEM WITH A JUMP ADDRESS ONLY.  IF THE 
;* STRING DOES NOT MATCH ANY OF THE OTHER ITEMS, IT WILL 
;* MATCH THIS NULL ITEM AS DEFAULT.
;* 


DIRECT: LD      HL,TAB1-1
EXEC:   CALL    IGNBLK; ignore leading blanks  **EXEC**
        PUSH    DE; save pointer
EX1:    LD      A,(DE);if found . in string
        INC     DE;before any mismatch
        CP      2EH; matches
        JP      Z,EX3
        INC     HL; HL to table
        CP      (HL); if match, test next
        JP      Z,EX1
        LD      A,7FH; else see if bit 7
        DEC     DE; of table is set, which
        CP      (HL);is the jump addr (HI)
        JP      C,EX5;C, yes , matched
EX2:    INC     HL;NC, No, find jump addr.
        CP      (HL)
        JP      NC,EX2
        INC     HL; bump to next tab. item
        POP     DE;restore string pointer
        JP      EXEC; test against next item
EX3:    LD      A,7FH; partial match, find
EX4:    INC     HL;jump addr. which is
        CP      (HL); flagged by bit 7
        JP      NC,EX4
EX5:    LD      A,(HL); ld HL with jump
        INC     HL; address from the table
        LD      L,(HL)
        AND     0FFH; mask off bit 7
        LD      H,A
        POP     AF; clean up
        JP      (HL); and go do it

;**************************************************************
;* 
;* WHAT FOLLOWS IS THE CODE TO EXECUTE DIRECT AND STATEMENT
;* COMMANDS.  CONTROL IS TRANSFERED TO THESE POINTS VIA THE
;* COMMAND TABLE LOOKUP CODE OF 'DIRECT' AND 'EXEC' IN LAST
;* SECTION.  AFTER THE COMMAND IS EXECUTED, CONTROL IS 
;* TRANSFERED TO OTHER SECTIONS AS FOLLOWS:
;* 
;* FOR 'LIST', 'NEW', AND 'STOP': GO BACK TO 'RSTART'
;* FOR 'RUN': GO EXECUTE THE FIRST STORED LINE IF ANY; ELSE
;* GO BACK TO 'RSTART'.
;* FOR 'GOTO' AND 'GOSUB': GO EXECUTE THE TARGET LINE. 
;* FOR 'RETURN' AND 'NEXT': GO BACK TO SAVED RETURN LINE.
;* FOR ALL OTHERS: IF 'CURRNT' -> 0, GO TO 'RSTART', ELSE
;* GO EXECUTE NEXT COMMAND.  (THIS IS DONE IN 'FINISH'.) 
;* 
;**************************************************************
;* 
;* *** NEW *** STOP *** RUN (& FRIENDS) *** & GOTO *** 
;* 
;* 'NEW(CR)' SETS 'TXTUNF' TO POINT TO 'TXTBGN'
;* 
;* 'STOP(CR)' GOES BACK TO 'RSTART'
;* 
;* 'RUN(CR)' FINDS THE FIRST STORED LINE, STORE ITS ADDRESS (IN
;* 'CURRNT'), AND START EXECUTE IT.  NOTE THAT ONLY THOSE
;* COMMANDS IN TAB2 ARE LEGAL FOR STORED PROGRAM.
;* 
;* 
;* THERE ARE 3 MORE ENTRIES IN 'RUN':
;* 'RUNNXL' FINDS NEXT LINE, STORES ITS ADDR. AND EXECUTES IT. 
;* 'RUNTSL' STORES THE ADDRESS OF THIS LINE AND EXECUTES IT. 
;* 'RUNSML' CONTINUES THE EXECUTION ON SAME LINE.
;* 
;* 'GOTO EXPR(CR)' EVALUATES THE EXPRESSION, FIND THE TARGET 
;* LINE, AND JUMP TO 'RUNTSL' TO DO IT.
;* 'DLOAD' LOADS A NAMED PROGRAM FROM DISK.
;* 'DSAVE' SAVES A NAMED PROGRAM ON DISK.
;* 'FCBSET' SETS UP THE FILE CONTROL BLOCK FOR SUBSEQUENT DISK I/O.
;* 
NEW:    CALL    ENDCHK; *NEW*; is label NEW really
        JP      LF81B

STOP:   CALL    ENDCHK;*STOP*
        JP      STARTB; jmp restart

RUN:    CALL    ENDCHK;* RUN*
        LD      DE,TXTUNF+2; TXTBGN, first saved line

RUNNXL:  LD	HL,0000H ;* RUNNXL*
        CALL    FNDLNP;find whatever line no 
        JP      C,STARTB; C, passed TXTUNF, quit

RUNTSL:  EX      DE,HL; * RUNTSL*
        LD      (CURRNT),HL; set current to line number
        EX      DE,HL
        INC     DE; bump pass line no
        INC     DE

RUNSML:  CALL    CHKIO1; *RUNSML*
        LD      HL,TAB2-1;  find command in table2
        JP      EXEC; and execute it

GOTO:   CALL    EXPR; *GOTO EXPR*
        PUSH    DE; save for error routine
        CALL    ENDCHK; must find a CR
        CALL    FNDLN; find the target line
        JP      NZ,AHOW; no such line no
        POP     AF ;clear the 'push DE'
        JP      RUNTSL; go do it


;************************************************************* 
;* 
;* *** LIST *** & PRINT ***
;* 
;* LIST HAS TWO FORMS: 
;* 'LIST(CR)' LISTS ALL SAVED LINES
;* 'LIST #(CR)' START LIST AT THIS LINE #
;* YOU CAN STOP THE LISTING BY CONTROL C KEY 
;* 
;* PRINT COMMAND IS 'PRINT ....;' OR 'PRINT ....(CR)'
;* WHERE '....' IS A LIST OF EXPRESIONS, FORMATS, BACK-
;* ARROWS, AND STRINGS.  THESE ITEMS ARE SEPERATED BY COMMAS.
;* 
;* A FORMAT IS A POUND SIGN FOLLOWED BY A NUMBER.  IT CONTROLS 
;* THE NUMBER OF SPACES THE VALUE OF A EXPRESION IS GOING TO 
;* BE PRINTED.  IT STAYS EFFECTIVE FOR THE REST OF THE PRINT 
;* COMMAND UNLESS CHANGED BY ANOTHER FORMAT.  IF NO FORMAT IS
;* SPECIFIED, 6 POSITIONS WILL BE USED.
;* 
;* A STRING IS QUOTED IN A PAIR OF SINGLE QUOTES OR A PAIR OF
;* DOUBLE QUOTES.
;* 
;* A BACK-ARROW MEANS GENERATE A (CR) WITHOUT (LF) 
;* 
;* A (CRLF) IS GENERATED AFTER THE ENTIRE LIST HAS BEEN
;* PRINTED OR IF THE LIST IS A NULL LIST.  HOWEVER IF THE LIST 
;* ENDED WITH A COMMA, NO (CRLF) IS GENERATED. 
;* 

;LIST
LIST:   CALL    TSTNUM; test if there is a no.
        CALL    ENDCHK; if no number we get a 0
        CALL    FNDLN; find this or next line
        JP      C,STARTB; C, passed TXTUNF
        PUSH    HL
LF948:  LD      HL,(ARG3); sets no of lines to list
LF94B:  EX      (SP),HL
        CALL    PRTLN ; print line number
        CALL    PRTSTG1 ;print rest of line?
        CALL    FNDLNP ; find next line, DE points, C/Z set/reset
        JP      C,STARTB ; for 'OK', end text area
        CALL    CHKIO1 ; check if keypresssed
	EX (SP),HL ; get back no of lines
        DEC     HL; one line done
        LD      A,H
        OR      L ; see if ARG3 lines have been listed
        JR      NZ,LF94B  ;  no, do more lines
        CALL    CHKIO2; keyboard in; waits for any input
        JR      LF948 ; list next screen of lines

        NOP     
        NOP     
        NOP     
        NOP     
        NOP 

    
;PRINT
PRINT:  LD      C,08H; C=no. of spaces
        CALL    TSTC; if null list & ";"
.DB	3BH  ; ";"
.DB     06H
        call	CRLF; for CR-LF and
        JP      RUNSML; continue same line
        CALL    TSTC;PR2, if null list (CR)
        .DB	RETCODE, 24H
        CALL    CRLF;also give CR-LF and
        JP      RUNNXL; go to next line
PR0:    CALL    TSTC; else is it format?
	.DB 	"#",0EH
	call 	EXPR; yes, evaluate expr.
        LD      A,0C0H
        AND     L
        OR      H
        JP      NZ,QHOW ;?
        LD      C,L ;and save it in C
        JP      PR3 ;look for more to print
        CALL    QTSTG ;PR1, or is it a string?
        JP      PR8 ; if not, must be EXPR.
PR3:    CALL    TSTC ;  if ",", go find next
        .db 	2CH,13H ; ",",13H
LF9A1:  CALL    TSTC ; again
        .db	2CH,08H; ","
        LD      A,20H
        CALL    OUTC
        JP      LF9A1
        CALL    FIN;in the list
        JP      PR0;list continues
        CALL    CRLF; PR6, list ends
        JP      FINISH
PR8:    CALL    EXPR; evaluate the expr
        PUSH    BC
        CALL    PRTNUM;print the value
        POP     BC
        JP      PR3; more to print?

;**************************************************************
;* 
;* *** GOSUB *** & RETURN ***
;* 
;* 'GOSUB EXPR;' OR 'GOSUB EXPR (CR)' IS LIKE THE 'GOTO' 
;* COMMAND, EXCEPT THAT THE CURRENT TEXT POINTER, STACK POINTER
;* ETC. ARE SAVE SO THAT EXECUTION CAN BE CONTINUED AFTER THE
;* SUBROUTINE 'RETURN'.  IN ORDER THAT 'GOSUB' CAN BE NESTED 
;* (AND EVEN RECURSIVE), THE SAVE AREA MUST BE STACKED.
;* THE STACK POINTER IS SAVED IN 'STKGOS'. THE OLD 'STKGOS' IS 
;* SAVED IN THE STACK.  IF WE ARE IN THE MAIN ROUTINE, 'STKGOS'
;* IS ZERO (THIS WAS DONE BY THE "MAIN" SECTION OF THE CODE),
;* BUT WE STILL SAVE IT AS A FLAG FOR NO FURTHER 'RETURN'S.
;* 
;* 'RETURN(CR)' UNDOS EVERYHING THAT 'GOSUB' DID, AND THUS
;* RETURN THE EXCUTION TO THE COMMAND AFTER THE MOST RECENT
;* 'GOSUB'.  IF 'STKGOS' IS ZERO, IT INDICATES THAT WE 
;* NEVER HAD A 'GOSUB' AND IS THUS AN ERROR. 



GOSUB:  CALL    PUSHA; save the current "FOR"
        CALL    EXPR;  parameters
        PUSH    DE;and text pointer
        CALL    FNDLN;find the target line
        JP      NZ,AHOW;not there
        LD      HL,(CURRNT); found it, save old
        PUSH    HL;"currnt" old "stkgos"
        LD      HL,(STKGOS);stkgos
        PUSH    HL
        LD      HL,0000H; and load new ones
        LD      (LOPVAR),HL;lopvar
        ADD     HL,SP
        LD      (STKGOS),HL;stkgos
        JP      RUNTSL;runtsl, then run that line
RETURN: CALL    ENDCHK;endchk, there must be a CR
        LD      HL,(STKGOS);stkgos, old stack pointer
        LD      A,H;0 means not exist
        OR      L
        JP      Z,QWHAT;QWHAT, so, we say "WHAT?"
        LD      SP,HL; else, restore it
        POP     HL
        LD      (STKGOS),HL;and the old stkgos
        POP     HL
        LD      (CURRNT),HL; and the old currnt
        POP     DE;old text pointer
        CALL    POPA;old "FOR" parmeters
        JP      FINISH; and we are back home

;* 
;**************************************************************
;* 
;* *** FOR *** & NEXT ***
;* 
;* 'FOR' HAS TWO FORMS:
;* 'FOR VAR=EXP1 TO EXP2 STEP EXP1' AND 'FOR VAR=EXP1 TO EXP2' 
;* THE SECOND FORM MEANS THE SAME THING AS THE FIRST FORM WITH 
;* EXP1=1.  (I.E., WITH A STEP OF +1.) 
;* TBI WILL FIND THE VARIABLE VAR. AND SET ITS VALUE TO THE
;* CURRENT VALUE OF EXP1.  IT ALSO EVALUATES EXPR2 AND EXP1
;* AND SAVE ALL THESE TOGETHER WITH THE TEXT POINTER ETC. IN 
;* THE 'FOR' SAVE AREA, WHICH CONSISTS OF 'LOPVAR', 'LOPINC',
;* 'LOPLMT', 'LOPLN', AND 'LOPPT'.  IF THERE IS ALREADY SOME-
;* THING IN THE SAVE AREA (THIS IS INDICATED BY A NON-ZERO 
;* 'LOPVAR'), THEN THE OLD SAVE AREA IS SAVED IN THE STACK 
;* BEFORE THE NEW ONE OVERWRITES IT. 
;* TBI WILL THEN DIG IN THE STACK AND FIND OUT IF THIS SAME
;* VARIABLE WAS USED IN ANOTHER CURRENTLY ACTIVE 'FOR' LOOP. 
;* IF THAT IS THE CASE THEN THE OLD 'FOR' LOOP IS DEACTIVATED.
;* (PURGED FROM THE STACK..) 
;* 
;* 'NEXT VAR' SERVES AS THE LOGICAL (NOT NECESSARILLY PHYSICAL)
;* END OF THE 'FOR' LOOP.  THE CONTROL VARIABLE VAR. IS CHECKED
;* WITH THE 'LOPVAR'.  IF THEY ARE NOT THE SAME, TBI DIGS IN 
;* THE STACK TO FIND THE RIGHT ONE AND PURGES ALL THOSE THAT 
;* DID NOT MATCH.  EITHER WAY, TBI THEN ADDS THE 'STEP' TO 
;* THAT VARIABLE AND CHECK THE RESULT WITH THE LIMIT.  IF IT 
;* IS WITHIN THE LIMIT, CONTROL LOOPS BACK TO THE COMMAND
;* FOLLOWING THE 'FOR'.  IF OUTSIDE THE LIMIT, THE SAVE ARER 
;* IS PURGED AND EXECUTION CONTINUES.
;* 

FOR:    CALL    PUSHA; save the old save area
        CALL    SETVAL; set the control var
        DEC     HL; HL is its address
        LD      (LOPVAR),HL;lopvar, save that
        LD      HL,TAB5-1; use exec to look
        JP      EXEC; exec,for the word 'TO'
FR1:    CALL    EXPR;  evaluate the limit
        LD      (LOPLMT),HL; save that
        LD      HL,TAB6-1; 0FF74H;use 'exec' to look
        JP      EXEC;exec,for the word 'step'
FR2:    CALL    EXPR;found it, get step
        JP      FR4
FR3:    LD      HL,0001H; not found, set to 1
FR4:    LD      (LOPINC),HL;lopinc, save that too
        LD      HL,(CURRNT);currnt,save current line no.
        LD      (LOPLN),HL
        EX      DE,HL; and text pointer
        LD      (LOPPT),HL
        LD      BC,000AH; dig into stack to
        LD      HL,(LOPVAR); lopvar, find lopvar
        EX      DE,HL
        LD      H,B
        LD      L,B;HL=0 now
        ADD     HL,SP;here is the stack
        JP      LFA42; error?
FR7:    ADD     HL,BC;each level is 10 deep
LFA42:  LD      A,(HL);get that old lopvar
        INC     HL
        OR      (HL)
        JP      Z,FR8; 0 says no more in it
        LD      A,(HL)
        DEC     HL
        CP      D; same as this one?
        JP      NZ,FR7
        LD      A,(HL);the other half
        CP      E
        JP      NZ,FR7
        EX      DE,HL;yes, found one
        LD      HL,0000H
        ADD     HL,SP; try to move SP
        LD      B,H
        LD      C,L
        LD      HL,000AH
        ADD     HL,DE
        CALL    MVDOWN; and purge 10 words
        LD      SP,HL; in the stack
FR8:    LD      HL,(LOPPT);loppt, job done, restore DE
        EX      DE,HL
        JP      FINISH; and continue


NEXT:   CALL    TSTV; get address of var.;label is NEXT really
        JP      C,QWHAT; no variable, "WHAT?"
        LD      (VARNXT),HL; yes, save it
NX0:    PUSH    DE; save text pointer
        EX      DE,HL
        LD      HL,(LOPVAR); lopvar, get var. in 'FOR'
        LD      A,H
        OR      L; 0 says never had one
        JP      Z,AWHAT; so we ask what?
        CALL    COMP;  else we check them
        JP      Z,NX3; ok they agree
        POP     DE; no, let's see
        CALL    POPA;purge current loop
        LD      HL,(VARNXT);varnxt,and pop one level
        JP      NX0;go check again
NX3:    LD      E,(HL);come here when agreed
        INC     HL
        LD      D,(HL); DE=value of var.
        LD      HL,(LOPINC);lopinc
        PUSH    HL
        LD      A,H
        XOR     D
        LD      A,D
        ADD     HL,DE; add one step
        JP      M,LFA9E
        XOR     H
        JP      M,LFAC2
LFA9E:  EX      DE,HL
        LD      HL,(LOPVAR); lopvar, put it back
        LD      (HL),E
        INC     HL
        LD      (HL),D
        LD      HL,(LOPLMT);loplmt, HL to limit
        POP     AF;old HL
        OR      A
        JP      P,NX1; step>0
        EX      DE,HL
NX1:    CALL    CKHLDE;compare with limit
        POP     DE;restore text pointer
        JP      C,NX2;outside limit
        LD      HL,(LOPLN);lopln,within limit,go
        LD      (CURRNT),HL;currnt,back to the saved
        LD      HL,(LOPPT);loppt, currnt and text
        EX      DE,HL;pointer
        JP      FINISH
LFAC2:  POP     HL
        POP     DE
NX2:    CALL    POPA; purge this loop
        JP      FINISH
;* 
;**************************************************************
;* 
;* *** REM *** IF *** INPUT *** & LET (& DEFLT) ***
;* 
;* 'REM' CAN BE FOLLOWED BY ANYTHING AND IS IGNORED BY TBI.
;* TBI TREATS IT LIKE AN 'IF' WITH A FALSE CONDITION.
;* 
;* 'IF' IS FOLLOWED BY AN EXPR. AS A CONDITION AND ONE OR MORE 
;* COMMANDS (INCLUDING OUTHER 'IF'S) SEPERATED BY SEMI-COLONS. 
;* NOTE THAT THE WORD 'THEN' IS NOT USED.  TBI EVALUATES THE 
;* EXPR. IF IT IS NON-ZERO, EXECUTION CONTINUES.  IF THE 
;* EXPR. IS ZERO, THE COMMANDS THAT FOLLOWS ARE IGNORED AND
;* EXECUTION CONTINUES AT THE NEXT LINE. 
;* 
;* 'INPUT' COMMAND IS LIKE THE 'PRINT' COMMAND, AND IS FOLLOWED
;* BY A LIST OF ITEMS.  IF THE ITEM IS A STRING IN SINGLE OR 
;* DOUBLE QUOTES, OR IS A BACK-ARROW, IT HAS THE SAME EFFECT AS
;* IN 'PRINT'.  IF AN ITEM IS A VARIABLE, THIS VARIABLE NAME IS
;* PRINTED OUT FOLLOWED BY A COLON.  THEN TBI WAITS FOR AN 
;* EXPR. TO BE TYPED IN.  THE VARIABLE IS THEN SET TO THE
;* VALUE OF THIS EXPR.  IF THE VARIABLE IS PROCEDED BY A STRING
;* (AGAIN IN SINGLE OR DOUBLE QUOTES), THE STRING WILL BE
;* PRINTED FOLLOWED BY A COLON.  TBI THEN WAITS FOR INPUT EXPR.
;* AND SET THE VARIABLE TO THE VALUE OF THE EXPR.
;* 
;* IF THE INPUT EXPR. IS INVALID, TBI WILL PRINT "WHAT?",
;* "HOW?" OR "SORRY" AND REPRINT THE PROMPT AND REDO THE INPUT.
;* THE EXECUTION WILL NOT TERMINATE UNLESS YOU TYPE CONTROL-C. 
;* THIS IS HANDLED IN 'INPERR'.
;* 
;* 'LET' IS FOLLOWED BY A LIST OF ITEMS SEPERATED BY COMMAS. 
;* EACH ITEM CONSISTS OF A VARIABLE, AN EQUAL SIGN, AND AN EXPR. 
;* TBI EVALUATES THE EXPR. AND SET THE VARIBLE TO THAT VALUE.
;* TB WILL ALSO HANDLE 'LET' COMMAND WITHOUT THE WORD 'LET'.
;* THIS IS DONE BY 'DEFLT'.

REM:    LD      HL,0000H ;    ** REM****
        JP      LFAD3; should be just db  3EH ?????; this is like 'IF 0'

IF:     CALL    EXPR; ***IF**
LFAD3:  LD      A,H; is the expr.=0?
        OR      L
        JP      NZ,RUNSML; no continue
        CALL    FNDSKP; yes skip rest of line
        JP      NC,RUNTSL
        JP      STARTB;RSTART


INPERR: LD      HL,(VARNXT); **INPERR**
        LD      SP,HL; restore old SP
        POP     HL;and old currnt
        LD      (CURRNT),HL;currnt
        POP     DE; and old text pointer
        POP     DE;redo input

INPUT:  PUSH    DE; **INPUT**, save in case of error
        CALL    QTSTG;is next item a string?
        JP      IP2; no
        CALL    TSTV; yes, but followed by a 
        JP      C,IP4; variable? no.
LFAF8:  CALL    LFB2C ; goes to another part of 'INPUT'
        LD      DE,BUFFER; points to buffer
        CALL    EXPR ; evaluate input
        CALL    ENDCHK
        POP     DE;ok,get old HL
        EX      DE,HL
        LD      (HL),E;save value in var
        INC     HL
        LD      (HL),D
        POP     HL;get old currnt
        LD      (CURRNT),HL;currnt
        POP     DE;and old text pointer
IP4:    POP     AF;purge junk in stack
        CALL    TSTC;is next ch. ','?
	.DB	2CH,03H ;","
        JP      INPUT;yes more items
        JP      FINISH;rst 6

IP2:    PUSH    DE ;save for prtstg
        CALL    TSTV; must be variable now
        JP      NC,LFB24
        JP      QWHAT; 'what?' it is not?
LFB24:  LD      B,E
        POP     DE
        CALL    LFEA3
        JP      LFAF8

;subroutine - part of "INPUT"
LFB2C:  POP     BC
        PUSH    DE; save in case of error
        EX      DE,HL
        LD      HL,(CURRNT); also save currnt
        PUSH    HL
        LD      HL,INPUT ; a negative number
        LD      (CURRNT),HL;as a flag
        LD      HL,0000H; save SP too
        ADD     HL,SP
        LD      (VARNXT),HL
        PUSH    DE
        LD      A,20H
        PUSH    BC
        JP      GETLN


DEFLT:  LD      A,(DE);**DEFLT**
        CP      RETCODE; empty line is ok
        JP      Z,LT1;else it is 'let'

LET:    CALL    SETVAL;**LET**
        CALL    TSTC; set value to var.
	.db 	2CH, 03H ;","
        JP      LET;item by item
LT1:    JP      FINISH; until finish

;* 
;**************************************************************
;* 
;* *** EXPR ***
;* 
;* 'EXPR' EVALUATES ARITHMETICAL OR LOGICAL EXPRESSIONS. 
;* <EXPR>::=<EXPR2>
;*          <EXPR2><REL.OP.><EXPR2>
;* WHERE <REL.OP.> IS ONE OF THE OPERATORS IN TAB8 AND THE 
;* RESULT OF THESE OPERATIONS IS 1 IF TRUE AND 0 IF FALSE. 
;* <EXPR2>::=(+ OR -)<EXPR3>(+ OR -<EXPR3>)(....)
;* WHERE () ARE OPTIONAL AND (....) ARE OPTIONAL REPEATS.
;* <EXPR3>::=<EXPR4>(<* OR /><EXPR4>)(....)
;* <EXPR4>::=<VARIABLE>
;*           <FUNCTION>
;*           (<EXPR>)
;* <EXPR> IS RECURSIVE SO THAT VARIABLE '@' CAN HAVE AN <EXPR> 
;* AS INDEX, FNCTIONS CAN HAVE AN <EXPR> AS ARGUMENTS, AND
;* <EXPR4> CAN BE AN <EXPR> IN PARANTHESE. 
;* 

;subroutine; was a rst 3, evaluate an expression
EXPR:   CALL    EXPR2; EXPR This is at loc. 18
        PUSH    HL; save <expr2> value
        LD      HL,TAB8-1 ; lookup rel. op.
        JP      EXEC;go do it
XP11:   CALL    XP18;XP18, rel.op.">="
        RET     C;no, return HL=0
        LD      L,A;yes,return HL=1
        RET     
XP12:   CALL    XP18;rel.op."#"
        RET     Z;false,return hl=0
        LD      L,A;true, return hl=1
        RET     
XP13:   CALL    XP18;rel.op.">"
        RET     Z;false
        RET     C;also false, hl=0
        LD      L,A;true,hl=1
        RET     
XP14:   CALL    XP18; rel. op."<="
        LD      L,A;set hl=1
        RET     Z;rel. true, return
        RET     C
        LD      L,H;else set hl=0
        RET     
XP15:   CALL    XP18;rel.op."="
        RET     NZ;false,retrun hl=0
        LD      L,A;else set hl=1
        RET     
XP16:   CALL    XP18;rel.op. "<"
        RET     NC;false, return hl=0
        LD      L,A;else set hl=1
        RET     
XP17:   POP     HL;not rel.op.
        RET     ;return hl=<expr2>

XP18:   LD      A,C;xp18, subroutine for all
        POP     HL;rel. ops.
        POP     BC
        PUSH    HL;reverse top of stack
        PUSH    BC
        LD      C,A
        CALL    EXPR2;get 2nd <expr2>
        EX      DE,HL; value in de now
        EX      (SP),HL; 1st <expr2> in hl
        CALL    CKHLDE;compare 1st with 2nd
        POP     DE;restore text pointer
        LD      HL,0000H;set hl=0, A=1
        LD      A,01H
        RET     

EXPR2:  CALL    TSTC;  negative sign?
        .DB  "-",06H
	LD      HL, 0000H;yes fake '0-'
        JP      XP26;treat like subtract
        CALL    TSTC;rst 1, positive sign? ignore
        .DB	"+",00H
        CALL    EXPR3;1st <expr3>
XP23:   CALL    TSTC; add?
        .DB	"+",15H
        PUSH    HL;yes, save value
        CALL    EXPR3;get 2nd <expr3>
XP24:   EX      DE,HL;2nd in DE
        EX      (SP),HL;1st in HL
        LD      A,H;compare sign
        XOR     D
        LD      A,D
        ADD     HL,DE
        POP     DE; restore text pointer
        JP      M,XP23;1st 2nd sign differ
        XOR     H;1st2nd sign equal
        JP      XP23;so ISp result
	JP	QHOW;QHOW,else we have overflow
        CALL    TSTC;  subtract?
        .DB  "-", 92H
XP26:  PUSH    HL;yes, save 1st <EXPR3>
        CALL    EXPR3;get 2nd  <EXPR3>
        CALL    CHKSGN;negate
        JP      XP24;and add them


EXPR3:  CALL    EXPR4;get 1st <EXPR4>
XP31:   CALL    TSTC;multiply?
	.DB	"*",2DH
	PUSH HL ; yes save 1st       
        CALL    EXPR4;and get 2nd<EXPR4>
        LD      B,00H;clear B for sign
        CALL    CHGSGN;check sign
        EX      (SP),HL
        CALL    CHGSGN
        EX      DE,HL;2nd in DE now
        EX      (SP),HL;1st in HL
        LD      A,H;is HL>255?
        OR      A
        JP      Z,XP32; no
        LD      A,D;yes, how about DE
        OR      D
        EX      DE,HL;put smaller in HL
        JP      NZ,AHOW;also >, will overflow
XP32:   LD      A,L;this is dumb
        LD      HL,0000H;clear result
        OR      A;add and count
        JP      Z,XP35
XP33:   ADD     HL,DE
        JP      C,AHOW; overflow
        DEC     A
        JP      NZ,XP33
        JP      XP35;finished
        CALL    TSTC; divide?
        .DB "/",4EH
        PUSH    HL;yes,save 1st <EXPR4>
        CALL    EXPR4;and get 2nd one
        LD      B,00H;clear B for sign
        CALL    CHGSGN
        EX      (SP),HL
        CALL    CHGSGN
        EX      DE,HL
        EX      (SP),HL
        EX      DE,HL
        LD      A,D;divide by 0?
        OR      E
        JP      Z,AHOW;say "HOW?"
        PUSH    BC;else save sign
        CALL    DIVIDE;divide subroutine
        LD      H,B;result in HL now
        LD      L,C
        POP     BC;get sign back
XP35:   POP     DE;and text pointer
        LD      A,H;HL must be +
        OR      A
        JP      M,QHOW;else it is overflow
        LD      A,B
        OR      A
        CALL    M,CHKSGN; change sign if needed
        JP      XP31; look or more terms


EXPR4:  LD      HL,TAB4-1
		JP EXEC      
XP40:   CALL    TSTV;no, not a function
        JP      C,XP41;nor a variable
        LD      A,(HL); variable
        INC     HL
        LD      H,(HL); value in HL
        LD      L,A
        RET     
XP41:   CALL    TSTNUM; or is it a number
        LD      A,B; no. of digit
        OR      A
        RET     NZ; ok  
PARN:   CALL    TSTC; no digit, must be '('
.DB     28H, 09H                 
        CALL    EXPR;"(EXPR)"
        CALL    TSTC ; ')'
.DB	29H, 01H
XP42:	RET 
XP43:	JP 	QWHAT;else say "WHAT?"

RND:    CALL    PARN;*RND(EXPR)*
        LD      A,H;expr must be +
        OR      A
        JP      M,QHOW
        OR      L;and non-zero
        JP      Z,QHOW
        PUSH    DE;save both
        PUSH    HL
DUMMY:  LD      HL,(RANPNT);get memory as random(RANPNT)
        LD      D,LSTROM>>8 & 0FFH ; was FE in Nascom, now FF
        CALL    COMP
        JR      C,RA1;wrap around if last
        LD      H,STARTBAS>>8 & 0FFH ;  START
RA1:    LD      D,(HL)
        INC     HL
        LD      A,R
        ADD     A,D
        LD      E,A
        LD      (RANPNT),HL
        POP     HL
	EX      DE,HL 
        PUSH    BC
        CALL    DIVIDE;  call DIVIDE, RND(N)=MOD(M,N)+1
        POP     BC
	POP DE
	INC HL
	RET

ABS:    CALL    PARN; call PARN, *ABS(EXPR)*
        DEC     DE
        CALL    CHGSGN; change sign
        INC     DE
        RET     


SIZE:   LD      HL,(TXTUNF);*SIZE* TXTUNF
        PUSH    DE; get the numberof free
        EX      DE,HL;bytes between 'TXTUNF'
        LD      HL,(VARBGN) ;and'VARBGN'
        OR      A
        SBC     HL,DE
        POP     DE
        RET     

;*
;**************************************************************
;* 
;* *** DIVIDE *** SUBDE *** CHKSGN *** CHGSGN *** & CKHLDE *** 
;* 
;* 'DIVIDE' DIVIDES HL BY DE, RESULT IN BC, REMAINDER IN HL
;* 
;* 'SUBDE' SUBTRACTS DE FROM HL
;* 
;* 'CHKSGN' CHECKS SIGN OF HL.  IF +, NO CHANGE.  IF -, CHANGE 
;* SIGN AND FLIP SIGN OF B.
;* 
;* 'CHGSGN' CHNGES SIGN OF HL AND B UNCONDITIONALLY. 
;* 
;* 'CKHLE' CHECKS SIGN OF HL AND DE.  IF DIFFERENT, HL AND DE 
;* ARE INTERCHANGED.  IF SAME SIGN, NOT INTERCHANGED.  EITHER
;* CASE, HL DE ARE THEN COMPARED TO SET THE FLAGS. 
;* 


DIVIDE: PUSH    HL; * DIVIDE*
        LD      L,H; divide H by DE
        LD      H,00H
        CALL    DV1
        LD      B,C; save result in B
        LD      A,L; (remainder+L)/DE
        POP     HL
        LD      H,A
DV1:    LD      C,0FFH; result in C
DV2:    INC     C; dumb routine
        OR      A
        SBC     HL,DE; divide by subtract
        JR      NC,DV2; and count            
        ADD     HL,DE
        RET     

;subroutine used by tape read/write to select T2 or T4
LFCC3:  PUSH    HL
        LD      HL,STARTBAS
        EX      (SP),HL; for return later to basic
        LD      A,(008DH); 00H in T4, C9 in T2
        OR      A
        JR      Z,LFCCF ; if T4, go to 0400H dump, or 070CH load           
        EX      DE,HL ; if T2, go to 03D1, "DUMP" or 037C "LOAD"
LFCCF:  JP      (HL)

CHGSGN:  LD      A,H; *CHGSGN*
        OR      A;check sign of HL
        RET     P; if -, change sign


CHKSGN: LD      A,H;*CHKSGN*
        OR      L; check sign of HL
        RET     Z;if -, change sign

        LD      A,H;**CHGSGN**
        PUSH    AF; change sign of HL
        CPL     
        LD      H,A
        LD      A,L
	CPL
        LD      L,A
        INC     HL
        POP     AF
        XOR     H
        JP      P,QHOW
        LD      A,B; and also flip B
        XOR     80H
        LD      B,A
        RET     

CKHLDE:  LD      A,H
        XOR     D; same sign?
        JP      P,COMP; yes, compare
        EX      DE,HL; no, Xch and comp

;*******************************************************
; compare HL with DE, return C, Z flags
COMP:   OR      A
        SBC     HL,DE
        ADD     HL,DE
        RET     

;* 
;**************************************************************
;* 
;* *** SETVAL *** FIN *** ENDCHK *** & ERROR (& FRIENDS) *** 
;* 
;* "SETVAL" EXPECTS A VARIABLE, FOLLOWED BY AN EQUAL SIGN AND
;* THEN AN EXPR.  IT EVALUATES THE EXPR. AND SET THE VARIABLE
;* TO THAT VALUE.
;* 
;* "FIN" CHECKS THE END OF A COMMAND.  IF IT ENDED WITH ";", 
;* EXECUTION CONTINUES.  IF IT ENDED WITH A CR, IT FINDS THE 
;* NEXT LINE AND CONTINUE FROM THERE.
;* 
;* "ENDCHK" CHECKS IF A COMMAND IS ENDED WITH CR.  THIS IS 
;* REQUIRED IN CERTAIN COMMANDS. (GOTO, RETURN, AND STOP ETC.) 
;* 
;* "ERROR" PRINTS THE STRING POINTED BY DE (AND ENDS WITH CR). 
;* IT THEN PRINTS THE LINE POINTED BY 'CURRNT' WITH A "?"
;* INSERTED AT WHERE THE OLD TEXT POINTER (SHOULD BE ON TOP
;* OF THE STACK) POINTS TO.  EXECUTION OF TB IS STOPPED
;* AND TBI IS RESTARTED.  HOWEVER, IF 'CURRNT' -> ZERO 
;* (INDICATING A DIRECT COMMAND), THE DIRECT COMMAND IS NOT
;*  PRINTED.  AND IF 'CURRNT' -> NEGATIVE # (INDICATING 'INPUT'
;* COMMAND, THE INPUT LINE IS NOT PRINTED AND EXECUTION IS 
;* NOT TERMINATED BUT CONTINUED AT 'INPERR'. 
;* 
;* RELATED TO 'ERROR' ARE THE FOLLOWING: 
;* 'QWHAT' SAVES TEXT POINTER IN STACK AND GET MESSAGE "WHAT?" 
;* 'AWHAT' JUST GET MESSAGE "WHAT?" AND JUMP TO 'ERROR'. 
;* 'QSORRY' AND 'ASORRY' DO SAME KIND OF THING.
;* 'QHOW' AND 'AHOW' IN THE ZERO PAGE SECTION ALSO DO THIS 
;* 

;subroutine
SETVAL: CALL    TSTV;  **SETVAL**
        JP      C,QWHAT; "WHAT?" NO VARIABLE
        PUSH    HL ;Save address of var.
        CALL    TSTC
	.DB 	"=", 0DH
        CALL    EXPR;  evaluate expr.
        LD      B,H; value in BC now
        LD      C,L
        POP     HL; get address
        LD      (HL),C; save value
        INC     HL
        LD      (HL),B
        RET     

;was rst 6, **finish**
FINISH:  CALL    FIN; call fin; check end of command
        JP      QWHAT; ?print 'what?' if wrong

;subroutine
FIN:    CALL    TSTC; rst 1, ***FIN***
	.DB 	3BH, 04H ;";" 
        POP     AF; ";", purge ret addr.
        JP      RUNSML; continue same line
        CALL    TSTC;  not ";", is it CR?
	.DB 	RETCODE,04H	 
        POP     AF; yes, purge ret addr.
        JP      RUNNXL; run next line
        RET   ; else return to caller  


;subroutine ignore blanks
IGNBLK: LD      A,(DE); ***IGNBLK****
        CP      20H; ignore blanks
        RET     NZ; in text where DE->)
        INC     DE; and return the first
        JP      IGNBLK;non-blank character in A


ENDCHK: CALL    IGNBLK; **ENDCHK***
        CP      RETCODE; end with CR?
        RET     Z; or, else say:"WHAT?"


QWHAT:  PUSH    DE; **QWHAT**
AWHAT:  LD      DE,WHAT; **AWHAT**
ERROR:  CALL    CRLF
        CALL    PRTSTG1
        LD      HL,(CURRNT); get current line no.
        PUSH    HL
        LD      A,(HL); check the value
        INC     HL
        OR      (HL)
        POP     DE
        JP      Z,RSTART; RSTART, if zero, just restart
        LD      A,(HL); if negative,
        OR      A
        JP      M,INPERR; redo input
        CALL    PRTLN; else print the line
        POP     BC
        LD      B,C
        CALL    LFEA3
        LD      A,3FH;print a "?"
        CALL    OUTC
        CALL    PRTSTG1; and rest of line
        JP      RSTART;RSTART
QSORRY: PUSH    DE; **QSORRY**
ASORRY: LD      DE,SORRY;***ASORRY**
        JP      ERROR; ERROR

;**************************************************************
;* 
;* *** GETLN *** FNDLN (& FRIENDS) *** 
;* 
;* 'GETLN' READS A INPUT LINE INTO 'BUFFER'.  IT FIRST PROMPT
;* THE CHARACTER IN A (GIVEN BY THE CALLER), THEN IT FILLS THE 
;* THE BUFFER AND ECHOS.  IT IGNORES LF'S AND NULLS, BUT STILL 
;* ECHOS THEM BACK.  RUB-OUT IS USED TO CAUSE IT TO DELETE 
;* THE LAST CHARATER (IF THERE IS ONE), AND ALT-MOD IS USED TO 
;* CAUSE IT TO DELETE THE WHOLE LINE AND START IT ALL OVER.
;* CR SIGNALS THE END OF A LINE, AND CAUSE 'GETLN' TO RETURN.
;* 
;* 'FNDLN' FINDS A LINE WITH A GIVEN LINE # (IN HL) IN THE 
;* TEXT SAVE AREA.  DE IS USED AS THE TEXT POINTER.  IF THE
;* LINE IS FOUND, DE WILL POINT TO THE BEGINNING OF THAT LINE
;* (I.E., THE LOW BYTE OF THE LINE #), AND FLAGS ARE NC & Z. 
;* IF THAT LINE IS NOT THERE AND A LINE WITH A HIGHER LINE # 
;* IS FOUND, DE POINTS TO THERE AND FLAGS ARE NC & NZ.  IF 
;* WE REACHED THE END OF TEXT SAVE ARE AND CANNOT FIND THE 
;* LINE, FLAGS ARE C & NZ. 
;* 'FNDLN' WILL INITIALIZE DE TO THE BEGINNING OF THE TEXT SAVE
;* AREA TO START THE SEARCH.  SOME OTHER ENTRIES OF THIS 
;* ROUTINE WILL NOT INITIALIZE DE AND DO THE SEARCH. 
;* 'FNDLNP' WILL START WITH DE AND SEARCH FOR THE LINE #.
;* 'FNDNXT' WILL BUMP DE BY 2, FIND A CR AND THEN START SEARCH.
;* 'FNDSKP' USE DE TO FIND A CR, AND THEN STRART SEARCH. 
;* 


FNDLN:  LD      A,H; *FNDLN*
        OR      A;check sign of HL
        JP      M,QHOW;it can't be -
        LD      DE,TXTUNF+2; TXTBGN, init text pointer

FNDLNP: INC     DE;
        LD      A,(DE)
        DEC     DE;
        ADD     A,A;
        RET     C;C, NZ passed end
        LD      A,(DE);we did not, get byte 1
        SUB     L; is this the line?
        LD      B,A;compare low order
        INC     DE
        LD      A,(DE);get byte 2
        SBC     A,H;compare high order
        JP      C,FL2;no, not there yet
        DEC     DE;else we either found
        OR      B;it,or it is not there
        RET     ;NC,Z:found, NC, NZ: no

   
FNDNXT: INC     DE; *FNDNXT*
FL2:    INC     DE;find next line, just past byte 1&2

FNDSKP: LD      A,(DE);*FNDSKP*
        CP      RETCODE; try to find "return"
        JP      NZ,FL2;keep looking
        INC     DE;found CR, skip over
        JP      FNDLNP; check if end of text



;***********************************************************


; test variables
TSTV:   CALL	IGNBLK; **TSTV ***
	SUB 	40H; test variables
        RET     C; not a variable
        JP      NZ,TV1; not '@' array
        INC     DE; it is the "@" array
        CALL    PARN;@ should be followed
        ADD     HL,HL;;by (EXPR) as its index
        JP      C,QHOW;is index too big?
        PUSH    DE; will it overwrite?
        EX      DE,HL; test?
        CALL    SIZE; find size of free, call size
        CALL    COMP; and check that
        JP      C,ASORRY; if so, say "sorry"
        CALL    LFE5F;if not, get address of @(expr)
        ADD     HL,DE; and put it in HL
        POP     DE
        RET     ; c flag is cleared
TV1:    CP      1BH ; not @, is it a to z?
        CCF     ;  if not return cflag
        RET     C
        INC     DE; if a through z
        LD      HL,VARBGN; compute address of
        RLCA    ;that variable
        ADD     A,L; and return it in hl
        LD      L,A; with c flag cleared
        LD      A,00H
        ADC     A,H
        LD      H,A
        RET     


TSTC:   EX      (SP),HL; *TSTC * test character
        CALL    IGNBLK;  ignore blanks
        CP      (HL);and test character
        INC     HL;compare the byte that  
        JP      Z,TC2;follows the rst instr.
        PUSH    BC;with the text (DE ->)
        LD      C,(HL);if not=, add the 2nd
        LD      B,00H;byte that follows the
        ADD     HL,BC;rst to the old PC
        POP     BC;ie do a relative 
        DEC     DE;jump if not =
TC2:    INC     DE;if =, skip those bytes
        INC     HL; and continue
        EX      (SP),HL
        RET     
;***********************************************************
;subroutine TSTNUM
TSTNUM: LD      HL,0000H; *TSTNUM*
        LD      B,H;test if the text is
        CALL    IGNBLK; a number
TN1:    CP      30H; if not,return 0 in
        RET     C;B and HL
        CP      3AH;if numbers, convert
        RET     NC;to binary in HL and
        LD      A,0F0H;set A to no. of digits
        AND     H;if H>255, there is no
        JP      NZ,QHOW;room for next digit
        INC     B;B counts no. of digits
        PUSH    BC;
        LD      B,H;HL=10;*HL+(new digit)
        LD      C,L
        ADD     HL,HL;where 10;* is done by
        ADD     HL,HL; shift and add
        ADD     HL,BC
        ADD     HL,HL
        LD      A,(DE); and (digit) is from
        INC     DE;stripping the ascii
        AND     0FH;code
        ADD     A,L
        LD      L,A
        LD      A,00H
        ADC     A,H
        LD      H,A
        POP     BC
        LD      A,(DE);do this digit after
        JP      P,TN1;digit. S says overflow
QHOW:   PUSH    DE; *****ERROR: HOW?****
AHOW:   LD      DE,HOW;HOW
        JP      ERROR;ERROR

;**************************************************************
;* 
;* *** MVUP *** MVDOWN *** POPA *** & PUSHA ***
;* 
;* 'MVUP' MOVES A BLOCK UP FROM HERE DE-> TO WHERE BC-> UNTIL 
;* DE = HL 
;* 
;* 'MVDOWN' MOVES A BLOCK DOWN FROM WHERE DE-> TO WHERE HL-> 
;* UNTIL DE = BC 
;* 
;* 'POPA' RESTORES THE 'FOR' LOOP VARIABLE SAVE AREA FROM THE
;* STACK 
;* 
;* 'PUSHA' STACKS THE 'FOR' LOOP VARIABLE SAVE AREA INTO THE 
;* STACK 



MVUP:   CALL    COMP; RST 4, *MVUP*
        RET     Z;DE=HL, return
        LD      A,(DE);get one byte
        LD      (BC),A; move it
        INC     DE;increase both pointers
        INC     BC
        JP      MVUP;until done


MVDOWN: LD      A,B; *MVDOWN*
        SUB     D;test if DE=BC
        JP      NZ,MD1;no,go move
        LD      A,C;maybe, other byte
        SUB     E
        RET     Z; yes, return
MD1:    DEC     DE;else move a byte
        DEC     HL;but first decrease
        LD      A,(DE);both pointers
        LD      (HL),A;and then do it
	JP      MVDOWN; loop back

POPA:	POP 	BC; BC= return addr. *POPA*
	POP     HL;restore LOPVAR, but
        LD      (LOPVAR),HL;=0 means no more
        LD      A,H
        OR      L
        JP      Z,PP1; yes, go return
        POP     HL; no,restore others
        LD      (LOPINC),HL
        POP     HL
        LD      (LOPLMT),HL
        POP     HL
        LD      (LOPLN),HL
        POP     HL
        LD      (LOPPT),HL
PP1:    PUSH    BC; BC=return addr.
        RET     

PUSHA:  LD      HL,STKLMT; *PUSHA*
        CALL    CHKSGN ;STKLMT limit for stack
        POP     BC;BC=return addr.
        ADD     HL,SP; is stack near the top?
        JP      NC,QSORRY; yes, sorry for that
        LD      HL,(LOPVAR);LOPVAR, else save loop var.s
        LD      A,H;but if LOPVAR is 0
        OR      L;that will be all
        JP      Z,PU1
        LD      HL,(LOPPT);LOPPT,else, more to save
        PUSH    HL
        LD      HL,(LOPLN);LOPLN
        PUSH    HL
        LD      HL,(LOPLMT);LOPLMT
        PUSH    HL
        LD      HL,(LOPINC);LOPINC
        PUSH    HL
        LD      HL,(LOPVAR);LOPVAR
PU1:    PUSH    HL
        PUSH    BC; BC = return addr.
        RET     


;subroutine
LFE5F:  LD      HL,(TXTUNF)
        DEC     HL
        DEC     HL
        RET     

;*************************************************************
;* 
;* *** PRTSTG *** QTSTG *** PRTNUM *** & PRTLN *** 
;* 
;* 'PRTSTG' PRINTS A STRING POINTED BY DE.  IT STOPS PRINTING
;* AND RETURNS TO CALLER WHEN EITHER A CR IS PRINTED OR WHEN 
;* THE NEXT BYTE IS THE SAME AS WHAT WAS IN A (GIVEN BY THE
;* CALLER).  OLD A IS STORED IN B, OLD B IS LOST.
;* 
;* 'QTSTG' LOOKS FOR A BACK-ARROW, SINGLE QUOTE, OR DOUBLE 
;* QUOTE.  IF NONE OF THESE, RETURN TO CALLER.  IF BACK-ARROW, 
;* OUTPUT A CR WITHOUT A LF.  IF SINGLE OR DOUBLE QUOTE, PRINT 
;* THE STRING IN THE QUOTE AND DEMANDS A MATCHING UNQUOTE. 
;* AFTER THE PRINTING THE NEXT 3 BYTES OF THE CALLER IS SKIPPED
;* OVER (USUALLY A JUMP INSTRUCTION).
;* 
;* 'PRTNUM' PRINTS THE NUMBER IN HL.  LEADING BLANKS ARE ADDED 
;* IF NEEDED TO PAD THE NUMBER OF SPACES TO THE NUMBER IN C. 
;* HOWEVER, IF THE NUMBER OF DIGITS IS LARGER THAN THE # IN
;* C, ALL DIGITS ARE PRINTED ANYWAY.  NEGATIVE SIGN IS ALSO
;* PRINTED AND COUNTED IN, POSITIVE SIGN IS NOT. 
;* 
;* 'PRTLN' PRINTS A SAVED TEXT LINE WITH LINE # AND ALL. 
;* 

PRTSTG1: SUB     A
PRTSTG: LD      B,A; *PRTSTG*
PS1:    LD      A,(DE); get a character
        INC     DE; bump pointer
        CP      B; same as old A?
        RET     Z; yes return
        CALL    OUTC;RST 2, else print it
        CP      RETCODE; was it a CR?
        JP      NZ,PS1; no next
        RET     ;yes return

QTSTG:  CALL    TSTC; ***QTSTG**
	.DB	22H,0FH ; for "
	LD      A, 22H ;it is a "
QT1:	CALL    PRTSTG;print until another
LFE7E:  CP      RETCODE;was last one a CR? 
        POP     HL;return address
        JP      Z,RUNNXL;was CR, run next line
        INC     HL;skip 3 bytes on return
        INC     HL
        INC     HL
        JP      (HL);return
        CALL    TSTC; is it a '?
	.DB	27H,05H        
        LD      A,27H; yes, do same
        JP      QT1;as in "
        CALL    TSTC;RST 1, is it backarrow?
	.DB	24H,0BH  
         LD      A,(DE)
        XOR     40H
        CALL    OUTC 
        LD      A,(DE)
        INC     DE
        JP      LFE7E
        RET     


;subroutine
LFEA3:  LD      A,E
        CP      B
        RET     Z
        LD      A,(DE)
        CALL    OUTC
        INC     DE
        JP      LFEA3

;subroutine PRTNUM
PRTNUM: LD      B,00H
        CALL    CHGSGN;check sign
        JP      P,PN1;no sign
        LD      B,2DH; B=sign
        DEC     C;'-' takes space
PN1:    PUSH    DE;*prtnum*
        LD      DE,000AH; 
        PUSH    DE;save as a flag
        DEC     C;C=spaces
        PUSH    BC; save sign and space
PN2:    CALL    DIVIDE; call divide; divide hl by 10
        LD      A,B; result 0?
        OR      C
        JP      Z,PN3; yes we got all
        EX      (SP),HL; no,save remainder
        DEC     L; and count space
        PUSH    HL; hl is old bc
        LD      H,B;move result to bc
        LD      L,C; 
        JP      PN2; and divide by 10
PN3:    POP     BC; we got all digits in
PN4:    DEC     C; the stack
        LD      A,C; look at space count
        OR      A
        JP      M,PN5; no leading blanks
        LD      A,20H;leading blanks
        CALL    OUTC
        JP      PN4;more?
PN5:    LD      A,B;print sign
        OR      A
        CALL    NZ,OUTC;  maybe - or null
        LD      E,L;last remainder in E
PN6:    LD      A,E; check digit in E
        CP      0AH; 10 is flag for no more
        POP     DE
        RET     Z; if so, return
        ADD     A,30H; else convert to ascii
        CALL    OUTC;  and print the digit
        JP      PN6; go back for more

PRTLN:  LD      A,(DE);* PRTLN*
        LD      L,A;low order line
        INC     DE
        LD      A,(DE); high order
        LD      H,A
        INC     DE
        LD      C,04H; print 4 digit line no.
        CALL    PRTNUM; call PRTNUM
        LD      A,20H; followed by a space
        JP      OUTC

TAB1:  	.DB "LIST",LIST>>8,LIST
.DB  "NEW",NEW>>8,NEW,"RUN",RUN>>8,RUN,"CR",CR>>8,CR

TAB2:  .DB "NEXT",NEXT>>8,NEXT,"LET",LET>>8,LET,"IF",IF>>8,IF
.DB "GOTO",GOTO>>8,GOTO
.DB "GOSUB",GOSUB>>8,GOSUB
.DB "RET",RETURN>>8,RETURN
.DB "REM",REM>>8,REM,"FOR",FOR>>8,FOR
.DB "INPUT",INPUT>>8,INPUT,"PRINT",PRINT>>8,PRINT
.DB "STOP",STOP>>8,STOP,"MC",MCODE>>8,MCODE 
.DB  "CW",CW>>8,CW,"EX",DUMMY>>8,DUMMY+1,DEFLT>>8,DEFLT

TAB4: .DB "RND",RND>>8,RND,"ABS",ABS>>8,ABS
.DB  "SIZE",SIZE>>8,SIZE,XP40>>8,XP40

TAB6:  .DB "STEP",FR2>>8,FR2,FR3>>8,FR3

TAB8: .DB ">=",XP11>>8,XP11,"#",XP12>>8,XP12,">",XP13>>8,XP13
.DB "=",XP15>>8,XP15,"<=",XP14>>8,XP14
.DB "<",XP16>>8,XP16,XP17>>8,XP17

;subroutine, CRLF
CRLF:  LD      A,RETCODE ;***CRLF****
OUTC:  JP 0C4AH ; for printing
CHKIO1:  JP      LFFC9; keyboard input

GETLN:  LD      DE,BUFFER;BUFFER, prompt and init
LFF9E:  CALL    OUTC; print screen
GL1:    CALL    CHKIO2; keyboard read to A
        JR      Z,GL1   ; no input, wait
        LD      (DE),A ; put input in buffer
        CP      BACKCODE; was it backspace?
        JR      NZ,LFFB4 ; no               
        LD      A,E ; yes, get lsb of position in buffer
        CP      BUFFER & 0FFH ; was it CA? (ie beginning of buffer)?
        JR      Z,GL1 ;ignore if yes               
        LD      A,(DE); if not, reload A
        DEC     DE ; backup pointer
        JR      LFF9E; print screen    
LFFB4:  CP      RETCODE ; was it a return?
        JR      Z,LFFC1  ;yes, end of line               
        LD      A,E; no - more free room? (get lsb of position in buffer)
        CP      BUFEND-2 & 0FFH ;  ie at end of buffer)
LFFBB:  JR      Z,GL1  ; yes, ignore               
        LD      A,(DE) ;reload A
        INC     DE ; move to next
        JR      LFF9E ;character and print screen  
LFFC1:  INC     DE ;was return, so end of line
        INC     DE
        LD      A,0FFH; end of line
        LD      (DE),A; send "end of line"
        DEC     DE
        JR      CRLF ;CRLF             

;continuation of CHKIO1
LFFC9: 	CALL    _KBD;  keyboard input to A
        RET     NC; 
        CP      1EH
        SCF     
        RET     NZ
CHKIO2: CALL    _KBD; keyboard input to A 
        JR      NC,CHKIO2                
        CP      1EH
        JP      Z,STARTBAS ; start again
        OR      A
        RET     

;subroutine tape read
CR:     LD      DE,037CH ; for T2
        LD      HL,070CH ; for T4
        JR      LFFF7 

;for write to tape
CW:     LD      HL,TXTUNF 
        LD      (ARG1),HL; ARG1, start address
 	LD      HL,(TXTUNF)
        LD      (ARG2),HL; ARG2 , end address
        LD      DE,03D1H ; for T2
        LD      HL,0400H ; for T4
LFFF7:  JP      LFCC3

;'TO' must have been forgotten and left to here!
TAB5:   .DB  "TO", FR1>>8,FR1,QWHAT>>8,QWHAT

LSTROM: .EQU $-1 ; last mem

	.END