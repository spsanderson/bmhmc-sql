Option Explicit

Sub m0_Get_HCAHPS_Doctors()

Application.ScreenUpdating = False

Dim wksHCAHPS        As Worksheet
Dim wksHCAHPSDoctors As Worksheet

Set wksHCAHPS = Sheets("hcahps")
Set wksHCAHPSDoctors = Sheets("hcahps doctors")

    wksHCAHPS.Activate
    Columns("A:A").Copy
    
    wksHCAHPSDoctors.Activate
    Range("A1").Select
    
    Selection.PasteSpecial Paste:=xlPasteValues, Operation:=xlNone, SkipBlanks _
        :=False, Transpose:=False
    Application.CutCopyMode = False
    
    ActiveSheet.Range("A:A").RemoveDuplicates Columns:=1, Header:=xlNo
    Range("A1:A2").Select
    Selection.Delete Shift:=xlUp
    Range("I1").Select
    
    ' SORT COLUMN ALPHABETICALLY
    Columns("A:A").Select
    ActiveWorkbook.Worksheets("hcahps doctors").Sort.SortFields.Clear
    ActiveWorkbook.Worksheets("hcahps doctors").Sort.SortFields.Add Key:=Range( _
        "A1"), SortOn:=xlSortOnValues, Order:=xlAscending, DataOption:= _
        xlSortNormal
    With ActiveWorkbook.Worksheets("hcahps doctors").Sort
        .SetRange Range("A:A")
        .Header = xlNo
        .MatchCase = False
        .Orientation = xlTopToBottom
        .SortMethod = xlPinYin
        .Apply
    End With

Application.ScreenUpdating = True
    
End Sub

'-----------------------------------------------------------------------

Sub m1_PivotSetUp_Macro()

Dim vALOSQ   As String
Dim vRAQ     As String
Dim vHCAHPSQ As String


vALOSQ = "2013q4"
vRAQ = "2013q3"
vHCAHPSQ = "2014q2"

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' PivotSetUp_Macro Macro - this macro will run through all the data
' that gets downloaded and will setup all the required pivot tables
' that feed into the "report data" tab for reporting
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

Application.ScreenUpdating = False

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' This will select the readmis sheet and will create the pivot tables
' required to get the data in the format needed for the per
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    Sheets("readmits").Select
'    Range("ReadmitData[[#Headers],[LIHN Measure]]").Select
    
    
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    ' This will add the sheet necessary where the pivot table itself
    ' is going to live
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    
    Sheets.Add After:=Sheets(Sheets.Count)
    ActiveWorkbook.PivotCaches.Create(SourceType:=xlDatabase, SourceData:= _
        "readmits!R1C1:R1048576C8", Version:=xlPivotTableVersion12).CreatePivotTable _
        TableDestination:="Sheet1!R3C1", TableName:="PivotTable1", DefaultVersion _
        :=xlPivotTableVersion12
    
    '''''''''''''''''''''''''''''''''''''''''''''
    ' This is where we select the new sheet that
    ' was just created and we construct the pivot
    ' table in the fashion desired
    '''''''''''''''''''''''''''''''''''''''''''''
    
    Sheets("Sheet1").Select
    
    Cells(3, 1).Select
    
    With ActiveSheet.PivotTables("PivotTable1").PivotFields( _
        "Discharge Quarter (YYYYqN)")
        .Orientation = xlRowField
        .Position = 1
    End With
    
    ''''''''''''''''''''''''''''''''''''''
    ' Here we try to keep null values
    ''''''''''''''''''''''''''''''''''''''
    ActiveSheet.PivotTables("PivotTable1").PivotFields("Discharge Quarter (YYYYqN)" _
        ).ShowAllItems = True
    ''''''''''''''''''''''''''''''''''''''
    ' End of keeping nulls
    ''''''''''''''''''''''''''''''''''''''
    
    With ActiveSheet.PivotTables("PivotTable1").PivotFields("Attending Physician")
        .Orientation = xlPageField
        .Position = 1
    End With
    
    ActiveSheet.PivotTables("PivotTable1").AddDataField ActiveSheet.PivotTables( _
        "PivotTable1").PivotFields("Actual Measure Performance/Case"), _
        "Sum of Actual Measure Performance/Case", xlSum
    
    ActiveSheet.PivotTables("PivotTable1").AddDataField ActiveSheet.PivotTables( _
        "PivotTable1").PivotFields("Actual Measure Performance/Case"), _
        "Sum of Actual Measure Performance/Case2", xlSum
    
    With ActiveSheet.PivotTables("PivotTable1").PivotFields( _
        "Sum of Actual Measure Performance/Case2")
        .Caption = "Average of Actual Measure Performance/Case2"
        .Function = xlAverage
        .NumberFormat = "0.00%"
    End With
    
    With ActiveSheet.PivotTables("PivotTable1")
        .ColumnGrand = False
        .RowGrand = False
    End With
    
    ActiveSheet.PivotTables("PivotTable1").AddDataField ActiveSheet.PivotTables( _
        "PivotTable1").PivotFields("Expected Measure Performance/Case"), _
        "Sum of Expected Measure Performance/Case", xlSum
    
    With ActiveSheet.PivotTables("PivotTable1").PivotFields( _
        "Sum of Expected Measure Performance/Case")
        .Caption = "Average of Expected Measure Performance/Case"
        .Function = xlAverage
        .NumberFormat = "0.00%"
    End With
    
    With ActiveSheet.PivotTables("PivotTable1").PivotFields( _
        "Discharge Quarter (YYYYqN)")
        .PivotItems("(blank)").Visible = False
    End With
    
    Sheets("Sheet1").Select
    Sheets("Sheet1").Name = "readmit_pivot_trend"
    
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    ' The readmit_pivot_trend sheet and table are now finished
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
        
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    ' We will now make the ALOS sheets and tables
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

    Sheets("alos").Select
