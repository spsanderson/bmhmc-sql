-- CREATE TABLE TO STORE CTE RESULTS
DECLARE @PPR TABLE(
	VISIT1      VARCHAR(20)
	, READMIT   VARCHAR(20)
	, MRN       VARCHAR(10)
	, INIT_DISC DATETIME
	, RA_ADM    DATETIME
	, R1        INT
	, R2        INT
	, INTERIM   VARCHAR(20)
	, RA_COUNT  INT
	, FLAG      VARCHAR(2)
);

-- THE CTE THAT WILL GET USED TO POPULATE THE ABOVE TABLE
WITH cte AS (
  SELECT PTNO_NUM
  	, Med_Rec_No
	, Dsch_Date
	, Adm_Date
	, ROW_NUMBER() OVER (
	                     PARTITION BY MED_REC_NO 
	                     ORDER BY PtNo_Num
	                     ) AS r
	                     
  FROM smsdss.BMH_PLM_PtAcct_V
  
  WHERE Plm_Pt_Acct_Type = 'I'
  AND PtNo_Num < '20000000' 
  )

-- INSERT CTE RESULTS INTO PPR TABLE
INSERT INTO @PPR
SELECT
c1.PtNo_Num                                AS [INDEX]
, c2.PtNo_Num                              AS [READMIT]
, c1.Med_Rec_No                            AS [MRN]
, c1.Dsch_Date                             AS [INITIAL DISCHARGE]
, c2.Adm_Date                              AS [READMIT DATE]
, C1.r
, C2.r
, DATEDIFF(DAY, c1.Dsch_Date, c2.Adm_Date) AS INTERIM
, ROW_NUMBER() OVER (
				    PARTITION BY C1.MED_REC_NO 
				    ORDER BY C1.PTNO_NUM ASC
				    ) AS [RA COUNT]
				    
, CASE 
	WHEN DATEDIFF(DAY, c1.Dsch_Date, c2.Adm_Date) <= 30 
	THEN 1 
	ELSE 0
  END [FLAG]

FROM cte       C1
INNER JOIN cte C2
ON C1.Med_Rec_No = C2.Med_Rec_No

WHERE C1.Adm_Date <> C2.Adm_Date
AND C1.r + 1 = C2.r

ORDER BY C1.Med_Rec_No, C1.Dsch_Date

-- MANIPULATE PPR TABLE
SELECT PPR.VISIT1
, PPR.READMIT
, PPR.MRN
, PPR.INIT_DISC
, PPR.RA_ADM
, PPR.R1
, PPR.R2
, PPR.INTERIM
--, PPR.RA_COUNT
, PPR.FLAG

FROM @PPR PPR

WHERE PPR.MRN = '797178'

ORDER BY PPR.MRN, PPR.INIT_DISC

-------------------------

WITH cte AS (
  SELECT PTNO_NUM
  	, Med_Rec_No
	, Dsch_Date
	, Adm_Date
	, ROW_NUMBER() OVER (
	                     PARTITION BY MED_REC_NO 
	                     ORDER BY PtNo_Num
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
				    ) AS [RA COUNT]
				    
,  CASE 
WHEN DATEDIFF(DAY, c1.Dsch_Date, c2.Adm_Date) <= 30 THEN 1 
ELSE 0
END [FLAG]
,  case when 'FLAG'='0' THEN (ROW_NUMBER() OVER (
					PARTITION BY c1.med_rec_no,'FLAG'
					ORDER BY C1.MED_REC_NO,C1.PTNO_NUM
					
					))
					ELSE ''
					END AS [FLAG_2]



FROM cte c1
INNER JOIN cte c2 ON c1.Med_Rec_No = c2.Med_Rec_No

WHERE c1.Adm_Date <> c2.Adm_Date
AND c1.r+1 = c2.r
--AND c2.Adm_Date BETWEEN c1.Dsch_Date AND DATEADD(DAY,30,c1.Dsch_Date)

ORDER BY c1.med_rec_no,c1.dsch_date