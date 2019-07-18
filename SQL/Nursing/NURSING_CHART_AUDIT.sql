-- THIS REPORT WILL PERFORM AN ADMISSION ASSESSMENT FOR NURSING QUALITY
-- MANAGEMENT. IT WILL LOOK FOR ACCOUNT NUMBERS ON A DATE OR DATE RANGE
-- GIVEN BY A USER AND COLLECT THOSE VISIT ID(S) AND PERFORM THE 
-- NECESSARY AUDIT TO SEE IF ALL QUESTIONS WHERE ANSWERED. 1 = YES AND
-- 0 = NO
--###################################################################//

-- VARIABLE DECLARATION AND INITIALIZATION
DECLARE @SD DATETIME = '2013-12-01';
DECLARE @ED DATETIME = '2013-12-01';

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
AND Plm_Pt_Acct_Type = 'I'

-- INFO ON RECOMPILE 
-- http://technet.microsoft.com/en-us/library/ms190439.aspx
OPTION (RECOMPILE);
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++//
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++//

-- THIS `WITH` STATEMENT HOUSES ALL OF THE `SUB-QUERIES` WHERE WE
-- HAVE TO PULL INFORMATION FROM A VECTOR FORMAT
-- http://stackoverflow.com/questions/12552288/sql-with-clause-example
-- THIS GETS THE ANSWERS INTO A TABLE TO PULL FROM
WITH OBS
     AS (SELECT episode_no,
            MAX(CASE
                  WHEN form_usage = 'Admission' 
                  THEN 1
                END) AS [ADMIT ASSESSMENT DONE],
            MAX(CASE
                  WHEN form_usage = 'Admission'
                  AND obsv_cd_ext_name = 'Admission consent signed:'
                  AND dsply_val NOT LIKE 'NO%'
                  THEN 1
                END) AS [ADMIT CONSENT SIGNED?],
            MAX(CASE
                  WHEN form_usage = 'Admission'
                  AND obsv_cd_ext_name = 'Belongings with Patient'
                  THEN 1
                END) AS [PT BELONGINGS ADDRESSED],
			MAX(CASE
				  WHEN form_usage = 'Admission'
				  AND obsv_cd_ext_name = 'H&P Review'
				  THEN 1
				END) AS [H&P DONE],
			MAX(CASE
				  WHEN form_usage = 'Admission'
				  AND obsv_cd_ext_name = 'Past Surgical History'
				  THEN 1
				END) AS [PAST SX HX],
			MAX(CASE
				  WHEN form_usage = 'Admission'
				  AND obsv_cd_ext_name = 'Does Patient Have Pain?'
				  THEN 1
				END) AS [INITIAL PAIN DOCUMENTED],
			MAX(CASE
				  WHEN form_usage = 'Admission'
				  AND obsv_cd_ext_name = 'Acceptable level of pain'
				  THEN dsply_val
				END) AS [ACCPT PAIN LVL IDENT],
			MAX(CASE
				  WHEN form_usage = 'Admission'
				  AND obsv_cd_ext_name IN(
				  'Any cultural practices, customs or spiritual beliefs',
				  'Reason Unable to Assess'
				  )
				  THEN 1
				END) AS [CULTURAL/SPIRITUAL ADDRESSED],
			MAX(CASE
				  WHEN form_usage = 'Admission'
				  AND obsv_cd_ext_name = 'Care Management'
				  THEN 1
				END) AS [CARE MGMT SCREENING],
			MAX(CASE
				  WHEN form_usage = 'Admission'
				  AND obsv_cd_ext_name IN (
				  'Have you been hit, kicked or punched',
				  'Do you feel safe in your current relationship or environment?',
				  'Partner from previous relationship making you feel unsafe'				  
				  )
				  THEN 1
				END) AS [DOMESTIC ABUSE SCREEN],
			MAX(CASE
				  WHEN form_usage = 'Admission'
				  AND obsv_cd_ext_name IN (
				  'Past month, have been bothered by little interest or pleasure',
				  'Past month, feeling down, depressed or hopeless?'
				  )
				  THEN 1
				END) AS [DEPRESSION],
			MAX(CASE
				  WHEN form_usage = 'Admission'
				  and obsv_cd_ext_name IN (
				  'Body Mass Index',
				  'Unintentional weight loss in the past 3 - 6 months',
				  'Acute disease effect',
				  'Action based on nutritional screen score',
				  'Total score(nutrition screen for malnutrition)'
				  )
				  THEN 1
				END) AS [NUTRITION SCREENING],
			MAX(CASE
				  WHEN form_usage = 'Admission'
				  and obsv_cd_ext_name IN (
				  'Additional functional detail',
				  'Functional Screen'
				  )
				  THEN 1
				END) AS [FUNCTIONAL SCREEN],
			MAX(CASE
				  WHEN form_usage = 'Admission'
				  AND obsv_cd_ext_name IN (
				  'Tobacco use:',
				  'Do you sometimes drink beer, wine, or other alcoholic beverages?',
				  'How many times in the past year have you had: *5 or more drinks',
				  'On average, how many days a week do you have an alcoholic drink?',
				  'On a typical drinking day, how many drinks do you have?',
				  'Weekly average (Multiply above)',
				  'When was the last time you had a drink?',
				  'Do you use other non-prescription (street drugs)?',
				  'Do you use other prescription drugs?'
				  )
				  THEN 1
				END) AS [PERSONAL HABITS ADDRESSED],
			MAX(CASE
				  WHEN form_usage = 'Admission'
				  AND obsv_cd_ext_name IN (
				  'Bariatric Education Topic',
				  'Barriers to Education',
				  'Behavioral Education Topic',
				  'Cardiovascular Education Topic',
				  'Diabetes Education Topic',
				  'Discharge Education Topic',
				  'Education Given To',
				  'General Education Topic',
				  'Nutrition Education Topic',
				  'Ostomy Education Topic',
				  'Physical Therapy Education Topic',
				  'Preparation for Surgery Education Topic',
                  'Respiratory Education Topic',
				  'Speech Language Pathology Education Topic',
				  'Readiness to Learn',
				  'Teaching Methods'
				  )
				  THEN 1
				END) AS [EDU ASSMNT DONE],
			MAX(CASE
				  WHEN form_usage = 'Care Management_New'
				  AND dsply_val is not null
				  THEN 1
				END) AS [ANTICIPATED DC PLAN],
			MAX(CASE
				  WHEN form_usage = 'Post Falls Assessment'
				  AND obsv_cd_ext_name IN (
				  'Fall Precautions Initiated/In Place',
				  'Morse Fall Risk Total',
				  'Recent Fall History (within last 3 months)'
				  )
				  THEN 1
				END) AS [FALL ASSESSMENT]
         
         -- DB(S) USED           
         FROM smsmir.obsv
		 
		 -- FILTER(S) USED
         WHERE form_usage IN (
							 'Admission',
							 'Care Management_New',
							 'Post Falls Assessment'
							 )
         GROUP BY episode_no
		 )
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++//
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++//