'    Range("alosdata[[#Headers],[LIHN Measure]]").Select
'    Columns("A:L").Select
    
    Sheets.Add After:=Sheets(Sheets.Count)
    ActiveWorkbook.PivotCaches.Create(SourceType:=xlDatabase, SourceData:= _
        "alos!R1C1:R100000C12", Version:=xlPivotTableVersion12).CreatePivotTable _
        TableDestination:="Sheet2!R3C1", TableName:="PivotTable4", DefaultVersion _
        :=xlPivotTableVersion12
    
    Sheets("Sheet2").Select
    Cells(3, 1).Select
    With ActiveSheet.PivotTables("PivotTable4").PivotFields("Attending Physician")
        .Orientation = xlPageField
        .Position = 1
    End With
    
    With ActiveSheet.PivotTables("PivotTable4").PivotFields( _
        "Discharge Quarter (YYYYqN)")
        .Orientation = xlPageField
        .Position = 1
    End With
    
    ActiveSheet.PivotTables("PivotTable4").PivotFields("Discharge Quarter (YYYYqN)" _
        ).ClearAllFilters


    ActiveSheet.PivotTables("PivotTable4").PivotFields("Discharge Quarter (YYYYqN)" _
        ).CurrentPage = vALOSQ
    
    With ActiveSheet.PivotTables("PivotTable4").PivotFields("Severity of Illness")
        .Orientation = xlRowField
        .Position = 1
    End With
    
    ''''''''''''''''''''''''''''''''''''''
    ' Here we  keep null values
    ''''''''''''''''''''''''''''''''''''''
    ActiveSheet.PivotTables("PivotTable4").PivotFields("Severity of Illness" _
        ).ShowAllItems = True
    ''''''''''''''''''''''''''''''''''''''
    ' End of keeping nulls
    ''''''''''''''''''''''''''''''''''''''
    
    ActiveSheet.PivotTables("PivotTable4").AddDataField ActiveSheet.PivotTables( _
        "PivotTable4").PivotFields("Patient Account"), "Count of Patient Account", _
        xlCount
    
    ActiveSheet.PivotTables("PivotTable4").AddDataField ActiveSheet.PivotTables( _
        "PivotTable4").PivotFields("Actual  Measure Performance/Case"), _
        "Sum of Actual  Measure Performance/Case", xlSum
    
    With ActiveSheet.PivotTables("PivotTable4").PivotFields( _
        "Sum of Actual  Measure Performance/Case")
        .Caption = "Average of Actual  Measure Performance/Case"
        .Function = xlAverage
        .NumberFormat = "0.00"
    End With
    
    ActiveSheet.PivotTables("PivotTable4").AddDataField ActiveSheet.PivotTables( _
        "PivotTable4").PivotFields("Expected  Measure Performance/Case"), _
        "Sum of Expected  Measure Performance/Case", xlSum
    
    With ActiveSheet.PivotTables("PivotTable4").PivotFields( _
        "Sum of Expected  Measure Performance/Case")
        .Caption = "Average of Expected  Measure Performance/Case"
        .Function = xlAverage
        .NumberFormat = "0.00"
    End With
    
    ActiveSheet.PivotTables("PivotTable4").AddDataField ActiveSheet.PivotTables( _
        "PivotTable4").PivotFields("Performance Index"), "Sum of Performance Index", _
        xlSum
    Range("E6:E10").Select
    Selection.NumberFormat = "0.00"
    
    With ActiveSheet.PivotTables("PivotTable4").PivotFields( _
        "Sum of Performance Index")
        .Caption = "Average of Performance Index"
        .Function = xlAverage
    End With
    
    With ActiveSheet.PivotTables("PivotTable4").PivotFields( _
        "Severity of Illness")
        .PivotItems("(blank)").Visible = False
    End With
    
    ActiveSheet.PivotTables("PivotTable4").AddDataField ActiveSheet.PivotTables( _
        "PivotTable4").PivotFields("Total Opportunity"), "Sum of Total Opportunity", _
        xlSum
    Range("F6:F10").Select
    Selection.NumberFormat = "0.00"
    
    Sheets("Sheet2").Select
    Sheets("Sheet2").Name = "alos_pivot_current"
    ActiveSheet.PivotTables("PivotTable4").Name = "AlosPivotCurrentTable"
    
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    ' The alos_pivot_current is now done. Now we will construct the
    ' alos_pivot_trend sheet and corresponding data
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    
    Sheets("alos").Select
