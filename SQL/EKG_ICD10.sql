SET ANSI_NULLS OFF
GO

DECLARE @D DATETIME;
DECLARE @SD DATE;
DECLARE @ED DATE;
SET @D = GETDATE();
SET @SD = GETDATE() - 7;
SET @ED = GETDATE() - 1;
----------

SELECT A.episode_no AS [PatientNumber]
, a.fc
, LEFT(B.vst_type_cd, 1) AS [Accomodation]
, '' AS [Co-payment_Amount]
, '' AS [Co-payment_Paid]
, a.pty_cd AS [Referring_Dr_No]
, CASE
	-- WHEN THERE IS A COMMA IN THE NAME (ALWAYS AT END) AND THERE IS A THIRD SPACE
	WHEN CHARINDEX(',', A.pty_name) > 0 -- COMMA LOC
	AND CHARINDEX(' ', A.pty_name, CHARINDEX(' ', A.pty_name, CHARINDEX(' ', A.pty_name) + 1) + 1) > 0 -- THIRD SPACE LOC
		THEN SUBSTRING(
			A.pty_name
			, CHARINDEX(' ', A.pty_name, CHARINDEX(' ', A.pty_name) + 1) + 1-- SECOND SPACE LOC
			, (CHARINDEX(',', A.pty_name))- CHARINDEX(' ', A.pty_name, CHARINDEX(' ', A.pty_name) + 1) - 1 -- SUBTRACT SECOND SPACE FROM COMMA LOC
		)
	-- WHEN THERE IS A COMMA IN THE NAME (ALWAYS AT END) AND THERE IS A NO THIRD SPACE AND THE SECOND SPACE IS FURTHER THAN COMMA
	WHEN CHARINDEX(',', A.pty_name) > 0
	AND CHARINDEX(' ', A.pty_name, CHARINDEX(' ', A.pty_name, CHARINDEX(' ', A.pty_name) + 1) + 1) = 0 -- THIRD SPACE LOC
	AND CHARINDEX(',', A.pty_name) < CHARINDEX(' ', A.pty_name, CHARINDEX(' ', A.pty_name) + 1)
		THEN SUBSTRING(
			A.pty_name
			, CHARINDEX(' ', A.pty_name) + 1 -- START AT FIRST SPACE LOC
			, (CHARINDEX(',', A.pty_name) - 1) - CHARINDEX(' ', A.pty_name) -- SUBTRACT SECOND SPACE LOC FROM COMMA LOC
		)
	-- WHEN THERE IS NO COMMA BUT THERE IS A THRID SPACE
	WHEN CHARINDEX(',', A.pty_name) = 0
	AND CHARINDEX(' ', A.pty_name, CHARINDEX(' ', A.pty_name, CHARINDEX(' ', A.pty_name) + 1) + 1) > 0
		THEN SUBSTRING(
			A.pty_name
			, CHARINDEX(' ', A.pty_name, CHARINDEX(' ', A.pty_name) + 1) -- START AT SECOND SPACE
			, CHARINDEX(' ', A.pty_name, CHARINDEX(' ', A.pty_name, CHARINDEX(' ', A.pty_name) + 1) + 1) -- THIRD SPACE
			  -                                                                           -- MINUS                  
			  CHARINDEX(' ', A.pty_name, CHARINDEX(' ', A.pty_name) + 1)                            -- SECOND SPACE
		)
	-- WHEN THERE IS NO COMMA AND NO THIRD SPACE
	WHEN CHARINDEX(',', A.pty_name) = 0
	AND CHARINDEX(' ', A.pty_name, CHARINDEX(' ', A.pty_name, CHARINDEX(' ', A.pty_name) + 1) + 1) = 0
		THEN SUBSTRING(
			A.pty_name
			, CHARINDEX(' ', A.pty_name, CHARINDEX(' ', A.pty_name) + 1) + 1
			, LEN(A.pty_name) - (CHARINDEX(' ', A.pty_name, CHARINDEX(' ', A.pty_name) + 1))
		)
		ELSE ''
  END AS [Ref_Dr_Last_Name]
