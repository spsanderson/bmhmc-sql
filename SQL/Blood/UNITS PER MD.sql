-- VARIABLE DECLARATION AND INITIALIZATION
DECLARE @TODAY DATE;
DECLARE @STARTDATE DATETIME;
DECLARE @ENDATE DATETIME;

SET @TODAY = GETDATE();
SET @STARTDATE = DATEADD(MONTH, DATEDIFF(MONTH, 0, @TODAY) - 1, 0);
SET @ENDATE = DATEADD(MONTH, DATEDIFF(MONTH, 0, @TODAY), 0);

-- COLUMN SELECTION
SELECT PAV.Med_Rec_No                                 AS [MED REC NO]
, PAV.PtNo_Num                                        AS [ENCOUNTER NUM]
, PAV.Pt_Name                                         AS [PT NAME]
, PAV.Adm_Date                                        AS [ADMIT DATE TIME]
, DATEPART(MM, PAV.vst_start_dtime)                   AS [ADM MONTH]
, DATEPART(DD, PAV.vst_start_dtime)                   AS [ADM DAY]
, DATEPART(YY, PAV.vst_start_dtime)                   AS [ADM YR]
, PAV.Dsch_Date                                       AS [DISC DATE TIME]
, DATEPART(MM, PAV.vst_end_dtime)                     AS [DISC MONTH]
, DATEPART(DD, PAV.vst_end_dtime)                     AS [DISC DAY]
, DATEPART(YY, PAV.vst_end_dtime)                     AS [DISC YR]
, DATEPART(HH, PAV.vst_start_dtime)                   AS [ADMIT HR]
, DATEPART(HH, PAV.vst_end_dtime)                     AS [DISC HR]
, DATEDIFF(DD,PAV.vst_start_dtime, PAV.vst_end_dtime) AS LOS
, SO.ord_no                                           AS [ORDER NUMBER]
, SO.svc_desc                                         AS [SERVICE DESC]
, PAV.drg_no                                          AS [DRG NUMBER]
, DDV.std_drg_name_modf                               AS [DRG DESC]
, SO.pty_name                                         AS [DOCTOR]
, SO.perf_dept                                        AS [PERFORMING DEPT]
, PAV.pt_type                                         AS [PT TYPE]
, PAV.Pt_Age                                          AS [PT AGE]
, PAV.Adm_Source                                      AS [ADMIT SOURCE]
, PAV.dsch_disp                                       AS [PT DISPO]
, SO.desc_as_written AS [AS WRITTEN]
,(CAST
	(ISNULL
		(REPLACE
			(REPLACE
				(REPLACE
					(CASE 
						WHEN PATINDEX('%[0-9]UNIT%',so.desc_as_written) > 0 
							THEN SUBSTRING(so.desc_as_written,
								 PATINDEX('%[0-9]UNIT%',so.desc_as_written)-1,2) 
						WHEN PATINDEX('%[0-9] UNIT%',so.desc_as_written) > 0 
							THEN SUBSTRING(so.desc_as_written,
								 PATINDEX('%[0-9] UNIT%',so.desc_as_written)-1,2)
						WHEN PATINDEX('%[0-9]ROUTINE%',so.desc_as_written) > 0 
							THEN SUBSTRING(so.desc_as_written,
								 PATINDEX('%[0-9]ROUTINE%',so.desc_as_written)-1,2)
						WHEN PATINDEX('%[0-9] ROUTINE%',so.desc_as_written) > 0 
							THEN SUBSTRING(so.desc_as_written,
								 PATINDEX('%[0-9] ROUTINE%',so.desc_as_written)-1,2)
						WHEN PATINDEX('%[0-9]STAT%',so.desc_as_written) > 0 
							THEN SUBSTRING(so.desc_as_written,
								 PATINDEX('%[0-9]STAT%',so.desc_as_written)-1,2)
						WHEN PATINDEX('%[0-9] STAT%',so.desc_as_written) > 0 
							THEN SUBSTRING(so.desc_as_written,
								 PATINDEX('%[0-9] STAT%',so.desc_as_written)-1,2)
						WHEN PATINDEX('%[0-9]TODAY%',so.desc_as_written) > 0 
							THEN SUBSTRING(so.desc_as_written,
								 PATINDEX('%[0-9]TODAY%',so.desc_as_written)-1,2)
						WHEN PATINDEX('%[0-9] TODAY%',so.desc_as_written) > 0 
							THEN SUBSTRING(so.desc_as_written,
								 PATINDEX('%[0-9] TODAY%',so.desc_as_written)-1,2) 
					END,
				'S',''),
			'T',''),
		'U','')
	, 0)
AS INT)
) AS [UNITS]

-- DB(S) USED
FROM smsmir.sr_ord SO
JOIN smsdss.BMH_PLM_PtAcct_V PAV
ON SO.episode_no = PAV.PtNo_Num
JOIN smsdss.drg_dim_v DDV
ON DDV.drg_no = PAV.drg_no

-- FILTERS USED
WHERE SO.svc_cd IN (
	'XFUSERBC',
	'XFUSEPLATELETS',
	'XFUSEBLDPRD'
	)
	AND PAV.Dsch_Date BETWEEN @STARTDATE AND @ENDATE
	AND DDV.DRG_VERS = 'MS-V25' 
	AND SO.ord_no NOT IN (
		SELECT SO.ord_no
		
		FROM smsdss.BMH_PLM_PtAcct_V PV
		JOIN smsmir.sr_ord SO
		ON PV.PtNo_Num = SO.episode_no
		JOIN smsmir.sr_ord_sts_hist SOS
		ON SO.ord_no = SOS.ord_no
		JOIN smsmir.ord_sts_modf_mstr OSM
		ON SOS.hist_sts = OSM.ord_sts_modf_cd
		
		WHERE OSM.ord_sts IN (
			'CANCEL'
			, 'DISCONTINUE'
		)
		AND SO.svc_cd IN (
			'XFUSERBC'
			, 'XFUSEPLATELETS'
			, 'XFUSEBLODPRD'
		)
	)
ORDER BY PAV.Med_Rec_No