'    Range("alosdata[[#Headers],[LIHN Measure]]").Select
    Columns("A:L").Select
    
    Sheets.Add
    ActiveWorkbook.Worksheets("alos_pivot_current").PivotTables( _
        "AlosPivotCurrentTable").PivotCache.CreatePivotTable TableDestination:= _
        "Sheet3!R3C1", TableName:="PivotTable5", DefaultVersion:= _
        xlPivotTableVersion12
    
    Sheets("Sheet3").Select
    Cells(3, 1).Select
    With ActiveSheet.PivotTables("PivotTable5").PivotFields( _
        "Discharge Quarter (YYYYqN)")
        .Orientation = xlRowField
        .Position = 1
    End With
    
    ''''''''''''''''''''''''''''''''''''''
    ' Here we try to keep null values
    ''''''''''''''''''''''''''''''''''''''
    ActiveSheet.PivotTables("PivotTable5").PivotFields("Discharge Quarter (YYYYqN)" _
        ).ShowAllItems = True
    ''''''''''''''''''''''''''''''''''''''
    ' End of keeping nulls
    ''''''''''''''''''''''''''''''''''''''
    
    With ActiveSheet.PivotTables("PivotTable5").PivotFields("Attending Physician")
        .Orientation = xlPageField
        .Position = 1
    End With
    
    ActiveSheet.PivotTables("PivotTable5").AddDataField ActiveSheet.PivotTables( _
    "PivotTable5").PivotFields("Patient Account"), "Count of Patient Account", _
    xlCount
    
    ActiveSheet.PivotTables("PivotTable5").AddDataField ActiveSheet.PivotTables( _
        "PivotTable5").PivotFields("Actual  Measure Performance/Case"), _
        "Sum of Actual  Measure Performance/Case", xlSum
    
    ActiveSheet.PivotTables("PivotTable5").AddDataField ActiveSheet.PivotTables( _
        "PivotTable5").PivotFields("Expected  Measure Performance/Case"), _
        "Sum of Expected  Measure Performance/Case", xlSum
    
    With ActiveSheet.PivotTables("PivotTable5").PivotFields( _
        "Sum of Actual  Measure Performance/Case")
        .Caption = "Average of Actual  Measure Performance/Case"
        .Function = xlAverage
    End With
    
    With ActiveSheet.PivotTables("PivotTable5").PivotFields( _
        "Sum of Expected  Measure Performance/Case")
        .Caption = "Average of Expected  Measure Performance/Case"
        .Function = xlAverage
    End With
    
    With ActiveSheet.PivotTables("PivotTable5")
        .ColumnGrand = False
        .RowGrand = False
    End With
    
    With ActiveSheet.PivotTables("PivotTable5").PivotFields( _
        "Discharge Quarter (YYYYqN)")
        .PivotItems("(blank)").Visible = False
    End With
    
    Range("C5:C8").Select
    Selection.NumberFormat = "0.00"
    Range("D5:D8").Select
    Selection.NumberFormat = "0.00"
    Sheets("Sheet3").Select
    Sheets("Sheet3").Name = "alos_pivot_trend"
    ActiveSheet.PivotTables("PivotTable5").Name = "AlosPivotTrendTable"
    
    
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    ' Now we move onto construction of the HCAHPS data
    ' There are going to be two sheets that will be made from the data
    ' the first is the hcahps_pivot_current and the second
    ' is the hcahps_pivot_trend
    '
    '
    ' This is going to give us all the current hcahps data that we need
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    
    Sheets("hcahps").Select
    ''''
    ' new code
    ''''
    
        ''''
        ' where the pivot is going to go
        ''''
    Range("H1").Select
    
        ''''
        ' select the pivot data itself
        ''''
    ActiveWorkbook.PivotCaches.Create(SourceType:=xlDatabase, SourceData:= _
        "hcahps!R1C1:R1048576C6", Version:=xlPivotTableVersion12).CreatePivotTable _
        TableDestination:="hcahps!R1C8", TableName:="PivotTable2", DefaultVersion _
        :=xlPivotTableVersion12
    
    Sheets("hcahps").Select
    Cells(1, 8).Select
    ActiveWindow.SmallScroll ToRight:=5
    
    With ActiveSheet.PivotTables("PivotTable2").PivotFields("Doctor")
        .Orientation = xlPageField
        .Position = 1
    End With
    
    With ActiveSheet.PivotTables("PivotTable2").PivotFields("Quarter")
        .Orientation = xlPageField
        .Position = 1
    End With
    
    ActiveSheet.PivotTables("PivotTable2").PivotFields("Quarter").ClearAllFilters
    
    ActiveSheet.PivotTables("PivotTable2").PivotFields("Quarter").CurrentPage = _
        vHCAHPSQ
    
    ActiveSheet.PivotTables("PivotTable2").AddDataField ActiveSheet.PivotTables( _
        "PivotTable2").PivotFields("Your Top Box"), "Count of Your Top Box", xlCount
    
    ActiveSheet.PivotTables("PivotTable2").AddDataField ActiveSheet.PivotTables( _
        "PivotTable2").PivotFields("HSTM DB Top Box Percentile Rank"), _
        "Count of HSTM DB Top Box Percentile Rank", xlCount
        
    ''''''''''''''''''''''''''
    ' add in response counts
    ''''''''''''''''''''''''''
    ActiveSheet.PivotTables("PivotTable2").AddDataField ActiveSheet.PivotTables( _
        "PivotTable2").PivotFields("Adjusted N (Statbase)"), _
        "Count of Adjusted N (Statbase)", xlSum
    
    With ActiveSheet.PivotTables("PivotTable2").PivotFields("Count of Your Top Box" _
        )
        .Caption = "Average of Your Top Box"
        .Function = xlAverage
    End With
    
    With ActiveSheet.PivotTables("PivotTable2").PivotFields( _
        "Count of HSTM DB Top Box Percentile Rank")
        .Caption = "Average of HSTM DB Top Box Percentile Rank"
        .Function = xlAverage
    End With
    
    With ActiveSheet.PivotTables("PivotTable2").PivotFields( _
        "Count of Adjusted N (Statbase)")
        .Caption = "Response Count"
        .Function = xlSum
    End With
    
    Range("H6").Select
    Selection.Style = "Percent"
    Range("I6").Select
    Selection.NumberFormat = "0"
    
    'name the pivot table here
    ActiveSheet.PivotTables("PivotTable2").Name = "HcahpsPivotcurrentTable"
        
        '''''''''''''''''''''''''''''''''''''''''''''''''''
        ' make hcahps trend
        '''''''''''''''''''''''''''''''''''''''''''''''''''
        
    Sheets("hcahps").Select
    Range("H100").Select
    
        ActiveWorkbook.PivotCaches.Create(SourceType:=xlDatabase, SourceData:= _
        "hcahps!R1C1:R1048576C6", Version:=xlPivotTableVersion12).CreatePivotTable _
        TableDestination:="hcahps!R100C8", TableName:="PivotTable3", DefaultVersion _
        :=xlPivotTableVersion12
    Sheets("hcahps").Select
    Cells(100, 8).Select
    ActiveWindow.SmallScroll ToRight:=6
    
    With ActiveSheet.PivotTables("PivotTable3").PivotFields("Doctor")
        .Orientation = xlPageField
        .Position = 1
    End With
    
    With ActiveSheet.PivotTables("PivotTable3").PivotFields("Quarter")
        .Orientation = xlRowField
        .Position = 1
    End With
    
    ''''''''''''''''''''''''''''''''''''''
    ' Here we try to keep null values
    ''''''''''''''''''''''''''''''''''''''
    ActiveSheet.PivotTables("PivotTable3").PivotFields("Quarter" _
        ).ShowAllItems = True
    ''''''''''''''''''''''''''''''''''''''
    ' End of keeping nulls
    ''''''''''''''''''''''''''''''''''''''
    
    With ActiveSheet.PivotTables("PivotTable3").PivotFields("Quarter")
        .PivotItems("(blank)").Visible = False
    End With
    
    ActiveSheet.PivotTables("PivotTable3").AddDataField ActiveSheet.PivotTables( _
        "PivotTable3").PivotFields("HSTM DB Top Box"), "Count of HSTM DB Top Box", _
        xlCount
    
    With ActiveSheet.PivotTables("PivotTable3").PivotFields( _
        "Count of HSTM DB Top Box")
        .Caption = "Average of HSTM DB Top Box"
        .Function = xlAverage
    End With
    
    With ActiveSheet.PivotTables("PivotTable3")
        .ColumnGrand = False
        .RowGrand = False
    End With
    
    Range("I101:I105").Select
    
    Selection.Style = "Percent"
    
    ActiveSheet.PivotTables("PivotTable3").PivotFields("Average of HSTM DB Top Box" _
        ).Orientation = xlHidden
    
    ActiveSheet.PivotTables("PivotTable3").AddDataField ActiveSheet.PivotTables( _
        "PivotTable3").PivotFields("Your Top Box"), "Count of Your Top Box", xlCount
    
    With ActiveSheet.PivotTables("PivotTable3").PivotFields("Count of Your Top Box" _
        )
        .Caption = "Average of Your Top Box"
        .Function = xlAverage
        .NumberFormat = "0.00%"
    End With
    
    ActiveSheet.PivotTables("PivotTable3").Name = "HcahpsPivotTrendTable"
    
    Range("K98").Select
        
