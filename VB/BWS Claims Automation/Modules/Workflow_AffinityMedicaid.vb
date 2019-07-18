Option Explicit

Private lStartTime As Long
Const msModule As String = "Workflow_AffinityMedicaid"

Sub Login_IE_AffinityMedicaid(sWebSiteName As String)
    On Error GoTo ErrorHandler: Const procName = "Login_IE_AffinityMedicaid"
    Dim nConnectRetry As Integer

    Dim elem As IHTMLElement
    Dim doc As HTMLDocument

    ' moves to the top of the document
    First

    If Not Web1.Find("Username") Then
        GoTo ErrorHandler
    End If

    Set doc = Web1.IE.document
    ' Pause for login screen
    ' input Login UserID
    Set elem = doc.querySelector("[id='" & "txtUserName" & "']")
    elem.value = goConfig.AFMedicaidLoginUserID


    'text("<INPUT>#ctl00_MainContent_uxLoginForm_ctl00_uxUserNameText_textbox#<#inputText#>@AffinityMedicaid Provider Secure Services Website") = goConfig.HFLoginUserID

    ' input Login Password
    Set elem = doc.querySelector("[id='" & "txtPassword" & "']")
    elem.value = goConfig.AFMedicaidLoginPassword
    'text("ctl00$MainContent$uxLoginForm$*<INPUT>#ctl00_MainContent_uxLoginForm_ctl00_uxPasswordText_textbox#<#inputText#>@AffinityMedicaid Provider Secure Services Website") = goConfig.HFLoginPassword

    ' click on login Submit button
    Set elem = doc.querySelector("[id='" & "btnLogin" & "']")
    elem.Click

    '    Pause "ctl00$MainContent$uxLoginForm$*<INPUT>#ctl00_MainContent_uxLoginForm_ctl01_uxLoginButton#@AffinityMedicaid Provider Secure Services Website"
    '    Click "ctl00$MainContent$uxLoginForm$*<INPUT>#ctl00_MainContent_uxLoginForm_ctl01_uxLoginButton#@AffinityMedicaid Provider Secure Services Website"

    '    ' check for password expires in (x) days
    '    Web1.Click "", True
    '    Wait 1

    WaitForPage
    '    Set doc = Web1.IE.document
    '    Set elem = doc.querySelector("[name='" & "ctl00$MainContent$uxContinue_Normal" & "']")
    '    Set Web1.selected = elem
    '
    '    ' if it is not found log and move on to the next claim
    '    If Not Web1.selected Is Nothing Then
    '        Web1.selected.Click
    '        WaitForPage
    '    End If
    First
    ' click Claims
    Pause "Claim Search<A>@Affinity Health Plan"
    Click "Claim Search<A>@Affinity Health Plan"
    WaitForPage
    WaitForPage

    ' add code here to pause for a contorl on the web page TOOD

    Exit Sub
ErrorHandler:
    Err.Raise Err.Number, " MODULE: " & msModule & " Sub: " & procName, Err.Description
End Sub

Sub Logout_IE_AffinityMedicaid(Optional bDummy As Boolean)
    On Error GoTo ErrorHandler: Const procName = "Logout_IE_AffinityMedicaid"

    First

    LogMessage "MODULE: Workflow SUB: Logout_IE_AffinityMedicaid:" & " before closing the IE"
