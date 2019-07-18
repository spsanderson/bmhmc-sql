Option Explicit

Const msModule As String = "Scripts"

Sub Main()
    On Error GoTo ErrorHandler: Const procName = "Main"

    ' check if logins succeed into all the applications, if any fail to login, send a fatal notification email.
    'CheckAppsSuccessfulLogin

    ' read setup file
    ReadSetupAndInitialize
    
    ' stop heartbeat monitor
    StopHeartbeatMonitor

    ' check that Heartbeat is still running
    If IsProcessRunning("BWSHeartbeat.exe") = False Then
        StartHeartbeatMonitor
    End If
    
    'Stop
    ' check if there are any flies left over. If they do, move the files that are currently being processed to error ( BrookHaven\Results\ErroredFiles ) folder for manual review and process rest of the files.
    'Stop
    If CheckAnyLeftOverFiles Then
        ' keep going
    Else
        'Stop
        StockampCreateWorkList
        LogThis "Stockamp worklists created."
    End If

    Wait 5
    'Stop
    StockampReadData
    LogThis "Stockamp demographic read completed."

    'Stop
    Wait 5
    SMSNetReadData
    LogThis "SMSNet account information read completed."

    'Stop
    Wait 5
    HealthFirst    ' i04
    LogThis "HealthFirst account information read completed."

    'Stop
    Wait 5
    OPTUM    ' I010 ,J010, X022, K015,E008 unitedhealth
    LogThis "Optum account information read completed."

    'Affinity Medicaid i01
    'Stop
    AffinityMedicaid
    Wait 5
    LogThis "AffinityMedicaid account information read completed."

    'Affinity Essentials / J01
    'Affinity Medicare  E14

    'Stop
    UpdateSMSStockampAccountData
    
    ' stop heartbeat monitor
    StopHeartbeatMonitor

    Exit Sub
ErrorHandler:
    Logging "ERROR: MODULE: " & msModule & " SUB: " & procName & " :" & Err.Number & ":" & Err.Description
    SendStatusEmail2 goConfig, "Brookhaven Automation completed."

    ' clean up any objects
    WrapUp

    KillAnyAppsOpen
    Shutdown = True    ' use this if project is scheduled using Windows Task Scheduler TODO

End Sub