, CASE
	WHEN CHARINDEX(' ',a.pty_name) != 0 
		THEN UPPER(LEFT(a.pty_name,(CHARINDEX(' ',a.pty_name)-1)))
		ELSE ''
END AS [Ref_Dr_First_Name]
, CONVERT(VARCHAR(8), A.Order_Stop_Date, 112) AS [Date_Of_Service]
, '' AS [Second_FC]
, a.ord_no AS [Client_Trans_Ref_No]
, CASE
	-- WHEN THERE IS A THRID SPACE AND IT IS BEFORE THE COMMA
	WHEN CHARINDEX(',', f.readingdr) > 0 -- COMMA LOC
	AND CHARINDEX(' ', f.readingdr, CHARINDEX(' ', f.readingdr, CHARINDEX(' ', f.readingdr) + 1) + 1) < CHARINDEX(',', f.readingdr) -- THIRD SPACE LOC < COMMA LOC
		THEN SUBSTRING(
			f.readingdr
			, CHARINDEX(' ', f.readingdr, CHARINDEX(' ', f.readingdr) + 1)-- SECOND SPACE LOC
			, (CHARINDEX(',', f.readingdr))- CHARINDEX(' ', f.readingdr, CHARINDEX(' ', f.readingdr) + 1)-- SUBTRACT SECOND SPACE FROM COMMA LOC
		)
	-- WHEN THERE IS A THIRD SPACE AFTER THE COMMA
	WHEN CHARINDEX(',', f.readingdr) > 0 -- COMMA
	AND CHARINDEX(' ', f.readingdr, CHARINDEX(' ', f.readingdr, CHARINDEX(' ', f.readingdr) + 1) + 1) > CHARINDEX(',', f.readingdr)
		THEN SUBSTRING(
			f.readingdr
			, CHARINDEX(' ', f.readingdr) -- START FIRST SPACE
			, (CHARINDEX(' ', f.readingdr, CHARINDEX(' ', f.readingdr) + 1)) - (CHARINDEX(' ', f.readingdr)) -- SECOND SPACE MINUS FIRST SPACE
		)
	
		ELSE ''
  END AS [Reading_Dr_Last_Name]
, CASE
	WHEN CHARINDEX(' ', f.readingdr) != 0 
		THEN UPPER(LEFT(f.readingdr, (CHARINDEX(' ', f.readingdr) -1)))
	ELSE ''
  END AS [Reading_Dr_First_Name]
, D.Date_Coded
, a.ord_sts
, a.ord_no
, F.ReadingDr

INTO #TEMP_ORD

FROM smsdss.c_sr_orders_finance_rpt_v AS a 
LEFT JOIN smsmir.sr_vst_pms AS b
ON a.episode_no = b.episode_no 
	AND a.pt_id_start_dtime = b.pt_id_start_dtime
LEFT OUTER JOIN smsmir.obsv AS C
ON a.episode_no = C.episode_no
	AND a.ord_occr_no = C.ord_occr_no
LEFT OUTER JOIN smsdss.c_bmh_coder_activity_v AS D
ON a.episode_no = D.episode_no
LEFT OUTER JOIN smsmir.mir_sc_InvestigationResultSuppInfo AS F
ON C.rslt_supl_info_obj_id = F.ObjectID

WHERE a.svc_cd IN ('00424994','00600015')
AND a.Order_Start_Date >= '2017-01-01'
AND C.obsv_cd_name IN ('EKG', 'EKG-OP','EKG RESULTS')
AND C.val_sts_cd = 'F'
AND D.Date_Coded BETWEEN @SD AND @ED

OPTION(FORCE ORDER)
GO
;

----------

