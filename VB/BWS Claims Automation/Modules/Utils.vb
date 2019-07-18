'---------------------------------------------------------------------------------------
' Module    : Utils
' Author    : bwsuser
' Date      : 1/9/2017
' Purpose   :
'---------------------------------------------------------------------------------------

Option Explicit
Private Declare Function ApiGetComputerName Lib "Kernel32" Alias "GetComputerNameA" (ByVal lpBuffer As String, nSize As Long) As Long
' Physical Key - TCB added
Public k As New Keys
' file system ob ject
Public goFSO As FileSystemObject
' configuration object
Public goConfig As cConfig
' document object
Public goDoc As HTMLDocument

' IE object
Public goIE As Object
' Connect retry count
Public gnConnectRetry As Integer
' state mnemonic
Public gsPayorMnemonic As String

Public Enum enumControlStatus
    eCONTROL_VALID = 0
    eCONTROL_NOT_VALID = 99
    eCONTROL_ITEM_NOT_FOUND = 2
    eCONTROL_CONTROL_NOT_FOUND = 3
    'eCLAIM_STATUS_NOT_FOUND = 4
    'eCLAIM_STATUS_REQUIRED = 5
End Enum

Public Enum enumBilledStatus
    eBILLED_ELECTRONIC = 1
    eBILLED_PAPER = 2
    eBILLED_UNKNOWN = 99
End Enum

' used for status form
Enum FormAlign
    BottomCenter
    BottomLeft
    BottomRight
    center
    CenterLeft
    CenterRight
    TopCenter
    TopLeft
    TopRight
End Enum
Public Declare Function FindWindow Lib "user32" Alias "FindWindowA" _
                                   (ByVal lpClassName As String, ByVal lpWindowName As String) As Long
Public Declare Function SetWindowPos Lib "user32" (ByVal hWnd As Long, ByVal hwndInsertAfter As Long, ByVal X As Long, ByVal y As Long, ByVal cx As Long, ByVal cy As Long, ByVal wFlags As Long) As Long
Private Declare Function GetSystemMetrics Lib "user32" (ByVal nIndex As Long) As Long
Private Const SM_CXFULLSCREEN = 16
Private Const SM_CYFULLSCREEN = 17

Const msModulename As String = "Utils"
Sub testPhykey()
    Connect "", stWeb1
    SendPhyKeys "123"
End Sub

Public Sub SendPhyKeys(sText As String, Optional sTitle As String)    'TCB
'If web1.IE.Document.Title does not match the window title, pass sTitle (window title)
    If sTitle = "" Then sTitle = Web1.IE.document.title
    Activate sTitle
    Wait
    k.Key sText, SendInput_
End Sub

Public Sub SendPhyKeysSlow(sText As String, Optional sTitle As String)    'TCB
'If web1.IE.Document.Title does not match the window title, pass sTitle (window title)

    Dim i As Long

    If sTitle = "" Then sTitle = Web1.IE.document.title
    Activate sTitle
    Wait


    For i = 1 To Len(sText)
        Wait 0.2
        k.Key Mid$(sText, i, 1), SendInput_
    Next i

End Sub
' creates given folder
Sub CreateFolder(folderToCreate As String)
    Dim fso As FileSystemObject
    On Error Resume Next
    Set fso = New FileSystemObject

    fso.CreateFolder folderToCreate
    Set fso = Nothing
End Sub

' deletes given file
Sub KillFile(filePathAndName As String)
    On Error Resume Next
    Kill filePathAndName
End Sub

' return true if the modified date of the passed in complete path and filename
' is greater than 1 week old
Function FileIsWeekOld(inputfile As String) As Boolean
    Dim fso As FileSystemObject
    Dim targetFile As Object
    Dim modifiedDate As Date

    Set fso = New FileSystemObject

    If fso.FileExists(inputfile) Then
        Set targetFile = fso.GetFile(inputfile)

        modifiedDate = targetFile.DateLastModified

        If DateDiff("ww", modifiedDate, Date) > 0 Then
            FileIsWeekOld = True
        Else
            FileIsWeekOld = False
        End If
    Else
        FileIsWeekOld = False
    End If

    Set fso = Nothing
End Function

' take a screenshot of whole desktop and return
' the screenshot filename
Function TakeScreenshot(sLogFolder As String) As String
    Dim ssFilename As String
    ssFilename = sLogFolder & "errScreenShot_" & Format(Now, "mmddyyyy_hhnn") & ".bmp"
    ScreenShot ssFilename, False
    TakeScreenshot = ssFilename
End Function

' Returns the computername
Function GetMachineName(Optional bDummy As Boolean) As String
    Dim lngLen As Long, lngX As Long
    Dim strCompName As String
    lngLen = 16
    strCompName = String$(lngLen, 0)
    lngX = ApiGetComputerName(strCompName, lngLen)
    If lngX <> 0 Then
        GetMachineName = Left$(strCompName, lngLen)
    Else
        GetMachineName = ""
    End If
End Function

' sends email
Function SendEmail(MailTo As String, subject As String, body As String, Optional attachments As String) As String
    Dim tmpAttachments As String

    ' if any attachments fail, it will cause the email to fail
    If attachments <> "" Then
        tmpAttachments = CheckAttachmentsExist(attachments)
    End If

    ' enable this at the end TODO: enable this
    SendEmail = SendMail(MailTo, subject, body, "SSanderson@bmhmc.org", tmpAttachments, goConfig.EmailServer, "EMPTY", "EMPTY", "25")

End Function

' requires a list of filenames (incl. path) separated by "|"
' returns a "|" delimited list of only those files that exist
' intended to be used in conjunction with Sendmail command as missing
' attachments will cause the email to fail
Function CheckAttachmentsExist(listOfFiles As String) As String
    Dim tempList As String
    Dim listArr() As String
    Dim i As Integer
    Dim fso As FileSystemObject
    Set fso = New FileSystemObject
    listArr = Split(listOfFiles, "|")
    For i = 0 To UBound(listArr)
        If listArr(i) <> "" Then
            If fso.FileExists(listArr(i)) Then
                tempList = tempList & listArr(i) & "|"
            End If
        End If
    Next i

    If Right$(tempList, 1) = "|" Then tempList = Left$(tempList, Len(tempList) - 1)
    CheckAttachmentsExist = tempList
End Function

