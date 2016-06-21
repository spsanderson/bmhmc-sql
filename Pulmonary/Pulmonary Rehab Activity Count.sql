DECLARE @START DATETIME;
DECLARE @END   DATETIME;

SET @START = '2016-05-01';
SET @END   = '2016-06-01';

DECLARE @Pulm table (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, Encounter           INT
	, Actv_Cd             CHAR(8)
	, Actv_Dtime          DATETIME
	, Actv_Ent_Dtime      DATETIME
	, Adm_Date            DATE
	, Tot_Chg_Amt         FLOAT
	, RN                  INT
);

WITH CTE1 AS (
	SELECT b.PtNo_Num
	, actv_cd
	, actv_dtime
	, actv_entry_dtime
	, b.Adm_Date
	, a.chg_tot_amt
	, ROW_NUMBER() OVER(
		PARTITION BY b.ptno_num, a.actv_dtime
		ORDER BY a.actv_dtime
	) AS rn

	FROM smsmir.mir_actv              AS A
	LEFT JOIN smsdss.BMH_PLM_PtAcct_V AS B
	ON a.pt_id = b.Pt_No
		AND a.unit_seq_no = b.unit_seq_no

	WHERE LEFT(a.actv_cd,3) = '042'
	AND a.actv_dtime >= @START
	AND a.actv_dtime < @END
	AND a.chg_tot_amt > 0
)

INSERT INTO @Pulm
SELECT * FROM CTE1
SELECT * FROM @Pulm AS A WHERE A.RN = 1
-----

--DECLARE @MAXPulm TABLE (
--	PK INT IDENTITY(1, 1) PRIMARY KEY
--	, Encounter           INT
--	, MaxRN               INT
--);

--INSERT INTO @MAXPulm
--SELECT *
--FROM (
--	SELECT a.Encounter
--	, max_rn 

--	FROM @Pulm AS A
--	INNER JOIN (
--		SELECT a.Encounter, MAX(a.rn) AS max_rn
--		FROM @Pulm AS A
--		GROUP BY a.Encounter
--	) groupedVisits
--	ON a.Encounter = groupedVisits.Encounter
--		and a.RN = groupedVisits.max_rn
--) A

--SELECT DISTINCT(A.ENCOUNTER)
--, a.Adm_Date
--, b.MaxRN

--FROM @Pulm          AS A
--INNER JOIN @MAXPulm AS B
--ON a.Encounter = b.Encounter
