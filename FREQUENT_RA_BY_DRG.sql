DECLARE @SD AS DATE;
DECLARE @ED AS DATE;
SET @SD = '2011-01-01';
SET @ED = '2014-01-31';

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
    , X.[DISCHARGE DISPOSITION]
    , rn = ROW_NUMBER() OVER (PARTITION BY B_Pt_No ORDER BY B_Adm_Date DESC)
  
  FROM smsdss.c_readmissions_v AS R
  JOIN smsmir.vst_rpt VR
  ON R.B_Pt_No = VR.acct_no
  JOIN smsdss.dsch_disp_dim_v DV
  ON VR.dsch_disp = DV.dsch_disp
  
  CROSS APPLY (
	SELECT
		CASE
			WHEN DV.dsch_disp = 'AHB' THEN 'Drug/Alcohol Rehab Non-Hospital Facility'
			WHEN DV.dsch_disp = 'AHI' THEN 'Hospice at Hospice Facility, SNF or Inpatient Facility'
			WHEN DV.dsch_disp = 'AHR' THEN 'Home, Home with Public Health Nurse, Adult Home, Assisted Living'
			WHEN DV.dsch_disp = 'AMA' THEN 'Left Against Medical Advice, Elopement'
			WHEN DV.dsch_disp = 'ATB' THEN 'Correctional Institution'
			WHEN DV.dsch_disp = 'ATE' THEN 'SNF -Sub Acute'
			WHEN DV.dsch_disp = 'ATF' THEN 'Specialty Hospital ( i.e Sloan, Schneiders)'
			WHEN DV.DSCH_DISP = 'ATH' THEN 'Hospital - Med/Surg (i.e Stony Brook)'
			WHEN DV.DSCH_DISP = 'ATL' THEN 'SNF - Long Term'
			WHEN DV.DSCH_DISP = 'ATN' THEN 'Hospital - VA'
			WHEN DV.DSCH_DISP = 'ATP' THEN 'Hospital - Psych or Drug/Alcohol (i.e BMH 1EAST, South Oaks)'
			WHEN DV.DSCH_DISP = 'ATT' THEN 'Hospice at Home, Adult Home, Assisted Living'
			WHEN DV.DSCH_DISP = 'ATW' THEN 'Home, Adult Home, Assisted Living with Homecare'
			WHEN DV.dsch_disp = 'ATX' THEN 'Hospital - Acute Rehab ( I.e. St. Charles, Southside)'
			WHEN DV.dsch_disp = 'C1A' THEN 'Postoperative Death, Autopsy'
			WHEN DV.dsch_disp = 'C1N' THEN 'Postoperative Death, No Autopsy'
			WHEN DV.dsch_disp = 'C1Z' THEN 'Postoperative Death, Autopsy Unknown'
			WHEN DV.dsch_disp = 'C2A' THEN 'Surgical Death within 48hrs Post Surgery, Autopsy'
			WHEN DV.dsch_disp = 'C2N' THEN 'Surgical Death within 48hrs Post Surgery, No Autopsy'
			WHEN DV.dsch_disp = 'C2Z' THEN 'Surgical Death within 48hrs Post Surgery, Autopsy Unknown'
			WHEN DV.dsch_disp = 'C3A' THEN 'Surgical Death within 3-10 days Post Surgery, Autopsy'
			WHEN DV.dsch_disp = 'C3N' THEN 'Surgical Death within 3-10 days Post Surgery, No Autopsy'
			WHEN DV.dsch_disp = 'C3Z' THEN 'Surgical Death within 3-10 days Post Surgery, Autopsy Unknown'
			WHEN DV.dsch_disp = 'C4A' THEN 'Died in O.R, Autopsy'
			WHEN DV.dsch_disp = 'C4N' THEN 'Died in O.R, No Autopsy'
			WHEN DV.dsch_disp = 'C4Z' THEN 'Died in O.R., Autopsy Unknown'
			WHEN DV.dsch_disp = 'C7A' THEN 'Other Death, Autopsy'
			WHEN DV.dsch_disp = 'C7N' THEN 'Other Death, No Autopsy'
			WHEN DV.dsch_disp = 'C7Z' THEN 'Other Death, Autopsy Unknown'
			WHEN DV.dsch_disp = 'C8A' THEN 'Nonsurgical Death within 48hrs of Admission, Autopsy'
			WHEN DV.dsch_disp = 'C8N' THEN 'Nonsurgical Death within 48hrs of Admission, No Autopsy'
			WHEN DV.dsch_disp = 'C8Z' THEN 'Nonsurgical Death within 48hrs of Admission, Autopsy Unknown'
			WHEN DV.dsch_disp = 'D1A' THEN 'Postoperative Death, Autopsy'
			WHEN DV.dsch_disp = 'D1N' THEN 'Postoperative Death, No Autopsy'
			WHEN DV.dsch_disp = 'D1Z' THEN 'Postoperative Death, Autopsy Unknown'
			WHEN DV.dsch_disp = 'D2A' THEN 'Surgical Death within 48hrs Post Surgery, Autopsy'
			WHEN DV.dsch_disp = 'D2N' THEN 'Surgical Death within 48hrs Post Surgery, No Autopsy'
			WHEN DV.dsch_disp = 'D2Z' THEN 'Surgical Death within 48hrs Post Surgery, Autopsy Unknown'
			WHEN DV.dsch_disp = 'D3A' THEN 'Surgical Death within 3-10 days Post Surgery, Autopsy'
			WHEN DV.dsch_disp = 'D3N' THEN 'Surgical Death within 3-10 days Post Surgery, No Autopsy'
			WHEN DV.dsch_disp = 'D3Z' THEN 'Surgical Death within 3-10 days Post Surgery, Autopsy Unknown'
			WHEN DV.dsch_disp = 'D4A' THEN 'Died in O.R, Autopsy'
			WHEN DV.dsch_disp = 'D4N' THEN 'Died in O.R, No Autopsy'
			WHEN DV.dsch_disp = 'D4Z' THEN 'Died in O.R., Autopsy Unknown'
			WHEN DV.dsch_disp = 'D7A' THEN 'Other Death, Autopsy'
			WHEN DV.dsch_disp = 'D7N' THEN 'Other Death, No Autopsy'
			WHEN DV.dsch_disp = 'D7Z' THEN 'Other Death, Autopsy Unknown'
			WHEN DV.dsch_disp = 'D8A' THEN 'Nonsurgical Death within 48hrs of Admission, Autopsy'
			WHEN DV.dsch_disp = 'D8N' THEN 'Nonsurgical Death within 48hrs of Admission, No Autopsy'
			WHEN DV.dsch_disp = 'D8Z' THEN 'Nonsurgical Death within 48hrs of Admission, Autopsy Unknown'
			ELSE DV.dsch_disp
		END AS [DISCHARGE DISPOSITION]
  ) X
  
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
      ) 
	  AND MED_REC_NO = R.B_Med_Rec_No
  )
  AND B_Dsch_Date BETWEEN @SD AND @ED
  AND B_Adm_Src_Desc != 'Scheduled Admission'
  AND B_Pt_No < '20000000'
)
SELECT *
, visit_count = ROW_NUMBER() OVER (PARTITION BY MRN ORDER BY  [READMIT DATE] ASC)
FROM cte WHERE rn = 1;