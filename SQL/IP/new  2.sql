-- THIS QUERY COMBINES THREE IN ONE IN ORDER TO OBTIAN DATA FOR THE JAMA READMIT TOOL
--*****************************************************************************************

SET ANSI_NULLS OFF
GO

-- VARIABLE DECLARATION
DECLARE @STARTDATE DATETIME
DECLARE @ENDDATE DATETIME

-- VARIABLE INITIALIZATION
SET @STARTDATE = '6/1/12';
SET @ENDDATE = '7/1/12';


--#############################################################################################
-- TABLE DECLARATION WHICH WILL BE USED TO GET THE MAX ORDERED DATE                           #
--                                                                                            #
DECLARE @T1 TABLE (ENCOUNTER VARCHAR(200), PT_NAME VARCHAR(500), MRN VARCHAR(200),          --#
				   LOS VARCHAR(200), PT_LOC VARCHAR(500), PT_DISPO VARCHAR(500),            --# 
				   LAB_NAME VARCHAR(500), LAB_VALUE VARCHAR(40),LOWER_LIMIT VARCHAR(30),    --# 
				   UPPER_LIMIT VARCHAR(30),                                                 --#
				   AB_CODE VARCHAR(30), ORDER_ENTERED VARCHAR(500))                         --#
DECLARE @T2 TABLE (ENCOUNTER2 VARCHAR(200), PT_NAME2 VARCHAR(500), MRN2 VARCHAR(200),       --# 
				   LOS2 VARCHAR(200), PT_LOC2 VARCHAR(500), PT_DISPO2 VARCHAR(500),         --#
				   LAB_NAME2 VARCHAR(500), LAB_VALUE2 VARCHAR(40),LOWER_LIMIT2 VARCHAR(30), --#
				   UPPER_LIMIT2 VARCHAR(30),                                                --# 
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
A.AbnormalityCode,
A.Entered

FROM
(
-- COLUMN SELECTION
SELECT CV.VisitIDCode, CV.ClientDisplayName, CV.IDCode,DATEDIFF(DD,CV.ADMITDTM,CV.DISCHARGEDTM)AS 'LOS',
CV.CurrentLocation, CV.DischargeDisposition, BO.ItemName, BO.Value,
BO.ReferenceLowerLimit, BO.ReferenceUpperLimit, BO.AbnormalityCode,
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
B.AbnormalityCode,
B.Entered

FROM
(
-- COLUMN SELECTION
SELECT CV.VisitIDCode, CV.ClientDisplayName, CV.IDCode,DATEDIFF(DD,CV.ADMITDTM,CV.DISCHARGEDTM) AS 'LOS', 
CV.CurrentLocation,CV.DischargeDisposition, BO.ItemName, BO.Value,BO.ReferenceLowerLimit, BO.ReferenceUpperLimit,	
BO.AbnormalityCode,BO.Entered

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

--#############################################################################################
-- TABLE DECLARATION WHICH WILL BE USED TO GET THE PROC COUNT                                 #
DECLARE @procedures Table (MRN varchar(20), Patient varchar(80),Admit datetime, 
                           Disch datetime, SURG_COUNT VARCHAR(5))
--                                                                                            #
--#############################################################################################

--##       TABLE INSERTIONS         ##
--#############################################################################################
--## WHAT GETS PUT INTO @procedures ##
INSERT INTO @procedures
SELECT 
cv.IDCode,
cv.ClientDisplayName,
cv.AdmitDtm,
cv.DischargeDtm,
COUNT(CV.IDCODE) AS 'SURG_COUNT'

FROM CV3ClientVisit cv

LEFT JOIN cV3ClientEventDeclaration ed
ON cv.GUID=ed.ClientVisitGUID

WHERE ed.typecode = 'Surgery'
AND cv.AdmitDtm BETWEEN @STARTDATE AND @ENDDATE
AND Status = 'Active'
GROUP BY CV.IDCode,CV.ClientDisplayName,CV.AdmitDtm,CV.DischargeDtm
ORDER BY cv.ClientDisplayName

--#############################################################################################
--TABLE DECLARATION FOR INPATIENT VISITS
DECLARE @IPT TABLE (MRN VARCHAR(20), COUNT_IP VARCHAR(3))
--
--#############################################################################################

--##       TABLE INSERTIONS         ##
--#############################################################################################
--## WHAT GETS PUT INTO @IPT        ##
INSERT INTO @IPT
DECLARE @STARTDATEIPT DATETIME
DECLARE @ENDDATEIPT DATETIME
SET @ENDDATEIPT = '1/1/13'
SET @STARTDATEIPT = @ENDDATEIPT -180 

SELECT
CV.IDCODE,
COUNT(CV.IDCODE) AS 'COUNT', CV.AdmitDtm

FROM CV3ClientVisit CV

WHERE CV.AdmitDtm BETWEEN @STARTDATEIPT AND @ENDDATEIPT
AND CV.TypeCode LIKE '%INPATIENT'

GROUP BY CV.IDCode, CV.AdmitDtm
ORDER BY CV.AdmitDtm


SELECT
CV.IDCODE,
COUNT(CV.IDCODE)

FROM CV3ClientVisit CV

WHERE CV.AdmitDtm BETWEEN @STARTDATE AND @STARTDATE - 180
AND CV.TypeCode LIKE '%INPATIENT'

GROUP BY CV.IDCode

--#############################################################################################
-- TABLE DECLARATION WHICH WILL BE USED AS THE FINAL TABLE WHERE ALL THE RESULTS WILL GO.     
DECLARE @JT TABLE (ENCOUNTER VARCHAR(200), PT_NAME VARCHAR(500), MRN VARCHAR(200),          
				   LOS VARCHAR(200), PT_LOC VARCHAR(500), PT_DISPO VARCHAR(500),             
				   LAB_NAME VARCHAR(500), LAB_VALUE VARCHAR(40),LOWER_LIMIT VARCHAR(30),     
				   UPPER_LIMIT VARCHAR(30),    
				   AB_CODE VARCHAR(30), ORDER_ENTERED VARCHAR(500), SurgProcs VARCHAR(400),
				   COUNT_IP VARCHAR(3))
--                                                                                          
--#############################################################################################

INSERT INTO @JT
SELECT
Q1.ENCOUNTER, Q1.PT_NAME, Q1.MRN, Q1.LOS, Q1.PT_LOC, Q1.PT_DISPO, Q1.LAB_NAME2, Q1.LAB_VALUE2,
Q1.LOWER_LIMIT2, Q1.UPPER_LIMIT2, Q1.AB_CODE2, Q1.ORDER_ENTERED2, Q1.SURG_COUNT, Q1.COUNT_IP

FROM
(
SELECT
DISTINCT T1.ENCOUNTER, T1.PT_NAME, T1.MRN, T1.LOS, T1.PT_LOC, T1.PT_DISPO, T2.LAB_NAME2, 
T2.LAB_VALUE2, T2.LOWER_LIMIT2, T2.UPPER_LIMIT2, T2.AB_CODE2, T2.ORDER_ENTERED2, P.SURG_COUNT, COUNT_IP

FROM @T1 T1
JOIN @T2 T2
ON T1.MRN = T2.MRN2
LEFT JOIN @procedures P
ON T1.MRN = P.MRN
LEFT JOIN @IPT I
ON T1.MRN = I.MRN


WHERE
T1.ENCOUNTER = T2.ENCOUNTER2
AND T1.ORDER_ENTERED < T2.ORDER_ENTERED2
AND T2.ORDER_ENTERED2 = (
						SELECT MAX(TEMP.ORDER_ENTERED2)
						FROM @T2 TEMP
						WHERE T1.MRN = TEMP.MRN2
						)
)Q1

--#################################################################################################
-- THIS IS THE QUEREY TO THE @JT TABLE
SELECT *
FROM @JT