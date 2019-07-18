/*=================================================================================================
Rate of opioid reversal agent administration on inpatient care units per 1,000 patient days
Numerator: Number of naloxone doses administered on inpatient care units
Denominator: Number of total patient days

Notes:
Inclusion Criteria:
	- Inpatient
	- Intensive Care Unit (ICU)
	- Medical/Surgical
	- Step-Down/Intermediate
	- Critical Care Unit (CCU)
Exclusion Criteria:
	- Outpatient
	- Emergency Department
	- PPS-exempt units (Psych, Rehab)
	- All procedural and perioperative areas (i.e. - OR, PACU, Radiology, Cath Lab, Endoscopy, etc.)
	- Low-dose, continuous infusions of naloxone
=================================================================================================*/

DECLARE @START DATE;
DECLARE @END DATE;

SET @START = '2016-01-01';
SET @END = '2017-01-01';

-----
SELECT a.pt_no
, a.ord_no
, a.svc_desc
, a.ord_pty_name
, a.ent_dtime
, b.vst_start_dtime
, a.src_hosp_svc
, a.ord_pty_spclty
, a.nurs_sta

INTO #TEMP_A

FROM smsdss.ord_v as a
LEFT OUTER JOIN smsdss.bmh_plm_ptacct_v as b
ON a.pt_no = b.PtNo_Num

WHERE A.svc_cd IN (
	'PRE_6474IV'       -- Naloxone Hcl (Narcan)  0.2 MG IV PRN Resp Distress
	, 'PRE_P2311Q2MIN' -- Naloxone (Narcan) 0.1 MG IVPUSH Every 2 Min PRN Opiate Reversal
	, 'PRE_P2311P'     -- Naloxone (Narcan) 0.4 MG IVPUSH PRN Resp Distress
	, 'PRE_P2310OT'    -- Naloxone (Narcan) 1 MG IVPUSH ONE-TIME
)
AND A.ent_dtime >= @start
AND A.ent_dtime < @end
AND a.ent_dtime > b.vst_start_dtime
AND a.ord_pty_spclty != 'EMRED'
AND a.loc_cd != 'EDICMS'
AND a.src_nurs_sta != 'EMER'
AND a.nurs_sta NOT IN (
	'EMER', 'PACU', 'SICU', 'CATH', 'PSY'
)
AND a.preadm_ord_ind_cd != '1'
AND LEFT(b.PtNo_Num, 1) = '1'
AND b.tot_chg_amt > 0
;

-----

SELECT SUM(DAYS_STAY)
FROM smsdss.BMH_PLM_PtAcct_V
WHERE PtNo_Num IN (
	SELECT Pt_No
	FROM #TEMP_A
)
OPTION(FORCE ORDER)
;

-----

SELECT COUNT(*)
FROM #TEMP_A;

-----

DROP TABLE #TEMP_A