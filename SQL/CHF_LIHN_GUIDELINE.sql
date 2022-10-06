-- VARIABLE DECLARATION AND INITIALIZATION
--DECLARE @START    DATE;
--DECLARE @END      DATE;
DECLARE @LIHNTYPE VARCHAR(50);
DECLARE @DSPLYVAL VARCHAR(250);

--SET @START    = '2014-04-01';
--SET @END      = '2014-05-01';
SET @LIHNTYPE = 'A_LIHN TYPE';
SET @DSPLYVAL = '%CHF exclusion cardiogenic shock%';

-- COMMON TABLE EXPRESSION
;WITH LIHNCHF AS (
	SELECT OBS.episode_no
	, PAV.Med_Rec_No
	, PAV.Pt_Name
	, PAV.Pt_Age
	, PAV.Adm_Date
	, OBS.obsv_cd_ext_name
	, OBS.dsply_val
	/*
	BELOW WE WANT THE EARLIEST VERSION OF THE COMMENT
	THAT IS ON THE SHIFT ASSESSMENT SHEET
	*/
	, RN = ROW_NUMBER() OVER (PARTITION BY OBS.EPISODE_NO
							  ORDER BY OBS.VAL_MODF ASC) 

	FROM smsmir.sr_obsv                OBS
	JOIN smsdss.BMH_PLM_PtAcct_V       PAV
	ON OBS.episode_no = PAV.PtNo_Num

	WHERE OBS.dsply_val LIKE @DSPLYVAL   -- WHAT GUIDELINE WE WANT
	AND obsv_cd_ext_name = @LIHNTYPE     -- WANT LIHN GUIDELINE
	AND form_usage = 'Shift Assessment'  -- SHIFT ASSESSMENT FORM
	--AND PAV.Adm_Date >= @START
	--AND PAV.Adm_Date < @END
	AND Dsch_Date IS NULL                -- MAKE SURE PT IS STILL HERE
	AND PAV.Plm_Pt_Acct_Type = 'I'       -- ONLY INPATIENTS
	AND PAV.PtNo_Num < '20000000'        -- ONLY INPATIENTS
)
SELECT *
FROM LIHNCHF
WHERE RN = 1