Option Explicit

Private mlKey As Long
Private msWorkListNumber As String

Public Property Get WorkListNumber() As String
    WorkListNumber = msWorkListNumber
End Property

Public Property Let WorkListNumber(ByVal sWorkListNumber As String)
    msWorkListNumber = sWorkListNumber
End Property

Public Property Get Key() As Long
    Key = mlKey
End Property

Public Property Let Key(ByVal lKey As Long)
    mlKey = lKey
End Property

Private Sub Class_Initialize()
    mlKey = 0
    msWorkListNumber = vbNullString
End Sub

