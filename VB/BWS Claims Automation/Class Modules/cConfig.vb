Option Explicit
' login information
Private msLoginUserID As String
Private msLoginPassword As String
Private msLoginURL As String
Private msAnchorURL As String
Private msLoginCaption As String
Private msWebSiteName As String
Private msProjectFolderPath As String
Private msLogFolderPath As String
Private msLogFileName As String
Private msProjectName As String
Private msMachineName As String

' folder and files
Private msProcessDir As String
'Private msReportsFolder As String
Private msReportsFolder As String
Private msReportFileName As String
Private msInputFilePrefix As String
Private msBDSFileCSV As String
Private msBDSFileTXT As String
Private msSubmitReportFolder As String
Private mnSubmitReportTimeout As Integer

' number of IE restarts and Web Timeout
Private mnMaxIERestarts As Integer
Private mnWebTimeout As Integer
Private mnLogInd As Integer
Private mnDeleteLogsAfterDays As Integer

' configuration file
Private msConfigurationFile As String
Private msConfigurationBDSFile As String
Private msReportBDSFile As String

' email login/server information
Private msEMailServer As String
Private msEMailUserID As String
Private msEMailPassword As String
Private msStatusNotifyEmailID As String

' sql source/updates
Private msSourceSQLClaim As String
Private msSourceSQLClaimSvcLine As String
Private msUpdateSQL As String
Private msDBUserName As String
Private msDBPassword As String
Private msDBConnectString As String

' ineternet explorer path
Private msInternetExplorerPath As String

' process date time
Private msProcessDttm As String

' attach files manually
Private mbAttachFilesManually As Boolean
Private msAttachFileFolder As String

Private mlKey As Long

Public InputFileName As String
Public outputFileName As String
Public SMSNetExe As String
Public SMSNetLoginCaption As String
Public SMSUserName As String
Public SMSPassword As String
Public HFLoginUserID As String
Public HFLoginPassword As String
Public HFLoginURL As String
Public HFLoginCaption As String
Public HFWebSiteName As String
Public OPTUMLoginUserID As String
Public OPTUMLoginPassword As String
Public OPTUMLoginURL As String
Public OPTUMLoginCaption As String
Public OPTUMWebSiteName As String
Public AFMedicaidLoginUserID As String
Public AFMedicaidLoginPassword As String
Public AFMedicaidLoginURL As String
Public AFMedicaidLoginCaption As String
Public AFMedicaidWebSiteName As String

Public Property Get LoginUserID() As String
    LoginUserID = msLoginUserID
End Property

Public Property Let LoginUserID(ByVal sLoginUserID As String)
    msLoginUserID = sLoginUserID
End Property

Public Property Get LoginPassword() As String
    LoginPassword = msLoginPassword
End Property

Public Property Let LoginPassword(ByVal sLoginPassword As String)
    msLoginPassword = sLoginPassword
End Property

Public Property Get LoginURL() As String
    LoginURL = msLoginURL
End Property

Public Property Let LoginURL(ByVal sLoginURL As String)
    msLoginURL = sLoginURL
End Property

Public Property Get AnchorURL() As String
    AnchorURL = msAnchorURL
End Property

Public Property Let AnchorURL(ByVal sAnchorURL As String)
    msAnchorURL = sAnchorURL
End Property

Public Property Get LoginCaption() As String
    LoginCaption = msLoginCaption
End Property

Public Property Let LoginCaption(ByVal sLoginCaption As String)
    msLoginCaption = sLoginCaption
End Property

Public Property Get WebSiteName() As String
    WebSiteName = msWebSiteName
End Property

Public Property Let WebSiteName(ByVal sWebSiteName As String)
    msWebSiteName = sWebSiteName
End Property

Public Property Get ProjectFolderPath() As String
    ProjectFolderPath = msProjectFolderPath
End Property

Public Property Let ProjectFolderPath(ByVal sProjectFolderPath As String)
    msProjectFolderPath = sProjectFolderPath
End Property

