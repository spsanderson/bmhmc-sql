-- A report for patients discharged with the following ICD-9 Codes 263.9, 262, 263.8, 260
-- inside a specific date range along with a query for total discharges for the same specified date range
--
--	Alias'(s)
		-- dbo.CV3ClientVisit = CV
		-- dbo.CV3HealthIssueDeclaration = HID
		-- dbo.CV3CodedHealthIssue = CHI
--
-- Columns being used, ie "Name", "Diagnosis"
select
	CV.AdmitDtm, CV.VisitIDCode, CV.ClientDisplayName, HID.ShortName, CHI.Code

-- DB Table(s) being used
from
	dbo.CV3ClientVisit CV left join dbo.CV3HealthIssueDeclaration HID 
	
	-- The HID Table was `left join` to the CV table in order to get the Health Issue Declaration
	-- matched up with the correct patient by doing the following GUID look up
	
		on CV.GUID = HID.ClientVisitGUID
	left join dbo.CV3CodedHealthIssue CHI
		on HID.CodedHealthIssueGUID = CHI.GUID

-- Filters
where 
	AdmitDtm between '04/01/2012' and '10/25/2012'
	-- We wanted a specified range

and 
	CHI.Code in ('263.9', '262', '263.8', '260')
	-- We only care about the above ICD-9 codes
	
--------------------------------------------------------------------------------------------------
-- All Discharges for the same date range specified above
--
--	Alias'(s) 
		-- dbo.CV3ClientVisit = cv
SET ANSI_NULLS OFF
Go 

-- Columns Being Used
select 
	cv.VisitIDCode, cv.ClientDisplayName, cv.DischargeDtm, cv.TypeCode

-- DB Table(s) being used
from
	dbo.CV3ClientVisit cv


-- Filters
where 
	cv.DischargeDtm between '04/01/2012' and '10/25/2012'

and 
	cv.TypeCode like '%Inpatient%'