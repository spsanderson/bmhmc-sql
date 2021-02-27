/*
Billing TIN Number
Patient First Name
Patient Middle Initial  
Patient Last Name
Patient Date of Birth (MM/DD/YYYY)
ID Type (SSN, State ID, No ID)
ID Number   
Patient Gender (M/F)    
Patient Account Number  
Patient Street Line 1   
Patient Street Line 2   
Patient City    
Patient State   
Patient Zip Code    
Service Type (Professional, Institutional Outpatient, Institutional Inpatient)
Date of Service (MM/DD/YYYY)    
Date of Admission (MM/DD/YYYY)  
Date of Discharge (MM/DD/YYYY)
*/
SELECT PAV.PTNO_NUM
, '111704595' AS 'TIN'
, SUBSTRING(PT.pt_first, 1, 20) AS [pt_first]
, SUBSTRING(pt.pt_middle, 1, 1) AS [pt_middle]
, SUBSTRING(pt.pt_last, 1, 20) AS [pt_last]
-- CONVERT(VARCHAR(10), fmdate(), 101)
, CONVERT(VARCHAR(10), PT.pt_dob, 101) AS [pt_dob]
, CASE
	WHEN CAST(PT.PT_SOCIAL AS VARCHAR) = '000000000'
		THEN 'NO ID'
	WHEN CAST(PT.PT_SOCIAL AS VARCHAR) IS NULL
		THEN 'NO ID'
	ELSE 'SSN' END AS [ID_Type]
--, 'SSN' AS [ID_Type]
, CAST(PT.Pt_Social AS VARCHAR) AS [Pt_Social]
, PAV.Pt_Sex
--, pav.PtNo_Num
, SUBSTRING(PT.addr_line1, 1, 30) AS [addr_line1]
, SUBSTRING(PT.Pt_Addr_Line2, 1, 30) AS [Pt_Addr_Line2]
, SUBSTRING(PT.Pt_Addr_City, 1, 30) AS [Pt_Addr_City]
, PT.Pt_Addr_State
, SUBSTRING(PT.Pt_Addr_Zip, 1, 5) AS [Pt_Addr_Zip]
, CASE 
    WHEN PAV.Plm_Pt_Acct_Type = 'O'
        THEN 'Outpatient'
        ELSE 'Inpatient'
  END AS [PT_Type]
, [Date_Of_Service] = CASE  
    WHEN PAV.Plm_Pt_Acct_Type = 'O'
        THEN CONVERT(VARCHAR(10), PAV.Adm_Date, 101)
        ELSE CONVERT(VARCHAR(10), PAV.Dsch_Date, 101)
    END
, CONVERT(VARCHAR(10), PAV.Adm_Date, 101) AS [Adm_Date]
, CONVERT(VARCHAR(10), PAV.Dsch_Date, 101) AS [Dsch_Date]
, PAV.Med_Rec_No
, PAV.Tot_Amt_Due
FROM SMSDSS.BMH_PLM_PTACCT_V AS PAV
LEFT OUTER JOIN SMSDSS.c_patient_demos_v AS PT 
ON PAV.PT_NO = PT.pt_id
AND PAV.from_file_ind = PT.from_file_ind
--WHERE PAV.User_Pyr1_Cat = 'MIS'
WHERE pav.Pyr1_Co_Plan_Cd in ('*')--,'E37')
AND PAV.TOT_AMT_DUE > 0
AND PAV.PT_NO IN (
	SELECT DISTINCT PT_ID
	FROM SMSMIR.ACTV
	WHERE ACTV_CD IN (
		'00390914','00390922'
	)
)