/****** Script for SelectTopNRows command from SSMS  ******/
CREATE VIEW smsdss.c_Capio_Report_V
AS
SELECT b.pt_id AS 'Account_Number'
, LTRIM(RTRIM(c.vst_med_rec_no)) AS 'Medical_Record_Number'
, CONVERT(varchar(10),c.vst_start_dtime,101) AS 'Admit_Date/Date_Of_Service'
, CONVERT(varchar(10),c.vst_Start_Dtime,101) AS 'Registration_Date'
, CONVERT(varchar(10),c.vst_end_dtime,101) AS 'Discharge_Date'
, CONVERT(varchar(10),b.bd_wo_dtime,101) AS 'Charge_Off_Date'
, CONVERT(varchar(10),e.last_pt_pymt,101) AS 'Last_Pt_Pay_Date'
, ISNULL(LEFT(b.prim_pyr_cd,1),'') AS 'Financial_Class'
, Financial_Class_Description = (
	SELECT CASE
		WHEN LTRIM(RTRIM(LEFT(b.prim_pyr_cd,1))) = 'A' THEN 'Medicare'
		WHEN LTRIM(RTRIM(LEFT(b.prim_pyr_cd,1))) = 'B' THEN 'Blue Cross' 
		WHEN LTRIM(RTRIM(LEFT(b.prim_pyr_cd,1))) = 'C' THEN 'Workers Comp'
		WHEN LTRIM(RTRIM(LEFT(b.prim_pyr_cd,1))) = 'D' THEN 'DDD'
		WHEN LTRIM(RTRIM(LEFT(b.prim_pyr_cd,1))) = 'E' THEN 'Medicare Mgd'
		WHEN LTRIM(RTRIM(LEFT(b.prim_pyr_cd,1))) = 'I' THEN 'Medicaid Mgd'
		WHEN LTRIM(RTRIM(LEFT(b.prim_pyr_cd,1))) = 'K' THEN 'HMO'
		WHEN LTRIM(RTRIM(LEFT(b.prim_pyr_cd,1))) = 'M' THEN 'Blue Cross'
		WHEN LTRIM(RTRIM(LEFT(b.prim_pyr_cd,1))) = 'N' THEN 'No Fault'
		WHEN LTRIM(RTRIM(LEFT(b.prim_pyr_cd,1))) = 'P' THEN 'PPP'
		WHEN LTRIM(RTRIM(LEFT(b.prim_pyr_cd,1))) = 'S' THEN 'Blue Cross'
		WHEN LTRIM(RTRIM(LEFT(b.prim_pyr_cd,1))) = 'W' THEN 'Medicaid'
		WHEN LTRIM(RTRIM(LEFT(b.prim_pyr_cd,1))) = 'X' THEN 'Commercial'
		WHEN LTRIM(RTRIM(LEFT(b.prim_pyr_cd,1))) = 'Z' THEN 'Medicare'
		WHEN b.prim_pyr_cd IS NULL THEN 'Self Pay'
		ELSE ''
	END 
)
--, b.from_file_ind
--, b.resp_cd
--, b.tot_Bal_amt
--, CONVERT(varchar(10),n.userdatatext) AS 'Reg_Date'
, DATEDIFF(m,c.vst_end_dtime,GETDATE()) AS 'Acct_Age'
, DATEDIFF(m,c.vst_end_dtime,b.bd_wo_dtime) AS 'Age From Dsch When Xfrd to BD'
, DATEDIFF(m,b.bd_wo_dtime,d.End_Collect_Dtime) AS 'Time In BD'
, DATEDIFF(m,c.vst_end_dtime,b.bd_wo_dtime) + DATEDIFF(m,b.bd_wo_dtime,d.End_Collect_Dtime) AS 'Age When Collect Exhaust'
--, b.prim_pyr_cd
, '111704595' AS 'Facility_Tax_ID_No'
, '' AS 'Occurrence_Code'
, 'Brookhaven Memorial Hospital' AS 'Facility_Name'
, '' AS 'Facility_Description'
, g.rpt_name AS 'Patient_Name'
, g.Pt_Social AS 'Patient_Social_Security_Number'
, CONVERT(varchar(10),g.pt_DOB,101) AS 'Patient_Date_Of_Birth'
, g.gender_cd AS 'Patient_Gender'
, g.marital_sts_desc AS 'Patient_Marital_Status'
, g.addr_line1 AS 'Patient_Address_Line_One'
, g.Pt_Addr_Line2 AS 'Patient_Address_Line_Two'
, g.Pt_Addr_City AS 'Patient_City'
, g.Pt_Addr_State AS 'Patient_State'
, g.Pt_Addr_Zip AS 'Patient_Zip'
, '' AS 'Patient_Mail_Return_Flag'
, g.Pt_Phone_No AS 'Patient_Home_Phone'
, h.Pt_Emp_Phone_No AS 'Patient_Work_Phone'
, '' AS 'Patient_Cell_Phone'
, h.Pt_Employer AS 'Patient_Employer_Name'
, h.Pt_Emp_Phone_No AS 'Patient_Work_Employer_Phone'
, h.Pt_Emp_Addr1 AS 'Patient_Employer_Address_Line_One'
, h.Pt_Emp_Addr2 AS 'Patient_Employer_Address_Line_Two'
, h.Pt_Emp_Addr_City AS 'Patient_Employer_City'
, h.Pt_Emp_Addr_State AS 'Patient_Employer_State'
, h.Pt_Emp_Addr_Zip AS 'Patient_Employer_Zip'
, h.Pt_Emp_Phone_No AS 'Patient_Employer_Phone'
, (j.GuarantorLast + ' ,'+j.Guarantorfirst) AS 'Guarantor_Name'
, '' AS 'Guarantor_Relationship_To_Patient'
, j.guarantorsocial AS 'Guarantor_Social_Security_Number'
, j.GuarantorDOB AS 'Guarantor_Date_Of_Birth'
, '' AS 'Guarantor_Gender'
, '' AS 'Guaarantor_Marital_Status'
, j.GuarantorAddress AS 'Guarantor_Address_Line_One'
, j.guarantoaddress2 AS 'Guarantor_Address_Line_Two'
, j.gurantorcity AS 'Guarantor_City'
, j.GuarantorState AS 'Guarantor_State'
, j.GuarantorZip AS 'Guarantor_Zip'
, '' AS 'Guarantor_Mail_Return_Flag'
, j.GuarantorPhone AS 'Guarantor_Home_Phone'
, k.GuarantorWorkPhone AS 'Guarantor_Work_Phone'
, k.guarantorworkphone AS 'Guarantor_Wrk_Employer_Phone'
, '' AS 'Guarantor_Cell_Phone'
, k.GuarantorEmployer AS 'Guarantor_Employer'
, k.GuarantorWorkPhone AS 'Guarantor_Employer_Work_Phone'
, k.GuarantorEmployer_Address AS 'Guarantor_Employer_Address_Line_One'
, '' AS 'Guarantor_Employer_Address_Line_Two'
, k.gurantoremployer_city AS 'Guarantor_Employer_City'
, k.GuarantorEmployer_State AS 'Guarantor_Employer_State'
, k.GuarantorEmployer_Zip AS 'Guarantor_Employer_Zip'
, k.GuarantorWorkPhone AS 'Guarantor_Employer_Phone'
, b.tot_bal_amt AS 'Account_Balance'
, b.tot_chg_amt AS 'Total_Charges'
, m.tot_pymts_w_pip AS 'Total_Payments'
, (b.tot_chg_amt + m.tot_pymts_w_pip-b.tot_bal_amt) AS 'Total_Adjustments'
, b.ins_pay_amt AS 'Total_Insurance_Payment'
, m.tot_pymts_w_pip - b.ins_pay_amt AS 'Tot_Pt_Pymts'
, p.tot_pt_pymts AS 'Last_Patient_Payment'
, q.pyr_name AS 'Primary_Insurance_Name'
, CASE 
	WHEN LEFT(r.pyr_cd,1) IN ('A','Z') 
		THEN r.pol_no + ISNULL(LTRIM(RTRIM(r.grp_no)),'')
		ELSE r.pol_no
  END AS 'Primary_Ins_ID_Number'
