Public StartProcessingTime As Date
Public Const Status_REVIEW As String = "BOOKHAVEN_REVIEW"
Public Const Status_BSS_REVIEW As String = "BSS_REVIEW"
Public Const StatusText_OK As String = "COMPLETE"
Public DatastationColumns()
Public oDataStockamp As cDataStockamp
Public oDataSMSNet As cDataSMSNet
Public oDataHealthFirst As cDataHealthFirst
Public oDataOPTUM As cDataOPTUM
Public oDataAffinityMedicaid As cDataAffinityMedicaid
Public oDataSMSNetUpd As cDataSMSNetUpd
Public DebugMode As Boolean
Public B2 As New BostonWorkStation
Public HeartbeatBatchFile As String
'Public Const HeartbeatTimeoutPeriod As Integer = 90
Public Const HeartbeatTimeoutPeriod As Integer = 900    ' 15 minutes
