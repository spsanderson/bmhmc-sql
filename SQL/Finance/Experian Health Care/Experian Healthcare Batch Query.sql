DECLARE @BatchTable TABLE (
	PK INT IDENTITY(1, 1)               PRIMARY KEY
	, [Visit Number / Account Number]   VARCHAR(MAX)
	, [Unit Seq No]                     VARCHAR(MAX)
	, [Adm Date]                        DATE
	, [Guarantor First Name]            VARCHAR(MAX)
	, [Guarantor Last Name]             VARCHAR(MAX)
	, [Guarantor Address]               VARCHAR(MAX)
	, [Guarantor City]                  VARCHAR(MAX)
	, [Guarantor State]                 VARCHAR(MAX)
	, [Guarantor Zip]                   VARCHAR(MAX)
	, [Guarantor SSN]                   VARCHAR(MAX)
	, [Guarantor DOB]                   DATE
	, [Patient First Name]              VARCHAR(MAX)
	, [Patient Last Name]               VARCHAR(MAX)
	, [Guarantor Phone]                 VARCHAR(MAX)
	, [Patient Middle Name]             VARCHAR(MAX)
	, [Patient DOB]                     DATE
	, [Patient Gender]                  CHAR(1)
	, [Patient SSN]                     VARCHAR(MAX)
	, [Uninsured Insured]               VARCHAR(MAX)
	, [Patient Type]                    CHAR(1)
	, [Financial Class]                 CHAR(1)
	, [Client Balance]                  VARCHAR(MAX)
	, [Marital Status]                  VARCHAR(MAX)
	, [Diagnosis]                       VARCHAR(MAX)
	, [Employer]                        VARCHAR(500)
	, [Length of Stay]                  INT
	, [Date of Last Patient Payment]    DATE
	, [Amount of last Patient Payment]  VARCHAR(10)
	, [Days since last Patient Payment] INT
	, [RN]                              INT
	, [RN2]                             INT
);

