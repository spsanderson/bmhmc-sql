-- THIS QUEREY GETS THE DISCHARGE ORDER AND SUMMARY TIME FOR PATIENTS FOR A SPECIFIED TIME FRAME
--***********************************************************************************************
SET ANSI_NULLS OFF
Go 

-- VARIABLE DECLARATION AND INITIALIZATION
DECLARE @startdate DATETIME
DECLARE @enddate DATETIME
SET @startdate= '3/19/2013'      
SET   @enddate= '3/26/2013'

--################################################################################################
-- TABLE CREATION                                                                                #
-- TABLE 1
DECLARE @table1 TABLE( Encounter VARCHAR(13), MRN VARCHAR(13), Patient_Name VARCHAR(80), 
discharge_1 DATETIME, attending_physician VARCHAR(80), discipline VARCHAR(20), role VARCHAR(15), 
status VARCHAR(7), ordername VARCHAR (10), orderEntered_1 DATETIME, CurrentLocatiON VARCHAR(25),
summaryEntered_1 DATETIME, documentname VARCHAR(30), dischargedispo VARCHAR(30) )

-- TABLE 2
DECLARE @table2 TABLE( Encounter VARCHAR(13), MRN VARCHAR(13), Patient_Name VARCHAR(80), 
discharge_1 DATETIME, attending_physician VARCHAR(80), discipline VARCHAR(20), role VARCHAR(15), 
status VARCHAR(7), ordername VARCHAR (10), orderEntered_2 DATETIME, CurrentLocatiON VARCHAR(25), 
summaryEntered_2 DATETIME, documentname VARCHAR(30), dischargedispo VARCHAR(30))
--                                                                                               #
--################################################################################################

-- WHAT IS GETTING PUT INTO TABLE 1
INSERT INTO @table1
SELECT 
a.visitIDCode,
a.idcode,
a.ClientDisplayName,
a.DischargeDtm,
a.DisplayName,
a.Discipline,
a.rolecode,
a.Status,
a.name, 
a.entered, 
a.CurrentLocatiON,
a.authoreddtm,
a.documentname,
a.DischargeDispositiON
FROM
(
SELECT DISTINCT cv.idcode, cv.VisitIDCode, cv.ClientDisplayName,  cv.DischargeDtm,  cp.DisplayName, cp.Discipline, 
vr.rolecode, vr.Status, o.name,  cv.CurrentLocatiON,  cd.DocumentName,o.Entered ,cd.authoreddtm, cv.DischargeDispositiON
FROM dbo.CV3ClientVisit cv
JOIN CV3CareProviderVisitRole vr
ON cv.GUID=vr.ClientVisitGUID
JOIN CV3CareProvider cp
ON vr.ProviderGUID=cp.GUID
JOIN CV3ClientDocument cd 
ON cv.ClientGUID = cd.ClientGUID 
JOIN CV3Order o
ON o.ClientVisitGUID = cv.GUID
WHERE o.Name = 'discharge'
AND  cv.DischargeDtm between @startdate AND  @enddate
AND cp.Discipline = 'Hospital Medicine'

AND cv.TypeCode = 'inpatient'
AND cv.ClientDisplayName not like '%allscripts%'
AND cv.CurrentLocatiON != 'inpatient preadmit'
AND vr.RoleCode = 'attending'
AND vr.Status ='active'
AND cv.CurrentLocatiON not like 'TCU%'
AND DocumentName in ('Hospitalists Discharge Summary', 'Discharge Summary')
AND cd.AuthoredDtm between @startdate AND  @enddate
) a

-- WHAT IS GETTING INSERTED INTO TABLE 2
INSERT INTO @table2
SELECT 
b.visitIDCode,
b.idcode,
b.ClientDisplayName,
b.DischargeDtm,
b.DisplayName,
b.Discipline,
b.rolecode,
b.Status,
b.name, 
b.entered, 
b.CurrentLocatiON,
b.authoreddtm,
b.documentname,
b.DischargeDispositiON

FROM
(
SELECT DISTINCT cv.idcode, cv.VisitIDCode, cv.ClientDisplayName,  cv.DischargeDtm,  cp.DisplayName, cp.Discipline, 
vr.rolecode, vr.Status, o.name,  cv.CurrentLocatiON,  cd.DocumentName,o.Entered ,cd.authoreddtm,  cv.DischargeDispositiON
FROM dbo.CV3ClientVisit cv

JOIN CV3CareProviderVisitRole vr
ON cv.GUID=vr.ClientVisitGUID
JOIN CV3CareProvider cp
ON vr.ProviderGUID=cp.GUID
JOIN CV3ClientDocument cd 
ON cv.ClientGUID = cd.ClientGUID 
JOIN CV3Order o
ON o.ClientVisitGUID = cv.GUID

WHERE o.Name = 'discharge'
AND  cv.DischargeDtm between @startdate AND  @enddate
AND cp.Discipline = 'Hospital Medicine'

AND cv.TypeCode = 'inpatient'
AND cv.ClientDisplayName not like '%allscripts%'
AND cv.CurrentLocatiON != 'inpatient preadmit'
AND vr.RoleCode = 'attending'
AND vr.Status ='active'
AND cv.CurrentLocatiON not like 'TCU%'
AND DocumentName in ('Hospitalists Discharge Summary', 'Discharge Summary')
AND cd.AuthoredDtm between @startdate AND  @enddate
) b
--------------------------------------------------------------------------------------
SELECT DISTINCT
	  t1.Encounter,
      t1.MRN,
      t1.Patient_Name,
      t1.attending_physician,
      t1.discharge_1,	
      t1.discipline,
	  t1.role, 
	  t1.status,
	  t1.ordername,
	  t1.orderentered_1,
	  t1.CurrentLocatiON,
	  t1.summaryentered_1,
	  t1.documentname,
	  t1.dischargedispo
	
FROM @table1 t1
LEFT JOIN @table2 t2
ON t1.encounter =t2.encounter

WHERE t1.encounter =t2.encounter 
--AND t1.orderentered_1 < t2.orderentered_2

						
AND t1.orderentered_1 = (
						SELECT max(temp.orderentered_1)
						FROM @table1 temp
						WHERE t2.encounter=temp.encounter
						)
					
AND t1.summaryentered_1 = (
						SELECT max(temp.summaryentered_1)
						FROM @table1 temp
						WHERE t2.encounter=temp.encounter
						)	
					

ORDER BY t1.Patient_Name
