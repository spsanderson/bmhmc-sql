Option Explicit

Private Sub cmdCloseForm_Click()

    Unload Me

End Sub
''--
Private Sub cmdOpenEditRecord_Click()

    Unload Me
    
    Load frmEditRecord
    
    frmEditRecord.Show
    
End Sub
''--
Sub UserForm_Initialize()

    ' empty out the text boxes
    txtLastName = ""
    txtFirstName = ""
    cboSuffix = ""
    cboDept = ""
    cboSpecialty = ""
    txtNotes = ""
    cboMDStatus = ""
    txtMDIDNumber = ""
    cboPrivileged = ""
    cboCredentialed = ""
    
    txtFirstName.SetFocus


End Sub
''--
Private Sub cmdSaveRecord_Click()

'' variables
Dim emptyRow As Long

'' worksheets
Dim wksData As Worksheet
Dim wksInputData As Worksheet

' Turn screen updating off
Application.ScreenUpdating = False

'' set values of worksheets
Set wksData = Sheets("Data")
Set wksInputData = Sheets("Input Data")
    
    '' this is where data is going to be stored
    wksData.Activate
        
    ' determine empty row
    emptyRow = WorksheetFunction.CountA(Range("A:A")) + 1
    
    ' transfer information
    Cells(emptyRow, 1).Value = txtFirstName.Value
    Cells(emptyRow, 2).Value = txtLastName.Value
    Cells(emptyRow, 3).Value = WorksheetFunction.Proper(txtLastName.Value & ", " & txtFirstName.Value)
    Cells(emptyRow, 4).Value = cboSuffix.Value
    Cells(emptyRow, 5).Value = cboDept.Value
    Cells(emptyRow, 6).Value = cboSpecialty.Value
    Cells(emptyRow, 7).Value = txtNotes.Value
    Cells(emptyRow, 8).Value = dtpDatePassedTest.Value
    Cells(emptyRow, 9).Value = dtpDateOfPrivileges.Value
    Cells(emptyRow, 10).Value = cboPrivileged.Value
    Cells(emptyRow, 12).Value = cboCredentialed.Value
    Cells(emptyRow, 11).Value = dtpDateOfCredentialing.Value
    
    ' Date privileges expire
    Cells(emptyRow, 13).Value = DateAdd("yyyy", 4, dtpDateOfPrivileges)
    Cells(emptyRow, 14).Value = DateAdd("yyyy", 4, dtpDateOfCredentialing)
    
    Cells(emptyRow, 15).Value = DateDiff("D", Date, _
        DateAdd("yyyy", 4, dtpDateOfPrivileges), vbSunday, vbFirstJan1)
        
    Cells(emptyRow, 16).Value = DateDiff("D", Date, _
        DateAdd("yyyy", 4, dtpDateOfCredentialing), vbSunday, vbFirstJan1)
    
    Cells(emptyRow, 17).Value = cboMDStatus.Value
    Cells(emptyRow, 18).Value = txtMDIDNumber.Value
        
    '' resize columns to match data
    Columns("A:F").EntireColumn.AutoFit
    Range("G:G").ColumnWidth = 50
    Columns("H:Z").EntireColumn.AutoFit
    
    
    '' go back to the data input page
    wksInputData.Activate
    
    Call UserForm_Initialize

' Turn screen updating back on
Application.ScreenUpdating = True


End Sub

------------------------------------------------------------------------
Option Explicit

Private Sub cmdCloseForm_Click()

    Unload Me

End Sub

Private Sub cmdEditRecord_Click()

End Sub

Private Sub cmdOpenInputForm_Click()

    Unload Me
    
    Load frmDataInput
    
    frmDataInput.Show

End Sub

