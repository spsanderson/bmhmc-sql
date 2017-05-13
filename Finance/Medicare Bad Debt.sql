SELECT a.Pt_No,
a.from_file_ind,
       b.unit_no,
       a.Med_Rec_No,
       a.Pt_Name,
       a.fc,
       a.User_Pyr1_Cat,
       b.resp_cd,
       a.pt_type,
       a.hosp_svc,
       a.Adm_Date,
       a.Dsch_Date,
       b.unit_dtime,
       a.tot_chg_amt,
       a.Tot_Amt_Due,
       a.Pyr1_Co_Plan_Cd,
       a.Pyr2_Co_Plan_Cd,
       a.Pyr3_Co_Plan_Cd,
       a.Pyr4_Co_Plan_Cd,
       b.alt_bd_wo_amt,
       b.bd_wo_dtime,
       b.arch_xfer_dtime,
       b.arch_reactv_Dtime,
       (
       SELECT r.pol_no  +ISNULL(LTRIM(RTRIM(r.grp_no)),'')
       FROm smsmir.mir_pyr_plan as r
       --WHERE LEFT(r.pyr_cd,1) IN ('A','Z')
       WHERE r.pt_id NOT BETWEEN '000070000000' AND '000079999999'
       AND r.pyr_cd=a.Pyr1_Co_Plan_Cd AND pt_id=a.Pt_No AND r.pt_id_start_dtime=a.pt_id_start_dtime            ) as 'Pyr1_Pol',
       (
       SELECT r.pol_no  +ISNULL(LTRIM(RTRIM(r.grp_no)),'')
       FROm smsmir.mir_pyr_plan as r
       --WHERE LEFT(r.pyr_cd,1) IN ('A','Z')
       WHERE r.pt_id NOT BETWEEN '000070000000' AND '000079999999'
       AND r.pyr_cd=a.Pyr2_Co_Plan_Cd AND pt_id=a.Pt_No AND r.pt_id_start_dtime=a.pt_id_start_dtime            ) as 'Pyr2_Pol',
       (
       SELECT 'Pyr3_Pol'=r.pol_no  +ISNULL(LTRIM(RTRIM(r.grp_no)),'')
       FROm smsmir.mir_pyr_plan as r
       --WHERE LEFT(r.pyr_cd,1) IN ('A','Z')
       WHERE r.pt_id NOT BETWEEN '000070000000' AND '000079999999'
       AND r.pyr_cd=a.Pyr3_Co_Plan_Cd AND pt_id=a.Pt_No AND r.pt_id_start_dtime=a.pt_id_start_dtime            ) as 'Pyr3_Pol',
       (
       SELECT r.pol_no  +ISNULL(LTRIM(RTRIM(r.grp_no)),'')
       FROm smsmir.mir_pyr_plan as r
       --WHERE LEFT(r.pyr_cd,1) IN ('A','Z')
       WHERE r.pt_id NOT BETWEEN '000070000000' AND '000079999999'
       AND r.pyr_cd=a.Pyr4_Co_Plan_Cd AND pt_id=a.Pt_No AND r.pt_id_start_dtime=a.pt_id_start_dtime            ) as 'Pyr4_Pol',
       q.end_collect_dtime,
       (
       select MIN(tt.cmnt_dtime)


from smsmir.mir_acct_hist as tt

WHERE a.pt_no=tt.pt_id AND tt.acct_hist_cmnt LIKE '%MESSAGE PTRS%'


GROUP BY pt_id
) as '1st_Pt_Bill_Date',
--(
--       select MIN(xx.cmnt_dtime)


--from smsmir.mir_acct_hist as xx

--WHERE a.pt_no=xx.pt_id AND xx.acct_hist_cmnt LIKE '%MCR  %' OR xx.acct_hist_cmnt LIKE '%MC A %'


--GROUP BY pt_id
--) as '1st_Remit_Date',
s.[1st_Remit_Dtime],
t.acct_hist_cmnt as 'Deductible_Coins_IP',
u.tot_pay_adj_amt as 'Deduct_Coins_OP'
       
       

FROM smsdss.BMH_PLM_PtAcct_V as a LEFT JOIN smsmir.mir_acct as b
ON a.Pt_No=b.pt_id AND a.pt_id_start_dtime=b.pt_id_start_dtime AND a.unit_seq_no=b.unit_seq_no
--LEFT JOIN smsdss.BMH_PLM_PtAcct_Payor_V as b
--ON a.Pt_Key=b.Pt_Key AND a.Bl_Unit_Key=b.Bl_Unit_Key
left outer join smsdss.c_MJRF_Closed_Accts_v as q
ON a.Pt_No=q.acct_no
LEFT OUTER JOIN smsdss.c_1st_Remit_V as s
ON a.Pt_No=s.pt_id AND a.unit_seq_no=s.unit_Seq_no
LEFT OUTER JOIN smsmir.mir_Acct_hist as t
ON a.pt_no=t.pt_id AND t.acct_hist_cmnt LIKE '%DEDUCT.%'
LEFT OUTER JOIN smsmir.mir_pay as u
ON a.Pt_No=u.pt_id AND a.unit_seq_no=u.unit_seq_no AND u.pay_cd='03300803' AND s.[1st_remit_Dtime]=u.pay_dtime and u.tot_pay_adj_amt > '0'


WHERE (b.arch_xfer_dtime BETWEEN '2016-01-01 00:00:00.000' AND '2016-12-31 23:59:59.000'
      AND a.fc IN ('0','1','2','3','4','5','6','7','8','9')
      AND (b.unit_no IN ('1','2','3','4','5','6','7','8','9') OR b.unit_no IS NULL)
      AND (LEFT(pyr1_co_plan_Cd,1) IN ('A','Z')
      OR LEFT( pyr2_co_plan_cd,1) IN ('A','Z')
      OR LEFT(pyr3_co_plan_cd,1) IN ('A','Z')
      OR LEFT(Pyr4_Co_Plan_Cd,1) IN ('A','Z'))
      --AND a.bd_wo_date BETWEEN '01/01/12' AND '12/31/12')
      AND NOT(b.alt_bd_wo_amt IS NULL)
      AND a.Pt_No NOT IN
      (
      SELECT pt_no
      FROM smsdss.BMH_PLM_PtAcct_V 
      WHERE (Pyr1_Co_Plan_Cd IN ('A65','Z79','A79')
      OR Pyr2_Co_Plan_Cd IN ('A65','Z79','A79')
      OR Pyr3_Co_Plan_Cd IN ('A65','Z79','A79')
      OR Pyr4_Co_Plan_Cd IN ('A65','Z79','A79'))
      )
)


--ORDER BY b.pt_id, b.unit_no asc

/*
Runs slow and contains dups.  I’m sure it can be corrected/run time improved.  

These lines are the source of the duplicates.  Thanks.

t.acct_hist_cmnt as 'Deductible_Coins_IP',
u.tot_pay_adj_amt as 'Deduct_Coins_OP'
*/