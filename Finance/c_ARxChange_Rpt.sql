-- populate first TABLE

DECLARE @tmptblarx1 TABLE (
	PK INT IDENTITY(1, 1)            PRIMARY KEY
    , HospitalServiceDepartment      VARCHAR(MAX)
	, Inpatient_Outpatient           VARCHAR(MAX)
	, Primary_Diagnostic_Code        VARCHAR(MAX)
	, Current_Financial_Class        VARCHAR(MAX)
	, Primary_Financial_Class        VARCHAR(MAX)
	, Account_Number                 VARCHAR(MAX)
	, Patient_Alternate_ID           VARCHAR(MAX)
	, PatientMedicalRecordNumber     VARCHAR(MAX)
	, Patient_Last_Name              VARCHAR(MAX)
	, Patient_First_Name             VARCHAR(MAX)
	, Patient_Middle_Name_or_Initial VARCHAR(MAX)
	, Patient_Suffix                 VARCHAR(MAX)
	, Patient_SSN                    VARCHAR(MAX)
	, Patient_Date_Of_Birth          VARCHAR(MAX)
	, Patient_Gender                 VARCHAR(MAX)
	, Patient_Address_Line_1         VARCHAR(MAX)
	, Patient_Address_Line_2         VARCHAR(MAX)
	, Patient_City                   VARCHAR(MAX)
	, Patient_State                  VARCHAR(MAX)
	, Patient_Zip_Code               VARCHAR(MAX)
	, Patient_Home_Phone             VARCHAR(MAX)
	, Patient_Work_Phone             VARCHAR(MAX)
	, Patient_Employer_Name          VARCHAR(MAX)
	, Patient_Work_Address           VARCHAR(MAX)
	, Patient_Employer_City          VARCHAR(MAX)
	, Patient_Employer_State         VARCHAR(MAX)
	, Patient_Employer_Zip           VARCHAR(MAX)
	, Patient_Annual_Income          VARCHAR(MAX)
	, Patient_Email                  VARCHAR(MAX)
	, GuarantorSocial                VARCHAR(MAX)
	, GuarantorDOB                   VARCHAR(MAX)
	, GuarantorGender                VARCHAR(MAX)
	, GuarantorLast                  VARCHAR(MAX)
	, GuarantorFirst                 VARCHAR(MAX)
	, GuarantorMiddle                VARCHAR(MAX)
	, GuarantorSuffix                VARCHAR(MAX)
	, GuarantorAddressLine1          VARCHAR(MAX)
	, GuarantorAddressLine2          VARCHAR(MAX)
	, GuarantorCity                  VARCHAR(MAX)
	, GuarantorState                 VARCHAR(MAX)
	, GuarantorZip                   VARCHAR(MAX)
	, GuarantorPhone                 VARCHAR(MAX)
	, GuarantorCellPhone             VARCHAR(MAX)
	, GuarantorWorkPhone             VARCHAR(MAX)
	, GuarantorEmployer_Name         VARCHAR(MAX)
	, GuarantorEmployer_Address      VARCHAR(MAX)
	, GuarantorEmployer_City         VARCHAR(MAX)
	, GuarantorEmployer_State        VARCHAR(MAX)
	, GuarantorEmployer_Zip          VARCHAR(MAX)
	, GuarantorEmailAddress          VARCHAR(MAX)
	, Guarantor_Relation             VARCHAR(MAX)
	, GuarantorMaritalStatus         VARCHAR(MAX)
	, GuarantorHouseholdSize         VARCHAR(MAX)
	, tot_bal_amt                    VARCHAR(MAX)
	, tot_chg_amt                    VARCHAR(MAX)
	, vst_start_dtime                DATETIME
	, vst_end_dtime                  DATETIME
	, len_of_stay                    VARCHAR(MAX)
	, Last_Pt_Pymt                   VARCHAR(MAX)
	, Last_Pymt_Amount               VARCHAR(MAX)
	, Total_Payments                 VARCHAR(MAX)
	, Total_Adjustments              VARCHAr(MAX)
	, rn                             VARCHAR(MAX)
)

INSERT INTO @tmptblarx1
SELECT a.*
FROM (
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
) a

