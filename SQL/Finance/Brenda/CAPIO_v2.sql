-- COLUMNS
SELECT VST_RPT.pt_id                                          AS [Account_Number]
, VST_RPT.unit_seq_no                                         AS [Unit_Seq_No]
--, VST_RPT.from_file_ind                                       AS [From_File_Ind]
, LTRIM(RTRIM(VST_RPT.vst_med_rec_no))                        AS [Medical_Record_Number]
, CONVERT(VARCHAR, VST_RPT.adm_date, 101)                     AS [Admit_Date/Date_of_Service]
, CONVERT(VARCHAR, VST_RPT.adm_date, 101)                     AS [Registration_Date]
, CONVERT(VARCHAR, VST_RPT.dsch_date, 101)                    AS [Discharge_Date]
, CONVERT(VARCHAR, VST_RPT.bd_wo_date, 101)                   AS [Charge_Off_Date]
, CONVERT(VARCHAR, L_PT_PAY.Last_Pt_Pymt, 101)                AS [Last_Pt_Pay_Date]
, ISNULL(LEFT(VST_RPT.prim_pyr_cd, 1), '')                    AS [Financial_Class]
, Financial_Class_Description = (
	SELECT CASE
		WHEN LTRIM(RTRIM(LEFT(VST_RPT.prim_pyr_cd, 1))) = 'A' THEN 'Medicare'
		WHEN LTRIM(RTRIM(LEFT(VST_RPT.prim_pyr_cd, 1))) = 'B' THEN 'Blue Cross' 
		WHEN LTRIM(RTRIM(LEFT(VST_RPT.prim_pyr_cd, 1))) = 'C' THEN 'Workers Comp'
		WHEN LTRIM(RTRIM(LEFT(VST_RPT.prim_pyr_cd, 1))) = 'D' THEN 'DDD'
		WHEN LTRIM(RTRIM(LEFT(VST_RPT.prim_pyr_cd, 1))) = 'E' THEN 'Medicare Mgd'
		WHEN LTRIM(RTRIM(LEFT(VST_RPT.prim_pyr_cd, 1))) = 'I' THEN 'Medicaid Mgd'
		WHEN LTRIM(RTRIM(LEFT(VST_RPT.prim_pyr_cd, 1))) = 'K' THEN 'HMO'
		WHEN LTRIM(RTRIM(LEFT(VST_RPT.prim_pyr_cd, 1))) = 'M' THEN 'Blue Cross'
		WHEN LTRIM(RTRIM(LEFT(VST_RPT.prim_pyr_cd, 1))) = 'N' THEN 'No Fault'
		WHEN LTRIM(RTRIM(LEFT(VST_RPT.prim_pyr_cd, 1))) = 'P' THEN 'PPP'
		WHEN LTRIM(RTRIM(LEFT(VST_RPT.prim_pyr_cd, 1))) = 'S' THEN 'Blue Cross'
		WHEN LTRIM(RTRIM(LEFT(VST_RPT.prim_pyr_cd, 1))) = 'W' THEN 'Medicaid'
		WHEN LTRIM(RTRIM(LEFT(VST_RPT.prim_pyr_cd, 1))) = 'X' THEN 'Commercial'
		WHEN LTRIM(RTRIM(LEFT(VST_RPT.prim_pyr_cd, 1))) = 'Z' THEN 'Medicare'
		WHEN VST_RPT.prim_pyr_cd IS NULL THEN 'Self Pay'
		ELSE ''
	END 
)
, DATEDIFF(MONTH, VST_RPT.vst_start_date, GETDATE())          AS [Acct_Age]
, DATEDIFF(MONTH, VST_RPT.vst_end_date, VST_RPT.bd_wo_date)   AS [Age_From_Dsch_When_Xfrd_to_BD]
, DATEDIFF(MONTH, VST_RPT.bd_wo_date, MJRF.End_Collect_Dtime) AS [Time_In_BD]
, DATEDIFF(MONTH, VST_RPT.vst_end_date, VST_RPT.bd_wo_date) +
  DATEDIFF(MONTH, VST_RPT.bd_wo_date, MJRF.End_Collect_Dtime) AS [Age_When_Collect_Exhaust]