Application.ScreenUpdating = True
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    ' end of new code
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    ' All done
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
End Sub

'-----------------------------------------------------------------------

Sub cleanup()

'''''''''''''''''''''''''''''''''''''''''
' cleanup Macro
' this gets rid of all the pivot data
' so that we can close and be fresh on
' the next time we open
'''''''''''''''''''''''''''''''''''''''''
    Sheets("alos_pivot_trend").Select
    ActiveWindow.SelectedSheets.Delete
    
    Sheets("alos_pivot_current").Select
    ActiveWindow.SelectedSheets.Delete

    Sheets("readmit_pivot_trend").Select
    ActiveWindow.SelectedSheets.Delete
    
    Sheets("hcahps").Select
    Range("H:K").Select
    Selection.Delete Shift:=xlToLeft
    
    MsgBox "Clean Up All Done", vbOKOnly, "PER Clean Up"
    
End Sub

'-----------------------------------------------------------------------

Sub m2_Data_Pre_Processing()

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' DATA_PRE_PROCESSING Macro
' This macro will take all the values from the pivot table and place
' them in the necessary sheets so that the report macro can grab the
' values for the report tab itself
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

Application.ScreenUpdating = False

    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    ' start with the readmissions data
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    
    Sheets("readmit_pivot_trend").Activate
    Sheets("readmit_pivot_trend").Select
    
    Range("A15").Select
    ActiveCell.FormulaR1C1 = "=R[-10]C"
    
    Range("A16").Select
    ActiveCell.FormulaR1C1 = "=R[-10]C"
    
    Range("A17").Select
    ActiveCell.FormulaR1C1 = "=R[-10]C"
    
    Range("A18").Select
    ActiveCell.FormulaR1C1 = "=R[-10]C"
    
    Range("B15").Select
    ActiveCell.FormulaR1C1 = "=R[-10]C"
    
    Range("B16").Select
    ActiveCell.FormulaR1C1 = "=R[-10]C"
    
    Range("B17").Select
    ActiveCell.FormulaR1C1 = "=R[-10]C"
    
    Range("B18").Select
    ActiveCell.FormulaR1C1 = "=R[-10]C"
    
    Range("C15").Select
    ActiveCell.FormulaR1C1 = "=R[-10]C"
    
    Range("C16").Select
    ActiveCell.FormulaR1C1 = "=R[-10]C"
    
    Range("C17").Select
    ActiveCell.FormulaR1C1 = "=R[-10]C"
    
    Range("C18").Select
    ActiveCell.FormulaR1C1 = "=R[-10]C"
    
    Range("D15").Select
    ActiveCell.FormulaR1C1 = "=R[-10]C"
    
    Range("D16").Select
    ActiveCell.FormulaR1C1 = "=R[-10]C"
    
    Range("D17").Select
    ActiveCell.FormulaR1C1 = "=R[-10]C"
    
    Range("D18").Select
    ActiveCell.FormulaR1C1 = "=R[-10]C"
    
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    ' now we do the hcahps data
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    Sheets("hcahps").Select
    Range("H9").Select
    ActiveCell.FormulaR1C1 = "=R[-7]C[1]"
    
    Range("I9").Select
    ActiveCell.FormulaR1C1 = "=R[-3]C[-1]"
    
    Range("J9").Select
    ActiveCell.FormulaR1C1 = "=R[-3]C[-1]"
        
    Range("K9").Select
    ActiveCell.FormulaR1C1 = "=R[-3]C[-1]"
    
    ActiveWindow.SmallScroll Down:=93
    
    Range("H108").Select
    ActiveCell.FormulaR1C1 = "=R[-7]C"
    
    Range("H109").Select
    ActiveCell.FormulaR1C1 = "=R[-7]C"
    
    Range("H110").Select
    ActiveCell.FormulaR1C1 = "=R[-7]C"
    
    Range("H111").Select
    ActiveCell.FormulaR1C1 = "=R[-7]C"
    
    Range("H112").Select
    ActiveCell.FormulaR1C1 = "=R[-7]C"
    
    Range("I108").Select
    ActiveCell.FormulaR1C1 = "=R[-7]C"
    
    Range("I109").Select
    ActiveCell.FormulaR1C1 = "=R[-7]C"
    
    Range("I110").Select
    ActiveCell.FormulaR1C1 = "=R[-7]C"
    
    Range("I111").Select
    ActiveCell.FormulaR1C1 = "=R[-7]C"
    
    Range("I112").Select
    ActiveCell.FormulaR1C1 = "=R[-7]C"
    
   
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    ' now we move onto the alos data current
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    
    Sheets("alos_pivot_current").Select
    
    Range("A15").Select
    ActiveCell.FormulaR1C1 = "=R[-9]C"
    
    Range("A16").Select
    ActiveCell.FormulaR1C1 = "=R[-9]C"
    
    Range("A17").Select
    ActiveCell.FormulaR1C1 = "=R[-9]C"
    
    Range("A18").Select
    ActiveCell.FormulaR1C1 = "=R[-9]C"
    
    Range("A19").Select
    ActiveCell.FormulaR1C1 = "=R[-9]C"
    
    Range("B15").Select
    ActiveCell.FormulaR1C1 = "=R[-9]C"
    
    Range("B16").Select
    ActiveCell.FormulaR1C1 = "=R[-9]C"
    
    Range("B17").Select
    ActiveCell.FormulaR1C1 = "=R[-9]C"
    
    Range("B18").Select
    ActiveCell.FormulaR1C1 = "=R[-9]C"
    
    Range("B19").Select
    ActiveCell.FormulaR1C1 = "=R[-9]C"
    
    Range("C15").Select
    ActiveCell.FormulaR1C1 = "=R[-9]C"
    
    Range("C16").Select
    ActiveCell.FormulaR1C1 = "=R[-9]C"
    
    Range("C17").Select
    ActiveCell.FormulaR1C1 = "=R[-9]C"
    
    Range("C18").Select
    ActiveCell.FormulaR1C1 = "=R[-9]C"
    
    Range("C19").Select
    ActiveCell.FormulaR1C1 = "=R[-9]C"
    
    Range("D15").Select
    ActiveCell.FormulaR1C1 = "=R[-9]C"
    
    Range("D16").Select
    ActiveCell.FormulaR1C1 = "=R[-9]C"
    
    Range("D17").Select
    ActiveCell.FormulaR1C1 = "=R[-9]C"
    
    Range("D18").Select
    ActiveCell.FormulaR1C1 = "=R[-9]C"
    
    Range("D19").Select
    ActiveCell.FormulaR1C1 = "=R[-9]C"
    
    Range("E15").Select
    ActiveCell.FormulaR1C1 = "=R[-9]C"
    
    Range("E16").Select
    ActiveCell.FormulaR1C1 = "=R[-9]C"
    
    Range("E17").Select
    ActiveCell.FormulaR1C1 = "=R[-9]C"
    
    Range("E18").Select
    ActiveCell.FormulaR1C1 = "=R[-9]C"
    
    Range("E19").Select
    ActiveCell.FormulaR1C1 = "=R[-9]C"
    
    Range("E15:E19").Select
    Selection.NumberFormat = "0.00"
    
    Range("F15").Select
    ActiveCell.FormulaR1C1 = "=R[-9]C"
    
    Range("F16").Select
    ActiveCell.FormulaR1C1 = "=R[-9]C"
    
    Range("F17").Select
    ActiveCell.FormulaR1C1 = "=R[-9]C"
    
    Range("F18").Select
    ActiveCell.FormulaR1C1 = "=R[-9]C"
    
    Range("F19").Select
    ActiveCell.FormulaR1C1 = "=R[-9]C"
    
    '''''''''''''''''''''''''''''''''
    ' alos trending data
    '''''''''''''''''''''''''''''''''
    
    Sheets("alos_pivot_trend").Select
    Range("A15").Select
    ActiveCell.FormulaR1C1 = "=R[-10]C"
    
    Range("A16").Select
    ActiveCell.FormulaR1C1 = "=R[-10]C"
    
    Range("A17").Select
    ActiveCell.FormulaR1C1 = "=R[-10]C"
    
    Range("A18").Select
    ActiveCell.FormulaR1C1 = "=R[-10]C"
    
    Range("B15").Select
    ActiveCell.FormulaR1C1 = "=R[-10]C"
    
    Range("B16").Select
    ActiveCell.FormulaR1C1 = "=R[-10]C"
    
    Range("B17").Select
    ActiveCell.FormulaR1C1 = "=R[-10]C"
    
    Range("B18").Select
    ActiveCell.FormulaR1C1 = "=R[-10]C"
    
    Range("C15").Select
    ActiveCell.FormulaR1C1 = "=R[-10]C"
    
    Range("C16").Select
    ActiveCell.FormulaR1C1 = "=R[-10]C"
    
    Range("C17").Select
    ActiveCell.FormulaR1C1 = "=R[-10]C"
    
    Range("C18").Select
    ActiveCell.FormulaR1C1 = "=R[-10]C"
    
    Range("C15:C18").Select
    Selection.NumberFormat = "0.00"
    
    Range("D15").Select
    ActiveCell.FormulaR1C1 = "=R[-10]C"
    
    Range("D16").Select
    ActiveCell.FormulaR1C1 = "=R[-10]C"
    
    Range("D17").Select
    ActiveCell.FormulaR1C1 = "=R[-10]C"
    
    Range("D18").Select
    ActiveCell.FormulaR1C1 = "=R[-10]C"
    
    Range("D15:D18").Select
    Selection.NumberFormat = "0.00"
    
    Sheets("report").Select