Private Sub cmdSearch_Click()

    '' set up variables
    Dim vPhysLast As String
    Dim vMD_ID As String
    Dim wksData As Worksheet
    Dim Msg As String
    
    '' set variables equal to something
    vPhysLast = txtLastNameSearch.Value
    vMD_ID = txtMD_ID.Value
    Set wksData = Sheets("Data")
    
    '' this is the workseet where data lives
    wksData.Activate
    
    If txtLastNameSearch.Value = "" And txtMD_ID.Value = "" Then
        Application.ScreenUpdating = False
        Sheets("Input Data").Activate
        Application.ScreenUpdating = True
        Msg = "Congratulations you failed to enter search criteria"
        MsgBox Msg, vbCritical, "Good Job"
    End If
    
    If Len(vPhysLast) >= 1 Then
        Columns("C:C").Select
        Selection.Find(What:=vPhysLast, After:=ActiveCell, LookIn:=xlFormulas, _
            LookAt:=xlPart, SearchOrder:=xlByColumns, SearchDirection:=xlNext, _
            MatchCase:=False, SearchFormat:=False).Activate
        Selection.FindNext(After:=ActiveCell).Activate
    
    ElseIf vPhysLast = "" And Len(vMD_ID) >= 1 Then
        Columns("R:R").Select
        Selection.Find(What:=vMD_ID, After:=ActiveCell, LookIn:=xlFormulas, _
            LookAt:=xlPart, SearchOrder:=xlByColumns, SearchDirection:=xlNext, _
            MatchCase:=False, SearchFormat:=False).Activate
        Selection.FindNext(After:=ActiveCell).Activate
    End If

End Sub

-------------------------------------------------------------------------
Option Explicit

Sub mDaysTillExpired()
    
    Dim vDaysTillExpire As Integer
    
    Application.ScreenUpdating = False
    
    Sheets("Data").Activate
    Range("O2").Select
    
    ' This loop will get the days until Privileges Expire
    Do
        vDaysTillExpire = ActiveCell.Select
        ActiveCell.FormulaR1C1 = "=RC[-2] - TODAY()"
        ActiveCell.Offset(1, 0).Select
    Loop Until ActiveCell.Value = ""
    
    Range("O:O").NumberFormat = "0"
    
    ' This loop will get the days until Credentials Expire
    Range("P2").Select
    
    Do
        vDaysTillExpire = ActiveCell.Select
        ActiveCell.FormulaR1C1 = "=RC[-2] - TODAY()"
        ActiveCell.Offset(1, 0).Select
    Loop Until ActiveCell.Value = ""
    
    Range("P:P").NumberFormat = "0"
    
    Sheets("Input Data").Activate
    
    Application.ScreenUpdating = True
    
    MsgBox "All the days till expiration have finished calculating"

End Sub

------------------------------------------------------------------------

Option Explicit

Sub mExpiring()

Dim vDays As Integer

' Turn off screen updating
Application.ScreenUpdating = False

' Clear data on the Expiring Page
Sheets("Expiring").Activate
Range("A2").Select
Range(Selection, Selection.End(xlToRight)).Select
Range(Selection, Selection.End(xlDown)).Select
Selection.ClearContents
Range("A2").Select


' Go to the data page to run the Do Loop
Sheets("Data").Activate

' This is where to start
Range("O2").Select

' This is the loop for expiring privileges
Do
    vDays = ActiveCell.Value
        
    If vDays < 90 Then
        ActiveCell.Offset(0, -14).Activate
        Range(ActiveCell, ActiveCell.End(xlToRight)).Copy
        Worksheets("Expiring").Activate
        ActiveCell.PasteSpecial
        ActiveCell.Offset(1, 0).Select
        Sheets("Data").Activate
        ActiveCell.Offset(0, 14).Select
    End If
    
    Application.CutCopyMode = False
    ActiveCell.Offset(1, 0).Select
            
Loop Until ActiveCell.Value = ""

Sheets("Expiring").Activate

Application.ScreenUpdating = True

' Small finish message
MsgBox "Here is a list of all those who have privileges expiring in 90 days or less."

End Sub

------------------------------------------------------------------------
Sub mQuitApplication()

    Application.quit

End Sub