, '111704595'                                                 AS [Facility_Tax_ID_No]
, ''                                                          AS [Occurance_Code]
, 'Brookhaven Memorial Hospital'                              AS [Facility_Name]
, VST_RPT.rpt_name                                            AS [Patient_Name]
, PTACCTV.Pt_SSA_No                                           AS [Patient_Social_Security_Number]
, CONVERT(VARCHAR, PTACCTV.Pt_Birthdate, 101)                 AS [Patient_Date_of_Birth]
, VST_RPT.gender_cd                                           AS [Patient_Gender]
, MARITAL_STS.marital_sts_desc                                AS [Patient_Marital_Status]
, pt_addr_line1                                               AS [Patient_Address_Line_One]
, ''                                                          AS [Patient_Address_Line_Two]
, pt_addr_line2                                               AS [Patient_City]
, pt_addr_line3                                               AS [Patient_State]
, PTACCTV.Pt_Zip_Cd                                           AS [Patient_Zip]
, ''                                                          AS [Patient_Mail_Return_Flag]
, VST_RPT.pt_rpt_phone_no                                     AS [Patient_Home_Phone]
, SUBSTRING(XXX.phone_no, 1, 3) + '-' +
  SUBSTRING(XXX.PHONE_NO, 4, 3) + '-' +
  SUBSTRING(XXX.PHONE_NO, 7, 4)                               AS [Patient_Employer_Phone]
, ''                                                          AS [Patient_Cell_Phone]
, VST_RPT.pt_empl_name                                        AS [Patient_Employer_Name]
, SUBSTRING(XXX.phone_no, 1, 3) + '-' +
  SUBSTRING(XXX.PHONE_NO, 4, 3) + '-' +
  SUBSTRING(XXX.PHONE_NO, 7, 4)                               AS [Patient_Work_Employer_Phone]
, XXX.addr_line1                                              AS [Patient_Employer_Address_Line_One]
, ''                                                          AS [Patient_Employer_Address_Line_Two]
, XXX.addr_line2                                              AS [Patient_Employer_City]
, XXX.addr_line3                                              AS [Patient_Employer_State]
, XXX.postal_cd                                               AS [Patient_Employer_Zip]
, vst_rpt.guar_last_name + ' ,' + VST_RPT.guar_first_name     AS [Guarantor_Name]
, ''                                                          AS [Guarantor_Relationship_To_Patient]
, YYY.nhs_id_no                                               AS [Guarantor_Social_Security_Number]
, CONVERT(VARCHAR, YYY.guar_birth_dtime, 101)                 AS [Guarantor_Date_Of_Birth]
, ''                                                          AS [Guarantor_Gender]
, ''                                                          AS [Guarantor_Marital_Status]
, YYY.addr_line1                                              AS [Guarantor_Address_Line_One]
, ''                                                          AS [Guarantor_Address_Line_Two]
, YYY.addr_line2                                              AS [Guarantor_City]
, YYY.addr_line3                                              AS [Guarantor_State]
, YYY.postal_cd                                               AS [Guarantor_Zip]
, ''                                                          AS [Guarantor_Mail_Return_Flag]
, SUBSTRING(YYY.phone_no, 1, 3) + '-' +
  SUBSTRING(YYY.PHONE_NO, 4, 3) + '-' +
  SUBSTRING(YYY.PHONE_NO, 7, 4)                               AS [Guarantor_Home_Phone]
, SUBSTRING(WWW.phone_no, 1, 3) + '-' +
  SUBSTRING(WWW.PHONE_NO, 4, 3) + '-' +
  SUBSTRING(WWW.PHONE_NO, 7, 4)                               AS [Guarantor_Work_Phone]
, SUBSTRING(WWW.phone_no, 1, 3) + '-' +
  SUBSTRING(WWW.PHONE_NO, 4, 3) + '-' +
  SUBSTRING(WWW.PHONE_NO, 7, 4)                               AS [Guarantor_Wrk_Employer_Phone]
