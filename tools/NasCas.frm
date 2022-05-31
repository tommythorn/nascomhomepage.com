VERSION 5.00
Begin VB.Form frmNasCas
   BorderStyle     =   3  'Fixed Dialog
   Caption         =   "Nascom .NAS / .CAS converter"
   ClientHeight    =   1125
   ClientLeft      =   45
   ClientTop       =   390
   ClientWidth     =   4560
   LinkTopic       =   "frmNasCas"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   OLEDropMode     =   1  'Manual
   ScaleHeight     =   1125
   ScaleWidth      =   4560
   ShowInTaskbar   =   0   'False
   StartUpPosition =   3  'Windows Default
   Begin VB.Label lblNasCas
      Caption         =   "Drag .NAS / .CAS files here to convert"
      Enabled         =   0   'False
      Height          =   255
      Left            =   840
      TabIndex        =   0
      Top             =   360
      Width           =   2895
   End
End
Attribute VB_Name = "frmNasCas"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private Type Header
    addr As Integer
    Len  As Byte
    Num  As Byte
    Sum  As Byte
End Type

Private Type Block
    Header As Header
    Data() As Byte
    DataSum As Byte
End Type

Private Sub Form_OLEDragOver(Data As DataObject, Effect As Long, Button As Integer, Shift As Integer, X As Single, Y As Single, State As Integer)
    Effect = IIf(Data.GetFormat(vbCFFiles), vbDropEffectCopy, vbDropEffectNone)
End Sub

Private Sub Form_OLEDragDrop(Data As DataObject, Effect As Long, Button As Integer, Shift As Integer, X As Single, Y As Single)
    Dim i As Integer, p As Integer
    Dim file As String

    If Data.GetFormat(vbCFFiles) Then
        Enabled = False
        For i = 1 To Data.Files.Count
            file = Data.Files(i)
            p = InStrRev(file, ".")
            If p = 0 Then p = Len(file) + 1
            Select Case LCase$(Mid$(file, p))
                Case ".nas": Nas2Cas Left$(file, p - 1)
                Case ".cas": Cas2Nas Left$(file, p - 1)
                Case Else: Beep
            End Select
        Next i
        Enabled = True
    Else
        Beep
    End If
End Sub

Private Sub Nas2Cas(name As String)
    Dim blk() As Block
    Dim blocks As Integer, newAddr As Integer, addr As Integer, i As Integer
    Dim lineSum As Byte, b As Byte
    Dim s As String, a() As String

    Open name & ".nas" For Input As #1
    Open name & ".cas" For Binary Access Write As #2
    blocks = -1
    addr = -1
    Do Until EOF(1)
        Line Input #1, s
        If s = "." Then Exit Do
        a = Split(LTrim$(s), " ")
        newAddr = Val("&H" & a(0))
        If newAddr <> addr Then              ' Finish the current "R" block if "L" address is not in sequence (allows fragmented "L" to be correctly converted)
            addr = newAddr
            blocks = blocks + 1
            ReDim Preserve blk(blocks)       ' allocate another "R" block
            ReDim blk(blocks).Data(&HFF)             ' 256 bytes maximum
            blk(blocks).Header.addr = addr
        End If
        With blk(blocks)
            lineSum = (CLng(addr) And &HFF00&) \ &H100 + addr And &HFF   ' 2 bytes of "L" address
            For i = 1 To 8
                b = Val("&H" & a(i))
                .Data(.Header.Len) = b                                   ' store byte in "R" block
                .Header.Len = CInt(.Header.Len) + 1 And &HFF             ' count "R" block bytes, wrapping to 0 when 256
                .DataSum = CInt(.DataSum) + b And &HFF            ' add byte to "R" block sum avoiding Byte overflow
                lineSum = CInt(lineSum) + b And &HFF              ' add byte to "L" line sum, avoiding Byte overflow
                addr = (CLng(addr) + &H8000& + 1 And &HFFFF&) - &H8000&  ' increment addr, avoiding Integer overflow
            Next i
            If UBound(a) < 9 Then
                Problem name, s, "missing sum " & Right$(Hex$(&H100 + lineSum), 2)
            ElseIf UBound(a) > 9 Then
                Problem name, s, "too many values"
            ElseIf Val("&H" & a(9)) <> lineSum Then
                Problem name, s, "wrong sum " & Right$(Hex$(&H100 + lineSum), 2)
            End If
            If .Header.Len = 0 Then addr = -1
        End With
    Loop
    ReDim Preserve blk(blocks).Data(blk(blocks).Header.Len - 1 And &HFF) ' truncate "R" block to correct size
    For i = 0 To UBound(blk)
        With blk(i)
            With .Header
                .Num = UBound(blk) - i
                .Sum = (CLng(.addr) And &HFF00&) \ &H100 + .addr + .Len + .Num And &HFF
            End With
            If i = 0 Then
                If BASIC(.Header.addr) Then Put #2, , String$(3, &HD3) & UCase$(Mid$(name, InStrRev(name, "\") + 1, 1)) ' if BASIC load address, include D3 D3 D3 <first character of file name>
                Put #2, , String$(256, 0)
            End If
            Put #2, , Chr$(0) & String$(4, &HFF)    ' 00 FF FF FF sync mark
            Put #2, , .Header
            Put #2, , .Data
            Put #2, , .DataSum
            Put #2, , String$(10, &H0)
        End With
    Next i
    Close #2
    Close #1
    If BASIC(blk(0).Header.addr) Then ' [something I am doing with my file names] : if BASIC program, rename the input and output files to indicate they are for BASIC
        If InStr(name, " (BAS)") = 0 Then
            Debug.Print name & " (BAS)"
            Name name & ".nas" As name & " (BAS).nas"
            Name name & ".cas" As name & " (BAS).cas"
        End If
    End If
