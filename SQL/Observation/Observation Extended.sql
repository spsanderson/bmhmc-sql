DECLARE @START DATE;
DECLARE @END   DATE;

SET @START = '2016-01-01';
SET @END   = '2016-02-01';

DECLARE @Readmit TABLE (
	PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
	, MRN                 INT
	, Index_Encounter     INT
	, Readmit_Encounter   INT
	, Days_Until_Readmit  INT
);

WITH RA AS (
	SELECT [MRN]
	, [INDEX]
	, [READMIT]
	, [INTERIM]

	FROM SMSDSS.c_Readmission_IP_ER_v

	WHERE [INTERIM] < 31
	AND LEFT([READMIT], 1) IN ('8', '9')
	AND [READMIT DATE] >= DATEADD(DAY, -30, @START)
	AND [READMIT DATE] <= DATEADD(DAY, 30, @END)
)

INSERT INTO @Readmit
SELECT * FROM RA

SELECT DISTINCT(A.PtNo_Num)
, CASE
	WHEN E.Readmit_Encounter IS NOT NULL
	THEN 1
	ELSE 0
  END                               AS [Is_Readmit]
, E.Index_Encounter
, A.Med_Rec_No
, a.prin_dx_cd
, F.dx_cd_desc
, A.Pyr1_Co_Plan_Cd
, A.tot_chg_amt                     AS [Total Charges]
, A.reimb_amt
, A.tot_adj_amt
, A.tot_pay_amt
, D.pract_rpt_name
, C.obv_strt_Dtime
, C.dsch_strt_dtime
, DATEDIFF(HOUR, C.obv_strt_Dtime
			   , C.dsch_strt_dtime) AS [Hours in Observation]

FROM smsdss.bmh_plm_ptacct_v        AS A
LEFT OUTER JOIN smsmir.mir_actv     AS B
ON a.Pt_No = b.pt_id 
	AND A.unit_seq_no = b.unit_seq_no
LEFT OUTER JOIN SMSDSS.c_obv_Comb_1 AS C
ON C.pt_id = A.PtNo_Num
LEFT OUTER JOIN SMSDSS.pract_dim_v  AS D
ON A.Adm_Dr_No = D.src_pract_no
	AND D.orgz_cd = 'S0X0'
-- WE JOIN THE Encounter on the Readmit to see if it is
-- a 30 day readmit or not
LEFT OUTER JOIN @Readmit            AS E
ON A.PtNo_Num = E.Readmit_Encounter
LEFT OUTER JOIN SMSDSS.dx_cd_dim_v  AS F
ON A.prin_dx_cd = F.dx_cd
	AND A.prin_dx_cd_schm = F.dx_cd_schm

WHERE B.actv_cd = '04700035'
AND B.actv_dtime >= @START
AND B.actv_dtime < @END
--AND A.Adm_Date >= @START
--AND A.Adm_Date < @END

AND A.Plm_Pt_Acct_Type <> 'I'