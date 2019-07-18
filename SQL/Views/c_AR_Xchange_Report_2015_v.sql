USE [SMSPHDSSS0X0]
GO

/****** Object:  View [smsdss].[c_AR_Xchange_Report_2015_V]    Script Date: 11/4/2015 12:48:20 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Script for SelectTopNRows command from SSMS  ******/
ALTER VIEW [smsdss].[c_AR_Xchange_Report_2015_V]

AS

SELECT
-- Service Information ------------------------------------------------
'Brookhaven Memorial Hospital'					AS [FacilityName]
, '631-654-7209'								AS [FacilityPhoneNumber] -- not needed
, CASE 
	WHEN c.vst_type_cd = 'I' 
		AND bb.Pt_Key IS NULL
	THEN 'ED'
	WHEN c.vst_type_cd = 'O' 
		AND c.pt_type = 'E' 
		AND bb.Pt_Key IS NULL
	THEN 'ED'
	-- trauma indicator
	WHEN bb.Pt_Key IS NOT NULL
	THEN 'TR'
	ELSE 'EA'
  End											AS [Elective_or_ED_Admissions_or_Trauma_Indicator] -- not needed
, b.hosp_svc									AS [HospitalServiceDepartment]
, aa.pract_rpt_name								AS [PhysicianName] -- not needed
, c.vst_type_cd									AS [Inpatient_Outpatient]
, c.prin_dx_cd                                  AS [Primary_Diagnostic_Code]
, dd.clasf_desc                                 AS [Primary_Diagnostic_Description]
, b.fc											AS [Current_Financial_Class]
-- try to get primary fin class
,ISNULL( LEFT(b.prim_pyr_cd, 1),'P')            AS [Primary_Financial_Class]

-- Patient Information ------------------------------------------------
, b.pt_id										AS [Account_Number]
, ''											AS [Patient_Alternate_ID] -- not needed
, LTRIM(RTRIM(c.vst_med_rec_no))				AS [PatientMedicalRecordNumber]
, g.pt_last										AS [Patient_Last_Name]
, g.pt_first									AS [Patient_First_Name]
, g.pt_middle									AS [Patient_Middle_Name_or_Initial] -- not needed
, ''											AS [Patient_Suffix] -- not needed
, g.pt_social									AS [Patient_SSN]
, CONVERT(varchar(10),g.pt_DOB,101)				AS [Patient_Date_Of_Birth]
, c.gender_cd                                   AS [Patient_Gender]
, g.addr_line1									AS [Patient_Address_Line_1]
, g.Pt_Addr_Line2								AS [Patient_Address_Line_2]
, g.Pt_Addr_City								AS [Patient_City]
, g.Pt_Addr_State								AS [Patient_State]
, g.Pt_Addr_Zip									AS [Patient_ZIP_Code]
, g.Pt_Phone_No									AS [Patient_Home_Phone]
, h.Pt_Emp_Phone_No								AS [Patient_Work_Phone] -- not needed
, h.Pt_Employer									AS [Patient_Employer_Name] -- not needed
, h.Pt_Emp_Addr1 + h.pt_emp_addr2				AS [Patient_Work_Address] -- not needed
, h.pt_emp_addr_city							AS [Patient_Employer_City] -- not needed
, h.pt_emp_addr_state							AS [Patient_Employer_State] -- not needed
, h.pt_emp_addr_zip								AS [Patient_Employer_Zip] -- not needed
, ''											AS [Patient_Annual_Income] -- not needed
, nn.UserDataText								AS [Patient_Email] -- not needed

-- Co-Signor (Guarantor Information) ----------------------------------
, j.GuarantorSocial
, j.GuarantorDOB
, ''											AS [GuarantorGender] -- not needed
, j.GuarantorLast
, j.GuarantorFirst
, ''											AS [GuarantorMiddle] -- not needed
, ''											AS [GuarantorSuffix] -- not needed
, j.GuarantorAddress							AS [GuarantorAddressLine1]
, j.GuarantoAddress2							AS [GuarantorAddressLine2]
, j.GurantorCity								AS [GuarantorCity]
, j.GuarantorState
, j.GuarantorZip
, j.GuarantorPhone								AS [GuarantorHomePhone]
, ''											AS [GuarantorCellPhone] -- not needed
, k.GuarantorWorkPhone -- not needed
, k.GuarantorEmployer							AS [GuarantorEmployer_Name] -- not needed
, k.GuarantorEmployer_Address -- not needed
, k.GurantorEmployer_City						AS [GuarantorEmployer_City] -- not needed
, k.GuarantorEmployer_State -- not needed
, k.GuarantorEmployer_Zip -- not needed
, ''											AS [GuarantorEmailAddress] -- not needed
, ''											AS [Guarantor_Relation] -- not needed
, ''											AS [GuarantorMaritalStatus] -- not needed
, ''											AS [GuarantorHouseholdSize] -- not needed

