Option Explicit

Private lStartTime As Long
Const msModule As String = "Workflow_HealthFirst"

Sub Login_IE_HealthFirst(sWebSiteName As String)
    On Error GoTo ErrorHandler: Const procName = "Login_IE_HealthFirst"
    Dim nConnectRetry As Integer

    Dim elem As IHTMLElement
    Dim doc As HTMLDocument

    ' moves to the top of the document
    First
    If Not WaitForAControl("username: <LABEL>@Healthfirst Provider Secure Services Website") Then
        'If Not Web1.Find("username") Then
        GoTo ErrorHandler
    End If

    Set doc = Web1.IE.document
    ' Pause for login screen
    ' input Login UserID
    Set elem = doc.querySelector("[id='" & "ctl00_MainContent_uxLoginForm_ctl00_uxUserNameText_textbox" & "']")
    elem.value = goConfig.HFLoginUserID


    'text("<INPUT>#ctl00_MainContent_uxLoginForm_ctl00_uxUserNameText_textbox#<#inputText#>@Healthfirst Provider Secure Services Website") = goConfig.HFLoginUserID

    ' input Login Password
    Set elem = doc.querySelector("[id='" & "ctl00_MainContent_uxLoginForm_ctl00_uxPasswordText_textbox" & "']")
    elem.value = goConfig.HFLoginPassword
    'text("ctl00$MainContent$uxLoginForm$*<INPUT>#ctl00_MainContent_uxLoginForm_ctl00_uxPasswordText_textbox#<#inputText#>@Healthfirst Provider Secure Services Website") = goConfig.HFLoginPassword

    ' click on login Submit button
    Set elem = doc.querySelector("[id='" & "ctl00_MainContent_uxLoginForm_ctl01_uxLoginButton" & "']")
    elem.Click

    '    Pause "ctl00$MainContent$uxLoginForm$*<INPUT>#ctl00_MainContent_uxLoginForm_ctl01_uxLoginButton#@Healthfirst Provider Secure Services Website"
    '    Click "ctl00$MainContent$uxLoginForm$*<INPUT>#ctl00_MainContent_uxLoginForm_ctl01_uxLoginButton#@Healthfirst Provider Secure Services Website"

    '    ' check for password expires in (x) days
    '    Web1.Click "", True
    '    Wait 1

    WaitForPage
    Set doc = Web1.IE.document
    Set elem = doc.querySelector("[name='" & "ctl00$MainContent$uxContinue_Normal" & "']")
    Set Web1.selected = elem

    ' if it is not found log and move on to the next claim
    If Not Web1.selected Is Nothing Then
        Web1.selected.Click
        WaitForPage
    End If
    First
    ' click Claims
    Pause "Claims Look Up<A><#provPhiSearch#>@Healthfirst Provider Secure Services Website"
    Click "Claims Look Up<A><#provPhiSearch#>@Healthfirst Provider Secure Services Website"
    WaitForPage
    WaitForPage
    Exit Sub
ErrorHandler:
    Err.Raise Err.Number, " MODULE: " & msModule & " Sub: " & procName, Err.Description
End Sub

Sub Logout_IE_HealthFirst(Optional bDummy As Boolean)
    On Error GoTo ErrorHandler: Const procName = "Logout_IE_HealthFirst"

    First

    LogMessage "MODULE: Workflow SUB: Logout_IE_HealthFirst:" & " before closing the IE"
    'Click "Log Off System<A><#W_HL_8#>@Viewing Worklist Accounts - HealthFirst & Associates - eSTAT - TRAC"
    Pause "Logout"
    Web1.selected.Click
    '    Pause "Logout<A>@Provider Portal"
    '    Click "Logout<A>@Provider Portal"
    WaitForPage

    ' close Ineternet Explorer
    Web1.WB.quit

    ' kill ie session
    Shell (Environ("Windir") & "\SYSTEM32\TASKKILL.EXE /F /IM IEXPLORE.EXE")
    Wait 5

    LogMessage "MODULE: Workflow SUB: Logout_IE_HealthFirst:" & " after closing the IE"

    Exit Sub

ErrorHandler:
    Logging "ERROR: MODULE: " & msModule & " Sub: " & procName & ": " & Err.Number & ":" & Err.Description
    GeneralErrorHandler Err.Number, Err.Description, Err.Source, msModule & "." & procName
End Sub