, ''                                                          AS [Guarantor_Cell_Phone]
, WWW.last_name                                               AS [Guarantor_Employer]
, SUBSTRING(WWW.phone_no, 1, 3) + '-' +
  SUBSTRING(WWW.PHONE_NO, 4, 3) + '-' +
  SUBSTRING(WWW.PHONE_NO, 7, 4)                               AS [Guarantor_Employer_Work_Phone]
, WWW.addr_line1                                              AS [Guarantor_Employer_Address_Line_One]
, ''                                                          AS [Guarantor_Employer_Address_Line_Two]
, WWW.addr_line2                                              AS [Guarantor_Employer_City]
, WWW.addr_line3                                              AS [Guarantor_Employer_State]
, WWW.postal_cd                                               AS [Guarantor_Employer_Zip]
, SUBSTRING(WWW.phone_no, 1, 3) + '-' +
  SUBSTRING(WWW.PHONE_NO, 4, 3) + '-' +
  SUBSTRING(WWW.PHONE_NO, 7, 4)                               AS [Guarantor_Employer_Phone]
, VST_RPT.tot_bal_amt                                         AS [Account_Balance]
, VST_RPT.tot_chg_amt                                         AS [Total_Charges]
, PMT_PIP.tot_pymts_w_pip                                     AS [Total_Payments]
, (
	VST_RPT.tot_chg_amt + 
	PMT_PIP.tot_pymts_w_pip - 
	VST_RPT.tot_bal_amt
)                                                             AS [Total_Adjustments]
, VST_RPT.ins_pay_amt                                         AS [Total_Insurance_Payment]
, (
	PMT_PIP.tot_pymts_w_pip -
	VST_RPT.ins_pay_amt
)                                                             AS [Tot_Pt_Pymts]
, PT_PMTS.Tot_Pt_Pymts                                        AS [Last_Patient_Payment]
, PYR_MSTR.pyr_name                                           AS [Primary_Insurance_Name]
, VST_RPT.ins1_pol_no                                         AS [Primary_Ins_ID_Number]
, VST_RPT.subscr_ins1_grp_id                                  AS [Primary_Insurance_Group_Number]
, ''                                                          AS [Primary_Insurance_IPLAN_No]
, INS_INFO.Ins_Name                                           AS [Ins1_Name]
, INS_INFO.Ins_Addr1                                          AS [Primary_Insurance_Address_Line_One]
, ''                                                          AS [Primary_Insurance_Address_Line_Two]
, INS_INFO.Ins_City                                           AS [Primary_Insurance_City]
, INS_INFO.Ins_State                                          AS [Primary_Insurance_State]
, INS_INFO.Ins_Zip                                            AS [Primary_Insurance_Zip]
, INS_INFO.Ins_Tel_No                                         AS [Primary_Insurance_Phone_Number]
, PTACCTV.Pyr2_Co_Plan_Cd
, PTACCTV.Pyr3_Co_Plan_Cd
, PTACCTV.Pyr4_Co_Plan_Cd
, VST_RPT.ins2_pol_no
, VST_RPT.ins3_pol_no
, VST_RPT.ins4_pol_no
, VST_RPT.subscr_ins2_grp_id
, VST_RPT.subscr_ins3_grp_id
, VST_RPT.subscr_ins4_grp_id
--, PTACCTV.Adm_Dr_No
, PRACT_MSTR_A.npi_no                                         AS [Admitting_Physician_NPI]
, PRACT_MSTR_A.pract_rpt_name                                 AS [Admitting_Physician_Name]
--, PTACCTV.Atn_Dr_No
, PRACT_MSTR_B.npi_no                                         AS [Attending_Physician_NPI]
, PRACT_MSTR_B.pract_rpt_name                                 AS [Attending_Physician_Name]
, CONVERT(VARCHAR, VST_RPT.bd_wo_date, 101)                   AS [Last_Agency_Placed_Date]
, CONVERT(VARCHAR, MJRF.End_Collect_Dtime, 101)               AS [Last_Agency_Returned_Date]
, VST_RPT.alt_bd_wo_amt                                       AS [Last_Agency_Placed_Amount]
, (VST_RPT.tot_bal_amt - VST_RPT.alt_bd_wo_amt)               AS [Last_Agency_Recovery_Amount]
, ''                                                          AS [Last_Agency_Adjustment_Amount]
, ''                                                          AS [Last_Agency_Recall_Amount]
, ''                                                          AS [Attorney_Name]
, ''                                                          AS [Attorney_Address_Line_1]
, ''                                                          AS [Attorney_Address_Line_2]
, ''                                                          AS [Attorney_City]
, ''                                                          AS [Attorney_State]
, ''                                                          AS [Attorney_Zip]
, ''                                                          AS [Attorney_Phone_Number]

