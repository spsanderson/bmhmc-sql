/*
=======================================================================
Get the initial patient population for Pneumonia
=======================================================================
*/

DECLARE @INIT_POP TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, [Encounter Number]  INT
	, [Encounter Type]    VARCHAR(30)
	, [Prin Dx Code]      VARCHAR(15)
	, [Prin Dx Desc]      VARCHAR(MAX)
	, [MRN]               INT
);

WITH CTE AS (
	SELECT DISTINCT(A.pt_id) AS PT_ID
	, CASE
		WHEN A.pt_id >= '000080000000'
			AND A.pt_id < '000090000000'
			THEN 'ER'
		WHEN A.pt_id < '000020000000'
			AND B.Adm_Source NOT IN ('RA', 'RP')
			THEN 'Inpatient Admit From ER'
		WHEN A.pt_id < '000020000000'
			AND B.Adm_Source IN ('RA', 'RP')
			THEN 'Direct Admit'
		ELSE B.Adm_Source
	  END AS [Encounter Type]
	, B.prin_dx_cd
	, C.clasf_desc AS 'Prin_Dx_Desc'
	, B.Med_Rec_No

	FROM smsmir.mir_dx_grp                  AS A
	LEFT OUTER JOIN smsdss.BMH_PLM_PtAcct_V AS B
	ON A.pt_id = B.Pt_No 
	AND A.unit_seq_no = B.unit_Seq_no
	LEFT OUTER JOIN smsmir.mir_clasf_mstr   AS C
	ON B.prin_dx_cd = C.clasf_cd

	WHERE (
			b.prin_dx_cd IN (
				-- ICD-9
				'480', '480.1', '480.2', '480.3', '480.8', '480.9', '481', '482', 
				'482.1', '482.2', '482.3', '482.31', '482.32', '482.39', '482.4', 
				'482.41', '482.42', '482.49', '482.81', '482.82', '482.83', 
				'482.89', '482.9', '483', '483.1', '483.8', '484.1', '484.3', 
				'484.5', '484.6', '484.7', '484.8', '517.1', '485', '486', '507', 
				'507.1', '507.8', '506', 
				-- ICD-10 CODES
				'J12.0', 'j12.1', 'J12.2', 'J12.81', 'J12.89', 'J12.9', 'J13', 
				'J18.1', 'J15.0', 'J15.1', 'J14', 'J15.4', 'J15.4', 'J15.3', 
				'J15.4', 'J15.20', 'J15.211', 'J15.212', 'J15.29', 'J15.8', 
				'J15.5', 'J15.6', 'J15.8', 'J15.9', 'J15.7', 'J16.0', 'J16.8', 
				'B25.0', 'A37.91', 'A22.1', 'B44.0', 'J17', 'J17', 'J17', 
				'J18.0', 'J18.9', 'J69.0', 'J69.1', 'J69.8', 'J68.0'
			)
	)
	AND (
		b.PtNo_Num BETWEEN '10000000' AND '19999999'
		OR 
		b.PtNo_Num BETWEEN '80000000' AND '99999999'
	)
	AND b.Adm_Date >= '2015-01-01' 
	AND b.Adm_Date < '2016-01-01'
	AND B.User_Pyr1_Cat IN ('AAA')
	AND b.Pt_No IN (
		SELECT DISTINCT(pt_id)
		FROM smsmir.mir_actv
		WHERE LEFT(actv_cd,3) = '046'
		AND chg_tot_amt <> '0'
	)
)

INSERT INTO @INIT_POP
SELECT *
FROM CTE C1

--SELECT * FROM @INIT_POP

/*
=======================================================================
This will get the readmit id number, dx code and dx description. The
readmit will be within 30 days and can be a scheduled readmission
=======================================================================
*/
DECLARE @READMIT_POP TABLE (
	PK INT IDENTITY(1, 1)  PRIMARY KEY
	, [Initial Encounter]  INT
	, [Readmit Encounter]  INT
	, [Readmit Dx Code]    VARCHAR(20)
	, [Readmit Dx Desc]    VARCHAR(MAX)
	, [Days Until Readmit] INT
);