Public Property Get LogFolderPath() As String
    LogFolderPath = msLogFolderPath
End Property

Public Property Let LogFolderPath(ByVal sLogFolderPath As String)
    msLogFolderPath = sLogFolderPath
End Property

Public Property Get LogFileName() As String
    LogFileName = msLogFileName
End Property

Public Property Let LogFileName(ByVal sLogFileName As String)
    msLogFileName = sLogFileName
End Property

Public Property Get ProjectName() As String
    ProjectName = msProjectName
End Property

Public Property Let ProjectName(ByVal sProjectName As String)
    msProjectName = sProjectName
End Property

Public Property Get ProcessDir() As String
    ProcessDir = msProcessDir
End Property

Public Property Let ProcessDir(ByVal sProcessDir As String)
    On Error GoTo ErrorHandler

    Dim sInptFolder As String
    ' check folder names are correct
    sInptFolder = sProcessDir
    If Right$(sInptFolder, 1) <> "\" Then
        sInptFolder = sInptFolder & "\"
    End If
    msProcessDir = sInptFolder
    Exit Property
ErrorHandler:
    Logging "ERROR: CLASS: cConfig PROPERTY LET: ProcessDir :" & Err.Number & ":" & Err.Description
End Property
'
'Public Property Get ReportsFolder() As String
'    ReportsFolder = msReportsFolder
'End Property
'
'Public Property Let ReportsFolder(ByVal sReportsFolder As String)
'    msReportsFolder = sReportsFolder
'End Property

Public Property Get ReportsFolder() As String
    ReportsFolder = msReportsFolder
End Property

Public Property Let ReportsFolder(ByVal sReportsFolder As String)
    On Error GoTo ErrorHandler

    Dim sRptFolder As String
    ' check folder names are correct
    sRptFolder = sReportsFolder
    If sRptFolder = vbNullString Then
        'do nothing
    Else
        If Right$(sRptFolder, 1) <> "\" Then
            sRptFolder = sRptFolder & "\"
        End If
        msReportsFolder = sRptFolder
    End If

    Exit Property
ErrorHandler:
    Logging "ERROR: CLASS: cConfig PROPERTY LET: ReportsFolder :" & Err.Number & ":" & Err.Description
End Property

Public Property Get ReportFileName() As String
    ReportFileName = msReportFileName
End Property

Public Property Let ReportFileName(ByVal sReportFileName As String)
    msReportFileName = sReportFileName
End Property

Public Property Get InputFilePrefix() As String
    InputFilePrefix = msInputFilePrefix
End Property

Public Property Let InputFilePrefix(ByVal sInputFilePrefix As String)
    On Error GoTo ErrorHandler

    Dim sInputFile As String

    msInputFilePrefix = sInputFilePrefix
    If UCase(d("Required")) = "YES" Then
        ' check for input files, if needed
        sInputFile = Dir$(msProcessDir & msInputFilePrefix & "*.csv")
        If sInputFile = "" Then
            sInputFile = Dir$(msProcessDir & msInputFilePrefix & "*.txt")
        End If
        If sInputFile = "" Then
            Note = "No input files to process."

            Shutdown = True
        End If
    End If
    Exit Property
ErrorHandler:
    Logging "ERROR: CLASS: cConfig PROPERTY LET: InputFilePrefix :" & Err.Number & ":" & Err.Description
End Property

Public Property Get BDSFileCSV() As String
    BDSFileCSV = msBDSFileCSV
End Property

Public Property Let BDSFileCSV(ByVal sBDSFileCSV As String)
    msBDSFileCSV = sBDSFileCSV
End Property

Public Property Get BDSFileTXT() As String
    BDSFileTXT = msBDSFileTXT
End Property

Public Property Let BDSFileTXT(ByVal sBDSFileTXT As String)
    msBDSFileTXT = sBDSFileTXT
End Property

Public Property Get MaxIERestarts() As Integer
    MaxIERestarts = mnMaxIERestarts
End Property