INTO #TEMP_A

-- TABLES AND OR VIEWS
FROM smsmir.vst_rpt                    AS VST_RPT
LEFT JOIN smsdss.BMH_PLM_PtAcct_V      AS PTACCTV
ON VST_RPT.pt_id = PTACCTV.Pt_No
	AND VST_RPT.unit_seq_no = PTACCTV.unit_seq_no
LEFT JOIN smsdss.c_Last_Pt_Pymt_v      AS L_PT_PAY
ON VST_RPT.pt_id = L_PT_PAY.pt_id
	AND VST_RPT.unit_seq_no = L_PT_PAY.unit_seq_no
LEFT JOIN smsdss.c_MJRF_Closed_Accts_v AS MJRF
ON VST_RPT.pt_id = MJRF.acct_no
LEFT JOIN smsdss.marital_sts_mstr      AS MARITAL_STS
ON VST_RPT.marital_sts = MARITAL_STS.marital_sts 
	AND MARITAL_STS.src_sys_id='#PASS0X0'
-- patient information ---
LEFT JOIN smsmir.trn_pers_addr         AS ZZZ
ON VST_RPT.pt_id = ZZZ.PT_ID
	AND VST_RPT.from_file_ind = ZZZ.from_file_ind
	AND ZZZ.pers_type = 'PT'
-- patient employer informaiton ---
LEFT JOIN smsmir.trn_pers_addr         AS XXX
ON VST_RPT.pt_id = XXX.PT_ID
	AND VST_RPT.from_file_ind = XXX.from_file_ind
	AND XXX.pers_type = 'PE'
-- guarantor information --
LEFT JOIN smsmir.trn_pers_addr         AS YYY
ON VST_RPT.pt_id = YYY.pt_id
	AND VST_RPT.from_file_ind = YYY.from_file_ind
	AND YYY.pers_type = 'PG'
-- guarantor employer information --
LEFT JOIN smsmir.trn_pers_addr         AS WWW
ON VST_RPT.pt_id = WWW.pt_id
	AND VST_RPT.from_file_ind = WWW.from_file_ind
	AND WWW.pers_type = 'GE'
LEFT JOIN smsdss.c_tot_pymts_w_pip_v   AS PMT_PIP
ON VST_RPT.pt_id = PMT_PIP.pt_id 
	AND VST_RPT.unit_seq_no = PMT_PIP.unit_seq_no
LEFT JOIN smsdss.c_pt_payments_v       AS PT_PMTS
ON VST_RPT.pt_id = PT_PMTS.pt_id
	AND VST_RPT.unit_seq_no = PT_PMTS.unit_seq_no
	AND PT_PMTS.Pymt_Rank = '1'
LEFT JOIN smsmir.mir_pyr_mstr          AS PYR_MSTR
ON VST_RPT.prim_pyr_cd = PYR_MSTR.pyr_cd
LEFT JOIN smsdss.c_ins_user_fields_v   AS INS_INFO
ON VST_RPT.pt_id = INS_INFO.pt_id
	AND LTRIM(RTRIM(VST_RPT.prim_pyr_cd)) = LTRIM(RTRIM(INS_INFO.pyr_cd))
LEFT JOIN smsmir.mir_pract_mstr        AS PRACT_MSTR_A
ON PTACCTV.Adm_Dr_No = PRACT_MSTR_A.pract_no 
	AND PRACT_MSTR_A.iss_orgz_cd = 'S0X0'
