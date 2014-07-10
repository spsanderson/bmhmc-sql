SELECT DISTINCT PT_NO
, Dsch_Date
, DATEPART(MONTH, DSCH_DATE) AS [DISCH MONTH]

FROM smsdss.BMH_PLM_PtAcct_V

WHERE Dsch_Date >= '2012-01-01'
AND Dsch_Date < '2014-06-01'
AND Plm_Pt_Acct_Type = 'I'
AND PtNo_Num < '20000000'