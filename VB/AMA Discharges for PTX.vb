Option Explicit

Sub Report_update()

'''''
' setup variables
'''''

' Parameters
Dim vPhys As String
Dim vQuarter As String
Dim vQuarterAgg As String

'''''
' Pivot tables
'''''
Dim wksParams As Worksheet
Dim wksPivotData As Worksheet

'''''
' set variables equal to something
'''''
Set wksParams = Sheets("Parameters")
Set wksPivotData = Sheets("pivots")

vPhys = wksParams.Range("D1").Value
vQuarter = wksParams.Range("D2").Value
vQuarterAgg = wksParams.Range("D9").Value

'''''
' Get patient Counts by unit and alos
'''''
wksPivotData.PivotTables("Phys_AMA").PivotFields("ATTENDING MD").CurrentPage = vPhys
wksPivotData.PivotTables("Phys_AMA").PivotFields("YYYYqN").CurrentPage = vQuarter

'set aggregate data if chosen
wksPivotData.PivotTables("All_Time_Community").PivotFields("YYYYqN").CurrentPage = vQuarterAgg
wksPivotData.PivotTables("All_Time_Hospitalists").PivotFields("YYYYqN").CurrentPage = vQuarterAgg

'''''
' go to report page
'''''
Sheets("Report Page").Activate

End Sub
