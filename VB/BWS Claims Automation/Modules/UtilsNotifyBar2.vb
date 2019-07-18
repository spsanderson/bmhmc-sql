Option Explicit

Function NotifyBarSaveAs() As Boolean
    Dim cs As CSmart
    Dim notifyBarHwnd As Long
    Dim beginTime As Long
    Dim saveAsPopupHwnd As Long

    On Error GoTo ErrorHandler

    ' wait for notify bar
    beginTime = Timer
    Do
        If Timer >= beginTime + (goConfig.WebTimeout) Then
            Exit Function
        End If
        notifyBarHwnd = GetNotifyBarHwnd
        If notifyBarHwnd <> 0 Then
            Wait 3
            Exit Do
        End If
        DoEvents
    Loop

    ' find down arrow next to Save button and press it
    Set cs = New CSmart
    Set cs.r = r
    cs.First , notifyBarHwnd
    Do Until Not cs.IsElement
        If cs.Visible Then
            'Debug.Print cs.Name, cs.Value
            If cs.name = "Save" Then
                ' go to the next element
                ' which is the down arrow
                cs.Next_
                cs.doAction
                Exit Do
            End If    '
        End If
        cs.Next_
    Loop

    ' get hwnd of 'Save As' popup menu
    saveAsPopupHwnd = GetHwnd("#32768")

    ' find Save As menu item and choose it
    cs.First , saveAsPopupHwnd
    Do Until Not cs.IsElement
        If cs.Visible Then
            'Debug.Print cs.Name, cs.Value
            If cs.name = "Save as" Then
                cs.doAction
                NotifyBarSaveAs = True
                Exit Do
            End If
        End If
        cs.Next_
    Loop

    Set cs = Nothing
    Exit Function
ErrorHandler:
    NotifyBarSaveAs = False
End Function
Function GetNotifyBarHwnd(Optional ByVal ieHwnd As Long) As Long
    Dim h As Variant
    Dim clw As CListWindows

    On Error Resume Next
    Set clw = New CListWindows

    If ieHwnd = 0 Then ieHwnd = Web1.IE.hWnd

    For Each h In clw.InProcess(ieHwnd)
        ' Debug.Print ClassName(h)
        If className(h) = "DirectUIHWND" Then
            GetNotifyBarHwnd = h
            Exit For
        End If
    Next h
ProcExit:
    Set clw = Nothing
End Function
' Returns 0 if not found
Function GetHwnd(componentClassName As String) As Long
    Dim h As Variant
    Dim clw As New CListWindows

    For Each h In clw.InProcess(r.hWnd)
        ' Debug.Print ClassName((h)), View(h)
        ' this *does not* check if the component is visible
        If InStr(className((h)), componentClassName) > 0 Then
            GetHwnd = h
            Exit For
        End If
    Next h
ProcExit:
    Set clw = Nothing
End Function



