-- VARIABLE DECLARATION AND INITIALIZATION
DECLARE @START DATE;
DECLARE @END DATE;

SET @START = '2014-01-01';
SET @END = '2014-01-02';

SELECT
(CASE
	WHEN CHARINDEX(' ,', PAV.Pt_Name, 1) <> 0
	THEN SUBSTRING(PAV.Pt_Name, CHARINDEX(' ', PAV.Pt_Name, 1)+2, 25)
	WHEN CHARINDEX(', ', PAV.Pt_Name, 1) <> 0
	THEN SUBSTRING(PAV.Pt_Name, CHARINDEX(',', PAV.Pt_Name, 1)+2, 25)
END) 
AS [FIRST NAME]

, (CASE
	WHEN CHARINDEX(' ,', PAV.Pt_Name, 1) <> 0
	THEN SUBSTRING(PAV.Pt_Name, 1, CHARINDEX(' ', PAV.Pt_Name, 1)-1)
	WHEN CHARINDEX(', ', PAV.Pt_Name, 1) <> 0
	THEN SUBSTRING(PAV.Pt_Name, 1, CHARINDEX(',', PAV.Pt_Name, 1)-1)
	END) 
AS [LAST NAME]

, CONVERT(VARCHAR, PAV.Pt_Birthdate, 112) 
AS [DATE OF BIRTH]

, PAV.Pt_Sex
AS GENDER

, R.RACE
AS RACE

, E.ETHNICITY
AS ETHNICITY

, I.PAYER
AS PAYER

, MPP.pol_no -- PAGE 13
AS [INSURANCE NUMBER]

, SUBSTRING(PAV.Pt_SSA_No,6,4)
AS [SOCIAL SECURITY NUMBER]

, PAV.Med_Rec_No
AS [MEDICAL RECORD NUMBER]

, '' -- PAGE 16
AS [FACILITY IDENTIFIER]

, CONVERT(VARCHAR, PAV.Adm_Date, 112)
AS [ADMISSION DATE]

, SUBSTRING(CONVERT(VARCHAR, PAV.vst_start_dtime,114),1,5)
AS [ADMISSION TIME]

, A.ADMSRC
AS [SOURCE OF ADMISSION]

, CONVERT(VARCHAR, PAV.Dsch_Date, 112)
AS [DISCHARGE DATE]

, SUBSTRING(CONVERT(VARCHAR, PAV.vst_end_dtime,114),1,5)
AS [DISCHARGE TIME]

, D.DSCH
AS [DISCHARGE STATUS]

/*
***********************************************************************
WHERE THE DATA IS COMING FROM
***********************************************************************
*/
FROM smsdss.BMH_PLM_PtAcct_V               PAV
JOIN smsdss.pyr_dim_v                      PDV
ON PAV.Pyr1_Co_Plan_Cd = PDV.src_pyr_cd
JOIN smsmir.mir_pyr_plan                   MPP
ON PAV.PtNo_Num = MPP.pt_id
JOIN smsdss.adm_src_mstr                   ASM
ON PAV.Adm_Source = ASM.adm_src

/*
***********************************************************************
CROSS APPLY STATEMENTS BEING USED IN STEAD OF INDIVIDUAL CASE STATEMENTS
INSIDE OF THE SELECT CLAUSE
***********************************************************************
*/
CROSS APPLY (
	SELECT
		CASE
			WHEN PAV.Pt_Race = 'W'         
				THEN '01' -- WHITE
			WHEN PAV.Pt_Race = 'B'         
				THEN '02' -- BLACK OR AFRICAN AMERICAN
			WHEN PAV.Pt_Race = 'I'         
				THEN '03' -- NATIVE AMERICAN OR ALASKAN NATIVE
			WHEN PAV.Pt_Race = 'A'         
				THEN '04' -- ASIAN
			WHEN PAV.Pt_Race IN ('H', 'O') 
				THEN '88' -- NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER
			WHEN PAV.Pt_Race IN ('?', 'U') 
				THEN '99' -- OTHER RACE
			WHEN PAV.Pt_Race IS NULL       
				THEN '99' -- UNKNOWN
		END AS RACE
) R

CROSS APPLY (
	SELECT
		CASE
			WHEN PAV.Pt_Race = 'H'         
				THEN '1' -- SPANISH/HISPANIC ORIGIN
			WHEN PAV.Pt_Race IN ('W', 'B', 'I', 'A') 
				THEN '2' -- NOT OF SPANISH/HISPANIC ORIGIN
			ELSE     '9' -- UNKNOWN
		END AS ETHNICITY
) E

