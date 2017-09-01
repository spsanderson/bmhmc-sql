/*
=======================================================================
Get Initial Population of DSRIP TOC Patients
=======================================================================
*/

DECLARE @TOC TABLE (
	PK INT IDENTITY(1, 1)                 PRIMARY KEY
	, [CIN#]                              VARCHAR(15)
	, [Patient Last Name]                 VARCHAR(50)
	, [Patient First Name]                VARCHAR(50)
	, [Encounter]                         INT
	, [DOB]                               DATE
	, [Zip Code]                          CHAR(5)
	, [Arrival Date]                      DATE
	, [Discharge Date]                    DATE
	, [Primary Payor Name]                VARCHAR(200)
	, [Primary Payor Patient ID Number]   VARCHAR(200)
	, [Secondary Payor Name]              VARCHAR(200)
	, [Secondary Payor Patient ID Number] VARCHAR(200)
	, [Tertiary Payor Name]               VARCHAR(200)
	, [Tertiary Payor Patient ID Number]  VARCHAR(200)
	, [Encounter Type]                    CHAR(9)
);

WITH CTE1 AS (
	SELECT --a.med_Rec_no                AS [MRN #]
	  CASE
		WHEN LEFT(pyr1_co_plan_cd,1) = 'W'
			THEN RTRIM(ISNULL(c.pol_no,'')) + LTRIM(RTRIM(ISNULL(c.grp_no,'')))
		ELSE ''
	  END                              AS [CIN #]
	, n.pt_last                        AS [Patient Last Name]
	, N.pt_first                       AS [Patient First Name]
	, a.pt_no
	, CONVERT(date,a.Pt_Birthdate,101) AS [DOB]
	, b.postal_cd                      AS [Zip Code]
	--, b.nhs_id_no
	, CAST(h.vst_start_dtime AS date)  AS [Arrival date]
	, CAST(a.Dsch_DTime AS date)       AS [Discharge date]
	, i.pyr_name                       AS [Primary Payor Name]
	, CASE
		WHEN LEFT(a.pyr1_co_plan_cd,1) = 'B'
			THEN c.subscr_ins_grp_id
		WHEN a.pyr1_co_plan_Cd IN ('E18','E28')
			THEN c.subscr_ins_grp_id
		ELSE RTRIM(ISNULL(c.pol_no,'')) + LTRIM(RTRIM(ISNULL(c.grp_no,''))) 
	  END                              AS [Primary Payor Patient ID Number]
	, j.pyr_name                       AS [Secondary Payor Name]
	, CASE
		WHEN LEFT(a.pyr2_co_plan_cd,1) = 'B'
			THEN d.subscr_ins_grp_id
		WHEN a.pyr2_co_plan_Cd IN ('E18','E28')
			THEN d.subscr_ins_grp_id
		ELSE RTRIM(ISNULL(d.pol_no,'')) + LTRIM(RTRIM(ISNULL(d.grp_no,''))) 
	  END                              AS [Secondary Payor Patient ID Number]
	, k.pyr_name                       AS [Tertiary Payor Name]
	--, a.pyr3_co_plan_Cd                AS [Tertiary Payor Name]
	, CASE
		WHEN LEFT(a.pyr3_co_plan_cd,1) = 'B'
			THEN e.subscr_ins_grp_id
		WHEN a.pyr3_co_plan_Cd IN ('E18','E28')
			THEN e.subscr_ins_grp_id
		ELSE RTRIM(ISNULL(e.pol_no,'')) + LTRIM(RTRIM(ISNULL(e.grp_no,''))) 
	  END                              AS [Tertiary Payor Patient ID Number]
	--, a.Atn_Dr_No
	--, f.pract_rpt_name
	--, f.npi_no
	--, g.spclty_cd_Desc
	--, a.hosp_svc
	--, m.ward_cd
	--, a.plm_pt_acct_type               AS [Encounter Type]
	, 'IP'                             AS [Encounter Type]

	FROM smsdss.BMH_PLM_PtAcct_V             AS a 
	LEFT OUTER JOIN smsmir.mir_pt            AS b
	ON a.Pt_No = b.pt_id
	LEFT OUTER JOIN smsmir.mir_pyr_plan      AS c
	ON a.Pt_No = c.pt_id
		AND a.Pyr1_Co_Plan_Cd = c.pyr_cd
	LEFT OUTER JOIN smsmir.mir_pyr_plan      AS d
	ON a.Pt_No = d.pt_id 
		AND a.Pyr2_Co_Plan_Cd = d.pyr_cd
	LEFT OUTER JOIN smsmir.mir_pyr_plan      AS e
	ON a.Pt_No = e.pt_id 
		AND a.Pyr3_Co_Plan_Cd = e.pyr_Cd
	LEFT OUTER JOIN smsmir.mir_pract_mstr    AS f
	ON a.Atn_Dr_No = f.pract_no 
		AND f.src_sys_id='#PASS0X0'
	LEFT OUTER JOIN smsdss.pract_spclty_mstr AS g
	ON f.spclty_cd1 = g.spclty_cd 
		AND g.src_sys_id = '#PASS0X0'
	LEFT OUTER JOIN smsmir.mir_vst           AS h
	ON a.Pt_No = h.pt_id
	LEFT OUTER JOIN smsmir.mir_pyr_mstr      AS i
	ON a.pyr1_co_plan_cd = i.pyr_cd
	LEFT OUTER JOIN smsmir.mir_pyr_mstr      AS j
	ON a.Pyr2_Co_Plan_Cd = j.pyr_cd
	LEFT OUTER JOIN smsmir.mir_pyr_mstr      AS k
	ON a.Pyr3_Co_Plan_Cd = k.pyr_cd
	LEFT OUTER JOIN smsmir.mir_vst_rpt       AS m
	ON a.Pt_No = m.pt_id
	LEFT OUTER JOIN smsdss.c_patient_demos_v AS n
	ON A.Pt_No = N.pt_id

	WHERE a.user_pyr1_Cat IN ('WWW','III')
	AND a.Plm_Pt_Acct_Type = 'I'-- or a.pt_type = 'E')
	AND a.Dsch_DTime BETWEEN '2015-04-01 00:00:00.000' AND '2015-12-31 23:59:59.000'
	AND a.tot_chg_amt > '0'
	AND LEFT(a.dsch_disp, 1) NOT IN ('C','D')
	AND a.dsch_disp != 'AMA'
)

INSERT INTO @TOC
SELECT *
FROM CTE1 C1
WHERE C1.Pt_No NOT IN ('12345678910', '99990000999')

/*
=======================================================================
Get the CCDA Information AND Medication Reconcilliation Indicator
=======================================================================
*/
DECLARE @CCDA TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, [A - ENCOUNTER]     INT
	, [B - ENCOUNTER]     INT
	, [A - STARTING VISIT OID] INT
	, [Discharge Medication Reconcilliation] INT
	, [CCDA Generated]    INT
);

WITH CCDA AS (
	SELECT a.PatientAccountID  AS [A - ENCOUNTER]
	, b.episode_no             AS [B - ENCOUNTER]
	, A.StartingVisitOID       AS [A - STARTING VISIT OID]
	, b.dsch_reconcl_chtd_ind  AS [Discharge Medication Reconcilliation]
	, b.trans_of_care_chtd_ind AS [CCDA Generated]

	FROM smsmir.sc_patientvisit                   AS A
	LEFT OUTER JOIN smsdss.QOC_vst_summ_v         AS B
	ON a.PatientAccountID = b.episode_no

	WHERE A.PatientAccountID NOT IN (
		'12345678910', '99990000999'
	)
	AND A.PatientAccountID < '20000000'
)

INSERT INTO @CCDA
SELECT *
FROM CCDA

--SELECT * FROM @CCDA
/*
=======================================================================
Get Discharge Summary Information
=======================================================================
*/
DECLARE @DischargeSummary TABLE(
	PK INT IDENTITY(1, 1)                    PRIMARY KEY
	, [A - ENCOUNTER]                        INT
	, [A - STARTING VISIT OID]               INT
	, [C - PATIENT VISIT OID]                INT
	, [Discharge Summary Creation DateTime]  DATETIME
	, [Discharge Summary Created]            INT
	, [Last Discharge Summary]               INT
);

WITH DischargeSummary AS (
	SELECT a.PatientAccountID  AS [A - ENCOUNTER]
	, A.StartingVisitOID       AS [A - STARTING VISIT OID]
	, c.PatientVisit_oid       AS [C - PATIENT VISIT OID]
	, c.CreationTime           AS [Discharge Summary Creation DateTime]
	, CASE
		WHEN C.CreationTime IS NOT NULL
			THEN 1
			ELSE 0
	  END                      AS [Discharge Summary Created]
	-- If a Discharge Summary does not exist, using this case statement
	-- will force a value of 0 for the ROW_NUMBER() OVER() function
	-- At the end we only accept ROW_NUMBER() 1 to get the last 
	-- discharge summary generated
	, CASE 
		WHEN C.CreationTime IS NOT NULL
			THEN ROW_NUMBER() OVER (
				PARTITION BY C.PATIENTVISIT_OID
				ORDER BY C.OBJECTID DESC
				)
			ELSE 0
	END                         AS [Last_Discharge_Summary]

	FROM smsmir.sc_patientvisit                   AS A
	LEFT OUTER JOIN smsmir.sc_InvestigationResult AS C
	ON a.StartingVisitOID = c.PatientVisit_oid
		AND (
				C.FindingAbbreviation LIKE 'MQ_%Discharge Sum%'
			 OR C.FindingAbbreviation LIKE 'MQ_%Psych Sum%'
			 OR C.FindingAbbreviation LIKE 'MQ_%Transfer Sum%'
		)

	WHERE A.PatientAccountID NOT IN (
		'12345678910', '99990000999'
	)
	AND A.PatientAccountID < '20000000'
)

INSERT INTO @DischargeSummary
SELECT *
FROM DischargeSummary
-- We only want the last discharge summary generated
WHERE DischargeSummary.Last_Discharge_Summary = 1

/*
=======================================================================
Was some sort of education given to the patient during their stay Pt. 1
=======================================================================
*/
DECLARE @Edu TABLE (
	PK INT IDENTITY(1, 1)  PRIMARY KEY
	, [Encounter]          INT
	, [PatientVisit_oid]   INT
	, [Collected Datetime] DATETIME
	, [RN]                 INT
);

WITH EDU AS (
	SELECT A.PatientAccountID
	, B.PatientVisit_oid
	, B.CollectedDT
	-- Since multiple forms of education can be given, we only want
	-- the last system generated documentation that education was 
	-- given. At the end we select only those records where rn = 1
	, ROW_NUMBER() OVER (
		PARTITION BY B.patientvisit_oid
		ORDER BY B.collectedDT
	) AS [rn]

	FROM SMSMIR.sc_PatientVisit     AS A
	INNER JOIN smsmir.sc_Assessment AS B
	ON A.StartingVisitOID = B.PatientVisit_oid

	WHERE B.FormUsage = 'Education'
	AND A.PatientAccountID < '20000000'
	AND A.PatientAccountID NOT IN (
		'12345678910', '99990000999'
	)
	AND B.AssessmentStatus = 'Complete'
)

INSERT INTO @Edu
SELECT *
FROM EDU
WHERE RN = 1

--SELECT *
--FROM @Edu

/*
=======================================================================
Was some sort of education given to the patient during their stay Pt. 2
=======================================================================
*/
DECLARE @Edu2 TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, Encounter           INT
	, Edu_Type            VARCHAR(200)
	, Edu_Method          VARCHAR(200)
	, Edu2_Flag           INT
);

