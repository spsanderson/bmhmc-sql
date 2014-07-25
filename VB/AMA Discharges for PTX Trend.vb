Option Explicit

Sub Trend_Update_Click()

'''''
' setup variables
'''''

' Parameters
Dim vPhys As String
Dim wksParams As Worksheet
Dim wksPivotData As Worksheet

' set variable equal to something
Set wksParams = Sheets("Parameters")
Set wksPivotData = Sheets("pivots")

vPhys = wksParams.Range("D15").Value

' Set the pivot table to get the physician and year
wksPivotData.PivotTables("Trend_Table").PivotFields("ATTENDING MD").CurrentPage = vPhys

' Go to Report Page
Sheets("Report Trend Page").Activate

End Sub

