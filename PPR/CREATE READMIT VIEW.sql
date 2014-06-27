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
ALTER VIEW [smsdss].[vReadmits]
AS
SELECT T.Pt_No
, T.Med_Rec_No
, MIN(R.Adm_Date) ReadmittedDT
, MIN(R.[Pt_NO]) NextVisitID
, SUM(CASE
		WHEN R.Adm_Date <= DATEADD(D, 30, ISNULL(T.Dsch_Date, R.Adm_Date))
		THEN 1
		ELSE 0
		END
	  ) READMITNEXT30

FROM smsdss.BMH_PLM_PtAcct_V      T
LEFT JOIN smsdss.BMH_PLM_PtAcct_V R
ON T.Med_Rec_No = R.Med_Rec_No
AND T.Pt_No < R.Pt_No
AND R.Plm_Pt_Acct_Type = 'I'
AND R.Pt_No < '20000000'

WHERE T.Plm_Pt_Acct_Type = 'I'
AND T.Pt_No < '20000000'

GROUP BY T.Pt_No, T.Med_Rec_No


GO