-- THIS IS WHERE WE QUERY THE TWO TABLES THAT WE HAVE JUST CREATED    
SELECT #T1.VISIT_ID AS [VISIT ID]
, CASE
    WHEN QOC.prim_lng IS NOT NULL
        THEN 1
        ELSE 0
    END AS [PREF LANG COMPLETE?]
, QOC.ht_chtd_ind AS [HT IND]
, QOC.wt_chtd_ind AS [WT IND]
, QOC.adv_dir_ind AS [ADV DIRECTIVE]
, QOC.pn_immun AS [PN IMM IND]
, QOC.flu_immun AS [FLU IMM IND]
, QOC.home_meds_chtd_ind AS [HOME MEDS CHARTED IND]
, ISNULL(OBS.[ADMIT ASSESSMENT DONE], 0) AS [ADMIT ASSESSMENT DONE]
, ISNULL(OBS.[ADMIT CONSENT SIGNED?], 0) AS [ADMIT CONSENT SIGNED?]
, ISNULL(OBS.[PT BELONGINGS ADDRESSED], 0) AS [PT BELONGINGS ADDRESSED]
, ISNULL(OBS.[H&P DONE], 0) AS [H&P DONE]
, ISNULL(OBS.[PAST SX HX], 0) AS [PAST SX HX]
, ISNULL(OBS.[INITIAL PAIN DOCUMENTED], 0) AS [INITIAL PAIN DOCUMENTED]
, ISNULL(OBS.[ACCPT PAIN LVL IDENT], 0) AS [ACCPT PAIN LVL IDENT]
, ISNULL(OBS.[CULTURAL/SPIRITUAL ADDRESSED], 0) AS [CULTURAL/SPIRITUAL ADDRESSED]
, ISNULL(OBS.[CARE MGMT SCREENING], 0) AS [CARE MGMT SCREENING]
, ISNULL(OBS.[DOMESTIC ABUSE SCREEN], 0) AS [DOMESTIC ABUSE SCREEN]
, ISNULL(OBS.[DEPRESSION], 0) AS [DEPRESSION]
, ISNULL(OBS.[NUTRITION SCREENING], 0) AS [NUTRITION SCREENING]
, ISNULL(OBS.[FUNCTIONAL SCREEN], 0) AS [FUNCTIONAL SCREEN]
, ISNULL(OBS.[PERSONAL HABITS ADDRESSED], 0) AS [PERSONAL HABITS ADDRESSED]
, ISNULL(OBS.[EDU ASSMNT DONE], 0) AS [EDU ASSMNT DONE]
, ISNULL(OBS.[ANTICIPATED DC PLAN], 0) AS [ANTICIPATED DC PLAN]
, ISNULL(OBS.[FALL ASSESSMENT], 0) AS [FALL ASSESSMENT]

-- DB(S) USED       
FROM smsdss.QOC_vst_summ QOC
JOIN #T1
ON #T1.VISIT_ID = QOC.episode_no
LEFT JOIN OBS
ON OBS.episode_no = QOC.episode_no 

DROP TABLE #T1