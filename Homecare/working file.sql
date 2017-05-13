select a.bill_no
, B.S_CPM_REASONFORHOMECARE
, B.S_HOMECARE_VENDOR
, B.DC_TO_DEST
, B.VISIT_DC_STATUS
, *

FROM [BMH-3MHIS-DB].[MMM_COR_BMH_LIVE].[dbo].[visit_view]              AS A
LEFT JOIN [BMH-3MHIS-DB].[MMM_COR_BMH_LIVE].[dbo].[ctc_visit]          AS B
ON A.VISIT_ID = B._FK_VISIT
LEFT JOIN [BMH-3MHIS-DB].[MMM_cor_BMH_LIVE].[DBO].[CTC_DOCUMENTSENT]   AS C
ON B._FK_VISIT = C._FK_VISIT
LEFT JOIN [BMH-3MHIS-DB].[MMM_COR_BMH_LIVE].[Dbo].[ctc_letter]         AS D
ON D._FK_DOCUMENTSENT = C._PK
LEFT JOIN [BMH-3MHIS-DB].[MMM_COR_BMH_LIVE].[Dbo].[ctc_letterPrintJob] AS E
ON D._PK = E._FK_LETTER
	
-- This will make sure we start from the beginning case in the 
-- Home Care Rpt Tbl
WHERE A.BILL_NO in (
		SELECT PtNo_Num
		FROM SMSDSS.c_Home_Care_Rpt_Tbl
	)
-- Only capture Inpatients
AND A.BILL_NO < '20000000'
AND LEFT(A.BILL_NO, 4) != '1999'
AND B._PK IS NOT NULL
AND B.S_CPM_PATIENT_STATUS <> 'IP'
AND b.s_cpm_reasonforhomecare IS NULL
AND b.s_homecare_vendor IS NULL
AND b.dc_to_dest IS NULL
AND b.visit_dc_status != 'ATW'
