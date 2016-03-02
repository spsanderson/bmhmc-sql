DECLARE @START DATETIME;
DECLARE @END   DATETIME;

SET @START = '2016-02-01';
SET @END   = '2016-03-01';

/*
=======================================================================
W A S - T H E R E - T I M E - O N - 4 N O R
=======================================================================
*/
DECLARE @FourN TABLE (
	PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
	, Encounter           INT
	, From_Nurse_Sta      CHAR(4)
	, To_Nurse_Sta        CHAR(4)
	, RN                  INT
);

WITH FourN AS (
	SELECT episode_no
	--, xfer_eff_dtime
	, nurs_sta_from
	--, bed_from
	, nurs_sta as to_nurs_sta
	--, bed      as to_bed
	, ROW_NUMBER() OVER(
		PARTITION BY episode_no
		ORDER BY seq_no asc
	) AS RN

	FROM smsmir.mir_cen_hist
	
	WHERE nurs_sta is not null
	AND (
		nurs_sta = '4NOR'
		OR
		nurs_sta_from = '4NOR'
	)
	AND xfer_eff_dtime >= @START 
)

INSERT INTO @FourN
SELECT * FROM FourN AS A
WHERE A.RN = 1

--SELECT * FROM @FourN

/*
=======================================================================
P U L L - I T - T O G E T H E R
=======================================================================
*/
SELECT a.PtNo_Num
, a.Med_Rec_No
, CAST(a.Adm_Date AS date)  AS [Admit Date]
, CAST(a.Dsch_Date AS date) AS [Dsch Date]
, a.prin_dx_cd
, a.drg_no
, b.LIHN_Service_Line
, D.READMIT
, D.[READMIT DATE]
, D.INTERIM
, CASE
	WHEN LEFT(A.PtNo_Num, 1) = '8'
		THEN 1
		ELSE 0
  END                       AS [ER Visit]
, CASE
	WHEN LEFT(A.PtNo_Num, 1) = '1'
		THEN 1
		ELSE 0
  END                       AS [IP Visit]
, E.adm_src_desc
, CASE
	WHEN F.Encounter IS NOT NULL
		THEN 1
		ELSE 0
  END                       AS [4N Flag]

-- FROM CLAUSE
FROM smsdss.c_DSRIP_COPD                             AS C
INNER MERGE JOIN SMSDSS.BMH_PLM_PTACCT_V             AS A
ON C.Med_Rec_No = A.Med_Rec_No
LEFT OUTER JOIN SMSDSS.c_LIHN_Svc_Lines_Rpt2_ICD10_v AS B
ON A.Pt_No = B.pt_id
LEFT OUTER JOIN SMSDSS.c_Readmission_IP_ER_v         AS D
ON A.PtNo_Num = D.[INDEX]
LEFT OUTER JOIN SMSDSS.adm_src_dim_v                 AS E
ON A.Adm_Source = E.adm_src
	AND E.orgz_cd = 'NTX0'
LEFT OUTER JOIN @FourN                               AS F
ON A.PtNo_Num = F.Encounter

-- WHERE CLAUSE
WHERE Adm_Date >= @START
AND Adm_Date < @END
AND LEFT(A.PTNO_NUM, 4) != '1999'
AND hosp_svc != 'SUR'
AND (
	PtNo_Num < '20000000'
	OR
			(
				A.PtNo_Num >= '80000000' -- ER VISITS
				AND
				A.PtNo_Num < '90000000'
			)
	)

-- ORDER CLAUSE
ORDER BY c.Med_Rec_No
, Adm_Date
