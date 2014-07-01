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
DECLARE @EVENTS TABLE (
    -- Every visit gets an eventID, think of it as another unique key
	  EVENTID   INT IDENTITY(1,1) PRIMARY KEY
	, EVENTDATE DATE        -- Admit Date
	, PERSONID  VARCHAR(20) -- MRN
	, VISIT     VARCHAR(20) -- Encounter / Visit ID
	, DSCH      DATE        -- 
);

-- THIS COMMON TABLE EXPRESSION IS USED TO POPULATE THE EVENTS TABLE
WITH CTE AS (
	SELECT Adm_Date -- Date of admission
	, Med_Rec_No    -- MRN
	, Pt_No         -- Encounter / Visit ID --PTNO_NUM CHANGE BACK TO
	, Dsch_Date     -- Discharge Date

	FROM smsdss.BMH_PLM_PTACCT_V -- Your table here

	WHERE Plm_Pt_Acct_Type = 'I' -- Only want inpatients
	AND PtNo_Num < '20000000'    -- Only want inpatients
	--AND Dsch_Date >= '2004-01-01'
	--AND Dsch_Date < GETDATE()
)
-- INSERTING THE COMMON TABLE EXPRESSION RESULTS INTO THE EVENTS TABLE
INSERT INTO @EVENTS
SELECT C1.Adm_Date
, C1.Med_Rec_No
, C1.Pt_No --
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

FROM @EVENTS crt
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
, A.drg_no                              AS [INITIAL APR-DRG]
, CASE
	WHEN GE.[APR-DRG] IS NULL
	THEN 0
	ELSE 1
  END                                   AS [INITIAL EXCLUSION FLAG]
, B.dsch_disp                           AS [INITIAL DISPO]
, x.GroupEventNum                       AS [CHAIN LEN]
, x.GroupNum                            AS [CHAIN NUMBER]
, x.EventNum                            AS [30 DAY RA COUNT]
, V.READMIT                             AS [READMIT VISIT ID]
, C.drg_no                              AS [READMIT APR-DRG]
, CASE
	WHEN GE2.[APR-DRG] IS NULL
	THEN 0
	ELSE 1
  END                                   AS [RA EXCLUSION FLAG]
, D.dsch_disp                           AS [READMIT DISPO]
, CAST(V.[READMIT DATE] AS DATE)        AS [READMIT DATE]
, V.INTERIM

FROM CountingSequentialEvents        x
	LEFT MERGE JOIN smsdss.vReadmits V
	ON x.VISIT = V.[INDEX] 
	LEFT OUTER JOIN smsmir.mir_drg   A  -- Gets APR-DRG OF INITIAL VISIT
	ON x.VISIT = A.pt_id
	LEFT OUTER JOIN smsmir.mir_vst   B  -- Gets Discharge Dispo OF INITIAL VISIT
	ON A.pt_id = B.pt_id
	LEFT OUTER JOIN smsmir.mir_drg   C  -- GET APR-DRG OF READMIT VISIT
	ON V.READMIT = C.pt_id
	LEFT OUTER JOIN smsmir.mir_vst   D  -- GETS DISCHARGE DISPO OF READMIT VISIT
	ON C.pt_id = D.pt_id
	-- GET THE GLOBALLY EXCLUDED APR-DRGS SO THAT WE CAN FILTER
	-- INITIAL APR-DRG EXCLUSION
	LEFT OUTER JOIN smsdss.c_ppr_apr_drg_global_exclusions GE
	ON A.drg_no = GE.[APR-DRG]
	-- READMIT APR-DRG EXCLUSION
	LEFT OUTER JOIN smsdss.c_ppr_apr_drg_global_exclusions GE2
	ON C.drg_no = GE2.[APR-DRG]

-- THIS LIMITS THE DRG TYPE, IT ALSO DROPS MANY RECORDS FROM THE FINAL RESULT SET
WHERE A.drg_type = '3'
AND C.drg_type = '3'

ORDER BY x.PersonID, x.EventDate

OPTION (MAXRECURSION 1000); -- Max events a person can have