LEFT JOIN smsmir.mir_pract_mstr        AS PRACT_MSTR_B
ON PTACCTV.Adm_Dr_No = PRACT_MSTR_B.pract_no 
	AND PRACT_MSTR_B.iss_orgz_cd = 'S0X0'

-- FILTERS
WHERE VST_RPT.from_file_ind IN (
	'4H', '6H'
)
AND VST_RPT.resp_cd IS NULL
AND VST_RPT.bd_wo_date > '2007-12-31'
AND VST_RPT.tot_bal_amt > 0
AND VST_RPT.pt_id IN (
	SELECT DISTINCT(acct_no)
	FROM smsmir.acct
	WHERE FROM_FILE_IND IN (
		'4H', '6H'
	)
)
-- TESTING --
--AND VST_RPT.pt_id = '000074001264'
--AND vst_rpt.unit_seq_no = '12103144'
-- END TESTING --

OPTION(FORCE ORDER);

-----

SELECT A.*
, INS_INFO.Ins_Name                  AS [Secondary_Insurance_Name]
, A.ins2_pol_no                      AS [Secondary_Insurance_ID_Number]
, A.subscr_ins2_grp_id               AS [Secondary_Insurance_Group_Number]
, ''                                 AS [Secondary_Insurance_IPlan_Number]
, INS_INFO.Ins_Addr1                 AS [Secondary_Insurance_Address_Line_One]
, ''                                 AS [Secondary_Insurance_Address_Line_Two]
, INS_INFO.Ins_City                  AS [Secondary_Insurance_City]
, INS_INFO.Ins_State                 AS [Secondary_Insurance_State]
, INS_INFO.Ins_Zip                   AS [Secondary_Insurance_Zip]
, INS_INFO.Ins_Tel_No                AS [Secondary_Insurance_Phone_Number]

INTO #TEMP_B

FROM #TEMP_A AS A
LEFT JOIN smsdss.c_ins_user_fields_v AS INS_INFO
ON A.Account_Number = INS_INFO.pt_id
	AND LTRIM(RTRIM(A.PYR2_CO_PLAN_CD)) = LTRIM(RTRIM(INS_INFO.pyr_cd))
;
-----

SELECT B.*
, INS_INFO.Ins_Name                  AS [Tertiary_Insurance_Name]
, B.ins3_pol_no                      AS [Tertiary_Insurance_ID_Number]
, B.subscr_ins3_grp_id               AS [Tertiary_Insurance_Group_Number]
, ''                                 AS [Tertiary_Insurance_IPlan_Number]
, INS_INFO.Ins_Addr1                 AS [Tertiary_Insurance_Address_Line_One]
, ''                                 AS [Tertiary_Insurance_Address_Line_Two]
, INS_INFO.Ins_City                  AS [Tertiary_Insurance_City]
, INS_INFO.Ins_State                 AS [Tertiary_Insurance_State]
, INS_INFO.Ins_Zip                   AS [Tertiary_Insurance_Zip]
, INS_INFO.Ins_Tel_No                AS [Tertiary_Insurance_Phone_Number]

INTO #TEMP_C

FROM #TEMP_B AS B
LEFT JOIN smsdss.c_ins_user_fields_v AS INS_INFO
ON B.Account_Number = INS_INFO.pt_id
	AND LTRIM(RTRIM(B.PYR3_CO_PLAN_CD)) = LTRIM(RTRIM(INS_INFO.PYR_CD))
;
-----

