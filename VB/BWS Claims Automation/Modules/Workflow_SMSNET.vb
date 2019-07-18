Option Explicit

Const msModule As String = "Workflow_SMSNET"
Public nCurrentCommentLineNbr As Integer

Sub GetSMSNETData()
    On Error GoTo ErrorHandler: Const procName = "GetSMSNETData"

    Dim lStartTime As Long

    Pause "@22,63"
    Key "02"
    Key "{ENTER}"

    ' make sure you are on the PATIENT ACCOUNTING MASTER FUNCTIONS screen
    lStartTime = Timer
    Do
        Wait 0.5
        DoEvents_
        If InStr(View(Row:=1, Col:=3, length:=35), "PATIENT ACCOUNTING MASTER FUNCTIONS") > 0 Then
            DoEvents_
            Exit Do
        End If
        If Timer >= lStartTime + goConfig.WebTimeout Then
            Err.Raise seTimeOut, procName, "PATIENT ACCOUNTING MASTER FUNCTIONS did not appear within timeout period."
        End If
    Loop


    ' navigate to inquiry/data entry screen
    Pause "@21,63"
    Key "01"
    Key "{ENTER}"


    ' make sure you are on the SYSTEM ADMINISTRATOR MENU screen
    lStartTime = Timer
    Do
        Wait 0.5
        DoEvents_
        If InStr(View(Row:=1, Col:=3, length:=25), "SYSTEM ADMINISTRATOR MENU") > 0 Then
            DoEvents_
            Exit Do
        End If
        If Timer >= lStartTime + goConfig.WebTimeout Then
            Err.Raise seTimeOut, "Login", "SYSTEM ADMINISTRATOR MENU did not appear within timeout period."
        End If
    Loop


    ' navigate to pt inq.cmnts.pay/ad.rev screen
    Pause "@22,61"
    Key "PTIQ"
    Key "{ENTER}"

    ' login into smsnet
    ' navigate to

    Do Until GetNextSourceFile(goConfig.ProcessDir & "StockAmp\") = ""

        'Open the file with BWS Datastation
        d.Open_ goConfig.ProcessDir & "StockAmp\" & goConfig.InputFileName, ftDelimited, goConfig.ProcessDir & "InputFileConfig\InputFileConfig.bds"

        'Process records according to the workflow
        ProcessAllRecordsSMSNETRead

        'Close and archive the file
        d.Archive
        Wait 1

        ' copy results files to EIDX input folder
        'FileCopy goConfig.reportsFolder & goconfig.OutputFileName, "TODOfolder" & goconfig.OutputFileName
        Wait 2
    Loop

    Exit Sub
    ' logout from smsnet
ErrorHandler:
    Err.Raise seTimeOut, "GetSMSNetData", "Error occurred."
End Sub


Sub UpdateAccountData()
    On Error GoTo ErrorHandler: Const procName = "UpdateSMSNETData"

    Dim lStartTime As Long

    Pause "@22,63"
    Key "02"
    Key "{ENTER}"

    ' make sure you are on the PATIENT ACCOUNTING MASTER FUNCTIONS screen
    lStartTime = Timer
    Do
        Wait 0.5
        DoEvents_
        If InStr(View(Row:=1, Col:=3, length:=35), "PATIENT ACCOUNTING MASTER FUNCTIONS") > 0 Then
            DoEvents_
            Exit Do
        End If
        If Timer >= lStartTime + goConfig.WebTimeout Then
            Err.Raise seTimeOut, procName, "PATIENT ACCOUNTING MASTER FUNCTIONS did not appear within timeout period."
        End If
    Loop

    ' navigate to inquiry/data entry screen
    Pause "@21,63"
    Key "01"
    Key "{ENTER}"

    ' make sure you are on the SYSTEM ADMINISTRATOR MENU screen
    lStartTime = Timer
    Do
        Wait 0.5
        DoEvents_
        If InStr(View(Row:=1, Col:=3, length:=25), "SYSTEM ADMINISTRATOR MENU") > 0 Then
            DoEvents_
            Exit Do
        End If
        If Timer >= lStartTime + goConfig.WebTimeout Then
            Err.Raise seTimeOut, "Login", "SYSTEM ADMINISTRATOR MENU did not appear within timeout period."
        End If
    Loop

    ' navigate to pt inq.cmnts.pay/ad.rev screen
    Pause "@22,61"
    Key "PTIQ"
    Key "{ENTER}"

    ' login into smsnet
    ' navigate to
    Do Until GetNextSourceFile(goConfig.ProcessDir & "AffinityMedicaid\") = ""
        'Open the file with BWS Datastation
        d.Open_ goConfig.ProcessDir & "AffinityMedicaid\" & goConfig.InputFileName, ftDelimited, goConfig.ProcessDir & "InputFileConfig\InputFileConfig.bds"

        'Process records according to the workflow
        ProcessAllRecordsStockampSMSNETUpdate

        'Close and archive the file
        d.Archive
        Wait 1

        ' copy results files to EIDX input folder
        'FileCopy goConfig.reportsFolder & goconfig.OutputFileName, "TODOfolder" & goconfig.OutputFileName
        Wait 2
    Loop
    Exit Sub
    ' logout from smsnet
ErrorHandler:
    GeneralErrorHandler Err.Number, Err.Description, Err.Source, msModule & "." & procName
End Sub

Public Sub ProcessAllRecordsStockampSMSNETUpdate()
    On Error GoTo ErrorHandler: Const procName = "ProcessAllRecordsStockampSMSNETUpdate"

    Dim lStartTime As Long
    Dim sStatus As String
    Dim sStatusDetail As String
    Dim nPayorCommentLines As Integer
    Dim iSub As Integer
    Dim sComments As String

    Dim sPersonName As String
    Dim sBirthDate As String
    Dim sFirstName As String
    Dim sLastName As String
    Dim sSKStatActivity As String
    Dim elem As IHTMLElement
    Dim oDoc As HTMLDocument
    Dim iSub2 As Integer
    Dim sComments2 As String
    Dim sFromWorkListNumber As String
    Dim sToWorkListNumber As String

    'Loop through each record
    Do Until d.EOF_
        'If the record should be processed 'TODO check on this
        ' default to previous statuses
        SMSInitializeStatus sStatus, sStatusDetail

        Logging "Processing account in SMSNet for the account " & d("Account Number")

        'Instantiates object and sets Datastation Columns array for Output file
        Set oDataSMSNetUpd = New cDataSMSNetUpd
        StartProcessingTime = Now

        If d("SMS_Insurance_Carrier1") = "I04" Or d("SMS_Insurance_Carrier1") = "J14" Or d("Carrier Code") = "I004" Or d("Carrier Code") = "J014" _
           Or d("SMS_Insurance_Carrier1") = "I10" Or d("SMS_Insurance_Carrier1") = "J10" Or d("Carrier Code") = "I010" Or d("Carrier Code") = "J010" _
           Or d("SMS_Insurance_Carrier1") = "X22" Or d("SMS_Insurance_Carrier1") = "K15" Or d("Carrier Code") = "X022" Or d("Carrier Code") = "K015" _
           Or d("SMS_Insurance_Carrier1") = "E08" Or d("Carrier Code") = "E008" _
           Or d("SMS_Insurance_Carrier1") = "I01" Or d("Carrier Code") = "I001" Then
            ' KEEP GOING
        Else
            GoTo NextRow
        End If

        If d("HealthFirst_Status") = "GOOD" Or d("AFMEDICAID_Status") = "GOOD" Or d("OPTUM_Status") = "GOOD" Then     'TODO add other payers

            'If the record is valid
            If oDataSMSNetUpd.IsValid Then
                ' make sure you are on the patient selection criteria screen
                lStartTime = Timer
                Do
                    Wait 0.5
                    DoEvents_
                    If InStr(View(Row:=1, Col:=3, length:=26), "PATIENT SELECTION CRITERIA") > 0 Then
                        DoEvents_
                        Exit Do
                    End If
                    If Timer >= lStartTime + goConfig.WebTimeout Then
                        Err.Raise seTimeOut, procName, "PATIENT SELECTION CRITERIA did not appear within timeout period."
                    End If
                Loop

                ' type in account number
                Pause "@5,27"
                Key d("Account Number")
                Key "{ENTER}"

                ' make sure you are on the patient overview screen
                lStartTime = Timer
                Do
                    Wait 0.5
                    DoEvents_
                    If InStr(View(Row:=1, Col:=3, length:=16), "PATIENT OVERVIEW") > 0 Then
                        DoEvents_
                        Exit Do
                    End If
                    If Timer >= lStartTime + goConfig.WebTimeout Then
                        Err.Raise seTimeOut, procName, "PATIENT OVERVIEW did not appear within timeout period."
                    End If
                Loop

                ' post comments for account
                Key "@a"

                ' make sure you are on the post comments for account screen
                lStartTime = Timer
                Do
                    Wait 0.5
                    DoEvents_
                    If InStr(View(Row:=1, Col:=2, length:=25), "POST COMMENTS FOR ACCOUNT") > 0 Then
                        DoEvents_
                        Exit Do
                    End If
                    If Timer >= lStartTime + goConfig.WebTimeout Then
                        Err.Raise seTimeOut, procName, "PATIENT OVERVIEW did not appear within timeout period."
                    End If
                Loop

                Pause "@16,5"
                ' enter all comments do not delete
                nPayorCommentLines = d("Payor_Comment_Lines")
                sComments = vbNullString
                iSub = 0
                nCurrentCommentLineNbr = 1
                If nPayorCommentLines > 0 Then
                    For iSub = 1 To nPayorCommentLines
                        sComments = d("Payor_Comment_Line_" & iSub & "_1")
                        If SMS_KeyComment(sComments) Then
                            ' keep going
                        Else
                            ' log no comments added
                            sStatus = Status_REVIEW
                            sStatusDetail = "No comments found to update."
                            GoTo NextRow
                        End If
                    Next iSub
                Else
                    ' log no comments added
                    sStatus = Status_REVIEW
                    sStatusDetail = "No comments found to update."
                    GoTo NextRow
                End If

                ' save comments
                If nCurrentCommentLineNbr > 1 And nCurrentCommentLineNbr <= 5 Then
                    Key "{ENTER}"
                    If PauseForPressEnterComments Then
                        Key "{ENTER}"
                        If PauseForPressPostComments Then
                            ' keep going
                        Else
                            sStatus = Status_REVIEW
                            sStatusDetail = "No comments found to update."
                            GoTo NextRow
                        End If
                    End If
                End If
                ' mark review status and move onto the next row
                sStatus = StatusText_OK
                sStatusDetail = "Only SMS Comments updated successfully."

                ' Stockamp stat activity update
                B2.First
                ' click on stat
                B2.Pause "Search Accounts"
                B2.Web1.selected.Click
                WaitForPage2

                ' search for accounts
                ' plug in the account number and get the demographic information
                B2.text("<INPUT>#txtAccountNumber#@Search Accounts - Stockamp & Associates - eSTAT - TRAC") = d("Account Number")

                ' click search
                B2.Click "submit1<INPUT>#submit1#<#bttn#>@Search Accounts - Stockamp & Associates - eSTAT - TRAC"
                WaitForPage2

                ' click on the account number link
                B2.Click d("Account Number") & "<A><#B_HL_8#>@Viewing Account Search Results - Stockamp & Associates - eSTAT - TRAC"
                WaitForPage2

                ' stat activity
                ' If insurance website shows NO CLAIM ON FILE:   use CODE:  6300   and tickle for 1 day
                ' If insurance website shows claim received only or claim is pending payment:   use CODE: 6810 and tickle for 35 days - override
                ' If insurance website shows claim DENIED (for any reason):  use CODE:  6400 and tickle for 1 day
                ' If insurance website shows claim is pending for issues for any reason other than payment:  use CODE:  6900 and tickle for 1 day
                sSKStatActivity = d("Payor_Stat_Activity")

                sFromWorkListNumber = StrWord(d("SK_FileProcessed"), 1, "_")
                ' set stat activity to 6300 if the worklist number is 6050
                If sSKStatActivity = "6810" Then
                    ' keep going
                Else
                    If sFromWorkListNumber = "6050" Then
                        sSKStatActivity = "6300"
                    End If
                End If


                If ClickTheComboBoxQrySelectorB2("cboSTATActivity", "" & sSKStatActivity & " - ", sSKStatActivity, "SK Stat Activity", True, "onChange") = eCONTROL_VALID Then
                    ' keep going
                Else
                    LogMessage "MODULE: " & msModule & " Sub: " & procName & ":" & " end"
                    GoTo NextRow
                End If
                WaitForPage2

                d("TickleDays") = "System default days"
                If sSKStatActivity = "6810" Then
                    d("TickleDays") = "35"
                    B2.text("<INPUT>#txtTickleDays#@Viewing Account Detail - Stockamp & Associates - eSTAT - TRAC") = "35"
                End If

                Set oDoc = B2.Web1.IE.document

                ' stat submit date
                Set elem = oDoc.querySelector("[id='" & "txtSubmitDate" & "']")
                elem.value = Format(Now, "MM/DD/YYYY")    '"01/21/2017"    'd("SK_Stat_Submit_Date")

'                leave these blank
'                stat phone num_1
'                Set elem = oDoc.querySelector("[id='" & "txtAreaCode" & "']")
'                elem.value = "999"    'd("SK_Stat_Phone_Num_1")
'                ' stat phone num_2
'                Set elem = oDoc.querySelector("[id='" & "txtPhoneFirst" & "']")
'                elem.value = "999"    'd("SK_Stat_Phone_Num_2")
'                ' stat phone num_3
'                Set elem = oDoc.querySelector("[id='" & "txtAreaLast" & "']")
'                elem.value = "999"    'd("SK_Stat_Phone_Num_3")

                ' comments 'txtSTATNote
                Set elem = oDoc.querySelector("[id='" & "txtSTATNote" & "']")
                ' enter all comments
                nPayorCommentLines = 0
                nPayorCommentLines = d("Payor_Comment_Lines")
                sComments = vbNullString
                iSub2 = 0
                For iSub2 = 1 To nPayorCommentLines
                    sComments = sComments & d("Payor_Comment_Line_" & iSub2 & "_1") & Chr(13)
                Next iSub2
                elem.value = sComments

                ' update account
                B2.Pause "SubmitForm<INPUT>#SubmitForm#*@Viewing Account Detail - Stockamp & Associates - eSTAT - TRAC"
                Set elem = oDoc.querySelector("[id='" & "SubmitForm" & "']")
                elem.Click
                WaitForPage2
                If HandlePopups_Stockcamp Then
                    sStatus = Status_REVIEW
                    sStatusDetail = "SMSNet got posted but not Stockamp application"
                    GoTo NextRow
                End If
                sStatus = StatusText_OK
                sStatusDetail = "Both SMS and Stockamp New STAT Activity updated successfully"
            Else
                '                'IsValid exception details specified at place of occurrence
            End If   'If oDataStockampUpd.IsValid Then

            GoTo NextRow
        End If    'good status
NextRow:

        ' health first/optum/affinity medicaid
        If d("SMS_Insurance_Carrier1") = "I04" Or d("SMS_Insurance_Carrier1") = "J14" Or d("Carrier Code") = "I004" Or d("Carrier Code") = "J014" _
           Or d("SMS_Insurance_Carrier1") = "I10" Or d("SMS_Insurance_Carrier1") = "J10" Or d("Carrier Code") = "I010" Or d("Carrier Code") = "J010" _
           Or d("SMS_Insurance_Carrier1") = "X22" Or d("SMS_Insurance_Carrier1") = "K15" Or d("Carrier Code") = "X022" Or d("Carrier Code") = "K015" _
           Or d("SMS_Insurance_Carrier1") = "E08" Or d("Carrier Code") = "E008" _
           Or d("SMS_Insurance_Carrier1") = "I01" Or d("Carrier Code") = "I001" Then
            ' proceed
        Else
            sStatus = Status_REVIEW
            sStatusDetail = "Functionality for this Carrier is not implemented"
        End If

        oDataSMSNetUpd.UpdateStatusUpdate sStatus, sStatusDetail

        'Clean-up
        Set oDataSMSNetUpd = Nothing

        ' navigate to patient selection criteria screen
        Key "@e"
        DoEvents_

        ' make sure you are on the patient selection criteria screen
        lStartTime = Timer
        Do
            Wait 0.5
            DoEvents_
            If InStr(View(Row:=1, Col:=3, length:=26), "PATIENT SELECTION CRITERIA") > 0 Then
                DoEvents_
                Exit Do
            Else
                Key "@e"
                DoEvents_
            End If
            If Timer >= lStartTime + goConfig.WebTimeout Then
                Err.Raise seTimeOut, procName, "Application did not appear within timeout period."
            End If
        Loop

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
    GeneralErrorHandler Err.Number, Err.Description, Err.Source, msModule & "." & procName
End Sub

Public Sub ProcessAllRecordsSMSNETRead()
    On Error GoTo ErrorHandler: Const procName = "ProcessAllRecordsSMSNETRead"

    Dim sPersonName As String
    Dim sBirthDate As String
    Dim sFirstName As String
    Dim sLastName As String
    Dim lStartTime As Long
    Dim iPagesNum As Integer
    Dim iRowNum As Integer
    Dim bFound As Boolean
    Dim sBilledAmtDtl As String
    Dim sBilledAmtDtl2 As String
    Dim sTotalCharges As String
    Dim sInsuranceCarrier As String
    Dim sInsuranceCarrierAmt1 As String
    Dim sInsuranceCarrierAmt2 As String
    Dim sStatus As String
    Dim sStatusDetail As String
    Dim sDescriptionLine As String
    Dim sAmount As String
    Dim nBilledStatus As enumBilledStatus
    Dim nPages As Integer
    Dim nSplitsProcessCnt As Integer
    Dim sPolicyNumber As String
    Dim sFinNumber As String
    Dim bSkipFinNumber As Boolean
    Dim nPatientSelectionRetries As Integer
    Dim nBilled As enumBilledStatus
    Dim sAddress As String

    'Loop through each record
    Do Until d.EOF_
        'If the record should be processed 'TODO check on this
        ' default to previous statuses
        sStatus = d("SK_Status")
        sStatusDetail = "StockAmp " & d("SK_StatusDetail")

        sBilledAmtDtl = vbNullString
        sBilledAmtDtl2 = vbNullString
        sTotalCharges = vbNullString
        sInsuranceCarrier = vbNullString
        sInsuranceCarrierAmt1 = vbNullString
        sInsuranceCarrierAmt2 = vbNullString
        sDescriptionLine = vbNullString
        sAmount = vbNullString
        nSplitsProcessCnt = 0
        sPolicyNumber = vbNullString
        sFinNumber = vbNullString
        nPages = 0
        nPatientSelectionRetries = 0

        Logging "Reading account information from SMSNet for the account " & d("Account Number")

        'Instantiates object and sets Datastation Columns array for Output file
        Set oDataSMSNet = New cDataSMSNet
        StartProcessingTime = Now
        If d("SK_Status") = "GOOD" Then

            'If the record is valid
            If oDataSMSNet.IsValid Then

            'If d("Account Number") = "87257762" Then Stop

                ' make sure you are on the patient selection criteria screen
RetryPatientSelectionCriteria:
                lStartTime = Timer
                Do
                    Wait 0.5
                    DoEvents_
                    If InStr(View(Row:=1, Col:=3, length:=26), "PATIENT SELECTION CRITERIA") > 0 Then
                        DoEvents_
                        Exit Do
                    End If
                    If Timer >= lStartTime + goConfig.WebTimeout + 20 Then
                        Err.Raise seTimeOut, procName, "PATIENT SELECTION CRITERIA did not appear within timeout period."
                    End If
                Loop

                ' type in account number
                Pause "@5,27"
                Key d("Account Number")
                Key "{ENTER}"

                ' make sure you are on the patient overview screen
                lStartTime = Timer
                Do
                    Wait 0.5
                    DoEvents_
                    If InStr(View(Row:=1, Col:=3, length:=16), "PATIENT OVERVIEW") > 0 Then
                        DoEvents_
                        Exit Do
                    Else
                        DoEvents_
                        If Timer >= lStartTime + goConfig.WebTimeout + 40 Then
                            Err.Raise seTimeOut, procName, "PATIENT OVERVIEW did not appear within timeout period."
                        End If
                    End If
                Loop

                'Under the I01 amount
                'should match the individual amounts
                'three alpha 3 num - 6 digits
                'two alpha 4 num - 6 digits

                ' patient demographic data
                Key "@1"
                ' make sure you are on the patient demographic data screen
                lStartTime = Timer
                Do
                    Wait 0.5
                    DoEvents_
                    If InStr(View(Row:=1, Col:=3, length:=24), "PATIENT DEMOGRAPHIC DATA") > 0 Then
                        DoEvents_
                        Exit Do
                    End If
                    If Timer >= lStartTime + goConfig.WebTimeout Then
                        Err.Raise seTimeOut, procName, "PATIENT DEMOGRAPHIC DATA did not appear within timeout period."
                    End If
                Loop


                ' first name
                If View(Row:=12, Col:=2, length:=6) = "PT LN:" Then
                    d("SMS_Patient_Last_name") = Trim(View(Row:=12, Col:=9, length:=36))
                    If Len(d("SMS_Patient_Last_name")) <= 0 Then
                        ' could not read last name
                        sStatus = Status_BSS_REVIEW
                        sStatusDetail = "could not read last name"
                        GoTo NextRow
                    End If
                Else
                    ' could not read first name
                    sStatus = Status_BSS_REVIEW
                    sStatusDetail = "could not read first name column header"
                    GoTo NextRow
                End If

                ' first name
                If View(Row:=12, Col:=45, length:=3) = "FN:" Then
                    d("SMS_Patient_First_name") = Trim(View(Row:=12, Col:=49, length:=26))
                    If Len(d("SMS_Patient_First_name")) <= 0 Then
                        ' could not read first name
                        sStatus = Status_BSS_REVIEW
                        sStatusDetail = "could not read first name"
                        GoTo NextRow
                    End If
                Else
                    ' could not read first name
                    sStatus = Status_BSS_REVIEW
                    sStatusDetail = "could not read first name column header"
                    GoTo NextRow
                End If

                ' date of birth
                If View(Row:=6, Col:=2, length:=10) = "BIRTHDATE:" Then
                    d("SMS_Patient_Birth_Date") = Trim(View(Row:=6, Col:=18, length:=10))
                    If Len(d("SMS_Patient_Birth_Date")) <= 0 Then
                        ' could not read birth date
                        sStatus = Status_BSS_REVIEW
                        sStatusDetail = "could not read date of brith date"
                        GoTo NextRow
                    End If
                Else
                    ' could not read date of birth
                    sStatus = Status_BSS_REVIEW
                    sStatusDetail = "could not read date of birth column header"
                    GoTo NextRow
                End If

                ' gender
                If View(Row:=7, Col:=2, length:=12) = "SEX/MARITAL:" Then
                    d("SMS_Patient_Gender") = Trim(View(Row:=7, Col:=18, length:=1))
                    If Len(d("SMS_Patient_Gender")) <= 0 Then
                        ' could not read gender
                        sStatus = Status_REVIEW
                        sStatusDetail = "could not read gender"
                        GoTo NextRow
                    End If
                Else
                    If View(Row:=7, Col:=2, length:=4) = "SEX:" Then
                        d("SMS_Patient_Gender") = Trim(View(Row:=7, Col:=18, length:=1))
                        If Len(d("SMS_Patient_Gender")) <= 0 Then
                            ' could not read gender
                            sStatus = Status_REVIEW
                            sStatusDetail = "could not read gender"
                            GoTo NextRow
                        End If
                    Else
                        ' could not read gender
                        sStatus = Status_BSS_REVIEW
                        sStatusDetail = "could not read gender column header"
                        GoTo NextRow
                    End If
                End If

                ' address
                If View(Row:=13, Col:=2, length:=10) = "ADDRESS 1:" Then
                    sAddress = vbNullString
                    sAddress = Trim(View(Row:=13, Col:=13, length:=41))
                    sAddress = ReformatAddress(sAddress)
                    d("SMS_Patient_Address_Line_1") = sAddress    'Trim(View(Row:=13, Col:=13, length:=41))
                    If Len(d("SMS_Patient_Address_Line_1")) <= 0 Then
                        sStatus = Status_BSS_REVIEW
                        sStatusDetail = "could not read address 1"
                        GoTo NextRow
                    End If
                Else
                    sStatus = Status_BSS_REVIEW
                    sStatusDetail = "could not read address 1 column header"
                    GoTo NextRow
                End If
                If View(Row:=14, Col:=2, length:=10) = "ADDRESS 2:" Then
                    sAddress = vbNullString
                    sAddress = Trim(View(Row:=14, Col:=13, length:=41))
                    sAddress = ReformatAddress(sAddress)
                    d("SMS_Patient_Address_Line_2") = sAddress    'Trim(View(Row:=14, Col:=13, length:=41))
                    '                    If Len(d("SMS_Patient_Address_Line_2")) <= 0 Then
                    '                        sStatus = Status_REVIEW
                    '                        sStatusDetail = "could not read address 2"
                    '                        GoTo NextRow
                    '                    End If
                Else
                    sStatus = Status_BSS_REVIEW
                    sStatusDetail = "could not read address 2 column header"
                    GoTo NextRow
                End If

                ' city
                If View(Row:=15, Col:=2, length:=5) = "CITY:" Then
                    d("SMS_Patient_Address_City") = Trim(View(Row:=15, Col:=13, length:=32))
                    If Len(d("SMS_Patient_Address_City")) <= 0 Then
                        ' could not read city
                        sStatus = Status_REVIEW
                        sStatusDetail = "could not read city"
                        GoTo NextRow
                    End If
                Else
                    ' could not read city
                    sStatus = Status_BSS_REVIEW
                    sStatusDetail = "could not read city column header"
                    GoTo NextRow
                End If

                ' state
                If View(Row:=15, Col:=45, length:=11) = "STATE/PROV:" Then
                    d("SMS_Patient_Address_State") = Trim(View(Row:=15, Col:=58, length:=2))
                    If Len(d("SMS_Patient_Address_State")) <= 0 Then
                        ' could not read state
                        sStatus = Status_REVIEW
                        sStatusDetail = "could not read state"
                        GoTo NextRow
                    End If
                Else
                    ' could not read state
                    sStatus = Status_BSS_REVIEW
                    sStatusDetail = "could not read state column header"
                    GoTo NextRow
                End If
                ' zip
                If View(Row:=15, Col:=62, length:=7) = "ZIP CD:" Then
                    d("SMS_Patient_Address_Zip") = Trim(View(Row:=15, Col:=71, length:=5))
                    If Len(d("SMS_Patient_Address_Zip")) <= 0 Then
                        sStatus = Status_REVIEW
                        sStatusDetail = "ZIP is blank/null"
                        GoTo NextRow
                    End If
                Else
                    sStatus = Status_BSS_REVIEW
                    sStatusDetail = "could not read zip cd column header"
                    GoTo NextRow
                End If

                ' return to patient overview
                Key "@f"
                ' make sure you are on the patient overview screen
                lStartTime = Timer
                Do
                    Wait 0.5
                    DoEvents_
                    If InStr(View(Row:=1, Col:=3, length:=16), "PATIENT OVERVIEW") > 0 Then
                        DoEvents_
                        Exit Do
                    End If
                    If Timer >= lStartTime + goConfig.WebTimeout + 40 Then
                        Err.Raise seTimeOut, procName, "PATIENT OVERVIEW did not appear within timeout period."
                    End If
                Loop

                ' "@3"
                Key "@3"
                ' make sure you are on the patient insurance data screen
                lStartTime = Timer
                Do
                    Wait 0.5
                    DoEvents_
                    If InStr(View(Row:=1, Col:=3, length:=22), "PATIENT INSURANCE DATA") > 0 Then
                        DoEvents_
                        Exit Do
                    End If
                    If Timer >= lStartTime + goConfig.WebTimeout Then
                        Err.Raise seTimeOut, procName, "PATIENT INSURANCE DATA did not appear within timeout period."
                    End If
                Loop

                ' policy number ( member id )
                bSkipFinNumber = False
                If View(Row:=8, Col:=1, length:=10) = "POLICY NO:" Then
                    sPolicyNumber = Trim(View(Row:=8, Col:=13, length:=22))
                    sPolicyNumber = Replace(sPolicyNumber, " ", "")
                    If AllSameChars(sPolicyNumber) Then
                        If sPolicyNumber = "___________" Then
                            ' keep going, look for fin number
                        Else
                            sStatus = Status_REVIEW
                            sStatusDetail = "policy number may not be valid ." & sPolicyNumber
                            GoTo NextRow
                        End If
                    Else
                        d("SMS_Policy_Number") = sPolicyNumber    ' IIf(IsNumeric(Trim(View(Row:=8, Col:=13, length:=22))), Trim(View(Row:=8, Col:=13, length:=22)), "")
                        'If Not IsNumeric(sPolicyNumber) Then
                         'bSkipFinNumber = True
                        'End If
                    End If
                    '                    If Len(d("SMS_Policy_Number")) <= 0 Then
                    '                        sStatus = Status_REVIEW
                    '                        sStatusDetail = "could not read policy number"
                    '                        GoTo NextRow
                    '                    End If
                Else
                    sStatus = Status_BSS_REVIEW
                    sStatusDetail = "could not read policy number column header"
                    GoTo NextRow
                End If

                ' guarantor number
                ' fin number ( medicaid/ cin id )
                If sPolicyNumber = "___________" Then
                    bSkipFinNumber = False
                Else
                    If (d("Carrier Code") = "I001" Or d("Carrier Code") = "J001") Then
                        ' affinity
                        ' keep going
                        If IsNumeric(sPolicyNumber) Then
                            ' good keep going
                            bSkipFinNumber = True
                        Else
                            bSkipFinNumber = False
                        End If
                    Else
                        ' keep going
                        bSkipFinNumber = True
                    End If
                End If
                If Not bSkipFinNumber Then
                    If View(Row:=16, Col:=44, length:=12) = "SUPL GRP ID:" Then
                        sFinNumber = Trim(View(Row:=16, Col:=59, length:=20))
                        sFinNumber = Replace(sFinNumber, " ", "")
                        If AllSameChars(sFinNumber) Then    'IIf(IsNumeric(Trim(View(Row:=16, Col:=59, length:=20))), Trim(View(Row:=16, Col:=59, length:=20)), "")
                            sStatus = Status_REVIEW
                            sStatusDetail = "FIN number may not be valid ." & sFinNumber
                            GoTo NextRow
                        Else
                            d("SMS_Fin_Number") = sFinNumber
                        End If
                        If Len(d("SMS_Fin_Number")) <= 0 Then
                            sStatus = Status_REVIEW
                            sStatusDetail = "could not read SUPL GRP ID/FIN number"
                            GoTo NextRow
                        End If
                    Else
                        sStatus = Status_BSS_REVIEW
                        sStatusDetail = "could not read SUPL GRP ID column header"
                        GoTo NextRow
                    End If
                End If

                If Len(d("SMS_Fin_Number")) <= 0 And Len(d("SMS_Policy_Number")) <= 0 Then
                    sStatus = Status_REVIEW
                    sStatusDetail = "POLICY NO/SUPL GRP ID is blank"
                    GoTo NextRow
                End If


                ' date of service begin ( reg date )
                If View(Row:=3, Col:=1, length:=4) = "REG:" Then
                    d("SMS_DateOfServiceFrom") = Trim(View(Row:=3, Col:=5, length:=9))
                    If Len(d("SMS_DateOfServiceFrom")) <= 0 Then
                        ' could not read registered date
                        sStatus = Status_REVIEW
                        sStatusDetail = "could not read registered date"
                        GoTo NextRow
                    End If
                Else
                    If View(Row:=4, Col:=1, length:=4) = "REG:" Then
                        d("SMS_DateOfServiceFrom") = Trim(View(Row:=4, Col:=5, length:=9))
                        If Len(d("SMS_DateOfServiceFrom")) <= 0 Then
                            ' could not read registered date
                            sStatus = Status_REVIEW
                            sStatusDetail = "could not read registered date"
                            GoTo NextRow
                        End If
                    Else
                        ' could not read registered date
                        sStatus = Status_BSS_REVIEW
                        sStatusDetail = "could not read registered date column header"
                        GoTo NextRow
                    End If
                End If
                ' date of service end ( disch date )
                If View(Row:=3, Col:=16, length:=5) = "DSCH:" Then
                    d("SMS_DateOfServiceTo") = Trim(View(Row:=3, Col:=21, length:=12))
                    If Len(d("SMS_DateOfServiceTo")) <= 0 Then
                        ' could not read discharge date
                        '                        sStatus = Status_REVIEW
                        '                        sStatusDetail = "could not read discharge date to"
                        '                        GoTo NextRow
                    End If
                Else
                    If View(Row:=4, Col:=16, length:=5) = "DSCH:" Then
                        d("SMS_DateOfServiceTo") = Trim(View(Row:=4, Col:=21, length:=12))
                        If Len(d("SMS_DateOfServiceTo")) <= 0 Then
                            ' could not read discharge date
                            '                            sStatus = Status_REVIEW
                            '                            sStatusDetail = "could not read discharge date to"
                            '                            GoTo NextRow
                        End If
                    Else
                        ' could not read discharge date
                        sStatus = Status_BSS_REVIEW
                        sStatusDetail = "could not read discharge date column header"
                        GoTo NextRow
                    End If
                End If

                If Len(d("SMS_DateOfServiceTo")) <= 0 And Len(d("SMS_DateOfServiceFrom")) <= 0 Then
                    sStatus = Status_BSS_REVIEW
                    sStatusDetail = "DATE OF SERVICE FROM/DATE OF SERVICE TO is blank"
                    GoTo NextRow
                End If

                ' return to patient overview
                Key "@f"
                ' make sure you are on the patient overview screen
                lStartTime = Timer
                Do
                    Wait 0.5
                    DoEvents_
                    If InStr(View(Row:=1, Col:=3, length:=16), "PATIENT OVERVIEW") > 0 Then
                        DoEvents_
                        Exit Do
                    End If
                    If Timer >= lStartTime + goConfig.WebTimeout + 40 Then
                        Err.Raise seTimeOut, procName, "PATIENT OVERVIEW did not appear within timeout period."
                    End If
                Loop

                Key "@7"

                ' make sure you are on the account detail data screen
                lStartTime = Timer
                Do
                    Wait 0.5
                    DoEvents_
                    If InStr(View(Row:=1, Col:=3, length:=19), "ACCOUNT DETAIL DATA") > 0 Then
                        DoEvents_
                        Exit Do
                    End If
                    If Timer >= lStartTime + goConfig.WebTimeout Then
                        Err.Raise seTimeOut, procName, "ACCOUNT DETAIL DATA did not appear within timeout period."
                    End If
                Loop

                ' go to the last page
                lStartTime = Timer
                Do
                    Wait 0.5
                    DoEvents_
                    If InStr(View(Row:=24, Col:=2, length:=21), "THIS IS THE LAST PAGE") > 0 Then
                        DoEvents_
                        Exit Do
                    Else
                        Key "@9"
                    End If
                    If Timer >= lStartTime + goConfig.WebTimeout Then
                        Err.Raise seTimeOut, procName, "THIS IS THE LAST PAGE did not appear within timeout period."
                    End If
                Loop

                ' header row
                '     SVC    POST   SVC CD   DESCRIPTION/COMMENT-REF DATE         AMOUNT      BALANCE
                ' footer row
                ' --------------------------------------------------------------------------------
                ' read last line, move up until the criteria is met, probably look at last two pages?
                ' column
                ' DESCRIPTION/COMMENT-REF DATE
                ' service date
                ' post date
                ' description/comment-ref date
                ' service date > reg date?
                ' scan the history information to determine if a Bill was generated.

                'Determine the primary insurance based on the information in the Siemens system
                'Dollar amount ( or some of the dollar amounts in case of split claims should match the amount displayed under the insurance carrier ). If could not find, mark it as exception and send it for review.
                bFound = False
                Do

                    If View(Row:=20, Col:=1, length:=80) = "--------------------------------------------------------------------------------" And View(Row:=9, Col:=1, length:=80) = "  SVC    POST   SVC CD   DESCRIPTION/COMMENT-REF DATE        AMOUNT     BALANCE " Then
                        ' move on to the previous line
                        For iRowNum = 19 To 9 Step -1
                            ' reached header
                            sAmount = vbNullString
                            If View(Row:=iRowNum, Col:=1, length:=80) = "  SVC    POST   SVC CD   DESCRIPTION/COMMENT-REF DATE        AMOUNT     BALANCE " Then
                                ' move on to previous page
                                Key "@6"
                                DoEvents_

                                ' if it is the first page, exit loop
                                Wait 0.5
                                DoEvents_
                                If InStr(View(Row:=24, Col:=2, length:=25), "THERE IS NO PREVIOUS PAGE") > 0 Then
                                    DoEvents_
                                    Exit Do
                                End If

                                'Exit For
                            End If

                            nBilled = 0
                            ' first two or 3 chars alpha, next 3 or 4 chars numeric, rest amount, L - paper bill, E - electronic
                            ' strip userid out/appbridgeout
                            sDescriptionLine = Trim(View(Row:=iRowNum, Col:=26, length:=36))
                            If Len(sDescriptionLine) > 0 Then
                                If IsBilled(sDescriptionLine, sAmount, nBilled) And val(sAmount) > 0 Then
                                    ' svc date
                                    d("SMS_DateOfService_Dtl") = Trim(View(Row:=iRowNum, Col:=2, length:=6))
                                    ' post date
                                    d("SMS_DateOfPost_Dtl") = Trim(View(Row:=iRowNum, Col:=9, length:=6))

                                    If Len(sAmount) > 0 Then
                                        If Len(sBilledAmtDtl) <= 0 Then
                                            sBilledAmtDtl = sAmount
                                            nSplitsProcessCnt = iRowNum - 1
                                            If nSplitsProcessCnt = 9 Then
                                                nSplitsProcessCnt = 19
                                            End If
                                        Else
                                            sBilledAmtDtl2 = sAmount
                                        End If
                                        If Not bFound Then
                                            bFound = True
                                        End If
                                    End If
                                    If Len(sAmount) <= 0 Then
                                        sStatus = Status_REVIEW
                                        sStatusDetail = "Did not find amount"
                                        GoTo NextRow
                                    End If
                                End If
                            End If
                            ' check one row above for split claims
                            If nSplitsProcessCnt = iRowNum Then
                                ' split claims looked for
                                Exit Do
                            End If
                        Next iRowNum
                    Else
                        ' could not read grid
                        ' mark status review boston
                        sStatus = Status_BSS_REVIEW
                        sStatusDetail = "Could not read header or footer row on the ACCOUNT DETAIL DATA screen."
                        GoTo NextRow
                    End If

                    ''                    ' if it is the first page, exit loop
                    ''                    Wait 0.5
                    ''                    DoEvents_
                    ''                    If InStr(View(Row:=24, Col:=2, length:=25), "THERE IS NO PREVIOUS PAGE") > 0 Then
                    ''                        DoEvents_
                    ''                        Exit Do
                    ''                    End If

                    nPages = nPages + 1
                    ''                    If nPages > 100 Then
                    ''                        to do test this or remove later
                    ''                    End If
                Loop

                If bFound Then
                    sStatus = "GOOD"
                    sStatusDetail = "Good sample work on this"
                    If val(sBilledAmtDtl2) < val(sBilledAmtDtl) Then
                        'd("SMS_BilledAmt_Dtl_2") = sBilledAmtDtl2
                        d("SMS_BilledAmt_Dtl_1") = sBilledAmtDtl
                    Else
                        'd("SMS_BilledAmt_Dtl_2") = sBilledAmtDtl
                        d("SMS_BilledAmt_Dtl_1") = sBilledAmtDtl2
                    End If

                    ' determine the insurance carrier
                    ' sum of split claim amounts should be equal to the amounts shown below the insurnace carrier.
                    ' ignore the smaller amount in case of split claims.

                    If View(Row:=6, Col:=6, length:=8) = "ACCT BAL" Then
                        ' keep going
                    Else
                        ' could not read insurance amounts/ account balance
                        sStatus = Status_BSS_REVIEW
                        sStatusDetail = "could not read acct bal column header"
                        GoTo NextRow
                    End If

                    ' insurance carrier 1
                    sInsuranceCarrier = vbNullString
                    sInsuranceCarrierAmt1 = Trim(View(Row:=7, Col:=18, length:=10))
                    sInsuranceCarrierAmt2 = Trim(View(Row:=7, Col:=33, length:=8))
                    'If (val(sInsuranceCarrierAmt1) = val(sBilledAmtDtl2) + val(sBilledAmtDtl)) And val(sInsuranceCarrierAmt1) > 0 Then
                    If val(sInsuranceCarrierAmt1) > 0 Then
                        sInsuranceCarrier = Trim(View(Row:=6, Col:=18, length:=10))
                        If Len(sInsuranceCarrier) <= 0 Then
                            ' todo test this
                            sStatus = Status_BSS_REVIEW
                            sStatusDetail = "could not read carrier insurance carrier"
                            GoTo NextRow
                        End If
                        d("SMS_Insurance_Carrier1") = StrWord(sInsuranceCarrier, 1, " ")
                        If d("SMS_Insurance_Carrier1") = vbNullString Then
                            ' todo test this
                            sStatus = Status_BSS_REVIEW
                            sStatusDetail = "could not read carrier insurance carrier"
                            GoTo NextRow
                        End If
                        'ElseIf (val(sInsuranceCarrierAmt2) = val(sBilledAmtDtl2) + val(sBilledAmtDtl)) And val(sInsuranceCarrierAmt2) > 0 Then
                    ElseIf val(sInsuranceCarrierAmt2) > 0 Then
                        sInsuranceCarrier = Trim(View(Row:=6, Col:=33, length:=7))
                        d("SMS_Insurance_Carrier1") = StrWord(sInsuranceCarrier, 1, " ")
                        If d("SMS_Insurance_Carrier1") = vbNullString Then
                            sStatus = Status_BSS_REVIEW
                            sStatusDetail = "could not read insurance carrier"
                            GoTo NextRow
                        End If
                    Else
                        ' mark status review
                        sStatus = Status_REVIEW
                        sStatusDetail = "Could not find insurance carrier id/insurance carrier amount."
                        'sStatusDetail = "Billed amount did not match with the amount documented above the insurance carrier id. " & sBilledAmtDtl & "/" & sBilledAmtDtl2 & "(" & sInsuranceCarrierAmt1 & "/" & sInsuranceCarrierAmt2 & ")"
                        GoTo NextRow
                    End If
                End If

                If Not bFound Then
                    ' mark review status and move onto the next row
                    sStatus = Status_REVIEW
                    sStatusDetail = "Account is not APPBRIDGED/PAPER BILLED. Please review manually. Descript is " & sDescriptionLine
                    Select Case nBilled
                    Case eBILLED_PAPER
                        sStatusDetail = "PAPER BILLED. Please review manually."
                    Case eBILLED_UNKNOWN
                        sStatusDetail = "It is not either APPBRIDGE or PAPER billed. Please review manually."
                    End Select
                    GoTo NextRow
                End If
            End If

        End If    'd("SK_Status")
NextRow:
        '                    If sStatusDetail <> "StockAmp STAT account information has rows other than activity code of INIT and worked by of SYS-System Rep" Then
        '                    End If
        oDataSMSNet.UpdateStatus sStatus, sStatusDetail
        'Clean-up
        Set oDataSMSNet = Nothing

        ' navigate to patient selection criteria screen
        Key "@e"
        DoEvents_

        ' make sure you are on the patient selection criteria screen
        lStartTime = Timer
        Do
            Wait 0.5
            DoEvents_
            If InStr(View(Row:=1, Col:=3, length:=26), "PATIENT SELECTION CRITERIA") > 0 Then
                DoEvents_
                Exit Do
            Else
                Key "@e"
                DoEvents_
            End If
            If Timer >= lStartTime + goConfig.WebTimeout Then
                Err.Raise seTimeOut, procName, "Application did not appear within timeout period."
            End If
        Loop

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
    GeneralErrorHandler Err.Number, Err.Description, Err.Source, msModule & "." & procName
End Sub


Sub SMSNetReadData()
    On Error GoTo ErrorHandler: Const procName = "SMSNetReadData"
    Dim sMessage As String
    If Not LaunchAndConnect Then
        sMessage = "Please check if the credentials in the setup file are valid. Also please look at the log file for more information"
        GoTo CleanUp
    End If

    If Not Login Then
        sMessage = "Please check if the credentials in the setup file are valid. Also please look at the log file for more information"
        CloseSMSNet
        GoTo CleanUp
    End If

    'open and process the input file/input record source
    GetSMSNETData
    ' clean up any objects
    CloseSMSNet

    Exit Sub
CleanUp:
    'CloseApp
    Logging "ERROR:" & " Please check if the credentials(username/password) in the setup file are valid."
    SendFatalError2 goConfig, sMessage
    Shutdown = True    ' use this if project is scheduled using Windows Task Scheduler TODO
    Exit Sub
ErrorHandler:
    If DebugMode Then
        Debug.Print "Error in " & msModule & "." & procName & ":" & Err.Number & ":" & Err.Description
        Stop
        Resume
    End If
    GeneralErrorHandler Err.Number, Err.Description, Err.Source, msModule & "." & procName
End Sub

Sub UpdateSMSStockampAccountData()
    On Error GoTo ErrorHandler: Const procName = "UpdateSMSStockampAccountData"
    
    KillAnyAppsOpen

    ' launch and login into SMSnet
    If Not LaunchAndConnect Then
        'sMessage = "Please check if the credentials in the setup file are valid. Also please look at the log file for more information"
        GoTo CleanUp
    End If

    If Not Login Then
        'sMessage = "Please check if the credentials in the setup file are valid. Also please look at the log file for more information"
        CloseSMSNet
        GoTo CleanUp
    End If

    ' Launch and login into Stockamp
    LaunchAndLoginStockamp

    'open and process the input file/input record source
    UpdateAccountData
    ' clean up any objects
    CloseSMSNet
    ' close stockamp
    Logout_IE2_Stockamp

    LogMessage "Updates made to SMSNet and Stockamp applications."

    Note = vbCrLf & goConfig.ProjectName & " Project Completed."

    SendSuccessEMail "Brookhaven Automation completed."

    ' clean up any objects
    WrapUp

    Shutdown = True    ' use this if project is scheduled using Windows Task Scheduler TODO

    Exit Sub
CleanUp:
    '    CloseApp
    Logging "ERROR:" & " Please check if the credentials(username/password) in the setup file are valid."
    'SendFatalError2 goConfig, sMessage
    Shutdown = True    ' use this if project is scheduled using Windows Task Scheduler TODO
    Exit Sub
ErrorHandler:
    If DebugMode Then
        Debug.Print "Error in " & msModule & "." & procName & ":" & Err.Number & ":" & Err.Description
        Stop
        Resume
    End If
    GeneralErrorHandler Err.Number, Err.Description, Err.Source, msModule & "." & procName
End Sub


Function LaunchAndConnect() As Boolean
    Dim lStartTime As Long

    On Error GoTo ErrorHandler: Const procName = "LaunchAndConnect"

    LaunchAndConnect = False
    Shell_ goConfig.SMSNetExe
    Wait
    TimeOut = goConfig.WebTimeout
    Connect goConfig.SMSNetLoginCaption, stRumba
    TimeOut = goConfig.WebTimeout

    lStartTime = Timer
    Do
        If InStr(View(Row:=6, Col:=1, length:=15), "SIGNON:") > 0 Then
            DoEvents_
            Exit Do
        End If
        If Timer >= lStartTime + goConfig.WebTimeout + 120 Then
            Err.Raise seTimeOut, procName, "SIGNON did not appear within timeout period."
        Else
            Connect goConfig.SMSNetLoginCaption, stRumba
            TimeOut = goConfig.WebTimeout
        End If
    Loop
    LaunchAndConnect = True

    LogMessage "MODULE: " & msModule & "  SUB:" & procName & ":" & " end"

    Exit Function
ErrorHandler:
    Logging Err.Number & " " & "ERROR: MODULE: " & msModule & " SUB: " & procName & " : " & Err.Description
    GeneralErrorHandler Err.Number, Err.Description, Err.Source, msModule & "." & procName
    'Err.Raise Err.Number, "ERROR: MODULE: " & msModule & " SUB: " & procName & " : " & Err.Description
    'Resume
End Function

Sub CloseSMSNet(Optional bDummy As Boolean)
    On Error GoTo errh: Const procName = "CloseSMSNet"

    If IsWindowEx("SMSNET - Micro Focus Rumba") Then
        CloseApplication "SMSNET - Micro Focus Rumba"
    End If

    Exit Sub
errh:
    '    dbg "CloseSMSNet", Err.Number, Err.Description, Status
    Err.Raise Err.Number, procName, Err.Description & Err.Source
End Sub

Private Function Login() As Boolean
    On Error GoTo ErrorHandler: Const procName = "Login"
    Dim lStartTime As Long

    Login = False
    'UN:
    On Error GoTo ErrorHandler:

    ' Logon ID
    Pause "@6,11"
    Key goConfig.SMSUserName
    'Key "@T"
    'Tab_ ""

    ' Password
    Pause "@9,11"
    Key goConfig.SMSPassword
    'Tab_ ""

    ' click enter key
    Key "@E"
    'Key "{ENTER}"

    ' wait to load (takes a long time)
    lStartTime = Timer
    Do
        Wait 0.5
        DoEvents_
        If InStr(View(Row:=1, Col:=3, length:=19), "GENERAL MASTER MENU") > 0 Then
            DoEvents_
            Exit Do
        End If
        If Timer >= lStartTime + goConfig.WebTimeout Then
            Err.Raise seTimeOut, procName, "GENERAL MASTER MENU did not appear within timeout period."
        End If
    Loop

    Login = True
    Exit Function
ErrorHandler:
    Logging "Login " & Err.Number & " " & Err.Description & " " & Status
    Logging "Login : Please check username and password in the setup file"
    GeneralErrorHandler Err.Number, Err.Description, Err.Source, msModule & "." & procName
    'Err.Raise Err.Number, "Login", Err.Description & Status
    'Resume    'todo delete later
End Function

Private Function IsBilled(sDescription As String, sAmount As String, nBilled As enumBilledStatus) As Boolean
    On Error GoTo ErrorHandler: Const procName = "IsBilled"
    'Look for keyword APPBRIDGE.
    'If you see E at the end of the dollar amount, it is electronically processed and continue with workflow steps.
    'If you see L at the end of the dollar amount, it is paper billed and mark it as an exception.
    'Look for a userid (BH1234 or BHA123) pattern
    'First two or three characters of the 6 letter userid are alpha
    'Last three or four characters of the 6 letter userid are numeric

    Dim sFirst6Chars As String
    Dim sFirst9Chars As String

    IsBilled = False

    'sDescription = " BH123411,200.04M "
    'sDescription = "BHA2341,20.04E"
    'sDescription = "BHA2341,20.04L"
    'sDescription = " APPBRIDGE 2341,20.04L"
    'sDescription = " APPBRIDGE 2341,20.04E"

    sDescription = Replace(sDescription, " ", "")
    sDescription = Replace(sDescription, ",", "")

    If Len(sDescription) <= 6 Then
        ' no need to process this
        Exit Function
    End If

    sFirst6Chars = Mid(sDescription, 1, 6)
    sFirst9Chars = Mid(sDescription, 1, 9)



    If (TextPatterMatches(Mid(sFirst6Chars, 1, 2)) And NumberPatterMatches(Mid(sFirst6Chars, 3, 4)) Or _
        TextPatterMatches(Mid(sFirst6Chars, 1, 3)) And NumberPatterMatches(Mid(sFirst6Chars, 4, 3))) Or _
        sFirst9Chars = "APPBRIDGE" Then
        If sFirst9Chars = "APPBRIDGE" Then
            sAmount = Trim(Mid(sDescription, 10, Len(sDescription) - 9))
        Else
            sAmount = Trim(Mid(sDescription, 7, Len(sDescription) - 6))
        End If
        If Mid(sAmount, Len(sAmount), 1) = "L" Then
            nBilled = eBILLED_PAPER
        ElseIf Mid(sAmount, Len(sAmount), 1) = "E" Then
            nBilled = eBILLED_ELECTRONIC
        Else
            nBilled = eBILLED_UNKNOWN
            Exit Function
        End If
        sAmount = RemoveAlpha(sAmount)
        If Len(sAmount) > 0 Then
            ' keep going
        Else
            Exit Function
        End If

        IsBilled = True
    Else
        IsBilled = False
    End If


    Exit Function
ErrorHandler:
    Logging "IsBilled " & Err.Number & " " & Err.Description & " " & Status
    Logging "IsBilled : Please check username and password in the setup file"
    GeneralErrorHandler Err.Number, Err.Description, Err.Source, msModule & "." & procName
End Function

' input comment text
Function SMS_KeyComment(commentText As String) As Boolean
    Dim remainingText As String
    Dim oneCharacter As String
    Dim workingText As String
    Dim i As Long

    On Error GoTo ErrorHandler: Const procName = "SMS_KeyComment"

    SMS_KeyComment = False
    remainingText = commentText

    ' four comment lines, once the four lines are filled-in, four more would show.
    Do
        If Len(remainingText) <= 41 Then
            If nCurrentCommentLineNbr = 5 Then
                nCurrentCommentLineNbr = 1
                ' open next 4 comment lines and set the cursor position to the first comment line.
                Key "{ENTER}"
                If PauseForPressEnterComments Then
                    Key "{ENTER}"
                    If PauseForPressPostComments Then
                        ' keep going
                    Else
                        GoTo ErrorHandler
                    End If
                End If
            End If
            'MsgBox remainingText
            Key remainingText

            ' move the cursor to the next line
            ' TAB through 5 times
            Tab_ ""
            Tab_ ""
            Tab_ ""
            Tab_ ""
            Tab_ ""

            nCurrentCommentLineNbr = nCurrentCommentLineNbr + 1
            If nCurrentCommentLineNbr = 5 Then
                nCurrentCommentLineNbr = 1
                ' open next 4 comment lines and set the cursor position to the first comment line.
                Key "{ENTER}"
                If PauseForPressEnterComments Then
                    Key "{ENTER}"
                    If PauseForPressPostComments Then
                        ' keep going
                    Else
                        GoTo ErrorHandler
                    End If
                End If
            End If
            If nCurrentCommentLineNbr = 1 Then
                Pause "@16,5"
            ElseIf nCurrentCommentLineNbr = 2 Then
                Pause "@17,5"
            ElseIf nCurrentCommentLineNbr = 3 Then
                Pause "@18,5"
            ElseIf nCurrentCommentLineNbr = 4 Then
                Pause "@19,5"
            End If

            Exit Do
        End If

        ' word wrap
        workingText = Mid$(remainingText, 1, 41)    ' get a 41 character string of text - that is total # char of comment line in SMS
        For i = Len(workingText) To 1 Step -1   ' work backwards a space
            oneCharacter = Mid$(workingText, i, 1)
            If oneCharacter = " " Then          ' found a space
                'Key Mid$(workingText, 1, i)
                If nCurrentCommentLineNbr = 5 Then
                    nCurrentCommentLineNbr = 1
                    ' open next 4 comment lines and set the cursor position to the first comment line.
                    Key "{ENTER}"
                    If PauseForPressEnterComments Then
                        Key "{ENTER}"
                        If PauseForPressPostComments Then
                            ' keep going
                        Else
                            GoTo ErrorHandler
                        End If
                    End If
                End If

                'MsgBox Mid$(workingText, 1, i)
                Key Mid$(workingText, 1, i)

                'Key "@A@E"    ' field exit
                remainingText = Mid$(remainingText, i + 1, Len(remainingText))
                ' move the cursor to the next line
                ' TAB through 5 times
                Tab_ ""
                Tab_ ""
                Tab_ ""
                Tab_ ""
                Tab_ ""
                nCurrentCommentLineNbr = nCurrentCommentLineNbr + 1
                If nCurrentCommentLineNbr = 1 Then
                    Pause "@16,5"
                ElseIf nCurrentCommentLineNbr = 2 Then
                    Pause "@17,5"
                ElseIf nCurrentCommentLineNbr = 3 Then
                    Pause "@18,5"
                ElseIf nCurrentCommentLineNbr = 4 Then
                    Pause "@19,5"
                End If

                Exit For
            End If
        Next
    Loop

    '    ' put CONT>>> on bottom right
    '    If continued Then
    '        Do Until Row = 20
    '            Key "@V"    ' down arrow
    '        Loop
    '        If Col < 70 Then
    '            Do Until Col = 70
    '                Key "@Z"    ' right arrow
    '            Loop
    '        Else
    '            Do Until Col = 70
    '                Key "@L"    ' left arrow
    '            Loop
    '        End If
    '        Key "CONT>>>"
    '    End If

    SMS_KeyComment = True

ProcExit:
    Exit Function
ErrorHandler:
    SMS_KeyComment = False
    GeneralErrorHandler Err.Number, Err.Description, Err.Source, msModule & "." & procName
    'GeneralErrorHandler Err.Number, Err.Description, "SMS_KeyComment", Err.Description
    'Resume ProcExit
End Function

Sub SMSInitializeStatus(ByRef sStatus As String, ByRef sStatusDetail As String)
' todo add other insurance carriers
    If d("SK_Status") <> "GOOD" Then
        sStatus = d("SK_Status")
        sStatusDetail = "SK " & d("SK_StatusDetail")
    ElseIf d("SMS_Status") <> "GOOD" Then
        sStatus = d("SMS_Status")
        sStatusDetail = "SMS " & d("SMS_StatusDetail")
    ElseIf (d("HealthFirst_Status") <> "GOOD") And (d("SMS_Insurance_Carrier1") = "I04" Or d("SMS_Insurance_Carrier1") = "J14" Or d("Carrier Code") = "I004" Or d("Carrier Code") = "J014") Then
        sStatus = d("HealthFirst_Status")
        sStatusDetail = "HF " & d("HealthFirst_StatusDetail")
    ElseIf (d("OPTUM_Status") <> "GOOD") And (d("SMS_Insurance_Carrier1") = "I10" Or d("SMS_Insurance_Carrier1") = "J10" Or d("Carrier Code") = "I010" Or d("Carrier Code") = "J010" _
                                              Or d("SMS_Insurance_Carrier1") = "X22" Or d("SMS_Insurance_Carrier1") = "K15" Or d("Carrier Code") = "X022" Or d("Carrier Code") = "K015" _
                                              Or d("SMS_Insurance_Carrier1") = "E08" Or d("Carrier Code") = "E008") Then
        sStatus = d("OPTUM_Status")
        sStatusDetail = "OPTUM " & d("OPTUM_StatusDetail")
    ElseIf (d("AFMEDICAID_Status") <> "GOOD") And (d("SMS_Insurance_Carrier1") = "I01" Or d("Carrier Code") = "I001") Then
        sStatus = d("AFMEDICAID_Status")
        sStatusDetail = "AFMEDICAID " & d("AFMEDICAID_StatusDetail")
    End If
End Sub

Sub SMSNetLoginCheck()
    On Error GoTo ErrorHandler: Const procName = "SMSNetLoginCheck"
    Dim sMessage As String
    Dim sFileName As String

    If Not LaunchAndConnect Then
        'sMessage = "Please check if the credentials in the setup file are valid. Also please look at the log file for more information"
        GoTo CleanUp
    End If

    If Not Login Then
        sMessage = "Please check if the credentials in the setup file are valid. Also please look at the log file for more information"
        Wait 5
        CloseSMSNet
        GoTo CleanUp
    End If
    Wait 5

    'CloseSMSNet
    Exit Sub
CleanUp:
    '    CloseApp
    CloseSMSNet
    sFileName = TakeScreenshot2(goConfig.LogFolderPath)
    Logging "ERROR: Pls see screenshot - " & sFileName
    Logging "ERROR:" & " Please check if the credentials(username/password) in the setup file are valid."
    SendFatalError2 goConfig, sMessage
    Shutdown = True    ' use this if project is scheduled using Windows Task Scheduler TODO
    Exit Sub
ErrorHandler:
    GeneralErrorHandler Err.Number, Err.Description, Err.Source, msModule & "." & procName
End Sub

Function PauseForPressEnterComments() As Boolean
    Dim lStartTime As Long

    PauseForPressEnterComments = False
    lStartTime = Timer
    Do
        Wait 0.5
        DoEvents_
        Debug.Print View(Row:=24, Col:=2, length:=65)    ' TODO
        If InStr(View(Row:=24, Col:=2, length:=65), "PRESS ENTER") > 0 Then
            DoEvents_
            PauseForPressEnterComments = True
            Exit Do
        End If
        If Timer >= lStartTime + goConfig.WebTimeout Then
            Err.Raise seTimeOut, PauseForPressEnterComments, "PRESS ENTER is not found on Comments screen."
        End If
    Loop
End Function

Function PauseForPressPostComments() As Boolean
    Dim lStartTime As Long

    On Error GoTo ErrorHandler: Const procName = "PauseForPressPostComments"

    PauseForPressPostComments = False
    lStartTime = Timer
    Do
        Wait 0.5
        DoEvents_
        Debug.Print View(Row:=24, Col:=2, length:=70)    ' todo
        If InStr(View(Row:=24, Col:=2, length:=70), "TRANSACTION(S) POSTED") > 0 Then
            DoEvents_
            PauseForPressPostComments = True
            Exit Do
        End If
        If Timer >= lStartTime + goConfig.WebTimeout Then
            Err.Raise seTimeOut, "PauseForPressPostComments", "TRANSACTION(S) POSTED is not found on Comments screen."
        End If
    Loop
    Exit Function
ErrorHandler:
    GeneralErrorHandler Err.Number, Err.Description, Err.Source, msModule & "." & procName
End Function

Sub LaunchAndLoginStockamp()
    On Error GoTo ErrorHandler: Const procName = "LaunchAndLoginStockamp"

    Dim sFileName As String
    Dim nIERestarts As Integer

RestartIE:

    LogMessage "MODULE: " & msModule & " SUB: " & procName & " before the call to LanuchAndConnect_IE "
    gnConnectRetry = 0
    LaunchAndConnect_IE2 goConfig
    LogMessage "MODULE: " & msModule & " SUB: " & procName & " after the call to LanuchAndConnect_IE "
    Login_IE2_Stockamp goConfig.WebSiteName
    LogMessage "MODULE: " & msModule & " SUB: " & procName & " before the call to ProcessData "

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

Sub Login_IE2_Stockamp(sWebSiteName As String)
    On Error GoTo ErrorHandler: Const procName = "Login_IE2_Stockamp"
    Dim nConnectRetry As Integer
    ' moves to the top of the document
    B2.First

    ' login screen
    If Not B2.Web1.Find("Login Name") Then
        GoTo ErrorHandler
    End If

    ' input Login UserID
    B2.text("<INPUT>#txtLoginName#@Login - Stockamp & Associates") = goConfig.LoginUserID

    ' input Login Password
    B2.text("txtPassword<INPUT>#txtPassword#@Login - Stockamp & Associates") = goConfig.LoginPassword

    ' click on login Submit button
    B2.Pause "submit1<INPUT>#submit1#<#bttn_sized#>@Login - Stockamp & Associates"
    B2.Click "submit1<INPUT>#submit1#<#bttn_sized#>@Login - Stockamp & Associates"
    WaitForPage2
    WaitForPage2

    ' click Claims
    B2.Pause "STAT<A><#R_HL#>@Welcome - Stockamp & Associates QUIC - TRAC"
    B2.Click "STAT<A><#R_HL#>@Welcome - Stockamp & Associates QUIC - TRAC"
    WaitForPage2
    WaitForPage2
    Exit Sub
ErrorHandler:
    Err.Raise Err.Number, msModule & ": Workflow Sub: " & procName, Err.Description
End Sub

Sub Logout_IE2_Stockamp(Optional bDummy As Boolean)
    On Error GoTo ErrorHandler: Const procName = "Logout_IE2_Stockamp"

    B2.First

    LogMessage "MODULE: " & msModule & " SUB: " & procName & ":" & " before closing the IE"
    B2.Pause "Log Off System"
    B2.Web1.selected.Click

    WaitForPage2

    ' close Ineternet Explorer
    B2.Web1.WB.quit

    ' kill ie session
    Shell (Environ("Windir") & "\SYSTEM32\TASKKILL.EXE /F /IM IEXPLORE.EXE")
    Wait 5

    LogMessage "MODULE:" & msModule & " Workflow SUB: " & procName & ":" & " after closing the IE"

    Exit Sub

ErrorHandler:
    Logging "ERROR: MODULE:" & msModule & " Workflow Sub: " & procName & ": " & Err.Number & ":" & Err.Description
    GeneralErrorHandler Err.Number, Err.Description, Err.Source, msModule & "." & procName
End Sub


Sub InitializeStatus(ByRef sStatus As String, ByRef sStatusDetail As String)
' todo add other insurance carriers
    If d("SK_Status") <> "GOOD" Then
        sStatus = d("SK_Status")
        sStatusDetail = "SK " & d("SK_StatusDetail")
    ElseIf d("SMS_Status") <> "GOOD" Then
        sStatus = d("SMS_Status")
        sStatusDetail = "SMS " & d("SMS_StatusDetail")
    ElseIf d("HealthFirst_Status") <> "GOOD" Then
        sStatus = d("HealthFirst_Status")
        sStatusDetail = "HF " & d("HealthFirst_StatusDetail")
    ElseIf d("OPTUM_Status") <> "GOOD" Then
        sStatus = d("OPTUM_Status")
        sStatusDetail = "OPTUM " & d("OPTUM_StatusDetail")
    ElseIf d("AFMEDICAID_Status") <> "GOOD" Then
        sStatus = d("AFMEDICAID_Status")
        sStatusDetail = "AFMEDICAID " & d("AFMEDICAID_StatusDetail")
    End If
End Sub

Function HandlePopups_Stockcamp() As Boolean
    On Error GoTo ErrorHandler
    Dim lStartTime As Long
    Dim ssFilename As String

    HandlePopups_Stockcamp = False
    lStartTime = Timer
    Do
        DoEvents_
        If Timer >= lStartTime + 2 Then
            Logging "INFO: No Popup"
            Exit Function
        End If
        If GetPopupCaption = "Message from webpage" Then
            ssFilename = TakeScreenshot2(goConfig.LogFolderPath)
            Logging "ERROR: Unhandled Popup - " & GetPopupCaption & " - " & GetPopupText(GetPopupHandle), True
            Logging "       Please see screenshot '" & ssFilename & "'"
            B2.SmartDialog("Message from webpage", "OK<Push button>").Click
            HandlePopups_Stockcamp = True
            Wait 0.1
            Exit Function
        End If
        DoEvents
    Loop    ' Until PopupExists = False
    Exit Function
ErrorHandler:
    Logging "ERROR in 'HandlePopups_Stockcamp':" & Err.Number & ":" & Err.Description, True
End Function

