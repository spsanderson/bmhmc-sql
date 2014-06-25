/*
#######################################################################

THIS QUERY WILL MAKE USE OF THE VIEW THAT WAS CREATED BY THE QUERY
"CREATE READMIT VIEW.sql"

THIS QUERY MAKES USE OF A COUPLE OF RECURSIVE CTE'S IN ORDER TO OBTAIN
THE DAISY CHAIN COUNT AND THE COUNT OF CHAINS

#######################################################################
*/

-- CREATE A TABLE WHERE INITIAL ENCOUNTERS WILL BE STORED IN ORDER TO 
-- QUERY LATER ON
CREATE TABLE dbo.EVENTS (
    -- Every visit gets an eventID, think of it as another unique key
	  EVENTID   INT IDENTITY(1,1) PRIMARY KEY
	, EVENTDATE DATE        -- Admit Date
	, PERSONID  VARCHAR(20) -- MRN
	, VISIT     VARCHAR(20) -- Encounter / Visit ID
	, DSCH      DATE        -- 
);
GO
-- THIS COMMON TABLE EXPRESSION IS USED TO POPULATE THE EVENTS TABLE
WITH CTE AS (
	SELECT Adm_Date -- Date of admission
	, Med_Rec_No    -- MRN
	, PtNo_Num      -- Encounter / Visit ID
	, Dsch_Date     -- Discharge Date

	FROM smsdss.BMH_PLM_PTACCT_V -- Your table here

	WHERE Plm_Pt_Acct_Type = 'I' -- Only want inpatients
	AND PtNo_Num < '20000000'    -- Only want inpatients
	AND Dsch_Date >= '2014-01-01'
	AND Dsch_Date < '2014-02-01'
)
-- INSERTING THE COMMON TABLE EXPRESSION RESULTS INTO THE EVENTS TABLE
INSERT INTO dbo.EVENTS
SELECT C1.Adm_Date
, C1.Med_Rec_No
, C1.PtNo_Num
, C1.Dsch_Date

FROM CTE C1

--SELECT * FROM dbo.EVENTS ** You can uncomment this to see the output

-- This table will capture all the following information
DECLARE @EventsWithNum TABLE (
	  EventID   INT                    -- A second unique visit key
	, EventDate DATE                   -- Admit date
	, PersonID  VARCHAR(20)            -- MRN
	, VISIT     VARCHAR(20)            -- Encounter / Visit ID
	, DSCH      DATE                   -- Discharge Date
	, EventNum  INT                    -- 30 Day Readmit Number:
	                                   --  (How many 30day RA's)
	, PRIMARY KEY (EventNum, PersonID) -- Complex Index Key
);
INSERT @EventsWithNum
SELECT crt.EVENTID
, crt.EVENTDATE
, crt.PERSONID
, crt.VISIT
, crt.DSCH
, ROW_NUMBER() OVER(
					PARTITION BY crt.PERSONID
					ORDER BY crt.EVENTDATE
					, CRT.EVENTID
					) AS EventNum

FROM dbo.EVENTS crt
WHERE crt.PERSONID IS NOT NULL -- We don't want NULL Encounter ID's
;

--SELECT * FROM @EventsWithNum ** Uncomment to see intermediate results

-- Another Common Table Expression to get the Sequential Events and counts
WITH CountingSequentialEvents AS (
	SELECT crt.EventID
	, crt.EventDate
	, crt.PersonID
	, crt.VISIT
	, crt.DSCH
	, crt.EventNum
	, 1 AS GroupNum
	, 1 AS GroupEventNum

	FROM @EventsWithNum crt
	
	WHERE crt.EventNum = 1

	UNION ALL

	SELECT crt.EventID
	, crt.EventDate
	, crt.PersonID
	, crt.VISIT
	, crt.DSCH
	, crt.EventNum
	, CASE
		WHEN DATEDIFF(DAY, prev.EventDate, crt.EventDate) <= 30
		THEN prev.GroupNum
		ELSE prev.GroupNum + 1
	  END AS GroupNum
	, CASE
		WHEN DATEDIFF(DAY, prev.EventDate, crt.EventDate) <= 30
		THEN prev.GroupEventNum + 1
		ELSE 1
	  END AS GroupEventNum

	FROM @EventsWithNum                  crt
	JOIN CountingSequentialEvents        prev
	ON crt.PersonID = prev.PersonID
	AND crt.EventNum = prev.EventNum + 1
)
SELECT x.EventID                        AS [EVENT ID]
, x.EventDate                           AS [ADMIT DATE]
, x.PersonID                            AS [MRN]
, x.VISIT                               AS [VISIT ID]
, x.DSCH                                AS [DISCHARGE DATE]
, x.GroupEventNum                       AS [CHAIN LEN]
, x.GroupNum                            AS [CHAIN NUMBER]
, x.EventNum                            AS [30 DAY RA COUNT]
, V.NextVisitID                         AS [READMIT VISIT ID]
, CAST(V.ReadmittedDT AS DATE)          AS [READMIT DATE]
, DATEDIFF(DAY, x.DSCH, V.ReadmittedDT) AS [INTERIM]

FROM CountingSequentialEvents x
LEFT JOIN smsdss.vReadmits    V
ON x.VISIT = V.PtNo_Num

ORDER BY x.PersonID, x.EventDate

OPTION (MAXRECURSION 1000);

DROP TABLE DBO.EVENTS