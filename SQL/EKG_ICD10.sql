SET ANSI_NULLS OFF
GO

DECLARE @D DATETIME;
DECLARE @SD DATE;
DECLARE @ED DATE;
DECLARE @OD DATE;

SET @D = GETDATE();
SET @SD = DATEADD(DAY, DATEDIFF(DAY, 0, @D) - 7, 0);
SET @ED = DATEADD(DAY, DATEDIFF(DAY, 0, @D) - 1, 0);
SET @OD = DATEADD(DAY, DATEDIFF(DAY, 0, @D) - (365*2), 0);

SELECT A.episode_no,
A.FC,
LEFT(B.VST_TYPE_CD, 1) AS [Accomodation],
'' AS [Co-payment_Amount],
'' AS [Co-payment Paid],
A.pty_cd AS [Referring_Dr_No],
UPPER(REVERSE(PARSENAME(REPLACE(REVERSE(A.PTY_NAME), ',', '.'),1))) AS [pty_name],
CONVERT(VARCHAR(8), A.Order_Stop_Date, 112) AS [Date_Of_Service],
'' AS [Second_FC],
A.ord_no AS [Client_Trans_Ref_No],
A.ord_sts,
A.ord_no,
A.ord_occr_no,
D.Date_Coded
INTO #TEMPA
FROM SMSDSS.c_sr_orders_finance_rpt_v AS A
LEFT OUTER JOIN SMSDSS.c_bmh_coder_activity_v AS D
ON A.episode_no = D.episode_no
LEFT OUTER JOIN SMSMIR.sr_vst_pms AS B ON A.episode_no = B.episode_no
	AND A.pt_id_start_dtime = B.pt_id_start_dtime

WHERE A.svc_cd IN ('00424994','00600015')
AND D.Date_Coded BETWEEN @SD AND @ED;

SELECT B.episode_no AS [PatientNumber],
b.fc,
b.Accomodation,
b.[Co-payment_Amount],
b.[Co-payment Paid],
b.Referring_Dr_No,
b.pty_name,
b.Date_Of_Service,
b.Second_FC,
b.Client_Trans_Ref_No,
b.ord_sts,
b.ord_no,
B.Date_Coded,
CASE
       -- WHEN THERE IS A THRID SPACE AND IT IS BEFORE THE COMMA
       WHEN CHARINDEX(',', f.readingdr) > 0 -- COMMA LOC
       AND CHARINDEX(' ', f.readingdr, CHARINDEX(' ', f.readingdr, CHARINDEX(' ', f.readingdr) + 1) + 1) < CHARINDEX(',', f.readingdr) -- THIRD SPACE LOC < COMMA LOC
              THEN UPPER(SUBSTRING(
                     f.readingdr
                     , CHARINDEX(' ', f.readingdr, CHARINDEX(' ', f.readingdr) + 1)-- SECOND SPACE LOC
                     , (CHARINDEX(',', f.readingdr))- CHARINDEX(' ', f.readingdr, CHARINDEX(' ', f.readingdr) + 1)-- SUBTRACT SECOND SPACE FROM COMMA LOC
              ))
       -- WHEN THERE IS A THIRD SPACE AFTER THE COMMA
       WHEN CHARINDEX(',', f.readingdr) > 0 -- COMMA
       AND CHARINDEX(' ', f.readingdr, CHARINDEX(' ', f.readingdr, CHARINDEX(' ', f.readingdr) + 1) + 1) > CHARINDEX(',', f.readingdr)
              THEN UPPER(SUBSTRING(
                     f.readingdr
                     , CHARINDEX(' ', f.readingdr) -- START FIRST SPACE
                     , (CHARINDEX(' ', f.readingdr, CHARINDEX(' ', f.readingdr) + 1)) - (CHARINDEX(' ', f.readingdr)) -- SECOND SPACE MINUS FIRST SPACE
              ))
       
              ELSE ''
  END AS [Reading_Dr_Last_Name],
CASE
       WHEN charindex(' ', f.readingdr) != 0 
              THEN UPPER(LEFT(f.readingdr, (charindex(' ', f.readingdr) -1)))
       ELSE ''
  END as [Reading_Dr_First_Name],
