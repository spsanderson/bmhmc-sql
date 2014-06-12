/*
QUERY GETS 30 DAY READMISSIONS FROM THE BMH_PLM_PTACCT_V TABLE
AND WILL RUN THE ENTRIRE TABLE IN ABOUT 1 MINUTE
*/

WITH cte AS (
  SELECT PTNO_NUM
  	, Med_Rec_No
	, Dsch_Date
	, Adm_Date
	, ROW_NUMBER() OVER (
	                     PARTITION BY MED_REC_NO 
	                     ORDER BY ADM_DATE
	                     ) AS r
	                     
  FROM smsdss.BMH_PLM_PtAcct_V
  
  WHERE Plm_Pt_Acct_Type = 'I'
  AND PtNo_Num < '20000000' 
  )
SELECT
c1.PtNo_Num                                AS [INDEX]
, c2.PtNo_Num                              AS [READMIT]
, c1.Med_Rec_No                            AS [MRN]
, c1.Dsch_Date                             AS [INITIAL DISCHARGE]
, c2.Adm_Date                              AS [READMIT DATE]
, DATEDIFF(DAY, c1.Dsch_Date, c2.Adm_Date) AS INTERIM
, ROW_NUMBER() OVER (
				    PARTITION BY C1.MED_REC_NO 
				    ORDER BY C1.PTNO_NUM
				    ) AS [30D RA COUNT]


FROM cte c1
INNER JOIN cte c2 ON c1.Med_Rec_No = c2.Med_Rec_No

WHERE c1.Adm_Date <> c2.Adm_Date
AND c1.r+1 = c2.r
AND c2.Adm_Date BETWEEN c1.Dsch_Date AND DATEADD(DAY,30,c1.Dsch_Date)

ORDER BY c1.Dsch_Date
