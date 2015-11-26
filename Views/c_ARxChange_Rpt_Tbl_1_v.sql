USE [SMSPHDSSS0X0]
GO

/****** Object:  View [smsdss].[c_ARxChange_Rpt_Tbl_1_v]    Script Date: 11/23/2015 2:14:34 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER VIEW [smsdss].[c_ARxChange_Rpt_Tbl_1_v]

AS

-- service information --------------------------------------------
SELECT b.hosp_svc
, c.vst_type_cd
, c.prin_dx_cd
, b.fc
, ISNULL(LEFT(b.prim_pyr_cd, 1), 'P') AS prim_pyr_cd

-- patient information --------------------------------------------
, b.pt_id
, '' Patient_Alternate_ID
, LTRIM(RTRIM(c.vst_med_rec_no)) AS med_rec_no
, g.pt_last
, g.pt_first
, g.pt_middle
, '' AS patient_suffix
, g.Pt_Social
, CONVERT(varchar(10), g.pt_dob, 101) AS pt_dob
, c.gender_cd
, g.addr_line1
, g.Pt_Addr_Line2
, g.Pt_Addr_City
, g.Pt_Addr_State
, g.Pt_Addr_Zip
, g.Pt_Phone_No
, h.Pt_Emp_Phone_No
, h.Pt_Employer
, h.Pt_Emp_Addr1 + h.Pt_Emp_Addr2 AS emp_address
, h.Pt_Emp_Addr_City
, h.Pt_Emp_Addr_State
, h.Pt_Emp_Addr_Zip
, '' AS annual_income
, nn.UserDataText                 AS [Patient_Email]
	
-- co-signor (guarantor information) ------------------------------
, j.GuarantorSocial
, j.GuarantorDOB
, '' AS GuarantorGender
, j.GuarantorLast
, j.GuarantorFirst
, '' AS guarantormiddle
, '' AS guarantorsuffix
, j.GuarantorAddress
, j.GuarantoAddress2
, j.GurantorCity
, j.GuarantorState
, j.GuarantorZip
, j.GuarantorPhone 
, '' AS GuarantorCellPhone
, k.GuarantorWorkPhone
, k.GuarantorEmployer
, k.GuarantorEmployer_Address
, k.GurantorEmployer_City
, k.GuarantorEmployer_State
, k.GuarantorEmployer_Zip
, '' AS guarantoremailaddress
, '' AS guarantor_relation
, '' AS guarantormaritalstatus
, '' AS guarantorhouseholdsize
	
-- billing info ---------------------------------------------------
, b.tot_bal_amt
, b.tot_chg_amt
, c.vst_start_dtime
, c.vst_end_dtime
, c.len_of_stay
, CONVERT(varchar(10),e.Last_Pt_Pymt,101) AS Last_Pt_Pymt
, p.Tot_Pt_Pymts                          AS Last_Payment_Amount
, m.tot_pymts_w_pip                       AS Total_Payments
, (b.tot_chg_amt +
	m.tot_pymts_w_pip -
	b.tot_bal_amt)                         AS Total_Adjustments
, rn = ROW_NUMBER() over(partition by e.pt_id order by e.last_pt_pymt desc)

FROM smsmir.mir_acct                            AS b
LEFT JOIN smsmir.mir_vst						AS c
ON b.pt_id = c.pt_id 
AND b.pt_id_start_dtime = c.pt_id_start_dtime 
AND b.unit_seq_no = c.unit_Seq_no
LEFT JOIN smsdss.c_Last_Pt_Pymt_v				AS e
ON b.pt_id = e.pt_id
	AND b.unit_seq_no = e.unit_seq_no
	AND c.unit_seq_no = e.unit_seq_no
LEFT JOIN smsdss.c_patient_demos_v				AS g
ON b.pt_id = g.pt_id 
	AND b.pt_id_start_dtime = g.pt_id_Start_Dtime
LEFT JOIN smsdss.c_patient_employer_demos_v		AS h
ON b.pt_id = h.pt_id 
	AND b.pt_id_start_dtime = h.pt_id_Start_dtime
LEFT JOIN smsdss.c_guarantor_demos_v			AS j
ON b.pt_id = j.pt_id 
	AND b.pt_id_start_dtime = j.pt_id_Start_Dtime 
LEFT JOIN smsdss.c_guarantor_employer_demos_v	AS k
ON b.pt_id = k.pt_id 
	AND b.pt_id_start_dtime = k.pt_id_Start_Dtime
LEFT JOIN smsdss.c_tot_pymts_w_pip_v			AS m
ON b.pt_id = m.pt_id 
	AND b.pt_id_start_dtime = m.pt_id_Start_Dtime
	AND b.pt_id_start_dtime = m.pt_id_Start_Dtime
LEFT JOIN smsdss.BMH_UserTwoFact_V				AS nn
ON b.pt_id = nn.ptno_num 
	AND nn.userdatakey = '631'
LEFT JOIN smsdss.c_pt_payments_v				AS p
ON b.pt_id = p.pt_id 
	AND b.unit_seq_no = p.unit_seq_no 
	AND p.pymt_rank = '1'

WHERE b.from_file_ind IN ('4a','4h','6a','6h')
AND b.bd_wo_dtime > '12/31/2014'
AND b.tot_bal_amt > 0
AND b.resp_cd IS NULL
AND b.unit_seq_no IN (0, -1)
AND b.pt_type NOT IN ('R', 'K')

GO


