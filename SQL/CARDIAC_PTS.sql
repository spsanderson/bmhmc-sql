-- VARIABLE DECLARATION AND INITIALIZATION
DECLARE @SD DATETIME
DECLARE @ED DATETIME

SET @SD = '2014-7-01'
SET @ED = '2014-8-01'

-- COLUMN SELECTION
SELECT DISTINCT PAV.PtNo_Num AS [ENCOUNTER NUMBER]
, prin_dx_cd AS [PRINCIPAL ICD-9 CODE]
, CASE
    WHEN DV.ClasfCd = '427.5'  THEN 'CARDIAC ARREST'
    WHEN DV.ClasfCd = '427.41' THEN 'VENTRICULAR FIBRILLATION'
    WHEN DV.ClasfCd = '427.9'  THEN 'PULSELESS ELECTRICAL ACTIVITY'
    WHEN DV.ClasfCd = '427.1'  THEN 'PAROXYSMAL VENTRICULAR TACHYCARDIA'
    WHEN DV.ClasfCd = '427.5'  THEN 'ASYSTOLE'
  END AS [PRINCIPAL DIAGNOSIS]

  -- DB(S) USED
FROM smsdss.BMH_PLM_PtAcct_V PAV
JOIN smsdss.BMH_PLM_PtAcct_Clasf_Dx_V DV
ON PAV.PtNo_Num = DV.PtNo_Num

-- FILTER(S)
WHERE PAV.Dsch_Date >= @SD 
AND PAV.Dsch_Date < @ED
AND DV.ClasfCd IN (
'427.5'    -- CARDIAC ARREST
, '427.41' -- VENTRICULAR FIBRILLATION
, '427.9'  -- PULSELESS ELECTRICAL ACTIVITY
, '427.1'  -- PAROXYSMAL VENTRICULAR TACHYCARDIA
, '427.5'  -- ASYSTOLE
)
/*
END REPORT
*/