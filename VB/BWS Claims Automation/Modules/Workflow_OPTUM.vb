Option Explicit

Private lStartTime As Long
Const msModule As String = "Workflow_OPTUM"

Sub Login_IE_OPTUM(sWebSiteName As String)
    On Error GoTo ErrorHandler: Const procName = "Login_IE_OPTUM"
    Dim nConnectRetry As Integer

    Dim elem As IHTMLElement
    Dim doc As HTMLDocument
    Dim sSourceVal As String

    ' moves to the top of the document
    First

    If Not Web1.Find("Optum ID or email address") Then
        GoTo ErrorHandler
    End If

    Set doc = Web1.IE.document
    ' Pause for login screen
    ' input Login UserID
    Set elem = doc.querySelector("[id='" & "userNameId_input" & "']")
    'elem.value = goConfig.OPTUMLoginUserID
    text("<INPUT>#userNameId_input#<#tk-input-masking tk-height-2t tk-width-22t ng-empty ng-valid ng-valid-pattern ng-valid-minlength ng-valid-maxlength ng-valid-required#>@Sign In With Your Optum ID - Optum ID") = goConfig.OPTUMLoginUserID

    ' input Login Password
    Set elem = doc.querySelector("[id='" & "passwdId_input" & "']")
    'elem.value = goConfig.OPTUMLoginPassword
    text("userPwd<INPUT>#passwdId_input#<#tk-input-masking tk-height-2t pwd-field-width tk-mob-password ng-empty ng-valid ng-valid-pattern ng-valid-minlength ng-valid-maxlength ng-valid-required#>@Sign In With Your Optum ID - Optum ID") = goConfig.OPTUMLoginPassword
    TriggerInputEx "userPwd<INPUT>#passwdId_input#<#tk-input-masking tk-height-2t pwd-field-width tk-mob-password ng-empty ng-valid ng-valid-pattern ng-valid-minlength ng-valid-maxlength ng-valid-required#>@Sign In With Your Optum ID - Optum ID", goConfig.OPTUMLoginPassword, True
    'text("ctl00$MainContent$uxLoginForm$*<INPUT>#ctl00_MainContent_uxLoginForm_ctl00_uxPasswordText_textbox#<#inputText#>@OPTUM Provider Secure Services Website") = goConfig.HFLoginPassword

    ' click on login Submit button
    Set elem = doc.querySelector("[id='" & "SignIn" & "']")
    elem.Click
    Wait 10
    WaitForPage

    Pause "*-dash/dashboard-ptp-claims.png<IMG>@Link"
    Click "*-dash/dashboard-ptp-claims.png<IMG>@Link"
    WaitForPage

    Exit Sub
ErrorHandler:
    Err.Raise Err.Number, " MODULE: " & msModule & " Sub: " & procName, Err.Description
End Sub

Sub Logout_IE_OPTUM(Optional bDummy As Boolean)
    On Error GoTo ErrorHandler: Const procName = "Logout_IE_OPTUM"

    Dim elem As IHTMLElement
    Dim doc As HTMLDocument
    Dim elemCol As IHTMLDOMChildrenCollection

    LogMessage "MODULE: Workflow SUB: Logout_IE_OPTUM:" & " before closing the IE"
    First
    'Pause "<svg><#fBvtAG#>@UnitedHealthcare Online"
    '    Pause "<A><#dzxvhD#>@Claim Search | Claims Link"
    '    Web1.selected.Click
    '    'Pause "Main Menu<svg>#main-menu#@UnitedHealthcare Online@0" ' this worked before, not working any more
    '    'Click "Main Menu<svg>#main-menu#@UnitedHealthcare Online@0"
    '    WaitForPage
    '
    '    Pause "Sign Out<SPAN><#ZYfnM#>@Claim Search | Claims Link"
    '    'Pause "Sign Out<SPAN><#dFlNGv#>@UnitedHealthcare Online"
    '    Web1.selected.Click
    '
    '    ' this worked before, not working any more
    '    '    Set doc = Web1.IE.document.frames.Item(1).document
    '    '    Set elemCol = doc.querySelectorAll(".ng-binding")
    '    '    ' sign out
    '    '    Set elem = elemCol(5)
    '
    '    ' expecting just one table
    '    '    If elem Is Nothing Then
    '    '        Exit Sub
    '    '    End If
    '    '    elem.Click
    '    WaitForPage
    '
    '    ' close Ineternet Explorer
    '    Web1.WB.quit

    ' kill ie session
    Shell (Environ("Windir") & "\SYSTEM32\TASKKILL.EXE /F /IM IEXPLORE.EXE")
    Wait 5


    LogMessage "MODULE: Workflow SUB: Logout_IE_OPTUM:" & " after closing the IE"
    Exit Sub

ErrorHandler:
    Logging "ERROR: MODULE: " & msModule & " Sub: " & procName & ": " & Err.Number & ":" & Err.Description
    GeneralErrorHandler Err.Number, Err.Description, Err.Source, msModule & "." & procName
End Sub

Sub OPTUMLoginCheck()
    On Error GoTo ErrorHandler: Const procName = "OPTUMLoginCheck"

    Dim sFileName As String
    Dim nIERestarts As Integer

RestartIE:

    LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " before the call to LanuchAndConnect_IE "
    LaunchAndConnect_IE_OPTUM goConfig
    LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " after the call to LanuchAndConnect_IE "
    Login_IE_OPTUM goConfig.WebSiteName
    LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " before the call to ProcessData "

    ' logout & exit
    'Logout_IE_OPTUM

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

