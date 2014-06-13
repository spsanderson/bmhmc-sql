-- VARIABLE DECLARATION AND INITIALIZATION
DECLARE @STARTDATE DATETIME
DECLARE @ENDATE DATETIME

-- DATA STARTS AT 2011-11-01
SET @STARTDATE = '2014-05-01';
SET @ENDATE =    '2014-06-01';

-- COLUMN SELECTION
SELECT PAV.Med_Rec_No                                 AS [MED REC NO]
, PAV.PtNo_Num                                        AS [ENCOUNTER NUM]
, PAV.Pt_Name                                         AS [PT NAME]
, PAV.vst_start_dtime                                 AS [ADMIT DATE TIME]
, DATEPART(MM, PAV.vst_start_dtime)                   AS [ADM MONTH]
, DATEPART(DD, PAV.vst_start_dtime)                   AS [ADM DAY]
, DATEPART(YY, PAV.vst_start_dtime)                   AS [ADM YR]
, PAV.vst_end_dtime                                   AS [DISC DATE TIME]
, DATEPART(MM, PAV.vst_end_dtime)                     AS [DISC MONTH]
, DATEPART(DD, PAV.vst_end_dtime)                     AS [DISC DAY]
, DATEPART(YY, PAV.vst_end_dtime)                     AS [DISC YR]
, DATEPART(HH, PAV.vst_start_dtime)                   AS [ADMIT HR]
, DATEPART(HH, PAV.vst_end_dtime)                     AS [DISC HR]
, DATEDIFF(DD,PAV.vst_start_dtime, PAV.vst_end_dtime) AS [LOS]
, SO.svc_desc                                         AS [SERVICE DESC]
, PAV.drg_no                                          AS [DRG NUMBER]
, DDV.std_drg_name_modf                               AS [DRG DESC]
, SO.pty_name                                         AS [DOCTOR]
, SO.perf_dept                                        AS [PERFORMING DEPT]
, PAV.pt_type                                         AS [PT TYPE]
, PAV.Pt_Age                                          AS [PT AGE]
, PAV.Adm_Source                                      AS [ADMIT SOURCE]
, PAV.dsch_disp                                       AS [PT DISPO]

-- DB(S) USED
FROM smsmir.sr_ord                   SO
	JOIN smsdss.BMH_PLM_PtAcct_V     PAV
	ON SO.episode_no = PAV.PtNo_Num
	JOIN smsdss.drg_dim_v            DDV
	ON DDV.drg_no = PAV.drg_no

-- FILTERS USED
WHERE SO.svc_cd IN (
	'XFUSERBC',
	'XFUSEPLATELETS',
	'XFUSEBLDPRD'
	)
	AND PAV.vst_end_dtime >= @STARTDATE 
	AND PAV.vst_end_dtime < @ENDATE
	AND DDV.DRG_VERS = 'MS-V25' 
ORDER BY PAV.vst_end_dtime