Public Property Let MaxIERestarts(ByVal nMaxIERestarts As Integer)
' default it to 20
    If nMaxIERestarts = 0 Then
        mnMaxIERestarts = 20
    Else
        mnMaxIERestarts = nMaxIERestarts
    End If
End Property

Public Property Get WebTimeout() As Integer
    WebTimeout = mnWebTimeout
End Property

Public Property Let WebTimeout(ByVal nWebTimeout As Integer)
' default it to 40
    If nWebTimeout = 0 Then
        mnWebTimeout = 40
    Else
        mnWebTimeout = nWebTimeout
    End If
End Property

Public Property Get SubmitReportTimeout() As Integer
    SubmitReportTimeout = mnSubmitReportTimeout
End Property

Public Property Let SubmitReportTimeout(ByVal nSubmitReportTimeout As Integer)
' default it to 360
    If nSubmitReportTimeout <= 360 Then
        mnSubmitReportTimeout = 360
    Else
        mnSubmitReportTimeout = nSubmitReportTimeout
    End If
End Property


Public Property Get DeleteLogsAfterDays() As Integer
    DeleteLogsAfterDays = mnDeleteLogsAfterDays
End Property

Public Property Let DeleteLogsAfterDays(ByVal nDeleteLogsAfterDays As Integer)
' default it to 14
    If nDeleteLogsAfterDays <= 0 Then
        mnDeleteLogsAfterDays = 14
    Else
        mnDeleteLogsAfterDays = nDeleteLogsAfterDays
    End If
End Property

Public Property Get LogInd() As Integer
    LogInd = mnLogInd
End Property

Public Property Let LogInd(ByVal nLogInd As Integer)
    mnLogInd = nLogInd
End Property

Public Property Get ConfigurationFile() As String
    ConfigurationFile = msConfigurationFile
End Property

Public Property Let ConfigurationFile(ByVal sConfigurationFile As String)
    msConfigurationFile = sConfigurationFile
End Property

Public Property Get ConfigurationBDSFile() As String
    ConfigurationBDSFile = msConfigurationBDSFile
End Property

Public Property Let ConfigurationBDSFile(ByVal sConfigurationBDSFile As String)
    msConfigurationBDSFile = sConfigurationBDSFile
End Property

Public Property Get ReportBDSFile() As String
    ReportBDSFile = msReportBDSFile
End Property

Public Property Let ReportBDSFile(ByVal sReportBDSFile As String)
    msReportBDSFile = sReportBDSFile
End Property

Public Property Get EmailServer() As String
    EmailServer = msEMailServer
End Property

Public Property Let EmailServer(ByVal sEmailServer As String)
    msEMailServer = sEmailServer
End Property

Public Property Get EMailUserID() As String
    EMailUserID = msEMailUserID
End Property

Public Property Let EMailUserID(ByVal sEMailUserID As String)
    msEMailUserID = sEMailUserID
End Property

Public Property Get EMailPassword() As String
    EMailPassword = msEMailPassword
End Property

Public Property Let EMailPassword(ByVal sEMailPassword As String)
    msEMailPassword = sEMailPassword
End Property

Public Property Get StatusNotifyEmailID() As String
    StatusNotifyEmailID = msStatusNotifyEmailID
End Property

Public Property Let StatusNotifyEmailID(ByVal sStatusNotifyEmailID As String)
    msStatusNotifyEmailID = sStatusNotifyEmailID
End Property

Public Property Get SourceSQLClaim() As String
    SourceSQLClaim = msSourceSQLClaim
End Property

Public Property Let SourceSQLClaim(ByVal sSourceSQLClaim As String)
    msSourceSQLClaim = sSourceSQLClaim
End Property

Public Property Get SourceSQLClaimSvcLine() As String
    SourceSQLClaimSvcLine = msSourceSQLClaimSvcLine
End Property

Public Property Let SourceSQLClaimSvcLine(ByVal sSourceSQLClaimSvcLine As String)
    msSourceSQLClaimSvcLine = sSourceSQLClaimSvcLine
End Property

Public Property Get UpdateSQL() As String
    UpdateSQL = msUpdateSQL
