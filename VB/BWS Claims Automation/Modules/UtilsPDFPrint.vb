
Dim lw As New CListWindows
Dim lv As New cListView
Dim l
Dim TempSmart As New CSmart

Sub testPrint()
    Connect "", stWeb1
    TimeOut = 20
    PrintPDF "C:\test.pdf", "Adobe PDF*"
    Wait
    '    Kill "C:\test.pdf"
End Sub

Sub PrintPDF(sFileName As String, PDFPrinter As String, Optional PrintDialogCaption As String = "Print", Optional bEvokeIEPrintDlg As Boolean = False)
'UN: IMPORTANT: All steps of the process handle screen pacing and are expecting Timeout to be set
'UN: Uses ExecCommand to trigger a Print in the connected to webpage
'UN: Detects a print dialog with caption of PrintDialogCaption - defaults to "Print"
'UN: Selects a printer by name uses VB Like - requires the *
'UN: Populates the Save As dialog box with sFilename
'UN: Errors in any step of the process will be bubbled up to this routine and it will throw an seTimeout
    Dim dialogHwnd As Long
    Dim SelectPrinterHwnd As Long
    Dim FileNameHwnd As Long
    Dim ButtonHwnd As Long
    Dim i As Long
    Dim lStartTime As Long

    On Error GoTo errh

    'Check if the file alread exists.If it does delete the file
    If FileExists(sFileName) Then KillFile sFileName

    'Delete the default file in case there was one because of error
    If FileExists(PDFFolder & "Inquiry.pdf") Then KillFile sFileName

    If bEvokeIEPrintDlg Then
        Web1.IE.document.execCommand "Print", True    ' This triggers a print, do not know if you need to specify a frame's document if in a framed website
    End If
retry:
    Wait 5
    dialogHwnd = GetDialogHwnd(PrintDialogCaption)
    SelectPrinterHwnd = ClassHandleInDialog("SysListView32", dialogHwnd)
    l = lv.getListView(SelectPrinterHwnd)
    Rule ""
    Do
        If UBound(l.Column(0).Item) <> 0 Then Exit Do    ' The printer list takes a beat of time to load, even though the SysListView32 exists
        If UBound(l.Column(0).Item) = 0 Then    ' Get the ListView again
            l = lv.getListView(SelectPrinterHwnd)
        End If
        If Rule("TIMEOUT") Then Err.Raise seTimeOut, "PrintPDF", "Printer list didn't load"
        DoEvents_
    Loop
    Rule ""
    Do
        For i = 0 To UBound(l.Column(0).Item)
            'Debug.Print l.Column(0).Item(i).text
            If l.Column(0).Item(i).text Like PDFPrinter Then
                lv.SetSelectedItem SelectPrinterHwnd, i
                Exit Do
            End If
        Next i
        If Rule("TIMEOUT") Then Err.Raise seTimeOut, "PrintPDF", "Printer list didn't load"
        DoEvents_
    Loop
    ' ClickEx ClassHandleInDialog("Button", dialogHwnd, , "&Print")
    'Wait 5
    ClickClassText dialogHwnd, "Button", "&Print"
    Wait 0.2
    dialogHwnd = GetDialogHwnd("Save PDF File As")
    'Debug.Print "dialogHwnd " & dialogHwnd

    Set TempSmart = GetComponent(dialogHwnd, "Editable text", , "File name:")
    If TempSmart Is Nothing Then
        Logging "TempSmart is nothing line 19"
    End If
    TempSmart.value = sFileName

    'SetClassText dialogHwnd, "Edit", sFileName
    'ClickEx ClassHandleInDialog("Button", dialogHwnd, , "&Save")
    ClickClassText dialogHwnd, "Button", "&Save"

    ' check if the file is successfully created
    lStartTime = Timer
    Do
        ' check if the file creation completed successfully
        If FileExists(sFileName) Then
            DoEvents_
            Exit Do
        End If

        'Timeout if elapsed time is greater than our Timeout setting
        If Timer >= lStartTime + 100 Then    ' goConfig.SubmitReportTimeout + 100 Then
            Logging "Timed out on Saving the file"
            DoEvents_
            Exit Sub
        End If
        DoEvents
    Loop

    '        If IsWindowEx("Confirm Save As") Then
    '            Activate "Confirm Save As", True
    '            SmartDialog("Confirm Save As", "Yes<Push button>").Click
    '        End If

    Exit Sub
errh:
    If Err.Number = 9 Then
        DoEvents_
        Resume retry    ' Listview isn't fully populated
    End If
    Resume
    Logging "ERROR: Utils_Print " & "|" & Err.Number & "|" & Err.Description & "|" & Err.Source
    Logging "Couldn't print " & sFileName
    Err.Raise seTimeOut, "PrintPDF", Err.Description
End Sub