-- populate second TABLE
DECLARE @tmptblarx2 TABLE (
	pk INT IDENTITY(1, 1) PRIMARY KEY
	, ptnumber            VARCHAR(MAX)
	, INS1_Name           VARCHAR(MAX)
	, INS1_ProgramName    VARCHAR(MAX)
	, INS1_GROUPID        VARCHAR(MAX)
	, INS1_PayerID        VARCHAR(MAX)
	, INS1_SubscriberID   VARCHAR(MAX)
	, INS1_Relation_Code  VARCHAR(MAX)
	, INS1_PolicyNumber   VARCHAR(MAX)
	, INS1_StartDate      VARCHAR(MAX)
	, INS1_EndDate        VARCHAR(MAX)
	, INS1_PhoneNumber    VARCHAR(MAX)
	, INS1_Plan_Code      VARCHAR(MAX)
	, INS1_Plan_Type      VARCHAR(MAX)
	, INS2_Name           VARCHAR(MAX)
	, INS2_ProgamName     VARCHAR(MAX)
	, INS2_GroupID        VARCHAR(MAX)
	, INS2_PolicyNumber   VARCHAR(MAX)
	, INS2_PayerID        VARCHAR(MAX)
	, INS2_SubscriberID   VARCHAR(MAX)
	, INS2_Relation_Code  VARCHAR(MAX)
	, INS2_Start_Date     VARCHAR(MAX)
	, INS2_End_Date       VARCHAR(MAX)
	, INS2_PhoneNumber    VARCHAR(MAX)
	, INS2_Plan_Code      VARCHAR(MAX)
	, INS2_Plan_Type      VARCHAR(MAX)
	, TraumaIndicator     VARCHAR(2)
	, PhysicianName       VARCHAR(MAX)
	, Prmary_Diagnostic_Description VARCHAR(MAX)
)

INSERT INTO @tmptblarx2
SELECT b.*
FROM (
	-- insurance information ------------------------------------------
	 SELECT b.pt_id
	, q.pyr_name									AS [INS1_Name]
	, ''											AS [INS1_ProgramName] -- NOT needed
	, CASE
		WHEN LEFT(r.pyr_Cd,1) NOT IN ('A','Z') 
		THEN r.grp_no
		ELSE ''
		END											AS [INS1_GROUPID] -- NOT needed
	, r.pyr_cd										AS [INS1_PayerID] -- NOT needed
	, ''                                            AS [INS1_SubscriberID] -- NOT needed
	, ''                                            AS [INS1_Relation_Code] -- NOT needed
	, CASE 
		WHEN LEFT(r.pyr_cd,1) IN ('A','Z') 
		THEN r.pol_no + ISNULL(LTRIM(RTRIM(r.grp_no)),'')
		WHEN r.pol_no IS NULL
		THEN r.subscr_ins_grp_id
		ELSE r.pol_no
		END											AS [INS1_PolicyNumber]
	, ''                                            AS [INS1_StartDate] -- NOT needed
	, ''                                            AS [INS1_EndDate] -- NOT needed
	, s.Ins_tel_no									AS [INS1_PhoneNumber] -- NOT needed
	, r.pyr_cd										AS [INS1_Plan_Code] -- NOT needed
	, ''											AS [INS1_Plan_Type] -- NOT needed
	, v.pyr_name									AS [INS2_Name]
	, ''											AS [INS2_ProgramName] -- NOT needed
	, CASE
		WHEN LEFT(w.pyr_cd,1) IN ('A','Z') 
		THEN ''
		ELSE w.grp_no
		END											AS [INS2_GroupID] -- NOT needed
	, CASE 
		WHEN LEFT(w.pyr_cd,1) IN ('A','Z') 
		THEN w.pol_no + ISNULL(LTRIM(RTRIM(w.grp_no)),'')
		WHEN w.pol_no IS NULL
		THEN w.subscr_ins_grp_id
		ELSE w.pol_no
		END											AS [INS2_PolicyNumber]
	, w.pyr_cd										AS [INS2_PayerID] -- NOT needed
	, ''											AS [INS2_SubscriberID] -- NOT needed
	, ''											AS [INS2_Relation_Code] -- NOT needed
	, ''											AS [INS2_StartDate] -- NOT needed
	, ''											AS [INS2_EndDate] -- NOT needed
	, t.Ins_tel_no									AS [INS2_PhoneNumber] -- NOT needed
	, w.pyr_cd										AS [INS2_Plan_Code] -- NOT needed
	, ''											AS [INS2_Plan_Type] -- NOT needed
	, CASE
		WHEN C.VST_TYPE_CD = 'I'
			AND BB.PT_KEY IS NULL
		THEN 'ED'
		WHEN C.VST_TYPE_CD = 'O'
			AND C.PT_TYPE = 'E'
			AND BB.PT_KEY IS NULL
		THEN 'ED'
		WHEN BB.PT_KEY IS NOT NULL
		THEN 'TR'
	    ELSE 'EA'
	  END                                           AS [Elective_or_ED_Admissions_or_Trauma_Indicator]
	, aa.pract_rpt_name                             AS [PhysicianName]
	, dd.clasf_desc                                 AS [Primary_Diagnostic_Description]

	FROM smsmir.mir_acct							AS b 
	LEFT JOIN smsmir.mir_vst						AS c
	ON b.pt_id = c.pt_id 
		AND b.pt_id_start_dtime = c.pt_id_start_dtime 
		AND b.unit_seq_no = c.unit_Seq_no
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

	WHERE b.from_file_ind IN ('4a','4h','6a','6h')
	AND b.bd_wo_dtime > '12/31/2014'
	AND b.tot_bal_amt > 0
	AND b.resp_cd IS NULL
	AND b.unit_seq_no IN (0, -1)
	AND b.pt_type NOT IN ('R', 'K')
) b

