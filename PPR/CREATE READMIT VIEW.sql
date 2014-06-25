/*
########################################################################

CREATE A READMISSIONS VIEW TABLE THAT WILL GET USED TO CALCULATE
CHAIN LENGTH AND CHAIN COUNTS

########################################################################
*/
USE [SMSPHDSSS0X0]
GO

/****** 

Object:  View [smsdss].[vReadmits] Script Date: 06/24/2014 10:55:12 

******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER VIEW [smsdss].[vReadmits]
AS
SELECT T.PtNo_Num
, T.Med_Rec_No
, MIN(R.Adm_Date) ReadmittedDT
, MIN(R.[PtNo_Num]) NextVisitID
, SUM(CASE
		WHEN R.Adm_Date <= DATEADD(D, 30, ISNULL(T.Dsch_Date, R.Adm_Date))
		THEN 1
		ELSE 0
		END
	  ) READMITNEXT30

FROM smsdss.BMH_PLM_PtAcct_V      T
LEFT JOIN smsdss.BMH_PLM_PtAcct_V R
ON T.Med_Rec_No = R.Med_Rec_No
AND T.PtNo_Num < R.PtNo_Num
AND R.Plm_Pt_Acct_Type = 'I'
AND R.PtNo_Num < '20000000'

WHERE T.Plm_Pt_Acct_Type = 'I'
--AND R.Plm_Pt_Acct_Type = 'I'
AND T.PtNo_Num < '20000000'
--AND R.PtNo_Num < '20000000'

GROUP BY T.PtNo_Num, T.Med_Rec_No


GO