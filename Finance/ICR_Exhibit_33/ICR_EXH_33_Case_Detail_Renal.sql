SELECT A.User_Pyr1_Cat
, A.PtNo_Num
, A.unit_seq_no
, A.Pyr1_Co_Plan_Cd
, A.Adm_Date
, A.pt_type
, A.hosp_svc
, B.Chg_Qty AS [Cases]
, B.Tot_Chg_Amt
, A.tot_pay_amt
, A.tot_adj_amt
, A.Tot_Amt_Due

INTO #TEMPA

FROM smsdss.BMH_PLM_PtAcct_V as a 
inner join smsdss.BMH_PLM_PtAcct_Svc_V_Hold as b
On a.Pt_Key = b.Pt_Key 
	and a.Bl_Unit_Key=b.Bl_Unit_key

WHERE b.Svc_Date BETWEEN '1/1/17' and '12/31/17'
AND a.Plm_Pt_Acct_Type = 'I'
--AND a.pt_type IN ('R')
AND b.Svc_Cd BETWEEN '05400000' AND '05499999'

OPTION(FORCE ORDER)

GO
;

SELECT A.User_Pyr1_Cat
, A.PtNo_Num
, A.unit_seq_no
, A.Pyr1_Co_Plan_Cd
, A.Adm_Date
, A.pt_type
, A.hosp_svc
, A.tot_pay_amt
, A.tot_adj_amt
, A.Tot_Amt_Due
, SUM(A.TOT_CHG_AMT) AS [Total_Chgs]
, SUM(A.CASES) AS [Cases]

FROM #TEMPA AS A

GROUP BY A.User_Pyr1_Cat
, A.PtNo_Num
, A.unit_seq_no
, A.Pyr1_Co_Plan_Cd
, A.Adm_Date
, A.pt_type
, A.hosp_svc
, A.tot_pay_amt
, A.tot_adj_amt
, A.Tot_Amt_Due

GO
;

DROP TABLE #TEMPA
GO
;