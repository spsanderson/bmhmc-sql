SET ANSI_NULLS OFF
GO
-- VARIABLE DECLARATION AND INITIALIZATION
DECLARE @D DATETIME;
DECLARE @SD DATETIME;
DECLARE @ED DATETIME;

SET @D = GETDATE();
SET @SD = GETDATE()-7;
SET @ED = GETDATE()-1;

select B.episode_no AS [PatientNumber]
, A.Med_Rec_No
, LEFT(A.PT_NAME, (CHARINDEX(',', A.PT_NAME, 1) - 1)) AS [Pt_Last_Name]
, SUBSTRING(
	A.Pt_Name
	, (CHARINDEX(',', A.PT_NAME, 1) + 1)
	, LEN(A.PT_NAME) - CHARINDEX(',', A.PT_NAME,1)
	) AS [Pt_First_Name]
, '' AS [CPT]
, '' AS [Mod1]
, '' AS [Mod2]
, CONVERT(VARCHAR(8), B.VST_START_DATE, 112) AS [Date_Of_Service]
, C.Date_Coded
, B.prim_pract_no AS [Attend_Dr_No]
, LEFT(D.pract_rpt_name, (CHARINDEX(' ', LTRIM(D.PRACT_RPT_NAME)) - 1)) AS [Attend_Dr_Last_Name]
, SUBSTRING(
	D.PRACT_RPT_NAME
	, (CHARINDEX(' ', LTRIM(D.PRACT_RPT_NAME)) + 1)
	, LEN(D.PRACT_RPT_NAME) - CHARINDEX(' ', LTRIM(D.PRACT_RPT_NAME)) - 1
) AS [Attend_Dr_First_Name]
, B.fc
, LEFT(B.VST_TYPE_CD, 1) AS [Accomodation]
, '' AS [Co-Payment_Amount]
, '' AS [Co-Payment_Paid]
, B.ref_pract_no AS [Referring_Dr_No]
, CASE
	WHEN CHARINDEX(' ', b.ref_pract_name) != 0
	AND CHARINDEX(',', b.ref_pract_name) != 0 
		THEN UPPER(
			SUBSTRING(
				b.ref_pract_name
				,CHARINDEX(' ', b.ref_pract_name) + 1
				,(CHARINDEX(',', b.ref_pract_name) - CHARINDEX(' ', b.ref_pract_name) - 1)
			)
		)
	WHEN CHARINDEX(' ', b.ref_pract_name) > 0
	AND CHARINDEX(',', b.ref_pract_name) = 0
		THEN UPPER(
			SUBSTRING(
				b.ref_pract_name
				,CHARINDEX(' ', b.ref_pract_name) + 1
				,(LEN(RTRIM(b.ref_pract_name)) - CHARINDEX(' ', b.ref_pract_name))
			)
		)
	ELSE ''
  END AS [Ref_Dr_Last_Name]
, CASE
	WHEN CHARINDEX(' ', b.ref_pract_name) != 0
		THEN UPPER(LEFT(b.ref_pract_name, (CHARINDEX(' ', b.ref_pract_name) - 1)))
	ELSE ''
  END AS [Ref_Dr_First_Name]
, '' as [Second_FC]
, '' as [Client_Trans_Ref_No]

INTO #TEMPA

FROM smsmir.sr_vst_pms AS B
LEFT MERGE JOIN smsdss.bmh_plm_ptacct_v AS A
ON b.med_rec_no = a.med_rec_no 
	AND b.episode_no = a.PtNo_Num
LEFT MERGE JOIN smsdss.c_bmh_coder_activity_v AS C
ON B.pt_no = c.episode_no
LEFT OUTER JOIN smsmir.mir_pract_mstr AS D
ON B.prim_pract_no = D.pract_no
	AND D.src_sys_id = '#PMSNTX0'

WHERE B.hosp_svc = 'BPC'
AND CAST(Date_Coded AS date) BETWEEN @SD and @ED

OPTION(FORCE ORDER)

GO
;

----------
-- get dx codes

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
, '' as [Dx1]
, '' as [Dx2]
, '' as [Dx3]
, '' as [Dx4]
, '' as [Dx5]
, '' as [Dx6]
, '' as [Dx7]
, '' as [Dx8]
, '' as [Dx9]
, '' as [Dx10]
, C.Dx11
, C.Dx12
, C.Dx13
, C.Dx14
, C.Dx15
, C.Dx16
, C.Dx17
, C.Dx18
, C.Dx19
, C.Dx20
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

FROM #TEMPA AS A
LEFT OUTER JOIN #TEMP_ADM_DX AS B
ON A.PatientNumber = B.PtNo_Num
LEFT OUTER JOIN #TEMP_DX AS C
ON A.PatientNumber = C.PatientNumber

ORDER BY A.Date_Coded
, A.PatientNumber

GO
;

----------

DROP TABLE #TEMP_ADM_DX, #TEMP_DX, #TEMPA
GO
;