Application.ScreenUpdating = True
End Sub

'-----------------------------------------------------------------------

Sub m3_Report_Data_Processing()

Application.ScreenUpdating = False
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Report_Data_Error_Correction_Macro Macro
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' This macro will input all the data necessary along with some minor
' error correction into the "report data" tab
' This data is used by the "report" tab in order to generate a report
' for each physician
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

    Sheets("report data").Select
    
    Range("A2").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_current!RC[1]"
    
    Range("B2").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_current!R[13]C[-1]"
    
    Range("B3").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_current!R[13]C[-1]"
    
    Range("B4").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_current!R[13]C[-1]"
    
    Range("B5").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_current!R[13]C[-1]"
    
    Range("B6").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_current!R[13]C[-1]"
    
    Range("C2").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_current!R[13]C[-1]"
    
    Range("C3").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_current!R[13]C[-1]"
    
    Range("C4").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_current!R[13]C[-1]"
    
    Range("C5").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_current!R[13]C[-1]"
    
    Range("C6").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_current!R[13]C[-1]"
    
    Range("D2").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_current!R[13]C[-1]"
    
    Range("D3").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_current!R[13]C[-1]"
    
    Range("D4").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_current!R[13]C[-1]"
    
    Range("D5").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_current!R[13]C[-1]"
    
    Range("D6").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_current!R[13]C[-1]"
    
    Range("E2").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_current!R[13]C[-1]"
    
    Range("E3").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_current!R[13]C[-1]"
    
    Range("E4").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_current!R[13]C[-1]"
    
    Range("E5").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_current!R[13]C[-1]"
    
    Range("E6").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_current!R[13]C[-1]"
    
    Range("F2").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_current!R[13]C[-1]"
    
    Range("F3").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_current!R[13]C[-1]"
    
    Range("F4").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_current!R[13]C[-1]"
    
    Range("F5").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_current!R[13]C[-1]"
    
    Range("F6").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_current!R[13]C[-1]"
    
    Range("G2").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_current!R[13]C[-1]"
    
    Range("G3").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_current!R[13]C[-1]"
    
    Range("G4").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_current!R[13]C[-1]"
    
    Range("G5").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_current!R[13]C[-1]"
    
    Range("G6").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_current!R[13]C[-1]"
    
    Range("A9").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_trend!R[6]C"
    
    Range("A10").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_trend!R[6]C"
    
    Range("A11").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_trend!R[6]C"
    
    Range("A12").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_trend!R[6]C"
    
    Range("B9").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_trend!R[6]C"
    
    Range("B10").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_trend!R[6]C"
    
    Range("B11").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_trend!R[6]C"
    
    Range("B12").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_trend!R[6]C"
    
    Range("C9").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_trend!R[6]C"
    
    Range("C10").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_trend!R[6]C"
    
    Range("C11").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_trend!R[6]C"
    
    Range("C12").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_trend!R[6]C"
    
    Range("D9").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_trend!R[6]C"
    
    Range("D10").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_trend!R[6]C"
    
    Range("D11").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_trend!R[6]C"
    
    Range("D12").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_trend!R[6]C"
    
    Range("A15").Select
    ActiveCell.FormulaR1C1 = "=readmit_pivot_trend!RC"
    
    Range("A16").Select
    ActiveCell.FormulaR1C1 = "=readmit_pivot_trend!RC"
    
    Range("A17").Select
    ActiveCell.FormulaR1C1 = "=readmit_pivot_trend!RC"
    
    Range("A18").Select
    ActiveCell.FormulaR1C1 = "=readmit_pivot_trend!RC"
    
    Range("B15").Select
    ActiveCell.FormulaR1C1 = "=readmit_pivot_trend!RC"
    
    Range("B16").Select
    ActiveCell.FormulaR1C1 = "=readmit_pivot_trend!RC"
    
    Range("B17").Select
    ActiveCell.FormulaR1C1 = "=readmit_pivot_trend!RC"
    
    Range("B18").Select
    ActiveCell.FormulaR1C1 = "=readmit_pivot_trend!RC"
    
    Range("C15").Select
    ActiveCell.FormulaR1C1 = "=readmit_pivot_trend!RC"
    
    Range("C16").Select
    ActiveCell.FormulaR1C1 = "=readmit_pivot_trend!RC"
    
    Range("C17").Select
    ActiveCell.FormulaR1C1 = "=readmit_pivot_trend!RC"
    
    Range("C18").Select
    ActiveCell.FormulaR1C1 = "=readmit_pivot_trend!RC"
    
    Range("D15").Select
    ActiveCell.FormulaR1C1 = "=readmit_pivot_trend!RC"
    
    Range("D16").Select
    ActiveCell.FormulaR1C1 = "=readmit_pivot_trend!RC"
    
    Range("D17").Select
    ActiveCell.FormulaR1C1 = "=readmit_pivot_trend!RC"
    
    Range("D18").Select
    ActiveCell.FormulaR1C1 = "=readmit_pivot_trend!RC"
    
    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    ' HCAHPS DATA New Code
    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    '''''''''''''''''''''
    ' Current information
    '''''''''''''''''''''
    Range("A21").Select
    ActiveCell.FormulaR1C1 = "=hcahps!R[-12]C[7]"
    
    Range("B21").Select
    ActiveCell.FormulaR1C1 = "=hcahps!R[-12]C[7]"
    
    Range("C21").Select
    ActiveCell.FormulaR1C1 = "=hcahps!R[-12]C[7]"
    
    '''''''''''''''''''''''''
    ' add in response count
    '''''''''''''''''''''''''
    Range("D21").Select
    ActiveCell.FormulaR1C1 = "=hcahps!R[-12]c[7]"
    
    Range("A26").Select
    ActiveCell.FormulaR1C1 = "=hcahps!R[83]C[7]"
    
    Range("A27").Select
    ActiveCell.FormulaR1C1 = "=hcahps!R[83]C[7]"
    
    Range("A28").Select
    ActiveCell.FormulaR1C1 = "=hcahps!R[83]C[7]"
    
    Range("A29").Select
    ActiveCell.FormulaR1C1 = "=hcahps!R[83]C[7]"
    
    Range("B26").Select
    ActiveCell.FormulaR1C1 = "=hcahps!R[83]C[7]"
    Selection.Style = "Percent"
    
    Range("B27").Select
    ActiveCell.FormulaR1C1 = "=hcahps!R[83]C[7]"
    Selection.Style = "Percent"
    
    Range("B28").Select
    ActiveCell.FormulaR1C1 = "=hcahps!R[83]C[7]"
    Selection.Style = "Percent"
    
    Range("B29").Select
    ActiveCell.FormulaR1C1 = "=hcahps!R[83]C[7]"
    Selection.Style = "Percent"
    
    Range("B30").Select
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    ' END OF NEW HCAHPS CODE BLOCK
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    
'    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'    ' HCAHPS DATA OLD CODE
'    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'    Range("A21").Select
'    ActiveCell.FormulaR1C1 = "=hcahps_pivot_current!R[-10]C"
'
'    Range("A22").Select
'    ActiveCell.FormulaR1C1 = "=hcahps_pivot_current!R[-10]C"
'
'    Range("A23").Select
'    ActiveCell.FormulaR1C1 = "=hcahps_pivot_current!R[-10]C"
'
'    Range("B21").Select
'    ActiveCell.FormulaR1C1 = "=hcahps_pivot_current!R[-10]C[1]"
'
'    Range("B22").Select
'    ActiveCell.FormulaR1C1 = "=hcahps_pivot_current!R[-10]C[1]"
'
'    Range("B23").Select
'    ActiveCell.FormulaR1C1 = "=hcahps_pivot_current!R[-10]C[1]"
'
'    Range("C21").Select
'    ActiveCell.FormulaR1C1 = "=hcahps_pivot_current!R[-10]C[1]"
'
'    Range("C22").Select
'    ActiveCell.FormulaR1C1 = "=hcahps_pivot_current!R[-10]C[1]"
'
'    Range("C23").Select
'    ActiveCell.FormulaR1C1 = "=hcahps_pivot_current!R[-10]C[1]"
'
'
'     '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'     ' Trending information
'     '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'    Range("A26").Select
'    ActiveCell.FormulaR1C1 = "=hcahps_pivot_trend!R[-11]C"
'
'    Range("A27").Select
'    ActiveCell.FormulaR1C1 = "=hcahps_pivot_trend!R[-11]C"
'
'    Range("A28").Select
'    ActiveCell.FormulaR1C1 = "=hcahps_pivot_trend!R[-11]C"
'
'    Range("A29").Select
'    ActiveCell.FormulaR1C1 = "=hcahps_pivot_trend!R[-11]C"
'
'    Range("B26").Select
'    ActiveCell.FormulaR1C1 = "=hcahps_pivot_trend!R[-11]C"
'
'    Range("B27").Select
'    ActiveCell.FormulaR1C1 = "=hcahps_pivot_trend!R[-11]C"
'
'    Range("B28").Select
'    ActiveCell.FormulaR1C1 = "=hcahps_pivot_trend!R[-11]C"
'
'    Range("B29").Select
'    ActiveCell.FormulaR1C1 = "=hcahps_pivot_trend!R[-11]C"
'
    Sheets("report").Activate
    Sheets("report").Select

    Range("G1").Select
    ActiveCell.FormulaR1C1 = "=alos_pivot_current!rc[-5]"
    
    Sheets("hcahps report").Activate
    Sheets("hcahps report").Select
    
    Range("G1").Select
    ActiveCell.FormulaR1C1 = "=hcahps!RC[2]"
    
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''
    ' Make sure HCAHPS initial is set to Brookhaven and not
    ' (All), setting it to (All) will give the wrong percentile
    ' ranking
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''
    Sheets("hcahps").Select

    ActiveSheet.PivotTables("HcahpsPivotcurrentTable").PivotFields("Doctor"). _
        ClearAllFilters
        
    ActiveSheet.PivotTables("HcahpsPivotcurrentTable").PivotFields("Doctor"). _
        CurrentPage = "Brookhaven Memorial Hospital Medical Center - Filtered"
   
    ActiveSheet.PivotTables("HcahpsPivotTrendTable").PivotFields("Doctor"). _
        ClearAllFilters
        
    ActiveSheet.PivotTables("HcahpsPivotTrendTable").PivotFields("Doctor"). _
        CurrentPage = "Brookhaven Memorial Hospital Medical Center - Filtered"
        
    Range("I87").Select
    
