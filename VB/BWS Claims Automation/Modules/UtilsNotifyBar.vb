Dim oListWindowsNotifyBar As New CListWindows
Dim oSmartNotifyBar As New CSmart
'
'Sub NotifyBarFillSaveAs(sFileName As String)
'    Activate "Save As", True
'    SmartDialog("Save As", "File name:<Editable text>").value = sFileName
'    SmartDialog("Save As", "Save<Push button>").Click
'End Sub


Sub NotifyBarFillSaveAs(sFileName As String)

    If NotifyBarSaveAs Then
        Activate "Save As", True
        SmartDialog("Save As", "File name:<Editable text>").value = sFileName
        SmartDialog("Save As", "Save<Push button>").Click
    End If

End Sub

Sub NotifyBarFileDownloadCopmleted()
    Dim cs As New CSmart
    Set cs.r = r
    'Wait 5
    cs.First , GetBarHwndNotifyBar
    Do Until Not cs.IsElement
        If cs.Visible Then
            'Debug.Print cs.name, cs.value, cs.Description, cs.View
            If cs.name = "Notification bar Text" Then  ' IE11 is "Open"
                If InStr(1, cs.value, "download has completed") > 0 Then
                    cs.Next_
                    cs.Next_
                    cs.Next_
                    cs.Next_
                    cs.Next_
                    cs.doAction
                    Exit Do
                End If
            End If
        End If
        cs.Next_
    Loop
    Set cs = Nothing

    ' click on Close
    '    NotifyBarDoClickAction "Close", "Press"

End Sub

Sub NotifyBarInitSmart(ByVal h As Long)    ' used to "connect"  - h is a top level handle
    Set oSmartNotifyBar.r = r
    oSmartNotifyBar.First , h
End Sub

Function GetBarHwndNotifyBar(Optional ByVal ieHwnd As Long) As Long
    On Error Resume Next    ' just in case someone is using this without web connection alive, they could pass the top level hwnd of IE instead
    If ieHwnd = 0 Then ieHwnd = Web1.IE.hWnd
    For Each h In oListWindowsNotifyBar.InProcess(ieHwnd)
        If className(h) = "DirectUIHWND" Then
            GetBarHwndNotifyBar = h
            Exit Function
        End If

        'ListAllNotifyBar
    Next h
End Function

Sub ListSmartNotifyBar()
'Use as a just run this development tool to see contents of the notification bar - the text you see isn't exactly what is returned.
    Set oSmartNotifyBar.r = r
    oSmartNotifyBar.First , GetBarHwndNotifyBar
    Do Until Not oSmartNotifyBar.IsElement
        If oSmartNotifyBar.Visible Then
            Debug.Print oSmartNotifyBar.name, oSmartNotifyBar.value  ' Name is what you use for the NotifyBarDoClickAction routine, Value is the contents of text
        End If
        oSmartNotifyBar.Next_
    Loop
End Sub

'Sub NotifyBarPauseBarText(sText As String, sPauseStr As String)
'    If TimeOut = 0 Then TimeOut = 10
'    Dim lPrintHwnd As Long
'
'    Activate sPauseStr
'    Wait 5
'    'NotifyBarInitSmart GetBarHwndNotifyBar
'    lPrintHwnd = GetForeGroundhWnd
'    For i = 1 To TimeOut * 10
'        NotifyBarInitSmart GetBarHwndNotifyBar(lPrintHwnd)
'        Wait 5
'        If NotifyBarGetBarText Like sText Then
'            Wait 5
'            Exit Sub
'        End If
'        Activate goConfig.LoginCaption, True
'        Wait 5
'        Activate sPauseStr
'        Wait 5
'        'NotifyBarInitSmart GetBarHwndNotifyBar
'        lPrintHwnd = GetForeGroundhWnd
'        Wait 2
'    Next i
'    Err.Raise seTimeOut
'End Sub

Function NotifyBarGetBarText() As String
    On Error Resume Next    ' Let a empty string go through
    CreateNotifyBar "Notification bar Text"
    'CreateNotifyBar "open or save"
    NotifyBarGetBarText = oSmartNotifyBar.value
    'Debug.Print "oSmartNotifyBar.value"
    'Debug.Print oSmartNotifyBar.value
End Function

Sub NotifyBarDoClickAction(Window As String, Optional ActionFind As String, Optional ByVal noFirst As Boolean = True, Optional ByVal X As Long, Optional ByVal y As Long)
    CreateNotifyBar Window, ActionFind, noFirst, X, y
    If oSmartNotifyBar.IsElement Then
        oSmartNotifyBar.doAction
    End If
End Sub

Sub CreateNotifyBar(sName As String, Optional ByVal Action As String = "*", Optional noFirst As Boolean = True, Optional ByVal X As Long, Optional ByVal y As Long)
    Dim tt As Long
    Dim ll As Long
    Dim ww As Long
    Dim hh As Long
    If Not noFirst Then NotifyBarInitSmart GetBarHwndNotifyBar
    Do Until Not oSmartNotifyBar.IsElement
        If oSmartNotifyBar.Visible Then
            If oSmartNotifyBar.name Like sName And oSmartNotifyBar.Action Like Action Then
                If X <> 0 Or y <> 0 Then
                    oSmartNotifyBar.location ll, tt, ww, hh
                    oSmartNotifyBar.Create "CURSORLOCATION", ll + X, tt + y
                    Debug.Print oSmartNotifyBar.name, oSmartNotifyBar.Action
                    If Not oSmartNotifyBar.IsElement Then
                        Exit Do
                    Else
                        Exit Sub
                    End If
                Else
                    Exit Sub
                End If
            End If
        End If
        oSmartNotifyBar.Next_
    Loop
    Err.Raise seTimeOut    ' Can't find the element
End Sub

Sub ListAllNotifyBar()
    Dim tt As Long
    Dim ll As Long
    Dim ww As Long
    Dim hh As Long
    Do Until Not oSmartNotifyBar.IsElement
        If oSmartNotifyBar.Visible Then
            oSmartNotifyBar.location ll, tt, ww, hh
            Debug.Print oSmartNotifyBar.name, ll, tt, ww, hh, oSmartNotifyBar.Action, oSmartNotifyBar.Class
        End If
        oSmartNotifyBar.Next_
    Loop
End Sub

Function GetNotifyBarHwnd(Optional ByVal ieHwnd As Long) As Long
    Dim h As Variant
    Dim clw As New CListWindows
    On Error Resume Next
    If ieHwnd = 0 Then ieHwnd = Web1.IE.hWnd

    For Each h In clw.InProcess(ieHwnd)
        If className(h) = "DirectUIHWND" Then
            GetNotifyBarHwnd = h
            Exit Function
        End If
    Next h
End Function

Sub WaitForNotifyBar()
    Dim cs As CSmart
    Dim notifyBarHwnd As Long
    Dim beginTime As Long

    ' wait for notify bar
    beginTime = Timer
    Do
        If Timer >= beginTime + goConfig.WebTimeout Then
            Exit Sub
        End If
        notifyBarHwnd = GetNotifyBarHwnd
        If notifyBarHwnd <> 0 Then
            Wait 3
            Exit Do
        End If
        DoEvents
    Loop
End Sub


