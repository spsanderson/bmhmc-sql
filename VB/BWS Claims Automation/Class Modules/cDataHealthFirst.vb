Option Explicit
Option Compare Text

Private Const ModuleName As String = "cDataHealthFirst"

Public IsLoaded As Boolean
Public NumOfBWSColumns As Long

Public Status As String
Public StatusDetail As String
Public ProcessingTime As Long
Private StartTime As Date

Private Sub Class_Initialize()
'Set the number of BWS-generated columns
' NOTE: Should always be 1+ the columns initialized below
    NumOfBWSColumns = 21    '8    'NOT USING

'Initialize BWS-generated columns (besides Status)
    d("HealthFirst_Status") = ""
    d("HealthFirst_StatusDetail") = ""

    ' healthfirst demographics
    d("Payor_ClaimNumber_1") = ""
    d("Payor_TotalCharges_1") = ""
    d("Payor_DateOfService_1") = ""
    d("Payor_ClaimReceivedDate_1") = ""
    d("Payor_PaidAmount_1") = ""
    d("Payor_CheckNumber_1") = ""
    d("Payor_ProcessedDate_1") = ""
    d("Payor_Paid_Issued_Date_1") = ""
    d("Payor_Claim_Status_1") = ""
    d("Payor_Patient_Full_Name_1") = ""
    d("Payor_Patient_First_name_1") = ""
    d("Payor_Patient_Last_name_1") = ""
    d("Payor_Patient_Middle_name_1") = ""
    d("Payor_Patient_Birth_Date_1") = ""
    d("Payor_Patient_Gender_1") = ""
    d("Payor_Patient_Address_Line_1_1") = ""
    d("Payor_Patient_Address_Line_2_1") = ""
    d("Payor_Patient_Address_City_1") = ""
    d("Payor_Patient_Address_State_1") = ""
    d("Payor_Patient_Address_Zip_1") = ""

    d("Payor_Comment_Lines") = ""
    d("Payor_Comment_Line_1_1") = ""
    d("Payor_Comment_Line_2_1") = ""
    d("Payor_Comment_Line_3_1") = ""
    d("Payor_Comment_Line_4_1") = ""
    d("Payor_Comment_Line_5_1") = ""
    d("Payor_Comment_Line_6_1") = ""
    d("Payor_Comment_Line_7_1") = ""
    d("Payor_Comment_Line_8_1") = ""
    d("Payor_Comment_Line_9_1") = ""
    d("Payor_Comment_Line_10_1") = ""
    d("Payor_Comment_Line_11_1") = ""
    d("Payor_Comment_Line_12_1") = ""

    d("Payor_ClaimNumber_2") = ""
    d("Payor_TotalCharges_2") = ""
    d("Payor_DateOfService_2") = ""
    d("Payor_ClaimReceivedDate_2") = ""
    d("Payor_PaidAmount_2") = ""
    d("Payor_CheckNumber_2") = ""
    d("Payor_ProcessedDate_2") = ""
    d("Payor_Paid_Issued_Date_2") = ""
    d("Payor_Claim_Status_2") = ""
    d("Payor_Patient_Full_Name_2") = ""
    d("Payor_Patient_First_name_2") = ""
    d("Payor_Patient_Last_name_2") = ""
    d("Payor_Patient_Middle_name_2") = ""
    d("Payor_Patient_Birth_Date_2") = ""
    d("Payor_Patient_Gender_2") = ""
    d("Payor_Patient_Address_Line_1_2") = ""
    d("Payor_Patient_Address_Line_2_2") = ""
    d("Payor_Patient_Address_City_2") = ""
    d("Payor_Patient_Address_State_2") = ""
    d("Payor_Patient_Address_Zip_2") = ""

    d("Payor_Comment_Line_1_2") = ""
    d("Payor_Comment_Line_2_2") = ""

    d("Payor_Stat_Activity") = ""

    '    d("HealthFirst_StartTime") = ""
    '    d("HealthFirst_ProcessingTime") = ""

    '    d("HealthFirst_FileProcessed") = goConfig.InputFileName

    'Load column header values into the DatastationColumns array, if needed
    InitDataColumns

    'Mark processing start time
    Update_StartTime Now()

End Sub