Application.ScreenUpdating = True

End Sub

'-----------------------------------------------------------------------

Sub m5_HCAHPS_Macro()
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' This macro must be run last, it will produce the HCAHPS reports
' only for those that have data available in the latest quarter.
' The report tab will show the trend for the facility and then the
' hcahps report will show for the corresponding person
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

    ''''''''''''''''''''''''''''''''
    'Activate and select the desired sheet
    ''''''''''''''''''''''''''''''''
    Sheets("hcahps report").Activate
    Sheets("hcahps report").Select

    ''''''''''''''''''''''''''''''''
    ' create the desired variables
    ''''''''''''''''''''''''''''''''
    Dim vPhys2 As String
    Dim vrow2 As Long: vrow2 = 1
    Dim vlastphys2 As String

    Dim wksDoctors As Worksheet
    Dim wksHCAHPS As Worksheet

    '''''''''''''''''''''''''''''''''
    ' set the value of the sheet variables
    '''''''''''''''''''''''''''''''''
    Set wksHCAHPS = Sheets("hcahps")
    Set wksDoctors = Sheets("hcahps doctors")

    '''''''''''''''''''''''''''''''''
    ' set the value of vPhys2
    '''''''''''''''''''''''''''''''''
    vPhys2 = wksDoctors.Range("A" & CStr(vrow2)).Value

    '''''''''''''''''''''''''''''''''
    ' this will loop through the list of
    ' persons who have data
    '''''''''''''''''''''''''''''''''
    Do While (Len(vPhys2) > 1)
        wksHCAHPS.PivotTables("HcahpsPivotcurrentTable").PivotFields("Doctor").CurrentPage = vPhys2
        wksHCAHPS.PivotTables("HcahpsPivotTrendTable").PivotFields("Doctor").CurrentPage = vPhys2

        ActiveSheet.ExportAsFixedFormat Type:=xlTypePDF, _
            Filename:= _
            "G:\Phys Report Card\current reports\hcahps reports\" & vPhys2 & " hcahps.pdf", _
            Quality:=xlQualityStandard, _
            IncludeDocProperties:=True, _
            IgnorePrintAreas:=False, _
            OpenAfterPublish:=False

        vrow2 = vrow2 + 1
        vlastphys2 = vPhys2

        vPhys2 = wksDoctors.Range("A" & CStr(vrow2)).Value
    Loop

    MsgBox "All Done Here"