End Property

Public Property Let UpdateSQL(ByVal sUpdateSQL As String)
    msUpdateSQL = sUpdateSQL
End Property

Public Property Get DBUserName() As String
    DBUserName = msDBUserName
End Property

Public Property Let DBUserName(ByVal sDBUserName As String)
    msDBUserName = sDBUserName
End Property

Public Property Get DBPassword() As String
    DBPassword = msDBPassword
End Property

Public Property Let DBPassword(ByVal sDBPassword As String)
    msDBPassword = sDBPassword
End Property

Public Property Get DBConnectString() As String
    DBConnectString = msDBConnectString
End Property

Public Property Let DBConnectString(ByVal sDBConnectString As String)
    msDBConnectString = sDBConnectString
End Property

Public Property Get InternetExplorerPath() As String
    InternetExplorerPath = msInternetExplorerPath
End Property

Public Property Let InternetExplorerPath(ByVal sInternetExplorerPath As String)
    msInternetExplorerPath = sInternetExplorerPath
End Property

Public Property Get ProcessDtTm() As String
    ProcessDtTm = msProcessDttm
End Property

Public Property Let ProcessDtTm(ByVal sProcessDtTm As String)
    msProcessDttm = sProcessDtTm
End Property

Public Property Get MachineName() As String
    MachineName = msMachineName
End Property

Public Property Let MachineName(ByVal sMachineName As String)
    msMachineName = sMachineName
End Property

Public Property Get Key() As Long
    Key = mlKey
End Property

Public Property Let Key(ByVal lKey As Long)
    mlKey = lKey
End Property

Public Property Get SubmitReportFolder() As String
    SubmitReportFolder = msSubmitReportFolder
End Property

Public Property Let SubmitReportFolder(ByVal sSubmitReportFolder As String)
    msSubmitReportFolder = sSubmitReportFolder
End Property

