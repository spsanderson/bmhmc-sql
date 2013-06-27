-- FINDING READMISSIONS
--*************************************************************************
--
SET ANSI_NULLS OFF
GO

-- DATE VARIABLE DECLARATION AND INITIALIZATION
DECLARE @STARTDATE DATETIME
DECLARE @ENDDATE DATETIME

SET @STARTDATE = '2012-05-01';
SET @ENDDATE = '2013-04-30';

--######################################################################################
-- TABLE CREATION WHICH WILL BE USED TO COMPARE DATA                                   #

DECLARE @TABLE1 TABLE(Patient_Name VARCHAR(80), MRN_1 VARCHAR(13), Arrival_1 DATETIME, 
					  Encounter_1 VARCHAR(15), Admit_Source_1 VARCHAR(80),
					  DEPARTURE_1 DATETIME)

DECLARE @TABLE2 TABLE(Patient_Name_2 VARCHAR(80), MRN_2 VARCHAR(13), Arrival_2 DATETIME, 
                      Encounter_2 VARCHAR(15), Admit_Source_2 VARCHAR(80),
                      DEPARTURE_2 DATETIME)
--                                                                                     #
--######################################################################################

-- WHAT GETS INSERTED INTO TABLE 1
INSERT INTO @TABLE1
SELECT
PT_NAME,
MED_REC_NO,
VST_START_DTIME,
PT_NO,
ADM_SOURCE,
VST_END_DTIME

FROM
(
SELECT PT_NAME, MED_REC_NO, VST_START_DTIME, PT_NO, ADM_SOURCE, VST_END_DTIME 
FROM smsdss.BMH_PLM_PtAcct_V
WHERE vst_start_dtime BETWEEN @STARTDATE AND @ENDDATE
AND Plm_Pt_Acct_Type = 'I'
AND Plm_Pt_Acct_Type != 'P'
) A ORDER BY Pt_Name

-- WHAT GETS INSERTED INTO TABLE 2
INSERT INTO @TABLE2
SELECT
PT_NAME,
MED_REC_NO,
VST_START_DTIME,
PT_NO,
ADM_SOURCE,
VST_END_DTIME

FROM
(
SELECT PT_NAME, MED_REC_NO, vst_start_dtime, PT_NO, ADM_SOURCE, VST_END_DTIME
FROM smsdss.BMH_PLM_PtAcct_V
WHERE vst_start_dtime BETWEEN @STARTDATE AND @ENDDATE
AND Plm_Pt_Acct_Type = 'I'
AND Plm_Pt_Acct_Type != 'P'
) B ORDER BY Pt_Name

-- DATEDIFF LOGIC AND TABLE COMPARISONS
SELECT
DISTINCT T1.MRN_1,
DATEDIFF(DD,T1.ARRIVAL_1,T2.ARRIVAL_2) AS 'INTERIM',
T1.PATIENT_NAME AS 'PT NAME', T1.ARRIVAL_1 AS 'PT ARRIVAL',
T1.ENCOUNTER_1

FROM @TABLE1 T1
JOIN @TABLE2 T2
ON T1.MRN_1 = T2.MRN_2

WHERE T1.MRN_1 = T2.MRN_2
AND T1.Arrival_1 < T2.Arrival_2
AND T2.Arrival_2 = (
					SELECT MIN(TEMP.ARRIVAL_2)
					FROM @TABLE2 TEMP
					WHERE T1.MRN_1 = TEMP.MRN_2
					AND T1.DEPARTURE_1 < TEMP.Arrival_2
					)
AND DATEDIFF(DD, T1.ARRIVAL_1, T2.Arrival_2) <= 30