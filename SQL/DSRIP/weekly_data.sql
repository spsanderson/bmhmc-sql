-- VARIABLE DECLARTION AND SETTING
DECLARE @START DATE;
DECLARE @END   DATE;

SET @START = '2016-06-15';
SET @END   = '2016-06-22';

-- COLUMNS SELECTED
SELECT A.Med_Rec_No
, B.PtNo_Num
, B.Pt_Name
, CAST(B.Adm_Date AS date)     AS [Adm_Date]
, CAST(B.Dsch_Date AS date)    AS [Dsch_Date]
, DATEPART(MONTH, B.Dsch_Date) AS [Dsch_Month]
, DATEPART(YEAR, B.Dsch_Date)  AS [Dsch_Year]
, CAST(B.Days_Stay AS INT)     AS [Days Stay]
, CASE
WHEN LEFT(B.PtNo_Num, 1) = '8'
THEN 1
ELSE 0
  END AS [Treat and Release]
, CASE
WHEN C.Account = B.PtNo_Num
AND LEFT(C.Account, 1) = '1'
THEN 1
ELSE 0
  END AS [ED to IP Admit]
, CASE
WHEN LEFT(B.PtNo_Num, 1) = '1'
THEN 1
ELSE 0
  END AS [IP Visit]
, CASE
WHEN D.[READMIT] IS NOT NULL
THEN 1
ELSE 0
  END AS [Readmit Flag]
, D.[READMIT DATE]
, D.INTERIM

-- FROM STATEMENT
FROM smsdss.c_DSRIP_COPD                  AS A
INNER JOIN smsdss.BMH_PLM_PtAcct_V        AS B
ON A.MED_REC_NO = B.Med_Rec_No
LEFT OUTER JOIN smsdss.c_Wellsoft_Rpt_tbl AS C
ON B.Med_Rec_No = C.MR#
AND B.PtNo_Num = C.Account
LEFT OUTER JOIN smsdss.vReadmits          AS D
ON B.Med_Rec_No = D.MRN
AND B.PtNo_Num = D.[INDEX]
AND D.INTERIM < 31

-- CONDITION CLAUSE
WHERE B.Dsch_Date >= @START
AND B.Dsch_Date < @END
AND LEFT(B.PtNo_Num, 1) IN ('1', '8')
AND B.tot_chg_amt > 0