WITH CTE2 AS (
	SELECT A.[INDEX]
	, A.[READMIT]
	, B.prin_dx_cd
	, C.clasf_desc
	, A.[INTERIM]

	FROM smsdss.vReadmits                    AS A
	INNER MERGE JOIN SMSDSS.BMH_PLM_PtAcct_V AS B
	ON A.[READMIT] = B.PtNo_Num
	INNER JOIN SMSMIR.mir_clasf_mstr         AS C
	ON B.prin_dx_cd = C.clasf_cd

	WHERE C.clasf_schm IN ('9','0')
	AND B.Adm_Date >= '2015-01-01'
	AND B.User_Pyr1_Cat IN ('AAA')
	AND A.[INTERIM] < 31
	AND (
		B.prin_dx_cd IN (
		-- AMI
		-- ICD-9
		'410', '410.01', '401.02', '410.1', '410.11', '410.12', 
		'410.2', '410.21', '410.22', '410.3', '410.31', '410.32', 
		'410.4', '410.41', '410.42', '410.5', '410.51', '410.52', 
		'410.6', '410.61', '410.62', '410.7', '410.71', '410.72', 
		'410.8', '410.81', '410.82', '410.9', '410.91', '410.92', 
		'997.1', 
		-- ICD-10 CODES
		'i21.09', 'i21.09', 'I21.09', 'I21.09', 'I21.09', 'I21.09', 
		'I21.09', 'I21.09', 'I21.09', 'I21.11', 'I21.11', 'I21.11', 
		'I21.19', 'I21.19', 'I21.19', 'I21.29', 'I21.29', 'I21.29', 
		'I21.29', 'I21.29', 'I21.29', 'I21.4', 'I21.4', 'I21.4', 
		'I21.29', 'I21.29', 'I21.29', 'I21.3', 'I21.3', 'I21.3', 
		'I97.190',

		-- CHF
		-- ICD-9 CODES
		'428.0','428.1','428.20','428.21','428.22',
		'428.23','428.30','428.31','428.32','428.33','428.40',
		'428.41','428.42','428.43','428.9','429.4','402.01',
		'402.11','402.91','404.91','404.93',
		-- ICD-10 CODES
		'I50.9', 'I50.1', 'I50.20', 'I50.21', 'I50.22', 'I50.23', 
		'I50.30', 'I50.31', 'I50.32', 'I50.33', 'I50.40', 'I50.41', 
		'I50.42', 'I50.43', 'I97.0', 'I97.110', 'I97.130', 'I197.190', 
		'I11.0', 'I13.0', 'I13.2',

		-- Pneumonia
		-- ICD-9
		'480', '480.1', '480.2', '480.3', '480.8', '480.9', '481', '482', 
		'482.1', '482.2', '482.3', '482.31', '482.32', '482.39', '482.4', 
		'482.41', '482.42', '482.49', '482.81', '482.82', '482.83', 
		'482.89', '482.9', '483', '483.1', '483.8', '484.1', '484.3', 
		'484.5', '484.6', '484.7', '484.8', '517.1', '485', '486', '507', 
		'507.1', '507.8', '506', 
		-- ICD-10 CODES
		'J12.0', 'j12.1', 'J12.2', 'J12.81', 'J12.89', 'J12.9', 'J13', 
		'J18.1', 'J15.0', 'J15.1', 'J14', 'J15.4', 'J15.4', 'J15.3', 
		'J15.4', 'J15.20', 'J15.211', 'J15.212', 'J15.29', 'J15.8', 
		'J15.5', 'J15.6', 'J15.8', 'J15.9', 'J15.7', 'J16.0', 'J16.8', 
		'B25.0', 'A37.91', 'A22.1', 'B44.0', 'J17', 'J17', 'J17', 
		'J18.0', 'J18.9', 'J69.0', 'J69.1', 'J69.8', 'J68.0'
		)
		OR 
		(
			-- COPD
			-- icd-9 codes
			B.prin_dx_cd BETWEEN '491.0' AND '491.22'
			OR 
			B.prin_dx_cd BETWEEN '493.20' AND '493.22'
			OR 
			B.prin_dx_cd ='496'
			-- icd-10 codes
			OR B.prin_dx_cd IN (
			'J41.0', 'J41.1', 'J44.9', 'J44.1', 'J44.0', 
			'J44.9', 'J44.0', 'J44.1', 'J44.9'
			)
		)
	)
)

INSERT INTO @READMIT_POP
SELECT *
FROM CTE2