WITH Edu2 AS (
	SELECT episode_no
	, obsv_cd_name
	, dsply_val
	, ROW_NUMBER() OVER (
		PARTITION BY episode_no
		ORDER BY timestamp asc
	) AS rn

	FROM smsmir.sr_obsv
	WHERE obsv_cd IN (
		'A_BMH_Gentemeth', 'A_BMH_BariTeaM', 'A_BMH_NutTeaM',
		'A_BMH_GenEdTo',   'A_BMH_BariEdTo', 'A_BMH_NutEdTo',
		'A_BMH_CardTeaM',  'A_BMH_PreTeaM',  'A_BMH_PTTeaM',
		'A_BMH_CardEdTo',  'A_BMH_PreEdTo',  'A_BMH_PTEdTo',
		'A_BMH_DbTeaM',	   'A_BMH_BehTeaM',  'A_BMH_ResTeaM',
		'A_BMH_DbEdTo',	   'A_BMH_BehEdTo',  'A_BMH_ResEdTo',
		'A_BMH_OstTeaM',   'A_BMH_DiTea',    'A_BMH_SLPTeaM',
		'A_BMH_OstEdTo',   'A_BMH_DcEdTo',   'A_BMH_SLPEdTo'
	)
	AND episode_no < '20000000'
	AND episode_no NOT IN ('12345678910', '99990000999')
)

