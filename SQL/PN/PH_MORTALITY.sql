-- COPD DATA ON MORTALITY, LOS FOR DRG 291, 292, 293
-- REQUESTED BY PHYLLIS HARTMANN
--#####################################################################
-- VARIABLE DECLARATION AND INITIALIZATION
DECLARE @SD DATETIME
DECLARE @ED DATETIME

SET @SD = '2014-01-01';
SET @ED = '2014-01-31';

--COLUMN SELECTION
SELECT PAV.PtNo_Num AS 'VISIT ID'
, PAV.Med_Rec_No AS 'MRN'
, PAV.Pt_Name AS 'PT NAME'
, PAV.Pt_Age AS 'AGE'
, PAV.hosp_svc AS 'HOSP SVC'
, PAV.Adm_Dr_No AS 'ADM DR NO'
, PDV.pract_rpt_name AS 'ADMITTING DR'
-- WHEN THE FOLLOWING = 0 THAT MEANS THERE IS NO SOI GIVEN
, CASE
    WHEN PP.bl_drg_soi_ind IS NULL
    THEN 0
    ELSE PP.bl_drg_soi_ind 
    END AS 'SEVERITY'
, CASE 
    WHEN VR.mortality_cd IS NULL 
    THEN 0 
    ELSE VR.mortality_cd 
    END AS 'MORTALITY'
, VR.drg_no AS 'DRG'
, VR. drg_std_days_stay AS 'DRG LOS'
, PAV.Days_Stay AS 'ACT LOS'
-- IF THE FOLLOWING IS POSITIVE THEN IT MEANS THE PATIENT HAS STAYED
-- LONGER THAN THE DRG STANDARD AMOUNT OF DAYS
, PAV.Days_Stay - VR.drg_std_days_stay AS 'DRG LOS - ACT LOS'
, CASE
    WHEN APV.src_adm_prio = 'N'
        THEN 'NEWBORN'
    WHEN APV.src_adm_prio = 'O'
        THEN 'UNKNOWN'
    WHEN APV.src_adm_prio = 'P' 
      OR APV.src_adm_prio = 'S'
      OR APV.src_adm_prio = 'U'
        THEN 'URGENT'
    WHEN APV.src_adm_prio = 'R'
        THEN 'ELECTIVE'
    WHEN APV.src_adm_prio = 'X'
        THEN 'EMERGENT'
    ELSE APV.src_adm_prio
    END AS 'ADMIT PRIO DESC'
, PMS.days_denied AS 'DAYS DENIED'
, VR.adm_dtime AS 'ADMIT'
, VR.dsch_dtime AS 'DISC'
, DATEPART(MM,VR.adm_date) AS 'ADMIT MONTH'
, DATEPART(YYYY, VR.adm_date) AS 'ADMIT YEAR'
, DATEPART(MM,VR.DSCH_DATE) AS 'DISC MONTH'
, DATEPART(YYYY,VR.DSCH_DATE) AS 'DISC YEAR'

-- DB(S) USED
FROM smsdss.BMH_PLM_PtAcct_V PAV
JOIN smsmir.vst_rpt VR
ON PAV.PtNo_Num = VR.acct_no
JOIN smsdss.pract_dim_v PDV
ON PDV.src_pract_no = PAV.Adm_Dr_No
JOIN smsmir.pyr_plan PP
ON PP.pt_id = PAV.Pt_No
JOIN smsdss.pms_case1_fct_v PMS
ON PAV.PtNo_Num = PMS.pt_no
JOIN smsdss.adm_prio_dim_v APV
ON PMS.adm_prio = APV.src_adm_prio

-- FILTERS
WHERE PDV.orgz_cd = 'S0X0'
AND PAV.Adm_Date BETWEEN @SD AND @ED
AND VR.drg_no IN (193, 194, 195)
AND PP.pyr_seq_no = 0
AND APV.orgz_cd = 'S0X0'
AND PAV.Plm_Pt_Acct_Type = 'I'
ORDER BY VR.adm_dtime

--#####################################################################
-- END REPORT.
-- NAME: SANDERSON, STEVEN
-- DEPT: PERFORMANCE IMPROVEMENT
-- DATE: JUNE 6 2013
-- FOR : PHYLLIS HARTMANN