, CASE
	WHEN LEFT(r.pyr_Cd,1) NOT IN ('A','Z') 
		THEN r.grp_no
		ELSE ''
  END AS 'Primary_Insurance_Group_Number' 
, '' AS 'Primary_Insurance_IPLAN_No'
, s.Ins_Name AS 'Ins1_Name'
, s.Ins_Addr1 AS 'Primary_Insurance_Address_Line_One'
, '' AS 'Primary_Insurance_Address_Line_Two'
, s.Ins_City AS 'Primary_Insurance_City'
, s.Ins_State AS 'Primary_Insurance_State'
, s.Ins_Zip AS 'Primary_Insurance_Zip'
, s.Ins_tel_no AS 'Primary_Insurance_Phone_Number'
, v.pyr_name AS 'Secondary_Insurance_Name'
, CASE 
	WHEN LEFT(w.pyr_cd,1) IN ('A','Z') 
		THEN w.pol_no + ISNULL(LTRIM(RTRIM(w.grp_no)),'')
		ELSE w.pol_no
  END AS 'Secondary_Insurance_ID_Number'
, CASE
	WHEN LEFT(w.pyr_cd,1) IN ('A','Z') 
		THEN ''
		ELSE w.grp_no
  END AS 'Seconary_Insurance_Group_Number'