'''    'Click "Log Off System<A><#W_HL_8#>@Viewing Worklist Accounts - AffinityMedicaid & Associates - eSTAT - TRAC"
'''    Pause "Logout<A><#floatRight#>@Affinity Health Plan"
'''    'Web1.selected.Click
'''    Web1.Click "", True
'''    Wait 1
'''    Activate "Message from webpage*", True
'''    SmartDialog("Message from webpage", "OK<Push button>").Click
'''    'WaitForPage
'''
'''    Activate "Windows Internet Explorer*", True
'''    SmartDialog("Windows Internet Explorer", "Yes<Push button>").Click
'''    'WaitForPage
'''
'''    ' close Ineternet Explorer
'''    'Web1.WB.quit

    ' kill ie session
    Shell (Environ("Windir") & "\SYSTEM32\TASKKILL.EXE /F /IM IEXPLORE.EXE")
    Wait 5

    LogMessage "MODULE: Workflow SUB: Logout_IE_AffinityMedicaid:" & " after closing the IE"

    Exit Sub

ErrorHandler:
    Logging "ERROR: MODULE: " & msModule & " Sub: " & procName & ": " & Err.Number & ":" & Err.Description
    GeneralErrorHandler Err.Number, Err.Description, Err.Source, msModule & "." & procName
End Sub

Sub AffinityMedicaidLoginCheck()
    On Error GoTo ErrorHandler: Const procName = "AffinityMedicaidLoginCheck"

    Dim sFileName As String
    Dim nIERestarts As Integer

RestartIE:

    LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " before the call to LanuchAndConnect_IE "
    LaunchAndConnect_IE_HF goConfig
    LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " after the call to LanuchAndConnect_IE "
    Login_IE_AffinityMedicaid goConfig.WebSiteName
    LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " before the call to ProcessData "

    ' logout & exit
    'Logout_IE_AffinityMedicaid

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

Sub AffinityMedicaid()
    On Error GoTo ErrorHandler: Const procName = "AffinityMedicaid"

    Dim sFileName As String
    Dim nIERestarts As Integer

RestartIE:

    LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " before the call to LanuchAndConnect_IE "
    LaunchAndConnect_IE_HF goConfig
    LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " after the call to LanuchAndConnect_IE "
    Login_IE_AffinityMedicaid goConfig.WebSiteName
    LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " before the call to ProcessData "

    GetAffinityMedicaidProcessData
    Exit Sub    ' todo delete later
    'ProcessData_AffinityMedicaid

    LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " after the call to ProcessData "

    LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " before sending the success email"
    'send an email with a link to the output report
    SendSuccessEMail
    LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " after sending the success email"

    ' logout & exit
    Logout_IE_AffinityMedicaid

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
Sub LaunchAndConnect_IE_HF(oConfig As cConfig)
    On Error GoTo ErrorHandler: Const procName = "LaunchAndConnect_IE_HF"

    LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " begin"

TryConnectAgain:
    If Not IsWindowEx("*Internet Explorer*") Then
        LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " executing shell command on loginurl"
        Shell oConfig.InternetExplorerPath & " " & oConfig.AFMedicaidLoginURL, vbNormalFocus
        LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " executed shell command on loginurl"
    End If
    Wait

    LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " before attempting to activate the login page"
    Do Until Active
        TimeOut = oConfig.WebTimeout
        Activate oConfig.AFMedicaidLoginCaption, True
        Connect oConfig.AFMedicaidLoginCaption, stWeb1
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

Sub GetAffinityMedicaidProcessData()
'Loop until no more source files are found
    Do Until GetNextSourceFile(goConfig.ProcessDir & "OPTUM\") = ""

        'Open the file with BWS Datastation
        d.Open_ goConfig.ProcessDir & "OPTUM\" & goConfig.InputFileName, ftDelimited, goConfig.ProcessDir & "InputFileConfig\InputFileConfig.bds"

        'Process records according to the workflow
        ProcessAllRecordsAffinityMedicaidRead

        'Close and archive the file
        d.Archive
        Wait 1
        'Exit Do    ' todo delete later
    Loop
    Logout_IE_AffinityMedicaid
End Sub

Public Sub ProcessAllRecordsAffinityMedicaidRead()
    On Error GoTo ErrorHandler: Const procName = "ProcessAllRecordsAffinityMedicaidRead"

    Dim sPersonName As String
    Dim sBirthDate As String
    Dim sFirstName As String
    Dim sLastName As String
    Dim sMiddleName As String
    Dim sAddress As String
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
    Dim nNumberOfClaims As String
    Dim iSub As Integer
    Dim nClaimRowNbr As Integer
    Dim sCheckNumber As String
    Dim nRemarkCodes As Integer
    Dim bPaymentAmountExists As Boolean
    Dim bDeniedAmountExists As Boolean
    Dim bTryFinNumber As Boolean
    Dim iTotalPages As Integer
    Dim bAtLeastOnePagePresent As Boolean
    Dim oChildrenCollection As IHTMLDOMChildrenCollection
    Dim oElementPage As IHTMLElement
    Dim oDoc As HTMLDocument
    Dim iSub2 As Integer
    Dim sPaymentAmt As String
    Dim sDeniedAmt As String

    'Loop through each record
    Do Until d.EOF_
        'Instantiates object and sets Datastation Columns array for Output file
        Set oDataAffinityMedicaid = New cDataAffinityMedicaid
        StartProcessingTime = Now

        sStatus = vbNullString
        sStatusDetail = vbNullString

        Logging "Reading account information from AffinityMedicaid for the account " & d("Account Number")

        ' default to previous statuses
        '        sStatus = d("OPTUM_Status")
        '        sStatusDetail = "OPTUM " & d("OPTUM_StatusDetail")
        
        'If d("Account Number") = "62433214" Then Stop

        'If the record should be processed - only AffinityMedicaid claims
        If d("SMS_Status") = "GOOD" And (d("SMS_Insurance_Carrier1") = "I01") Then
            ' default to previous statuses
            sStatus = d("OPTUM_Status")
            sStatusDetail = "OPTUM " & d("OPTUM_StatusDetail")

            'If the record is valid
            If oDataAffinityMedicaid.IsValid Then
                Set doc = Web1.IE.document

                bTryFinNumber = False
                ' search for accounts
                If Len(d("SMS_Policy_Number")) > 0 And IsNumeric(d("SMS_Policy_Number")) Then
                    ' plug in the policy number or fin number
                    'Set elem = doc.querySelector("[id='" & "ctl00_MainContent_uxClaimControl_MemberIDInput" & "']")
                    text("<INPUT>#ctl00_ContentPlaceHolder1_txtMemberID#<#textBox#>@Affinity Health Plan") = d("SMS_Policy_Number")
                Else
TryFinNumber:
                    If Len(d("SMS_Fin_Number")) > 0 Then
                        ' plug in the fin number or fin number
                        bTryFinNumber = True
                        'Set elem = doc.querySelector("[id='" & "ctl00_MainContent_uxClaimControl_MemberIDInput" & "']")
                        text("<INPUT>#ctl00_ContentPlaceHolder1_txtMedicaidID#<#textBox#>@Affinity Health Plan") = d("SMS_Fin_Number")

                        ' last name
                        text("<INPUT>#ctl00_ContentPlaceHolder1_txtLastName#<#textBox#>@Affinity Health Plan") = d("SMS_Patient_Last_name")

                        ' date of birth ' ask Steve
                        'Set elem = doc.querySelector("[id='" & "ctl00_MainContent_uxClaimControl_DOBInput" & "']")
                        text("<INPUT>#ctl00_ContentPlaceHolder1_txtDateOfBirth#<#textBoxDate#>@Affinity Health Plan") = Format(d("SMS_Patient_Birth_Date"), "mm/dd/yyyy")

                    Else
                        ' it is an issue log it, missing policy number/fin number
                        sStatus = Status_REVIEW
                        sStatusDetail = "Missing policy number/fin number"
                        GoTo NextRow
                    End If
                End If

                ' service being date - reg date
                Set elem = doc.querySelector("[id='" & "ctl00_MainContent_uxClaimControl_BeginDateInput" & "']")
                text("<INPUT>#ctl00_ContentPlaceHolder1_txtClaimFromDate#<#textBoxDate#>@Affinity Health Plan") = Format(d("SMS_DateOfServiceFrom"), "mm/dd/yyyy")

                ' service end date - discharge date
                'Set elem = doc.querySelector("[id='" & "ctl00_MainContent_uxClaimControl_EndDateInput" & "']")
                If Len(d("SMS_DateOfServiceTo")) > 0 Then
                    text("<INPUT>#ctl00_ContentPlaceHolder1_txtClaimToDate#<#textBoxDate#>@Affinity Health Plan") = Format(d("SMS_DateOfServiceTo"), "mm/dd/yyyy")
                Else
                    text("<INPUT>#ctl00_ContentPlaceHolder1_txtClaimToDate#<#textBoxDate#>@Affinity Health Plan") = Format(d("SMS_DateOfServiceFrom"), "mm/dd/yyyy")
                End If

                ' click search
                Pause "ctl00$ContentPlaceHolder1$btnS*<INPUT>#ctl00_ContentPlaceHolder1_btnSearch#<#button#>@Affinity Health Plan"
                Click "ctl00$ContentPlaceHolder1$btnS*<INPUT>#ctl00_ContentPlaceHolder1_btnSearch#<#button#>@Affinity Health Plan"
                WaitForPage

                ' check if 'No claims found.
                Set elem = doc.querySelector("[id='" & "msgSearchCriteria" & "']")
                If InStr(1, elem.innerText, "Unable to locate a Claim based") > 0 Then
                    d("Payor_Comment_Lines") = 1
                    d("Payor_Stat_Activity") = "6300"
                    d("Payor_Comment_Line_1_1") = "BWS NCOF"
                    d("Payor_Comment_Line_2_1") = vbNullString
                    ' mark status no claims found and move on to the next claim
                    sStatus = "GOOD"
                    sStatusDetail = "No claims found."
                    GoTo NextRow
                ElseIf InStr(1, elem.innerText, "Search either by Member Id or by other Criteria.") > 0 Then
                    ' mark status no claims found and move on to the next claim
                    sStatus = Status_REVIEW
                    sStatusDetail = elem.innerText
                    GoTo NextRow
                ElseIf InStr(1, elem.innerText, "Please enter numeric values for MemberID.") > 0 Then
                    ' look it up by FIN#
                    ' mark status no claims found and move on to the next claim
                    sStatus = Status_REVIEW
                    sStatusDetail = elem.innerText
                    GoTo NextRow
                    '                ElseIf InStr(1, elem.innerText, "Search either by Member Id or by other Criteria.") > 0 Then
                    '                    ' mark status no claims found and move on to the next claim
                    '                    sStatus = Status_REVIEW
                    '                    sStatusDetail = elem.innerText
                    '                    GoTo NextRow
                Else
                    ' keep going
                End If


                ' table name
                ' find the row that has the charged amount = d("SMS_BilledAmt_Dtl_1")
                Set elem2 = Web1.IE.document
                Set elem = elem2.querySelector("[id='" & "ctl00_ContentPlaceHolder1_grdClaims" & "']")
                WaitForPage

                ' expecting just one table
                If elem Is Nothing Then
                    d("Payor_Comment_Lines") = 1
                    d("Payor_Stat_Activity") = "6300"
                    d("Payor_Comment_Line_1_1") = "BWS NCOF"
                    d("Payor_Comment_Line_2_1") = vbNullString
                    ' mark status no claims found and move on to the next claim
                    sStatus = "GOOD"
                    sStatusDetail = "No claims found."
                    GoTo NextRow
                    Exit Sub
                ElseIf elem.Rows.length < 2 Then        'No files found
                    d("Payor_Comment_Lines") = 1
                    d("Payor_Stat_Activity") = "6300"
                    d("Payor_Comment_Line_1_1") = "BWS NCOF"
                    d("Payor_Comment_Line_2_1") = vbNullString
                    ' mark status no claims found and move on to the next claim
                    sStatus = "GOOD"
                    sStatusDetail = "No claims found."
                    GoTo NextRow
                    Exit Sub
                End If                    ' first row

                sTotalCharge = vbNullString
                nClaimRowNbr = 0
                For iSub = 1 To elem.Rows.length - 1
                    ' d("SMS_BilledAmt_Dtl_1")
                    If Trim(elem.Rows(0).cells(7).innerText) = "Charged Amount" Then
                        sTotalCharge = Trim(elem.Rows(iSub).cells(7).innerText)
                        sTotalCharge = Replace(sTotalCharge, ",", "")
                        sTotalCharge = Replace(sTotalCharge, "$", "")
                        If sTotalCharge = d("SMS_BilledAmt_Dtl_1") Then
                            nClaimRowNbr = iSub
                            Exit For
                        End If
                    End If
                Next iSub
                If nClaimRowNbr > 0 Then
                    ' keep going
                Else
                    sStatus = Status_REVIEW
                    sStatusDetail = "SMS, AffinityMedicaid Billed amount and Total Charges did not match. SMSBilled Amount " & d("SMS_BilledAmt_Dtl_1")
                    GoTo NextRow
                End If

                ' total charges
                d("Payor_TotalCharges_1") = sTotalCharge

                ' name fields
                If Trim(elem.Rows(0).cells(1).innerText) = "Member Name" Then
                    sPersonName = elem.Rows(nClaimRowNbr).cells(1).innerText
                    d("Payor_Patient_Full_Name_1") = sPersonName

                    ' name fields
                    sMiddleName = vbNullString
                    sFirstName = vbNullString
                    sLastName = vbNullString
                    If Len(sPersonName) > 0 Then
                        sLastName = UCase(StrWord(sPersonName, 1, ","))
                        sFirstName = UCase(StrWord(sPersonName, 2, " "))
                        sMiddleName = vbNullString
                        If Len(sLastName) = 1 Then
                            sMiddleName = UCase(StrWord(sPersonName, 2, " "))
                            sLastName = UCase(StrWord(sPersonName, 3, " "))
                        End If
                    End If

                    If sFirstName = vbNullString Or sLastName = vbNullString Then
                        sStatus = Status_REVIEW
                        sStatusDetail = "AffinityMedicaid first name, last name cannot be blank/null"
                        GoTo NextRow
                    End If

                    d("Payor_Patient_First_name_1") = sFirstName
                    d("Payor_Patient_Last_name_1") = sLastName
                    d("Payor_Patient_Middle_name_1") = sMiddleName

                    '                    d("Payor_Patient_Address_Line_1_1") = Trim(elem.Rows(3).cells(1).innerText)
                    '
                    '                    sAddress = vbNullString
                    '                    sAddress = Trim(elem.Rows(4).cells(1).innerText)
                    '                    d("Payor_Patient_Address_City_1") = StrWord(sAddress, 1, ",")
                    '                    d("Payor_Patient_Address_State_1") = StrWord(sAddress, 2, " ")
                    '                    d("Payor_Patient_Address_Zip_1") = StrWord(sAddress, 3, " ")
                End If



                WaitForPage
                Set oElement = GetElementByTagName("A", Trim(elem.Rows(nClaimRowNbr).cells(0).innerText))
                If Not oElement Is Nothing Then
                    oElement.Click
                    WaitForPage
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

                Pause "Claim Information<SPAN>@Affinity Health Plan"
                Click "Claim Information<SPAN>@Affinity Health Plan"
                WaitForPage

                '                ' date of birth
                '                Pause "Date of Birth:<SPAN><#REGTEXT#>@Viewing Account Detail - Stockamp & Associates - eSTAT - TRAC"
                '                Set selected = NextElement(selected)
                '                sBirthDate = Web1.selected.innerText
                '                d("SK_Patient_Birth_Date") = sBirthDate
                '
                '                If Len(sBirthDate) > 0 Then
                '                    ' keep going
                '                Else
                '                    sStatus = Status_REVIEW
                '                    sStatusDetail = "Stockamp date of birth is blank/null"
                '                    GoTo NextRow
                '                End If

                ' claim number
                Set elem = doc.querySelector("[id='" & "ctl00_ContentPlaceHolder1_lblClaimNo" & "']")
                If Not elem Is Nothing Then
                    d("Payor_ClaimNumber_1") = elem.innerText
                Else
                    sStatus = Status_REVIEW
                    sStatusDetail = "AffinityMedicaid could not read Claim Number."
                    GoTo NextRow
                End If

                ' service date
                Set elem = doc.querySelector("[id='" & "ctl00_ContentPlaceHolder1_lblServiceDate" & "']")
                If Not elem Is Nothing Then
                    d("Payor_DateOfService_1") = elem.innerText
                Else
                    sStatus = Status_REVIEW
                    sStatusDetail = "AffinityMedicaid could not read Service Date."
                    GoTo NextRow
                End If

                ' status
                Set elem = doc.querySelector("[id='" & "ctl00_ContentPlaceHolder1_lblClaimStatus" & "']")
                If Not elem Is Nothing Then
                    d("Payor_Claim_Status_1") = Trim(elem.innerText)
                Else
                    sStatus = Status_REVIEW
                    sStatusDetail = "Affinity Medicaid could not read status."
                    GoTo NextRow
                End If

                '                ' claim received
                '                If Trim(elem.Rows(1).cells(4).innerText) = "Claim Received:" Then
                '                    d("Payor_ClaimReceivedDate_1") = Trim(elem.Rows(1).cells(5).innerText)
                '                End If

                ' payment information
                ' check number
                Set elem = doc.querySelector("[id='" & "ctl00_ContentPlaceHolder1_lblCheckNo" & "']")
                If Not elem Is Nothing Then
                    If Len(Trim(elem.innerText)) > 0 Then
                        d("Payor_CheckNumber_1") = Trim(elem.innerText)
                    Else
                        d("Payor_CheckNumber_1") = "NO CK NUMBER"
                    End If
                Else
                    d("Payor_CheckNumber_1") = "NO CK NUMBER"
                End If

                ' paid date/issue date
                Set elem = doc.querySelector("[id='" & "ctl00_ContentPlaceHolder1_lblEFTDate" & "']")
                If Not elem Is Nothing Then
                    d("Payor_Paid_Issued_Date_1") = elem.innerText
                End If

                ' paid amount
                Set elem = doc.querySelector("[id='" & "ctl00_ContentPlaceHolder1_lblEFTDate" & "']")
                If Not elem Is Nothing Then
                    sTotalCharge = elem.innerText
                    sTotalCharge = Replace(sTotalCharge, "$", "")
                    d("Payor_PaidAmount_1") = sTotalCharge
                End If


                '                ' gender
                '                If Trim(elem.Rows(2).cells(2).innerText) = "Gender:" Then
                '                    d("Payor_Patient_Gender_1") = Mid(Trim(elem.Rows(2).cells(3).innerText), 1, 1)
                '                End If

                ' click on service lines information
                Pause "Member Details<SPAN>@Affinity Health Plan"
                Set selected = NextElement(selected)
                Web1.selected.Click
                WaitForPage


                ' pause for service lines information
                Pause "Service Lines Information<SPAN>#ctl00_ContentPlaceHolder1_Label1#@Affinity Health Plan"


                ' check if there is an entry in the payment column
                ' check if there is an entry in the denied column
                bPaymentAmountExists = False
                bDeniedAmountExists = False
                sPaymentAmt = vbNullString
                sDeniedAmt = vbNullString
                iTotalPages = 0
                iSub2 = 0
                iSub = 0

                Set oDoc = Web1.IE.document
                Set oElementPage = oDoc.querySelector("[id='" & "ctl00_ContentPlaceHolder1_grdLineItems_ctl13_PageDropDownList" & "']")
                ' expecting just one table
                If oElementPage Is Nothing Then
                    ' keep going
                Else
                    ' todo go through all the pages
                    iTotalPages = oElementPage.length
                    If iTotalPages = 0 Then
                        ' no pages
                    Else
                        ' more than one page exists
                        iSub2 = 0
                        For iSub2 = 1 To iTotalPages
                            If bPaymentAmountExists Then
                                Exit For
                            End If
                            If ClickTheComboBoxSelected("*<SELECT>#ctl00_ContentPlaceHolder1_grdLineItems_ctl13_PageDropDownList#@Affinity Health Plan", "" & iSub2 & "", CStr(iSub2), "Page number", True, "onChange") = eCONTROL_VALID Then
                                WaitForPage
                                Set elem2 = Web1.IE.document
                                Set elem = elem2.querySelector("[id='" & "ctl00_ContentPlaceHolder1_grdLineItems" & "']")
                                WaitForPage

                                ' expecting just one table
                                If elem Is Nothing Then
                                    ' keep going, it is okay without any service lines

                                ElseIf elem.Rows.length < 2 Then        'No rows found
                                    ' keep going, it is okay without any service lines
                                Else
                                    iSub = 0
                                    For iSub = 1 To elem.Rows.length - 2
                                        If Not bPaymentAmountExists Then
                                            If Trim(elem.Rows(0).cells(11).innerText) = "Payment Amount" Then
                                                sPaymentAmt = Trim(elem.Rows(iSub).cells(11).innerText)
                                                sPaymentAmt = Replace(sPaymentAmt, "$", "")
                                                sPaymentAmt = Replace(sPaymentAmt, ",", "")
                                                If val(sPaymentAmt) > 0 Then
                                                    bPaymentAmountExists = True
                                                    Exit For
                                                End If
                                            Else
                                                sStatus = Status_REVIEW
                                                sStatusDetail = "Affinity Medicaid could not read Payment Amount column."
                                                GoTo NextRow
                                            End If
                                        End If    ' at least one payment amount exists
                                        If Not bDeniedAmountExists Then
                                            If Trim(elem.Rows(0).cells(8).innerText) = "Denied Amount" Then
                                                sDeniedAmt = Trim(elem.Rows(iSub).cells(11).innerText)
                                                sDeniedAmt = Replace(sDeniedAmt, "$", "")
                                                sDeniedAmt = Replace(sDeniedAmt, ",", "")

                                                If val(sDeniedAmt) > 0 Then
                                                    bDeniedAmountExists = True
                                                End If
                                            Else
                                                sStatus = Status_REVIEW
                                                sStatusDetail = "Affinity Medicaid could not read Denied Amount column."
                                                GoTo NextRow
                                            End If
                                        End If    ' at least one denied amount exits
                                    Next iSub
                                End If
                            End If
                        Next iSub2    ' total pages loop
                    End If    ' total pages 0
                End If    ' no pages

                ' read remarks explanations
                ' Get all remark codes.
                ' Format “remark code;remark description”
                ' 41 characters in each comment line for SMS
                ' table name
                ' find the row that has the charged amount = d("SMS_BilledAmt_Dtl_1")
                Set elem2 = Web1.IE.document
                Set elem = elem2.querySelector("[id='" & "ctl00_ContentPlaceHolder1_grdRemarkCode" & "']")
                WaitForPage

                nRemarkCodes = 0
                ' expecting just one table
                If elem Is Nothing Then
                    ' no remark code
                    ' keep going
                ElseIf elem.Rows.length < 2 Then        'No rows found
                    ' keep going
                Else
                    iSub = 0
                    For iSub = 1 To elem.Rows.length - 1
                        d("Payor_Comment_Line_" & iSub + 2 & "_1") = Trim(elem.Rows(iSub).cells(0).innerText) & ";" & Trim(elem.Rows(iSub).cells(1).innerText)
                    Next iSub
                    nRemarkCodes = elem.Rows.length - 1
                End If
                d("Payor_Comment_Lines") = 2 + nRemarkCodes

                Pause "Claim Search<A>#ctl00_ContentPlaceHolder1_lnkClaimSearch#@Affinity Health Plan"
                Click "Claim Search<A>#ctl00_ContentPlaceHolder1_lnkClaimSearch#@Affinity Health Plan"
                WaitForPage

                'd("Payor_ProcessedDate") = ""
                'd("Payor_Patient_Birth_Date_1") = d("SMS_Patient_Birth_Date") And _
                 ' verify demographics - check with EU TODO
                'd("Payor_Patient_Middle_name_1") = d("SMS_Patient_Middle_name") And _
                 d("Payor_Patient_Gender_1") = d("SMS_Patient_Gender") And _
                 d("Payor_Patient_Address_Line_1_1") = d("SMS_Patient_Address_Line_1") And _
                 d("Payor_Patient_Address_City_1") = d("SMS_Patient_Address_City") And _
                 d("Payor_Patient_Address_State_1") = d("SMS_Patient_Address_State") And _
                 d("Payor_Patient_Address_Zip_1") = d("SMS_Patient_Address_Zip")

                If d("Payor_Patient_First_name_1") = d("SMS_Patient_First_name") And _
                   d("Payor_Patient_Last_name_1") = d("SMS_Patient_Last_name") Then
                    ' keep going
                Else
                    sStatus = Status_REVIEW
                    sStatusDetail = "SMS, AffinityMedicaid demographics did not match."
                    GoTo NextRow
                End If

                ' verify totalcharges
                If d("Payor_TotalCharges_1") = d("SMS_BilledAmt_Dtl_1") Then    'Or d("Payor_TotalCharges_1") = d("SMS_BilledAmt_Dtl_2") Then
                    ' claim 1
                    d("Payor_Comment_Line_1_1") = "BWS CLAIM " & d("Payor_ClaimNumber_1") & " " & d("Payor_Claim_Status_1")
                    d("Payor_Comment_Line_2_1") = d("Payor_PaidAmount_1") & " " & d("Payor_CheckNumber_1")
                    d("Payor_Stat_Activity") = "TODO"
                    'nNumberOfClaims - number of claims
                    If bPaymentAmountExists Then
                        d("Payor_Stat_Activity") = "6810"
                        sStatus = "GOOD"
                        sStatusDetail = "Good to process further."
                        GoTo NextRow
                    Else
                        If bDeniedAmountExists Then
                            d("Payor_Stat_Activity") = "6400"
                            sStatus = "GOOD"
                            sStatusDetail = "Good to process further."
                            GoTo NextRow
                        Else
                            d("Payor_Stat_Activity") = "6900"
                            sStatus = "GOOD"
                            sStatusDetail = "Good to process further."
                            GoTo NextRow
                        End If
                    End If
                Else
                    sStatus = Status_REVIEW
                    sStatusDetail = "SMS, AffinityMedicaid Billed amount and Total Charges did not match."
                    GoTo NextRow
                End If
                GoTo NextRow
            Else
                'IsValid exception details specified at place of occurrence
            End If   'If oDataAffinityMedicaid.IsValid Then
        End If    ' D("SMS_Status")

NextRow:

        oDataAffinityMedicaid.UpdateStatus sStatus, sStatusDetail

        'Clean-up
        Set oDataAffinityMedicaid = Nothing

        Click "ctl00$ContentPlaceHolder1$btnR*<INPUT>#ctl00_ContentPlaceHolder1_btnReset#<#button margin10Left#>@Affinity Health Plan"
        WaitForPage

        '        Pause "Claim Search<A>#ctl00_ContentPlaceHolder1_lnkClaimSearch#@Affinity Health Plan"
        '        Click "Claim Search<A>#ctl00_ContentPlaceHolder1_lnkClaimSearch#@Affinity Health Plan"

        'Move to the next record
        d.Next_
        'Exit Do    ' todo delete later
    Loop

ExitSub:
    Exit Sub

ErrorHandler:
    SendStatusEmail2 goConfig, "Affinity Medicaid issue, please look into right away."
    Stop
    Resume
    If DebugMode Then
        Debug.Print "Error in " & msModule & "." & procName & ":" & Err.Number & ":" & Err.Description
        Stop
        Resume
    End If
    GeneralErrorHandler Err.Number, Err.Description, Err.Source, msModule & "." & procName
End Sub