Sub PrintPDFoaUB04(sFileName As String, PDFPrinter As String, Optional PrintDialogCaption As String = "Print", Optional bEvokeIEPrintDlg As Boolean = False)
'UN: IMPORTANT: All steps of the process handle screen pacing and are expecting Timeout to be set
'UN: Uses ExecCommand to trigger a Print in the connected to webpage
'UN: Detects a print dialog with caption of PrintDialogCaption - defaults to "Print"
'UN: Selects a printer by name uses VB Like - requires the *
'UN: Populates the Save As dialog box with sFilename
'UN: Errors in any step of the process will be bubbled up to this routine and it will throw an seTimeout
    Dim dialogHwnd As Long
    Dim SelectPrinterHwnd As Long
    Dim FileNameHwnd As Long
    Dim ButtonHwnd As Long
    Dim i As Long
    Dim lStartTime As Long
    Dim lPrintHwnd As Long

    On Error GoTo errh

    'Check if the file alread exists.If it does delete the file
    If FileExists(sFileName) Then KillFile sFileName

    'Delete the default file in case there was one because of error
    If FileExists(PDFFolder & "Inquiry.pdf") Then KillFile sFileName

    'Wait 5
    Activate "https://www.officeally.com/oa/Claims/OA_PrintClaim_UB04.aspx*"
    lPrintHwnd = GetForeGroundhWnd

    'lPrintHwnd = GetComponentHwndByClassname("AVL_AVView")
    'Wait 5
    ' click save
    ClickEx lPrintHwnd, False, False, 40, 80, False

    ' send keys shift + ctrl + s
    'Key "^P"


    If bEvokeIEPrintDlg Then
        Web1.IE.document.execCommand "Print", True    ' This triggers a print, do not know if you need to specify a frame's document if in a framed website
    End If
retry:
    Wait 5
    '    dialogHwnd = GetDialogHwnd(PrintDialogCaption)
    '    SelectPrinterHwnd = ClassHandleInDialog("SysListView32", dialogHwnd)
    '    l = lv.getListView(SelectPrinterHwnd)
    '    Rule ""
    '    Do
    '        If UBound(l.Column(0).Item) <> 0 Then Exit Do    ' The printer list takes a beat of time to load, even though the SysListView32 exists
    '        If UBound(l.Column(0).Item) = 0 Then    ' Get the ListView again
    '            l = lv.getListView(SelectPrinterHwnd)
    '        End If
    '        If Rule("TIMEOUT") Then Err.Raise seTimeOut, "PrintPDFoaUB04", "Printer list didn't load"
    '        DoEvents_
    '    Loop
    '    Rule ""
    '    Do
    '        For i = 0 To UBound(l.Column(0).Item)
    '            Debug.Print l.Column(0).Item(i).text
    '            If l.Column(0).Item(i).text Like PDFPrinter Then
    '                lv.SetSelectedItem SelectPrinterHwnd, i
    '                Exit Do
    '            End If
    '        Next i
    '        If Rule("TIMEOUT") Then Err.Raise seTimeOut, "PrintPDF", "Printer list didn't load"
    '        DoEvents_
    '    Loop
    ' ClickEx ClassHandleInDialog("Button", dialogHwnd, , "&Print")
    'Wait 5
    'ClickClassText dialogHwnd, "Button", "&Print"
    'Wait 0.2
    dialogHwnd = GetDialogHwnd("Save a Copy...")
    Debug.Print "dialogHwnd " & dialogHwnd

    Set TempSmart = GetComponent(dialogHwnd, "Editable text", , "File name:")
    If TempSmart Is Nothing Then
        Logging "TempSmart is nothing line 19"
    End If
    TempSmart.value = sFileName

    'SetClassText dialogHwnd, "Edit", sFileName
    'ClickEx ClassHandleInDialog("Button", dialogHwnd, , "&Save")
    ClickClassText dialogHwnd, "Button", "Save"

    ' check if the file is successfully created
    lStartTime = Timer
    Do
        ' check if the file creation completed successfully
        If FileExists(sFileName) Then
            DoEvents_
            Exit Do
        End If

        'Timeout if elapsed time is greater than our Timeout setting
        If Timer >= lStartTime + 100 Then    ' goConfig.SubmitReportTimeout + 100 Then
            Logging "Timed out on Saving the file"
            DoEvents_
            Exit Sub
        End If
        DoEvents
    Loop

    '        If IsWindowEx("Confirm Save As") Then
    '            Activate "Confirm Save As", True
    '            SmartDialog("Confirm Save As", "Yes<Push button>").Click
    '        End If

    Exit Sub
errh:
    If Err.Number = 9 Then
        DoEvents_
        Resume retry    ' Listview isn't fully populated
    End If
    Resume
    Logging "ERROR: Utils_Print " & "|" & Err.Number & "|" & Err.Description & "|" & Err.Source
    Logging "Couldn't print " & sFileName
    Err.Raise seTimeOut, "PrintPDFoaUB04", Err.Description
End Sub