--SELECT * FROM @READMIT_POP

/*
=======================================================================
ED Utilization where Pneumonia is listed as the principal diagnosis
=======================================================================
*/
DECLARE @PN_ED_TMP TABLE (
	PK INT IDENTITY(1, 1)   PRIMARY KEY
	, [ED Encounter Number] INT
);

WITH CTE3 AS (
	SELECT DISTINCT(a.Pt_No) AS PT_ID

	FROM SMSDSS.BMH_PLM_PtAcct_V       AS A
	INNER MERGE JOIN SMSMIR.mir_dx_grp AS B
	ON A.Pt_No = B.pt_id
	INNER JOIN SMSMIR.mir_clasf_mstr   AS C
	ON A.prin_dx_cd = C.clasf_cd

	WHERE (
		a.prin_dx_cd IN (
			-- ICD-9
			'480', '480.1', '480.2', '480.3', '480.8', '480.9', '481', '482', 
			'482.1', '482.2', '482.3', '482.31', '482.32', '482.39', '482.4', 
			'482.41', '482.42', '482.49', '482.81', '482.82', '482.83', 
			'482.89', '482.9', '483', '483.1', '483.8', '484.1', '484.3', 
			'484.5', '484.6', '484.7', '484.8', '517.1', '485', '486', '507', 
			'507.1', '507.8', '506', 
			-- ICD-10 CODES
			'J12.0', 'j12.1', 'J12.2', 'J12.81', 'J12.89', 'J12.9', 'J13', 
			'J18.1', 'J15.0', 'J15.1', 'J14', 'J15.4', 'J15.4', 'J15.3', 
			'J15.4', 'J15.20', 'J15.211', 'J15.212', 'J15.29', 'J15.8', 
			'J15.5', 'J15.6', 'J15.8', 'J15.9', 'J15.7', 'J16.0', 'J16.8', 
			'B25.0', 'A37.91', 'A22.1', 'B44.0', 'J17', 'J17', 'J17', 
			'J18.0', 'J18.9', 'J69.0', 'J69.1', 'J69.8', 'J68.0'
		)
	)
	AND (
		a.Pt_No BETWEEN '000010000000' AND '000019999999'
		OR 
		a.Pt_No BETWEEN '000080000000' AND '000099999999'
	)
	AND a.adm_date >= '2015-01-01' 
	AND a.Adm_Date <= '2016-01-01'
	AND A.User_Pyr1_Cat IN ('AAA')
	AND a.Pt_No IN (
		SELECT DISTINCT(pt_id)
		FROM smsmir.mir_actv
		WHERE LEFT(actv_cd,3) = '046'
		AND chg_tot_amt <> '0'
	)
)
-- Insert all of the above into the temp table
INSERT INTO @PN_ED_TMP
SELECT *
FROM CTE3

--SELECT * FROM @COPD_ED_TMP

-----------------------------------------------------------------------
DECLARE @PN_ED_STAGING TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, [Encounter Number]  INT
	, [MRN]               INT
	, [Visit Count]       INT
);

WITH CTE4 AS (
	SELECT A.[ED Encounter Number]
	, B.Med_Rec_No
	, RN = ROW_NUMBER() OVER(
		PARTITION BY B.MED_REC_NO 
		ORDER BY A.[ED Encounter Number]
	)

	FROM @PN_ED_TMP                          AS A
	INNER MERGE JOIN SMSDSS.BMH_PLM_PTACCT_V AS B
	ON A.[ED Encounter Number] = B.PtNo_Num

	WHERE B.User_Pyr1_Cat IN ('AAA')
	AND B.Adm_Date >= '2015-01-01'
	AND B.Adm_Date < '2016-01-01'
	AND B.prin_dx_cd IS NOT NULL
)

INSERT INTO @PN_ED_STAGING
SELECT *
FROM CTE4

--SELECT * FROM @PN_ED_STAGING