Sub HealthFirst()
    On Error GoTo ErrorHandler: Const procName = "HealthFirst"

    Dim sFileName As String
    Dim nIERestarts As Integer

RestartIE:

    LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " before the call to LanuchAndConnect_IE "
    gnConnectRetry = 0
    LaunchAndConnect_IE_HF goConfig
    LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " after the call to LanuchAndConnect_IE "
    Login_IE_HealthFirst goConfig.WebSiteName
    LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " before the call to ProcessData "

    GetHealthFirstProcessData
    Exit Sub    ' todo delete later
    'ProcessData_HealthFirst

    LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " after the call to ProcessData "

    LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " before sending the success email"
    'send an email with a link to the output report
    SendSuccessEMail
    LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " after sending the success email"

    ' logout & exit
    Logout_IE_HealthFirst

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

Sub HealthFirstLoginCheck()
    On Error GoTo ErrorHandler: Const procName = "HealthFirstLoginCheck"

    Dim sFileName As String
    Dim nIERestarts As Integer

RestartIE:

    LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " before the call to LanuchAndConnect_IE "
    gnConnectRetry = 0
    LaunchAndConnect_IE_HF goConfig
    LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " after the call to LanuchAndConnect_IE "
    Login_IE_HealthFirst goConfig.WebSiteName
    LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " before the call to ProcessData "

    ' logout & exit
    'Logout_IE_HealthFirst

    Exit Sub
ErrorHandler:
    sFileName = TakeScreenshot2(goConfig.LogFolderPath)
    Logging "ERROR: Pls see screenshot - " & sFileName
    If InStr(Err.Source, "_IE") > 0 Then
        SendFatalError2 goConfig, Err.Source & ":" & Err.Number & ":" & Err.Description
    Else
        SendFatalError2 goConfig, Err.Source & ":" & Err.Number & ":" & Err.Description & " - " & Status & " - UNHANDLED ERROR."
    End If
End Sub


' runs IE and launches the website
Sub LaunchAndConnect_IE_HF(oConfig As cConfig)
    On Error GoTo ErrorHandler: Const procName = "LaunchAndConnect_IE_HF"

    LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " begin"

TryConnectAgain:
    If Not IsWindowEx("*Internet Explorer*") Then
        LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " executing shell command on loginurl"
        Shell oConfig.InternetExplorerPath & " " & oConfig.HFLoginURL, vbNormalFocus
        LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " executed shell command on loginurl"
    End If
    Wait

    LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " before attempting to activate the login page"
    Do Until Active
        TimeOut = oConfig.WebTimeout
        Activate oConfig.HFLoginCaption, True
        Connect oConfig.HFLoginCaption, stWeb1
        TimeOut = oConfig.WebTimeout
        Wait 1
        gnConnectRetry = gnConnectRetry + 1
        LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " attempted " & gnConnectRetry & " times to connect to the login page out of " & goConfig.MaxIERestarts & " attempts"
        If gnConnectRetry > oConfig.MaxIERestarts Then
            Err.Raise vbObjectError + 1000, "LaunchAndConnect_IE_HF", "Unable to connect to IE."
        End If
    Loop
    LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " after attempting to activate the login page"

    'WaitForPage

    LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " end"

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
        Err.Raise errNum, "ERROR: MODULE: " & msModule & " SUB: LaunchAndConnect_IE_HF: ", errDesc
    End If
End Sub

