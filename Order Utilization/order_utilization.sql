DECLARE @T1 TABLE (
	PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
	, MRN                 INT
	, Encounter           INT
	, Order_No            INT
	, Order_Loc           VARCHAR(100)
	, Svc_Cd              VARCHAR(100)
	, Svc_Desc            VARCHAR(500)
	, Ord_Set_ID          VARCHAR(200)
	, Ordering_Party      VARCHAR(500)
	, Performing_Dept     VARCHAR(100)
	, Svc_Dept            VARCHAR(100)
	, Svc_Sub_Dept        VARCHAR(100)
	, Ord_Occ_No          INT
	, Ord_Occ_Obj_ID      INT
	, Ord_Entry_DTime     DATETIME
	, Ord_Start_DTime     DATETIME
	, Ord_Stop_DTime      DATETIME
	, Order_Status        VARCHAR(250)
	, Order_Occ_sts_cd    CHAR(1)
	, Order_Occ_Status    VARCHAR(250)
	, Admit_DateTime      DATETIME
);

WITH T1 AS (
	SELECT A.med_rec_no
	, A.episode_no
	, A.ord_no
	, A.ord_loc
	, A.svc_cd
	, A.svc_desc
	, A.ord_set_id
	, A.pty_name
	, A.perf_dept
	, A.svc_dept
	, A.svc_subdept
	, A.ord_occr_no
	, A.ord_occr_obj_id
	, A.ent_dtime
	, A.Order_Str_Dtime
	, A.stp_dtime
	, C.ord_sts_modf  AS [Order_Status]
	, B.occr_sts_cd
	, B.occr_sts_modf AS [Order_Occ_Status]
	, D.adm_dtime

	FROM smsdss.c_sr_orders_finance_rpt_v    AS A
	INNER JOIN SMSMIR.ord_occr_sts_modf_mstr AS B
	ON A.Occr_Sts = B.occr_sts_modf_cd
	INNER JOIN SMSMIR.ord_sts_modf_mstr      AS C
	ON A.ord_sts = C.ord_sts_modf_cd
	LEFT OUTER JOIN smsmir.acct              AS D
	ON A.episode_no = SUBSTRING(D.pt_id, 5, 8)

	WHERE (
		LEFT(A.svc_cd, 3) IN (
			'004', '005', '006', '013', '014', '023'
		)
		OR
		A.svc_cd IN (
			'XFuseRBC', 'XFusePlatelets', '5025', 'CrsMtchRBC', 
			'XfuseBldPrd'
		)
	)
	AND C.ord_sts_modf IN ('Complete', 'Discontinue')
	AND D.adm_date >= '2015-01-01'
	AND D.adm_date <  '2016-01-01'
	-- CAN ADD UNITIZED ACCOUNTS BACK IN IF NEEDED
	--AND LEFT(A.episode_no, 1) != '7'
	AND (
		A.episode_no < '20000000'
		OR
			(
				A.episode_no > '80000000'
				AND
				A.episode_no < '99999999'
			)
		)
) 
INSERT INTO @T1
SELECT * FROM T1

SELECT MRN
, Encounter
, Order_No
, Order_Loc
, Svc_Desc
, Ord_Set_ID
, Ordering_Party
, Performing_Dept
, Ord_Occ_No
, Ord_Occ_Obj_ID
, Ord_Entry_DTime
, Ord_Start_DTime
, Ord_Stop_DTime
, Order_Status
, Order_Occ_Status
, Admit_DateTime

FROM @T1 T1
WHERE T1.Order_Occ_sts_cd = '4'
--AND YEAR(T1.Admit_DateTime) = 2007
--AND MONTH(T1.Admit_DateTime) >= 1
--AND MONTH(T1.Admit_DateTime) <= 3
