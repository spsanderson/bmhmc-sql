' https://uknowit.uwgb.edu/page.php?id=28850'

Sub PasswordBreaker()
    'Breaks worksheet password protection.
    Dim i As Integer, j As Integer, k As Integer
    Dim l As Integer, m As Integer, n As Integer
    Dim i1 As Integer, i2 As Integer, i3 As Integer
    Dim i4 As Integer, i5 As Integer, i6 As Integer
    On Error Resume Next
    For i = 65 To 66: For j = 65 To 66: For k = 65 To 66
    For l = 65 To 66: For m = 65 To 66: For i1 = 65 To 66
    For i2 = 65 To 66: For i3 = 65 To 66: For i4 = 65 To 66
    For i5 = 65 To 66: For i6 = 65 To 66: For n = 32 To 126
    ActiveSheet.Unprotect Chr(i) & Chr(j) & Chr(k) & _
        Chr(l) & Chr(m) & Chr(i1) & Chr(i2) & Chr(i3) & _
        Chr(i4) & Chr(i5) & Chr(i6) & Chr(n)
    If ActiveSheet.ProtectContents = False Then
        MsgBox "One usable password is " & Chr(i) & Chr(j) & _
            Chr(k) & Chr(l) & Chr(m) & Chr(i1) & Chr(i2) & _
            Chr(i3) & Chr(i4) & Chr(i5) & Chr(i6) & Chr(n)
         Exit Sub
    End If
    Next: Next: Next: Next: Next: Next
    Next: Next: Next: Next: Next: Next
End Sub

' OR
' https://techcommunity.microsoft.com/t5/excel/how-to-unprotect-the-excel-sheet-if-forgot-the-password/m-p/1574559
Sub GetPass()

    Const a = 65, b = 66, c = 32, d = 126

    Dim i#, j#, k#, l#, m#, n#, o#, p#, q#, r#, s#, t#

    With ActiveSheet
        If .ProtectContents Then
            On Error Resume Next
            For i = a To b
                For j = a To b
                    For k = a To b
                        For l = a To b
                            For m = a To b
                                For n = a To b
                                    For o = a To b
                                        For p = a To b
                                            For q = a To b
                                                For r = a To b
                                                    For s = a To b
                                                        For t = c To d
            ActiveSheet.Unprotect Chr(i) & Chr(j) & Chr(k) & Chr(l) & Chr(m) & _
            Chr(n) & Chr(o) & Chr(p) & Chr(q) & Chr(r) & Chr(s) & Chr(t)
                                                        Next t
                                                    Next s
                                                Next r
                                            Next q
                                        Next p
                                    Next o
                                Next n
                            Next m
                        Next l
                    Next k
                Next j
            Next i
            MsgBox "Finished"
        End If
    End With
End Sub