' del logs, screenshots, archived input files older than X days
Sub CleanHouse(sLogFolder As String, sProcessDir As String, nDeleteLogsAfterDays As Integer)

    Dim fileToCheck As String

    On Error GoTo ErrorHandler

    LogMessage "MODULE: Utils SUB: CleanHouse:" & " begin"

    '    todo: enable to show the status
    '    StatusForm.lblCurrentFile.caption = "Cleaning up old logs..."
    '    StatusForm.lblCurrentEnvironment.caption = ""
    '    StatusForm.lblNumFilesInQueue.caption = ""

    ' Dir is MUCH faster that fso
    fileToCheck = Dir$(sLogFolder)
    Do While fileToCheck <> ""
        ' only keep log files for X days
        If InStr(fileToCheck, "_Log") > 0 Then
            If FileIsDaysOld(sLogFolder & fileToCheck, nDeleteLogsAfterDays) Then
                KillFile sLogFolder & fileToCheck
            End If
        End If
        ' only keep screenshot files for X days
        If Left$(fileToCheck, 14) = "errScreenShot_" Then
            If FileIsDaysOld(sLogFolder & fileToCheck, nDeleteLogsAfterDays) Then
                KillFile sLogFolder & fileToCheck
            End If
        End If
        DoEvents
        fileToCheck = Dir$
    Loop

    LogMessage "MODULE: Utils SUB: ClaenHouse:" & " deleted log files and error files older than " & nDeleteLogsAfterDays

    ' delete archive files older than X days
    fileToCheck = ""
    fileToCheck = Dir$(sProcessDir & "\Archive")
    Do While fileToCheck <> ""
        If FileIsDaysOld(sProcessDir & "\Archive\" & fileToCheck, nDeleteLogsAfterDays) Then
            KillFile sProcessDir & "\Archive\" & fileToCheck
        End If
        DoEvents
        fileToCheck = Dir$
    Loop

    ' delete archive files older than X days
    fileToCheck = ""
    fileToCheck = Dir$(sProcessDir & "\AffinityMedicaid\Archive")
    Do While fileToCheck <> ""
        If FileIsDaysOld(sProcessDir & "\AffinityMedicaid\Archive\" & fileToCheck, nDeleteLogsAfterDays) Then
            KillFile sProcessDir & "\AffinityMedicaid\Archive\" & fileToCheck
        End If
        DoEvents
        fileToCheck = Dir$
    Loop

    ' delete archive files older than X days
    fileToCheck = ""
    fileToCheck = Dir$(sProcessDir & "\HealthFirst\Archive")
    Do While fileToCheck <> ""
        If FileIsDaysOld(sProcessDir & "\HealthFirst\Archive\" & fileToCheck, nDeleteLogsAfterDays) Then
            KillFile sProcessDir & "\HealthFirst\Archive\" & fileToCheck
        End If
        DoEvents
        fileToCheck = Dir$
    Loop

    ' delete archive files older than X days
    fileToCheck = ""
    fileToCheck = Dir$(sProcessDir & "\OPTUM\Archive")
    Do While fileToCheck <> ""
        If FileIsDaysOld(sProcessDir & "\OPTUM\Archive\" & fileToCheck, nDeleteLogsAfterDays) Then
            KillFile sProcessDir & "\OPTUM\Archive\" & fileToCheck
        End If
        DoEvents
        fileToCheck = Dir$
    Loop

    ' delete archive files older than X days
    fileToCheck = ""
    fileToCheck = Dir$(sProcessDir & "\SMS\Archive")
    Do While fileToCheck <> ""
        If FileIsDaysOld(sProcessDir & "\SMS\Archive\" & fileToCheck, nDeleteLogsAfterDays) Then
            KillFile sProcessDir & "\SMS\Archive\" & fileToCheck
        End If
        DoEvents
        fileToCheck = Dir$
    Loop

    ' delete archive files older than X days
    fileToCheck = ""
    fileToCheck = Dir$(sProcessDir & "\StockAmp\Archive")
    Do While fileToCheck <> ""
        If FileIsDaysOld(sProcessDir & "\StockAmp\Archive\" & fileToCheck, nDeleteLogsAfterDays) Then
            KillFile sProcessDir & "\StockAmp\Archive\" & fileToCheck
        End If
        DoEvents
        fileToCheck = Dir$
    Loop

    LogMessage "MODULE: Utils SUB: ClaenHouse:" & " deleted archive files older than " & nDeleteLogsAfterDays

    ' delete resutls files older than X days
    fileToCheck = ""
    fileToCheck = Dir$(goConfig.ReportsFolder)
    Do While fileToCheck <> ""
        If FileIsDaysOld(goConfig.ReportsFolder & "\" & fileToCheck, nDeleteLogsAfterDays) Then
            KillFile goConfig.ReportsFolder & "\" & fileToCheck
        End If
        DoEvents
        fileToCheck = Dir$
    Loop

    ' delete resutls files older than X days
    fileToCheck = ""
    fileToCheck = Dir$(goConfig.ReportsFolder & "\ErroredFiles")
    Do While fileToCheck <> ""
        If FileIsDaysOld(goConfig.ReportsFolder & "\ErroredFiles\" & fileToCheck, nDeleteLogsAfterDays) Then
            KillFile goConfig.ReportsFolder & "\ErroredFiles\" & fileToCheck
        End If
        DoEvents
        fileToCheck = Dir$
    Loop

    LogMessage "MODULE: Utils SUB: ClaenHouse:" & " deleted 1 week old error files"
    LogMessage "MODULE: Utils SUB: ClaenHouse:" & " end"

    Exit Sub
ErrorHandler:
    ' error not critical here, only log it
    Logging "ERROR: MODULE: Utils SUB: CleanHouse: " & Err.Number & ":" & Err.Description
    Resume Next
End Sub

' return true if the modified date of the passed in complete path and filename
' is greater than given day(s) old
Function FileIsDaysOld(inputfile As String, numberDays As Integer) As Boolean
    Dim fso As Object, targetFile As Object
    Dim modifiedDate As Date

    Set fso = CreateObject("Scripting.FileSystemObject")

    Set targetFile = fso.GetFile(inputfile)

    modifiedDate = targetFile.DateLastModified

    If DateDiff("d", modifiedDate, Date) > numberDays Then
        FileIsDaysOld = True
    Else
        FileIsDaysOld = False
    End If

End Function


' runs IE and launches the website
Sub LaunchAndConnect_IE2(oConfig As cConfig)
'On Error GoTo ErrorHandler

    LogMessage "MODULE: Utils SUB: LaunchAndConnect_IE2:" & " begin"
TryConnectAgain:
    If Not IsWindowEx("*Internet Explorer*") Then
        LogMessage "MODULE: Utils SUB: LaunchAndConnect_IE2:" & " executing shell command on loginurl"
        Shell oConfig.InternetExplorerPath & " " & oConfig.LoginURL, vbNormalFocus
        LogMessage "MODULE: Utils SUB: LaunchAndConnect_IE2:" & " executed shell command on loginurl"
    End If
    Wait

    LogMessage "MODULE: Utils SUB: LaunchAndConnect_IE2:" & " before attempting to activate the login page"
    Do Until B2.Active
        B2.TimeOut = oConfig.WebTimeout
        B2.Activate oConfig.LoginCaption, True
        B2.Connect oConfig.LoginCaption, stWeb1
        B2.TimeOut = oConfig.WebTimeout
        Wait 1
        gnConnectRetry = gnConnectRetry + 1
        LogMessage "MODULE: Utils SUB: LaunchAndConnect_IE2:" & " attempted " & gnConnectRetry & " times to connect to the login page out of " & goConfig.MaxIERestarts & " attempts"
        If gnConnectRetry > oConfig.MaxIERestarts Then
            Err.Raise vbObjectError + 1000, "LaunchAndConnect_IE2", "Unable to connect to IE."
        End If
    Loop
    LogMessage "MODULE: Utils SUB: LaunchAndConnect_IE2:" & " after attempting to activate the login page"

    'WaitForPage

    LogMessage "MODULE: Utils SUB: LaunchAndConnect_IE2:" & " end"

    Exit Sub
ErrorHandler:
    Dim errDesc As String
    Dim errNum As Long
    errDesc = Err.Description
    errNum = Err.Number
    If Err.Number = 91 Then
        Resume TryConnectAgain
    ElseIf Err.Number = vbObjectError + 1000 Then
        Resume TryConnectAgain
    Else
        ' rethrow error up the food chain
        Err.Raise errNum, "ERROR: MODULE: Utils SUB: LaunchAndConnect_IE2: ", errDesc
    End If
End Sub

' runs IE and launches the website
Sub LaunchAndConnect_IE(oConfig As cConfig)
'On Error GoTo ErrorHandler

    LogMessage "MODULE: Utils SUB: LaunchAndConnect_IE:" & " begin"

TryConnectAgain:
    If Not IsWindowEx("*Internet Explorer*") Then
        LogMessage "MODULE: Utils SUB: LaunchAndConnect_IE:" & " executing shell command on loginurl"
        Shell oConfig.InternetExplorerPath & " " & oConfig.LoginURL, vbNormalFocus
        LogMessage "MODULE: Utils SUB: LaunchAndConnect_IE:" & " executed shell command on loginurl"
    End If
    Wait

    LogMessage "MODULE: Utils SUB: LaunchAndConnect_IE:" & " before attempting to activate the login page"
    Do Until Active
        TimeOut = oConfig.WebTimeout
        Activate oConfig.LoginCaption, True
        Connect oConfig.LoginCaption, stWeb1
        TimeOut = oConfig.WebTimeout
        Wait 1
        gnConnectRetry = gnConnectRetry + 1
        LogMessage "MODULE: Utils SUB: LaunchAndConnect_IE:" & " attempted " & gnConnectRetry & " times to connect to the login page out of " & goConfig.MaxIERestarts & " attempts"
        If gnConnectRetry > oConfig.MaxIERestarts Then
            Err.Raise vbObjectError + 1000, "LaunchAndConnect_IE", "Unable to connect to IE."
        End If
    Loop
    LogMessage "MODULE: Utils SUB: LaunchAndConnect_IE:" & " after attempting to activate the login page"

    'WaitForPage

    LogMessage "MODULE: Utils SUB: LaunchAndConnect_IE:" & " end"

    Exit Sub
ErrorHandler:
    Dim errDesc As String
    Dim errNum As Long
    errDesc = Err.Description
    errNum = Err.Number
    If Err.Number = 91 Then
        Resume TryConnectAgain
    ElseIf Err.Number = vbObjectError + 1000 Then
        Resume TryConnectAgain
    Else
        ' rethrow error up the food chain
        Err.Raise errNum, "ERROR: MODULE: Utils SUB: LaunchAndConnect_IE: ", errDesc
    End If
End Sub


' waits for the web document to load
Sub WaitForPage(Optional bDummy As Boolean)
    Do Until Not (Web1.Busy)
        Wait 0.2
        DoEvents
    Loop
    'Do Until (Web1.IE.document.readystate = "complete" Or Web1.IE.document.readystate = "interactive")
    Do Until (Web1.IE.document.readyState = "complete")    'Or Web1.IE.document.readystate = "interactive")
        Wait 0.2
        DoEvents
    Loop
End Sub

' waits for the web document to load
Sub WaitForPage2(Optional bDummy As Boolean)
    Do Until Not (B2.Web1.Busy)
        Wait 0.2
        DoEvents
    Loop
    Do Until (B2.Web1.IE.document.readyState = "complete")    'Or Web1.IE.document.readystate = "interactive")
        Wait 0.2
        DoEvents
    Loop
End Sub

' waits for the web document to load
Sub WaitForPageFrames(objDoc As Object)
    Dim lngCount As Long

    'wait until the top document object is completely loaded
    Do Until objDoc.readyState = "complete"
        Wait 0.2

        'recurse the other frames
        For lngCount = 0 To objDoc.frames.length - 1
            WaitForPageFrames objDoc.frames.Item(lngCount).document
        Next
    Loop
End Sub


' an error occurred where the automation can no longer function properly
' log it, send an email notification and
' shutdown BWS
Sub SendFatalError2(oConfig As cConfig, Optional DetailText As String)
    Dim sRetString As String

    On Error GoTo ErrorHandler

    sRetString = SendEmail2(oConfig.StatusNotifyEmailID, "FATAL ERROR " & oConfig.ProjectName, "The " & oConfig.ProjectName & " automation has encountered a fatal error." & _
                                                                                               vbCrLf & _
                                                                                               DetailText & _
                                                                                               vbCrLf & _
                                                                                               "MachineName: " & oConfig.MachineName, oConfig.EmailServer, oConfig.EMailUserID, oConfig.EMailPassword)

    Logging "FATAL ERROR: The " & oConfig.ProjectName & " automation has encountered a fatal error." & _
            vbCrLf & _
            DetailText & _
            vbCrLf & _
            "An attempt was made to send an email notification with return status of: " & sRetString

    ' close Ineternet Explorer
    ' kill IE
    Shell (Environ("Windir") & "\SYSTEM32\TASKKILL.EXE /F /IM IEXPLORE.EXE")
    Wait 5
    '    If Not Web1 Is Nothing Then
    '        Web1.WB.quit
    '    End If

    Shutdown = True    ' fatal error, stop the script
    Exit Sub
ErrorHandler:
    ' we dont need to do anything
    Logging "ERROR: MODULE: Utils SUB: SendFatalError2: " & Err.Number & ":" & Err.Description
End Sub

' log it, send an email notification and
Sub SendStatusEmail2(oConfig As cConfig, Optional DetailText As String)
    Dim sRetString As String

    On Error GoTo ErrorHandler

    sRetString = SendEmail2(oConfig.StatusNotifyEmailID, "INFO " & oConfig.ProjectName, "The " & oConfig.ProjectName & _
                                                                                        vbCrLf & _
                                                                                        DetailText & _
                                                                                        vbCrLf & _
                                                                                        "MachineName: " & oConfig.MachineName, oConfig.EmailServer, oConfig.EMailUserID, oConfig.EMailPassword)

    Logging "INFO : The " & oConfig.ProjectName & _
            vbCrLf & _
            DetailText & _
            vbCrLf & _
            "An attempt was made to send an email notification with return status of: " & sRetString

    Exit Sub
ErrorHandler:
    ' we dont need to do anything
    Logging "ERROR: MODULE: Utils SUB: SendFatalError2: " & Err.Number & ":" & Err.Description
End Sub


' an error occurred where the automation can no longer function properly
' log it, send an email notification and
' shutdown BWS
Sub SendFatalError(sErroNotifyEmail As String, sProjectName As String, sMachineName As String, sMailServer As String, sMailUserID As String, sMailPwd As String, Optional DetailText As String)
    Dim sRetString As String

    On Error GoTo ErrorHandler

    sRetString = SendEmail2(sErroNotifyEmail, "FATAL ERROR " & sProjectName, _
                            "The " & sProjectName & " automation has encountered a fatal error." & _
                            vbCrLf & _
                            DetailText & _
                            vbCrLf & _
                            "MachineName: " & sMachineName, sMailServer, sMailUserID, sMailPwd)

    Logging "FATAL ERROR: The " & sProjectName & " automation has encountered a fatal error." & _
            vbCrLf & _
            DetailText & _
            vbCrLf & _
            "An attempt was made to send an email notification with return status of: " & sRetString

    ' close Ineternet Explorer
    '    Web1.WB.quit

    ' kill IE
    Shell (Environ("Windir") & "\SYSTEM32\TASKKILL.EXE /F /IM IEXPLORE.EXE")
    Wait 5

    Shutdown = True    ' fatal error, stop the script
    Exit Sub
ErrorHandler:
    ' we dont need to do anything
    Logging "ERROR: MODULE: Utils SUB: SendFatalError: " & Err.Number & ":" & Err.Description
    Shutdown = True    ' fatal error, stop the script
End Sub

' sends email
Function SendEmail2(sMailTo As String, sSubject As String, sBody As String, sMailServer, sMailUserID, sMailPwd, Optional sAttachments As String) As String
    Dim sTempAttachments As String

    ' if any attachments fail, it will cause the email to fail
    If sAttachments <> "" Then
        sTempAttachments = CheckAttachmentsExist(sAttachments)
    End If

    ' todo enable this later
    SendEmail2 = SendMail(sMailTo, sSubject, sBody, "SSanderson@bmhmc.org", sTempAttachments, sMailServer, "EMPTY", "EMPTY", "25")

End Function

' take a screenshot of whole desktop and return
' the screenshot filename
Function TakeScreenshot2(sLogFolder As String) As String
    Dim sFileName As String
    sFileName = sLogFolder & "errScreenShot_" & Format(Now, "mmddyyyy_hhnn") & ".bmp"
    ScreenShot sFileName, False
    TakeScreenshot2 = sFileName
End Function

' take a screenshot of whole desktop and return
' the screenshot filename
Function TakeScreenshot3(sLogFolder As String, sFIlePrefix As String) As String
    Dim sFileName As String
    sFileName = sLogFolder & sFIlePrefix & "_ScreenShot_" & Format(Now, "mmddyyyy_hhnnss") & ".bmp"
    ScreenShot sFileName, False
    TakeScreenshot3 = sFileName
End Function

' sends success email
Sub SendSuccessEMail(Optional sMsg As String)
    Dim sReturnString As String

    On Error GoTo ErrorHandler

    sReturnString = SendEmail(goConfig.StatusNotifyEmailID, "Success Process Completed: " & goConfig.ProjectName & sMsg, _
                              "The " & goConfig.ProjectName & " is completed successfully" & sMsg & "." & _
                              vbCrLf & _
                              "MachineName: " & goConfig.MachineName)

    Logging "Success Process Completed: The " & goConfig.ProjectName & " is completed successfully" & sMsg & "." & _
            vbCrLf & _
            "An attempt was made to send an email notification with return status of: " & sReturnString

    Exit Sub
ErrorHandler:
    ' we dont need to do anything
    Logging "ERROR: MODULE: Utils SUB: SendSuccessEMail: " & Err.Number & ":" & Err.Description
End Sub

' reads setup file, this happens in the cConfig class
Function ReadSetupFile(Optional bDummy As Boolean) As Boolean
    On Error GoTo ErrorHandler
    ' file system object
    Set goFSO = New FileSystemObject

    Set goConfig = New cConfig

    ReadSetupFile = True
    Exit Function
ErrorHandler:
    SendFatalError2 goConfig, "ERROR: MODULE: Utils SUB: ReadSetupFile: " & Err.Number & ":" & Err.Description
End Function

' validates if the required field value is passed in, if not sends out a fatal error email and shuts down the BWS
Sub RequiredGlobalDataMissing(sData As String, oConfig As cConfig, sErrorMessage As String)
    If sData = vbNullString Then
        SendFatalError2 oConfig, sErrorMessage
    End If
End Sub

' validates if the field is passed in , if not logs the validation message.
Sub GlobalDataMissing(sData As String, sErrorMessage As String)
    If sData = vbNullString Then
        LogMessage sErrorMessage
    End If
End Sub

' cleans up an objects
Sub WrapUp(Optional bDummy As Boolean)
' cleanup
    If Not goConfig Is Nothing Then
        Set goConfig = Nothing
    End If

    If Not goFSO Is Nothing Then
        Set goFSO = Nothing
    End If

    If Not goDoc Is Nothing Then
        Set goDoc = Nothing
    End If

    If Not goIE Is Nothing Then
        Set goIE = Nothing
    End If

End Sub

' logs message when the log ind is set to 5
Sub LogMessage(sMessage As String)
' logind 5 logs everything
    If goConfig.LogInd = 5 Then
        Logging sMessage
    End If
End Sub

Sub LogMessageLines(sMessage As String)
    LogMessage sMessage
End Sub

' Returns true if the specified file exists
Function FileExists(inputfile As String) As Boolean
    Dim fso As Object

    Set fso = CreateObject("Scripting.FileSystemObject")

    If fso.FileExists(inputfile) Then
        FileExists = True
    Else
        FileExists = False
    End If

End Function



' click the combobox
Function ClickTheComboBoxQrySelectorB2(sName As String, sSearchFor As String, sSourceVal As String, sWebFieldName As String, bRequired As Boolean, sFireEvent As String, Optional bClickOnit As Boolean, Optional bExactMatch As Boolean = False) As enumControlStatus
    Dim bFound As Boolean
    Dim iSub As Integer
    Dim bWebElemFound As Boolean
    Dim elem As IHTMLElement
    Dim doc As HTMLDocument

    ClickTheComboBoxQrySelectorB2 = eCONTROL_NOT_VALID

    If Not bRequired And sSourceVal = vbNullString Then
        ClickTheComboBoxQrySelectorB2 = eCONTROL_VALID
        Exit Function
    End If

    Set doc = B2.Web1.IE.document
    Set elem = doc.querySelector("[name='" & sName & "']")
    Set B2.Web1.selected = elem

    ' if it is not found log and move on to the next claim
    If B2.Web1.selected Is Nothing And bRequired Then
        ClickTheComboBoxQrySelectorB2 = eCONTROL_CONTROL_NOT_FOUND
        '            oClaim.Status = sWebFieldName & " passed in is - " & sSourceVal & " but web field " & sWebFieldName & " is not found"
        '            oClaim.StatusInd = 3
        '            oclaims.SaveStatus goConfig.DBConnectString, "NOT PROCESSED", oClaim.Key
        Exit Function
    End If

    ' loop thru all the Options (children), until we find the one we want

    LogMessage "MODULE: Utils Sub: ClickTheComboBoxQrySelectorB2:" & " Looking for " & sWebFieldName & "... " & sSourceVal
    bFound = False
    For iSub = 0 To B2.Web1.selected.children.length - 1
        ' Debug.Print Web1.Selected.Children(i).innertext
        If bExactMatch Then
            If UCase(B2.Web1.selected.children(iSub).innerText) = UCase(sSearchFor) Then
                LogMessage "MODULE: Utils Sub: ClickTheComboBoxQrySelectorB2:" & " Found " & sWebFieldName & "... " & B2.Web1.selected.children(iSub).innerText
                Set B2.selected = B2.Web1.selected.children(iSub)
                bFound = True
                'Web1.selected.doAction
                B2.Click
                If sFireEvent = vbNullString Then
                    ' do nothing
                Else
                    B2.Web1.selected.parentElement.FireEvent sFireEvent
                    'Web1.selected.parentElement.parentElement.FireEvent sFireEvent
                End If
                Exit For
            End If
        Else
            If InStr(1, UCase(B2.Web1.selected.children(iSub).innerText), UCase(sSearchFor)) > 0 Then
                LogMessage "MODULE: Utils Sub: ClickTheComboBoxQrySelectorB2:" & " Found " & sWebFieldName & "... " & B2.Web1.selected.children(iSub).innerText
                Set B2.selected = B2.Web1.selected.children(iSub)
                bFound = True
                'Web1.selected.doAction
                B2.Click
                If sFireEvent = vbNullString Then
                    ' do nothing
                Else
                    B2.Web1.selected.parentElement.FireEvent sFireEvent
                    'Web1.selected.parentElement.parentElement.FireEvent sFireEvent
                End If
                Exit For
            End If
        End If
    Next iSub

    ' if it is not found log and move on to the next claim
    If Not bFound And bRequired Then
        ClickTheComboBoxQrySelectorB2 = eCONTROL_ITEM_NOT_FOUND
        Exit Function
    End If

    ClickTheComboBoxQrySelectorB2 = eCONTROL_VALID
End Function


' click the combobox
Function ClickTheComboBoxQrySelector(sName As String, sSearchFor As String, sSourceVal As String, sWebFieldName As String, bRequired As Boolean, sFireEvent As String, Optional bClickOnit As Boolean, Optional bExactMatch As Boolean = False) As enumControlStatus
    Dim bFound As Boolean
    Dim iSub As Integer
    Dim bWebElemFound As Boolean
    Dim elem As IHTMLElement
    Dim doc As HTMLDocument

    ClickTheComboBoxQrySelector = eCONTROL_NOT_VALID

    If Not bRequired And sSourceVal = vbNullString Then
        ClickTheComboBoxQrySelector = eCONTROL_VALID
        Exit Function
    End If

    Set doc = Web1.IE.document
    Set elem = doc.querySelector("[name='" & sName & "']")
    Set Web1.selected = elem

    ' if it is not found log and move on to the next claim
    If Web1.selected Is Nothing And bRequired Then
        ClickTheComboBoxQrySelector = eCONTROL_CONTROL_NOT_FOUND
        '            oClaim.Status = sWebFieldName & " passed in is - " & sSourceVal & " but web field " & sWebFieldName & " is not found"
        '            oClaim.StatusInd = 3
        '            oclaims.SaveStatus goConfig.DBConnectString, "NOT PROCESSED", oClaim.Key
        Exit Function
    End If

    ' loop thru all the Options (children), until we find the one we want

    LogMessage "MODULE: Utils Sub: ClickTheComboBoxQrySelector:" & " Looking for " & sWebFieldName & "... " & sSourceVal
    bFound = False
    For iSub = 0 To Web1.selected.children.length - 1
        ' Debug.Print Web1.Selected.Children(i).innertext
        If bExactMatch Then
            If UCase(Web1.selected.children(iSub).innerText) = UCase(sSearchFor) Then
                LogMessage "MODULE: Utils Sub: ClickTheComboBoxQrySelector:" & " Found " & sWebFieldName & "... " & Web1.selected.children(iSub).innerText
                Set selected = Web1.selected.children(iSub)
                bFound = True
                'Web1.selected.doAction
                Click
                If sFireEvent = vbNullString Then
                    ' do nothing
                Else
                    Web1.selected.parentElement.FireEvent sFireEvent
                    'Web1.selected.parentElement.parentElement.FireEvent sFireEvent
                End If
                Exit For
            End If
        Else
            If InStr(1, UCase(Web1.selected.children(iSub).innerText), UCase(sSearchFor)) > 0 Then
                LogMessage "MODULE: Utils Sub: ClickTheComboBoxQrySelector:" & " Found " & sWebFieldName & "... " & Web1.selected.children(iSub).innerText
                Set selected = Web1.selected.children(iSub)
                bFound = True
                'Web1.selected.doAction
                Click
                If sFireEvent = vbNullString Then
                    ' do nothing
                Else
                    Web1.selected.parentElement.FireEvent sFireEvent
                    'Web1.selected.parentElement.parentElement.FireEvent sFireEvent
                End If
                Exit For
            End If
        End If
    Next iSub

    ' if it is not found log and move on to the next claim
    If Not bFound And bRequired Then
        ClickTheComboBoxQrySelector = eCONTROL_ITEM_NOT_FOUND
        '        oClaim.Status = sWebFieldName & " passed in is - " & sSourceVal & " but it was not found in the available " & sWebFieldName
        '        oClaim.StatusInd = 2
        '        oclaims.SaveStatus goConfig.DBConnectString, "NOT PROCESSED", oClaim.Key
        Exit Function
    End If

    ClickTheComboBoxQrySelector = eCONTROL_VALID
End Function


' click the combobox
Function ClickTheComboBoxEx(sPauseString As String, sSearchFor As String, sSourceVal As String, sWebFieldName As String, bRequired As Boolean, sFireEvent As String, Optional bLoopInd As Boolean, Optional sName As String, Optional bClickOnit As Boolean, Optional bExactMatch As Boolean = False) As enumControlStatus
    Dim bFound As Boolean
    Dim iSub As Integer
    Dim bWebElemFound As Boolean
    Dim nDoLoopCnt As Integer

    ClickTheComboBoxEx = eCONTROL_NOT_VALID

    If Not bRequired And sSourceVal = vbNullString Then
        ClickTheComboBoxEx = eCONTROL_VALID
        Exit Function
    End If

    Pause sPauseString

    If bClickOnit Then
        Click
        Wait 0.5
    End If

    If bLoopInd Then
        Pause sPauseString
        bWebElemFound = False
        Do
            nDoLoopCnt = nDoLoopCnt + 1
            Set selected = NextElement(selected)
            If Web1.selected.tagName = "SELECT" Then
                If Web1.selected.name = sName Then
                    bWebElemFound = True
                    Exit Do
                End If
            End If
            If nDoLoopCnt > 20 Then
                Exit Do
            End If
        Loop

        ' if it is not found log and move on to the next claim
        If Not bWebElemFound And bRequired Then
            ClickTheComboBoxEx = eCONTROL_CONTROL_NOT_FOUND
            '            oClaim.Status = sWebFieldName & " passed in is - " & sSourceVal & " but web field " & sWebFieldName & " is not found"
            '            oClaim.StatusInd = 3
            '            oclaims.SaveStatus goConfig.DBConnectString, "NOT PROCESSED", oClaim.Key
            Exit Function
        End If
    End If

    ' loop thru all the Options (children), until we find the one we want

    LogMessage "MODULE: Utils Sub: ClickTheComboBoxEx:" & " Looking for " & sWebFieldName & "... " & sSourceVal
    bFound = False
    For iSub = 0 To Web1.selected.children.length - 1
        ' Debug.Print Web1.Selected.Children(i).innertext
        If bExactMatch Then
            If UCase(Web1.selected.children(iSub).innerText) = UCase(sSearchFor) Then
                LogMessage "MODULE: Utils Sub: ClickTheComboBoxEx:" & " Found " & sWebFieldName & "... " & Web1.selected.children(iSub).innerText
                Set selected = Web1.selected.children(iSub)
                bFound = True
                'Web1.selected.doAction
                Click
                If sFireEvent = vbNullString Then
                    ' do nothing
                Else
                    Web1.selected.parentElement.FireEvent sFireEvent
                    'Web1.selected.parentElement.parentElement.FireEvent sFireEvent
                End If
                Exit For
            End If
        Else
            If InStr(1, UCase(Web1.selected.children(iSub).innerText), UCase(sSearchFor)) > 0 Then
                LogMessage "MODULE: Utils Sub: ClickTheComboBoxEx:" & " Found " & sWebFieldName & "... " & Web1.selected.children(iSub).innerText
                Set selected = Web1.selected.children(iSub)
                bFound = True
                'Web1.selected.doAction
                Click
                If sFireEvent = vbNullString Then
                    ' do nothing
                Else
                    Web1.selected.parentElement.FireEvent sFireEvent
                    'Web1.selected.parentElement.parentElement.FireEvent sFireEvent
                End If
                Exit For
            End If
        End If
    Next iSub

    ' if it is not found log and move on to the next claim
    If Not bFound And bRequired Then
        ClickTheComboBoxEx = eCONTROL_ITEM_NOT_FOUND
        '        oClaim.Status = sWebFieldName & " passed in is - " & sSourceVal & " but it was not found in the available " & sWebFieldName
        '        oClaim.StatusInd = 2
        '        oclaims.SaveStatus goConfig.DBConnectString, "NOT PROCESSED", oClaim.Key
        Exit Function
    End If

    ClickTheComboBoxEx = eCONTROL_VALID
End Function


' click the combobox
Function ClickTheComboBoxSelected(sPauseString As String, sSearchFor As String, sSourceVal As String, sWebFieldName As String, bRequired As Boolean, sFireEvent As String, Optional bLoopInd As Boolean, Optional sName As String, Optional bClickOnit As Boolean, Optional bExactMatch As Boolean = False) As enumControlStatus
    Dim bFound As Boolean
    Dim iSub As Integer
    Dim bWebElemFound As Boolean
    Dim nDoLoopCnt As Integer

    ClickTheComboBoxSelected = eCONTROL_NOT_VALID

    If Not bRequired And sSourceVal = vbNullString Then
        ClickTheComboBoxSelected = eCONTROL_VALID
        Exit Function
    End If

    Pause sPauseString

    If bClickOnit Then
        Click
        Wait 0.5
    End If

    If bLoopInd Then
        Pause sPauseString
        bWebElemFound = False
        Do
            nDoLoopCnt = nDoLoopCnt + 1
            Set selected = NextElement(selected)
            If Web1.selected.tagName = "SELECT" Then
                If Web1.selected.name = sName Then
                    bWebElemFound = True
                    Exit Do
                End If
            End If
            If nDoLoopCnt > 20 Then
                Exit Do
            End If
        Loop

        ' if it is not found log and move on to the next claim
        If Not bWebElemFound And bRequired Then
            ClickTheComboBoxSelected = eCONTROL_CONTROL_NOT_FOUND
            '            oClaim.Status = sWebFieldName & " passed in is - " & sSourceVal & " but web field " & sWebFieldName & " is not found"
            '            oClaim.StatusInd = 3
            '            oclaims.SaveStatus goConfig.DBConnectString, "NOT PROCESSED", oClaim.Key
            Exit Function
        End If
    End If

    ' loop thru all the Options (children), until we find the one we want

    LogMessage "MODULE: Utils Sub: ClickTheComboBoxSelected:" & " Looking for " & sWebFieldName & "... " & sSourceVal
    bFound = False
    For iSub = 0 To Web1.selected.children.length - 1
        ' Debug.Print Web1.Selected.Children(i).innertext
        If bExactMatch Then
            If UCase(Web1.selected.children(iSub).innerText) = UCase(sSearchFor) Then
                LogMessage "MODULE: Utils Sub: ClickTheComboBoxSelected:" & " Found " & sWebFieldName & "... " & Web1.selected.children(iSub).innerText
                Set selected = Web1.selected.children(iSub)
                bFound = True
                'Web1.selected.doAction
                Click
                If sFireEvent = vbNullString Then
                    ' do nothing
                Else
                    Web1.selected.parentElement.FireEvent sFireEvent
                    'Web1.selected.parentElement.parentElement.FireEvent sFireEvent
                End If
                Exit For
            End If
        Else
            If InStr(1, UCase(Web1.selected.children(iSub).innerText), UCase(sSearchFor)) > 0 Then
                LogMessage "MODULE: Utils Sub: ClickTheComboBoxSelected:" & " Found " & sWebFieldName & "... " & Web1.selected.children(iSub).innerText
                Set selected = Web1.selected.children(iSub)
                bFound = True
                Web1.selected.selected = True
                'Web1.selected.doAction
                'Click
                If sFireEvent = vbNullString Then
                    ' do nothing
                Else
                    Web1.selected.parentElement.FireEvent sFireEvent
                    'Web1.selected.parentElement.parentElement.FireEvent sFireEvent
                End If
                Exit For
            End If
        End If
    Next iSub

    ' if it is not found log and move on to the next claim
    If Not bFound And bRequired Then
        ClickTheComboBoxSelected = eCONTROL_ITEM_NOT_FOUND
        '        oClaim.Status = sWebFieldName & " passed in is - " & sSourceVal & " but it was not found in the available " & sWebFieldName
        '        oClaim.StatusInd = 2
        '        oclaims.SaveStatus goConfig.DBConnectString, "NOT PROCESSED", oClaim.Key
        Exit Function
    End If

    ClickTheComboBoxSelected = eCONTROL_VALID
End Function






' enter text into the input box
Sub EnterTextIntoInputBox(sPauseString As String, sSourceVal As String)
    If sSourceVal = vbNullString Then
        ' skip
    Else
        text(sPauseString) = sSourceVal
    End If
End Sub

Function GetElementByName(sElementName As String, Optional nInstance As Integer = 1) As IHTMLElement
    Dim oElement As IHTMLElement
    Dim oCollection As IHTMLElementCollection
    Dim nCounter As Integer

    On Error GoTo ErrorHandler

    Set GetElementByName = Nothing
    Set oCollection = Web1.IE.document.getElementsByName(sElementName)
    ' loop thru to find the one we want
    For Each oElement In oCollection
        nCounter = nCounter + 1
        If nCounter = nInstance Then
            Set GetElementByName = oElement
            Exit For
        End If
    Next
    Exit Function
ErrorHandler:
    Exit Function
End Function

' requires bWS10 or above
Sub SendSpecialKey(SpecialKey As String)
    On Error GoTo ErrorHandler
    Dim bk As Object
    Set bk = CreateObject("BWS10.Keys")
    Const Hardware = 1

    ' Dim bk As New BWS10.Keys  ' early binding
    bk.Key SpecialKey, Hardware
ProcExit:
    Set bk = Nothing
    Exit Sub
ErrorHandler:
    Debug.Print Err.Number & ":" & Err.Description
    Resume ProcExit
End Sub

Function FormatDateStr(sDate As String) As String

    Dim sDateReformattted As String

    ' takes mmddyyyy as input and returns mm/dd/yyyy
    If sDate = vbNullString Then
        FormatDateStr = sDate
    Else
        sDateReformattted = Mid(sDate, 1, 2) & "/" & Mid(sDate, 3, 2) & "/" & Mid(sDate, 5, 8)
        FormatDateStr = sDateReformattted
    End If
End Function

Function WaitForAControl(sPauseString As String) As Boolean
    Dim lStartTime As Long

    WaitForAControl = False

    lStartTime = Timer
    Do
        If Web1.Find(sPauseString) Then
            DoEvents_
            Exit Do
        Else
            ' keep looping
        End If
        'Timeout if elapsed time is greater than our Timeout setting
        If Timer >= lStartTime + 10 Then    'goConfig.WebTimeout Then
            Logging "Timed out on waiting for a control " & sPauseString
            Exit Function
        End If
        DoEvents_
    Loop

    WaitForAControl = True

End Function

Sub test()
' Must be on the Verify Patient Screen
    Connect "", stWeb1
    TimeOut = 20

    ' pass in the findstring for the NPI  Input element and the desired value
    TriggerInput "<INPUT>#BaseInfoNPI#<#providerNPI OrRequired-G1-SG1 required#>@NCTracks - Verify Patient", "1043267727"

    ' pass in the findstring for the desired option
    TriggerOptionSelect "2215 BURDETT AVE<OPTION>@NCTracks - Verify Patient"

    TriggerOptionSelect "282N00000X - General Acute Care Hospital<OPTION>@NCTracks - Verify Patient"
End Sub




Public Sub SetFocus(ByVal OptionFindString As String)
    Web1.selected.parentElement.focus
    Wait 1
    Pause OptionFindString
End Sub
Public Function TriggerInputEx(InputFindString As String, sText As String, bRequired As Boolean) As enumControlStatus
    On Error GoTo ErrorHandler

    TriggerInputEx = eCONTROL_CONTROL_NOT_FOUND

    'Text(InputFindString) = sText
    'Use http://api.jquery.com/trigger/ on the id
    'use the element's ID and trigger a jquery event
    Pause InputFindString
    Web1.selected.value = sText
    Web1.selected.focus
    Web1.IE.document.parentWindow.execScript "$('#" & Web1.selected.id & "').trigger('change')"
    TriggerInputEx = eCONTROL_VALID

    Exit Function

ErrorHandler:
    If bRequired Then
        TriggerInputEx = eCONTROL_ITEM_NOT_FOUND
    End If
End Function

Public Function TriggerInputExBlur(InputFindString As String, sText As String, Optional bUsePhyKey As Boolean, Optional bSlowKey As Boolean) As enumControlStatus
    On Error GoTo ErrorHandler

    TriggerInputExBlur = eCONTROL_CONTROL_NOT_FOUND

    'Text(InputFindString) = sText
    'Use http://api.jquery.com/trigger/ on the id
    'use the element's ID and trigger a jquery event
    Pause InputFindString
    If bUsePhyKey Then
        Web1.selected.focus
        If bSlowKey Then
            SendPhyKeysSlow sText
        Else
            SendPhyKeys sText
        End If
        TriggerInputExBlur = eCONTROL_VALID
    Else
        Web1.selected.value = sText
        Web1.selected.focus
        'Web1.IE.document.parentWindow.execScript "$('#" & Web1.selected.id & "').trigger('change')"
        Web1.IE.document.parentWindow.execScript "$('#" & Web1.selected.id & "').trigger('blur')"
        TriggerInputExBlur = eCONTROL_VALID
    End If
    Exit Function

ErrorHandler:
End Function

Function TriggerInputBlurWrapper(sPauseString As String, sSearchFor As String, sSourceVal As String, sWebFieldName As String, bRequired As Boolean, Optional bUsePhyKeys As Boolean, Optional bSlowKeys As Boolean) As Boolean

    Dim nControlStatusInd As Integer

    TriggerInputBlurWrapper = False

    If Not bRequired And sSourceVal = vbNullString Then
        TriggerInputBlurWrapper = True
        Exit Function
    End If

    nControlStatusInd = TriggerInputExBlur(sPauseString, sSearchFor, bUsePhyKeys, bSlowKeys)

    Select Case nControlStatusInd
    Case eCONTROL_VALID
        TriggerInputBlurWrapper = True
        Exit Function
    Case eCONTROL_NOT_VALID
        Exit Function
    Case eCONTROL_CONTROL_NOT_FOUND
        Exit Function
    Case eCONTROL_ITEM_NOT_FOUND
        Exit Function
    End Select

    TriggerInputBlurWrapper = True
End Function



' used for status form
' Move a window designated by its caption to
' BottomCenter, BottomLeft, BottomRight, Center,
' CenterLeft, CenterRight, TopCenter, TopLeft, or TopRight
' no connection needed
Public Sub MoveWindowByCaption(windowCaption As String, Position As FormAlign)

    Dim psngLeft As Single, psngTop As Single
    Dim scrnWt As Single
    Dim scrnHt As Single
    Dim cgw As New CGetWindow
    Dim windowHt As Long
    Dim windowWt As Long
    Dim windowHwnd As Long

    scrnWt = GetSystemMetrics(SM_CXFULLSCREEN)
    scrnHt = GetSystemMetrics(SM_CYFULLSCREEN)

    Activate windowCaption, True
    windowHwnd = GetForeGroundhWnd
    cgw.GetWindowSize windowHwnd, windowHt, windowWt

    Select Case Position
    Case BottomCenter
        psngTop = scrnHt - windowHt
        psngLeft = (scrnWt - windowWt) / 2
    Case BottomLeft
        psngTop = scrnHt - windowHt
        psngLeft = 1
    Case BottomRight
        psngTop = scrnHt - windowHt
        psngLeft = scrnWt - windowWt
    Case center
        psngTop = (scrnHt - windowHt) / 2
        psngLeft = (scrnWt - windowWt) / 2
    Case CenterLeft
        psngTop = (scrnHt - windowHt) / 2
        psngLeft = 1
    Case CenterRight
        psngTop = (scrnHt - windowHt) / 2
        psngLeft = scrnWt - windowWt
    Case TopCenter
        psngTop = 1
        psngLeft = (scrnWt - windowWt) / 2
    Case TopLeft
        psngTop = 1
        psngLeft = 1
    Case TopRight
        psngTop = 1
        psngLeft = scrnWt - windowWt
    End Select

    Activate windowCaption, True
    cgw.SetWindowPosition windowHwnd, (psngLeft), (psngTop)

End Sub
Public Sub ThomTest()
'Wait 10
    TriggerInput "<INPUT>#BaseInfoNPI#<#providerNPI OrRequired-G1-SG1 required#>@NCTracks - Verify Patient", "1043267727"
    TriggerOptionSelect "2215 BURDETT AVE<OPTION>@NCTracks - Verify Patient"
    TriggerOptionSelect "282N00000X - General Acute Care Hospital<OPTION>@NCTracks - Verify Patient"
    text("<INPUT>#RecipientID#<#medium alphanumeric#>@NCTracks - Verify Patient") = "948537513L"
    text("mm/dd/yyyy<INPUT>#FromServiceDate#<#dateInput formHint dp-applied#>@NCTracks - Verify Patient") = "07/04/2015"    '  07/04/2015
    text("mm/dd/yyyy<INPUT>#ToServiceDate#<#dateInput formHint dp-applied#>@NCTracks - Verify Patient") = "07/06/2015"    '  07/06/2015
    Click " Verify<BUTTON><#submitBtn#>@NCTracks - Verify Patient"
End Sub
Public Sub TriggerInput(InputFindString As String, sText As String)
    On Error GoTo errh

    'Changed to set Value instead
    Pause InputFindString
    Web1.selected.value = sText
    Web1.selected.focus    ' Added
    Web1.IE.document.parentWindow.execScript "$('#" & Web1.selected.id & "').trigger('change')"
    Exit Sub
errh:
    Err.Raise seTimeOut, "TriggerInput", Status
End Sub
Public Sub TriggerOptionSelect(OptionFindString)
    On Error GoTo errh
    Pause OptionFindString
    Web1.selected.parentElement.value = Web1.selected.value
    Web1.IE.document.parentWindow.execScript "$('#" & Web1.selected.parentElement.id & "').trigger('change')"
    Exit Sub
errh:
    Resume Next
    Err.Raise seTimeOut, "TriggerOptionSelect", Status
End Sub

Function ActivateScreen(sScreenCaption As String, nTimeOut As Integer) As Boolean
    Dim lStartTime As Long
    ActivateScreen = False

    lStartTime = Timer
    Do
        ' add timer
        Activate sScreenCaption, True
        If caption(hWnd) = sScreenCaption Then
            DoEvents_
            Exit Do
        Else
            ' keep looping
        End If
        'Timeout if elapsed time is greater than our Timeout setting
        If Timer >= lStartTime + nTimeOut Then
            Logging sScreenCaption
            Exit Function
        End If
        DoEvents_
    Loop
    ActivateScreen = True
End Function

Function GetHwndByCaptionLike(windowCaptionLike As String) As Long
    Dim clw As New CListWindows
    Dim h As Variant
    On Error Resume Next

    ' loop thru windows that have a similar caption
    For Each h In clw.HasCaptionLike("*" & windowCaptionLike & "*")
        GetHwndByCaptionLike = h
        Exit Function
    Next

End Function

Function GetElementByTagName(sTagName As String, sElementName As String) As IHTMLElement
    Dim oElement As IHTMLElement
    Dim oCollection As IHTMLElementCollection
    Dim nCounter As Integer

    On Error GoTo ErrorHandler

    Set GetElementByTagName = Nothing
    Set oCollection = Web1.IE.document.getElementsByTagName(sTagName)
    ' loop thru to find the one we want
    For Each oElement In oCollection
        If oElement.innerText = sElementName Then
            Set GetElementByTagName = oElement
            Exit For
        End If
    Next
    Exit Function
ErrorHandler:
    Exit Function
End Function

Function GetElementByTagNameLike(sTagName As String, sElementName As String) As IHTMLElement
    Dim oElement As IHTMLElement
    Dim oCollection As IHTMLElementCollection
    Dim nCounter As Integer

    On Error GoTo ErrorHandler

    Set GetElementByTagNameLike = Nothing
    Set oCollection = Web1.IE.document.getElementsByTagName(sTagName)
    ' loop thru to find the one we want
    For Each oElement In oCollection
        If InStr(1, UCase(oElement.innerText), UCase(sElementName)) > 0 Then
            Set GetElementByTagNameLike = oElement
            Exit For
        End If
    Next
    Exit Function
ErrorHandler:
    Exit Function
End Function


Function GetElementByTagNameLikeError(sTagName As String, sElementName As String) As IHTMLElement
    Dim oElement As IHTMLElement
    Dim oCollection As IHTMLElementCollection
    Dim nCounter As Integer

    On Error GoTo ErrorHandler

    Set GetElementByTagNameLikeError = Nothing
    Set oCollection = Web1.IE.document.getElementsByTagName(sTagName)
    ' loop thru to find the one we want
    For Each oElement In oCollection
        If oElement.className = "rcbScroll rcbWidth rcbNoWrap" Or oElement.className = "RadComboBoxDropDown RadComboBoxDropDown_Default " Or oElement.className = "rcbSlide" Or oElement.className = "RadComboBox RadComboBox_Default" Or InStr(1, UCase(oElement.innerText), UCase("change provider:")) > 0 Or InStr(1, UCase(oElement.innerText), UCase("select")) > 0 Then
            ' keep going
        Else
            If InStr(1, UCase(oElement.innerText), UCase(sElementName)) > 0 Then
                Set GetElementByTagNameLikeError = oElement
                Exit For
            End If
        End If
    Next
    Exit Function
ErrorHandler:
    Exit Function
End Function

' PopupExists can be used to detect the presence of a dialog window
Function PopupExists() As Boolean
    Dim clw As New CListWindows
    Dim i As Long

    On Error GoTo ErrorHandler

    For i = 1 To (clw.InProcess(r.hWnd).Count - 1)
        If className(clw.InProcess(r.hWnd).Item(i)) = "#32770" Then
            ' Debug.Print ClassName(clw.InProcess(R.hwnd).Item(i)), View(clw.InProcess(R.hwnd).Item(i)), clw.InProcess(R.hwnd).Item(i), Cgw.IsStyle(styVISIBLE, clw.InProcess(R.hwnd).Item(i))
            SwitchToThisWindow clw.InProcess(r.hWnd).Item(i), vbNormalFocus
            PopupExists = True
            GoTo ProcExit:
        End If
    Next i
ProcExit:
    Set clw = Nothing
    Exit Function
ErrorHandler:
    If Err.Number = 9 Then    ' subscript out of range, happens when screen is changing
        Resume ProcExit
    Else
        Logging "ERROR in 'PopupExists':" & Err.Number & ":" & Err.Description, True
        Resume ProcExit
    End If
End Function

'GetPopupCaption returns the caption of a popup window
Function GetPopupCaption() As String
    Dim h As Long

    h = GetPopupHandle
    If h <> 0 Then
        GetPopupCaption = WindowText(h)
        Exit Function
    Else
        GetPopupCaption = WindowText(getParent(hWnd))
    End If
End Function

' GetPopupHandle is used by the other Popup routines.  It will return the handle of a popup window if one is found.
Function GetPopupHandle() As Long
    Dim lw As New CListWindows
    Dim handle As Variant
    ' the exe name from the config file
    For Each handle In lw.HasCaption
        'If GetProcessName(IsProcess(handle)) = goConfig.applicationName Then  'only consider popups from Paragon
        If WindowText(handle) = "Message from webpage" Then
            If className(handle) = "#32770" Then
                GetPopupHandle = handle
                Exit Function
            End If
        End If
        'End If
        'Debug.Print GetProcessName(IsProcess(handle))
    Next handle
End Function

'GetPopupText returns the text from the body of a popup window
Function GetPopupText(popupHandle As Long) As String
    Dim gw As New CGetWindow
    Dim text As String
    Dim textHandle As Long
    Dim b4 As New BostonWorkStation

    If popupHandle <> 0 Then
        b4.Connect "@_WINDOW:" & popupHandle & "@_NOCHECKHOOK", stWindows
        textHandle = gw.GetChild(popupHandle)
        Do
            ' Debug.Print ClassName(textHandle)
            If b4.className(textHandle) = "Static" Then
                text = text & b4.View(textHandle)
            End If
            textHandle = gw.GetNext(textHandle)
            If textHandle = 0 Then
                GetPopupText = text
                GoTo ProcExit
            End If
        Loop
    End If
ProcExit:
    Set b4 = Nothing
End Function


' enter text into the input box by passing in html element
Sub EnterTextIntoInputBoxHTML(oHTMLElement As IHTMLElement2, sSourceVal As String)
    If sSourceVal = vbNullString Then
        ' skip
    Else
        oHTMLElement.value = sSourceVal
    End If
End Sub

' enter text into the input box by passing in html element
Sub EnterTextIntoInputBoxHTMLDate(oHTMLElement As IHTMLElement, sSourceVal As String)
    If sSourceVal = vbNullString Then
        ' skip
    Else
        oHTMLElement.value = sSourceVal
        oHTMLElement.setAttribute "RadInputValidationValue", Format(sSourceVal, "YYYY-MM-DD") & "-00-00-00"
        oHTMLElement.setAttribute "RadInputChangeFired", "false"
        oHTMLElement.className = "riTextBox riEnabled"
    End If
End Sub


' click check box by passing in html element
Sub ClickChecBoxHTML(oHTMLElement As IHTMLElement2, sSourceVal As String)
    If sSourceVal = vbNullString Then
        ' skip
    Else
        If sSourceVal = "Y" Then
            oHTMLElement.Checked = 1
        Else
            oHTMLElement.Checked = 0
        End If
    End If
End Sub

Function CheckProcess(pKill As Boolean, username As String, Optional ByVal processName As String, Optional ByVal ProcessID As Long) As Boolean
    Dim currentProc As String
    Dim user As String
    Dim domain As String
    On Error GoTo errx
    currentProc = "CheckProcess"
    Dim oWMI, oServices, oservice
    Set oWMI = GetObject("winmgmts:\\.\root\cimv2")
    Set oServices = oWMI.InstancesOf("win32_Process")
    For Each oservice In oServices
        'Debug.Print oservice.Name, oservice.Caption, oservice.csname, oservice.Handle, oservice.parentprocessid, oservice.ProcessID, oservice.sessionid
        'Debug.Print oservice.Name
        'oservice.GetOwner user, domain
        If Trim(processName) <> "" Then
            If UCase(oservice.name) Like UCase(processName) Then
                oservice.GetOwner user, domain
                'Debug.Print oservice.Name, oservice.Caption, oservice.csname, oservice.Handle, oservice.parentprocessid, oservice.ProcessID, oservice.sessionid
                If UCase(user) = UCase(username) Then
                    If pKill = True Then
                        oservice.Terminate
                    End If
                    CheckProcess = True
                End If
            End If
        ElseIf Trim(ProcessID) <> "" Then
            If UCase(oservice.ProcessID) Like UCase(ProcessID) Then
                If pKill = True Then
                    oservice.Terminate
                End If
                CheckProcess = True
            End If
        End If
    Next
    Exit Function
errx:
    'the process could already be terminating when the terminate order is executed
    Resume Next
End Function

Function GetPopupDoc() As IHTMLDocument2
    Dim h
    Dim TempDoc As IHTMLDocument2
    Dim cgw As New CGetWindow
    Dim clw As New CListWindows
    clw.className = "Internet Explorer_Server"
    For Each h In clw.TopWindows
        If getParent(h) = 0 And cgw.IsStyle(styVISIBLE, ((h))) Then
            Set TempDoc = Web1.IEDOMFromhWnd((h))    ' There are IEServers inside Windows that won't return documents
            ' If InStr(className(hh), "Internet Explorer_TridentDlgFrame") > 0 And Cgw.IsStyle(styVISIBLE, ((hh))) And WindowText((hh)) <> "" Then
            If Not TempDoc Is Nothing Then
                Set GetPopupDoc = TempDoc
                Exit Function
            End If
        End If
    Next h
End Function

Sub SlowKey(textToKey As String, Optional verySlow As Boolean)
    Dim i As Long
    For i = 1 To Len(textToKey)
        If verySlow Then
            DoEvents_
        Else
            DoEvents
        End If
        Key Mid$(textToKey, i, 1)
    Next i
End Sub

' output a comma-delimited file
' to the given folder
'Sub WriteStockampWorkList(bReportPathAndFile As String)
'    Dim i As Integer
'    Dim bWriteHeader As Boolean
'    Dim fso As Object    ' late binding
'    Set fso = CreateObject("Scripting.FileSystemObject")    '
'
'    Dim myTextstream As Object
'    Const ForAppending = 8
'
'    Dim myRecord As String
'    Dim header As String
'    Dim reportFolder As String
'
'    On Error GoTo ErrorHandler
'
'    ' if Reports folder doesn't exist, create it
'    reportFolder = fso.GetParentFolderName(bReportPathAndFile)
'    If Not fso.FolderExists(reportFolder) Then
'        fso.CreateFolder reportFolder
'    End If
'
'    ' check if file exists
'    If Not fso.FileExists(bReportPathAndFile) Then
'        bWriteHeader = True
'    End If
'
'    If bWriteHeader Then
'        ' build header from Datastation header plus...
'        header = "Status" & vbTab & "StatusDetails" & vbTab & "ChangeDetails" & vbTab & "OtherDetails" & vbTab & "MachineName" & vbTab & "TimeToProcess" & vbTab & "ProcessedDateTime" & vbTab & "RecordStartTime" & vbTab & "RecordEndTime" & vbTab & "SourceFile" & vbTab & "Success or Failure" & vbTab & _
         '                 "XWALK_Department_Value" & vbTab & "XWALK_Visit_Type" & vbTab & "XWALK_Provider" & vbTab & _
         '                 "RecordID" & vbTab & "Create_datetime" & vbTab & "Appointment_DateTime" & vbTab & "Legacy_Account" & vbTab & "Lefacy_MRN" & vbTab & "Patient_Name" & vbTab & "Patient_SSN" & vbTab & "Patient_Sex" & vbTab & "Patient_DOB" & vbTab & "Refer_Doc_Name" & vbTab & "PCP" & vbTab & "Facility_Abbr" & vbTab & "Facility_Name" & vbTab & "Department_Abbr" & vbTab & "Department_Name" & vbTab & "Procedure_Abbr" & vbTab & "Visit_TypeProcedure_Name" & vbTab & "Actual_Procedure_Name" & vbTab & "Proc_Duration" & vbTab & "Diagnosis" & vbTab & "Resource_Abbr" & vbTab & "Resource_Name" & vbTab & "Resource_Type" & vbTab & "Practitioner_Name" & vbTab & "Patient_Type" & vbTab
'    End If
'
'    ' if report file doesn't exist, create it
'    ' and open it
'    Set myTextstream = fso.OpenTextFile(bReportPathAndFile, ForAppending, True)
'
'    If bWriteHeader Then
'        bWriteHeader = False
'        myTextstream.WriteLine header
'    End If
'
'    ' built record line
'    myRecord = rec.Status & vbTab
'    myRecord = myRecord & rec.StatusDetails & vbTab     ' use Chr(34) if want data enclosed in ""
'    myRecord = myRecord & rec.ChangeDetails & vbTab
'    myRecord = myRecord & rec.OtherDetails & vbTab
'    myRecord = myRecord & rec.MachineName & vbTab
'    myRecord = myRecord & rec.TimeToProcess & vbTab
'    myRecord = myRecord & rec.ProcessedDateTime & vbTab
'    myRecord = myRecord & rec.RecordStartTime & vbTab
'    myRecord = myRecord & rec.RecordEndTime & vbTab
'    myRecord = myRecord & rec.SourceFile & vbTab
'    myRecord = myRecord & rec.failed & vbTab
'    'xwalk data
'    myRecord = myRecord & rec.XDepart & vbTab
'    myRecord = myRecord & rec.XVisitType & vbTab
'    myRecord = myRecord & rec.XProvider & vbTab
'    'data from file
'
'    myRecord = myRecord & d(header_RecordID) & vbTab
'    myRecord = myRecord & d(header_Create_datetime) & vbTab
'    myRecord = myRecord & d(header_Appointment_DateTime) & vbTab
'    myRecord = myRecord & d(header_Legacy_Account) & vbTab
'    myRecord = myRecord & d(header_Lefacy_MRN) & vbTab
'    myRecord = myRecord & d(header_Patient_Name) & vbTab
'    myRecord = myRecord & d(header_Patient_SSN) & vbTab
'    myRecord = myRecord & d(header_Patient_Sex) & vbTab
'    myRecord = myRecord & d(header_Patient_DOB) & vbTab
'    myRecord = myRecord & d(header_Refer_Doc_Name) & vbTab
'    myRecord = myRecord & d(header_PCP) & vbTab
'    myRecord = myRecord & d(header_Facility_Abbr) & vbTab
'    myRecord = myRecord & d(header_Facility_Name) & vbTab
'    myRecord = myRecord & d(header_Department_Abbr) & vbTab
'    myRecord = myRecord & d(header_Department_Name) & vbTab
'    myRecord = myRecord & d(header_Procedure_Abbr) & vbTab
'    myRecord = myRecord & d(header_Visit_TypeProcedure_Name) & vbTab
'    myRecord = myRecord & d(header_Actual_Procedure_Name) & vbTab
'    myRecord = myRecord & d(header_Proc_Duration) & vbTab
'    myRecord = myRecord & d(header_Diagnosis) & vbTab
'    myRecord = myRecord & d(header_Resource_Abbr) & vbTab
'    myRecord = myRecord & d(header_Resource_Name) & vbTab
'    myRecord = myRecord & d(header_Resource_Type) & vbTab
'    myRecord = myRecord & d(header_Practitioner_Name) & vbTab
'    myRecord = myRecord & d(header_Patient_Type) & vbTab
'
'    myRecord = Left$(myRecord, Len(myRecord) - 1)
'
'    ' and write to activity report
'    myTextstream.WriteLine myRecord
'
'    myTextstream.Close
'
'    Exit Sub
'ErrorHandler:
'    ' if errSource does not equal BostonWorkStation70 or the Scriptname then we know this error was
'    ' bubbled up from somewhere else, so keep original exception info
'    If Err.Source <> "BostonWorkStation70" And Err.Source <> StrWord(Mid$(ScriptName, InStrRev(ScriptName, "\") + 1), 1, ".") Then
'        Err.Raise Err.Number, Err.Source, Err.Description
'    Else
'        Err.Raise Err.Number, "WriteStockampWorkList", Err.Description
'    End If
'End Sub
' output a comma-delimited file
' to the given folder
'Sub WriteRecordToScriptOutputReport(reportPathAndFile As String)
'    Dim i As Integer
'    Dim WriteHeader As Boolean
'    Dim fso As Object    ' late binding
'    Set fso = CreateObject("Scripting.FileSystemObject")    '
'
'    Dim myTextstream As Object
'    Const ForAppending = 8
'
'    Dim myRecord As String
'    Dim header As String, reportFolder As String
'
'    On Error GoTo ErrorHandler
'
'    ' if Reports folder doesn't exist, create it
'    reportFolder = fso.GetParentFolderName(reportPathAndFile)
'    If Not fso.FolderExists(reportFolder) Then
'        fso.CreateFolder reportFolder
'    End If
'
'    ' check if file exists
'    If Not fso.FileExists(reportPathAndFile) Then
'        WriteHeader = True
'    End If
'
'    If WriteHeader Then
'        ' build header from Datastation header plus...
'        header = "Status" & vbTab & "StatusDetails" & vbTab & "ChangeDetails" & vbTab & "OtherDetails" & vbTab & "MachineName" & vbTab & "TimeToProcess" & vbTab & "ProcessedDateTime" & vbTab & "RecordStartTime" & vbTab & "RecordEndTime" & vbTab & "SourceFile" & vbTab & "Success or Failure" & vbTab & _
         '                 "XWALK_Department_Value" & vbTab & "XWALK_Visit_Type" & vbTab & "XWALK_Provider" & vbTab & _
         '                 "RecordID" & vbTab & "Create_datetime" & vbTab & "Appointment_DateTime" & vbTab & "Legacy_Account" & vbTab & "Lefacy_MRN" & vbTab & "Patient_Name" & vbTab & "Patient_SSN" & vbTab & "Patient_Sex" & vbTab & "Patient_DOB" & vbTab & "Refer_Doc_Name" & vbTab & "PCP" & vbTab & "Facility_Abbr" & vbTab & "Facility_Name" & vbTab & "Department_Abbr" & vbTab & "Department_Name" & vbTab & "Procedure_Abbr" & vbTab & "Visit_TypeProcedure_Name" & vbTab & "Actual_Procedure_Name" & vbTab & "Proc_Duration" & vbTab & "Diagnosis" & vbTab & "Resource_Abbr" & vbTab & "Resource_Name" & vbTab & "Resource_Type" & vbTab & "Practitioner_Name" & vbTab & "Patient_Type" & vbTab
'    End If
'
'    ' if report file doesn't exist, create it
'    ' and open it
'    Set myTextstream = fso.OpenTextFile(reportPathAndFile, ForAppending, True)
'
'    If WriteHeader Then
'        WriteHeader = False
'        myTextstream.WriteLine header
'    End If
'
'    ' built record line
'    myRecord = rec.Status & vbTab
'    myRecord = myRecord & rec.StatusDetails & vbTab     ' use Chr(34) if want data enclosed in ""
'    myRecord = myRecord & rec.ChangeDetails & vbTab
'    myRecord = myRecord & rec.OtherDetails & vbTab
'    myRecord = myRecord & rec.MachineName & vbTab
'    myRecord = myRecord & rec.TimeToProcess & vbTab
'    myRecord = myRecord & rec.ProcessedDateTime & vbTab
'    myRecord = myRecord & rec.RecordStartTime & vbTab
'    myRecord = myRecord & rec.RecordEndTime & vbTab
'    myRecord = myRecord & rec.SourceFile & vbTab
'    myRecord = myRecord & rec.failed & vbTab
'    'xwalk data
'    myRecord = myRecord & rec.XDepart & vbTab
'    myRecord = myRecord & rec.XVisitType & vbTab
'    myRecord = myRecord & rec.XProvider & vbTab
'    'data from file
'
'    myRecord = myRecord & d(header_RecordID) & vbTab
'    myRecord = myRecord & d(header_Create_datetime) & vbTab
'    myRecord = myRecord & d(header_Appointment_DateTime) & vbTab
'    myRecord = myRecord & d(header_Legacy_Account) & vbTab
'    myRecord = myRecord & d(header_Lefacy_MRN) & vbTab
'    myRecord = myRecord & d(header_Patient_Name) & vbTab
'    myRecord = myRecord & d(header_Patient_SSN) & vbTab
'    myRecord = myRecord & d(header_Patient_Sex) & vbTab
'    myRecord = myRecord & d(header_Patient_DOB) & vbTab
'    myRecord = myRecord & d(header_Refer_Doc_Name) & vbTab
'    myRecord = myRecord & d(header_PCP) & vbTab
'    myRecord = myRecord & d(header_Facility_Abbr) & vbTab
'    myRecord = myRecord & d(header_Facility_Name) & vbTab
'    myRecord = myRecord & d(header_Department_Abbr) & vbTab
'    myRecord = myRecord & d(header_Department_Name) & vbTab
'    myRecord = myRecord & d(header_Procedure_Abbr) & vbTab
'    myRecord = myRecord & d(header_Visit_TypeProcedure_Name) & vbTab
'    myRecord = myRecord & d(header_Actual_Procedure_Name) & vbTab
'    myRecord = myRecord & d(header_Proc_Duration) & vbTab
'    myRecord = myRecord & d(header_Diagnosis) & vbTab
'    myRecord = myRecord & d(header_Resource_Abbr) & vbTab
'    myRecord = myRecord & d(header_Resource_Name) & vbTab
'    myRecord = myRecord & d(header_Resource_Type) & vbTab
'    myRecord = myRecord & d(header_Practitioner_Name) & vbTab
'    myRecord = myRecord & d(header_Patient_Type) & vbTab
'
'    myRecord = Left$(myRecord, Len(myRecord) - 1)
'
'    ' and write to activity report
'    myTextstream.WriteLine myRecord
'
'    myTextstream.Close
'
'    Exit Sub
'ErrorHandler:
'    ' if errSource does not equal BostonWorkStation70 or the Scriptname then we know this error was
'    ' bubbled up from somewhere else, so keep original exception info
'    If Err.Source <> "BostonWorkStation70" And Err.Source <> StrWord(Mid$(ScriptName, InStrRev(ScriptName, "\") + 1), 1, ".") Then
'        Err.Raise Err.Number, Err.Source, Err.Description
'    Else
'        Err.Raise Err.Number, "WriteRecordToScriptOutputReport", Err.Description
'    End If
'End Sub

Function WriteTableToaFile(sTableName As String, sFileName As String)
    Const currProc As String = "Modulename" & ".WriteTableToaFile"
    On Error GoTo ErrorHandler

    Dim elem As IHTMLElement
    Dim elemCol As IHTMLDOMChildrenCollection
    Dim elem2 As HTMLDocument
    Dim i As Integer
    Dim iCol As Integer
    Dim FilePath As String
    Dim onclickAttributeText As String
    Dim urlFilename As String
    Dim bWriteHeader As Boolean
    Dim fso As Object    ' late binding
    Set fso = CreateObject("Scripting.FileSystemObject")    '
    Dim myRecord As String
    Dim header As String
    Dim reportFolder As String
    Dim myTextstream As Object
    Const ForAppending = 8

    ' if Reports folder doesn't exist, create it
    reportFolder = fso.GetParentFolderName(sFileName)
    If Not fso.FolderExists(reportFolder) Then
        fso.CreateFolder reportFolder
    End If

    ' check if file exists
    If Not fso.FileExists(sFileName) Then
        bWriteHeader = True
    End If


    Set elem2 = Web1.IE.document
    Set elemCol = elem2.querySelectorAll("." & sTableName)

    ' expecting just one table
    Set elem = elemCol(0)

    If elem Is Nothing Then
        Exit Function
    ElseIf elem.Rows.length < 2 Then        'No files found
        Exit Function
    End If

    ' if file doesn't exist, create it
    ' and open it
    Set myTextstream = fso.OpenTextFile(sFileName, ForAppending, True)

    ' write header
    iCol = 0
    header = vbNullString
    If bWriteHeader Then
        ' build header
        For iCol = 0 To elem.Rows(0).cells.length - 1
            header = header & elem.Rows(0).cells(iCol).innerText & vbTab
        Next iCol
        ' write to file
        header = Left$(header, Len(header) - 1)
        myTextstream.WriteLine header
        bWriteHeader = False
    End If

    i = 0
    iCol = 0
    For i = 2 To elem.Rows.length - 1
        myRecord = vbNullString
        For iCol = 0 To elem.Rows(i).cells.length - 1
            myRecord = myRecord & elem.Rows(i).cells(iCol).innerText & vbTab
        Next iCol
        ' and write to file
        myRecord = Left$(myRecord, Len(myRecord) - 1)
        ' just write the i004/j014 for now TODO delete this later
        If InStr(1, myRecord, "I004") > 0 Or InStr(1, myRecord, "J014") > 0 _
         Or InStr(1, myRecord, "I010") > 0 Or InStr(1, myRecord, "J010") > 0 Or InStr(1, myRecord, "X022") > 0 Or InStr(1, myRecord, "K015") > 0 Or InStr(1, myRecord, "E008") > 0 _
         Or InStr(1, myRecord, "I001") > 0 Then
        ' TODO remove this later
        
           ' comment out the if block to return program to normal state
           'If InStr(1, myRecord, "") > 0 _
            'Or InStr(1, myRecord, "") > 0 Then
'            'Stop ' TODO remove this before prod rollout
            myTextstream.WriteLine myRecord
           'End If 'comment line back out in order to run all possible accounts
        End If
    Next i

    myTextstream.Close

    Exit Function
ErrorHandler:
End Function

Public Function GetNextSourceFile(sInputDir As String) As String
'---------------------------------------------------------------------------------------
' Procedure     : GetNextSourceFile
' Author/Editor : Boston Software Systems, Inc. ldh
' Date          : 2016-01-07
' Purpose       : Prepares and opens a data file from the input folder
' Parameters    : None
' Returns       : None
'---------------------------------------------------------------------------------------
    On Error GoTo ErrorHandler: Const procName = "GetNextSourceFile"

    'If there is a file already open
    If d.IsOpen Then

        'Close it
        d.Close_

    End If

    'Clear the Data Columns array
    Erase DatastationColumns

    'Set the active input file
    goConfig.InputFileName = Dir$(sInputDir & "*.tab")

    'Set the active output file
    goConfig.outputFileName = GetOutputFileName

    'Return the open file path
    GetNextSourceFile = goConfig.InputFileName

ExitFunction:
    Exit Function

ErrorHandler:
    If DebugMode Then
        Debug.Print "Error in " & msModulename & "." & procName & ":" & Err.Number & ":" & Err.Description
        Stop
        Resume
    End If
    GeneralErrorHandler Err.Number, Err.Description, Err.Source, msModulename & "." & procName
End Function

Private Function GetOutputFileName() As String

    Dim fso As New FileSystemObject

    'If there is already an Output file present for this file
    If Dir$(goConfig.ReportsFolder & "Output_" & goConfig.InputFileName & ".tab") <> "" Then

        'Use the existing file
        'GetOutputFileName = Dir$(goConfig.ReportsFolder & "Output_" & goConfig.InputFileName & ".tab")
        GetOutputFileName = Dir$(goConfig.ReportsFolder & goConfig.InputFileName & ".tab")

    Else

        'Create a new file
        'GetOutputFileName = "Output_" & fso.GetBaseName(goConfig.InputFileName) & ".tab"   '& "_" & Format(Date, "yyyy-mm-dd") & ".tab"
        'TODO check this later
        GetOutputFileName = fso.GetBaseName(goConfig.InputFileName) & ".tab"   '& "_" & Format(Date, "yyyy-mm-dd") & ".tab"
        ' fso.CreateTextFile goConfig.ReportsFolder & GetOutputFileName todo delete later
    End If

End Function

Function RemoveAlpha(r As String) As String
    With CreateObject("vbscript.regexp")
        .Pattern = "[A-Za-z]"
        .Global = True
        RemoveAlpha = .Replace(r, "")
    End With
End Function

Function RemoveSpecial(r As String) As String
    With CreateObject("vbscript.regexp")
        .Pattern = "[}{.,/\':;><?!@#$%^&*)(]"
        .Global = True
        RemoveSpecial = .Replace(r, "")
    End With
End Function


Function ClickTheComboBoxQuerySelector(sName As String, sSearchFor As String, sSourceVal As String, sWebFieldName As String, bRequired As Boolean, sFireEvent As String, Optional bClickOnit As Boolean) As Boolean

    Dim nControlStatusInd As Integer

    ClickTheComboBoxQuerySelector = False

    nControlStatusInd = ClickTheComboBoxQrySelector(sName, sSearchFor, sSourceVal, sWebFieldName, bRequired, sFireEvent, bClickOnit)

    Select Case nControlStatusInd
    Case eCONTROL_VALID
        ClickTheComboBoxQuerySelector = True
        Exit Function
    Case eCONTROL_NOT_VALID
        Exit Function
    Case eCONTROL_CONTROL_NOT_FOUND
        LogMessage "ERROR: " & sWebFieldName & " passed in is - " & sSourceVal & " but web field " & sWebFieldName & " is not found"
        Exit Function
    Case eCONTROL_ITEM_NOT_FOUND
        LogMessage "ERROR: " & sWebFieldName & " passed in is - " & sSourceVal & " but it was not found in the available " & sWebFieldName
        Exit Function
    End Select

    ClickTheComboBoxQuerySelector = True
End Function

Function TextPatterMatches(sString As String) As Boolean
    With CreateObject("vbscript.regexp")
        .Pattern = "[A-Za-z]"
        .Global = True
        If .test(sString) Then
            TextPatterMatches = True
        Else
            TextPatterMatches = False
        End If
    End With
End Function

Function NumberPatterMatches(sString As String) As Boolean
    With CreateObject("vbscript.regexp")
        .Pattern = "[0-9]"
        .Global = True
        If .test(sString) Then
            NumberPatterMatches = True
        Else
            NumberPatterMatches = False
        End If
    End With
End Function

Function CountChar(ByVal text As String, ByVal Char As String) As Long
    Dim V As Variant
    V = Split(text, Char)
    CountChar = UBound(V)
End Function

Function AllSameChars(sText As String) As Boolean
    AllSameChars = False
    If CountChar(sText, Mid(sText, 1, 1)) = Len(sText) Then
        AllSameChars = True
    End If
End Function

Sub DebugPrintAllWebElements()
    Web1.IE.document.title

End Sub

' move files
Sub MoveFiles(inputFileFolder As String, outputFileFolder As String)

    Dim fldr
    Dim fso As Object
    Dim sFile As Variant

    On Error GoTo ErrorHandler

    Set fso = New FileSystemObject
    Set fldr = fso.GetFolder(inputFileFolder)

    ' add all files to a dict
    For Each sFile In fldr.Files
        fso.CopyFile sFile, outputFileFolder
        fso.DeleteFile sFile
    Next

    Exit Sub
ErrorHandler:
    Debug.Print "ERROR: " & Err.Number & ":" & Err.Description
End Sub

Function ReformatAddress(sAddress As String) As String
'o AVE = AVENUE
'o BLVD = BOULEVARD
'o CTR = CENTER
'o CIR = CIRCLE
'o CT = COURT
'o DR = Drive
'o LN = LANE
'o PL = PLACE
'o RD = ROAD
'o SQ = SQUARE
'o ST = STREET
'o TER = TERRACE
'o WAY = WAY
    sAddress = UCase(sAddress)
    sAddress = Replace(sAddress, "AVENUE", "AVE")
    sAddress = Replace(sAddress, "BOULEVARD", "BLVD")
    sAddress = Replace(sAddress, "CENTER", "CTR")
    sAddress = Replace(sAddress, "CIRCLE", "CIR")
    sAddress = Replace(sAddress, "COURT", "CT")
    sAddress = Replace(sAddress, "DRIVE", "DR")
    sAddress = Replace(sAddress, "LANE", "LN")
    sAddress = Replace(sAddress, "PLACE", "PL")
    sAddress = Replace(sAddress, "ROAD", "RD")
    sAddress = Replace(sAddress, "SQUARE", "SQ")
    sAddress = Replace(sAddress, "STREET", "ST")
    sAddress = Replace(sAddress, "TERRACE", "TER")
    sAddress = Replace(sAddress, "WAY", "WAY")
    sAddress = Replace(sAddress, "-", "")
    sAddress = Replace(sAddress, " ", "")
    ReformatAddress = Mid(sAddress, 1, 4)
End Function

Sub SendFatalError3(oConfig As cConfig, Optional DetailText As String)
    Dim sRetString As String

    On Error GoTo ErrorHandler

    sRetString = SendEmail2(oConfig.StatusNotifyEmailID, "FATAL ERROR " & oConfig.ProjectName, "The " & oConfig.ProjectName & " automation has encountered a fatal error." & _
                                                                                               vbCrLf & _
                                                                                               DetailText & _
                                                                                               vbCrLf & _
                                                                                               "MachineName: " & oConfig.MachineName, oConfig.EmailServer, oConfig.EMailUserID, oConfig.EMailPassword)

    Logging "FATAL ERROR: The " & oConfig.ProjectName & " automation has encountered a fatal error." & _
            vbCrLf & _
            DetailText & _
            vbCrLf & _
            "An attempt was made to send an email notification with return status of: " & sRetString

    ' close Ineternet Explorer
    ' close Ineternet Explorer
    ' kill IE
    Shell (Environ("Windir") & "\SYSTEM32\TASKKILL.EXE /F /IM IEXPLORE.EXE")
    Wait 5

    Shutdown = True    ' fatal error, stop the script
    Exit Sub
ErrorHandler:
    ' we dont need to do anything
    Logging "ERROR: MODULE: Utils SUB: SendFatalError3: " & Err.Number & ":" & Err.Description
End Sub

Function StartHeartbeatMonitor()
' Monitor for a heartbeat from your automation
' bwsHEARTBEAT.EXE
' Intended to be used to monitor a logfile that your automation is writing to
' If no changes to the logfile within the given time period, then there's no heartbeat, run
'     batch file that will shutdown everything & restart.
' Requires 3 command-line arguments:
'    E.g.:
'          -fC:\LogFileToMonitor.txt
'          -t240 (time in seconds to trigger restart if no heartbeat)
'          -b"C:\My Folder\ResetBatchFile.bat" (batch file that kills & restarts monitored automation)
'
' Requires that BWS be running when launched, otherwise it thinks there is no automation to monitor, so
'    it exits.    '     e.g. OUTLOOK has itself & BWS locked down because of timing out
    Dim tempArgs As String

    On Error GoTo ErrorHandler
    Shell Environ("WINDIR") & "\SYSTEM32\TASKKILL.EXE /F /IM BWSHEARTBEAT.exe"
    Wait 10
    Do Until IsProcessRunning("BWSHeartbeat.exe") = False
        Wait 1
        DoEvents
    Loop

    LogThis "Starting Heartbeat Monitor..."
    tempArgs = "c:\bss70\BWSheartbeat.exe -t" & HeartbeatTimeoutPeriod & " -f" & Chr(34) & goConfig.LogFolderPath & goConfig.LogFileName & Chr(34) & " -b" & Chr(34) & HeartbeatBatchFile & Chr(34)
    Shell tempArgs, vbNormalFocus
    Exit Function
ErrorHandler:
    LogThis "ERROR: StartHeartbeatMonitor:" & Err.Number & ":" & Err.Description
End Function
Function StopHeartbeatMonitor()
    LogThis "Stopping Heartbeat Monitor..."
    Shell Environ("WINDIR") & "\SYSTEM32\TASKKILL.EXE /F /IM BWSHEARTBEAT.exe"
End Function

Public Function IsProcessRunning(processName As String) As Boolean
    Dim objWMI
    Dim objServices
    Dim objservice
    Set objWMI = GetObject("winmgmts:")
    Set objServices = objWMI.InstancesOf("win32_process")
    For Each objservice In objServices
        If UCase(objservice.name) = UCase(processName) Then
            IsProcessRunning = True
            Exit Function
        End If
    Next
End Function

Public Function GetTheLine(sText As String, nLineNumber As Integer)
    On Error GoTo ErrorHandler
    Dim TextArray() As String
    TextArray = Split(sText, vbNewLine)
    GetTheLine = TextArray(2)

    Exit Function
ErrorHandler:
    GetTheLine = "ERROR"
End Function