-----------------------------------------------------------------------
DECLARE @PN_ED TABLE (
	PK INT IDENTITY(1, 1)   PRIMARY KEY
	, [ED Encounter Number] INT
	, [MRN]                 INT
	, [ED PN Visit Count]   INT
);
-- Insert all of the following into the final COPD ED Count table
INSERT INTO @PN_ED
SELECT *
FROM (
	SELECT EDS.[Encounter Number]
	, EDS.MRN
	, MAX_VISIT

	FROM @PN_ED_STAGING EDS
	INNER JOIN (
		SELECT EDS.MRN, MAX(EDS.[Visit Count]) AS MAX_VISIT
		FROM @PN_ED_STAGING EDS
		GROUP BY EDS.MRN
	) groupedEDVisits
	ON EDS.[MRN] = groupedEDVisits.MRN
	AND EDS.[Visit Count] = groupedEDVisits.MAX_VISIT
) A

--SELECT * FROM @COPD_ED E

/*
=======================================================================
Get a total count of ed visits. From here we can then in the final 
select statment just do a simple subtraction to get how many ED visits
a patient has where Pneumonia is not listed.
=======================================================================
*/
DECLARE @ER_VISIT_COUNT_TMP TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, MRN                 INT
	, VISIT_ID            VARCHAR(MAX)
	, VISIT_DATE          DATETIME
	, ED_VISIT_COUNT      INT
)

INSERT INTO @ER_VISIT_COUNT_TMP
SELECT
A.MRN
, A.VISIT_ID
, A.VISIT_DATE
, [ED Visit Count] = ROW_NUMBER() OVER(PARTITION BY MRN ORDER BY VISIT_DATE)

FROM
(
	SELECT MED_REC_NO AS MRN
	, PtNo_Num AS VISIT_ID
	, VST_START_DTIME AS VISIT_DATE

	FROM smsdss.BMH_PLM_PtAcct_V

	WHERE (
			(
			PLM_PT_ACCT_TYPE = 'I'
			AND ADM_SOURCE NOT IN (
				'RP'
			)
		)
		OR PT_TYPE = 'E'
	)
	AND vst_start_dtime >= '2015-01-01' 
	AND vst_start_dtime <  '2016-01-01'
	AND prin_dx_cd IS NOT NULL
)A

DECLARE @ER_TOT_CNT TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, [Visit ID]          INT
	, [MRN]               INT
	, [Total Count]       INT
) 

INSERT INTO @ER_TOT_CNT
SELECT *
FROM (
	SELECT ET.VISIT_ID
	, ET.[MRN]
	, ET.ED_VISIT_COUNT

	FROM @ER_VISIT_COUNT_TMP ET
	INNER JOIN (
		SELECT EDTMP.MRN, MAX(EDTMP.ED_VISIT_COUNT) AS MAX_VISIT
		FROM @ER_VISIT_COUNT_TMP EDTMP
		GROUP BY MRN
	) groupedERVisits
	ON ET.MRN = groupedERVisits.MRN
	AND ET.ED_VISIT_COUNT = groupedERVisits.MAX_VISIT
) B

/*
=======================================================================
Get the following counts for the time period
Inpatient Count for one of the listed condition
=======================================================================
*/
DECLARE @IP_Count TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, MRN                 INT
	, [Admit_Count]       INT
)

