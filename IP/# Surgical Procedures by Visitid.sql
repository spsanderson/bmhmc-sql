--Query to list # of surgery procedures by VisitID--- 

--####################################################################################################
-- TABLE DECLARATION WHICH WILL BE USED TO GET THE MAX ORDERED DATE                                  #
DECLARE @procedures Table (MRN varchar(20), Patient varchar(80), VisitID varchar(20), Admit datetime, 
                           Disch datetime, SurgProc varchar(200), ProcDesc varchar(200))
--                                                                                                   #
--####################################################################################################


--##       TABLE INSERTIONS     ##
--####################################################################################################
--## WHAT GETS PUT INTO TABLE 1 ##
INSERT INTO @procedures
SELECT 
cv.IDCode,
cv.ClientDisplayName,
cv.VisitIDCode,
cv.AdmitDtm,
cv.DischargeDtm,
ed.Description,
ed.text 

FROM CV3ClientVisit cv

LEFT JOIN cV3ClientEventDeclaration ed
ON cv.GUID=ed.ClientVisitGUID

WHERE ed.typecode = 'Surgery'
AND cv.AdmitDtm > '6/30/12' AND cv.AdmitDtm <='1/1/13'
AND Status = 'Active'

--###########################################################################################
--## THIS IS WHERE WE GET THE DESIRED RESULTS ##	
SELECT visitid, COUNT(visitid) AS '#Surg Procs' 

FROM @procedures

GROUP BY visitid