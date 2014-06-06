Sub row_split()
    ''//Select last row in worksheet
    Selection.End(xlDown).Select
    
    Do Until ActiveCell.Row = 1
      ''//Insert Blank Row
      ActiveCell.EntireRow.Insert shift:=xlDown
      ''//Move up one row
      ActiveCell.Offset(-1, 0).Select
    Loop
End Sub