Option Explicit
Private mlKeyNbr As Long
Private mcWorkLists As New Collection

Public Function Item(ByVal nIndex As Integer) As cWorkList
    Dim oWorkList As cWorkList

    Set Item = Nothing

    On Error Resume Next

    Set Item = mcWorkLists.Item(nIndex)
End Function

Public Property Get Count() As Long
    Count = mcWorkLists.Count
End Property

Public Sub Clear()
    mlKeyNbr = 0
    Set mcWorkLists = Nothing
End Sub

Private Sub Class_Initialize()
    Clear
End Sub

Private Sub Class_Terminate()
    Clear
End Sub

'Add the new object to the collection
Public Function Add(ByRef oWorkList As cWorkList, Optional ByVal lKey As Long) As Boolean
    Add = False

    If IsMissing(lKey) Then
        lKey = 0
    End If

    With oWorkList
        If lKey = 0 Then
            mlKeyNbr = mlKeyNbr + 1
            .Key = mlKeyNbr
        Else
            .Key = lKey
        End If
        mcWorkLists.Add oWorkList, CStr(.Key)
    End With
    Add = True
End Function

Public Function Load() As Boolean
    On Error GoTo ErrHandler

    Dim oWorkList As cWorkList
    Dim sProjectFolderPath As String
    Dim sWorkListSetupFile As String
    Dim sWorkListSetupBdsFile As String
    Dim dStation As New DataStation

    Load = False

    Clear

    ' read WorkListsToProcess.xlsx file and process the WorkLists listed in it
    sProjectFolderPath = Left$(ScriptName, InStrRev(ScriptName, "\"))
    sWorkListSetupFile = sProjectFolderPath & "Setup\WorkListsToProcess.xlsx"
    sWorkListSetupBdsFile = sProjectFolderPath & "Setup\WorkListsToProcess.xlsx.bds"

    ' load configuration file
    dStation.Open_ sWorkListSetupFile, ftExcel, sWorkListSetupBdsFile

    ' handle spaces before and after
    dStation.Trim = True

    Do Until dStation.EOF
        If dStation("Worklist Number") = vbNullString Then
            Exit Do
        Else
            Set oWorkList = New cWorkList
            oWorkList.WorkListNumber = dStation("Worklist Number")

            If Not Add(oWorkList) Then
                'GoTo Cleanup
            End If
        End If
        dStation.Next_
    Loop

    dStation.Close_

    Load = True

ErrHandler:
End Function