SELECT 'Brookhaven Memorial Hospital'       AS [FacilityName]
, '631-654-7209'                            AS [FacilityPhoneNumber]
, b.TraumaIndicator                         AS [Elective_or_ED_Admission_or_Trauma_Indicator]
, a.HospitalServiceDepartment
, b.PhysicianName
, a.Inpatient_Outpatient
, a.Primary_Diagnostic_Code
, b.Prmary_Diagnostic_Description
, a.Current_Financial_Class
, a.Primary_Financial_Class

-- Patient Information ------------------------------------------------
, b.ptnumber                                AS [Account_Number]
, ''                                        AS [Patient_Alternate_ID]
, a.PatientMedicalRecordNumber
, a.Patient_Last_Name
, a.Patient_First_Name
, a.Patient_Middle_Name_or_Initial
, a.Patient_Suffix
, a.Patient_SSN
, a.Patient_Date_Of_Birth
, a.Patient_Gender
, a.Patient_Address_Line_1
, a.Patient_Address_Line_2
, a.Patient_City
, a.Patient_State
, a.Patient_Zip_Code
, a.Patient_Home_Phone
, a.Patient_Work_Phone
, a.Patient_Employer_Name
, a.Patient_Work_Address
, a.Patient_Employer_City
, a.Patient_Employer_State
, a.Patient_Employer_Zip
, ''                                        AS [Patient_Annual_Income]
, a.Patient_Email

-- Co-Signor (Guarantor Informaiton) ----------------------------------
, a.GuarantorSocial
, a.GuarantorDOB
, ''                                        AS [GuarantorGender]
, a.GuarantorLast
, a.GuarantorFirst
, ''                                        AS [GuarantorMiddle]
, ''                                        AS [GuarantorSuffix]
, a.GuarantorAddressLine1
, a.GuarantorAddressLine2
, a.GuarantorCity
, a.GuarantorState
, a.GuarantorZip
, a.GuarantorPhone
, ''                                        AS [GuarantorCellPhone]
, a.GuarantorWorkPhone
, a.GuarantorEmployer_Name                  AS [GuarantorEmployer_Name]
, a.GuarantorEmployer_Address
, a.GuarantorEmployer_City
, a.GuarantorEmployer_State
, a.GuarantorEmployer_Zip
, ''                                        AS [GuarnatorEmailAddress]
, ''								        AS [Guarantor_Relation]
, ''								        AS [GuarantorMaritalStatus]
, ''								        AS [GuarantorHouseholdSize]

-- Insuarnace Information (for each insurance payor listed) -----------
, b.INS1_Name
, b.INS1_ProgramName
, b.INS1_GROUPID
, b.INS1_PayerID
, b.INS1_SubscriberID
, b.INS1_Relation_Code
, b.INS1_PolicyNumber
, b.INS1_StartDate
, b.INS1_EndDate
, b.INS1_PhoneNumber
, b.INS1_Plan_Code
, b.INS1_Plan_Type
, b.INS2_Name
, b.INS2_ProgamName
, b.INS2_GroupID
, b.INS2_PolicyNumber
, b.INS2_PayerID
, b.INS2_SubscriberID
, b.INS2_Relation_Code
, b.INS2_Start_Date
, b.INS2_End_Date
, b.INS2_PhoneNumber
, b.INS2_Plan_Code
, b.INS2_Plan_Type

