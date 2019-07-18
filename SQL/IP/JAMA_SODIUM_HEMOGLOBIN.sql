-- GET RESULTS FOR ANALYSIS OF PATIENTS IN ORDER TO DETERMINE IF THEY WILL BE READMITTED
-- SODIUM AND HEMOGLOBIN
--*****************************************************************************************

SET ANSI_NULLS OFF
GO

-- VARIABLE DECLARATION
DECLARE @STARTDATE DATETIME
DECLARE @ENDDATE DATETIME

-- VARIABLE INITIALIZATION
SET @STARTDATE = '6/1/12';
SET @ENDDATE = '1/1/13';

--#############################################################################################
-- TABLE DECLARATION WHICH WILL BE USED TO GET THE MAX ORDERED DATE                           #
--                                                                                            #
DECLARE @T1 TABLE (ENCOUNTER VARCHAR(200), PT_NAME VARCHAR(500), MRN VARCHAR(200),          --#
				   LOS VARCHAR(200), PT_LOC VARCHAR(500), PT_DISPO VARCHAR(500),            --# 
				   LAB_NAME VARCHAR(500), LAB_VALUE VARCHAR(40),LOWER_LIMIT VARCHAR(30),    --# 
				   UPPER_LIMIT VARCHAR(30), HISTORY VARCHAR(10), HAS_HISTORY VARCHAR(10),   --#
				   AB_CODE VARCHAR(30), ORDER_ENTERED VARCHAR(500))                         --#
DECLARE @T2 TABLE (ENCOUNTER2 VARCHAR(200), PT_NAME2 VARCHAR(500), MRN2 VARCHAR(200),       --# 
				   LOS2 VARCHAR(200), PT_LOC2 VARCHAR(500), PT_DISPO2 VARCHAR(500),         --#
				   LAB_NAME2 VARCHAR(500), LAB_VALUE2 VARCHAR(40),LOWER_LIMIT2 VARCHAR(30), --#
				   UPPER_LIMIT2 VARCHAR(30), HISTORY2 VARCHAR(10), HAS_HISTORY2 VARCHAR(10),--# 
				   AB_CODE2 VARCHAR(30), ORDER_ENTERED2 VARCHAR(500))                       --#
--                                                                                            #
--#############################################################################################

--##       TABLE INSERTIONS     ##
--#############################################################################################
--## WHAT GETS PUT INTO TABLE 1 ##
INSERT INTO @T1
SELECT
A.VisitIDCode,
A.ClientDisplayName,
A.IDCode,
A.LOS,
A.CurrentLocation,
A.DischargeDisposition,
A.ItemName,
A.Value,
A.ReferenceLowerLimit,
A.ReferenceUpperLimit,
A.IsHistory,
A.HasHistory,
A.AbnormalityCode,
A.Entered

FROM
(
-- COLUMN SELECTION
SELECT CV.VisitIDCode, CV.ClientDisplayName, CV.IDCode,DATEDIFF(DD,CV.ADMITDTM,CV.DISCHARGEDTM)AS 'LOS',
CV.CurrentLocation, CV.DischargeDisposition, BO.ItemName, BO.Value,
BO.ReferenceLowerLimit, BO.ReferenceUpperLimit, BO.IsHistory, BO.HasHistory, BO.AbnormalityCode,
BO.Entered

-- DB USED: SCM
FROM CV3ClientVisit CV
JOIN CV3BasicObservation BO
ON CV.GUID = BO.ClientVisitGUID

WHERE CV.AdmitDtm BETWEEN @STARTDATE AND @ENDDATE
AND CV.TypeCode = 'INPATIENT'
AND BO.Value IS NOT NULL
AND (BO.ItemName LIKE '%SODIUM LEVEL%'
OR BO.ITEMNAME LIKE '%HEMOG%')
)A 

--##       TABLE INSERTIONS     ##
--###########################################################################################
--## WHAT GETS PUT INTO TABLE 2 ##
INSERT INTO @T2
SELECT
B.VisitIDCode,
B.ClientDisplayName,
B.IDCode,
B.LOS,
B.CurrentLocation,
B.DischargeDisposition,
B.ItemName,
B.Value,
B.ReferenceLowerLimit,
B.ReferenceUpperLimit,
B.IsHistory,
B.HasHistory,
B.AbnormalityCode,
B.Entered

FROM
(
-- COLUMN SELECTION
SELECT CV.VisitIDCode, CV.ClientDisplayName, CV.IDCode,DATEDIFF(DD,CV.ADMITDTM,CV.DISCHARGEDTM) AS 'LOS', 
CV.CurrentLocation,CV.DischargeDisposition, BO.ItemName, BO.Value,BO.ReferenceLowerLimit, BO.ReferenceUpperLimit,	
BO.IsHistory, BO.HasHistory, BO.AbnormalityCode,BO.Entered

-- DB USED: SCM
FROM CV3ClientVisit CV
JOIN CV3BasicObservation BO
ON CV.GUID = BO.ClientVisitGUID


WHERE CV.AdmitDtm BETWEEN @STARTDATE AND @ENDDATE
AND CV.TypeCode = 'INPATIENT'
AND BO.Value IS NOT NULL
AND (BO.ItemName LIKE '%SODIUM LEVEL%'
OR BO.ITEMNAME LIKE '%HEMOG%')
)B

--###########################################################################################
--## HERE IS WHERE WE DO TABLE COMPARISONS ##

SELECT
DISTINCT T1.ENCOUNTER,
T1.PT_NAME AS 'PT NAME', T1.MRN AS 'MRN', T1.LOS AS 'LOS', T1.PT_LOC AS 'PT LOC',
T1.PT_DISPO AS 'PT DISPO', T2.LAB_NAME2 AS 'LAB NAME', T2.LAB_VALUE2, T2.LOWER_LIMIT2 AS 'LOWER LIMIT',
T2.UPPER_LIMIT2 AS 'UPPER LIMIT', T2.AB_CODE2 AS 'AB CODE', T2.ORDER_ENTERED2

FROM @T1 T1
JOIN @T2 T2
ON T1.MRN = T2.MRN2

WHERE
T1.ENCOUNTER = T2.ENCOUNTER2
AND T1.ORDER_ENTERED < T2.ORDER_ENTERED2
AND T2.ORDER_ENTERED2 = (
						SELECT MAX(TEMP.ORDER_ENTERED2)
						FROM @T2 TEMP
						WHERE T1.MRN = TEMP.MRN2
						)

--*****************************************************************************************
-- SANDERSON, STEVEN MEDICAL AFFAIRS
-- 3.29.13 EXT 4901