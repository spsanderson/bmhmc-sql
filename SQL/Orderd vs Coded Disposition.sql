-- Declare and Set variables
DECLARE @DischargeDate1 DATE;
DECLARE @DischargeDate2 DATE;

SET @DischargeDate1 = '2015-01-01';
SET @DischargeDate2 = '2016-01-01';

-- Get Inpatient Discharges
DECLARE @Discharges TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, Encounter           INT
	, MRN                 INT
	, Admit_Date_Time     DATETIME
	, Discharge_Date_Time DATETIME
	, Disposition         CHAR(3)
);

WITH CTE1 AS (
	SELECT PtNo_Num
	, Med_Rec_No
	, vst_start_dtime
	, vst_end_dtime
	, dsch_disp

	FROM SMSDSS.BMH_PLM_PtAcct_V
	WHERE Plm_Pt_Acct_Type = 'I'
	AND PtNo_Num < '20000000'
	AND Dsch_Date >= @DischargeDate1
	AND Dsch_Date < @DischargeDate2
)

INSERT INTO @Discharges
SELECT *
FROM CTE1 C1

--SELECT *
--FROM @Discharges

-- Get the final Discharge Order ADT09
DECLARE @FinalDischOrder TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, Encounter           INT
	, Order_Num           INT
	, Svc_Desc            CHAR(12)
	, Order_Entry_Dtime   DATETIME
	, Order_As_Written    VARCHAR(MAX)
	, Order_Desc_Code     CHAR(3)
	, RN                  INT
);

WITH CTE2 AS (
	SELECT episode_no
	, ord_no
	, svc_desc
	, ent_dtime
	, desc_as_written
	, SUBSTRING(desc_as_written, PATINDEX('%(A-%', desc_as_written) + 1, 1) +
	  SUBSTRING(desc_as_written, PATINDEX('%(A-%', desc_as_written) + 3, 2)
	  AS [Last_Soarian_Discharge_Order - ADT09]
	, ROW_NUMBER() OVER(
		PARTITION BY episode_no
		ORDER BY ent_dtime DESC
	) AS rn

	FROM smsmir.sr_ord

	WHERE svc_cd = 'ADT09'
	AND episode_no IN (
		SELECT Encounter
		FROM @Discharges
	)
) 

INSERT INTO @FinalDischOrder
SELECT *
FROM CTE2 C2
WHERE RN = 1

--SELECT *
--FROM @FinalDischOrder

/*
=======================================================================
Pull it together
=======================================================================
*/

SELECT A.MRN
, A.Encounter
, A.Admit_Date_Time
, A.Discharge_Date_Time
, A.Disposition
, B.Order_Desc_Code
, B.Order_As_Written
, B.Order_Entry_Dtime

FROM @Discharges AS A
LEFT OUTER JOIN @FinalDischOrder AS B
ON A.Encounter = B.Encounter