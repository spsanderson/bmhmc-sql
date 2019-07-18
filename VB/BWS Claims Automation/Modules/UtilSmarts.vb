Public Declare Function SwitchToThisWindow Lib "user32" (ByVal hWnd As Long, hWindowState As Long) As Long

' Get a CSmart component by classname, value, and/or name
' Pass in the window hwnd
' If you include a '*' in the name, method will use Like matching
Function GetComponent(windowHwnd As Long, Optional className As String, Optional value As String, Optional name As String) As CSmart
    Dim cs As New CSmart
    Dim useLike As Boolean

    On Error GoTo ErrorHandler

    ' if we didn't get any info to find, return nothing
    If className = "" And value = "" And name = "" Then
        Set GetComponent = Nothing
        GoTo Proc_Exit
    End If

    If InStr(name, "*") > 0 Then
        useLike = True
    End If

    'Activate WindowText(windowHwnd), True
    SwitchToThisWindow windowHwnd, vbNormalFocus
    Set cs.r = r
    cs.First , windowHwnd
    Do Until Not cs.IsElement
        If cs.Visible Then
            If useLike Then
                ' Debug.Print cs.Class, cs.value, cs.name
                If className <> "" And name <> "" And value <> "" Then
                    If cs.Class = className And cs.name Like name And cs.value = value Then
                        Set GetComponent = cs
                        GoTo Proc_Exit
                    End If
                ElseIf className <> "" And name <> "" And value = "" Then
                    If cs.Class = className And cs.name Like name Then
                        Set GetComponent = cs
                        GoTo Proc_Exit
                    End If
                ElseIf className = "" And name <> "" And value <> "" Then
                    If cs.value = value And cs.name Like name Then
                        Set GetComponent = cs
                        GoTo Proc_Exit
                    End If
                ElseIf className <> "" And name = "" And value <> "" Then
                    If cs.value = value And cs.Class = className Then
                        Set GetComponent = cs
                        GoTo Proc_Exit
                    End If
                ElseIf className <> "" And name = "" And value = "" Then
                    If cs.Class = className Then
                        Set GetComponent = cs
                        GoTo Proc_Exit
                    End If
                ElseIf className = "" And name <> "" And value = "" Then
                    If cs.name Like name Then
                        Set GetComponent = cs
                        GoTo Proc_Exit
                    End If
                ElseIf className = "" And name = "" And value <> "" Then
                    If cs.value = value Then
                        Set GetComponent = cs
                        GoTo Proc_Exit
                    End If
                End If
            Else
                ' Debug.Print cs.Class, cs.value, cs.name
                If className <> "" And name <> "" And value <> "" Then
                    If cs.Class = className And cs.name = name And cs.value = value Then
                        Set GetComponent = cs
                        GoTo Proc_Exit
                    End If
                ElseIf className <> "" And name <> "" And value = "" Then
                    If cs.Class = className And cs.name = name Then
                        Set GetComponent = cs
                        GoTo Proc_Exit
                    End If
                ElseIf className = "" And name <> "" And value <> "" Then
                    If cs.value = value And cs.name = name Then
                        Set GetComponent = cs
                        GoTo Proc_Exit
                    End If
                ElseIf className <> "" And name = "" And value <> "" Then
                    If cs.value = value And cs.Class = className Then
                        Set GetComponent = cs
                        GoTo Proc_Exit
                    End If
                ElseIf className <> "" And name = "" And value = "" Then
                    If cs.Class = className Then
                        Set GetComponent = cs
                        GoTo Proc_Exit
                    End If
                ElseIf className = "" And name <> "" And value = "" Then
                    If cs.name = name Then
                        Set GetComponent = cs
                        GoTo Proc_Exit
                    End If
                ElseIf className = "" And name = "" And value <> "" Then
                    If cs.value = value Then
                        Set GetComponent = cs
                        GoTo Proc_Exit
                    End If
                End If
            End If
        End If
        cs.Next_
    Loop

Proc_Exit:
    Set cs = Nothing
    Exit Function
ErrorHandler:
    'LogThis "ERROR: GetComponent" & "|" & Err.Number & "|" & Err.Description
    Resume Proc_Exit
End Function

Function GetHwndByCaption(windowCaptionLike As String) As Long
    Dim clw As New CListWindows
    On Error Resume Next

    ' loop thru the windows that have a similar caption
    For Each h In clw.HasCaptionLike("*" & windowCaptionLike & "*")
        GetHwndByCaption = h
        ' Debug.Print WindowText(h)
        Exit Function
    Next

End Function


Function GetComponentHwndByClassname(componentClassName As String) As Long
    Dim h As Variant
    Dim clw As New CListWindows

    For Each h In clw.InProcess(r.hWnd)
        ' Debug.Print ClassName((h)), View(h)
        ' this *does not* check if the component is visible
        If InStr(className((h)), componentClassName) > 0 Then
            GetComponentHwndByClassname = h
            Set clw = Nothing
            Exit Function
        End If
    Next h
    Set clw = Nothing
End Function

