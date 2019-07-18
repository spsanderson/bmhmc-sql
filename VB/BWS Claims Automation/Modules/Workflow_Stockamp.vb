Option Explicit

Private lStartTime As Long
Const msModule As String = "Workflow_Stockamp"

Function CheckAnyLeftOverFiles() As Boolean
' check for any left over files check, move the files that are currently being processed to error ( BrookHaven\Results\ErroredFiles ) folder for manual review and process rest of the files.

    Dim sInputDir As String
    Dim sInputFileName As String

    ' check root(processdir) folder for .bdf files
    
    sInputFileName = Dir$(goConfig.ProcessDir & "*.bds")
    If Len(sInputFileName) > 0 Then
        FileCopy goConfig.ProcessDir & sInputFileName, goConfig.ReportsFolder & "ErroredFiles\" & sInputFileName
        KillFile goConfig.ProcessDir & sInputFileName
        Wait 2
        sInputFileName = Left(sInputFileName, Len(sInputFileName) - 4)
        FileCopy goConfig.ProcessDir & sInputFileName, goConfig.ReportsFolder & "ErroredFiles\" & sInputFileName
        KillFile goConfig.ProcessDir & sInputFileName
        Wait 2
    End If

    ' check root(processdir) folder for .tab files
    sInputFileName = Dir$(goConfig.ProcessDir & "*.tab")
    If Len(sInputFileName) > 0 Then
        CheckAnyLeftOverFiles = True
    End If

    ' check stockamp folder for .bdf files
    sInputFileName = Dir$(goConfig.ProcessDir & "Stockamp\" & "*.bds")
    If Len(sInputFileName) > 0 Then
        FileCopy goConfig.ProcessDir & "Stockamp\" & sInputFileName, goConfig.ReportsFolder & "ErroredFiles\" & sInputFileName
        KillFile goConfig.ProcessDir & "Stockamp\" & sInputFileName
        Wait 2
        sInputFileName = Left(sInputFileName, Len(sInputFileName) - 4)
        FileCopy goConfig.ProcessDir & "Stockamp\" & sInputFileName, goConfig.ReportsFolder & "ErroredFiles\" & sInputFileName
        KillFile goConfig.ProcessDir & "Stockamp\" & sInputFileName
        Wait 2
    End If

    ' check stockamp folder for .tab files
    sInputFileName = Dir$(goConfig.ProcessDir & "Stockamp\" & "*.tab")
    If Len(sInputFileName) > 0 Then
        CheckAnyLeftOverFiles = True
    End If

    ' check AffinityMedicaid folder for .bdf files
    sInputFileName = Dir$(goConfig.ProcessDir & "AffinityMedicaid\" & "*.bds")
    If Len(sInputFileName) > 0 Then
        FileCopy goConfig.ProcessDir & "AffinityMedicaid\" & sInputFileName, goConfig.ReportsFolder & "ErroredFiles\" & sInputFileName
        KillFile goConfig.ProcessDir & "AffinityMedicaid\" & sInputFileName
        Wait 2
        sInputFileName = Left(sInputFileName, Len(sInputFileName) - 4)
        FileCopy goConfig.ProcessDir & "AffinityMedicaid\" & sInputFileName, goConfig.ReportsFolder & "ErroredFiles\" & sInputFileName
        KillFile goConfig.ProcessDir & "AffinityMedicaid\" & sInputFileName
        Wait 2
    End If

    ' check AffinityMedicaid folder for .tab files
    sInputFileName = Dir$(goConfig.ProcessDir & "AffinityMedicaid\" & "*.tab")
    If Len(sInputFileName) > 0 Then
        CheckAnyLeftOverFiles = True
    End If

    ' check HealthFirst folder for .bdf files
    sInputFileName = Dir$(goConfig.ProcessDir & "HealthFirst\" & "*.bds")
    If Len(sInputFileName) > 0 Then
        FileCopy goConfig.ProcessDir & "HealthFirst\" & sInputFileName, goConfig.ReportsFolder & "ErroredFiles\" & sInputFileName
        KillFile goConfig.ProcessDir & "HealthFirst\" & sInputFileName
        Wait 2
        sInputFileName = Left(sInputFileName, Len(sInputFileName) - 4)
        FileCopy goConfig.ProcessDir & "HealthFirst\" & sInputFileName, goConfig.ReportsFolder & "ErroredFiles\" & sInputFileName
        KillFile goConfig.ProcessDir & "HealthFirst\" & sInputFileName
        Wait 2
    End If

    ' check HealthFirst folder for .tab files
    sInputFileName = Dir$(goConfig.ProcessDir & "HealthFirst\" & "*.tab")
    If Len(sInputFileName) > 0 Then
        CheckAnyLeftOverFiles = True
    End If

    ' check OPTUM folder for .bdf files
    sInputFileName = Dir$(goConfig.ProcessDir & "OPTUM\" & "*.bds")
    If Len(sInputFileName) > 0 Then
        FileCopy goConfig.ProcessDir & "OPTUM\" & sInputFileName, goConfig.ReportsFolder & "ErroredFiles\" & sInputFileName
        KillFile goConfig.ProcessDir & "OPTUM\" & sInputFileName
        Wait 2
        sInputFileName = Left(sInputFileName, Len(sInputFileName) - 4)
        FileCopy goConfig.ProcessDir & "OPTUM\" & sInputFileName, goConfig.ReportsFolder & "ErroredFiles\" & sInputFileName
        KillFile goConfig.ProcessDir & "OPTUM\" & sInputFileName
        Wait 2
    End If

    ' check OPTUM folder for .tab files
    sInputFileName = Dir$(goConfig.ProcessDir & "OPTUM\" & "*.tab")
    If Len(sInputFileName) > 0 Then
        CheckAnyLeftOverFiles = True
    End If

    ' check SMS folder for .bdf files
    sInputFileName = Dir$(goConfig.ProcessDir & "SMS\" & "*.bds")
    If Len(sInputFileName) > 0 Then
        FileCopy goConfig.ProcessDir & "SMS\" & sInputFileName, goConfig.ReportsFolder & "ErroredFiles\" & sInputFileName
        KillFile goConfig.ProcessDir & "SMS\" & sInputFileName
        Wait 2
        sInputFileName = Left(sInputFileName, Len(sInputFileName) - 4)
        FileCopy goConfig.ProcessDir & "SMS\" & sInputFileName, goConfig.ReportsFolder & "ErroredFiles\" & sInputFileName
        KillFile goConfig.ProcessDir & "SMS\" & sInputFileName
        Wait 2
    End If

    ' check SMS folder for .tab files
    sInputFileName = Dir$(goConfig.ProcessDir & "SMS\" & "*.tab")
    If Len(sInputFileName) > 0 Then
        CheckAnyLeftOverFiles = True
    End If

    If Not CheckAnyLeftOverFiles Then
        MoveFiles goConfig.ReportsFolder, goConfig.ReportsFolder & "archive\"
    End If
End Function

Sub CheckAppsSuccessfulLogin()
' todo add other applications here
    StockampLoginCheck
    SMSNetLoginCheck
    'HealthFirstLoginCheck
    OPTUMLoginCheck
    'AffinityMedicaidLoginCheck
End Sub

Sub Login_IE_Stockamp(sWebSiteName As String)
    On Error GoTo ErrorHandler: Const procName = "Login_IE_Stockamp"
    Dim nConnectRetry As Integer
    ' moves to the top of the document
    First

    ' login screen
    If Not Web1.Find("Login Name") Then
        GoTo ErrorHandler
    End If

    ' input Login UserID
    text("<INPUT>#txtLoginName#@Login - Stockamp & Associates") = goConfig.LoginUserID

    ' input Login Password
    text("txtPassword<INPUT>#txtPassword#@Login - Stockamp & Associates") = goConfig.LoginPassword

    ' click on login Submit button
    Pause "submit1<INPUT>#submit1#<#bttn_sized#>@Login - Stockamp & Associates"
    Click "submit1<INPUT>#submit1#<#bttn_sized#>@Login - Stockamp & Associates"
    WaitForPage
    WaitForPage

    ' click Claims
    Pause "STAT<A><#R_HL#>@Welcome - Stockamp & Associates QUIC - TRAC"
    Click "STAT<A><#R_HL#>@Welcome - Stockamp & Associates QUIC - TRAC"
    WaitForPage
    WaitForPage
    Exit Sub
ErrorHandler:
    Err.Raise Err.Number, msModule & ": Workflow Sub: " & procName, Err.Description
End Sub

Sub Logout_IE_Stockamp(Optional bDummy As Boolean)
    On Error GoTo ErrorHandler: Const procName = "Logout_IE_Stockamp"

    First

    LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " before closing the IE"
    Pause "Log Off System"
    Web1.selected.Click

    WaitForPage

    ' close Ineternet Explorer
    Web1.WB.quit

    ' kill ie session
    Shell (Environ("Windir") & "\SYSTEM32\TASKKILL.EXE /F /IM IEXPLORE.EXE")
    Wait 5

    LogMessage "MODULE:" & msModule & " Workflow SUB: " & procName & ":" & " after closing the IE"

    Exit Sub

ErrorHandler:
    Logging "ERROR: MODULE:" & msModule & " Workflow Sub: " & procName & ": " & Err.Number & ":" & Err.Description
    GeneralErrorHandler Err.Number, Err.Description, Err.Source, msModule & "." & procName
End Sub

Sub StockampLoginCheck()
    On Error GoTo ErrorHandler: Const procName = "StockampLoginCheck"

    Dim sFileName As String

    ' ReadSetupFile set up file load configuration object with Login URL, Login Username, Login Password etc.,
    If Not ReadSetupFile Then
        ' exit out
        Exit Sub
    End If
    LogMessage "MODULE: " & msModule & " SUB: " & procName & " after call to sub ReadSetupFile "

    LogMessage "MODULE: " & msModule & " SUB: " & procName & " before the call to LanuchAndConnect_IE "
    LaunchAndConnect_IE goConfig
    LogMessage "MODULE: " & msModule & " SUB: " & procName & " after the call to LanuchAndConnect_IE "
    Login_IE_Stockamp goConfig.WebSiteName

    ' logout & exit
    'Logout_IE_Stockamp

    Exit Sub
ErrorHandler:
    sFileName = TakeScreenshot2(goConfig.LogFolderPath)
    Logging "ERROR: Pls see screenshot - " & sFileName
    If InStr(Err.Source, "_IE") > 0 Then
        SendFatalError2 goConfig, Err.Source & ":" & Err.Number & ":" & Err.Description & " - Maximum # of IE restarts reached."
    Else
        SendFatalError2 goConfig, Err.Source & ":" & Err.Number & ":" & Err.Description & " - " & Status & " - UNHANDLED ERROR."
    End If
End Sub

Sub ReadSetupAndInitialize()
    On Error GoTo ErrorHandler: Const procName = "ReadSetupAndInitialize"

    Dim sFileName As String
    Dim nIERestarts As Integer

    ' ReadSetupFile set up file load configuration object with Login URL, Login Username, Login Password etc.,
    If Not ReadSetupFile Then
        ' exit out
        Exit Sub
    End If
    
    HeartbeatBatchFile = goConfig.ProcessDir & "HeartBeat\HeartbeatBatchFile.bat"

    ' prep the automation.
    KillAnyAppsOpen

    SendStatusEmail2 goConfig, "Brookhaven Automation started."

    ' delete log/error/archive files - keeps files for a specified number of days in the configuraton file.
    CleanHouse goConfig.LogFolderPath, goConfig.ProcessDir, goConfig.DeleteLogsAfterDays

    LogMessage "MODULE: " & msModule & " SUB: " & procName & " after call to sub CleanHouse "

    Exit Sub

ErrorHandler:
    sFileName = TakeScreenshot2(goConfig.LogFolderPath)
    Logging "ERROR: Pls see screenshot - " & sFileName
    SendFatalError2 goConfig, Err.Source & ":" & Err.Number & ":" & Err.Description & " - " & Status & " could not read setup file."
End Sub


Sub StockampCreateWorkList()
    On Error GoTo ErrorHandler: Const procName = "StockampCreateWorkList"

    Dim sFileName As String
    Dim nIERestarts As Integer

RestartIE:

    LogMessage "MODULE: " & msModule & " SUB: " & procName & " before the call to LanuchAndConnect_IE "
    gnConnectRetry = 0
    LaunchAndConnect_IE goConfig
    LogMessage "MODULE: " & msModule & " SUB: " & procName & " after the call to LanuchAndConnect_IE "
    Login_IE_Stockamp goConfig.WebSiteName
    LogMessage "MODULE: " & msModule & " SUB: " & procName & " before the call to ProcessData "

    ' create worklists
    If Not ExportWorkList Then
        ' if there is no data to process... log and exit
        ' send email notification that there are no accounts/worklists to process
        SendSuccessEMail "There are no accounts/worklists to process."
        ' logout & exit
        Logout_IE_Stockamp
        Shutdown = True
    End If

    Logout_IE_Stockamp
    Exit Sub

ErrorHandler:
    sFileName = TakeScreenshot2(goConfig.LogFolderPath)
    Logging "ERROR: Pls see screenshot - " & sFileName
    If InStr(Err.Source, "_IE") > 0 And nIERestarts < goConfig.MaxIERestarts Then
        ' kill IE
        Shell (Environ("Windir") & "\SYSTEM32\TASKKILL.EXE /F /IM IEXPLORE.EXE")
        Wait 5
        nIERestarts = nIERestarts + 1
        Logging "Restarting IE..."
        Resume RestartIE
    ElseIf InStr(Err.Source, "_IE") > 0 And nIERestarts >= goConfig.MaxIERestarts Then
        SendFatalError2 goConfig, Err.Source & ":" & Err.Number & ":" & Err.Description & " - Maximum # of IE restarts reached."
    ElseIf Err.Number = -2147024726 Then    ' Automation error The requested resource is in use.
        Wait 2
        Resume
    Else
        SendFatalError2 goConfig, Err.Source & ":" & Err.Number & ":" & Err.Description & " - " & Status & " - UNHANDLED ERROR."
    End If
End Sub

Sub StockampReadData()
    On Error GoTo ErrorHandler: Const procName = "StockampReadData"

    Dim sFileName As String
    Dim nIERestarts As Integer

RestartIE:

    LogMessage "MODULE: " & msModule & " SUB: " & procName & " before the call to LanuchAndConnect_IE "
    gnConnectRetry = 0
    LaunchAndConnect_IE goConfig
    LogMessage "MODULE: " & msModule & " SUB: " & procName & " after the call to LanuchAndConnect_IE "
    Login_IE_Stockamp goConfig.WebSiteName
    LogMessage "MODULE: " & msModule & " SUB: " & procName & " before the call to ProcessData "

    GetStockampDemographics
    Exit Sub

ErrorHandler:
    sFileName = TakeScreenshot2(goConfig.LogFolderPath)
    Logging "ERROR: Pls see screenshot - " & sFileName
    If InStr(Err.Source, "_IE") > 0 And nIERestarts < goConfig.MaxIERestarts Then
        ' kill IE
        Shell (Environ("Windir") & "\SYSTEM32\TASKKILL.EXE /F /IM IEXPLORE.EXE")
        Wait 5
        nIERestarts = nIERestarts + 1
        Logging "Restarting IE..."
        Resume RestartIE
    ElseIf InStr(Err.Source, "_IE") > 0 And nIERestarts >= goConfig.MaxIERestarts Then
        SendFatalError2 goConfig, Err.Source & ":" & Err.Number & ":" & Err.Description & " - Maximum # of IE restarts reached."
    ElseIf Err.Number = -2147024726 Then    ' Automation error The requested resource is in use.
        Wait 2
        Resume
    Else
        SendFatalError2 goConfig, Err.Source & ":" & Err.Number & ":" & Err.Description & " - " & Status & " - UNHANDLED ERROR."
    End If
End Sub


Function ExportWorkList() As Boolean
    Dim elem As IHTMLElement
    Dim oDoc As HTMLDocument
    Dim iPageNum As Integer
    Dim sWorkListNumber As String
    Dim oHTMLElement As IHTMLElement2
    Dim iSub As Integer
    Dim sControlType As String
    Dim sSourceVal As String
    Dim oChildrenCollection As IHTMLDOMChildrenCollection
    Dim iTotalPages As Integer
    Dim oElement As IHTMLElement
    Dim sFileName As String
    Dim oWorkLists As New cWorkLists
    Dim oWorkList As cWorkList
    Dim iSub2 As Integer
    Dim bAtLeastOneWorkListPresent As Boolean

    On Error GoTo ErrorHandler: Const procName = "ExportWorkList"

    ' assigned worklists
    oWorkLists.Load

    If oWorkLists Is Nothing Then
        ExportWorkList = False
        GoTo ErrorHandler
    End If

    For iSub2 = 1 To oWorkLists.Count
        Set oWorkList = oWorkLists.Item(iSub2)
        sWorkListNumber = oWorkList.WorkListNumber
        ExportWorkList = False
        If Not ClickTheComboBoxQuerySelector("cboOtherWorkList", "" & sWorkListNumber & " - ", sWorkListNumber, "WorkList ID", True, "onChange") Then
            LogMessage "MODULE: " & msModule & " Sub: " & procName & ":" & " end"
            GoTo NextWorkList
        End If

        Set oDoc = Web1.IE.document

        WaitForPage
        ' sort the data by insureance carrier
        Click "Carrier Code<A><#W_HL_8#>@Viewing Worklist Accounts - Stockamp & Associates - eSTAT - TRAC"

        ' check if there are any accounts
        WaitForPage
        Set oChildrenCollection = oDoc.querySelectorAll(".TESTPAGING")
        iTotalPages = oChildrenCollection.length / 2
        First
        If iTotalPages = 0 Then
            If Web1.Find("No Accounts...") Then
                LogMessage "MODULE: " & msModule & " Sub: " & procName & "No Accounts"
                GoTo NextWorkList
            Else
                ' create worklist for 1 page
                If Not bAtLeastOneWorkListPresent Then
                    bAtLeastOneWorkListPresent = True
                End If
                WriteTableToaFile "WLAccounts", goConfig.ProcessDir & sWorkListNumber & "_" & iSub & "_" & goConfig.ProcessDtTm & ".tab"
                GoTo NextWorkList
            End If
        End If

        If iTotalPages = 1 Then
            LogMessage "MODULE: " & msModule & " Sub: " & procName & "No Accounts"
            GoTo NextWorkList
        Else
            ' create worklist for 1 page
            WriteTableToaFile "WLAccounts", goConfig.ProcessDir & sWorkListNumber & "_1" & "_" & goConfig.ProcessDtTm & ".tab"
            ' collection
            Set oChildrenCollection = oDoc.querySelectorAll(".TESTPAGING")
            For iSub = 2 To iTotalPages
                Set oElement = GetElementByTagName("A", CStr(iSub))
                If Not oElement Is Nothing Then
                    oElement.Click
                    WaitForPage
                    If Not bAtLeastOneWorkListPresent Then
                        bAtLeastOneWorkListPresent = True
                    End If
                    WriteTableToaFile "WLAccounts", goConfig.ProcessDir & sWorkListNumber & "_" & iSub & "_" & goConfig.ProcessDtTm & ".tab"
                End If
                'Exit For    ' todo delete later
            Next iSub
        End If
NextWorkList:
    Next iSub2
    ExportWorkList = bAtLeastOneWorkListPresent
    Exit Function
ErrorHandler:
    ExportWorkList = False
End Function

Sub GetStockampDemographics()
    On Error GoTo ErrorHandler: Const procName = "GetStockampDemographics"
    'Loop until no more source files are found
    Do Until GetNextSourceFile(goConfig.ProcessDir) = ""

        'Open the file with BWS Datastation
        d.Open_ goConfig.ProcessDir & goConfig.InputFileName, ftDelimited, goConfig.ProcessDir & "InputFileConfig\InputFileConfig.bds"

        'Process records according to the workflow
        ProcessAllRecordsStockampRead

        'Close and archive the file
        d.Archive
        Wait 1
        'Exit Do    ' todo delete later
    Loop
    Logout_IE_Stockamp
    Exit Sub
ErrorHandler:
    GeneralErrorHandler Err.Number, Err.Description, Err.Source, msModule & "." & procName
End Sub

Public Sub ProcessAllRecordsStockampRead()
    On Error GoTo ErrorHandler: Const procName = "ProcessAllRecordsStockampRead"

    Dim sPersonName As String
    Dim sBirthDate As String
    Dim sFirstName As String
    Dim sLastName As String
    Dim sStatus As String
    Dim sStatusDetail As String
    Dim elem As IHTMLElement
    Dim elemCol As IHTMLDOMChildrenCollection
    Dim elem2 As HTMLDocument


    'Loop through each record
    Do Until d.EOF_
        'Instantiates object and sets Datastation Columns array for Output file
        Set oDataStockamp = New cDataStockamp
        StartProcessingTime = Now
        
        Logging "Reading account information from Stockamp for the account " & d("Account Number")
        
        'If the record should be processed
        If d("Status") = "" And Len(d("Account Number")) > 0 Then
            'If the record is valid
            If oDataStockamp.IsValid Then

                First
                ' click on stat
                Pause "Search Accounts"
                Web1.selected.Click
                WaitForPage

                ' search for accounts
                ' plug in the account number and get the demographic information
                text("<INPUT>#txtAccountNumber#@Search Accounts - Stockamp & Associates - eSTAT - TRAC") = d("Account Number")

                ' click search
                Click "submit1<INPUT>#submit1#<#bttn#>@Search Accounts - Stockamp & Associates - eSTAT - TRAC"
                WaitForPage

                ' click on the account number link
                Click d("Account Number") & "<A><#B_HL_8#>@Viewing Account Search Results - Stockamp & Associates - eSTAT - TRAC"
                WaitForPage

                ' date of birth
                Pause "Date of Birth:<SPAN><#REGTEXT#>@Viewing Account Detail - Stockamp & Associates - eSTAT - TRAC"
                Set selected = NextElement(selected)
                sBirthDate = Web1.selected.innerText
                d("SK_Patient_Birth_Date") = sBirthDate

                If Len(sBirthDate) > 0 Then
                    ' keep going
                Else
                    sStatus = Status_REVIEW
                    sStatusDetail = "Stockamp date of birth is blank/null"
                    GoTo NextRow
                End If

                ' name fields
                sPersonName = d("Patient Name")
                If Len(sPersonName) > 0 Then
                    sLastName = UCase(StrWord(sPersonName, 1, ","))
                    sFirstName = UCase(StrWord(sPersonName, 2, ","))
                    d("SK_Patient_Last_name") = sLastName
                    d("SK_Patient_First_name") = sFirstName
                End If

                If sFirstName = vbNullString Or sLastName = vbNullString Then
                    sStatus = Status_REVIEW
                    sStatusDetail = "Stockamp first name, last name cannot be blank/null"
                    GoTo NextRow
                End If

                ' STAT account information. Process accounts that has only one row with activity code of INIT and worked by of SYS-System Rep
                Set elem2 = Web1.IE.document
                Pause "Activity CodeDescriptionActivi*<TABLE>@Viewing Account Detail - Stockamp & Associates - eSTAT - TRAC"

                ' Set elemCol = selected
                Set elem = selected
                'Set elemCol = elem2.querySelectorAll("." & "STAT")

                ' expecting just one table
                'Set elem = elemCol(0)

                If elem Is Nothing Then
                    sStatus = Status_REVIEW
                    sStatusDetail = "No STAT account information. Could not find activity code of INIT and worked by of SYS-System Rep"
                    GoTo NextRow
                ElseIf elem.Rows.length > 3 Then        ' more than two rows found
                    sStatus = Status_REVIEW
                    sStatusDetail = "STAT account information has rows other than activity code of INIT and worked by of SYS-System Rep"
                    GoTo NextRow
                End If

                If elem.Rows(0).cells(0).innerText = "Activity Code" And elem.Rows(1).cells(0).innerText = "INIT" And elem.Rows(0).cells(5).innerText = "Worked by" And elem.Rows(1).cells(5).innerText = "SYS - System Rep" Then
                    ' good proceed
                    ' if the insurance carrier is "J010" and Activity Date is 21 days older proceed
                    If d("Carrier Code") = "J010" Then
                        ' check activity date
                        If elem.Rows(0).cells(0).innerText = "Activity Date" And DateDiff("d", elem.Rows(1).cells(2).innerText, Now) > 21 Then
                            ' proceed
                        Else
                            sStatus = Status_REVIEW
                            sStatusDetail = "Insurance carrier is J010 and Activity date is " & elem.Rows(1).cells(0).innerText & " is not older than 21 days"
                            GoTo NextRow
                        End If
                    Else
                        ' keep going
                    End If
                Else
                    sStatus = Status_REVIEW
                    sStatusDetail = "STAT account information has rows other than activity code of INIT and worked by of SYS-System Rep"
                    GoTo NextRow
                End If

                sStatus = "GOOD"
                sStatusDetail = "Stockamp Demographic information read successfully"
                GoTo NextRow
            Else
                'IsValid exception details specified at place of occurrence
                sStatus = Status_REVIEW
                sStatusDetail = "Data row is not valid"
                GoTo NextRow
            End If   'If oDataStockamp.IsValid Then

        End If    'If D("Status") = "" Then

NextRow:
        oDataStockamp.UpdateStatus sStatus, sStatusDetail
        'Clean-up
        Set oDataStockamp = Nothing

        'Move to the next record
        d.Next_
        'Exit Do    ' todo delete later
    Loop

ExitSub:
    Exit Sub

ErrorHandler:
    GeneralErrorHandler Err.Number, Err.Description, Err.Source, msModule & "." & procName
End Sub

Sub KillAnyAppsOpen()
' kill ie session
    Shell (Environ("Windir") & "\SYSTEM32\TASKKILL.EXE /F /IM IEXPLORE.EXE")
    Wait 5
    CloseSMSNet
    Wait 5
End Sub

Sub ArchiveAnyLeftOverFiles()
    MoveFiles goConfig.ReportsFolder, goConfig.ReportsFolder & "archive\"
    MoveFiles goConfig.ProcessDir & "AffinityMedicaid", goConfig.ReportsFolder & "ErroredFiles\"
    MoveFiles goConfig.ProcessDir & "HealthFirst", goConfig.ReportsFolder & "ErroredFiles\"
    MoveFiles goConfig.ProcessDir & "OPTUM", goConfig.ReportsFolder & "ErroredFiles\"
    MoveFiles goConfig.ProcessDir & "SMS", goConfig.ReportsFolder & "ErroredFiles\"
    MoveFiles goConfig.ProcessDir & "Stockamp", goConfig.ReportsFolder & "ErroredFiles\"
End Sub