INSERT INTO @IP_Count
SELECT A.*
FROM (
	SELECT plm.Med_Rec_No
	, COUNT(plm.Med_Rec_No) AS [30 day ra count]

	FROM smsdss.BMH_PLM_PtAcct_V AS PLM

	WHERE PLM.Adm_Date >= '2015-01-01'
	AND PLM.Adm_Date < '2016-01-01'
	AND PLM.prin_dx_cd IS NOT NULL
	AND PLM.tot_chg_amt > 0
	AND (
		PLM.prin_dx_cd IN (
		---- AMI
		---- ICD-9
		--'410', '410.01', '401.02', '410.1', '410.11', '410.12', 
		--'410.2', '410.21', '410.22', '410.3', '410.31', '410.32', 
		--'410.4', '410.41', '410.42', '410.5', '410.51', '410.52', 
		--'410.6', '410.61', '410.62', '410.7', '410.71', '410.72', 
		--'410.8', '410.81', '410.82', '410.9', '410.91', '410.92', 
		--'997.1', 
		---- ICD-10 CODES
		--'i21.09', 'i21.09', 'I21.09', 'I21.09', 'I21.09', 'I21.09', 
		--'I21.09', 'I21.09', 'I21.09', 'I21.11', 'I21.11', 'I21.11', 
		--'I21.19', 'I21.19', 'I21.19', 'I21.29', 'I21.29', 'I21.29', 
		--'I21.29', 'I21.29', 'I21.29', 'I21.4', 'I21.4', 'I21.4', 
		--'I21.29', 'I21.29', 'I21.29', 'I21.3', 'I21.3', 'I21.3', 
		--'I97.190',

		---- CHF
		---- ICD-9 CODES
		--'428.0','428.1','428.20','428.21','428.22',
		--'428.23','428.30','428.31','428.32','428.33','428.40',
		--'428.41','428.42','428.43','428.9','429.4','402.01',
		--'402.11','402.91','404.91','404.93',
		---- ICD-10 CODES
		--'I50.9', 'I50.1', 'I50.20', 'I50.21', 'I50.22', 'I50.23', 
		--'I50.30', 'I50.31', 'I50.32', 'I50.33', 'I50.40', 'I50.41', 
		--'I50.42', 'I50.43', 'I97.0', 'I97.110', 'I97.130', 'I197.190', 
		--'I11.0', 'I13.0', 'I13.2',

		-- Pneumonia
		-- ICD-9
		'480', '480.1', '480.2', '480.3', '480.8', '480.9', '481', '482', 
		'482.1', '482.2', '482.3', '482.31', '482.32', '482.39', '482.4', 
		'482.41', '482.42', '482.49', '482.81', '482.82', '482.83', 
		'482.89', '482.9', '483', '483.1', '483.8', '484.1', '484.3', 
		'484.5', '484.6', '484.7', '484.8', '517.1', '485', '486', '507', 
		'507.1', '507.8', '506', 
		-- ICD-10 CODES
		'J12.0', 'j12.1', 'J12.2', 'J12.81', 'J12.89', 'J12.9', 'J13', 
		'J18.1', 'J15.0', 'J15.1', 'J14', 'J15.4', 'J15.4', 'J15.3', 
		'J15.4', 'J15.20', 'J15.211', 'J15.212', 'J15.29', 'J15.8', 
		'J15.5', 'J15.6', 'J15.8', 'J15.9', 'J15.7', 'J16.0', 'J16.8', 
		'B25.0', 'A37.91', 'A22.1', 'B44.0', 'J17', 'J17', 'J17', 
		'J18.0', 'J18.9', 'J69.0', 'J69.1', 'J69.8', 'J68.0'
		)
		--OR 
		--(
		--	-- COPD
		--	-- icd-9 codes
		--	PLM.prin_dx_cd BETWEEN '491.0' AND '491.22'
		--	OR 
		--	PLM.prin_dx_cd BETWEEN '493.20' AND '493.22'
		--	OR 
		--	PLM.prin_dx_cd ='496'
		--	-- icd-10 codes
		--	OR PLM.prin_dx_cd IN (
		--	'J41.0', 'J41.1', 'J44.9', 'J44.1', 'J44.0', 
		--	'J44.9', 'J44.0', 'J44.1', 'J44.9'
		--	)
		--)
	)

	GROUP BY plm.Med_Rec_No
) A

/*
=======================================================================
This will join the tables together
=======================================================================
*/

SELECT IP.[Encounter Number]
, IP.[Encounter Type]
, IP.[Prin Dx Code]
, IP.[Prin Dx Desc]
, IP.[MRN]
, RP.[Readmit Encounter]
, RP.[Readmit Dx Code]
, RP.[Readmit Dx Desc]
, RP.[Days Until Readmit]
, CED.[ED PN Visit Count]
, (
   ERTOT.[Total Count] -
   CED.[ED PN Visit Count]
  )                       AS [Non PN ER Visits]
, ERTOT.[Total Count]     AS [Total ER Visits]
, IPC.Admit_Count         AS [Total PN Inpatient Count]

FROM @INIT_POP            AS IP
LEFT JOIN @READMIT_POP    AS RP
ON IP.[Encounter Number] = RP.[Initial Encounter]
LEFT JOIN @PN_ED          AS CED
ON IP.[MRN] = CED.[MRN]
LEFT JOIN @ER_TOT_CNT     AS ERTOT
ON IP.[MRN] = ERTOT.[MRN]
LEFT JOIN @IP_Count       AS IPC
ON IP.MRN = IPC.MRN

ORDER BY IP.[MRN]
, IP.[Encounter Number]