INSERT INTO @Edu2
SELECT *
FROM Edu2
WHERE rn = 1

--SELECT *
--FROM @Edu2

/*
=======================================================================
Where discharge Instuctions completed with a referral
=======================================================================
*/
DECLARE @DischargeInstructions TABLE (
	PK INT IDENTITY(1, 1)  PRIMARY KEY
	, [Encounter]          INT
	, [PatientVisit_oid]   INT
	, [Collected Datetime] DATETIME
	, [Status]             VARCHAR(20)
	, [Referral]           VARCHAR(MAX)
	, [Referral Flag]      INT
	, [RN]                 INT
);

WITH DischInstruct AS (
	SELECT A.PatientAccountID
	, B.PatientVisit_oid
	, B.CollectedDT
	, B.AssessmentStatus
	, C.dsply_val
	, CASE
		WHEN C.dsply_val IS NOT NULL
			THEN 1
			ELSE 0
	  END AS [Referral Flag]
	-- We want to see if a patient has a completed set of discharge instructions
	-- and if the patient was given a referral to a follow up appointment
	, ROW_NUMBER() OVER (
		PARTITION BY B.patientvisit_oid
		ORDER BY B.collectedDT
	) AS [rn]

	FROM SMSMIR.sc_PatientVisit     AS A
	INNER JOIN smsmir.sc_Assessment AS B
	ON A.StartingVisitOID = B.PatientVisit_oid
	LEFT OUTER JOIN SMSMIR.sr_obsv  AS C
	ON A.PatientAccountID = C.episode_no
		AND form_usage = 'bmh_discharge instructions2'
		AND obsv_cd = 'A_OSMedRefWho'

	WHERE B.FormUsage = 'BMH_Discharge Instructions2'
	AND A.PatientAccountID < '20000000'
	AND A.PatientAccountID NOT IN (
		'12345678910', '99990000999'
	)
	AND B.AssessmentStatus = 'Complete'
)

