/*
This will get a list of patients who have only been to BMH once for hosp_svc = PSY
*/

DECLARE @START_DATE DATE;
DECLARE @END_DATE   DATE;

SET @START_DATE = '2017-01-01';
SET @END_DATE   = '2017-12-31';

----------

SELECT A.Med_Rec_No
, A.PtNo_Num
, A.hosp_svc
, A.Adm_Date
, A.Dsch_Date
, DATEPART(QUARTER, A.DSCH_DATE) AS [Dsch_Qtr]
, [PSY_Vist_Count] = ROW_NUMBER() OVER(PARTITION BY A.MED_REC_NO ORDER BY A.ADM_DATE)

INTO #TEMPA

FROM smsdss.BMH_PLM_PtAcct_V AS A

WHERE A.Dsch_Date BETWEEN @START_DATE AND @END_DATE
AND A.hosp_svc = 'PSY'
AND A.tot_chg_amt > 0
AND A.Med_Rec_No NOT IN (
	SELECT ZZZ.MED_REC_NO
	FROM smsdss.BMH_PLM_PtAcct_V AS ZZZ
	WHERE ZZZ.Dsch_Date < @START_DATE
	AND ZZZ.hosp_svc = 'PSY'
)

ORDER BY A.Adm_Date
;

----------

SELECT A.Med_Rec_No
, A.PtNo_Num
, A.hosp_svc
, A.Adm_Date
, A.Dsch_Date
, A.Dsch_Qtr
--, A.PSY_Vist_Count

FROM #TEMPA AS A

WHERE A.Med_Rec_No NOT IN (
	SELECT XXX.MED_REC_NO
	FROM #TEMPA AS XXX
	WHERE XXX.PSY_Vist_Count > 1
)
;

----------

DROP TABLE #TEMPA
;