SELECT PtNo_Num AS [PatientNumber]
, LTRIM(RTRIM(Med_Rec_No)) AS Med_Rec_No
, SUBSTRING(PT_NAME, (CHARINDEX(',', Pt_Name, 1) + 1), (LEN(PT_NAME))) AS [PT_FirstName]
, SUBSTRING(PT_NAME, 1, (CHARINDEX(' ', PT_NAME, 1))) AS [PT_LastName]
, '' AS [CPT]
, '' AS [Mod1]
, '' AS [Mod2]
, src_pract_no AS [Attending_Dr_No]
, SUBSTRING(PRACT_RPT_NAME, (CHARINDEX(' ', PRACT_RPT_NAME, 1) + 1), (LEN(PRACT_RPT_NAME))) AS [Attending_Dr_First_Name]
, SUBSTRING(PRACT_RPT_NAME, 1, (CHARINDEX(' ', PRACT_RPT_NAME, 1))) AS [Attending_Dr_Last_Name]
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
	SELECT DX.PtNo_Num
	, PLM.Med_Rec_No
	, PLM.Pt_Name
	, PDV.src_pract_no
	, PDV.pract_rpt_name
	, DX.ClasfCd
	, DX.ClasfPrio
	
	FROM smsdss.BMH_PLM_PtAcct_Clasf_Dx_V AS DX
	LEFT OUTER JOIN smsdss.BMH_PLM_PtAcct_V AS PLM
	ON DX.PT_NO = PLM.Pt_No
		AND DX.Pt_Key = PLM.Pt_Key
		AND DX.Bl_Unit_Key = PLM.Bl_Unit_Key
	LEFT OUTER JOIN smsdss.pract_dim_v AS PDV
	ON PLM.Atn_Dr_No = PDV.src_pract_no
		AND PLM.Regn_Hosp = PDV.orgz_cd
	
	WHERE DX.ClasfSch = '0'
	AND DX.SortClasfType = 'DF'
	--AND DX.Pt_No = ''
) AS A

PIVOT(
	MAX(CLASFCD)
	FOR CLASFPRIO IN (
		"01","02","03","04","05","06","07","08","09","10"
	)
) AS PVT

GO
;

----------
-- ADMITTING DX
SELECT PtNo_Num
, ClasfCd

INTO #TEMP_ADM_DX

FROM smsdss.BMH_PLM_PtAcct_Clasf_Dx_V AS D
WHERE D.SortClasfType = 'DA'
AND D.ClasfSch = '0'
AND D.ClasfPrio IN ('01', '1')
AND D.PtNo_Num IN (
	SELECT ZZZ.PatientNumber
	FROM #TEMP_ORD AS ZZZ
)

GO
;

----------

SELECT A.PatientNumber
, B.Med_Rec_No
, B.PT_LastName
, B.PT_FirstName
, B.CPT
, B.Mod1
, B.Mod2
, A.Date_Of_Service
, B.Attending_Dr_No
, B.Attending_Dr_First_Name
, B.Attending_Dr_Last_Name
, A.fc
, A.Accomodation
, A.[Co-payment_Amount]
, A.[Co-payment_Paid]
, A.Referring_Dr_No
, UPPER(A.Ref_Dr_Last_Name) AS [Ref_Dr_Last_Name]
, A.Ref_Dr_First_Name
, A.Second_FC
, A.Client_Trans_Ref_No
, C.ClasfCd AS [Admit_Dx]
, UPPER(A.Reading_Dr_Last_Name) AS [Reading_Dr_Last_Name]
, A.Reading_Dr_First_Name
, '' AS [Dx3]
, '' AS [Dx4]
, '' AS [Dx5]
, '' AS [Dx6]
, '' AS [Dx7]
, '' AS [Dx8]
, '' AS [Dx9]
, '' AS [Dx10]
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
, '' AS [Dx21]
, '' AS [Dx22]
, '' AS [Dx23]
, '' AS [Dx24]
, '' AS [Dx25]
, '' AS [Dx26]
, '' AS [Dx27]
, '' AS [Dx28]
, '' AS [Dx29]
, '' AS [Dx30]
, A.Date_Coded
, A.ord_sts
, A.ord_no
, A.ReadingDr

FROM #TEMP_ORD AS A
LEFT OUTER JOIN #TEMP_DX AS B
ON A.PatientNumber = B.PatientNumber
LEFT OUTER JOIN #TEMP_ADM_DX AS C
ON A.PatientNumber = C.PtNo_Num

ORDER BY A.PatientNumber

GO
;

----------

DROP TABLE #TEMP_ADM_DX, #TEMP_DX, #TEMP_ORD

GO
;