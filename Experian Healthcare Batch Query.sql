SELECT a.pt_id AS [Visit Number / Account Number]
, b.GuarantorFirst AS [Guarantor First Name]
, b.GuarantorLast  AS [Guarantor Last Name]
, b.GuarantorAddress AS [Guarantor Address]
, b.GurantorCity AS [Guarantor City]
, b.GuarantorState AS [Guarantor State]
, b.GuarantorZip AS [Guarantor Zip]
, b.GuarantorSocial AS [Guarantor SSN]
, CAST(b.GuarantorDOB AS DATE) AS [Guarantor DOB]
--, C.Pt_Name
--, SUBSTRING(C.Pt_Name,1, CHARINDEX(' ', C.Pt_Name, 1))      AS [Patient Last NameX]
--, RIGHT(C.PT_NAME, CHARINDEX(',', REVERSE(C.PT_NAME), 1)-1) AS [Patient First NameX]
, D.pt_first AS [Patient First Name]
, D.pt_last  AS [Patient Last Name]
, b.GuarantorPhone AS [Guarantor Phone]
, d.pt_middle AS [Patient Middle Name]
, d.pt_dob AS [Patient DOB]
, d.gender_cd AS [Patient Gender]
, d.Pt_Social AS [Patient SSN]
, c.Plm_Pt_Acct_Type AS [Patient Type]
, a.fc AS [Financial Class]
, c.Pt_Marital_Sts AS [Marital Status]
, c.prin_dx_cd AS [Diagnosis]
, c.Days_Stay AS [Length of Stay]

FROM SMSMIR.mir_acct                       AS A
LEFT OUTER JOIN SMSDSS.c_guarantor_demos_v AS B
ON A.pt_id = B.pt_id
	AND A.pt_id_start_dtime = B.pt_id_start_dtime
LEFT OUTER JOIN SMSDSS.BMH_PLM_PTACCT_V    AS C
ON A.pt_id = C.Pt_No
	AND A.unit_seq_no = C.unit_seq_no
LEFT OUTER JOIN SMSDSS.c_patient_demos_v   AS D
ON A.pt_id = D.pt_id

WHERE C.Plm_Pt_Acct_Type = 'I'