End Sub

Private Function BASIC(addr As Integer) As Boolean ' return True if addr is BASIC start address (10D6 for ROM BASIC, 30D6 for TAPE BASIC)
    Const PROGRAM_LOAD_ROM_BASIC As Integer = &H10D6
    Const PROGRAM_LOAD_TAPE_BASIC As Integer = &H30D6
    BASIC = addr = PROGRAM_LOAD_ROM_BASIC Or addr = PROGRAM_LOAD_TAPE_BASIC
End Function

Private Sub Cas2Nas(name As String)
    Dim h As Header
    Dim length As Long, i As Integer
    Dim b As Byte, chksumBlock As Byte, chksumLine As Byte

    Open name & ".cas" For Binary Access Read As #1
    Open name & ".nas" For Output As #2
    For i = 1 To 4 ' show the first 4 bytes (a hint in debug mode that it's a BASIC program)
        Get #1, , b
        Debug.Print Right$(Hex$(&H100 + b), 2); " ";
    Next i
    Debug.Print
    Do
        For i = 1 To 4 ' find a marker (00 FF FF FF)
            If EOF(1) Then Exit Do
            Get #1, , b
            If b <> &HFF Then i = 0
        Next i
        Get #1, , h
        If ((CLng(h.addr) And &HFF00&) \ &H100 + h.addr + h.Len + h.Num And &HFF) <> h.Sum Then Stop ' stop [debugging] if header sum is wrong
        length = &H100& * h.Num + h.Len
        If length = 0 Then length = 256
        chksumBlock = 0
        Do
            Print #2, Right$(Hex$(&H10000 + h.addr), 4);
            chksumLine = (CLng(h.addr) And &HFF00&) \ &H100 + h.addr And &HFF ' begin line sum with address (avoiding Integer overflow)
            For i = 1 To 8
                b = 0
                If length Then
                    Get #1, , b
                    chksumBlock = CInt(chksumBlock) + b And &HFF ' add byte to "R" block sum, avoiding Byte overflow
                    length = length - 1
                End If
                Print #2, " " & Right$(Hex$(&H100 + b), 2);
                chksumLine = CInt(chksumLine) + b And &HFF' add byte to "L" line sum, avoiding Byte overflow
                h.addr = (CLng(h.addr) + &H8000& + 1 And &HFFFF&) - &H8000& ' increment h.addr, avoiding Integer overflow
            Next i
Print #2, " " & Right$(Hex$(&H100 + chksumLine), 2) & vbBack & vbBack ' line checksum, and 2 backspaces
        Loop While length And &HFF ' loop until a complete "R" block of 256 bytes
        Get #1, , b
        If b <> chksumBlock Then Stop' stop [debugging] if "R" block sum is wrong
    Loop
    Print #2, "."
    Close #2
    Close #1
End Sub

Private Sub Problem(name As String, s As String, t As String) ' show any problems [debug mode]
    Debug.Print s; vbTab; "; "; name; ":"; vbTab; " ; "; t
    Beep
End Sub