End Sub

'-----------------------------------------------------------------------

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' This macro will run through all the physicians and loop through
' the data they have in the pivot tables and list it on the report
' tab and generate their quarterly report
' Data comes from LIHN
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

Sub Button1_Click()

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Define variables
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Dim vPhys As String
Dim vrow As Long
Dim vlastphys As String

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' We want to start on Row 2 of the sheet
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
vrow = 2

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' This pushes us to the next row in the PhysListing sheet in order to
' obtain the name of the next physician that we want to generate data
' for
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
nextRow:

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' This will select the PhysListing Sheet and make it the active sheet
' it will then select the row number from vrow
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Sheets("PhysListing").Activate
Range("A" & CStr(vrow)).Select
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Select the physician by selecting the cell that vrow landed us on
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
vPhys = ActiveCell.Value

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' This can be uncommented to see that the above does in fact move us
' down the list of doctors
' MsgBox vPhys <-- uncomment
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' This tells us to stop going down the list when the nextRow is empty
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
If Len(vPhys) < 1 Then
    MsgBox "ALL DONE"
    GoTo subcomplete
End If

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' DO FIELD settings here. This is where we are going to grab data from
' the pivot tables which will update the report data tab so the phys
' report can be generated and saved to disk with the filename being the
' attending physicians name.
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Sheets("readmit_pivot_trend").Activate
    With ActiveSheet.PivotTables("PivotTable1").PivotFields("Attending Physician")
        .CurrentPage = vPhys
    End With

