-- FINDING READMISSIONS
--*************************************************************************
--
SET ANSI_NULLS OFF
GO

-- DATE VARIABLE DECLARATION AND INITIALIZATION
DECLARE @STARTDATE DATETIME;
DECLARE @ENDDATE   DATETIME;

SET @STARTDATE = '2014-04-01';
SET @ENDDATE   = '2014-05-01';

-- TABLE CREATION WHICH WILL BE USED TO COMPARE DATA                                   
DECLARE @TABLE1 TABLE(
	Patient_Name   VARCHAR(80)
	, MRN          VARCHAR(13)
	, Arrival      DATETIME
	, Encounter    VARCHAR(15)
	, Admit_Source VARCHAR(80)
	, DEPARTURE    DATETIME
)

-- WHAT GETS INSERTED INTO TABLE 1
INSERT INTO @TABLE1
SELECT
A.Pt_Name
, A.Med_Rec_No
, A.vst_start_dtime
, A.PtNo_Num
, A.Adm_Source
, A.vst_end_dtime

FROM
(
	SELECT PT_NAME
	, MED_REC_NO
	, VST_START_DTIME
	, PTNO_NUM
	, ADM_SOURCE
	, VST_END_DTIME 
	
	FROM smsdss.BMH_PLM_PtAcct_V
	
	WHERE vst_start_dtime >= @STARTDATE 
	AND vst_start_dtime   < @ENDDATE
	AND Plm_Pt_Acct_Type  = 'I'
	AND Plm_Pt_Acct_Type != 'P'
	AND PTNO_NUM < '20000000'
) A

DECLARE @TABLE2 TABLE(
	Patient_Name   VARCHAR(80)
	, MRN          VARCHAR(13)
	, Arrival      DATETIME
	, Encounter    VARCHAR(15)
	, Admit_Source VARCHAR(80)
	, DEPARTURE    DATETIME
)

-- WHAT GETS INSERTED INTO TABLE 1
INSERT INTO @TABLE2
SELECT
B.Pt_Name
, B.Med_Rec_No
, B.vst_start_dtime
, B.PtNo_Num
, B.Adm_Source
, B.vst_end_dtime

FROM
(
	SELECT PT_NAME
	, MED_REC_NO
	, VST_START_DTIME
	, PTNO_NUM
	, ADM_SOURCE
	, VST_END_DTIME 
	
	FROM smsdss.BMH_PLM_PtAcct_V
	
	WHERE vst_start_dtime >= @STARTDATE 
	--AND vst_start_dtime   < @ENDDATE
	AND Plm_Pt_Acct_Type  = 'I'
	AND Plm_Pt_Acct_Type != 'P'
	AND PTNO_NUM < '20000000'
) B
-- DATEDIFF LOGIC AND TABLE COMPARISONS
SELECT
DISTINCT T1.MRN
, T1.ENCOUNTER                         AS [INDEX ENCOUNTER]
, T1.PATIENT_NAME                      AS [PT NAME]
, T1.ARRIVAL                           AS [INDEX ARRIVAL]
, T1.DEPARTURE                         AS [INDEX DEPARTURE]
, DATEDIFF(DD,T1.DEPARTURE,T2.Arrival) AS [INTERIM]
, T2.Encounter                         AS [READMIT ENCOUNTER]
, Readmit_Chain = ROW_NUMBER() OVER (
                                     PARTITION BY T1.MRN 
                                     ORDER BY T1.ARRIVAL ASC
                                     )
, T2.Arrival                           AS [READMIT ARRIVAL]
, T2.DEPARTURE                         AS [READMIT DEPARTURE]

FROM @TABLE1 T1
JOIN @TABLE2 T2
ON T1.MRN = T2.MRN

WHERE T1.MRN = T2.MRN
AND T1.Arrival < T2.Arrival
--AND T2.Arrival = (
--					SELECT MIN(TEMP.Arrival)
--					FROM @TABLE1 TEMP
--					WHERE T1.MRN = TEMP.MRN
--					AND T1.DEPARTURE < TEMP.Arrival
--				 )
AND DATEDIFF(DD, T1.ARRIVAL, T2.Arrival) <= 30