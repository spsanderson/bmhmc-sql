Option Explicit

' Save and Backup ticket data

Sub cmdBackUpStats()

    'Turn off screen updating
    Application.ScreenUpdating = False

    ActiveWorkbook.Save
    Sheets("Cumulative Stats").Select
    ActiveSheet.Range("A1:K34").Select
    ActiveWorkbook.EnvelopeVisible = True
    
    With ActiveSheet.MailEnvelope
        .Item.to = "spsanderson@gmail.com"
        .Item.Subject = "Ticket Stats Backup"

        'Use item.display below if you want to edit before sending
        '.Item.display
        .Item.Send
    End With
    
    ' Copy over daily log before saving and quitting
    ' The following few lines copy the data we want
    Sheets("Cumulative Stats").Select
    Range("G3:G12").Select
    Selection.Copy
    
    ' Go to the sheet we want to paste the data to
    Sheets("Daily Log").Select
    Range("B1").Select
    
    ' Find the first empty cell
    Selection.End(xlDown).Select
    ActiveCell.Offset(1, 0).Select
    
    ' Transpose the previously copied data and get rid of formatting
    Selection.PasteSpecial Paste:=xlPasteAll, Operation:=xlNone, SkipBlanks:= _
        False, Transpose:=True
    Application.CutCopyMode = False
    
    With Selection.Interior
        .Pattern = xlNone
        .TintAndShade = 0
        .PatternTintAndShade = 0
    End With
    
    ' Clear boarders and formatting
    Selection.Borders(xlDiagonalDown).LineStyle = xlNone
    Selection.Borders(xlDiagonalUp).LineStyle = xlNone
    Selection.Borders(xlEdgeLeft).LineStyle = xlNone
    Selection.Borders(xlEdgeTop).LineStyle = xlNone
    Selection.Borders(xlEdgeBottom).LineStyle = xlNone
    Selection.Borders(xlEdgeRight).LineStyle = xlNone
    Selection.Borders(xlInsideVertical).LineStyle = xlNone
    Selection.Borders(xlInsideHorizontal).LineStyle = xlNone
    Selection.Font.Bold = False
    Selection.Font.Italic = False
    Selection.Font.ColorIndex = xlAutomatic
    Selection.Font.TintAndShade = 0
    
    ' Add date and time stamp to column A
    ActiveCell.Offset(0, -1).Select
    ActiveCell.Value = Now
    
    ' Get "Doned" amount
    ActiveCell.Offset(0, 11).Select
    ActiveCell.Value = ActiveCell.Offset(0, -10) - ActiveCell.Offset(-1, -10)
    
    ' Go to the Cumulative Stats Page
    Sheets("Cumulative Stats").Select
    Range("I13").Select
        
    ' Re-save the workbook before closing out
    ActiveWorkbook.Save
    
    'Turn screen updating back on
    Application.ScreenUpdating = True
    
    ' Close out excel
    Application.Quit
    
End Sub

' Refresh data on pivot table

Sub cmdRefreshData()
    
    'Turn off screen updating
    Application.ScreenUpdating = False
    
    ' Refresh the pivot table and then save
    ActiveWorkbook.RefreshAll
    ActiveWorkbook.Save
    
    'Turn screen updating back on
    Application.ScreenUpdating = True
        
End Sub

