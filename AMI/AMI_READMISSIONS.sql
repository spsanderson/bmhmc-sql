-- COPD DATA ON READMISSIONS FOR DRG 280, 281, 282
-- REQUESTED BY PHYLLIS HARTMANN
--#####################################################################

DECLARE @STARTDATE DATETIME
DECLARE @ENDATE DATETIME

SET @STARTDATE = '2010-01-01';
SET @ENDATE = '2013-04-30';

-- COLUMN SELECTION
-- INITIAL VISIT
SELECT pt_no AS 'VISIT ID'
, med_rec_no AS 'MRN'
, pt_name AS 'PT NAME'
, adm_src_desc AS 'ADM SOURCE DES'
, adm_date AS 'INITIAL ADMIT'
, dsch_date AS 'INITIAL DISC'
, days_stay AS 'LOS'
, drg_no AS 'DRG'
, mdc_name AS 'MDC NAME'
, clasf_desc AS' CLASF DESCRIPTION'
, Admit_Adm_Dr_Name 'INITIAL ADMITTING'
, Admit_Atn_Dr_Name 'INITIAL ATTENDING'
, Days_To_Readmit 'INTERIM'
-- READMISSION VISIT
, B_Pt_No AS 'READMIT VISIT ID'
, B_Med_Rec_No AS 'READMIT MRN'
, B_Adm_Src_Desc AS 'READMIT SRC DES'
, B_Adm_Date AS 'READMIT ADM'
, B_Dsch_Date AS 'READMIT DISC'
, B_Days_Stay AS 'READMIT LOS'
, B_Drg_No AS 'READMIT DRG'
, B_Mdc_Name AS 'READMIT MDC'
, B_Clasf_Desc AS 'READMIT CLSF DESC'
, B_Readm_Adm_Dr_Name AS 'READMIT ADMITTING'
, B_Readm_Atn_Dr_Name AS 'READMIT ATTENDING'
, CASE
    WHEN B_Admit_Denial_Amt IS NULL
    THEN 0
    ELSE B_Admit_Denial_Amt
    END AS 'DENIAL AMT'

-- DB(S) USED
FROM smsdss.c_readmissions_v

-- FILTERS
--WHERE B_Drg_No IN (280, 281, 282)
WHERE B_Adm_Date BETWEEN @STARTDATE AND @ENDATE

--#####################################################################
-- END REPORT.
-- NAME: SANDERSON, STEVEN
-- DEPT: PERFORMANCE IMPROVEMENT
-- DATE: MAY 30 2013
-- FOR : PHYLLIS HARTMANN