Sub OPTUM()
    On Error GoTo ErrorHandler: Const procName = "OPTUM"

    Dim sFileName As String
    Dim nIERestarts As Integer

RestartIE:

    LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " before the call to LanuchAndConnect_IE "
    LaunchAndConnect_IE_OPTUM goConfig
    LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " after the call to LanuchAndConnect_IE "
    Login_IE_OPTUM goConfig.WebSiteName
    LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " before the call to ProcessData "

    GetOPTUMProcessData
    Exit Sub    ' todo delete later
    'ProcessData_OPTUM

    LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " after the call to ProcessData "

    LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " before sending the success email"
    'send an email with a link to the output report
    SendSuccessEMail
    LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " after sending the success email"

    ' logout & exit
    Logout_IE_OPTUM

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


' runs IE and launches the website
Sub LaunchAndConnect_IE_OPTUM(oConfig As cConfig)
    On Error GoTo ErrorHandler: Const procName = "LaunchAndConnect_IE_OPTUM"

    LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " begin"

TryConnectAgain:
    If Not IsWindowEx("*Internet Explorer*") Then
        LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " executing shell command on loginurl"
        Shell oConfig.InternetExplorerPath & " " & oConfig.OPTUMLoginURL, vbNormalFocus
        LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " executed shell command on loginurl"
    End If
    Wait

    LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " before attempting to activate the login page"
    Do Until Active
        TimeOut = oConfig.WebTimeout
        Activate "Sign In With Your Optum ID", True    ' oConfig.HFLoginCaption, True
        Connect "Sign In With Your Optum ID", stWeb1    'oConfig.HFLoginCaption, stWeb1
        TimeOut = oConfig.WebTimeout
        Wait 1
        gnConnectRetry = gnConnectRetry + 1
        LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " attempted " & gnConnectRetry & " times to connect to the login page out of " & goConfig.MaxIERestarts & " attempts"
        If gnConnectRetry > oConfig.MaxIERestarts Then
            Err.Raise vbObjectError + 1000, "LaunchAndConnect_IE_OPTUM", "Unable to connect to IE."
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
        Err.Raise errNum, "ERROR: MODULE: " & msModule & " SUB: LaunchAndConnect_IE_OPTUM: ", errDesc
    End If
End Sub

