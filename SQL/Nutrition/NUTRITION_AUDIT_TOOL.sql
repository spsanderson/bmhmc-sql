-- THIS REPORT WILL PERFORM AN AUDIT ON THE NUTRITIONAL SCREENING
-- FOR THE NUTRITION DEPARTMENT. A 1 = YES AND A 0 = NO.
--###################################################################//

-- VARIABLE DECLARATION AND INITIALIZATION
DECLARE @SD DATETIME;
DECLARE @ED DATETIME;
DECLARE @NOW DATETIME ;
DECLARE @MARK DATETIME;
SET @SD = '2014-09-21';
SET @ED = '2014-09-21';
SET @NOW = GETDATE();
SET @MARK = DATEADD(HH, -24, @NOW);

-- THIS CREATES A TABLE WHERE ALL THE DESIRED VISIT ID NUMBERS WILL GO
-- THIS TABLE IS A UNIQUE CLUSTER
CREATE TABLE #T1
  (
  VISIT_ID VARCHAR(20) UNIQUE CLUSTERED
  )

-- WHAT GETS INSERTED INTO #T1. IT IS QUICKER TO USE #T1 THAN @T1
INSERT INTO #T1
SELECT DISTINCT PTNO_NUM

FROM smsdss.BMH_PLM_PtAcct_V

WHERE Adm_Date BETWEEN @SD AND @ED
AND vst_start_dtime <= @MARK
AND Plm_Pt_Acct_Type = 'I'

-- INFO ON RECOMPILE 
-- http://technet.microsoft.com/en-us/library/ms190439.aspx
OPTION (RECOMPILE);

-- THIS `WITH` STATEMENT HOUSES ALL OF THE `SUB-QUERIES` WHERE WE
-- HAVE TO PULL INFORMATION FROM A VECTOR FORMAT
-- http://stackoverflow.com/questions/12552288/sql-with-clause-example
-- THIS GETS THE ANSWERS INTO A TABLE TO PULL FROM

WITH NOBS
	AS (SELECT episode_no,
		MAX(CASE
			WHEN form_usage = 'Admission'
			AND obsv_cd_ext_name = 'Body Mass Index'
			THEN dsply_val
			END) AS [BMI],
		MAX(CASE
			WHEN form_usage = 'Admission'
			AND obsv_cd_ext_name = 'Unintentional weight loss in the passt 3 - 6 months'
			THEN dsply_val
			END) AS [UNINTENDED WEIGHT LOSS],
		MAX(CASE
			WHEN form_usage = 'Admission'
			AND obsv_cd_ext_name = 'Acute disease effect'
			THEN dsply_val
			END) AS [ACUTE DISEASE EFFECT],
		MAX(CASE
			WHEN form_usage = 'Admission'
			AND obsv_cd_ext_name = 'Action based on nutritional screen score'
			THEN dsply_val
			END) AS [ACTION BASED ON SCORE],
		MAX(CASE
			WHEN form_usage = 'Admission'
			AND obsv_cd_ext_name IN (
			'Total score(nutrition screen for malnutrition)',
			'Total score of nutrition screen for the elderly'
			)
			THEN dsply_val
			END) As [TOTAL SCORE]
			
			-- DB(S) USED
			FROM smsmir.obsv
			
			-- FILTER(S) USED
			WHERE form_usage IN (
			'Nutritional Assessment',
			'Admission'
			)
			GROUP BY episode_no
		)

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++//
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++//

-- THIS IS WHERE WE QUERY THE TWO TABLES THAT WE HAVE JUST CREATED    
SELECT #T1.VISIT_ID AS [VISIT ID]
, ISNULL(NOBS.[TOTAL SCORE], 0) AS [TOTAL SCORE]
, ISNULL(NOBS.[ACTION BASED ON SCORE], 0) AS [ACTION BASED ON SCORE]
, ISNULL(NOBS.[BMI], 0) AS [BMI]
, ISNULL(NOBS.[UNINTENDED WEIGHT LOSS], 0) AS [UNINTENDED WEIGHT LOSS]
, ISNULL(NOBS.[ACUTE DISEASE EFFECT], 0) AS [ACUTE DISEASE EFFECT]

-- DB(S) USED
FROM #T1
LEFT JOIN NOBS
ON #T1.VISIT_ID = NOBS.episode_no

DROP TABLE #T1