Private Sub ReadConfigFileAndInitializeVars()
    On Error GoTo ErrorHandler

    ' load configuration file
    d.Open_ msConfigurationFile, ftExcel, msConfigurationBDSFile

    ' handle spaces before and after
    d.Trim = True

    Do Until d.EOF
        Select Case UCase(d("FieldName"))
        Case "LOGINUSERID"
            LoginUserID = ValidateField(d("Value"), d("Required"), "Please provide Login UserID.")
        Case "LOGINPASSWORD"
            LoginPassword = ValidateField(d("Value"), d("Required"), "Please provide Login Password.")
        Case "LOGINURL"
            LoginURL = ValidateField(d("Value"), d("Required"), "Please provide Login URL.")
        Case "ANCHORURL"
            AnchorURL = ValidateField(d("Value"), d("Required"), "Please provide Anchor URL.")
        Case "LOGINCAPTION"
            LoginCaption = ValidateField(d("Value"), d("Required"), "Please provide Login Caption.")
        Case "WEBSITENAME"
            WebSiteName = ValidateField(d("Value"), d("Required"), "Please provide Web Site name.")
        Case "PROCESSDIR"
            ProcessDir = ValidateField(d("Value"), d("Required"), "Please provide Input Folder.")
        Case "REPORTSFOLDER"
            ReportsFolder = ValidateField(d("Value"), d("Required"), "You may provide Reports Folder if not it will be created in the project folder.")
        Case "INPUTFILEPREFIX"
            InputFilePrefix = ValidateField(d("Value"), d("Required"), "Please provide Input File Prefix.")
        Case "BDSFILECSV"
            BDSFileCSV = ValidateField(d("Value"), d("Required"), "Please provide BDS File CSV.")
        Case "BDSFILETXT"
            BDSFileTXT = ValidateField(d("Value"), d("Required"), "You may provide BDS File TXT.")
        Case "MAXIERESTARTS"
            MaxIERestarts = ValidateField(d("Value"), d("Required"), "You may provide Max IE restart number otherwise it will be defaulted to 20.")
        Case "WEBTIMEOUT"
            WebTimeout = ValidateField(d("Value"), d("Required"), "You may provide Web Timeout otherwise it will be defaulted to 40 secs.")
        Case "DELETELOGSAFTERDAYS"""
            DeleteLogsAfterDays = ValidateField(d("Value"), d("Required"), "You may provide Number of days to hold the log/error/archive files. It will be defaulted to 14 days.")
        Case "EMAILSERVER"
            EmailServer = ValidateField(d("Value"), d("Required"), "Please provide Email Server.")
        Case "EMAILUSERID"
            EMailUserID = ValidateField(d("Value"), d("Required"), "Please provide Email UserID.")
        Case "EMAILPASSWORD"
            EMailPassword = ValidateField(d("Value"), d("Required"), "Please provide Email Password.")
        Case "STATUSNOTIFYEMAILID"
            StatusNotifyEmailID = ValidateField(d("Value"), d("Required"), "Please provide Status Notify EmailID.")
        Case "SOURCESQLCLAIM"
            SourceSQLClaim = ValidateField(d("Value"), d("Required"), "Please provide Source CLaim SQL select statement.")
        Case "SOURCESQLCLAIMSVCLINE"
            SourceSQLClaimSvcLine = ValidateField(d("Value"), d("Required"), "Please provide Source Claim Svc Line SQL select statement.")
        Case "UPDATESQL"
            UpdateSQL = ValidateField(d("Value"), d("Required"), "Please provide SQL update statement.")
        Case "DBUSERNAME"
            DBUserName = ValidateField(d("Value"), d("Required"), "Please provide Database Username.")
        Case "DBPASSWORD"
            DBPassword = ValidateField(d("Value"), d("Required"), "Please provide Database Password.")
        Case "DBCONNECTSTRING"
            DBConnectString = ValidateField(d("Value"), d("Required"), "Please provide Database Connection String.")
        Case "INTERNETEXPLORERPATH"
            InternetExplorerPath = ValidateField(d("Value"), d("Required"), "Please provide internet explorer application path.")
        Case "LOGIND"
            LogInd = ValidateField(d("Value"), d("Required"), "You may provide log indicator otherwise will be defaulted to 0")
        Case "SUBMITREPORTFOLDER"
            SubmitReportFolder = ValidateField(d("Value"), d("Required"), "You may provide Submit Report folder")
        Case "SUBMITREPORTTIMEOUT"
            SubmitReportTimeout = ValidateField(d("Value"), d("Required"), "You may provide Submit Report Timeout otherwise it will be defaulted to 360 secs.")
        Case "ATTACHFILESMANUALLY"
            AttachFileManullay = ValidateField(d("Value"), d("Required"), "You may set Attach Files Manually value.")
        Case "ATTACHFILEFOLDER"
            AttachFileFolder = ValidateField(d("Value"), d("Required"), "Please provide Attachment(file)s folder.")
        Case "SMSEXE"
            SMSNetExe = ValidateField(d("Value"), d("Required"), "Please provide Exe path.")
        Case "SMSLOGINCAPTION"
            SMSNetLoginCaption = ValidateField(d("Value"), d("Required"), "Please provide login caption.")
        Case "SMSUSERNAME"
            SMSUserName = ValidateField(d("Value"), d("Required"), "Please provide SMS username.")
        Case "SMSPASSWORD"
            SMSPassword = ValidateField(d("Value"), d("Required"), "Please provide SMS password.")
        Case "HFLOGINUSERID"
            HFLoginUserID = ValidateField(d("Value"), d("Required"), "Please provide HF Login UserID.")
        Case "HFLOGINPASSWORD"
            HFLoginPassword = ValidateField(d("Value"), d("Required"), "Please provide HF Login Password.")
        Case "HFLOGINURL"
            HFLoginURL = ValidateField(d("Value"), d("Required"), "Please provide HF Login URL.")
        Case "HFLOGINCAPTION"
            HFLoginCaption = ValidateField(d("Value"), d("Required"), "Please provide HF Login Caption.")
        Case "HFWEBSITENAME"
            HFWebSiteName = ValidateField(d("Value"), d("Required"), "Please provide HF Web Site name.")
        Case "OPTUMLOGINUSERID"
            OPTUMLoginUserID = ValidateField(d("Value"), d("Required"), "Please provide OPTUM Login UserID.")
        Case "OPTUMLOGINPASSWORD"
            OPTUMLoginPassword = ValidateField(d("Value"), d("Required"), "Please provide OPTUM Login Password.")
        Case "OPTUMLOGINURL"
            OPTUMLoginURL = ValidateField(d("Value"), d("Required"), "Please provide OPTUM Login URL.")
        Case "OPTUMLOGINCAPTION"
            OPTUMLoginCaption = ValidateField(d("Value"), d("Required"), "Please provide OPTUM Login Caption.")
        Case "OPTUMWEBSITENAME"
            OPTUMWebSiteName = ValidateField(d("Value"), d("Required"), "Please provide OPTUM Web Site name.")
        Case "AFMEDICAIDLOGINUSERID"
            AFMedicaidLoginUserID = ValidateField(d("Value"), d("Required"), "Please provide AFMEDICAID Login UserID.")
        Case "AFMEDICAIDLOGINPASSWORD"
            AFMedicaidLoginPassword = ValidateField(d("Value"), d("Required"), "Please provide AFMEDICAID Login Password.")
        Case "AFMEDICAIDLOGINURL"
            AFMedicaidLoginURL = ValidateField(d("Value"), d("Required"), "Please provide AFMEDICAID Login URL.")
        Case "AFMEDICAIDLOGINCAPTION"
            AFMedicaidLoginCaption = ValidateField(d("Value"), d("Required"), "Please provide AFMEDICAID Login Caption.")
        Case "AFMEDICAIDWEBSITENAME"
            AFMedicaidWebSiteName = ValidateField(d("Value"), d("Required"), "Please provide AFMEDICAID Web Site name.")
        End Select
        d.Next_
    Loop

    d.Close_

    Exit Sub