Sub GetOPTUMProcessData()
    Dim iFileCount As Long
    ' Loop until no more source files are found
    Do Until GetNextSourceFile(goConfig.ProcessDir & "HealthFirst\") = ""
        iFileCount = iFileCount + 1
        'Open the file with BWS Datastation
        'd.Open_ goConfig.ProcessDir & "SMS\" & goConfig.InputFileName, ftDelimited, goConfig.ProcessDir & "InputFileConfig.bds"
        d.Open_ goConfig.ProcessDir & "HealthFirst\" & goConfig.InputFileName, ftDelimited, goConfig.ProcessDir & "InputFileConfig\InputFileConfig.bds"

        If iFileCount = 10 Then
            ' logout & exit
            Logout_IE_OPTUM
            LaunchAndConnect_IE_OPTUM goConfig
            Login_IE_OPTUM goConfig.WebSiteName
            iFileCount = 0
        End If

        'Process records according to the workflow
        ProcessAllRecordsOPTUMRead

        'Close and archive the file
        d.Archive
        Wait 1
        'Exit Do    ' todo delete later
    Loop
    Logout_IE_OPTUM
End Sub

Public Sub ProcessAllRecordsOPTUMRead()
    On Error GoTo ErrorHandler: Const procName = "ProcessAllRecordsOPTUMRead"

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
    Dim oElementSPAN As IHTMLElement
    Dim elemCol As IHTMLDOMChildrenCollection
    Dim elemColHeader As IHTMLDOMChildrenCollection
    Dim elem2 As HTMLDocument
    Dim i As Integer
    Dim iCol As Integer
    Dim sTotalCharge As String
    Dim nNumberOfClaims As String
    Dim iSub As Integer
    Dim sCheckNumber As String
    Dim sPolicyNumber As String
    Dim sDOB As String
    Dim sBeginDate As String
    Dim sEndDate As String
    Dim bTryFinNumber As Boolean
    Dim oChildrenCollection As IHTMLDOMChildrenCollection
    Dim sBilledAmount As String
    Dim elemCol2 As IHTMLDOMChildrenCollection
    Dim sClaimStatus As String
    Dim sClaimNetworkStatus As String
    Dim oCollectionSPAN As IHTMLDOMChildrenCollection
    Dim oCollectionA As IHTMLElementCollection
    Dim sFileName As String
    Dim lStartTime As Long

    'Loop through each record
    Do Until d.EOF_
        'Instantiates object and sets Datastation Columns array for Output file
        Set oDataOPTUM = New cDataOPTUM
        StartProcessingTime = Now

        '        ' default to previous statuses
        '        sStatus = d("HealthFirst_Status")
        '        sStatusDetail = "HF " & d("HealthFirst_StatusDetail")
        
        Logging "Reading account information from OPTUM for the account " & d("Account Number")

        sStatus = vbNullString
        sStatusDetail = vbNullString
        d("Payor_Comment_Lines") = 4

        ' click on new search
        'Pause "New Search<A><#_3oPrNDk5iL_jWJvLLCggJf#>*"
        First
        Pause "New Search<A>*"
        'Pause "New Search"
        Web1.selected.Click
        'Click "New Search<A><#_3oPrNDk5iL_jWJvLLCggJf#>*"
        WaitForPage
        Pause "Be sure to select the correct *<P>*@Claim Search | Claims Link"

        Debug.Print d("Account Number")
        Debug.Print d("SMS_Status")
        Debug.Print d("SMS_Insurance_Carrier1")

        'If the record should be processed - only HealthFirst claims
        If d("SMS_Status") = "GOOD" And (d("SMS_Insurance_Carrier1") = "I10" Or d("SMS_Insurance_Carrier1") = "J10" Or d("SMS_Insurance_Carrier1") = "X22" Or d("SMS_Insurance_Carrier1") = "K15" Or d("SMS_Insurance_Carrier1") = "E08") Then

            ' default to previous statuses
            sStatus = d("HealthFirst_Status")
            sStatusDetail = "HF " & d("HealthFirst_StatusDetail")

            'If the record is valid
            If oDataOPTUM.IsValid Then

                ' ?Only limited information for this claim is available at this time. Some data and functionality may be missing or unavailable.
                If WaitForAControl("[*]Select Search Type<H3>#search-searchtype-label#<#text-uppercase text-weight-bold text-medium#>@Claim Search | Claims Link") Then
                    ' click refresh
                    Web1.IE.refresh
                    WaitForPage
                    WaitForPage
                    If WaitForAControl("[*]Select Search Type<H3>#search-searchtype-label#<#text-uppercase text-weight-bold text-medium#>@Claim Search | Claims Link") Then
                        'keep going
                        WaitForPage
                    Else
                        sStatus = Status_REVIEW
                        sStatusDetail = "Claim search window may have changed."
                        GoTo NextRow
                        ' move onto the next claim
                        Exit Sub
                    End If
                End If

                ' click on reset
                'Click "Reset<BUTTON>#select-reset-button#<#_-4rO08FXBoNiJUBbs6zHx abyss-button#>@Claim Search | Claims Link"
                Click "Reset<BUTTON>#select-reset-button#*@Claim Search | Claims Link"
                ' clear date fields
                WaitForPage
                WaitForPage

                ' click on member id radio element
                Pause "<INPUT>#select-radio-memberid#<#abyss-radio__input#>@Claim Search | Claims Link"
                Web1.selected.Click
                'Click "<INPUT>#select-radio-memberid#<#abyss-radio__input#>@Claim Search | Claims Link"
                WaitForPage
                WaitForPage
                'WriteWebPageSourceToFile
                'Wait 5    ' REMOVE LATER TODO
                bTryFinNumber = False
                ' search for accounts
                If Len(d("SMS_Policy_Number")) > 0 Then
                    ' plug in the policy number or fin number
                    sPolicyNumber = d("SMS_Policy_Number")
                    Pause "<INPUT>#select-memberid-input#*@Claim Search | Claims Link"
                    If Not TriggerInputBlurWrapper("<INPUT>#select-memberid-input#*@Claim Search | Claims Link", sPolicyNumber, sPolicyNumber, "Policy Number", True, True) Then
                        sStatus = Status_REVIEW
                        sStatusDetail = "Policy number cannot be entered."
                        GoTo NextRow
                        ' move onto the next claim
                        Exit Sub
                    End If
                Else
TryFinNumber:
                    If Len(d("SMS_Fin_Number")) > 0 Then
                        ' plug in the fin number or fin number
                        bTryFinNumber = True
                        sPolicyNumber = d("SMS_Fin_Number")
                        If Not TriggerInputBlurWrapper("<INPUT>#select-memberid-input#*@Claim Search | Claims Link", sPolicyNumber, sPolicyNumber, "Policy Number", True, True) Then
                            sStatus = Status_REVIEW
                            sStatusDetail = "FIN number cannot be entered."
                            GoTo NextRow
                            ' move onto the next claim
                            Exit Sub
                        End If
                    Else
                        'it is an issue log it, missing fin number
                        sStatus = Status_REVIEW
                        sStatusDetail = "Missing Fin number."
                        GoTo NextRow
                        ' move onto the next claim
                        Exit Sub
                    End If
                End If

                ' date of birth
                sDOB = d("SMS_Patient_Birth_Date")
                If Not TriggerInputBlurWrapper("<INPUT>#select-dob-input#*@Claim Search | Claims Link", sDOB, sDOB, "Date of Birth", True, True, True) Then
                    sStatus = Status_REVIEW
                    sStatusDetail = "Date of birth cannot be entered."
                    GoTo NextRow
                    ' move onto the next claim
                    Exit Sub
                End If

                ' service being date - reg date
                DoEvents_
                sBeginDate = Format(d("SMS_DateOfServiceFrom"), "mm/dd/yyyy")
                'If Not TriggerInputBlurWrapper("*<INPUT>#select-startdate-input#<#abyss-textinput#>@Claim Search | Claims Link", sBeginDate, sBeginDate, "Begin date", True, True) Then
                If Not TriggerInputBlurWrapper("<INPUT>#select-startdate-input#*@Claim Search | Claims Link", sBeginDate, sBeginDate, "Begin date", True, True, True) Then
                    sStatus = Status_REVIEW
                    sStatusDetail = "Begin date cannot be entered."
                    GoTo NextRow
                    ' move onto the next claim
                    Exit Sub
                End If
                WaitForPage

                '                Web1.selected.focus
                '                Key "{TAB}"

                ' service end date - discharge date
                If Len(d("SMS_DateOfServiceTo")) > 0 Then
                    '                    sStatus = Status_BSS_REVIEW
                    '                    sStatusDetail = "Handle Date of Service To."
                    '                    GoTo NextRow
                    ' service end date - discharge date
                    'Key "{TAB}"
                    '                    Pause "<INPUT>#select-enddate-input#*@Claim Search | Claims Link"
                    '                    Web1.selected.value = ""
                    '                    Web1.selected.focus
                    DoEvents_
                    sEndDate = Format(d("SMS_DateOfServiceTo"), "mm/dd/yyyy")
                    If Not TriggerInputBlurWrapper("<INPUT>#select-enddate-input#*@Claim Search | Claims Link", sEndDate, sEndDate, "End date", True, True, True) Then
                        sStatus = Status_REVIEW
                        sStatusDetail = "End date cannot be entered."
                        GoTo NextRow
                        ' move onto the next claim
                        Exit Sub
                    End If
                End If

                ' click search
                'Pause "Submit Search<BUTTON>#submit-search-button#<#sYRqvUkAHFW0C74o6J3Lo abyss-button#>@Claim Search | Claims Link"
                Pause "Submit Search<BUTTON>#submit-search-button#*@Claim Search | Claims Link"
                Web1.selected.Click
                WaitForPage
                WaitForPage

                lStartTime = Timer
                Do
                    Set doc = Web1.IE.document
                    Set elemCol = doc.querySelectorAll("._1xj7m9l_6OzJl76y_CRqTM")
                    Debug.Print elemCol.length
                    If elemCol Is Nothing Then
                        DoEvents_
                        Exit Do
                    Else
                        If elemCol.length = 0 Then
                            DoEvents_
                            Exit Do
                        Else
                            ' keep going
                        End If
                    End If

                    'Timeout if elapsed time is greater than our Timeout setting
                    If Timer >= lStartTime + goConfig.WebTimeout + 60 Then
                        Logging "Timed out on claim search"
                        sStatus = Status_REVIEW
                        sStatusDetail = "Timed out on claim search."
                        GoTo NextRow
                    End If
                    DoEvents_
                Loop
                'Click "Submit Search<BUTTON>#submit-search-button#<#sYRqvUkAHFW0C74o6J3Lo abyss-button#>@Claim Search | Claims Link"
                WaitForPage
                WaitForPage
                'DebugPrintAllWebElements
                If WaitForAControl(sPolicyNumber & "<P><#component-data#>@Claim Results | Claims Link") Then
                    ' keep going
                    Set doc = Web1.IE.document
                    'Set elemCol = doc.querySelectorAll(".z-content")
                    Set elemCol = doc.querySelectorAll(".rt-td")
                    Set elemColHeader = doc.querySelectorAll(".rt-resizable-header-content")
                    ' expecting just one table
                    If Not elemCol Is Nothing Then
                        '8 columns in the header
                        '1. Processed Date
                        '2. Status
                        '3. Paid Amount
                        '4. Billed Amount
                        '5. Last Service Date
                        '6. First Service Date
                        '7. Claim Number
                        '8. Patient name

                        sBilledAmount = vbNullString
                        nNumberOfClaims = elemCol.length / 8
                        iSub = 0
                        'Set elem = elemCol(0)
                        If nNumberOfClaims > 0 Then
                            ' loop through rows to find the correct claim
                            ' find the claim row that matched the billed amount d("SMS_BilledAmt_Dtl_1")
                            For iSub = 1 To nNumberOfClaims
                                If elemColHeader(5).innerText = "Billed Amount" Then
                                    ' billed amount
                                    'Debug.Print elemCol((iSub * 8) - 3).innerText
                                    sBilledAmount = elemCol((iSub * 8) - 3).innerText
                                    sBilledAmount = Replace(sBilledAmount, "$", "")
                                    sBilledAmount = Replace(sBilledAmount, ",", "")
                                    If d("SMS_BilledAmt_Dtl_1") = sBilledAmount Then
                                        ' click on claim number
                                        Set oElement = Nothing
                                        Set oElement = GetElementByTagName("A", elemCol((iSub * 8) - 6).innerText)
                                        If Not oElement Is Nothing Then
                                            oElement.Click
                                            WaitForPage

                                            Pause "Claim Status<H3>*@Claim Details | Claims Link"

                                            DoEvents_
                                            lStartTime = Timer
                                            Do
                                                Set doc = Web1.IE.document
                                                Set oElement = doc.querySelector("[id='" & "claimstatus-status-data" & "']")
                                                If oElement Is Nothing Then
                                                    DoEvents_
                                                    'keep going
                                                    'Exit Do
                                                Else
                                                    If Len(oElement.innerText) > 0 Then
                                                        DoEvents_
                                                        Exit Do
                                                    Else
                                                        ' keep going
                                                        DoEvents_
                                                    End If
                                                End If

                                                'Timeout if elapsed time is greater than our Timeout setting
                                                If Timer >= lStartTime + goConfig.WebTimeout Then
                                                    Logging "Timed out on loading claim data"
                                                    sStatus = Status_REVIEW
                                                    sStatusDetail = "Timed out on clicking claim link"
                                                    GoTo NextRow
                                                End If
                                                DoEvents_
                                            Loop


                                            DoEvents_
                                            lStartTime = Timer
                                            Do
                                                Set doc = Web1.IE.document
                                                Set oElement = doc.querySelector("[id='" & "billingsummary-data-totalbilled" & "']")
                                                If oElement Is Nothing Then
                                                    DoEvents_
                                                    'keep going
                                                    'Exit Do
                                                Else
                                                    If Len(oElement.innerText) > 0 Then
                                                        DoEvents_
                                                        Exit Do
                                                    Else
                                                        ' keep going
                                                        DoEvents_
                                                    End If
                                                End If

                                                'Timeout if elapsed time is greater than our Timeout setting
                                                If Timer >= lStartTime + goConfig.WebTimeout Then
                                                    Logging "Timed out on loading claim data"
                                                    sStatus = Status_REVIEW
                                                    sStatusDetail = "Timed out on clicking claim link"
                                                    GoTo NextRow
                                                End If
                                                DoEvents_
                                            Loop


                                            DoEvents_
                                            lStartTime = Timer
                                            Do
                                                Set doc = Web1.IE.document
                                                'Set oElement = doc.querySelector("[id='" & "billingsummary-data-totalbilled" & "']")
                                                Set oElement = doc.querySelector("[id='" & "claimstatus-507code" & "']")
                                                If oElement Is Nothing Then
                                                    DoEvents_
                                                    'keep going
                                                    'Exit Do
                                                Else
                                                    If Len(oElement.innerText) > 0 Then
                                                        DoEvents_
                                                        Exit Do
                                                    Else
                                                        ' keep going
                                                        DoEvents_
                                                    End If
                                                End If

                                                'Timeout if elapsed time is greater than our Timeout setting
                                                If Timer >= lStartTime + goConfig.WebTimeout Then
                                                    Logging "Timed out on loading claim data"
                                                    sStatus = Status_REVIEW
                                                    sStatusDetail = "Timed out on clicking claim link"
                                                    GoTo NextRow
                                                End If
                                                DoEvents_
                                            Loop


                                            DoEvents_
                                            lStartTime = Timer
                                            Do
                                                Set doc = Web1.IE.document
                                                Set elem = doc.querySelector("._1lOoGLtWyORIPx3IkMN5MX")
                                                If elem Is Nothing Then
                                                    DoEvents_
                                                    Exit Do
                                                Else
                                                    If elem.getAttribute("data-loading") = "false" Then
                                                        DoEvents_
                                                        Exit Do
                                                    Else
                                                        ' keep going
                                                        DoEvents_
                                                    End If
                                                End If

                                                'Timeout if elapsed time is greater than our Timeout setting
                                                If Timer >= lStartTime + goConfig.WebTimeout Then
                                                    Logging "Timed out on clicking claim link"
                                                    sStatus = Status_REVIEW
                                                    sStatusDetail = "Timed out on clicking claim link"
                                                    GoTo NextRow
                                                End If
                                                DoEvents_
                                            Loop

                                            First
                                            If WaitForAControl("Search Summary<H3>*@Claim Details | Claims Link") Then
                                                ' gather claim information
                                                ' claim number
                                                Set doc = Web1.IE.document
                                                Set oElement = Nothing
                                                Set oElement = doc.querySelector("[id='" & "claiminfo-data-claimnumber" & "']")
                                                If Not oElement Is Nothing Then
                                                    If Len(oElement.innerText) > 0 Then
                                                        d("Payor_ClaimNumber_1") = oElement.innerText
                                                        WaitForPage
                                                    Else
                                                        ' could not find claim number
                                                        sStatus = Status_REVIEW
                                                        sStatusDetail = "Policy number not found on OPTUM website."
                                                        GoTo NextRow
                                                    End If
                                                Else
                                                    ' could not find claim number
                                                    sStatus = Status_REVIEW
                                                    sStatusDetail = "Policy number not found on OPTUM website."
                                                    GoTo NextRow
                                                End If

                                                ' status
                                                Set oElement = doc.querySelector("[id='" & "claimstatus-status-data" & "']")
                                                If Not oElement Is Nothing Then
                                                    If Len(oElement.innerText) > 0 Then
                                                        d("Payor_Claim_Status_1") = oElement.innerText
                                                        WaitForPage
                                                    Else
                                                        ' could not find claim status
                                                        sStatus = Status_REVIEW
                                                        sStatusDetail = "Claims status not found on OPTUM website."
                                                        GoTo NextRow
                                                    End If
                                                Else
                                                    ' could not find claim status
                                                    sStatus = Status_REVIEW
                                                    sStatusDetail = "Claims status not found on OPTUM website."
                                                    GoTo NextRow
                                                End If

                                                ' Service Date
                                                Set oElement = doc.querySelector("[id='" & "claiminfo-data-firstdate" & "']")
                                                If Not oElement Is Nothing Then
                                                    If Len(oElement.innerText) > 0 Then
                                                        d("Payor_DateOfService_1") = oElement.innerText
                                                        WaitForPage
                                                    Else
                                                        ' could not find claim service date
                                                        sStatus = Status_REVIEW
                                                        sStatusDetail = "Claim service date not found on OPTUM website."
                                                        GoTo NextRow
                                                    End If
                                                Else
                                                    ' could not find claim service
                                                    sStatus = Status_REVIEW
                                                    sStatusDetail = "Claim service date not found on OPTUM website."
                                                    GoTo NextRow
                                                End If

                                                ' person name summary-data-patient
                                                Set oElement = doc.querySelector("[id='" & "summary-data-patient" & "']")
                                                If Not oElement Is Nothing Then
                                                    If Len(oElement.innerText) > 0 Then
                                                        d("Payor_Patient_Full_Name_1") = oElement.innerText
                                                        ' name fields
                                                        sMiddleName = vbNullString
                                                        sFirstName = vbNullString
                                                        sLastName = vbNullString
                                                        sPersonName = d("Payor_Patient_Full_Name_1")
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
                                                            sStatusDetail = "OPTUM first name, last name cannot be blank/null"
                                                            GoTo NextRow
                                                        End If
                                                        d("Payor_Patient_First_name_1") = sFirstName
                                                        d("Payor_Patient_Last_name_1") = sLastName
                                                        d("Payor_Patient_Middle_name_1") = sMiddleName
                                                    Else
                                                        ' could not find person name
                                                        sStatus = Status_REVIEW
                                                        sStatusDetail = "Person name not found on OPTUM website."
                                                        GoTo NextRow
                                                    End If
                                                Else
                                                    ' could not find person name
                                                    sStatus = Status_REVIEW
                                                    sStatusDetail = "Person name not found on OPTUM website."
                                                    GoTo NextRow
                                                End If

                                                ' address line
                                                Set elemCol2 = doc.querySelectorAll(".component-data")
                                                If Not elemCol2 Is Nothing Then
                                                    If elemCol2.length > 0 Then
                                                        sAddress = vbNullString
                                                        sAddress = elemCol2(13).innerText
                                                        sAddress = GetTheLine(sAddress, 3)
                                                        sAddress = ReformatAddress(sAddress)
                                                        d("Payor_Patient_Address_Line_1_1") = sAddress    'elemCol2(13).innerText
                                                    Else
                                                        ' could not find address
                                                        sStatus = Status_REVIEW
                                                        sStatusDetail = "Person address not found on OPTUM website."
                                                        GoTo NextRow
                                                    End If
                                                Else
                                                    ' could not find address
                                                    sStatus = Status_REVIEW
                                                    sStatusDetail = "Person address not found on OPTUM website."
                                                    GoTo NextRow
                                                End If

                                                ' received date
                                                If Not elemCol2 Is Nothing And elemCol2.length > 0 Then
                                                    d("Payor_ClaimReceivedDate_1") = elemCol2(20).innerText
                                                Else
                                                    ' could not find address
                                                    sStatus = Status_REVIEW
                                                    sStatusDetail = "Received date not found on OPTUM website."
                                                    GoTo NextRow
                                                End If

                                                ' city state zip
                                                Set oElement = doc.querySelector("[id='" & "memberinfo-data-subscribercitystatezip" & "']")
                                                If Not oElement Is Nothing Then
                                                    If Len(oElement.innerText) > 0 Then
                                                        sAddress = vbNullString
                                                        sAddress = oElement.innerText
                                                        d("Payor_Patient_Address_City_1") = StrWord(sAddress, 1, ",")
                                                        sAddressRemaining = Mid(sAddress, Len(d("Payor_Patient_Address_City_1")) + 3, Len(sAddress) - Len(d("Payor_Patient_Address_City_1")))
                                                        d("Payor_Patient_Address_State_1") = StrWord(sAddressRemaining, 1, " ")
                                                        'd("Payor_Patient_Address_Zip_1") = StrWord(sAddressRemaining, 2, " ")
                                                    Else
                                                        ' could not find person name
                                                        sStatus = Status_REVIEW
                                                        sStatusDetail = "Person city state zip not found on OPTUM website."
                                                        GoTo NextRow
                                                    End If
                                                Else
                                                    ' could not find person name
                                                    sStatus = Status_REVIEW
                                                    sStatusDetail = "Person city state zip not found on OPTUM website."
                                                    GoTo NextRow
                                                End If

                                                ' gender
                                                d("Payor_Patient_Gender_1") = "OPTUM does not have this field"

                                                ' total charges
                                                Pause "Total Billed:<SPAN>#billingsummary-label-totalbilled#*@Claim Details | Claims Link"
                                                sTotalCharge = vbNullString
                                                Set oElement = Nothing
                                                Set oElement = doc.querySelector("[id='" & "billingsummary-data-totalbilled" & "']")
                                                If Not oElement Is Nothing Then
                                                    If Len(oElement.innerText) > 0 Then
                                                        sTotalCharge = oElement.innerText
                                                        sTotalCharge = Replace(sTotalCharge, ",", "")
                                                        d("Payor_TotalCharges_1") = Replace(sTotalCharge, "$", "")
                                                    End If
                                                Else
                                                    ' could not find total billed
                                                    sStatus = Status_REVIEW
                                                    sStatusDetail = "TotalBilled is not found on OPTUM website."
                                                    GoTo NextRow
                                                End If

                                                ' comments
                                                sClaimStatus = vbNullString
                                                Set oElement = Nothing
                                                Set oElement = doc.querySelector("[id='" & "claimstatus-507code" & "']")
                                                If Not oElement Is Nothing Then
                                                    If Len(oElement.innerText) > 0 Then
                                                        sClaimStatus = oElement.innerText
                                                    End If
                                                Else
                                                    ' could not find status
                                                    sStatus = Status_REVIEW
                                                    sStatusDetail = "Current Status is not found on OPTUM website."
                                                    GoTo NextRow
                                                End If

                                                ' status to comment line
                                                Set oElement = doc.querySelector("[id='" & "claimstatus-507description" & "']")
                                                If Not oElement Is Nothing Then
                                                    If Len(oElement.innerText) > 0 Then
                                                        d("Payor_Comment_Line_3_1") = sClaimStatus & oElement.innerText
                                                    End If
                                                Else
                                                    ' could not find status
                                                    sStatus = Status_REVIEW
                                                    sStatusDetail = "Current Status Description is not found on OPTUM website."
                                                    GoTo NextRow
                                                End If

                                                sClaimNetworkStatus = vbNullString
                                                Set oElement = doc.querySelector("[id='" & "claimstatus-508code" & "']")
                                                If Not oElement Is Nothing Then
                                                    If Len(oElement.innerText) > 0 Then
                                                        sClaimNetworkStatus = oElement.innerText
                                                    End If
                                                Else
                                                    ' could not find status
                                                    sStatus = Status_REVIEW
                                                    sStatusDetail = "Network Status is not found on OPTUM website."
                                                    GoTo NextRow
                                                End If

                                                ' status to comment line
                                                Set oElement = doc.querySelector("[id='" & "claimstatus-508description" & "']")
                                                If Not oElement Is Nothing Then
                                                    If Len(oElement.innerText) > 0 Then
                                                        d("Payor_Comment_Line_4_1") = sClaimNetworkStatus & oElement.innerText
                                                    End If
                                                Else
                                                    ' could not find status
                                                    sStatus = Status_REVIEW
                                                    sStatusDetail = "Network Status Description is not found on OPTUM website."
                                                    GoTo NextRow
                                                End If

                                                ' payment information
                                                'check Number
                                                Set oElement = doc.querySelector("[id='" & "paymentinfo-data-checknumber-0" & "']")
                                                If Not oElement Is Nothing Then
                                                    If Len(oElement.innerText) > 0 Then
                                                        d("Payor_CheckNumber_1") = oElement.innerText
                                                    Else
                                                        d("Payor_CheckNumber_1") = "NO CK NUMBER"
                                                    End If
                                                Else
                                                    d("Payor_CheckNumber_1") = "NO CK NUMBER"
                                                End If

                                                ' paid amount
                                                ' paymentinfo-data-checkAmount-0
                                                sTotalCharge = vbNullString
                                                Set oElement = doc.querySelector("[id='" & "paymentinfo-data-checkAmount-0" & "']")
                                                If Not oElement Is Nothing Then
                                                    If Len(oElement.innerText) > 0 Then
                                                        sTotalCharge = oElement.innerText
                                                        d("Payor_PaidAmount_1") = Replace(sTotalCharge, "$", "")
                                                    End If
                                                End If

                                                'paid Date
                                                Set oElement = doc.querySelector("[id='" & "paymentinfo-data-paymentissuedate-0" & "']")
                                                If Not oElement Is Nothing Then
                                                    If Len(oElement.innerText) > 0 Then
                                                        d("Payor_Paid_Issued_Date_1") = oElement.innerText
                                                    End If
                                                End If

                                                'd("Payor_Patient_Birth_Date_1") = d("SMS_Patient_Birth_Date") And _
                                                 ' verify demographics - check with EU TODO
                                                'd("Payor_Patient_Middle_name_1") = d("SMS_Patient_Middle_name") And _
                                                 'd("Payor_Patient_Gender_1") = d("SMS_Patient_Gender") And _

                                                 If d("Payor_Patient_First_name_1") = d("SMS_Patient_First_name") And _
                                                 d("Payor_Patient_Last_name_1") = d("SMS_Patient_Last_name") And _
                                                 d("Payor_Patient_Address_Line_1_1") = d("SMS_Patient_Address_Line_1") And _
                                                 d("Payor_Patient_Address_City_1") = d("SMS_Patient_Address_City") And _
                                                 d("Payor_Patient_Address_State_1") = d("SMS_Patient_Address_State") Then
                                                ' keep going
                                            Else
                                                sStatus = Status_REVIEW
                                                sStatusDetail = "SMS, OPTUM demographics did not match. Please look at corresponding Payor_Patient_First_name_1, SMS_Patient_First_name results file columns."
                                                GoTo NextRow
                                            End If
                                        Else
                                            ' could not find the claim
                                            d("Payor_Comment_Lines") = 1
                                            d("Payor_Stat_Activity") = "6300"
                                            d("Payor_Comment_Line_1_1") = "BWS NCOF"
                                            d("Payor_Comment_Line_2_1") = vbNullString
                                            ' mark status no claims found and move on to the next claim
                                            sStatus = "GOOD"
                                            sStatusDetail = "No claims found."
                                            GoTo NextRow
                                        End If
                                    End If
                                    WaitForPage
                                    Exit For    ' multiple claim rows
                                End If
                            End If
                        Next iSub
                        ' claims found, but amounts did not match
                        If iSub >= 1 Then
                            If d("SMS_BilledAmt_Dtl_1") = sBilledAmount Then
                                ' keep going
                            Else
                                sStatus = Status_REVIEW
                                sStatusDetail = "SMS, OPTUM Billed amounts did not match. SMS Billed amount " & d("SMS_BilledAmt_Dtl_1") & " OPTUM billed amount " & sBilledAmount
                                GoTo NextRow
                            End If
                        Else
                            ' number of claims
                            d("Payor_Comment_Lines") = 1
                            d("Payor_Stat_Activity") = "6300"
                            d("Payor_Comment_Line_1_1") = "BWS NCOF"
                            d("Payor_Comment_Line_2_1") = vbNullString
                            ' mark status no claims found and move on to the next claim
                            sStatus = "GOOD"
                            sStatusDetail = "No claims found."
                            GoTo NextRow
                        End If
                    Else
                        d("Payor_Comment_Lines") = 1
                        d("Payor_Stat_Activity") = "6300"
                        d("Payor_Comment_Line_1_1") = "BWS NCOF"
                        d("Payor_Comment_Line_2_1") = vbNullString
                        ' mark status no claims found and move on to the next claim
                        sStatus = "GOOD"
                        sStatusDetail = "No claims found."
                        GoTo NextRow
                    End If
                End If    ' claim search succeeded
            Else    ' WaitForAControl(sPolicyNumber & "<P><#component-data#>@Claim Results | Claims Link") Then
                ' check if 'No claims found.
                Set doc = Web1.IE.document
                Set elem = doc.querySelector("[id='" & "search-warning-message" & "']")
                If Not elem Is Nothing Then
                    If elem.innerText = "Your search returned no results. Please review your search criteria and try again." Then
                        ' capture screenshot if needed, mark status and move onto the next claim.
                        If bTryFinNumber Then
                            ' capture screenshot - todo
                            sFileName = TakeScreenshot2(goConfig.LogFolderPath)
                            Logging "ERROR: Pls see screenshot - " & sFileName
                            sStatus = Status_REVIEW
                            sStatusDetail = "Account not found on OPTUM website. Please look at screenshot " & sFileName
                            GoTo NextRow
                        Else
                            ' try look for using FIN#
                            If (sPolicyNumber) > 0 And Len(d("SMS_Fin_Number")) <= 0 Then
                                d("Payor_Comment_Lines") = 1
                                d("Payor_Stat_Activity") = "6300"
                                d("Payor_Comment_Line_1_1") = "BWS NCOF"
                                d("Payor_Comment_Line_2_1") = vbNullString
                                ' mark status no claims found and move on to the next claim
                                sStatus = "GOOD"
                                sStatusDetail = "No claims found."
                                GoTo NextRow
                            End If
                            GoTo TryFinNumber
                        End If
                    End If
                End If
            End If    ' claim not found ' WaitForAControl(sPolicyNumber & "<P><#component-data#>@Claim Results | Claims Link")

            ' verify totalcharges
            If d("Payor_TotalCharges_1") = d("SMS_BilledAmt_Dtl_1") Then
                d("Payor_Comment_Line_1_1") = "BWS CLAIM " & d("Payor_ClaimNumber_1") & " " & d("Payor_Claim_Status_1")
                d("Payor_Comment_Line_2_1") = d("Payor_PaidAmount_1") & " " & d("Payor_CheckNumber_1")
                d("Payor_Stat_Activity") = "TODO"
                If d("Payor_Claim_Status_1") = "FINALIZED" Then
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
                Else
                    sStatus = Status_REVIEW
                    sStatusDetail = "Claim status is other than FINALIZED. " & d("Payor_Claim_Status_1")
                    GoTo NextRow
                End If
            Else
                sStatus = Status_REVIEW
                sStatusDetail = "SMS, OPTUM Billed amount and Total Charges did not match. SMS Billed amount " & d("SMS_BilledAmt_Dtl_1") & " OPTUM Total charges " & d("Payor_TotalCharges_1")
                GoTo NextRow
            End If
            GoTo NextRow
        Else
            'IsValid exception details specified at place of occurrence
        End If   'If oDataOPTUM.IsValid Then
    End If    ' D("SMS_Status")

NextRow:

    oDataOPTUM.UpdateStatus sStatus, sStatusDetail

    'Clean-up
    Set oDataOPTUM = Nothing

    'Move to the next record
    d.Next_
Loop

ExitSub:
Exit Sub

ErrorHandler:
If DebugMode Then
    Debug.Print "Error in " & msModule & "." & procName & ":" & Err.Number & ":" & Err.Description
    Stop
    Resume
End If

LogMessage "Error handler processlallrecordsoptum read"
Logout_IE_OPTUM
LaunchAndConnect_IE_OPTUM goConfig
Login_IE_OPTUM goConfig.WebSiteName

sStatus = Status_REVIEW
sStatusDetail = "Web page not responding for this account. Moving onto the next account"
LogMessage "Error handler processlallrecordsoptum read"
' click refresh
Web1.IE.refresh
WaitForPage
WaitForPage
If WaitForAControl("[*]Select Search Type<H3>#search-searchtype-label#<#text-uppercase text-weight-bold text-medium#>@Claim Search | Claims Link") Then
    'keep going
    WaitForPage
Else
    sStatus = Status_REVIEW
    sStatusDetail = "Claim search window may have changed."
End If
LogMessage "Error handler processlallrecordsoptum read"
'move on to the next account
GoTo NextRow

'GeneralErrorHandler Err.Number, Err.Description, Err.Source, msModule & "." & procName
End Sub


Function ClickTheComboBoxExOPTUM(sPauseString As String, sSearchFor As String, sSourceVal As String, sWebFieldName As String, bRequired As Boolean, sFireEvent As String, Optional bLoopInd As Boolean, Optional sName As String, Optional bClickOnit As Boolean) As Boolean

    Dim nControlStatusInd As Integer

    ClickTheComboBoxExOPTUM = False

    nControlStatusInd = ClickTheComboBoxSelected(sPauseString, sSearchFor, sSourceVal, sWebFieldName, bRequired, sFireEvent, bLoopInd, sName, bClickOnit)

    Select Case nControlStatusInd
    Case eCONTROL_VALID
        ClickTheComboBoxExOPTUM = True
        Exit Function
    Case eCONTROL_NOT_VALID
        Exit Function
    Case eCONTROL_CONTROL_NOT_FOUND
        Exit Function
    Case eCONTROL_ITEM_NOT_FOUND
        Exit Function
    End Select

    ClickTheComboBoxExOPTUM = True
End Function
