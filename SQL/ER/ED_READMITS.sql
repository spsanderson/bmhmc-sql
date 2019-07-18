-- FINDING ED READMISSIONS
--***************************************************************************************
--
SET ANSI_NULLS OFF
GO

-- DATE VARIABLE DECLARATION AND INITIALIZATION
DECLARE @STARTDATE DATETIME
DECLARE @ENDDATE DATETIME

SET @STARTDATE = '1/1/13';
SET @ENDDATE = '2/1/13';

--######################################################################################
-- TABLE CREATION WHICH WILL BE USED TO COMPARE DATA                                   #

DECLARE @TABLE1 TABLE(Patient_Name VARCHAR(80), MRN_1 VARCHAR(13), Arrival_1 DATETIME, 
					  Encounter_1 VARCHAR(15), Outcome_Location_1 VARCHAR(80),
					  DEPARTURE_1 DATETIME)

DECLARE @TABLE2 TABLE(Patient_Name_2 VARCHAR(80), MRN_2 VARCHAR(13), Arrival_2 DATETIME, 
                      Encounter_2 VARCHAR(15), Outcome_Location_2 VARCHAR(80),
                      DEPARTURE_2 DATETIME)
--                                                                                     #
--######################################################################################

-- WHAT GETS INSERTED INTO TABLE 1
INSERT INTO @TABLE1
SELECT
S_PATIENT_FULL_NAME,
s_MRN,
DT_ARRIVAL,
S_VISIT_IDENT,
n_OUTCOME_ID,
DT_DEPARTURE

FROM
(
SELECT dt_arrival, s_patient_full_name, s_visit_ident, s_MRN, n_OUTCOME_ID, DT_DEPARTURE
FROM dbo.JTM_GENERIC_LIST_V
WHERE DT_ARRIVAL BETWEEN @STARTDATE AND @ENDDATE
) A ORDER BY s_patient_full_name

-- WHAT GETS INSERTED INTO TABLE 2
INSERT INTO @TABLE2
SELECT 
s_patient_full_name,
s_MRN,
dt_ARRIVAL,
s_VISIT_IDENT,
n_OUTCOME_ID,
DT_DEPARTURE

FROM
(
SELECT dt_arrival, s_patient_full_name, s_visit_ident, s_MRN,n_OUTCOME_ID, DT_DEPARTURE
FROM dbo.JTM_GENERIC_LIST_V
WHERE dt_arrival between @STARTDATE and @ENDDATE 
) B ORDER BY s_patient_full_name, dt_arrival
 
-- DATEDIFF LOGIC AND TABLE COMPARISONS
SELECT
DISTINCT T1.MRN_1,
DATEDIFF(DD, T1.ARRIVAL_1, T2.ARRIVAL_2) AS 'INTERIM',
T1.PATIENT_NAME AS 'PT NAME', T1.ARRIVAL_1 AS 'PT ARRIVAL',
T1.ENCOUNTER_1
 
 
FROM @TABLE1 T1
JOIN @TABLE2 T2
ON T1.MRN_1 = T2.MRN_2
 
WHERE
T1.MRN_1 = T2.MRN_2
AND T1.ARRIVAL_1 < T2.ARRIVAL_2
AND T2.ARRIVAL_2 = (
                    SELECT MIN(TEMP.ARRIVAL_2)
                    From @TABLE2 TEMP
                    WHERE T1.MRN_1 = TEMP.MRN_2
                    AND T1.DEPARTURE_1 < TEMP.ARRIVAL_2
                    )
AND DATEDIFF(DD, T1.ARRIVAL_1, T2.ARRIVAL_2) <= 7

--*********************************************************************************
 