Sub SetClassText(dialogHwnd As Long, ByVal sClass As String, sText As String, Optional ByVal nth As Long = 1, Optional SmartClass As String = "Editable text")
'UN: Populates the nth textbox(typically) inside a dialog with handle of dialogHwnd
'UN: Uses cSmart.Value to populate the text so this may not work in all situations
    Dim tempHwnd As Long
    tempHwnd = ClassHandleInDialog(sClass, dialogHwnd)
    Rule ""
    Do
        If GetForeGroundhWnd <> dialogHwnd Then Activate (WindowText(dialogHwnd))
        TempSmart.Create tempHwnd, 2, 2
        If Rule("TIMEOUT") Then Err.Raise seTimeOut, "SetClassText"
        DoEvents
    Loop Until TempSmart.IsElement And TempSmart.Class = SmartClass
    TempSmart.value = sText
End Sub
Sub ClickClassText(dialogHwnd As Long, ByVal sClass As String, sText As String, Optional ByVal nth As Long = 1, Optional SmartClass As String = "Push button")
'UN: Populates the nth textbox(typically) inside a dialog with handle of dialogHwnd
'UN: Uses cSmart.Value to populate the text so this may not work in all situations
    Dim tempHwnd As Long
    tempHwnd = ClassHandleInDialog(sClass, dialogHwnd, , sText)
    Rule ""
    Do
        If GetForeGroundhWnd <> dialogHwnd Then Activate (WindowText(dialogHwnd))
        TempSmart.Create tempHwnd, 2, 2
        If Rule("TIMEOUT") Then Err.Raise seTimeOut, "SetClassText"
        DoEvents
    Loop Until TempSmart.IsElement And TempSmart.Class = SmartClass
    ClickEx tempHwnd, False, False, 2, 2
    'TempSmart.doAction
    'TempSmart.Click
End Sub

Function GetDialogHwnd(sCaption As String, Optional nth As Long = 1) As Long
    On Error GoTo errh
    'UN: Returns the handle for the Nth dialog with caption sCaption
    'UN: Uses Active,True to verify existance of the dialog
    'UN: Uses cListWindows.HasCaptionLike to detect the caption, the * is required.
    'UN: Existance of dialog handle within cListWindows.HasCaptionLike may take a beat of time, this handles the pacing
    Activate sCaption, True
    Dim t As Long
    Dim numRetries As Integer
    numRetries = 0
retry:
    Rule ""
    t = Timer
    Do
        GetDialogHwnd = lw.HasCaptionLike(sCaption)(nth)
        If GetDialogHwnd <> 0 Then Exit Function
        If Rule("TIMEOUT") Then Err.Raise seTimeOut, "GetDialogHwnd", "Dialog was activated but handle did not appear in HasCaptionLike"
        DoEvents_
        If Timer >= t + SoarianTimeout Then
            Err.Raise seTimeOut, "GetDialogHwnd", "Dialog was activated but handle did not appear in HasCaptionLike"
        End If
    Loop
    Exit Function
errh:
    If Err.Description = "Invalid procedure call or argument" And numRetries < 75 Then    ' For a brief beat in time the dialog's handle may not be in the collection and this throws an error
        DoEvents_
        numRetries = numRetries + 1
        Resume retry
    Else
        Err.Raise seTimeOut, "GetDialogHwnd", Err.Description & " Could not retrieve handle for: " & sCaption
    End If
End Function

Function ClassHandleInDialog(ByVal sClassName As String, ByVal dialogHwnd As Long, Optional ByVal nth As Long = 1, Optional sText As String) As Long
'UN: Returns the handle for the Nth instance of a class in dialog with handle DialogHwnd
'UN: Or the handle of the nth control with WindowText of sText
'UN: Existance of given class in a dialog may take a beat of time, this handles that pacing
    Dim h
    Dim i As Long
    Dim tempHwnd As Long
    On Error GoTo errh
retry:
    Rule ""
    i = 1
    Do
        lw.className = sClassName
        If sText <> "" Then
            For Each h In lw.InProcess(dialogHwnd)
                If WindowText((h)) Like sText Then
                    If i = nth Then
                        ClassHandleInDialog = CLng(h)
                        Exit Function
                    Else
                        i = i + 1
                    End If
                End If
            Next h
        Else
            tempHwnd = lw.InProcess(dialogHwnd)(nth)
        End If
        If tempHwnd <> 0 Then
            ClassHandleInDialog = tempHwnd
            Exit Function
        End If
        If Rule("TIMEOUT") Then Err.Raise seTimeOut, "ClassHandleInDialog", "Did not find:" & sClassName
        DoEvents_
    Loop
    Exit Function
errh:
    If Err.Description = "Invalid procedure call or argument" Then    ' For a brief beat in time the class's handle may not be in the collection and this throws an error
        DoEvents_
        Resume retry
    End If
    Err.Raise seTimeOut, "ClassHandleInDialog", Err.Description & " Did not locate: " & sClassName & " " & sText
End Function


