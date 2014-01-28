DECLARE @SD AS DATE;
DECLARE @ED AS DATE;
SET @SD = '2011-01-01';
SET @ED = '2013-12-31';

;WITH cte AS 
(
  SELECT B_Episode_No AS [READMIT ENCOUNTER]
    , B_Name AS NAME
    , B_Med_Rec_No AS MRN
    , CASE WHEN VR.mortality_cd IS NULL THEN 0
           ELSE 1
           END AS [MORTALITY CODE]
    , B_Adm_Src_Desc AS [READMIT SOURCE]
    , CAST(B_Adm_Date AS DATE) AS [READMIT DATE]
    , CAST(B_Dsch_Date AS DATE) AS [READMIT DISC DATE]
    , DATEPART(MONTH, B_Dsch_Date) AS [READMIT DISC MONTH]
    , DATEPART(YEAR, B_Dsch_Date) AS [READMIT DISC YEAR]
    , B_Days_Stay AS LOS
    , B_Days_To_Readmit AS INTERIM
    , CASE WHEN B_Pyr1_Co_Plan_Cd = '*' THEN 'SELF PAY' 
           ELSE B_Pyr1_Co_Plan_Cd END AS [READMIT INSURANCE]
    , B_Mdc_Name AS [READMIT MDC]
    , B_Drg_No AS [READMIT DRG]
    , B_Clasf_Desc AS [READMIT DX CLASF]
    , B_Readm_Adm_Dr_Name AS [READMIT ADMITTING DR]
    , B_Readm_Atn_Dr_Name AS [READMIT ATTENDING DR]
    , B_Hosp_Svc AS [READMIT HOSP SVC]
    , rn = ROW_NUMBER() OVER (PARTITION BY B_Pt_No ORDER BY B_Adm_Date DESC)
  FROM smsdss.c_readmissions_v AS r
  JOIN smsmir.vst_rpt VR
  ON R.B_Pt_No = VR.acct_no
  WHERE EXISTS 
  (
    SELECT 1 FROM smsdss.BMH_PLM_PtAcct_V
      WHERE Plm_Pt_Acct_Type = 'I'
      AND PtNo_Num < '20000000'
      AND Dsch_Date BETWEEN @SD AND @ED
      AND drg_no IN (
          '190','191','192'  -- COPD
          ,'291','292','293' -- CHF
          ,'287','313'       -- CHEST PAIN
      ) AND MED_REC_NO = r.B_Med_Rec_No
  )
  AND B_Dsch_Date BETWEEN @SD AND @ED
  AND B_Adm_Src_Desc != 'Scheduled Admission'
  AND B_Pt_No < '20000000'
)
SELECT *
, visit_count = ROW_NUMBER() OVER (PARTITION BY MRN ORDER BY  [READMIT DATE] ASC)
FROM cte WHERE rn = 1;