SELECT C.Account_Number
, C.Unit_Seq_No
, C.Medical_Record_Number
, C.[Admit_Date/Date_of_Service]
, C.Registration_Date
, C.Discharge_Date
, C.Charge_Off_Date
, C.Last_Pt_Pay_Date
, C.Financial_Class
, C.Financial_Class_Description
, C.Acct_Age
, C.Age_From_Dsch_When_Xfrd_to_BD
, C.Time_In_BD
, C.Age_When_Collect_Exhaust
, C.Facility_Name
, C.Occurance_Code
, C.Facility_Name
, C.Patient_Name
, C.Patient_Social_Security_Number
, C.Patient_Date_of_Birth
, C.Patient_Gender
, C.Patient_Marital_Status
, C.Patient_Address_Line_One
, C.Patient_Address_Line_Two
, C.Patient_City
, C.Patient_State
, C.Patient_Zip
, C.Patient_Mail_Return_Flag
, C.Patient_Home_Phone
, C.Patient_Employer_Phone
, C.Patient_Cell_Phone
, C.Patient_Employer_Name
, C.Patient_Work_Employer_Phone
, C.Patient_Employer_Address_Line_One
, C.Patient_Employer_Address_Line_Two
, C.Patient_Employer_City
, C.Patient_Employer_State
, C.Patient_Zip
, C.Guarantor_Name
, C.Guarantor_Relationship_To_Patient
, C.Guarantor_Social_Security_Number
, C.Guarantor_Date_Of_Birth
, C.Guarantor_Gender
, C.Guarantor_Marital_Status
, C.Guarantor_Address_Line_One
, C.Guarantor_Address_Line_Two
, C.Guarantor_City
, C.Guarantor_State
, C.Guarantor_Mail_Return_Flag
, C.Guarantor_Home_Phone
, C.Guarantor_Work_Phone
, C.Guarantor_Wrk_Employer_Phone
, C.Guarantor_Cell_Phone
, C.Guarantor_Employer
, C.Guarantor_Employer_Work_Phone
, C.Guarantor_Employer_Address_Line_One
, C.Guarantor_Employer_Address_Line_Two
, C.Guarantor_Employer_City
, C.Guarantor_Employer_State
, C.Guarantor_Employer_Zip
, C.Guarantor_Employer_Phone
, C.Account_Balance
, C.Total_Charges
, C.Total_Payments
, C.Total_Adjustments
, C.Total_Insurance_Payment
, C.Tot_Pt_Pymts
, C.Last_Patient_Payment
, C.Primary_Insurance_Name
, C.Primary_Ins_ID_Number
, C.Primary_Insurance_Group_Number
, C.Primary_Insurance_IPLAN_No
, C.Ins1_Name
, C.Primary_Insurance_Address_Line_One
, C.Primary_Insurance_Address_Line_Two
, C.Primary_Insurance_City
, C.Primary_Insurance_State
, C.Primary_Insurance_Zip
, C.Primary_Insurance_Phone_Number
, C.Secondary_Insurance_ID_Number
, C.Secondary_Insurance_Group_Number
, C.Secondary_Insurance_IPlan_Number
, C.Secondary_Insurance_Name
, C.Secondary_Insurance_Address_Line_One
, C.Secondary_Insurance_Address_Line_Two
, C.Secondary_Insurance_City
, C.Secondary_Insurance_State
, C.Secondary_Insurance_Zip
, C.Secondary_Insurance_Phone_Number
, C.Tertiary_Insurance_ID_Number
, C.Tertiary_Insurance_Group_Number
, C.Tertiary_Insurance_IPlan_Number
, C.Tertiary_Insurance_Name
, C.Tertiary_Insurance_Address_Line_One
, C.Tertiary_Insurance_Address_Line_Two
, C.Tertiary_Insurance_City
, C.Tertiary_Insurance_State
, C.Tertiary_Insurance_Phone_Number
, C.Admitting_Physician_NPI
, C.Admitting_Physician_Name
, C.Attending_Physician_NPI
, C.Attending_Physician_Name
, '' AS [Last_Agency_Name]
, C.Last_Agency_Placed_Date
, C.Last_Agency_Returned_Date
, C.Last_Agency_Placed_Amount
, C.Last_Agency_Recovery_Amount
, C.Last_Agency_Adjustment_Amount
, C.Last_Agency_Recall_Amount
, C.Attorney_Name
, C.Attorney_Address_Line_1
, C.Attorney_Address_Line_2
, C.Attorney_City
, C.Attorney_State
, C.Attorney_Zip
, C.Attorney_Phone_Number

FROM #TEMP_C AS C
;

-----
--DROP TABLE #TEMP_A, #TEMP_B, #TEMP_C