-- Insurance Information (for each insurance payor listed) ------------
, q.pyr_name									AS [INS1_Name]
, ''											AS [INS1_ProgramName] -- not needed
, CASE
	WHEN LEFT(r.pyr_Cd,1) NOT IN ('A','Z') 
	THEN r.grp_no
	ELSE ''
  END											AS [INS1_GROUPID] -- not needed
, r.pyr_cd										AS [INS1_PayerID] -- not needed
, ''                                            AS [INS1_SubscriberID] -- not needed
, ''                                            AS [INS1_Relation_Code] -- not needed
, CASE 
	WHEN LEFT(r.pyr_cd,1) IN ('A','Z') 
	THEN r.pol_no + ISNULL(LTRIM(RTRIM(r.grp_no)),'')
	WHEN r.pol_no IS NULL
	THEN r.subscr_ins_grp_id
	ELSE r.pol_no
  END											AS [INS1_PolicyNumber]
, ''                                            AS [INS1_StartDate] -- not needed
, ''                                            AS [INS1_EndDate] -- not needed
, s.Ins_tel_no									AS [INS1_PhoneNumber] -- not needed
, r.pyr_cd										AS [INS1_Plan_Code] -- not needed
, ''											AS [INS1_Plan_Type] -- not needed
, v.pyr_name									AS [INS2_Name]
, ''											AS [INS2_ProgramName] -- not needed
, CASE
	WHEN LEFT(w.pyr_cd,1) IN ('A','Z') 
	THEN ''
	ELSE w.grp_no
	END											AS [INS2_GroupID] -- not needed
, CASE 
	WHEN LEFT(w.pyr_cd,1) IN ('A','Z') 
	THEN w.pol_no + ISNULL(LTRIM(RTRIM(w.grp_no)),'')
	WHEN w.pol_no is null
	THEN w.subscr_ins_grp_id
	ELSE w.pol_no
	END											AS [INS2_PolicyNumber]
, w.pyr_cd										AS [INS2_PayerID] -- not needed
, ''											AS [INS2_SubscriberID] -- not needed
, ''											AS [INS2_Relation_Code] -- not needed
, ''											AS [INS2_StartDate] -- not needed
, ''											AS [INS2_EndDate] -- not needed
, t.Ins_tel_no									AS [INS2_PhoneNumber] -- not needed
, w.pyr_cd										AS [INS2_Plan_Code] -- not needed
, ''											AS [INS2_Plan_Type] -- not needed

-- Billing Information ------------------------------------------------
, CONVERT(varchar(10),c.vst_start_dtime,101)	AS [DateOfService]
, CONVERT(varchar(10),c.vst_Start_Dtime,101)	AS [DateOfAdmission]
, CONVERT(varchar(10),c.vst_Start_Dtime,101)	AS [DateOfTreatment] -- not needed
, CONVERT(varchar(10),c.vst_end_dtime,101)		AS [Discharge_Date]
, c.len_of_stay                                 AS [Length_of_Stay_in_days]
, ''                                            AS [Date_Billed] -- need this
, ''			                                AS [Amount_Charged]-- not needed
, ''                                            AS [Amount_Billed_to_Insurance]-- not needed
, b.tot_bal_amt									AS [Total_Amount_Due]
, ''                                            AS [Patient_Responsibility_Amount]-- not needed
, ''                                            AS [Patient_Amount_of_Payments_Received]-- not needed
, CONVERT(varchar(10),e.last_pt_pymt,101)       AS [Date_of_Last_Patient_Payment] -- not needed
, ''                                            AS [Total_Amount_Due_from_Patient]-- not needed
, ''                                            AS [Self_Pay_Adjustment_Amount]-- not needed
, ''                                            AS [Account_Status]-- not needed
, ''                                            AS [Status_Date]-- not needed
, ''                                            AS [AmountPrePaid]-- not needed
, ''                                            AS [TotalInterest]-- not needed
, ''                                            AS [TotalLateFees]-- not needed
, ''                                            AS [TotalInsurancePayments]-- not needed
, ''                                            AS [APR]-- not needed
, CONVERT(varchar(10),e.last_pt_pymt,101)		AS [LastPaymentDate] 
, p.tot_pt_pymts								AS [LastPaymentAmount] 
, ''                                            AS [Amount_Charge_Off] -- not needed
, ''                                            AS [Date_Account_Closed] -- not needed
, ''                                            AS [Charge_Off_Date] -- not needed
, ''                                            AS [Insurance_1_Amount_Billed] -- not needed
, ''                                            AS [Insurance_1_Date_Billed] -- not needed
, ''                                            AS [Insurance_1_Amount_of_Payments_Received] -- not needed
, ''                                            AS [Insurance_1_Date_of_Last_Payment_Received] -- not needed
, ''                                            AS [Insurance_1_Adjustment_Amount] -- not needed
, ''                                            AS [Insurance_1_Co-Pay_Amount] -- not needed
, ''                                            AS [Insurance_1_Co-Pay_Posted_Date] -- not needed
, ''                                            AS [Insurance_1_Deductible_Amount] -- not needed
, ''                                            AS [Insurance_1_Deductible_Posted_Date] -- not needed
, ''                                            AS [Insurance_1_Insurance_Status] -- not needed
, ''                                            AS [Insurance_1_Insurance_Denial_Code] -- not needed
, ''                                            AS [Insurance_1_Insurance_Denial_Posted_Date] -- not needed
, ''                                            AS [Insurance_2_Amount_Billed] -- not needed
, ''                                            AS [Insurance_2_Date_Billed] -- not needed
, ''                                            AS [Insurance_2_Amount_of_Payments_Received] -- not needed
, ''                                            AS [Insurance_2_Date_of_Last_Payment_Received] -- not needed
, ''                                            AS [Insurance_2_Adjustment_Amount] -- not needed
, ''                                            AS [Insurance_2_Co-Pay_Amount] -- not needed
, ''                                            AS [Insurance_2_Co-Pay_Posted_Date] -- not needed
, ''                                            AS [Insurance_2_Deductible_Amount] -- not needed
, ''                                            AS [Insurance_2_Deductible_Posted_Date] -- not needed
, ''                                            AS [Insurance_2_Insurance_Status] -- not needed
, ''                                            AS [Insurance_2_Insurance_Denial_Code] -- not needed
, ''                                            AS [Insurance_2_Insurance_Denial_Posted_Date] -- not needed

