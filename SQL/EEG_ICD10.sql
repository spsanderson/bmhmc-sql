SET ANSI_NULLS OFF
GO
-- VARIABLE DECLARATION AND INITIALIZATION
DECLARE @D DATETIME;
DECLARE @SD DATE;
DECLARE @ED DATE;

SET @D = GETDATE();
SET @SD = GETDATE()-7;
SET @ED = GETDATE()-1;

----------
SELECT A.episode_no AS [PatientNumber]
, LTRIM(RTRIM(A.MED_REC_NO)) AS [Med_Rec_No]
, LEFT(A.RPT_NAME, (CHARINDEX(',', A.RPT_NAME, 1) - 1)) AS [Pt_Last_Name]
, SUBSTRING(
	A.rpt_name
	, CHARINDEX(',', A.RPT_NAME, 1) + 1
	, LEN(A.RPT_NAME) - CHARINDEX(',', A.RPT_NAME, 1)
) AS [Pt_First_Name]
, '' AS [CPT]
, '' AS [Mod1]
, '' AS [Mod2]
, CONVERT(VARCHAR(8) , A.Order_Start_Date, 112) AS [Date_Of_Service]
, B.prim_pract_no AS [Attend_Dr_No]
, LEFT(F.PRACT_RPT_NAME, (CHARINDEX(' ', LTRIM(F.PRACT_RPT_NAME)) - 1)) AS [Attend_Dr_Last_Name]
, SUBSTRING(
	F.pract_rpt_name
	, (CHARINDEX(' ', LTRIM(F.PRACT_RPT_NAME)) + 1)
	, LEN(F.PRACT_RPT_NAME) - (CHARINDEX(' ', LTRIM(F.PRACT_RPT_NAME)) - 1)
) AS [Attend_Dr_First_Name]
, A.fc
, LEFT(B.VST_TYPE_CD, 1) AS [Accomodation]
, '' AS [Co-Payment_Amount]
, '' AS [Co-Payment_Paid]
, A.pty_cd AS [Referring_Dr_No]
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
, '' AS [Second_FC]
, A.ord_no AS [Client_Trans_Ref_No]
--, C.Date_Coded
--, A.ord_sts
--, @SD
--, A.Order_Start_Date
--, @ED

INTO #TEMPA

FROM SMSDSS.C_SR_ORDERS_FINANCE_RPT_V AS A
LEFT OUTER JOIN SMSMIR.SR_VST_PMS AS B
ON A.EPISODE_NO = B.EPISODE_NO
	AND A.PT_ID_START_DTIME = B.PT_ID_START_DTIME
LEFT OUTER JOIN SMSDSS.C_BMH_CODER_ACTIVITY_V AS C
ON A.EPISODE_NO = C.EPISODE_NO
LEFT OUTER JOIN smsmir.mir_pract_mstr AS F
ON B.prim_pract_no = F.pract_no
	AND F.src_sys_id = '#PMSNTX0'

WHERE A.SVC_CD = '04400016'
AND A.ORD_STS IN ('27','28','31','37')
AND A.ORDER_START_DATE > '07/01/2015'
AND Date_Coded BETWEEN @SD and @ED
--AND A.episode_no = '87676169'
GO
;

----------
-- get dx codes

SELECT PtNo_Num AS [PatientNumber]
, ISNULL(PVT.[01],'') AS Dx11
, ISNULL(PVT.[02],'') AS Dx12
, ISNULL(PVT.[03],'') AS Dx13
, ISNULL(PVT.[04],'') AS Dx14
, ISNULL(PVT.[05],'') AS Dx15
, ISNULL(PVT.[06],'') AS Dx16
, ISNULL(PVT.[07],'') AS Dx17
, ISNULL(PVT.[08],'') AS Dx18
, ISNULL(PVT.[09],'') AS Dx19
, ISNULL(PVT.[10],'') AS Dx20

INTO #TEMP_DX

FROM (
	SELECT DX.PtNo_Num
	, PLM.Med_Rec_No
	, PLM.Pt_Name
	, DX.ClasfCd
	, DX.ClasfPrio
	
	FROM smsdss.BMH_PLM_PtAcct_Clasf_Dx_V AS DX
	LEFT OUTER JOIN smsdss.BMH_PLM_PtAcct_V AS PLM
	ON DX.PT_NO = PLM.Pt_No
		AND DX.Pt_Key = PLM.Pt_Key
		AND DX.Bl_Unit_Key = PLM.Bl_Unit_Key
	
	WHERE DX.ClasfSch = '0'
	AND DX.SortClasfType = 'DF'
	AND DX.PtNo_Num IN (
		SELECT ZZZ.PatientNumber
		FROM #TEMPA AS ZZZ
	)
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
	FROM #TEMPA AS ZZZ
)

GO
;

----------

SELECT A.PatientNumber
, A.Med_Rec_No
, A.Pt_Last_Name
, A.Pt_First_Name
, A.CPT
, A.Mod1
, A.Mod2
, A.Date_Of_Service
, A.Attend_Dr_No
, A.Attend_Dr_Last_Name
, A.Attend_Dr_First_Name
, A.fc
, A.Accomodation
, A.[Co-Payment_Amount]
, A.[Co-Payment_Paid]
, A.Referring_Dr_No
, A.Ref_Dr_Last_Name
, A.Ref_Dr_First_Name
, A.Second_FC
, A.Client_Trans_Ref_No
, B.ClasfCd AS [Admit_Dx]
, '' AS [Dx1]
, '' AS [Dx2]
, '' AS [Dx3]
, '' AS [Dx4]
, '' AS [Dx5]
, '' AS [Dx6]
, '' AS [Dx7]
, '' AS [Dx8]
, '' AS [Dx9]
, '' AS [Dx10]
, C.[Dx11]
, C.[Dx12]
, C.[Dx13]
, C.[Dx14]
, C.[Dx15]
, C.[Dx16]
, C.[Dx17]
, C.[Dx18]
, C.[Dx19]
, C.[Dx20]
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

FROM #TEMPA AS A
LEFT OUTER JOIN #TEMP_ADM_DX AS B
ON A.PatientNumber = B.PtNo_Num
LEFT OUTER JOIN #TEMP_DX AS C
ON A.PatientNumber = C.PatientNumber

ORDER BY A.PatientNumber

GO
;

DROP TABLE #TEMPA, #TEMP_ADM_DX, #TEMP_DX
GO
;