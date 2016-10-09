DECLARE @START DATE;
DECLARE @END DATE;

SET @START = '2016-01-01';
SET @END = '2016-07-01';

SELECT COUNT(ED_MD) [Inpatient Count]
, ED_MD
, EDMDID
, CASE
     WHEN User_Pyr1_Cat IN ('AAA','ZZZ') Then 'Medicare'
     WHEN User_Pyr1_Cat = 'WWW' Then 'Medicaid'
     WHEN User_Pyr1_Cat = 'MIS' Then 'Self Pay'
     WHEN User_Pyr1_Cat = 'CCC' Then 'Comp'
     WHEN User_Pyr1_Cat = 'NNN' Then 'No Fault'
     ELSE 'Other'
  END as 'Payer Category'

FROM SMSDSS.c_Wellsoft_Rpt_tbl     AS A
INNER JOIN SMSDSS.BMH_PLM_PtAcct_V AS B
ON A.Account = B.PtNo_Num

WHERE ARRIVAL >= @START
AND ARRIVAL < @END 
AND B.Plm_Pt_Acct_Type = 'I'
AND B.PtNo_Num < '20000000'
AND LEFT(B.PTNO_NUM, 4) != '1999'

GROUP BY ED_MD, EDMDID, B.User_Pyr1_Cat