CROSS APPLY (
SELECT
	CASE
		WHEN PDV.pyr_group2 IN ('Self Pay', 'No Description')
			THEN 'A' -- SELF PAY
		WHEN PDV.pyr_group2 IN ('Compensation') 
			THEN 'B' -- WORKERS COMP
		WHEN PDV.pyr_group2 IN ('Medicare A', 'Medicare B', 
								'Medicare HMO')
			THEN 'C' -- MEDICARE
		WHEN PDV.pyr_group2 IN ('Medicaid', 'Medicaid HMO')
			THEN 'D' --MEDICAID
		WHEN PDV.pyr_group2 IN ('Commercial', 'No Description', 'HMO',
								'JJJ')				    
			THEN 'F' -- INSURANCE COMPANY
		WHEN PDV.pyr_group2 IN ('Blue Cross')   
			THEN 'G' -- BLUE CROSS
		WHEN PDV.pyr_group2 IN ('No Fault')     
			THEN 'I' -- OTHER NON-FEDERAL PROGRAM
	END AS PAYER
) I

CROSS APPLY (
SELECT 
	CASE 
		WHEN ASM.adm_src_desc IN ('Relatives Home',
							'Foster Home',
							'Newborn, Outside Hospital',
							'Scheduled Admission',
							'Unscheduled Admission',
							'HMO Referral',
							'Family Physician Referral',
							'Home Care Service Referral'
							)
			THEN '1'
		WHEN ASM.adm_src_desc IN ('Outpatient Clinic',
							'Structured Outpatient Unit'
							)
			THEN '2'
		WHEN ASM.adm_src_desc IN ('Transfer from Specialty Hospital')
			THEN '4'
		WHEN ASM.adm_src_desc IN ('Transfer from Intermediate Care')
			THEN '5'
		WHEN ASM.adm_src_desc IN ('Outpatient Service',
							'Transfer from Another Institution',
							'Transfer from Custodial Care',
							'Transfer from Long Term Care',
							'Transfer from State Facility',
							'Transfer from Short Term Hospital',
							'Transfer from Maternity',
							'Transfer from Another Facility',
							'Transfer from Psychiatric Facility',
							'Transfer from Rehabilitation Center'
							)
			THEN '6'
		WHEN ASM.adm_src_desc IN ('Govermental Agency Referral',
							'Transfer from Correctional Facility'
							)
			THEN '8'
		WHEN ASM.adm_src_desc IN ('Information Not Available',
							'No Description'
							)
			THEN '9'
		WHEN ASM.adm_src_desc IN ('Emergency Unit',
							'Newborn',
							'Newborn, Premature Delivery',
							'Newborn, Sick Baby'
							)
			THEN 'D'
		WHEN ASM.adm_src_desc IN ('Transfer from Terminal Care Facility')
			THEN 'F'
		
END AS ADMSRC
) A

CROSS APPLY (
SELECT 
	CASE 
		WHEN PAV.dsch_disp IN ('ATX', 'ATH', 'ATN') 
			THEN '02'
		WHEN PAV.dsch_disp IN ('ATL', 'ATE')
			THEN '03'
		WHEN PAV.dsch_disp IN ('ATW', 'AHR')
			THEN '06'
		WHEN PAV.dsch_disp IN ('AMA')
			THEN '07'
		WHEN PAV.dsch_disp IN ('ATF')
			THEN '09'
		WHEN PAV.dsch_disp IN ('C4A', 'D4A', 'C4N', 'D4N',
							   'C4Z', 'D4Z', 'C8A', 'D8A',
							   'C8Z', 'D8Z', 'C8N', 'D8N',
							   'C7A', 'D7A', 'C7Z', 'D7Z',
							   'C7N', 'D7N', 'C1A', 'D1A',
							   'C1Z', 'D1Z', 'C1N', 'D1N',
							   'C3A', 'D3A', 'C3Z', 'D3Z',
							   'C3N', 'D3N', 'C2A', 'D2A',
							   'C2Z', 'D2Z', 'C2N', 'D2N')
			THEN '20'
		WHEN PAV.dsch_disp IN ('ATB')
			THEN '21'
		WHEN PAV.dsch_disp IN ('ATT')
			THEN '50'
		WHEN PAV.dsch_disp IN ('AHI')
			THEN '51'
		WHEN PAV.dsch_disp IN ('ATP')
			THEN '65'
		WHEN PAV.dsch_disp IN ('AHB')
			THEN '70'
END AS DSCH
) D

WHERE PAV.Dsch_Date >= @START
AND PAV.Dsch_Date < @END
AND PAV.Plm_Pt_Acct_Type = 'I'
AND PAV.PtNo_Num < '20000000'
AND PDV.orgz_cd = 'S0X0'
AND MPP.pyr_seq_no = 1
AND ASM.orgz_cd = 'S0X0'

