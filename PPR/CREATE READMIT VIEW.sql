USE [SMSPHDSSS0X0]
GO

/****** 

Object:  View [smsdss].[vReadmits]    Script Date: 06/30/2014 12:15:07 

******/

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER VIEW [smsdss].[vReadmits]
AS
WITH cte AS (
  SELECT Pt_No
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
c1.Pt_No                                   AS [INDEX]
, c2.Pt_No                                 AS [READMIT]
, c1.Med_Rec_No                            AS [MRN]
, c1.Dsch_Date                             AS [INITIAL DISCHARGE]
, c2.Adm_Date                              AS [READMIT DATE]
, DATEDIFF(DAY, c1.Dsch_Date, c2.Adm_Date) AS INTERIM
, ROW_NUMBER() OVER (
				    PARTITION BY C1.MED_REC_NO 
				    ORDER BY C1.PT_NO
				    ) AS [30D RA COUNT]

FROM cte c1
INNER JOIN cte c2 ON c1.Med_Rec_No = c2.Med_Rec_No

WHERE c1.Adm_Date <> c2.Adm_Date
AND c1.r+1 = c2.r

GO