, '' AS 'Secondary_Insurance_IPlan_Number'
, t.Ins_Name AS 'Ins2_Name'
, t.Ins_Addr1 AS 'Secondary_Insurance_Address_Line_One'
, '' AS 'Secondary_Insurance_Address_Line_Two'
, t.Ins_City AS 'Secondary_Insurance_City'
, t.Ins_State AS 'Secondary_Insurance_State'
, t.Ins_Zip AS 'Secondary_Insurance_Zip'
, t.Ins_tel_no AS 'Secondary_Insurance_Phone_Number'
, x.pyr_name AS 'Tertiary_Insurance_Name'
, CASE 
	WHEN LEFT(y.pyr_cd,1) IN ('A','Z') 
		THEN y.pol_no + ISNULL(LTRIM(RTRIM(y.grp_no)),'')
		ELSE y.pol_no
  END AS 'Tertiary_Insurance_ID_Number'
, CASE
	WHEN LEFT(y.pyr_Cd,1) NOT IN ('A','Z') 
		THEN y.grp_no
		ELSE ''
  END AS 'Tertiary_Insurance_Group_Number'
, u.Ins_Name AS 'Ins3_Name'
, '' AS 'Tertiary_Insurance_IPLAN_Number'
, u.Ins_Addr1 AS 'Tertiary_Insurance_Address_Line_One'
, '' AS 'Tertiary_Insurance_Address_Line_Two'
, u.Ins_City AS 'Tertiary_Insurance_City'
, u.Ins_State AS 'Tertiary_Insurance_State'
, u.Ins_Zip AS 'Tertiary_Insurance_Zip'
, u.Ins_tel_no AS 'Tertiary_Insurance_Phone_Number'
, --c.adm_pract_no AS 'Admitting_Phys_No'
, z.npi_no 'Admitting_Phys_NPI'
, z.pract_rpt_name AS 'Admitting_Dr_Name'
, aa.npi_no AS 'Attending_Phys_NPI'
, --c.prim_pract_no AS 'Attending_Phys_No'
, aa.pract_rpt_name AS 'Attend_Dr_Name'
, '' AS 'Last_Agency_Name'
, CONVERT(varchar(10),b.bd_wo_dtime, 101) AS 'Last_Agency_Placed_Date'
, CONVERT(varchar(10),d.end_collect_dtime,101) AS 'Last_Agency_Returned_Date'
,  b.bd_wo_amt AS 'Last_Agency_Placed_Amount'
,  b.tot_bal_amt - b.bd_wo_amt AS 'Last_Agency_Recovery_Amt'
, '' AS 'Last_Agency_Adjustment_Amount'
, '' AS 'Last_Agency_Recall_Amount'
, '' AS 'Attorney_Name'
, '' AS 'Attorney_Address_Line_1'
, '' AS 'Attorney_Address_Line_2'
, '' AS 'Attorney_City'
, '' AS 'Attorney_State'
, '' AS 'Attorney_Zip'
, '' AS 'Attorney_Phone_Number'

FROM smsmir.mir_acct AS b 
LEFT JOIN smsmir.mir_vst AS c
ON b.pt_id = c.pt_id 
	AND b.pt_id_start_dtime = c.pt_id_start_dtime 
	AND b.unit_seq_no = c.unit_Seq_no