F.ReadingDr
INTO #TEMPB
FROM SMSMIR.obsv AS A
INNER JOIN #TEMPA AS B ON A.episode_no = B.episode_no
	AND A.ord_occr_no = B.ord_occr_no
	AND A.val_sts_cd = 'F'
	--AND A.obsv_cd_name IN ('EKG', 'EKG-OP','EKG RESULTS') -- SUPERFLUOUS ALREADY JOINS ON ORD_OCC_NO
LEFT OUTER JOIN SMSMIR.mir_sc_InvestigationResultSuppInfo AS F ON A.rslt_supl_info_obj_id = F.ObjectID;

SELECT A.PatientNumber
, A.fc
, A.Accomodation
, A.[Co-payment_Amount]
, A.[Co-payment Paid]
, A.Referring_Dr_No
, A.PTY_NAME
, REVERSE(PARSENAME(REPLACE(REVERSE(A.PTY_NAME), ' ', '.'), 1)) AS FIRST_NAME
, REVERSE(PARSENAME(REPLACE(REVERSE(A.PTY_NAME), ' ', '.'), 2)) AS MIDDLE_NAME
, REVERSE(PARSENAME(REPLACE(REVERSE(A.PTY_NAME), ' ', '.'), 3)) AS LAST_NAME_A
, REVERSE(PARSENAME(REPLACE(REVERSE(A.PTY_NAME), ' ', '.'), 4)) AS LAST_NAME_B
, A.Date_Of_Service
, A.Second_FC
, A.Client_Trans_Ref_No
, A.Reading_Dr_Last_Name
, A.Reading_Dr_First_Name
, A.Date_Coded
, A.ord_sts
, A.ord_no
, A.ReadingDr
INTO #TEMPC
FROM #TEMPB AS A;

SELECT A.PatientNumber
, A.fc
, A.Accomodation
, A.[Co-payment_Amount]
, A.[Co-payment Paid]
, A.Referring_Dr_No
, A.FIRST_NAME AS REF_DR_FIRST_NAME
, CASE
       WHEN A.LAST_NAME_B IS NOT NULL
              THEN CONCAT(A.LAST_NAME_A, ' ', A.LAST_NAME_B)
       WHEN A.LAST_NAME_A IS NULL
              THEN A.MIDDLE_NAME
    ELSE A.LAST_NAME_A
    END AS [Ref_Dr_Last_Name]
, A.Date_Of_Service
, A.Second_FC
, A.Client_Trans_Ref_No
, A.Reading_Dr_Last_Name
, A.Reading_Dr_First_Name
, A.Date_Coded
, A.ord_sts
, A.ord_no
, A.ReadingDr
INTO #TEMPD
FROM #TEMPC AS A;

SELECT PtNo_Num AS [PatientNumber]
, LTRIM(RTRIM(Med_Rec_No)) AS Med_Rec_No
, SUBSTRING(PT_NAME, (CHARINDEX(',', Pt_Name, 1) + 1), (LEN(PT_NAME))) AS [PT_FirstName]
, SUBSTRING(PT_NAME, 1, (CHARINDEX(' ', PT_NAME, 1))) AS [PT_LastName]
, '' AS [CPT]
, '' AS [Mod1]
, '' AS [Mod2]
, src_pract_no AS [Attend_Dr_No]
, UPPER(SUBSTRING(PRACT_RPT_NAME, (CHARINDEX(' ', PRACT_RPT_NAME, 1) + 1), (LEN(PRACT_RPT_NAME)))) AS [Attend_Dr_First_Name]
, UPPER(SUBSTRING(PRACT_RPT_NAME, 1, (CHARINDEX(' ', PRACT_RPT_NAME, 1)))) AS [Attend_Dr_Last_Name]
, ISNULL(PVT.[01],'') AS Dx01
, ISNULL(PVT.[02],'') AS Dx02
, ISNULL(PVT.[03],'') AS Dx03
, ISNULL(PVT.[04],'') AS Dx04
, ISNULL(PVT.[05],'') AS Dx05
, ISNULL(PVT.[06],'') AS Dx06
, ISNULL(PVT.[07],'') AS Dx07
, ISNULL(PVT.[08],'') AS Dx08
, ISNULL(PVT.[09],'') AS Dx09
, ISNULL(PVT.[10],'') AS Dx10