-- Billing Information ------------------------------------------------
, CONVERT(VARCHAR, a.vst_start_dtime, 101)  AS [DateOfService]
, CONVERT(VARCHAR, a.vst_start_dtime, 101)  AS [DateOfAdmission]
, CONVERT(VARCHAR, a.vst_start_dtime, 101)  AS [DateOfTreatment]
, CONVERT(VARCHAR, a.vst_end_dtime, 101)    AS [Discharge_Date]
, a.len_of_stay                             AS [length_of_Stay_in_Days]
, ''                                        AS [Date_Billed] -- need this
, ''			                            AS [Amount_Charged]-- not needed
, ''                                        AS [Amount_Billed_to_Insurance]-- not needed
, a.tot_bal_amt                             AS [Total_Amount_Due]
, ''                                        AS [Patient_Responsibility_Amount]-- not needed
, ''                                        AS [Patient_Amount_of_Payments_Received]-- not needed
, CONVERT(VARCHAR, a.Last_Pt_Pymt, 101)     AS [Date_of_Last_Patient_Paymnt]
, ''                                        AS [Total_Amount_Due_from_Patient]-- not needed
, ''                                        AS [Self_Pay_Adjustment_Amount]-- not needed
, ''                                        AS [Account_Status]-- not needed
, ''                                        AS [Status_Date]-- not needed
, ''                                        AS [AmountPrePaid]-- not needed
, ''                                        AS [TotalInterest]-- not needed
, ''                                        AS [TotalLateFees]-- not needed
, ''                                        AS [TotalInsurancePayments]-- not needed
, ''                                        AS [APR]-- not needed
, CONVERT(VARCHAR, a.Last_Pt_Pymt, 101)     AS [LastPaymentDate]
, a.Last_Pymt_Amount                        AS [LastPaymentAmount]
, ''                                        AS [Amount_Charge_Off] -- not needed
, ''                                        AS [Date_Account_Closed] -- not needed
, ''                                        AS [Charge_Off_Date] -- not needed
, ''                                        AS [Insurance_1_Amount_Billed] -- not needed
, ''                                        AS [Insurance_1_Date_Billed] -- not needed
, ''                                        AS [Insurance_1_Amount_of_Payments_Received] -- not needed
, ''                                        AS [Insurance_1_Date_of_Last_Payment_Received] -- not needed
, ''                                        AS [Insurance_1_Adjustment_Amount] -- not needed
, ''                                        AS [Insurance_1_Co-Pay_Amount] -- not needed
, ''                                        AS [Insurance_1_Co-Pay_Posted_Date] -- not needed
, ''                                        AS [Insurance_1_Deductible_Amount] -- not needed
, ''                                        AS [Insurance_1_Deductible_Posted_Date] -- not needed
, ''                                        AS [Insurance_1_Insurance_Status] -- not needed
, ''                                        AS [Insurance_1_Insurance_Denial_Code] -- not needed
, ''                                        AS [Insurance_1_Insurance_Denial_Posted_Date] -- not needed
, ''                                        AS [Insurance_2_Amount_Billed] -- not needed
, ''                                        AS [Insurance_2_Date_Billed] -- not needed
, ''                                        AS [Insurance_2_Amount_of_Payments_Received] -- not needed
, ''                                        AS [Insurance_2_Date_of_Last_Payment_Received] -- not needed
, ''                                        AS [Insurance_2_Adjustment_Amount] -- not needed
, ''                                        AS [Insurance_2_Co-Pay_Amount] -- not needed
, ''                                        AS [Insurance_2_Co-Pay_Posted_Date] -- not needed
, ''                                        AS [Insurance_2_Deductible_Amount] -- not needed
, ''                                        AS [Insurance_2_Deductible_Posted_Date] -- not needed
, ''                                        AS [Insurance_2_Insurance_Status] -- not needed
, ''                                        AS [Insurance_2_Insurance_Denial_Code] -- not needed
, ''                                        AS [Insurance_2_Insurance_Denial_Posted_Date] -- not needed

-- Total --------------------------------------------------------------
, a.tot_chg_amt                             AS [Total_Charges]
, a.Total_Payments
, a.Total_Adjustments

FROM @tmptblarx1              a 
LEFT OUTER JOIN @tmptblarx2   b
ON a.Account_Number = b.ptnumber