/*
***********************************************************************
File: zero_balance_accounts.sql

Input Parameters:
	None

Tables/Views:
	smsmir.pay
	smsdss.bmh_plm_ptacct_v
	smsmir.vst_rpt
	smsdss.pyr_dim_v
	smsdss.pay_cd_dim_v

Creates Table:
	None

Functions:
	SUM OVER(PARTITION BY ORDER BY)

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get accounts that went to a zero balance in a particular year

Revision History:
Date		Version		Description
----		----		----
2019-07-09	v1			Initial Creation
2019-07-10	v2			Addition of AND A.unit_seq_no = VST.unit_seq_no
						in join of smsmir.vst_rpt
***********************************************************************
*/
SELECT pav.Med_Rec_No
, a.pt_id
, CAST(PAV.ADM_daTE AS DATE) AS [Adm_Date]
, CAST(PAV.DSCH_DATE AS DATE) AS [Dsch_Date]
, A.unit_seq_no
, A.from_file_ind
, a.pay_date
, a.tot_pay_adj_amt
, a.pyr_cd
, A.pay_seq_no
, PAV.tot_chg_amt
, [FC] = PDV.pyr_group2
, PAV.Pyr1_Co_Plan_Cd
, PAV.Pyr2_Co_Plan_Cd
, PAV.Pyr3_Co_Plan_Cd
, PAV.Pyr4_Co_Plan_Cd
, PAV.tot_adj_amt AS [Total_Adjustments]
, [Running_Total_Payments] = SUM(A.tot_pay_adj_amt) OVER(PARTITION BY A.PT_ID ORDER BY A.PAY_SEQ_NO)
, [Running_Total_Balance] = PAV.tot_chg_amt + SUM(A.tot_pay_adj_amt) OVER(PARTITION BY A.PT_ID ORDER BY A.PAY_SEQ_NO)

INTO #TEMPA

FROM SMSMIR.PAY AS A
INNER JOIN SMSDSS.BMH_PLM_PtAcct_V AS PAV
ON A.PT_ID = PAV.PT_NO
	AND A.unit_seq_no = PAV.unit_seq_no
	AND A.from_file_ind = PAV.from_file_ind
INNER JOIN SMSDSS.pyr_dim_v AS PDV
ON PAV.Pyr1_Co_Plan_Cd = PDV.pyr_cd
	AND PAV.Regn_Hosp = PDV.orgz_cd

WHERE pav.Dsch_Date < '2019-01-01'
AND LEFT(PAV.PTNO_NUM, 1) != '2'
AND LEFT(PAV.PTNO_NUM, 4) != '1999'
AND LEN(PAV.PtNo_Num) = 8
AND PAV.tot_chg_amt > 0
AND A.tot_pay_adj_amt != 0

ORDER BY A.pt_id
, A.unit_seq_no
, A.pay_seq_no
;

-- GET DENIAL DATA --
SELECT X.pt_id
, X.unit_seq_no
, X.from_file_ind
, X.pay_cd
, PDV.pay_cd_name
, X.pay_seq_no
, X.pay_date
, [RN] = ROW_NUMBER() OVER(PARTITION BY X.PT_ID ORDER BY X.PAY_DATE, X.PAY_SEQ_NO)

INTO #TEMPB

FROM SMSMIR.pay AS X
INNER JOIN SMSDSS.pay_cd_dim_v AS PDV
ON X.pay_cd = PDV.pay_cd
	AND X.orgz_cd = PDV.orgz_cd

WHERE LEFT(X.PAY_CD, 3) = '105'
AND X.pay_cd != '10501435'
AND X.PT_ID IN (
	SELECT DISTINCT A.PT_ID
	FROM #TEMPA AS A
)
ORDER BY X.pt_id
, X.pay_seq_no

SELECT A.*

INTO #TEMPC

FROM #TEMPB AS A
INNER JOIN (
	SELECT B.PT_ID
	, B.unit_seq_no
	, B.from_file_ind
	, MAX(B.RN) AS [Max_RN]
	FROM #TEMPB AS B
	GROUP BY B.PT_ID
	, B.unit_seq_no
	, B.from_file_ind
) AS B
ON A.pt_id = B.pt_id
	AND A.unit_seq_no = B.unit_seq_no
	AND A.from_file_ind = B.from_file_ind
	AND A.RN = B.Max_RN
;

-- PULL IT ALL TOGETHER
SELECT A.Med_Rec_No
, A.pt_id
, A.Adm_Date
, A.Dsch_Date
, A.unit_seq_no
, A.from_file_ind
, CAST(A.pay_date AS DATE) AS [Pay_Date]
, A.pay_seq_no
, CAST(A.tot_pay_adj_amt AS money) AS [tot_pay_adj_amt]
, A.pyr_cd
, A.FC
, A.Pyr1_Co_Plan_Cd
, A.Pyr2_Co_Plan_Cd
, A.Pyr3_Co_Plan_Cd
, A.Pyr4_Co_Plan_Cd
, CAST(VST.ins_pay_amt AS MONEY) AS [Total_Ins_Pay_Amt]
, CAST((VST.tot_pay_amt - VST.ins_pay_amt) AS money) AS [Tot_Pt_Pay_Amt]
, C.pay_cd AS [Denial_Cd]
, C.pay_cd_name AS [Denail_Cd_Name]
, C.pay_date AS [Denial_Cd_Date]
, A.tot_chg_amt AS [Total_Visit_Charges]
, A.Running_Total_Payments AS [Running_Total_Pay_Adj]
, A.Running_Total_Balance

FROM #TEMPA AS A
INNER JOIN (
	SELECT B.PT_ID
	, B.unit_seq_no
	, B.from_file_ind
	, MAX(B.pay_seq_no) AS [Max_Pay_Seq_No]
	FROM #TEMPA AS B
	GROUP BY B.PT_ID
	, B.unit_seq_no
	, B.from_file_ind
) AS B
ON A.pt_id = B.pt_id
	AND A.unit_seq_no = B.unit_seq_no
	AND A.from_file_ind = B.from_file_ind
	AND A.pay_seq_no = B.Max_Pay_Seq_No
LEFT OUTER JOIN SMSMIR.vst_rpt AS VST
ON A.PT_ID = VST.PT_ID
	AND A.unit_seq_no = VST.unit_seq_no
	AND A.FROM_FILE_IND = VST.FROM_FILE_IND
LEFT OUTER JOIN #TEMPC AS C
ON A.pt_id = C.pt_id
	AND A.unit_seq_no = C.unit_seq_no
	AND A.from_file_ind = C.from_file_ind

WHERE A.Running_Total_Balance = '0'
AND YEAR(A.pay_date) = 2018

ORDER BY A.pt_id
, A.unit_seq_no
, A.pay_seq_no
;

DROP TABLE #TEMPA
DROP TABLE #TEMPB
DROP TABLE #TEMPC
;