INTO #TEMP_DX

FROM (
	SELECT PLM.PtNo_Num
       , PLM.Med_Rec_No
       , PLM.Pt_Name
       , PDV.src_pract_no
       , PDV.pract_rpt_name
       , DX.dx_cd
       , DX.dx_cd_prio
	FROM SMSDSS.BMH_PLM_PtAcct_V AS PLM
	LEFT OUTER JOIN SMSMIR.dx_grp AS DX ON PLM.Pt_No = DX.pt_id
		AND PLM.unit_seq_no = DX.unit_seq_no
		AND PLM.from_file_ind = DX.from_file_ind
	LEFT OUTER JOIN SMSDSS.PRACT_DIM_V AS PDV ON PLM.Atn_Dr_No = PDV.src_pract_no
		AND PLM.Regn_Hosp = PDV.orgz_cd
	INNER JOIN #TEMPD AS D ON PLM.PtNo_Num = D.PatientNumber
	WHERE DX.dx_cd_schm = '0'
	AND LEFT(DX.dx_cd_type, 2) = 'DF'
	AND DX.dx_cd_prio < '11'
) AS A

PIVOT(
       MAX(DX_CD)
       FOR DX_CD_PRIO IN (
              "01","02","03","04","05","06","07","08","09","10"
       )
) AS PVT;

SELECT DISTINCT SUBSTRING(D.PT_ID, 5, 8) AS [PtNo_Num],
D.dx_cd
INTO #TEMP_ADM_DX
FROM SMSMIR.dx_grp AS D
INNER JOIN #TEMPA AS A ON SUBSTRING(D.pt_id, 5, 8) = A.episode_no
WHERE LEFT(D.dx_cd_type, 2) = 'DA'
AND D.dx_cd_schm = '0'
AND D.dx_cd_prio IN ('01','1')
;

-- FINAL SELECT
SELECT A.PatientNumber
, B.Med_Rec_No
, B.PT_LastName
, B.PT_FirstName
, B.CPT
, B.Mod1
, B.Mod2
, A.Date_Of_Service
, B.Attend_Dr_No
, B.Attend_Dr_Last_Name
, B.Attend_Dr_First_Name
, A.fc
, A.Accomodation
, A.[Co-payment_Amount]
, A.[Co-payment Paid]
, A.Referring_Dr_No
, UPPER(A.Ref_Dr_Last_Name) AS [Ref_Dr_Last_Name]
, A.Ref_Dr_First_Name
, A.Second_FC
, A.Client_Trans_Ref_No
, C.dx_cd AS [Admit_Dx]
, UPPER(A.Reading_Dr_Last_Name) AS [Reading_Dr_Last_Name]
, A.Reading_Dr_First_Name
, '' as [Dx3]
, '' as [Dx4]
, '' as [Dx5]
, '' as [Dx6]
, '' as [Dx7]
, '' as [Dx8]
, '' as [Dx9]
, '' as [Dx10]
, B.Dx01 AS [Dx11]
, B.Dx02 AS [Dx12]
, B.Dx03 AS [Dx13]
, B.Dx04 AS [Dx14]
, B.Dx05 AS [Dx15]
, B.Dx06 AS [Dx16]
, B.Dx07 AS [Dx17]
, B.Dx08 AS [Dx18]
, B.Dx09 AS [Dx19]
, B.Dx10 AS [Dx20]
, '' as [Dx21]
, '' as [Dx22]
, '' as [Dx23]
, '' as [Dx24]
, '' as [Dx25]
, '' as [Dx26]
, '' as [Dx27]
, '' as [Dx28]
, '' as [Dx29]
, '' as [Dx30]
, A.Date_Coded
--, A.ord_sts
--, A.ord_no
--, A.ReadingDr

FROM #TEMPD AS A
LEFT OUTER JOIN #TEMP_DX AS B
ON A.PatientNumber = B.PatientNumber
LEFT OUTER JOIN #TEMP_ADM_DX AS C
ON A.PatientNumber = C.PtNo_Num
ORDER BY A.PatientNumber;

-- DROP TEMP TABLES
DROP TABLE #TEMPA,#TEMPB,#TEMPC,#TEMPD,#TEMP_DX,#TEMP_ADM_DX;