WITH CTE AS (
	SELECT Med_Rec_No
	, PtNo_Num
	, Adm_Date
	, Dsch_Date
	, Days_Stay
	, hosp_svc
	, vst_start_dtime
	, RN = ROW_NUMBER() OVER(PARTITION BY MED_REC_NO ORDER BY VST_START_DTIME)
	
	FROM smsdss.BMH_PLM_PtAcct_V
	
	WHERE hosp_svc = 'PSY'
	AND Dsch_Date >= '2016-01-01'
	AND Dsch_Date < '2016-08-01'
)

SELECT C1.Med_Rec_No
, C1.PtNo_Num AS [INDEX ENC]
, C1.Adm_Date AS [INDEX ADM DATE]
, C1.Dsch_Date AS [INDEX DSCH DATE]
, DATEPART(MONTH, C1.DSCH_DATE) AS [INDEX DSCH MONTH]
, C2.PtNo_Num AS [READMIT ENC]
, C2.Adm_Date AS [READMIT ADM DATE]
, C2.Dsch_Date AS [READMIT DSCH DATE]
, DATEDIFF(D, C1.DSCH_DATE, C2.ADM_DATE) AS [INTERIM]

FROM CTE AS C1
INNER JOIN CTE AS C2
ON C1.Med_Rec_No = C2.Med_Rec_No

WHERE C1.vst_start_dtime < C2.vst_start_dtime
AND C1.RN + 1 = C2.RN
AND DATEDIFF(D, C1.DSCH_DATE, C2.Adm_Date) > 0
AND DATEDIFF(D, C1.DSCH_DATE, C2.ADM_DATE) < 31

ORDER BY C1.Dsch_Date

OPTION(FORCE ORDER);