Private Sub InitDataColumns()
' This is faster than looping thru D.Names.Count for every record.

    Dim IsArrayAllocated As Boolean
    Dim TotalNumOfColumns As Long

    'Determine if array is already populated
    On Error Resume Next
    IsArrayAllocated = IsArray(DatastationColumns()) And _
                       Not IsError(LBound(DatastationColumns(), 1)) And _
                       LBound(DatastationColumns(), 1) <= UBound(DatastationColumns(), 1)
    On Error GoTo 0

    'If the array is not already populated
    If Not IsArrayAllocated Then

        Dim i As Long

        'Determine final number of data columns (original data file + BWS columns)
        TotalNumOfColumns = d.Names.Count

        'Re-size the array to account for the total number of columns
        ReDim DatastationColumns(1 To TotalNumOfColumns, 2)

        'For each data field/column
        For i = 1 To TotalNumOfColumns

            'Add field to array
            DatastationColumns(i, 1) = d.Names(i)

            'If this is a BWS-generated column
            If i <= NumOfBWSColumns Then

                'Add field for XLS reporting in General format
                DatastationColumns(i, 2) = 1

            Else

                'Add field for XLS reporting in Text format
                ' NOTE: This ensures that all of the original data is protected (leading zeros, etc.)
                DatastationColumns(i, 2) = 2

            End If

        Next i

    End If

End Sub

Public Function IsValid() As Boolean
'---------------------------------------------------------------------------------------
' Procedure     : IsValid
' Author/Editor : Boston Software Systems, Inc. ldh
' Date          : 2016-01-07
' Purpose       : Validates the data record before processing is attempted
' Parameters    : None
' Returns       : Boolean
'---------------------------------------------------------------------------------------

    Dim tmpStatusMessage As String

    'Load the record from the datastation
    If Not IsLoaded Then
        LoadFromDatastation
    End If

    'Assume true
    IsValid = True

    'Validate required data fields
    '[EXAMPLE]
    '    If MRN = "" Then
    '        IsValid = False
    '        tmpStatusMessage = tmpStatusMessage & "MRN is required. "
    '    End If
    'TODO


    If Not IsValid Then
        UpdateStatus "Error", Trim$(tmpStatusMessage)
    End If

End Function

Private Sub LoadFromDatastation()
'---------------------------------------------------------------------------------------
' Procedure     : LoadFromDatastation
' Author/Editor : Boston Software Systems, Inc. ldh
' Date          : 2016-01-07
' Purpose       : Loads all Datastation fields into variables
' Parameters    : None
' Returns       : None
'---------------------------------------------------------------------------------------

'Only required fields here
'[EXAMPLE]MRN = Trim$(UCase(D("MRN", True)))
'TODO

'Load Status from BDS file
    Status = Trim$(d("HealthFirst_Status", True))

    IsLoaded = True

End Sub

Public Sub UpdateStatus(StatusValue As String, Optional StatusDetailValue As String)
'---------------------------------------------------------------------------------------
' Procedure     : UpdateStatus
' Author/Editor : Boston Software Systems, Inc. ldh
' Date          : 2016-01-07
' Purpose       : Marks the status of the active record and updates the counts on the status form
' Parameters    : StatusValue (String), result of attempt to process record
'                 StatusDetailValue (String, optional), additional details regarding status
' Returns       : None
'---------------------------------------------------------------------------------------

'Update status values
    Update_Status StatusValue
    AddTo_StatusDetail StatusDetailValue

    'If there was a problem processing the record
    '    If StatusValue <> StatusText_OK Then
    '
    '        'Take a screenshot TODO enable this if you need screenshots
    '        ' AddTo_StatusDetail " See screenshot: " & TakeScreenshot(goconfig.LogFolder & "RecScreenShot_" & Format(Now, "yyyy-mm-dd_hhnnss") & ".bmp")
    '
    '    End If

    'Note the Processing Time
    'oDataStockamp.Update_ProcessingTime DateDiff("s", StartTime, Now())
    oDataHealthFirst.Update_ProcessingTime DateDiff("s", StartProcessingTime, Now())

    'Write to report
    WriteToOutputReport goConfig.ProcessDir & "HealthFirst", goConfig.ProcessDir & "HealthFirst\" & goConfig.outputFileName

End Sub

Public Sub Update_Status(val As String)
    Status = val
    d("HealthFirst_Status") = Status
End Sub

Public Sub AddTo_StatusDetail(val As String)
'StatusDetail = StatusDetail & val
    d("HealthFirst_StatusDetail") = val    'StatusDetail
End Sub

Public Sub Update_StartTime(val As Date)
'    StartTime = val
'    d("HealthFirst_StartTime") = StartTime
End Sub

Public Sub Update_ProcessingTime(val As Long)
'    ProcessingTime = val
'    d("HealthFirst_ProcessingTime") = ProcessingTime
End Sub








