SELECT A.Med_Rec_No
, A.PtNo_Num
, A.Adm_Date
, A.fc
, A.hosp_svc
, B.reg_fc
, A.tot_pay_amt

FROM smsdss.BMH_PLM_PtAcct_V AS A
LEFT OUTER JOIN smsmir.acct AS B
ON A.Pt_No = B.pt_id
	AND A.unit_seq_no = B.unit_seq_no

WHERE A.hosp_svc NOT IN ('EOR','OBV')
AND LEFT(PTNO_NUM, 1) = '8'
--AND A.fc IN ('P','J','9','8')
AND YEAR(A.Adm_Date) = 2017
--AND B.reg_fc = 'D'
AND LEFT(A.Pyr1_Co_Plan_Cd, 1) IN ('I','W')