ErrorHandler:
    Logging "ERROR: CLASS: cConfig SUB: ReadConfigFileAndInitializeVars :" & Err.Number & ":" & Err.Description
End Sub

Private Sub Class_Initialize()
    On Error GoTo ErrorHandler

    ' initialize variables
    mlKey = 0
    msAnchorURL = vbNullString
    msLoginUserID = vbNullString
    msLoginURL = vbNullString
    msLoginCaption = vbNullString
    msLoginPassword = vbNullString
    msLoginCaption = vbNullString
    msWebSiteName = vbNullString
    msProjectFolderPath = vbNullString
    msLogFolderPath = vbNullString
    msLogFileName = vbNullString
    msProjectName = vbNullString
    msProcessDir = vbNullString
    msReportsFolder = vbNullString
    msReportFileName = vbNullString
    '    msReportsFolder = vbNullString
    msInputFilePrefix = vbNullString
    msBDSFileCSV = vbNullString
    msBDSFileTXT = vbNullString
    mnMaxIERestarts = 0
    mnWebTimeout = 0
    mnSubmitReportTimeout = 0
    mnLogInd = 0
    mnDeleteLogsAfterDays = 0
    msConfigurationFile = vbNullString
    msConfigurationBDSFile = vbNullString
    msReportBDSFile = vbNullString
    msEMailServer = vbNullString
    msEMailUserID = vbNullString
    msEMailPassword = vbNullString
    msStatusNotifyEmailID = vbNullString
    msSourceSQLClaim = vbNullString
    msSourceSQLClaimSvcLine = vbNullString
    msUpdateSQL = vbNullString
    msDBUserName = vbNullString
    msDBPassword = vbNullString
    msDBConnectString = vbNullString
    msInternetExplorerPath = vbNullString
    msProcessDttm = vbNullString
    msMachineName = vbNullString
    msSubmitReportFolder = vbNullString
    mbAttachFilesManually = False
    msAttachFileFolder = vbNullString
    OPTUMLoginUserID = vbNullString
    OPTUMLoginPassword = vbNullString
    OPTUMLoginURL = vbNullString
    OPTUMLoginCaption = vbNullString
    OPTUMWebSiteName = vbNullString
    AFMedicaidLoginUserID = vbNullString
    AFMedicaidLoginPassword = vbNullString
    AFMedicaidLoginURL = vbNullString
    AFMedicaidLoginCaption = vbNullString
    AFMedicaidWebSiteName = vbNullString

    ' project folder
    ProjectFolderPath = Left$(ScriptName, InStrRev(ScriptName, "\"))

    ' log folder dir - create this folder
    LogFolderPath = ProjectFolderPath & "Log\"

    ' create folders if they don't exist
    CreateFolder LogFolderPath

    ' project name
    ProjectName = goFSO.GetBaseName(ScriptName)

    ' process date time
    ProcessDtTm = Format(Date, "mmddyyyy")

    ' logfile
    LogFileName = ProjectName & "_Log_" & ProcessDtTm & ".txt"

    ' turn on logging
    Share("Logging") = LogFolderPath & LogFileName & "| ID_Log_Enabled || ID_Log_Notes|"

    Note = vbCrLf & ProjectName & " Project Started."

    ' machine name
    MachineName = GetMachineName()

    ' check if setup bds file exists
    ConfigurationBDSFile = msProjectFolderPath & "Setup\Setup.bds"

    ' check if the file actually exists
    ValidateField Dir$(ConfigurationBDSFile), "YES", "Please provide Setup BDS File."

    '    ' check if report bds file exists
    '    ReportBDSFile = msProjectFolderPath & "Setup\Report.bds"
    '
    '    ' check if the file actually exists
    '    ValidateField Dir$(ReportBDSFile), "YES", "Please provide Report BDS File."

    ConfigurationFile = msProjectFolderPath & "Setup\Setup.xlsx"

    ' check if the file actually exists
    ValidateField Dir$(ConfigurationFile), "YES", "Please provide Setup File."

    'if reports folder not specified then create one
    ReportsFolder = ProjectFolderPath & "Report\"

    ' read config file
    ReadConfigFileAndInitializeVars

    ' report file
    If InputFilePrefix = vbNullString Then
        ReportFileName = ReportsFolder & ProjectName & "_" & ProcessDtTm & "_REPORT.csv"
    Else
        ReportFileName = ReportsFolder & InputFilePrefix & "_" & ProcessDtTm & "_REPORT.csv"
    End If

    ' create reports folder if it did not exist already
    CreateFolder ReportsFolder
    Exit Sub
ErrorHandler:
    Logging "ERROR: CLASS: cConfig SUB: Class_Initialize :" & Err.Number & ":" & Err.Description
End Sub

Private Function ValidateField(sData As String, sRequired As String, sErrorMessage As String) As String
    On Error GoTo ErrorHandler
    ' if it is a required field and not filled in send an email and end the application otherwise log message and keep going
    If sData = vbNullString And UCase(sRequired) = "YES" Then
        SendFatalError StatusNotifyEmailID, ProjectName, MachineName, EmailServer, EMailUserID, EMailPassword, sErrorMessage
    ElseIf sData = vbNullString Then
        If LogInd = 5 Then
            Logging sErrorMessage
        End If
    End If
    ValidateField = sData
    Exit Function
ErrorHandler:
    Logging "ERROR: CLASS: cConfig SUB: ValidateField :" & Err.Number & ":" & Err.Description
End Function

Public Property Get AttachFileManullay() As Boolean
    AttachFileManullay = mbAttachFilesManually
End Property

Public Property Let AttachFileManullay(ByVal bAttachFileManullay As Boolean)
    mbAttachFilesManually = bAttachFileManullay
End Property

Public Property Get AttachFileFolder() As String
    AttachFileFolder = msAttachFileFolder
End Property

Public Property Let AttachFileFolder(ByVal sAttachFileFolder As String)
    msAttachFileFolder = sAttachFileFolder
End Property

