-- THIS CREATES A TABLE WHERE ALL THE DESIRED VISIT ID NUMBERS WILL GO
-- THIS TABLE IS A UNIQUE CLUSTER
CREATE TABLE #T1
(
VISIT_ID VARCHAR(20) UNIQUE CLUSTERED
)

-- WHAT GETS INSERTED INTO #T1. IT CAN BE QUICKER TO USE #T1 RATHER
-- THAN @T1
INSERT INTO #T1

-- THE INFORMATION WE WANT SELECTED, IN THIS CASE JUST VISIT ID NUMBERS
SELECT DISTINCT PtNo_Num

-- THIS IS THE DATABASE WHERE THE VISIT ID'S COME FROM
FROM smsdss.BMH_PLM_PtAcct_V

/**
FILTER(S) THIS IS WHERE WE SET SOME FILTERS IN ORDER TO GET ONLY  THOSE
PATIENTS THAT ARE STILL ON SITE IN A BED SOMEWHERE IN THE FACILITY.
WE ARE SAYING THAT THE PEOPLE WE WANT DO NOT HAVE A DISCHARGE DATE WHICH
MEANS THEY ARE STILL HERE AND THEY MUST BE HERE FOR MORE THAN 0 DAYS, 
WHICH IN OUR DATABASE WILL BE ANYONE WHO IS CURRENTLY HERE AND THEY 
MUST BE OF THE TYPE 'I' WHICH IS INPATIENT
**/
WHERE Dsch_DTime IS NULL
AND Days_Stay > 0
AND Plm_Pt_Acct_Type = 'I'

OPTION (RECOMPILE);

-- THIS IS WHERE WE FIND OUT IF THE MITTS WAS USED AT LEAST ONCE
WITH OBS AS 
	(SELECT episode_no,
		MAX(CASE
				WHEN dsply_val LIKE 'Mitts%'
				THEN 1
			END) AS [MITTS]
		
		-- DATABASE(S) USED
		FROM smsmir.obsv
		
		-- FILTER(S) USED
		WHERE form_usage = 'Shift Flowsheet'
		AND obsv_cd_ext_name = 'Safety'
		GROUP BY episode_no
	)

-- THIS IS OUR FINAL SELECT STATEMENT THAT WILL GIVE US THE RESULTS FROM
-- THE DATABASE AND FILTERS ASCRIBED ABOVE
SELECT #T1.VISIT_ID AS [VISIT ID]
, ISNULL(OBS.[MITTS], 0) AS [MITTS USED?]

-- DB(S) USED
FROM #T1
LEFT JOIN
OBS
ON #T1.VISIT_ID = OBS.episode_no

-- THIS MEANS EVERYONE WITH A 1 WILL SHOW UP FIRST
ORDER BY [MITTS USED?] DESC

-- THIS DROPS THE TEMPORARY TABLE FROM MEMORY
DROP TABLE #T1