DECLARE @Dx TABLE (
	PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
	, MRN                 INT
	, Encounter           INT
	, Name                VARCHAR(50)
	, Atn_MD_ID           CHAR(6)
	, MD                  VARCHAR(50)
	, MD_Specialty        VARCHAR(75)
	, Hospital_svc        CHAR(3)
);

WITH DX AS (
	SELECT a.Med_Rec_No
	, a.PtNo_Num
	, a.Pt_Name
	, a.Atn_Dr_No
	, b.pract_rpt_name
	, b.spclty_desc
	, a.hosp_svc

	FROM smsdss.bmh_plm_ptacct_v AS A
	LEFT JOIN smsdss.pract_dim_v AS B
	ON A.Atn_Dr_No = B.src_pract_no
		AND orgz_cd = 's0x0'

	WHERE A.Dsch_Date >= '2015-01-01'
	AND A.Dsch_Date < '2016-01-01'
	AND A.prin_dx_cd in ('280.0', '280.1', '280.8', '280.9', '285.21',
		'285.22', '285.29', '285.3',
		-- icd-10 codes
		'D50.0', 'D50.8', 'D50.1', 'D50.8', 'D50.9', 'D63.1', 'D63.0',
		'D63.8', 'D64.81'
	)
	AND A.hosp_svc in ('INF')

	--order by a.Med_Rec_No
	--, a.PtNo_Num
)

INSERT INTO @Dx
SELECT * FROM DX

--select * from @Dx

DECLARE @IronTRx TABLE (
	PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
	, Encounter           INT
	, Med_Ord_Entry_DT    DATETIME
	, Desc_as_written     VARCHAR(MAX)
	, Svc_Desc            VARCHAR(MAX)
	, RN                  INT
);

WITH IronTRx AS (
	SELECT episode_no
	, ent_dtime
	, desc_as_written
	, svc_desc
	, ROW_NUMBER() OVER(
		PARTITION BY EPISODE_NO
		ORDER BY ENT_DTIME
	) AS RN

	FROM smsmir.sr_ord

	WHERE (
		desc_as_written LIKE '%ferrlecit%'
		OR
		desc_as_written LIKE '%venofer%'
	)
)

INSERT INTO @IronTRx
SELECT * FROM IronTRx
WHERE RN = 1

--SELECT * FROM @IronTRx

SELECT A.MRN
, A.Encounter
, A.Name
, A.MD
, A.MD_Specialty
, A.Hospital_svc
, B.Desc_as_written
, B.Svc_Desc
, B.Med_Ord_Entry_DT

FROM @Dx            AS A
INNER JOIN @IronTRx AS B
ON A.Encounter = B.Encounter