LEFT JOIN smsdss.c_MJRF_Closed_Accts_v AS d
ON b.pt_id = d.acct_no
LEFT JOIN smsdss.c_Last_Pt_Pymt_v AS e
ON b.pt_id = e.pt_id
LEFT JOIN smsdss.fc_dim AS f
ON b.orig_fc = f.fc 
	AND f.src_sys_id = '#PASS0X0'
LEFT JOIN smsdss.c_patient_demos_v AS g
ON b.pt_id = g.pt_id 
	AND b.pt_id_start_dtime = g.pt_id_Start_Dtime
LEFT JOIN smsdss.c_patient_employer_demos_v AS h
ON b.pt_id = h.pt_id 
	AND b.pt_id_start_dtime = h.pt_id_Start_dtime
LEFT JOIN smsdss.c_guarantor_demos_v AS j
ON b.pt_id = j.pt_id 
	AND b.pt_id_start_dtime = j.pt_id_Start_Dtime 
LEFT JOIN smsdss.c_guarantor_employer_demos_v AS k
ON b.pt_id = k.pt_id 
	AND b.pt_id_start_dtime = k.pt_id_Start_Dtime
LEFT JOIN smsdss.c_tot_pymts_w_pip_v AS m
ON b.pt_id = m.pt_id 
	AND b.pt_id_start_dtime = m.pt_id_Start_Dtime
LEFT JOIN smsdss.BMH_UserTwoFact_V AS n
ON b.pt_id = n.ptno_num 
	AND n.userdatakey = '456'
LEFT JOIN smsdss.c_pt_payments_v AS p
ON b.pt_id = p.pt_id 
	AND b.unit_seq_no = p.unit_seq_no 
	AND p.pymt_rank='1'
LEFT JOIN smsmir.mir_pyr_mstr AS q
ON b.prim_pyr_cd = q.pyr_cd
LEFT JOIN smsmir.mir_pyr_plan AS r
ON b.prim_pyr_cd = r.pyr_cd 
	AND b.pt_id = r.pt_id 
	AND b.pt_id_start_dtime = r.pt_id_start_dtime
LEFT JOIN smsdss.c_ins_user_fields_v AS s
ON CAST(b.pt_id AS int) = CAST(s.pt_id AS int) 
	AND LTRIM(RTRIM(b.prim_pyr_cd)) = LTRIM(RTRIM(s.pyr_cd))
LEFT JOIN smsdss.c_ins_user_fields_v AS t
ON CAST(b.pt_id AS int) = CAST(t.pt_id AS int)
	AND LTRIM(RTRIM(b.pyr2_cd)) = LTRIM(RTRIM(t.pyr_cd))
LEFT JOIN smsdss.c_ins_user_fields_v AS u
ON CAST(b.pt_id AS int) = CAST(u.pt_id AS int) 
	AND LTRIM(RTRIM(b.pyr3_cd)) = LTRIM(RTRIM(u.pyr_cd))
LEFT JOIN smsmir.mir_pyr_mstr AS v
ON b.pyr2_cd = v.pyr_cd
LEFT JOIN smsmir.mir_pyr_plan AS w
ON b.pyr2_cd = w.pyr_cd 
	AND b.pt_id = w.pt_id 
	AND b.pt_id_start_dtime = w.pt_id_start_dtime
LEFT JOIN smsmir.mir_pyr_mstr AS x
ON b.pyr3_cd = x.pyr_cd
LEFT JOIN smsmir.mir_pyr_plan AS y
ON b.pyr3_cd = y.pyr_cd 
	AND b.pt_id = y.pt_id 
	AND b.pt_id_start_dtime = y.pt_id_start_dtime
LEFT JOIN smsmir.mir_pract_mstr AS z
ON c.adm_pract_no = z.pract_no 
	AND z.iss_orgz_cd = 'S0X0'
LEFT JOIN smsmir.mir_pract_mstr AS aa
ON c.prim_pract_no = aa.pract_no 
	AND aa.iss_orgz_cd = 'S0X0'
  
WHERE b.from_file_ind IN ('4H','6H') 
AND b.resp_cd IS NULL 
AND b.bd_wo_dtime > '12/31/2007' 
AND b.tot_bal_amt > 0 
AND b.pt_id IN (
  SELECT DISTINCT(acct_no)
  FROM smsmir.mir_acct
  WHERE from_file_ind IN ('4H','6H')
)