WITH CTE1 AS (
	SELECT A.pt_id                 AS [Visit Number / Account Number]
	, A.unit_seq_no                AS [Unit Seq No]
	, C.Adm_Date                   AS [Adm Date]
	, B.GuarantorFirst             AS [Guarantor First Name]
	, B.GuarantorLast              AS [Guarantor Last Name]
	, B.GuarantorAddress           AS [Guarantor Address]
	, B.GurantorCity               AS [Guarantor City]
	, B.GuarantorState             AS [Guarantor State]
	, B.GuarantorZip               AS [Guarantor Zip]
	, B.GuarantorSocial            AS [Guarantor SSN]
	, CAST(B.GuarantorDOB AS DATE) AS [Guarantor DOB]
	, D.pt_first                   AS [Patient First Name]
	, D.pt_last                    AS [Patient Last Name]
	, B.GuarantorPhone             AS [Guarantor Phone]
	, D.pt_middle                  AS [Patient Middle Name]
	, CAST(D.pt_dob AS date)       AS [Patient DOB]
	, D.gender_cd                  AS [Patient Gender]
	, dbo.c_udf_AlphaNumericChars(
		D.Pt_Social
		)                          AS [Patient SSN]
	, CASE
		WHEN C.User_Pyr1_Cat IN ('MIS', '???')
			THEN 'U'
		    ELSE 'I'
	  END                          AS [Insured Uninsured]
	, C.Plm_Pt_Acct_Type           AS [Patient Type]
	, A.fc                         AS [Financial Class]
	, A.pt_bal_amt                 AS [Client Balance]
	, D.marital_sts_desc           AS [Marital Status]
	, C.prin_dx_cd                 AS [Diagnosis]
	, E.Pt_Employer                AS [Employer]
	, C.Days_Stay                  AS [Length of Stay]
	, CAST(
		F.pay_entry_date AS date
		)                          AS [Date of Last Patient Payment]
	, F.Tot_Pt_Pymts               AS [Amount of last Patient Payment]
	, DATEDIFF(
			   DAY, 
			   F.pay_entry_date,
			   CAST(GETDATE() AS date)
			   )                   AS [Days since last Patient Payment]
	, ROW_NUMBER() OVER(
		PARTITION BY A.PT_ID
		ORDER BY A.ADM_DTIME
	) AS [RN]
	, ROW_NUMBER() OVER(
	PARTITION BY A.PT_ID
	ORDER BY F.PAY_ENTRY_DATE DESC
	) AS [RN2]

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
		AND (
			F.Pymt_Rank = '1'
			-- add null to catch those that never paid
			OR
			F.Pymt_Rank IS NULL
		)

	WHERE RIGHT(A.from_file_ind, 1) IN ('A','T')
	
	-- Make sure the current fin class is one of the below
	AND A.fc IN ('P','J','G','T')
	
	-- Get rid of the -1 Unit Seq No line as it is a summary of
	-- all units
	AND A.unit_seq_no NOT IN (-1)
	
	-- We only want accounts that still have a balance
	AND A.pt_bal_amt > 0
	
	-- Change resp_cd to NOT IN (4, 5, 6) Per K D 1/22/2016
	AND (
		A.resp_cd NOT IN ('4', '5', '6', '9', 'K', 'O')
		OR (
			A.resp_cd IS NULL
			OR
			A.resp_cd IN (
				'*', '-', '0', '1', '2', '3', '7', '8', 'A', 'B', 'C', 
				'D', 'E', 'F', 'G', 'I', 'H', 'J', 'L', 'M', 'N',
				'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
				)
			)
		)
	-- End resp_cd edit
	
	-- Get rid of Hemo Test Pt
	AND A.acct_no != '000074006123'

	-- Get rid of unitized accounts
	AND LEFT(A.acct_no, 5) != '00000'
	AND LEFT(A.acct_no, 5) != '00007'
	
	-- Get rid of accounts that hae a credit rating
	AND A.cr_rating IS NULL
)
--ORDER BY [Visit Number / Account Number]
INSERT INTO @BatchTable
SELECT *
FROM CTE1 C1
WHERE C1.[RN2] = 1
--select * from @BatchTable

/*
=======================================================================
Get first and last financial classes
=======================================================================
*/
-- GET THE FIRST FIN CLASS A PATIENT WAS IN
DECLARE @FirstFinClass TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, PT_ID               CHAR(12)
	, CMNT_CRE_DTIME      DATE
	, ACCT_HIST_CMNT      CHAR(50)
	, RN                  INT
);

WITH CTE2 AS (
	SELECT pt_id
	, cmnt_cre_dtime
	, LTRIM(RTRIM(acct_hist_cmnt)) AS ACCT_HIST_CMNT
	, ROW_NUMBER() OVER(
		PARTITION BY PT_ID
		ORDER BY CMNT_CRE_DTIME ASC
	) AS RN

	FROM SMSMIR.mir_acct_hist

	WHERE acct_hist_cmnt LIKE 'FIN.%'
	AND pt_id >= (
		SELECT MIN([Visit Number / Account Number])
		FROM @BatchTable
	)
)

INSERT INTO @FirstFinClass
SELECT *
FROM CTE2 C2
WHERE RN = 1

-- GET THE LAST FIN CLASS A PATIENT WAS IN ----------------------------
DECLARE @LastFinClass TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, PT_ID               CHAR(12)
	, CMNT_CRE_DTIME      DATE
	, ACCT_HIST_CMNT      CHAR(50)
	, RN                  INT
);

