Sub Params_Button_Update()

'''''
' set up variables
'''''

' Parameters
Dim vPhys As String
Dim wksParams As Worksheet

' Pivot tables location
Dim wksConditionAlos As Worksheet

'''''
' set variable values
'''''
Set wksParams = Sheets("params")
Set wksConditionAlos = Sheets("CONDITION BY PHYS")

vPhys = wksParams.Range("D1").Value
vQuarter = wksParams.Range("I1").Value

'''''
' set pivot table physician and quarter values
'''''

' Patient Counts
wksConditionAlos.PivotTables("Condition_Count").PivotFields("PHYS NAME").CurrentPage = vPhys
wksConditionAlos.PivotTables("Condition_Count").PivotFields("YYYYqN").CurrentPage = vQuarter

' Condition ALOS
wksConditionAlos.PivotTables("ALOS").PivotFields("PHYS NAME").CurrentPage = vPhys
wksConditionAlos.PivotTables("ALOS").PivotFields("YYYYqN").CurrentPage = vQuarter

' Disposition Counts
wksConditionAlos.PivotTables("Disposition").PivotFields("PHYS NAME").CurrentPage = vPhys
wksConditionAlos.PivotTables("Disposition").PivotFields("YYYYqN").CurrentPage = vQuarter

' By Quarter: Patient Count, ALOS and STD Dev ALOS
wksConditionAlos.PivotTables("z_score_tbl").PivotFields("PHYS NAME").CurrentPage = vPhys

' Go to report page
Sheets("Report Page").Activate

End Sub
------------------------------------------------------------------------
Sub Quit_Application()

Dim Msg As String
    
    Msg = "Congratulations! You now know Steve's the bomb!"
    MsgBox Msg, vbExclamation, "Well Done!"
    
    Application.SaveWorkspace
    Application.Quit

End Sub
