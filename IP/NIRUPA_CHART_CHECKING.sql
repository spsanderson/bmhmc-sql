-- REPORT FOR NIRUPA. OVER A 3 MONTH PERIOD SELECT 4 RANDOM PATIENTS FOR EACH HOSPITALIST
-- PHYSICIAN AND GET NIRUPA A REPORT OF THE PATIENTS' NAME, ACCOUNT NUMBER, START DATE OF
-- THE ENCOUNTER
--***************************************************************************************
--
-- SELECT COLUMNS

SELECT DISTINCT CV.VISITIDCODE AS 'ENCOUNTER NUMBER', CV.ClientDisplayName AS 'PT NAME',
CP.DisplayName AS 'PYSICIAN NAME', CV.AdmitDtm

-- SELECT DB AND TABLES AND THEIR ALIAS IF APPLICABLE
FROM CV3ClientVisit CV
JOIN CV3CareProviderVisitRole CPVR
ON CV.GUID = CPVR.ClientVisitGUID
JOIN CV3CareProvider CP
ON CPVR.ProviderGUID = CP.GUID

-- FILTERS
WHERE CV.VisitStatus = 'DSC'
AND CV.AdmitDtm BETWEEN '10/1/12' AND '1/1/13'
AND CP.Discipline = 'HOSPITAL MEDICINE'
AND CP.TaskRoleType = 'PHYSICIAN'
AND CPVR.RoleCode = 'ATTENDING'
AND CPVR.Status = 'ACTIVE'
ORDER BY CV.ClientDisplayName ASC

--****************************************************************************************
-- END REPORT
-- 2.22.2013 STEVEN SANDERSON