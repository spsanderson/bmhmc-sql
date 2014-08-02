Sub Params_Button_Update()

    '''''
    ' set up variables
    '''''
    
    ' Parameters
    Dim vPhys As String
    Dim vQuarter As String
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
Sub m_AMA_Report()

' set up variables

    'Parameters
    Dim vPhysAMA As String
    Dim vQuarterAMA As String
    Dim wksAMAData As Worksheet
    Dim wksAMAParams As Worksheet
    
    Set wksAMAData = Sheets("AMA Pivots")
    Set wksAMAParams = Sheets("params")
    
    vPhysAMA = wksAMAParams.Range("D10").Value
    vQuarterAMA = wksAMAParams.Range("i10").Value

    
    'set pivot table information to get patient counts by physician
    wksAMAData.PivotTables("AMA_Pivot_tbl").PivotFields("Attending Doctor").CurrentPage = vPhysAMA
    wksAMAData.PivotTables("AMA_Pivot_tbl").PivotFields("YYYYqN").CurrentPage = vQuarterAMA
    
    'set pivot table information toget patient counts for aggregate data by discharge quarter
    wksAMAData.PivotTables("AMA_Pivot_Aggregate").PivotFields("YYYYqN").CurrentPage = vQuarterAMA
    
    'go to the report page
    Sheets("AMA Report").Activate

End Sub
------------------------------------------------------------------------
Sub AMA_Rate_Report()
    
    Dim vPhysAMARate As String
    Dim wksAMAParamsRate As Worksheet
    Dim wksAMARateData As Worksheet
    
    Set wksAMAParamsRate = Sheets("params")
    Set wksAMARateData = Sheets("AMA Pivots")
    vPhysAMARate = wksAMAParamsRate.Range("D10")
    
    'set pivot table information to get patient counts by physician
    wksAMARateData.PivotTables("AMA_Trend_tbl").PivotFields("Attending Doctor").CurrentPage = vPhysAMARate
    
    'go to the report page
    Sheets("AMA Trending Rate").Activate
End Sub
------------------------------------------------------------------------
Sub Quit_Application()

    Dim Msg As String
        
    Msg = "Congratulations! You now know Steve's the bomb!"
    MsgBox Msg, vbExclamation, "Well Done!"
        
    Application.Quit

End Sub

