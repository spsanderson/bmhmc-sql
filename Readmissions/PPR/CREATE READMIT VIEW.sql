USE [SMSPHDSSS0X0]
GO

/****** Object:  View [smsdss].[vReadmits]    Script Date: 2/7/2017 9:27:52 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO








ALTER VIEW [smsdss].[vReadmits]
AS
WITH cte AS (
  SELECT PTNO_NUM
  	, Med_Rec_No
	, Dsch_Date
	, Adm_Date
	, M.adm_src_desc
	, ROW_NUMBER() OVER (
	                     PARTITION BY MED_REC_NO 
	                     ORDER BY ADM_DATE
	                     ) AS r
	                     
  FROM smsdss.BMH_PLM_PtAcct_V
  LEFT JOIN smsdss.adm_src_mstr AS M
  ON Adm_Source = LTRIM(RTRIM(M.ADM_SRC))
  AND M.orgz_cd = 'S0X0'
  
  WHERE Plm_Pt_Acct_Type = 'I'
  AND PtNo_Num < '20000000' 
  AND LEFT(PtNo_Num, 1) = '1'
  AND LEFT(PtNo_Num, 4) != '1999'
  )
SELECT
c1.PtNo_Num                                AS [INDEX]
, c2.PtNo_Num                              AS [READMIT]
, c2.adm_src_desc                          AS [READMIT SOURCE DESC]
, c1.Med_Rec_No                            AS [MRN]
, CAST(c1.Dsch_Date AS DATE)               AS [INITIAL DISCHARGE]
, CAST(c2.Adm_Date AS DATE)                AS [READMIT DATE]
, DATEDIFF(DAY, c1.Dsch_Date, c2.Adm_Date) AS INTERIM
, ROW_NUMBER() OVER (
				    PARTITION BY C1.MED_REC_NO 
				    ORDER BY C1.PTNO_NUM
				    ) AS [ADMIT COUNT]


FROM cte c1
INNER JOIN cte c2 ON c1.Med_Rec_No = c2.Med_Rec_No

WHERE c1.Adm_Date <> c2.Adm_Date
AND c1.r+1 = c2.r









GO


