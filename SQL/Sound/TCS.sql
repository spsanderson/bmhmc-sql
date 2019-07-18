/*
=======================================================================
INITIAL POPULATION
=======================================================================
*/
DECLARE @InitialPopulation TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, Encounter           INT
	, MRN                 INT
	, Nurse_Station       CHAR(4)
	, Pt_LastName         VARCHAR(25)
	, Pt_FirstName        VARCHAR(25)
	, Adm_Date            DATE
);

WITH CTE1 AS (
	SELECT DISTINCT(A.pt_no_num) AS pt_id
	, A.pt_med_rec_no
	, A.nurse_sta
	, A.pt_last_name
	, A.pt_first_name
	, CAST(C.Adm_Date AS DATE)   AS [Adm_Date]
	--, CAST(C.Days_Stay AS INT)   AS [LOS]
	--, A.atn_dr_name
	--, C.Pyr1_Co_Plan_Cd
	--, C.Pyr2_Co_Plan_Cd

	FROM SMSDSS.c_soarian_real_time_census_v AS A
	LEFT OUTER JOIN SMSDSS.pract_dim_v       AS B
	ON A.adm_pract_no = B.src_pract_no
		AND B.orgz_cd = 'S0X0'
	LEFT OUTER JOIN SMSDSS.BMH_PLM_PtAcct_V  AS C
	ON A.pt_no_num = C.PtNo_Num

	WHERE B.src_spclty_cd = 'HOSIM'
	AND C.Pyr2_Co_Plan_Cd = 'Z28'
	AND A.nurse_sta NOT IN ('CCU', 'SICU', 'MICU', 'ICU')
)

INSERT INTO @InitialPopulation
SELECT * FROM CTE1

--SELECT *
--FROM @InitialPopulation

/*
=======================================================================
ESRD AND BLACK LUNG EXCLUSIONS
=======================================================================
*/
DECLARE @DXExclusions TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, MRN                 INT
	, Dx_Code             VARCHAR(10)
	, RN                  INT
);

WITH CTE2 AS (
	SELECT A.med_rec_no
	, B.dx_cd
	, ROW_NUMBER() OVER (
		PARTITION BY A.med_rec_no
		ORDER BY B.dx_cd_prio
	) AS [RN]

	FROM SMSMIR.mir_pt           AS A
	INNER JOIN SMSMIR.mir_dx_grp AS B
	ON A.pt_id = B.pt_id

	WHERE B.dx_cd_type = 'DF'
	AND b.dx_cd IN (
		'585.6', 'n18.6', '500', 'j60'
	)
	AND CAST(a.med_rec_no AS INT) IN (
		SELECT A.MRN
		FROM @InitialPopulation AS A
	)

)

INSERT INTO @DXExclusions
SELECT * FROM CTE2
WHERE CTE2.RN = 1

--SELECT *
--FROM @DXExclusions

/*
=======================================================================
Dialysis Exclusions
=======================================================================
*/
DECLARE @DialysisExclusionsTable TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, Encounter           INT
	, MRN                 INT
);

WITH CTE3 AS (
	SELECT PtNo_Num
	, Med_Rec_No

	FROM SMSDSS.BMH_PLM_PtAcct_V

	WHERE hosp_svc IN ('DIA', 'DMS')
	AND Dsch_Date IS NOT NULL
	AND Med_Rec_No IN (
		SELECT MRN
		FROM @InitialPopulation
	)
)

INSERT INTO @DialysisExclusionsTable
SELECT * FROM CTE3

/*
=======================================================================
PULL IT TOGETHER
=======================================================================
*/
SELECT A.Encounter      AS [Current Encounter]
, A.MRN
, A.Nurse_Station
, A.Pt_LastName 
, A.Pt_FirstName
, A.Adm_Date
, B.[INDEX]             AS [Previous Encounter]
, B.[INITIAL DISCHARGE] AS [Previous Discharge Date]
, B.[Interim]           AS [Days Between Admissions]
, B.*

FROM @InitialPopulation          AS A
LEFT OUTER JOIN SMSDSS.vReadmits AS B
ON A.Encounter = B.[READMIT]
	AND B.INTERIM < 91

WHERE A.MRN NOT IN (
	SELECT B.MRN
	FROM @DXExclusions AS B
)
AND A.MRN NOT IN (
	SELECT C.MRN
	FROM @DialysisExclusionsTable AS C
)