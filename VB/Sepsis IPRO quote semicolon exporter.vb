Option Explicit

Sub QuoteSemicolonExport()
   ' Dimension all variables.
   Dim DestFile As String
   Dim FileNum As Integer
   Dim ColumnCount As Long
   Dim RowCount As Long
   Dim MaxRow As Long
   Dim MaxCol As Long
   

   ' Prompt user for destination file name.
   DestFile = InputBox("Enter the destination filename" _
      & Chr(10) & "(with complete path):", "Quote-Semicolon Exporter")

   ' Obtain next free file handle number.
   FileNum = FreeFile()

   ' Turn error checking off.
   On Error Resume Next

   ' Attempt to open destination file for output.
   Open DestFile For Output As #FileNum

   ' If an error occurs report it and end.
   If Err <> 0 Then
      MsgBox "Cannot open filename " & DestFile
      End
   End If

   ' Turn error checking on.
   On Error GoTo 0
   
MaxRow = ActiveSheet.UsedRange.Rows.Count
MaxCol = Selection.Columns.Count

MsgBox "Processing this many rows: " & MaxRow
MsgBox "Processing this many columns: " & MaxCol
      
   ' Loop for each row in selection.
   For RowCount = 1 To MaxRow
     ' Loop for each column in selection.
      For ColumnCount = 1 To MaxCol

         ' Write current cell's text to file with quotation marks.
         Print #FileNum, """" & Selection.Cells(RowCount, _
            ColumnCount).Text & """";

         ' Check if cell is in last column.
         If ColumnCount = MaxCol Then
            ' If so, then write a blank line.
            Print #FileNum,
         Else
            ' Otherwise, write a comma.
            Print #FileNum, ";";
         End If
      ' Start next iteration of ColumnCount loop.
      Next ColumnCount
   ' Start next iteration of RowCount loop.
   Next RowCount

   ' Close destination file.
   Close #FileNum
End Sub