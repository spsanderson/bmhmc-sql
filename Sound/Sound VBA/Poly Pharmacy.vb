Option Explicit

Sub mPolyPharmacy()

' Turn screen updating off
Application.ScreenUpdating = False

    'put names in proper format
    Range("K1").Select
    
    'add empty rows between patients
    Range("K1").Select
    
    Do
        ActiveCell.FormulaR1C1 = "=Proper(RC[-1])"
        ActiveCell.Offset(1, 0).Select
    Loop Until ActiveCell.Offset(0, -1).Value = ""
    
    'copy the names and paste them as values not formulas
    Columns("K:K").Select
    Selection.Copy
    Columns("K:K").Select
    Selection.PasteSpecial Paste:=xlPasteValues, Operation:=xlNone, SkipBlanks _
        :=False, Transpose:=False
    'delete the formula columns
    Columns("J:J").Select
    Application.CutCopyMode = False
    Selection.Delete Shift:=xlToLeft
    
    '' ADD IN THE EXTRA ROWS
    ''//Select last row in worksheet
    Range("A2").Select
    Selection.End(xlDown).Select
        
    Do Until ActiveCell.Row = 2
      ''//Insert Blank Row
      ActiveCell.EntireRow.Insert Shift:=xlDown

      ''//Move up one row
      ActiveCell.Offset(-1, 0).Select
    Loop

    'Center align cells for better visual
    Columns("C:I").Select
    With Selection
        .HorizontalAlignment = xlCenter
        .VerticalAlignment = xlBottom
    End With
    
    'format the date time columns
    Columns("C:C").Select
    Selection.NumberFormat = "m/d/yy h:mm;@"
    Columns("E:E").Select
    Selection.NumberFormat = "m/d/yy h:mm;@"
    Columns("A:J").EntireColumn.AutoFit

Range("A1").Select
' Turn screenupdating back on
Application.ScreenUpdating = True

End Sub
