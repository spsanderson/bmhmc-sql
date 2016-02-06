DECLARE @START DATE;
DECLARE @END   DATE;

SET @START = '2015-12-01';
SET @END   = '2016-01-01';

SELECT DISTINCT(A.Pt_No)
, A.Med_Rec_No
, a.prin_dx_cd
, A.Pyr1_Co_Plan_Cd
, A.tot_chg_amt                     AS [Total Charges]
, A.reimb_amt
, A.tot_adj_amt
, A.tot_pay_amt
, D.pract_rpt_name
, C.obv_strt_Dtime
, C.dsch_strt_dtime
, DATEDIFF(HOUR, C.obv_strt_Dtime
			   , C.dsch_strt_dtime) AS [Hours in Observation]

FROM smsdss.bmh_plm_ptacct_v        AS A
LEFT OUTER JOIN smsmir.mir_actv     AS B
ON a.Pt_No = b.pt_id 
	AND A.unit_seq_no = b.unit_seq_no
LEFT OUTER JOIN SMSDSS.c_obv_Comb_1 AS C
ON C.pt_id = A.PtNo_Num
LEFT OUTER JOIN SMSDSS.pract_dim_v  AS D
ON A.Adm_Dr_No = D.src_pract_no
	AND D.orgz_cd = 'S0X0'

WHERE B.actv_cd = '04700035'
AND B.actv_dtime >= @START
AND B.actv_dtime < @END
--AND A.Adm_Date >= @START
--AND A.Adm_Date < @END

AND A.Plm_Pt_Acct_Type <> 'I'