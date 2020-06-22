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
SELECT '111704595' AS 'TIN'
, SUBSTRING(PT.pt_first, 1, 20) AS [pt_first]
, SUBSTRING(pt.pt_middle, 1, 1) AS [pt_middle]
, SUBSTRING(pt.pt_last, 1, 20) AS [pt_last]
-- CONVERT(VARCHAR(10), fmdate(), 101)
, CONVERT(VARCHAR(10), PT.pt_dob, 101) AS [pt_dob]
, 'SSN' AS [ID_Type]
, CAST(PT.Pt_Social AS VARCHAR) AS [Pt_Social]
, PAV.Pt_Sex
, pav.PtNo_Num
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
FROM SMSDSS.BMH_PLM_PTACCT_V AS PAV
LEFT OUTER JOIN SMSDSS.c_patient_demos_v AS PT 
ON PAV.PT_NO = PT.pt_id
AND PAV.from_file_ind = PT.from_file_ind
WHERE PAV.User_Pyr1_Cat = 'MIS'
AND PAV.PT_NO IN (
    SELECT DISTINCT ZZZ.pt_id
    FROM SMSMIR.dx_grp AS ZZZ
    WHERE ZZZ.dx_cd IN (
            'Z03.818','Z20.828','Z11.59','U07.1','B987.29','O98.5'
    )
    AND LEFT(ZZZ.dx_cd_type, 2) = 'DF'
    AND ZZZ.DX_PRIO != '01'
)
AND (
    (
        PAV.Plm_Pt_Acct_Type = 'I'
        AND PAV.Dsch_Date >= '2020-02-04'
    )
    OR 
    (
        PAV.Plm_Pt_Acct_Type != 'I'
        AND PAV.Adm_Date >= '2020-02-04'
    )
)
--AND PAV.prin_dx_cd IN (
    --'U07.1',
    --'B97.29', -- PRIOR TO APRIL 1, 2020
    --'O98.5'   -- for pregnancy
--    'Z03.818','Z20.828','Z11.59' -- only for outpatient
--)
