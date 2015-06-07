DECLARE @START DATE;
DECLARE @END   DATE;

SET @START = CONVERT(DATE, GETDATE() -1);
SET @END   = GETDATE();
--
DECLARE @T1 TABLE(
	[Visit ID]                  VARCHAR(MAX)
	, [Admit Date Time]         DATETIME
	, [Discharge Date Time]     DATETIME
	, [Attending MD Number]     VARCHAR(MAX)
	, [Order Number]            VARCHAR(MAX)
	, [Date Time Order Entry]   DATETIME
	, [Service Desc]            VARCHAR(MAX)
	, [Responsible Party]       VARCHAR(MAX)
	, [Last Processing Time]    DATETIME
	, [Row Number]              INT
);

WITH CTE AS (
	SELECT 
		A.episode_no
		, B.vst_start_dtime
		, B.vst_end_dtime
		, B.Atn_Dr_No
		, A.ord_no
		, ent_dtime
		, svc_desc
		, pty_name
		, C.prcs_dtime
		, ROW_NUMBER() OVER (
							PARTITION BY A.EPISODE_NO
							ORDER BY C.prcs_dtime DESC
							) AS [RN]

	FROM smsmir.sr_ord                          A
		LEFT MERGE JOIN smsdss.BMH_PLM_PtAcct_V B
		ON B.PtNo_Num = A.episode_no
		LEFT MERGE JOIN smsmir.ord_sts_hist     C
		ON A.ord_no = c.ord_no
			AND c.hist_no = 4

	WHERE a.sts_no = 4
		AND B.Dsch_Date >= @START
		AND B.Dsch_Date < @END
		AND B.Plm_Pt_Acct_Type = 'I'
		AND B.PtNo_Num < '20000000'
		AND B.drg_no IN ('067','068','069')
		AND C.prcs_dtime >= DATEADD(hour, -12, B.Dsch_DTime)
)

INSERT INTO @T1
SELECT
	CTE.episode_no
	, CTE.vst_start_dtime
	, CTE.vst_end_dtime
	, CTE.Atn_Dr_No
	, CTE.ord_no
	, CTE.ent_dtime
	, CTE.svc_desc
	, CTE.pty_name
	, CTE.prcs_dtime
	, CTE.RN

FROM CTE

SELECT 
	*
	, DATEDIFF(
			hour, 
			t1.[Last Processing Time], 
			t1.[Discharge Date Time]
			) AS [Completed Hours Before Discharge]

FROM @T1 T1