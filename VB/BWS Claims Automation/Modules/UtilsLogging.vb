Option Explicit

Private Const ModuleName As String = "UtilsLogging"

' Writes a given entry to the log file
Public Sub LogThis(TextEntry As String)
    On Error GoTo ErrorHandler: Const procName = "LogThis"

    Dim logText As String
    Const ForAppending = 8
    Dim objFSO, ts

    Set objFSO = CreateObject("Scripting.FileSystemObject")
    Set ts = objFSO.OpenTextFile(goConfig.LogFolderPath & goConfig.LogFileName, ForAppending, True)
    logText = Now() & " - " & TextEntry
    ts.WriteLine logText
    ts.Close

    Set ts = Nothing
    Set objFSO = Nothing

    Exit Sub
ErrorHandler:
    Debug.Print "ERROR:" & Err.Number & ":" & Err.Source & ":" & Err.Description
End Sub
' Writes a given record to the output report
' Creates a file if one doesn't exist; includes a date/time stamp.
Sub WriteToOutputReport(sOutputDir As String, sOutputFileName As String)
    On Error GoTo ErrorHandler: Const procName = "WriteToOutputReport"

    Const ForAppending = 8

    Dim objFSO As Object
    Dim OutputReportPath As String
    Dim WriteHeader As Boolean
    Dim HeaderText As String
    Dim objTextstream As Object
    Dim RetryCounter As Integer
    Dim RecordLineText As String
    Dim i As Long

    'LogThis "Write record to Output Report"

    Set objFSO = CreateObject("Scripting.FileSystemObject")

    'Create folder, if needed
    CreateFolder sOutputDir

    'Create the full path
    OutputReportPath = sOutputFileName

    'If this is a new file, first line will be the header
    WriteHeader = Not objFSO.FileExists(OutputReportPath)

    'Open/Create file
    Set objTextstream = objFSO.OpenTextFile(OutputReportPath, ForAppending, True)

    If WriteHeader Then

        'Loop through Datastation items
        ' NOTE: This is faster than looping thru D.Names.Count for every record
        For i = LBound(DatastationColumns) To UBound(DatastationColumns)

            'Add the field to the list
            HeaderText = HeaderText & DatastationColumns(i, 1) & vbTab

        Next i

        'Write the header lineoup
        objTextstream.WriteLine HeaderText

    End If

    Dim sText As String
    'Build record line from Datastation items
    ' NOTE: This is faster than looping thru D.Names.Count for every record
    For i = LBound(DatastationColumns) To UBound(DatastationColumns)

        'If DatastationColumns(i, 1) = "Status" Then
        sText = d(DatastationColumns(i, 1))
        'End If

        'Add the field to the list
        'RecordLineText = RecordLineText & Chr(34) & Replace(sText, Chr(34), "'") & Chr(34) & vbTab
        RecordLineText = RecordLineText & Replace(sText, Chr(34), "'") & vbTab
        'RecordLineText = RecordLineText & Chr(34) & Replace(D(DatastationColumns(i, 1), True), Chr(34), "'") & Chr(34) & vbTab

    Next i

    'Write to report
    objTextstream.WriteLine RecordLineText

    'Clean-up
    objTextstream.Close
    Set objFSO = Nothing
    Set objTextstream = Nothing

ExitSub:
    Exit Sub

ErrorHandler:
    If DebugMode Then
        Debug.Print "Error in " & ModuleName & "." & procName & ":" & Err.Number & ":" & Err.Description
        Stop
        Resume
    End If
    If Err.Number = 70 And RetryCounter < 50 Then  ' permission denied, try again
        RetryCounter = RetryCounter + 1
        Wait 2
        Resume
    Else
        GeneralErrorHandler Err.Number, Err.Description, Err.Source, procName
    End If
End Sub

Sub GeneralErrorHandler(errNum As Long, errDesc As String, errSource As String, currProc As String)

    LogThis "ERROR: " & "[" & errSource & "]" & errNum & ":" & errDesc

    ' if errSource does not equal BostonWorkStation70 or Scriptname then we know this error was
    ' bubbled up from somewhere else, so keep original source info
    If errSource <> "BostonWorkStation70" And errSource <> StrWord(Mid$(ScriptName, InStrRev(ScriptName, "\") + 1), 1, ".") Then
        Err.Raise errNum, errSource, errDesc
    Else
        Err.Raise errNum, currProc, errDesc
    End If
End Sub