Sub GetHealthFirstProcessData()
    On Error GoTo ErrorHandler: Const procName = "GetHealthFirstProcessData"
    'Loop until no more source files are found
    Do Until GetNextSourceFile(goConfig.ProcessDir & "SMS\") = ""

        'Open the file with BWS Datastation
        d.Open_ goConfig.ProcessDir & "SMS\" & goConfig.InputFileName, ftDelimited, goConfig.ProcessDir & "InputFileConfig\InputFileConfig.bds"

        'Process records according to the workflow
        ProcessAllRecordsHealthFirstRead

        'Close and archive the file
        d.Archive
        Wait 1
        'Exit Do    ' todo delete later
    Loop
    Logout_IE_HealthFirst
    Exit Sub
ErrorHandler:
    GeneralErrorHandler Err.Number, Err.Description, Err.Source, msModule & "." & procName
End Sub

Public Sub ProcessAllRecordsHealthFirstRead()
    On Error GoTo ErrorHandler: Const procName = "ProcessAllRecordsHealthFirstRead"

    Dim sPersonName As String
    Dim sBirthDate As String
    Dim sFirstName As String
    Dim sLastName As String
    Dim sMiddleName As String
    Dim sAddress As String
    Dim sAddressRemaining As String
    Dim sStatus As String
    Dim sStatusDetail As String
    Dim elem As IHTMLElement
    Dim doc As HTMLDocument
    Dim oElement As IHTMLElement
    Dim elemCol As IHTMLDOMChildrenCollection
    Dim elem2 As HTMLDocument
    Dim i As Integer
    Dim iCol As Integer
    Dim sTotalCharge As String
    Dim nNumberOfClaimsStr As String
    Dim nNumberOfClaims As Integer
    Dim iSub As Integer
    Dim sCheckNumber As String
    Dim iNumberOfClaimsRetries As Integer
    Dim iRetryClickOnClaim As Integer

    'Loop through each record
    Do Until d.EOF_
        'Instantiates object and sets Datastation Columns array for Output file
        Set oDataHealthFirst = New cDataHealthFirst
        StartProcessingTime = Now
        
        Logging "Reading account information from HealthFirst for the account " & d("Account Number")

        ' default to previous statuses
        sStatus = vbNullString
        sStatusDetail = vbNullString
        d("Payor_Comment_Lines") = vbNullString

        ' click search
        Set doc = Web1.IE.document
        Set elem = doc.querySelector("[id='" & "ctl00_MainContent_uxClaimControl_uxSearch" & "']")
        If Not elem Is Nothing Then
            elem.Click
            WaitForPage
        End If

        'If the record should be processed - only HealthFirst claims
        If d("SMS_Status") = "GOOD" And (d("SMS_Insurance_Carrier1") = "I04" Or d("SMS_Insurance_Carrier1") = "J14") Then

            ' default to previous statuses
            sStatus = d("SMS_Status")
            sStatusDetail = "SMS " & d("SMS_StatusDetail")
            d("Payor_Comment_Lines") = 2

            'If the record is valid
            If oDataHealthFirst.IsValid Then
                Set doc = Web1.IE.document
                ' search for accounts
                If Len(d("SMS_Policy_Number")) > 0 Then
                    ' plug in the policy number or fin number
                    Set elem = doc.querySelector("[id='" & "ctl00_MainContent_uxClaimControl_MemberIDInput" & "']")
                    elem.value = d("SMS_Policy_Number")
                Else
                    If Len(d("SMS_Fin_Number")) > 0 Then
                        ' plug in the fin number or fin number
                        Set elem = doc.querySelector("[id='" & "ctl00_MainContent_uxClaimControl_MemberIDInput" & "']")
                        elem.value = d("SMS_Fin_Number")
                    Else
                        ' it is an issue log it, missing policy number/fin number
                        sStatus = Status_REVIEW
                        sStatusDetail = "Missing policy number/fin number."
                        GoTo NextRow
                        Exit Sub
                    End If
                End If
                ' date of birth
                Set elem = doc.querySelector("[id='" & "ctl00_MainContent_uxClaimControl_DOBInput" & "']")
                elem.value = d("SMS_Patient_Birth_Date")

                ' service being date - reg date
                Set elem = doc.querySelector("[id='" & "ctl00_MainContent_uxClaimControl_BeginDateInput" & "']")
                elem.value = d("SMS_DateOfServiceFrom")

                ' service end date - discharge date
                Set elem = doc.querySelector("[id='" & "ctl00_MainContent_uxClaimControl_EndDateInput" & "']")
                If Len(d("SMS_DateOfServiceTo")) > 0 Then
                    elem.value = d("SMS_DateOfServiceTo")
                Else
                    elem.value = d("SMS_DateOfServiceFrom")
                End If

                ' click search
                Set elem = doc.querySelector("[id='" & "ctl00_MainContent_uxClaimControl_uxSearch" & "']")
                elem.Click
                WaitForPage

                ' wait until page loads
                If Not WaitForAControl("To perform a search, please us*<P>@Provider Portal") Then
                    sStatus = Status_REVIEW
                    sStatusDetail = "Could not load claims page."
                    GoTo NextRow
                    Exit Sub
                End If
                WaitForPage

                ' check if 'No claims found.
                nNumberOfClaims = 0
                iNumberOfClaimsRetries = 0
TryNumberofCLaims:
                Set elem = doc.querySelector("[id='" & "ctl00_MainContent_uxClaimControl_uxMessageLabel" & "']")

                If elem.innerText = vbNullString Then
                    ' try 50 times
                    iNumberOfClaimsRetries = iNumberOfClaimsRetries + 1
                    If iNumberOfClaimsRetries >= 50 Then
                        sStatus = Status_REVIEW
                        sStatusDetail = "Could not find claims page."
                        GoTo NextRow
                    End If
                    DoEvents_
                    GoTo TryNumberofCLaims
                End If

                If elem.innerText = "No claims found." Then
                    d("Payor_Stat_Activity") = "6300"
                    d("Payor_Comment_Line_1_1") = "BWS NCOF"
                    d("Payor_Comment_Line_2_1") = vbNullString
                    ' mark status no claims found and move on to the next claim
                    sStatus = "GOOD"
                    sStatusDetail = "No claims found."
                    GoTo NextRow
                Else
                    nNumberOfClaimsStr = elem.innerText
                    If nNumberOfClaimsStr = vbNullString Then
                        d("Payor_Stat_Activity") = "6300"
                        d("Payor_Comment_Line_1_1") = "BWS NCOF"
                        d("Payor_Comment_Line_2_1") = vbNullString
                        ' mark status no claims found and move on to the next claim
                        sStatus = "GOOD"
                        sStatusDetail = "No claims found."
                        GoTo NextRow
                    Else
                        nNumberOfClaims = CInt(Trim(RemoveSpecial(RemoveAlpha(nNumberOfClaimsStr))))
                    End If
                    If nNumberOfClaims = 0 Then
                        d("Payor_Stat_Activity") = "6300"
                        d("Payor_Comment_Line_1_1") = "BWS NCOF"
                        d("Payor_Comment_Line_2_1") = vbNullString
                        ' mark status no claims found and move on to the next claim
                        sStatus = "GOOD"
                        sStatusDetail = "No claims found."
                        GoTo NextRow
                    End If
                End If

                For iSub = 1 To nNumberOfClaims
                    ' expecting 2 rows
                    WaitForPage
                    First
                    ' wait until page loads
                    If Not WaitForAControl("To perform a search, please us*<P>@Provider Portal") Then
                        d("Payor_Stat_Activity") = "6300"
                        d("Payor_Comment_Line_1_1") = "BWS NCOF"
                        d("Payor_Comment_Line_2_1") = vbNullString
                        ' mark status no claims found and move on to the next claim
                        sStatus = "GOOD"
                        sStatusDetail = "No claims found."
                        GoTo NextRow
                        Exit Sub
                    End If

                    ' table name
                    ' read first row
                    iRetryClickOnClaim = 0
TryClickOnClaims:
                    Set elem2 = Web1.IE.document
                    Set elem = elem2.querySelector("[id='" & "ctl00_MainContent_uxClaimControl_uxListGrid" & "']")
                    WaitForPage

                    ' expecting just one table
                    If elem Is Nothing Then
                        d("Payor_Stat_Activity") = "6300"
                        d("Payor_Comment_Line_1_1") = "BWS NCOF"
                        d("Payor_Comment_Line_2_1") = vbNullString
                        ' mark status no claims found and move on to the next claim
                        sStatus = "GOOD"
                        sStatusDetail = "No claims found."
                        GoTo NextRow
                        Exit Sub
                    ElseIf elem.Rows.length < 2 Then        'No files found
                        d("Payor_Stat_Activity") = "6300"
                        d("Payor_Comment_Line_1_1") = "BWS NCOF"
                        d("Payor_Comment_Line_2_1") = vbNullString
                        ' mark status no claims found and move on to the next claim
                        sStatus = "GOOD"
                        sStatusDetail = "No claims found."
                        GoTo NextRow
                        Exit Sub
                    End If                    ' first row
                    ' total charges
                    If Trim(elem.Rows(0).cells(3).innerText) = "Total Charge" Then
                        sTotalCharge = Trim(elem.Rows(iSub).cells(3).innerText)
                        sTotalCharge = Replace(sTotalCharge, ",", "")
                        d("Payor_TotalCharges_" & iSub) = Replace(sTotalCharge, "$", "")
                    End If

                    If Trim(elem.Rows(0).cells(2).innerText) = "Service Date" Then
                        d("Payor_DateOfService_" & iSub) = Trim(elem.Rows(iSub).cells(2).innerText)
                    End If


                    WaitForPage

                    'iRetryClickOnClaim = 0
                    Set oElement = GetElementByTagName("A", elem.Rows(iSub).cells(0).innerText)
                    If Not oElement Is Nothing Then
                        oElement.Click
                        WaitForPage
                    Else
                        ' could not find the claim
                        iRetryClickOnClaim = iRetryClickOnClaim + 1
                        If iRetryClickOnClaim >= 20 Then
                            d("Payor_Stat_Activity") = "6300"
                            d("Payor_Comment_Line_1_1") = "BWS NCOF"
                            d("Payor_Comment_Line_2_1") = vbNullString
                            ' mark status no claims found and move on to the next claim
                            sStatus = "GOOD"
                            sStatusDetail = "No claims found."
                            GoTo NextRow
                        End If
                        GoTo TryClickOnClaims
                    End If

                    ' wait until page loads
                    If Not WaitForAControl("Claim Information<B>@Provider Portal") Then
                        d("Payor_Stat_Activity") = "6300"
                        d("Payor_Comment_Line_1_1") = "BWS NCOF"
                        d("Payor_Comment_Line_2_1") = vbNullString
                        ' mark status no claims found and move on to the next claim
                        sStatus = "GOOD"
                        sStatusDetail = "No claims found."
                        GoTo NextRow
                        Exit Sub
                    End If
                    ' claim information
                    Set elemCol = elem2.querySelectorAll(".contentheader")
                    Set elem = elemCol(0)

                    ' expecting just one table
                    If elem Is Nothing Then
                        d("Payor_Stat_Activity") = "6300"
                        d("Payor_Comment_Line_1_1") = "BWS NCOF"
                        d("Payor_Comment_Line_2_1") = vbNullString
                        ' mark status no claims found and move on to the next claim
                        sStatus = "GOOD"
                        sStatusDetail = "No claims found."
                        GoTo NextRow
                        Exit Sub
                    ElseIf elem.Rows.length < 2 Then        'No files found
                        d("Payor_Stat_Activity") = "6300"
                        d("Payor_Comment_Line_1_1") = "BWS NCOF"
                        d("Payor_Comment_Line_2_1") = vbNullString
                        ' mark status no claims found and move on to the next claim
                        sStatus = "GOOD"
                        sStatusDetail = "No claims found."
                        GoTo NextRow
                        Exit Sub
                    End If

                    ' policy number
                    If Trim(elem.Rows(1).cells(0).innerText) = "Claim Number:" Then
                        d("Payor_ClaimNumber_" & iSub) = Trim(elem.Rows(1).cells(1).innerText)
                    End If

                    ' status
                    If Trim(elem.Rows(1).cells(2).innerText) = "Status:" Then
                        d("Payor_Claim_Status_" & iSub) = Trim(elem.Rows(1).cells(3).innerText)
                    End If

                    ' claim received
                    If Trim(elem.Rows(1).cells(4).innerText) = "Claim Received:" Then
                        d("Payor_ClaimReceivedDate_" & iSub) = Trim(elem.Rows(1).cells(5).innerText)
                    End If

                    ' claim received
                    If Trim(elem.Rows(2).cells(0).innerText) = "Member:" Then
                        d("Payor_Patient_Full_Name_" & iSub) = Trim(elem.Rows(2).cells(1).innerText)

                        ' name fields
                        sMiddleName = vbNullString
                        sFirstName = vbNullString
                        sLastName = vbNullString
                        sPersonName = d("Payor_Patient_Full_Name_" & iSub)
                        If Len(sPersonName) > 0 Then
                            sFirstName = UCase(StrWord(sPersonName, 1, " "))
                            sLastName = UCase(StrWord(sPersonName, 2, " "))
                            sMiddleName = vbNullString
                            If Len(sLastName) = 1 Then
                                sMiddleName = UCase(StrWord(sPersonName, 2, " "))
                                sLastName = UCase(StrWord(sPersonName, 3, " "))
                            End If
                        End If

                        If sFirstName = vbNullString Or sLastName = vbNullString Then
                            sStatus = Status_REVIEW
                            sStatusDetail = "HealthFirst first name, last name cannot be blank/null"
                            GoTo NextRow
                        End If

                        d("Payor_Patient_First_name_" & iSub) = sFirstName
                        d("Payor_Patient_Last_name_" & iSub) = sLastName
                        d("Payor_Patient_Middle_name_" & iSub) = sMiddleName

                        sAddress = vbNullString
                        sAddress = Trim(elem.Rows(3).cells(1).innerText)
                        sAddress = ReformatAddress(sAddress)
                        d("Payor_Patient_Address_Line_1_" & iSub) = sAddress    'Trim(elem.Rows(3).cells(1).innerText)

                        sAddress = vbNullString
                        sAddress = Trim(elem.Rows(4).cells(1).innerText)
                        d("Payor_Patient_Address_City_" & iSub) = StrWord(sAddress, 1, ",")

                        sAddressRemaining = Mid(sAddress, Len(d("Payor_Patient_Address_City_" & iSub)) + 3, Len(sAddress) - Len(d("Payor_Patient_Address_City_" & iSub)))
                        d("Payor_Patient_Address_State_1") = StrWord(sAddressRemaining, 1, " ")
                        d("Payor_Patient_Address_Zip_1") = StrWord(sAddressRemaining, 2, " ")

                        d("Payor_Patient_Address_State_" & iSub) = StrWord(sAddressRemaining, 1, " ")
                        d("Payor_Patient_Address_Zip_" & iSub) = StrWord(sAddressRemaining, 2, " ")
                    End If

                    ' gender
                    If Trim(elem.Rows(2).cells(2).innerText) = "Gender:" Then
                        d("Payor_Patient_Gender_" & iSub) = Mid(Trim(elem.Rows(2).cells(3).innerText), 1, 1)
                    End If

                    ' payment information
                    ' check number
                    sCheckNumber = vbNullString
                    If Trim(elem.Rows(11).cells(2).innerText) = "Check/EFT # (?):" Then
                        sCheckNumber = Trim(elem.Rows(11).cells(3).innerText)
                        If Len(sCheckNumber) > 0 Then
                            d("Payor_CheckNumber_" & iSub) = sCheckNumber
                        Else
                            d("Payor_CheckNumber_" & iSub) = "NO CK NUMBER"
                        End If
                    End If

                    ' paid date
                    If Trim(elem.Rows(11).cells(4).innerText) = "Paid Date:" Then
                        d("Payor_Paid_Issued_Date_" & iSub) = Trim(elem.Rows(11).cells(5).innerText)
                    End If

                    ' paid amount
                    If Trim(elem.Rows(12).cells(2).innerText) = "Paid Amount:" Then
                        sTotalCharge = Trim(elem.Rows(12).cells(3).innerText)
                        d("Payor_PaidAmount_" & iSub) = Replace(sTotalCharge, "$", "")
                    End If

                    ' click on back button
                    Set elem = doc.querySelector("[id='" & "ctl00_MainContent_uxClaimControl_uxBackToSearchLink" & "']")
                    elem.Click
                    WaitForPage
                Next iSub

                'd("Payor_ProcessedDate") = ""
                'd("Payor_Patient_Birth_Date_1") = d("SMS_Patient_Birth_Date") And _
                 ' verify demographics - check with EU TODO
                'd("Payor_Patient_Middle_name_1") = d("SMS_Patient_Middle_name") And _

                 If d("Payor_Patient_First_name_1") = d("SMS_Patient_First_name") And _
                 d("Payor_Patient_Last_name_1") = d("SMS_Patient_Last_name") And _
                 d("Payor_Patient_Gender_1") = d("SMS_Patient_Gender") And _
                 d("Payor_Patient_Address_Line_1_1") = d("SMS_Patient_Address_Line_1") And _
                 d("Payor_Patient_Address_City_1") = d("SMS_Patient_Address_City") And _
                 d("Payor_Patient_Address_State_1") = d("SMS_Patient_Address_State") And _
                 d("Payor_Patient_Address_Zip_1") = d("SMS_Patient_Address_Zip") Then
                ' keep going
            Else
                sStatus = Status_REVIEW
                sStatusDetail = "SMS, HealthFirst demographics did not match."
                GoTo NextRow
            End If
            ' verify totalcharges
            If d("Payor_TotalCharges_1") = d("SMS_BilledAmt_Dtl_1") Then    'Or d("Payor_TotalCharges_1") = d("SMS_BilledAmt_Dtl_2") Then
                ' claim 1
                d("Payor_Comment_Line_1_1") = "BWS CLAIM " & d("Payor_ClaimNumber_1") & " " & d("Payor_Claim_Status_1")
                d("Payor_Comment_Line_2_1") = d("Payor_PaidAmount_1") & " " & d("Payor_CheckNumber_1")
                d("Payor_Stat_Activity") = "TODO"
                'nNumberOfClaims - number of claims
                If d("Payor_Claim_Status_1") = "Posted" Then
                    If Len(d("Payor_CheckNumber_1")) > 0 Then
                        If val(d("Payor_PaidAmount_1")) > 0 Then
                            d("Payor_Stat_Activity") = "6810"
                            sStatus = "GOOD"
                            sStatusDetail = "Good to process further."
                            GoTo NextRow
                        Else
                            d("Payor_Stat_Activity") = "6900"
                            sStatus = "GOOD"
                            sStatusDetail = "Good to process further."
                            GoTo NextRow
                        End If
                    Else
                        d("Payor_Stat_Activity") = "6400"
                        sStatus = "GOOD"
                        sStatusDetail = "Good to process further."
                        GoTo NextRow
                    End If
                ElseIf d("Payor_Claim_Status_1") = "Open" Then
                    d("Payor_Stat_Activity") = "6900"
                    sStatus = "GOOD"
                    sStatusDetail = "Good to process further."
                    GoTo NextRow
                Else
                    sStatus = Status_REVIEW
                    sStatusDetail = "Claim status is other than Posted or Open. " & d("Payor_Claim_Status_1")
                    GoTo NextRow
                End If
            ElseIf d("Payor_TotalCharges_2") = d("SMS_BilledAmt_Dtl_1") Then    'Or d("Payor_TotalCharges_2") = d("SMS_BilledAmt_Dtl_2") Then
                ' claim 2
                d("Payor_Comment_Line_1_1") = "BWS CLAIM " & d("Payor_ClaimNumber_2") & " " & d("Payor_Claim_Status_2")
                d("Payor_Comment_Line_2_1") = d("Payor_PaidAmount_2") & " " & d("Payor_CheckNumber_2")
                d("Payor_Stat_Activity") = "TODO"
                'nNumberOfClaims - number of claims
                If d("Payor_Claim_Status_2") = "Posted" Then
                    If Len(d("Payor_CheckNumber_2")) > 0 Then
                        If val(d("Payor_PaidAmount_2")) > 0 Then
                            d("Payor_Stat_Activity") = "6810"
                            sStatus = "GOOD"
                            sStatusDetail = "Good to process further."
                            GoTo NextRow
                        Else
                            d("Payor_Stat_Activity") = "6900"
                            sStatus = "GOOD"
                            sStatusDetail = "Good to process further."
                            GoTo NextRow
                        End If
                    Else
                        d("Payor_Stat_Activity") = "6400"
                        sStatus = "GOOD"
                        sStatusDetail = "Good to process further."
                        GoTo NextRow
                    End If
                ElseIf d("Payor_Claim_Status_1") = "Open" Then
                    d("Payor_Stat_Activity") = "6900"
                    sStatus = "GOOD"
                    sStatusDetail = "Good to process further."
                    GoTo NextRow
                Else
                    sStatus = Status_REVIEW
                    sStatusDetail = "Claim status is other than Posted or Open " & d("Payor_Claim_Status_1")
                    GoTo NextRow
                End If
            Else
                sStatus = Status_REVIEW
                sStatusDetail = "SMS, HealthFirst Billed amount and Total Charges did not match."
                GoTo NextRow
            End If
            GoTo NextRow
        Else
            'IsValid exception details specified at place of occurrence
        End If   'If oDataHealthFirst.IsValid Then
    End If    ' D("SMS_Status")

NextRow:

    oDataHealthFirst.UpdateStatus sStatus, sStatusDetail

    'Clean-up
    Set oDataHealthFirst = Nothing

    'Move to the next record
    d.Next_
    'Exit Do    ' todo delete later
Loop

ExitSub:
Exit Sub

ErrorHandler:
If DebugMode Then
    Debug.Print "Error in " & msModule & "." & procName & ":" & Err.Number & ":" & Err.Description
    Stop
    Resume
End If
GeneralErrorHandler Err.Number, Err.Description, Err.Source, msModule & "." & procName
End Sub