INSERT INTO @DischargeInstructions
SELECT *
FROM DischInstruct
WHERE RN = 1

--SELECT *
--FROM @DischargeInstructions
/*
=======================================================================
Pull it together
=======================================================================
*/
SELECT A.*
, b.[CCDA Generated]
, b.[Discharge Medication Reconcilliation]
, CASE
	WHEN C.[Discharge Summary Created] IS NULL
		THEN 0
		ELSE C.[Discharge Summary Created]
  END AS [Discharge Summary Created]
, CASE
	WHEN D.[Collected Datetime] IS NULL
		THEN 0
		ELSE 1
  END AS [Edu Flag 1]
, CASE
	WHEN E.Edu2_Flag IS NULL
		THEN 0
		ELSE 1
  END AS [Edu Flag 2]
, CASE
	WHEN D.[Collected Datetime] IS NOT NULL
	OR
	e.Edu2_Flag = 1
		THEN 1
		ELSE 0
  END AS [Edu Given Flag]
, CASE
	WHEN F.[Referral Flag] = 1
	THEN 1
	ELSE 0
  END AS [Discharge Instructions Comp w/MD Ref]
, CASE
	WHEN (
	    -- is the ccda generate chrt ind equal to 1
		B.[CCDA Generated] = 1
		-- if not then:
			-- discharge instuctions w/ref flag = 1
			-- AND med rec flag = 1
			-- AND edu flag = 1
			-- AND discharge summary flag = 1 -- sps not needed
		OR (
			-- does med rec flag = 1
			b.[Discharge Medication Reconcilliation] = 1
			-- was a discharge summary created
			--AND c.[Discharge Summary Created] IS NOT NULL -- sps not needed
			-- was education given
			AND (
				-- edu flag 1
				d.[Collected Datetime]        IS NOT NULL
				OR
				-- edu flag 2
				E.Edu2_Flag = 1
				)
			-- complete discharge instructions w/md ref
			AND f.[Referral Flag] = 1
			)
		)
		THEN 'Yes'
		ELSE 'No'
  END AS [CCDA AND/OR Discharge Instructions Completed]

FROM @TOC                              AS A
LEFT OUTER JOIN @CCDA                  AS B
ON A.Encounter = B.[A - ENCOUNTER]
LEFT OUTER JOIN @DischargeSummary      AS C
ON A.Encounter = C.[A - ENCOUNTER]
LEFT OUTER JOIN @Edu                   AS D
ON A.Encounter = D.Encounter
LEFT OUTER JOIN @Edu2                  AS E
ON A.Encounter = E.Encounter
LEFT OUTER JOIN @DischargeInstructions AS F
ON A.Encounter = F.Encounter

WHERE A.Encounter < 20000000

ORDER BY A.Encounter