WITH CTE3 AS (
	SELECT pt_id
	, cmnt_cre_dtime
	, LTRIM(RTRIM(acct_hist_cmnt)) AS ACCT_HIST_CMNT
	, ROW_NUMBER() OVER(
		PARTITION BY PT_ID
		ORDER BY CMNT_CRE_DTIME DESC
	) AS RN

	FROM SMSMIR.mir_acct_hist

	WHERE acct_hist_cmnt LIKE 'FIN.%'
	AND PT_ID >= (
		SELECT MIN([Visit Number / Account Number])
		FROM @BatchTable
	)
)

INSERT INTO @LastFinClass
SELECT *
FROM CTE3 C3
WHERE RN = 1

/*
=======================================================================
Pull it all together
=======================================================================
*/
SELECT A.[Visit Number / Account Number]
--, A.[Unit Seq No]
--, A.[Adm Date]
, A.[Guarantor First Name]
, A.[Guarantor Last Name]
, A.[Guarantor Address]
, A.[Guarantor City]
, A.[Guarantor State]
, A.[Guarantor Zip]
, CASE
	WHEN (DATEDIFF(DAY, A.[Patient DOB], A.[Adm Date])/365.25) >= 21 
		THEN A.[Patient SSN] 
		ELSE A.[Guarantor SSN]
  END                                AS [Guarantor SSN]
, A.[Guarantor DOB]
, A.[Patient First Name]
, A.[Patient Last Name]
, A.[Guarantor Phone]
, A.[Patient Middle Name]
, A.[Patient DOB]
, A.[Patient Gender]
, A.[Patient SSN]
, A.[Uninsured Insured]
, A.[Patient Type]
, A.[Financial Class]
, A.[Client Balance]
, A.[Marital Status]
, A.[Diagnosis]
, A.[Employer]
, A.[Length of Stay]

INTO #experian_batch

--, A.[Date of Last Patient Payment]
--, A.[Amount of last Patient Payment]
--, A.[Days since last Patient Payment]
--, B.ACCT_HIST_CMNT                   AS [First_FC_Comment]
--, SUBSTRING(B.ACCT_HIST_CMNT, 16, 1) AS [First_FC]
--, B.CMNT_CRE_DTIME                   AS [Message_Date]
--, C.ACCT_HIST_CMNT                   AS [Last_FC_Comment]
--, SUBSTRING(C.ACCT_HIST_CMNT, 16, 1) AS [Last_FC]
--, C.CMNT_CRE_DTIME                   AS [Message_Date]
--, DATEDIFF(
--	DAY,
--	C.CMNT_CRE_DTIME,
--	CAST(GETDATE() AS date)
--	)                                AS [Days_In_Current_FC]

FROM @BatchTable                     AS A
LEFT OUTER MERGE JOIN @FirstFinClass AS B
ON A.[Visit Number / Account Number] = B.PT_ID
LEFT OUTER MERGE JOIN @LastFinClass  AS C
ON A.[Visit Number / Account Number] = C.PT_ID

WHERE (
		-- Changes days since last payment to  >= 90 
		-- per K D 1/22/2016
		-- [Days since last Patient Payment] >= 120
		[Days since last Patient Payment] >= 90
		OR
		[Days since last Patient Payment] IS NULL
	)

-- Must be self pay for at least 110 days
AND DATEDIFF(DAY, C.CMNT_CRE_DTIME, CAST(GETDATE() AS date)) >= 118

-- Get rid of Unitized accounts per K D 1/22/2016
AND LEFT(A.[Visit Number / Account Number], 5) != '00000'
AND LEFT(A.[Visit Number / Account Number], 5) != '00007'

-- Brookhaven cannot be the guarantor
AND A.[Guarantor Last Name] != 'BROOKHAVEN MEMORIAL HOPITAL'

-- get the following accounts
--AND A.[Visit Number / Account Number] IN ()

SELECT * 
FROM #experian_batch zzz

WHERE zzz.[Guarantor SSN] NOT IN (
	'999999999', '999999991', '888888888', '111111111', '000000000'
)

-- Drop the temporary persistant table when done
DROP TABLE #experian_batch