SELECT A.pt_id                 AS [Visit Number / Account Number]
, B.GuarantorFirst             AS [Guarantor First Name]
, B.GuarantorLast              AS [Guarantor Last Name]
, B.GuarantorAddress           AS [Guarantor Address]
, B.GurantorCity               AS [Guarantor City]
, B.GuarantorState             AS [Guarantor State]
, B.GuarantorZip               AS [Guarantor Zip]
, B.GuarantorSocial            AS [Guarantor SSN]
, CAST(B.GuarantorDOB AS DATE) AS [Guarantor DOB]
--, C.Pt_Name
--, SUBSTRING(C.Pt_Name,1, CHARINDEX(' ', C.Pt_Name, 1))      AS [Patient Last NameX]
--, RIGHT(C.PT_NAME, CHARINDEX(',', REVERSE(C.PT_NAME), 1)-1) AS [Patient First NameX]
, D.pt_first                   AS [Patient First Name]
, D.pt_last                    AS [Patient Last Name]
, B.GuarantorPhone             AS [Guarantor Phone]
, D.pt_middle                  AS [Patient Middle Name]
, D.pt_dob                     AS [Patient DOB]
, D.gender_cd                  AS [Patient Gender]
, dbo.c_udf_AlphaNumericChars(
	D.Pt_Social
	)                          AS [Patient SSN]
, CASE
	WHEN RIGHT(D.Pt_Social, 1) = '?'
		THEN 1
	ELSE 0
  END                          AS [Unsure of SSN]
, C.Plm_Pt_Acct_Type           AS [Patient Type]
, A.fc                         AS [Financial Class]
, A.tot_bal_amt                AS [Client Balance]
, D.marital_sts_desc           AS [Marital Status]
, C.prin_dx_cd                 AS [Diagnosis]
, E.Pt_Employer                AS [Employer]
, C.Days_Stay                  AS [Length of Stay]
, F.pay_entry_date             AS [Date of Last Patient Payment]
, A.bd_wo_dtime                AS [Bad Debt Write Off Datetime]
, F.Tot_Pt_Pymts               AS [Amount of last Patient Payment]
, DATEDIFF(
           DAY, 
           F.pay_entry_date,
		   CAST(GETDATE() AS date)
		   )                   AS [Days since last Patient Payment]

FROM SMSMIR.mir_acct                              AS A
LEFT OUTER JOIN SMSDSS.c_guarantor_demos_v        AS B
ON A.pt_id = B.pt_id
	AND A.pt_id_start_dtime = B.pt_id_start_dtime
LEFT OUTER JOIN SMSDSS.BMH_PLM_PTACCT_V           AS C
ON A.pt_id = C.Pt_No
	AND A.unit_seq_no = C.unit_seq_no
LEFT OUTER JOIN SMSDSS.c_patient_demos_v          AS D
ON A.pt_id = D.pt_id
	AND A.pt_id_start_dtime = D.pt_id_start_dtime
LEFT OUTER JOIN smsdss.c_patient_employer_demos_v AS E
ON A.pt_id = E.pt_id
	AND A.pt_id_start_dtime = E.pt_id_start_dtime
/*
Get the last payment made by the patient from smsdss.c_pt_payments_v
*/
LEFT OUTER JOIN SMSDSS.c_pt_payments_v            AS F
ON A.pt_id = F.pt_id
	AND A.unit_seq_no = F.unit_seq_no
	-- Get the last payment made by the pt by specifying rank = 1
	AND F.Pymt_Rank = '1'

WHERE A.from_file_ind IN ('4a','4h','6a','6h')
AND A.bd_wo_dtime > '2014-12-31'
AND A.tot_bal_amt > 0
AND A.resp_cd IS NULL
AND A.unit_seq_no IN (0, -1)
AND A.pt_type NOT IN ('R', 'K')



-- get some financial class timeline data
declare @t table (
	pk int identity(1, 1) primary key
	, pt_id varchar(max)
	, cmnt_cre_dtime datetime
	, acct_hist_cmnt VARCHAR(MAX)
	, RN INT
)

INSERT into @t
select pt_id
, cmnt_cre_dtime
, acct_hist_cmnt
, ROW_NUMBER() over(
					partition by pt_id
					order by cmnt_cre_dtime desc
					) as rn

from smsmir.mir_acct_hist
where pt_id = '000013315049'
AND acct_hist_cmnt LIKE 'FIN.%'

select * from @t t where t.RN = 1

select pt_id
, cmnt_cre_Dtime
,  acct_hist_cmnt
, ROW_NUMBER() over(
					partition by pt_id
					order by cmnt_cre_dtime desc
					) as rn

from smsmir.mir_acct_hist
where pt_id = '000013315049'
AND acct_hist_cmnt LIKE 'FIN.%'