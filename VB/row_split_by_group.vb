Sub row_split()
    Dim NumRows As Integer
    Dim StartPoint As String

Beginning:

    NumRows = ActiveCell.Offset(1).Value - ActiveCell.Value - 1
    StartPoint = ActiveCell.Address

    If ActiveCell.Value = "" Then
      Exit Sub
    End If

    If (NumRows < 1) Then
      Range(StartPoint).Offset(1).Select
      GoTo Beginning
    End If

    Rows(ActiveCell.Offset(1).Row & ":" & ActiveCell.Offset(1).Row).Select
    Selection.Insert

    Range(StartPoint).Offset(2).Select
    
    GoTo Beginning

End Sub