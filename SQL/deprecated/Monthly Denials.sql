SELECT visit_attend_phys
, Attend_Dr
, attend_dr_no
, Attend_Spclty
, bill_no
, last_name
, first_name
, rvw_date
, patient_type
, Initial_Denial
, appl_type
, appl_status
, Pending
, Finalized
, appl_dollars_appealed
, [1st_Lvl_Appealed_Ind]
, [2nd_Lvl_Appealed_Ind]
, s_cpm_Dollars_not_appealed
, No_Appeal
, appl_dollars_recovered
, [1st_Lvl_Recovery]
, DRA_Lvl_Recovery
, s_qm_subseq_appeal
, External_Appeal
, s_qm_subseq_appeal_date
, assoc_prvdr
, Denial_Dr
, Denial_Dr_No
, BMH_Specialty
, Denial_Spclty
, s_rvw_dnl_rsn
, v_financial_cls
, length_of_stay
, Short_Stay_Indicator
, Long_Stay_Indicator
, Short_Stay_Appeal_Indicator
, Long_Stay_Appeal_Indicator
, visit_admit_diag
, admit_diag_Description
, admission_date
, discharged
, Dsch_Yr
, Dsch_Mo

/*
cerm_review_status
cerm_rvwr_id      
cerm_rvw_date     
cerm_case_notes
*/

, pyr_cd
, pyr_seq_no
, pyr_name

/*
UM_Review_Date  
UM_Review_Denial_Type   
UM_Days_Denied    
UM_Rvw_Dates_Denied      
UM_Denial_Date    
*/

, Appeal_Date
, YEAR(appeal_Date) AS [Appeal_Yr]
, Adm_Dx
, (
	SELECT SUM(tot_pay_Adj_Amt)
	FROM smsmir.mir_pay qq
	WHERE CAST(a.bill_no as int)=CAST(qq.pt_id as int) AND LEFT(qq.pay_Cd,4)='0974'
) AS [Denial_WOffs]



FROM smsdss.c_Softmed_Denials_Detail_v a 


WHERE discharged BETWEEN '01/01/2014' AND '08/31/2015' 

-- unused filters #####
--AND bill_no IN
--(SELECT CAST(pt_id as int)
--FROM smsmir.mir_dx_grp
--WHERE LEFT(dx_Cd_type,2)='DF' 
--AND dx_cd_prio = '01' 
--AND dx_cd IN ('786.50','756.59','496','491.21')
-- unused filters #####

GROUP BY visit_attend_phys,
Attend_Dr,
attend_dr_no,
Attend_Spclty,
bill_no,
last_name,
first_name,
rvw_date,
patient_type,
Initial_Denial,
appl_type,
appl_status,
Pending,
Finalized,
appl_dollars_appealed, [1st_Lvl_Appealed_Ind],
[2nd_Lvl_Appealed_Ind],
s_cpm_Dollars_not_appealed,
No_Appeal,
appl_dollars_recovered,
[1st_Lvl_Recovery],
DRA_Lvl_Recovery,
s_qm_subseq_appeal,
External_Appeal,
s_qm_subseq_appeal_date,
assoc_prvdr,
Denial_Dr,
Denial_Dr_No,
BMH_Specialty,
Denial_Spclty,
s_rvw_dnl_rsn,
v_financial_cls,
length_of_stay,
Short_Stay_Indicator,
Long_Stay_Indicator,
Short_Stay_Appeal_Indicator,
Long_Stay_Appeal_Indicator,
visit_admit_diag,
admit_diag_Description,
admission_date,
discharged,
Dsch_Yr,
Dsch_Mo,
--cerm_review_status    cerm_rvwr_id      cerm_rvw_date     cerm_case_notes
pyr_cd,
pyr_seq_no,
pyr_name,
--UM_Review_Date  UM_Review_Denial_Type   UM_Days_Denied    UM_Rvw_Dates_Denied      UM_Denial_Date    
Appeal_Date,
YEAR(Appeal_Date),
Adm_Dx