-- Total --------------------------------------------------------------
, b.tot_chg_amt									AS [Total_Charges] 
, m.tot_pymts_w_pip								AS [Total_Payments] 
, (b.tot_chg_amt + 
	m.tot_pymts_w_pip - 
	b.tot_bal_amt)								AS [Total_Adjustments] 
 
 -- Table selection ----------------------------------------------------     
FROM smsmir.mir_acct							AS b 
LEFT JOIN smsmir.mir_vst						AS c
ON b.pt_id = c.pt_id 
	AND b.pt_id_start_dtime = c.pt_id_start_dtime 
	AND b.unit_seq_no = c.unit_Seq_no
LEFT JOIN smsdss.c_Last_Pt_Pymt_v				AS e
ON b.pt_id = e.pt_id
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
LEFT JOIN smsdss.BMH_UserTwoFact_V				AS nn
ON b.pt_id = nn.ptno_num 
	AND nn.userdatakey = '631'
LEFT JOIN smsdss.c_pt_payments_v				AS p
ON b.pt_id = p.pt_id 
	AND b.unit_seq_no = p.unit_seq_no 
	AND p.pymt_rank = '1'
LEFT JOIN smsmir.mir_pyr_mstr					AS q
ON b.prim_pyr_cd = q.pyr_cd
LEFT JOIN smsmir.mir_pyr_plan					AS r
ON b.prim_pyr_cd = r.pyr_cd 
	AND b.pt_id = r.pt_id 
	AND b.pt_id_start_dtime = r.pt_id_start_dtime
LEFT JOIN smsdss.c_ins_user_fields_v			AS s
ON b.pt_id = s.pt_id
	AND b.prim_pyr_cd = s.pyr_cd
LEFT JOIN smsdss.c_ins_user_fields_v			AS t
ON b.pt_iD = t.pt_id
	AND b.pyr2_cd = t.pyr_cd
LEFT JOIN smsmir.mir_pyr_mstr					AS v
ON b.pyr2_cd = v.pyr_cd
LEFT JOIN smsmir.mir_pyr_plan					AS w
ON b.pyr2_cd = w.pyr_cd 
	AND b.pt_id = w.pt_id 
	AND b.pt_id_start_dtime = w.pt_id_start_dtime
	AND w.pyr_seq_no = 2
LEFT JOIN smsmir.mir_pract_mstr					AS aa
ON c.prim_pract_no = aa.pract_no 
	AND aa.iss_orgz_cd = 'S0X0'
-- add trauma indicator
LEFT JOIN smsdss.bmh_plm_ptacct_v			    AS cc
ON cc.Pt_No = b.pt_id
LEFT JOIN smsdss.BMH_ER_TraumaCase_Evaluator_V  AS bb
ON cc.Pt_Key = bb.Pt_Key
LEFT JOIN SMSDSS.dx_cd_dim_v                    AS dd
ON c.prin_dx_cd = dd.dx_cd
	AND c.prin_dx_cd_schm = dd.dx_cd_schm

-- Filters ------------------------------------------------------------
WHERE b.from_file_ind IN ('4H', '6H') 
AND b.resp_cd IS NULL 
AND b.bd_wo_dtime > '12/31/2014' 
AND b.tot_bal_amt > 0 
