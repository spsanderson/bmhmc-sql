-- READMISSIONS DATA FOR THE LAST 12 MONTHS MAY 1 2012 THROUGH APRIL 30 2013
-- REQUESTED BY PHYLLIS HARTMANN
--##########################################################################################################
-- COLUMN SELECTION
-- INITIAL ENCOUNTERS
SELECT pt_no AS 'INITIAL ENCOUNTER'
, med_rec_no, pt_name AS 'PT NAME'
, adm_src_desc AS 'INITIAL ADM SOURCE'
, adm_date AS 'INITIAL ADM DATE'
, dsch_date AS 'INITIAL DISC DATE'
, DATEDIFF(DD,ADM_DATE,DSCH_DATE) AS 'INITIAL LOS'
, CASE WHEN pyr1_co_plan_cd = '*' THEN 'SELF PAY' ELSE pyr1_co_plan_cd END AS 'INITIAL INSURANCE'
, mdc_name AS 'INITIAL MDC'
, drg_no AS 'INITIAL DRG'
, clasf_desc AS 'INITAL DX CLASF'
, Admit_Adm_Dr_Name AS 'INITIAL ADMIT DR'
, Admit_Atn_Dr_Name AS 'INITIAL ATTENDING'
, hosp_svc AS 'INITIAL HOSPITAL SVC'
, Days_To_Readmit,

-- READMISSION ENCOUNTERS 
B_Pt_No AS 'READMIT ENCOUNTER'
, B_Adm_Src_Desc AS 'READMIT SOURCE'
, B_Adm_Date AS 'READMIT DATE'
, B_Dsch_Date AS 'READMIT DISC DATE'
, DATEDIFF(DD,B_ADM_DATE,B_DSCH_DATE) AS 'READMIT LOS'
, CASE WHEN B_Pyr1_Co_Plan_Cd = '*' THEN 'SELF PAY' ELSE B_Pyr1_Co_Plan_Cd END AS 'READMIT INSURANCE'
, B_Mdc_Name AS 'READMIT MDC'
, B_Drg_No AS 'READMIT DRG'
, B_Clasf_Desc AS 'READMIT DX CLASF'
, B_Readm_Adm_Dr_Name AS 'READMIT ADMITTING DR'
, B_Readm_Atn_Dr_Name AS 'READMIT ATTENDING DR'
, B_Hosp_Svc AS 'READMIT HOSP SVC'

-- DB USED
FROM smsdss.c_readmissions_v

-- FILTERS USED
WHERE B_Adm_Date BETWEEN '2012-05-01' AND '2013-04-30'
AND adm_src_desc != 'SCHEDULED ADMISSION'
AND pt_no < 20000000
AND B_Adm_Src_Desc != 'SCHEDULED ADMISSION'
AND B_Pt_No < 20000000

--###########################################################################################################
-- END REPORT.
-- NAME: SANDERSON, STEVEN
-- DEPT: PERFORMANCE IMPROVEMENT
-- DATE: MAY 21 2013
-- FOR : PHYLLIS HARTMANN
