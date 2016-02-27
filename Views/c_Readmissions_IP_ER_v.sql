USE [SMSPHDSSS0X0]

/******

Object: View [smsdss].[c_Readmissions_IP_ER_v]

This gets readmissions for inpatients and ED visits only.

******/

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [smsdss].[c_Readmission_IP_ER_v]
AS

WITH cte AS (
	SELECT A.PtNo_Num
	, A.Med_Rec_No
	, A.Dsch_Date
	, A.Adm_Date
	, M.adm_src_desc
	, ROW_NUMBER() OVER (
							PARTITION BY A.MED_REC_NO 
							ORDER BY A.ADM_DATE
							) AS r
	                     
	FROM smsdss.BMH_PLM_PtAcct_V   AS A
	LEFT JOIN smsdss.adm_src_mstr  AS M
	ON Adm_Source = LTRIM(RTRIM(M.ADM_SRC))
	AND M.orgz_cd = 'S0X0'
  
	WHERE (
		A.PtNo_Num < '20000000' -- INPATIENTS
		OR
			(
				A.PtNo_Num >= '80000000' -- ER VISITS
				AND
				A.PtNo_Num < '90000000'
			)
	)
	AND LEFT(A.PtNo_Num, 4) != '1999' -- NO PREADMITS
	AND A.tot_chg_amt > '0' -- MAKE SURE THERE WAS SOME CHARGES
)

SELECT c1.Med_Rec_No                       AS [MRN]
, c1.PtNo_Num                              AS [INDEX]
, c2.PtNo_Num                              AS [READMIT]
, c2.adm_src_desc                          AS [READMIT SOURCE DESC]
, CAST(c1.Dsch_Date AS DATE)               AS [INITIAL DISCHARGE]
, CAST(c2.Adm_Date AS DATE)                AS [READMIT DATE]
, DATEDIFF(DAY, c1.Dsch_Date, c2.Adm_Date) AS INTERIM
, ROW_NUMBER() OVER (
				    PARTITION BY C1.MED_REC_NO 
				    ORDER BY C1.PTNO_NUM
				    ) AS [VISIT COUNT]


FROM cte c1
INNER JOIN cte c2 
ON c1.Med_Rec_No = c2.Med_Rec_No

WHERE c1.Adm_Date <> c2.Adm_Date
AND c1.r+1 = c2.r
AND DATEDIFF(DAY, c1.Dsch_Date, c2.Adm_Date) > 0

GO