'''''''''''''''''''''''''
' New HCAHPS here
'''''''''''''''''''''''''
'Sheets("hcahps").Activate
'
'    If ActiveSheet.PivotTables("HcahpsPivotcurrentTable").PivotFields("Doctor").CurrentPage = vPhys Then
'
'        With ActiveSheet.PivotTables("HcahpsPivotcurrentTable").PivotFields("Doctor").CurrentPage = vPhys
'        End With
'
'        Else: ActiveSheet.PivotTables("HcahpsPivotcurrentTable").PivotFields("Doctor").CurrentPage = "(All)"
'    End If
'
'    If ActiveSheet.PivotTables("HcahpsPivotTrendTable").PivotFields("Doctor").CurrentPage = vPhys Then
'
'        With ActiveSheet.PivotTables("HcahpsPivotTrendTable").PivotFields("Doctor").CurrentPage = vPhys
'        End With
'
'        Else: ActiveSheet.PivotTables("HcahpsPivotTrendTable").PivotFields("Doctor").CurrentPage = "(All)"
'    End If

'''''''''''''''''''''''''
' End of new HCAHPS
'''''''''''''''''''''''''

'''''''''''''''''''''''''
' Old HCAHPS
'''''''''''''''''''''''''
'need to fix this
'Sheets("hcahps_pivot_current").Activate
'    With ActiveSheet.PivotTables("HcahpsPivotCurrentTable").PivotFields("Attending Physician")
'            .CurrentPage = vPhys
'    End With
'
'need to fix this
'Sheets("hcahps_pivot_trend").Activate
'    With ActiveSheet.PivotTables("HcahpsPivotTrendTable").PivotFields("Attending Physician")
'            .CurrentPage = vPhys
'    End With
''''''''''''''''''''''''
' End of OLD HCAHPS
''''''''''''''''''''''''

Sheets("alos_pivot_current").Activate
    With ActiveSheet.PivotTables("AlosPivotCurrentTable").PivotFields("Attending Physician")
            .CurrentPage = vPhys
    End With

Sheets("alos_pivot_trend").Activate
    With ActiveSheet.PivotTables("AlosPivotTrendTable").PivotFields("Attending Physician")
            .CurrentPage = vPhys
    End With

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' This opens up the report sheet and saves the file to disk
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Sheets("report").Activate

ActiveSheet.ExportAsFixedFormat Type:=xlTypePDF, _
    Filename:= _
    "G:\Phys Report Card\current reports\" & vPhys & ".pdf", _
    Quality:=xlQualityStandard, _
    IncludeDocProperties:=True, _
    IgnorePrintAreas:=False, _
    OpenAfterPublish:=False

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' This forces the vrow to increment by one on the PhysListing sheet
' so that we can get data on the next doctor in the list
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
vrow = vrow + 1
vlastphys = vPhys

GoTo nextRow

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' After we have gone through all the data, this ends the routine that
' the button runs on, we then exit and end the sub
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
subcomplete:

Exit Sub

End Sub

'-----------------------------------------------------------------------

Sub mstr_Run_All_Macro()

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' This macro will run all of the macros in the correct order, so that
' the report can be run in one click
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    '''''''''''''''''''''''
    ' Setup Pivot Tables
    '''''''''''''''''''''''
    Application.Run "'per data.xlsm'!m1_PivotSetUp_Macro"
    
    '''''''''''''''''''''''
    ' Pre-Process Data
    '''''''''''''''''''''''
    Application.Run "'per data.xlsm'!m2_Data_Pre_Processing"
    
    '''''''''''''''''''''''
    ' Get data into report fields
    '''''''''''''''''''''''
    Application.Run "'per data.xlsm'!m3_Report_Data_Processing"
    
    '''''''''''''''''''''''
    ' Run Report with static Brookhaven HCAHPS Score
    '''''''''''''''''''''''
    Application.Run "'per data.xlsm'!Button1_Click"
    
    '''''''''''''''''''''''
    ' Now run the HCAHPS Reports
    '''''''''''''''''''''''
    Application.Run "'per data.xlsm'!m4_HCAHPS_Macro"
    
    '''''''''''''''''''''''
    ' Cleanup the workbook
    '''''''''''''''''''''''
    Application.Run "'per data.xlsm'!cleanup"
    
    
End Sub
