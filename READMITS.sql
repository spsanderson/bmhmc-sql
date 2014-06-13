
-- COLUMN SELECTION
-- INITIAL ENCOUNTERS
SELECT pt_no                      AS [INITIAL ENCOUNTER]
, med_rec_no
, pt_name                         AS [PT NAME]
, adm_src_desc                    AS [INITIAL ADM SOURCE]
, adm_date                        AS [INITIAL ADM DATE]
, dsch_date                       AS [INITIAL DISC DATE]
, DATEPART(MONTH,adm_date)        AS [INITIAL MONTH]
, DATEPART(YEAR, adm_date)        AS [INITIAL YEAR]
, days_stay                       AS [INITIAL LOS]
, CASE 
    WHEN pyr1_co_plan_cd = '*' 
	THEN 'SELF PAY]'
	ELSE pyr1_co_plan_cd END      AS [INITIAL INSURANCE]
, mdc_name                        AS [INITIAL MDC]
, drg_no                          AS [INITIAL DRG]
, clasf_desc                      AS [INITAL DX CLASF]
, Admit_Adm_Dr_Name               AS [INITIAL ADMIT DR]
, Admit_Atn_Dr_Name               AS [INITIAL ATTENDING]
, hosp_svc                        AS [INITIAL HOSPITAL SVC]
, Days_To_Readmit,

-- READMISSION ENCOUNTERS 
B_Pt_No                               AS [READMIT ENCOUNTER]
, B_Adm_Src_Desc                      AS [READMIT SOURCE]
, B_Adm_Date                          AS [READMIT DATE]
, B_Dsch_Date                         AS [READMIT DISC DATE]
, DATEPART(MONTH, B_Dsch_Date)        AS [READMIT MONTH]
, DATEPART(YEAR, B_Dsch_Date)         AS [READMIT YEAR]
, B_Days_Stay                         AS [READMIT LOS]
, CASE 
    WHEN B_Pyr1_Co_Plan_Cd = '*' 
	THEN 'SELF PAY'
	ELSE B_Pyr1_Co_Plan_Cd END        AS [READMIT INSURANCE]
, B_Mdc_Name                          AS [READMIT MDC]
, B_Drg_No                            AS [READMIT DRG]
, B_Clasf_Desc                        AS [READMIT DX CLASF]
, B_Readm_Adm_Dr_Name                 AS [READMIT ADMITTING DR]
, B_Readm_Atn_Dr_Name                 AS [READMIT ATTENDING DR]
, B_Hosp_Svc                          AS [READMIT HOSP SVC]

-- DB USED
FROM smsdss.c_readmissions_v

-- FILTERS USED
WHERE B_Adm_Date BETWEEN '2014-04-01' AND '2014-04-30'
AND adm_src_desc != 'SCHEDULED ADMISSION'
AND pt_no < 20000000
AND B_Adm_Src_Desc != 'SCHEDULED ADMISSION'
AND B_Pt_No < 20000000

