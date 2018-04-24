DECLARE @START AS DATE;
DECLARE @END   AS DATE;

SET @START = '2017-01-01';
SET @END   = '2017-10-01';

-----

select bill_no
, appl_dollars_recovered 
, pay_cd

into #tempa

from smsmir.mir_pay
left outer join smsdss.c_Softmed_Denials_Detail_v
ON smsmir.mir_pay.pt_id = smsdss.c_Softmed_Denials_Detail_v.bill_no

WHERE discharged >= @START
AND discharged < @END
AND LEFT(smsmir.mir_pay.pay_cd, 4) = '0974'

-----

SELECT PLM.Med_Rec_No
, PLM.PtNo_Num
, PLM.pt_no   
, PLM.Pt_Name
, PLM.prin_dx_cd
, DXCD.alt_clasf_desc
, PLM.Atn_Dr_No
, PDM.pract_rpt_name
, PLM.tot_chg_amt
, PAY.pay_cd

INTO #tempb

FROM smsdss.BMH_PLM_PtAcct_V AS PLM
LEFT OUTER JOIN smsdss.pract_dim_v AS PDM
ON PLM.Atn_Dr_No = PDM.src_pract_no
       AND PLM.Regn_Hosp = PDM.orgz_cd
LEFT OUTER JOIN smsdss.dx_cd_dim_v AS DXCD
ON PLM.prin_dx_cd = DXCD.dx_cd
       AND PLM.prin_dx_cd_schm = DXCD.dx_cd_schm
LEFT OUTER JOIN smsmir.mir_pay AS PAY
ON PLM.Pt_No = PAY.pt_id
       AND LEFT(PAY.PAY_CD, 4) = '0974'


WHERE PLM.User_Pyr1_Cat IN ('AAA', 'ZZZ')
AND PLM.Dsch_Date >= @START
AND PLM.Dsch_Date < @END
AND PLM.Days_Stay < 2
AND PLM.Plm_Pt_Acct_Type = 'I'
AND Atn_Dr_No NOT IN (
       '000000', '000059', '999995', '999999'
)
AND LEFT(PLM.PTNO_NUM, 1) != '2'
option(force order);

-----

select a.*
, b.appl_dollars_recovered
, CASE
       WHEN b.bill_no IS NOT NULL
              THEN 1
              ELSE 0
  END AS [Denial_Flag]

from #tempb as a
left outer join #tempa as b
on a.Pt_No = b.bill_no

-----
DROP TABLE #tempa, #tempb
