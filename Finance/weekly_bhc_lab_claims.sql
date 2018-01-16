/*
=======================================================================
Get the intital patients that have lab claims for BHC
=======================================================================
*/
SELECT a.pt_id
, c.Pt_Name
, c.User_Pyr1_Cat
, a.actv_dtime
, a.actv_Cd
, b.actv_name
, bb.clasf_cd            AS [CPT/HCPCs]
, CAST(d.price AS MONEY) AS [Unit_Price]
, (
	SELECT SUM(a.actv_tot_qty)
	FROM smsmir.mir_actv cc
	WHERE a.actv_cd = cc.actv_cd 
	AND a.actv_dtime = cc.actv_dtime 
	AND a.pt_id = cc.pt_id
	GROUP BY cc.actv_cd, cc.actv_dtime, cc.pt_id
)                        AS [Quantity]

INTO #TBL_1

FROM smsmir.mir_actv                               AS a
LEFT OUTER JOIN smsmir.mir_actv_mstr               AS b
On a.actv_Cd = b.actv_Cd
LEFT OUTER JOIN smsdss.BMH_PLM_PtAcct_V            AS c
ON a.pt_id = c.Pt_No 
	AND a.unit_seq_no = c.unit_Seq_no
LEFT OUTER JOIN smsmir.mir_Actv_proc_seg_xref      AS bb
ON a.actv_cd = bb.actv_cd 
	AND bb.proc_pyr_ind = 'H'
LEFT OUTER JOIN smsdss.c_CMS_2018_Lab_Fee_Schedule AS d
ON bb.clasf_cd = d.HCPCS 
	AND d.modifier IS NULL

WHERE a.hosp_Svc = 'BHC'
AND actv_dtime >= '06/01/2016'
AND actv_Dtime <= '06/07/2016'
AND a.pt_id NOT IN (
	SELECT pt_no
	FROM smsdss.BMH_PLM_PtAcct_V
	WHERE hosp_svc = 'BHC'
	AND Adm_Date >= '12/31/2015'
	AND adm_Date <= '04/01/2016'
	AND tot_pay_amt < '0'
)
AND D.Price IS NOT NULL

GROUP BY a.pt_id
, c.Pt_Name
, c.User_Pyr1_Cat
, a.actv_dtime
, a.actv_Cd
, b.actv_name
, bb.clasf_cd
, d.price

order by a.pt_id, a.actv_dtime, a.actv_cd
-----------------------------------------------------------------------
/*
Get the toal charges for each activity code
*/
SELECT A.*
, CAST(A.UNIT_PRICE * A.Quantity AS MONEY) AS [Total Actv Charge]

INTO #TBL_2

FROM #TBL_1 AS A
-----------------------------------------------------------------------
/*
get tot charges per patient encounter
*/
SELECT A.PT_ID
, SUM(A.[Total Actv Charge]) AS [Total Encounter Charges]

INTO #TBL_3

FROM #TBL_2 AS A

GROUP BY a.pt_id
-----------------------------------------------------------------------
/*
Create a Basic Metobolic Panel flag
*/
SELECT A.*
, B.[Total Encounter Charges]
, (B.[Total Encounter Charges] * 0.80) AS [20% Reduction]
, (B.[Total Encounter Charges] * 0.75) AS [25% Reduction]
, CASE
	WHEN A.ACTV_CD = '00407627'
		THEN 1
		ELSE 0
  END AS [BMP Flag]

INTO #TBL_4

FROM #TBL_2 AS A
LEFT OUTER JOIN #TBL_3 AS B
ON A.PT_ID = B.PT_ID

--WHERE A.PT_ID = '0000########' Encouter Check
-----------------------------------------------------------------------
/*
Create a table that holds all the account numbers with a BMP
*/
SELECT A.*

INTO #TBL_5

FROM #TBL_4 AS A

WHERE A.[BMP Flag] = 1
-----------------------------------------------------------------------
/*
Create a flag for the child orders that cannot be charges becaus they
are art of the panel and therefore should be excluded.
*/
SELECT *
, CASE
	WHEN A.PT_ID IN (
		SELECT AA.PT_ID
		FROM #TBL_5 AA
	)
		AND A.ACTV_CD IN (
		'00400572', -- bun
		'00400671', -- calcium
		'00400788', -- chlorides
		'00400838', -- co2
		'00400945', -- creatinine
		'00401760', -- glucose
		'00403170', -- potassium
		'00403642'  -- sodium
	)
		THEN 1
		ELSE 0
  END AS [Child Ord Drop Flag]

INTO #TBL_6

FROM #TBL_4 AS A

-----------------------------------------------------------------------
/*
Get rid of all of the rows that have a child order that needs to be
excluded
*/
SELECT A.PT_ID
, A.PT_NAME
, A.USER_PYR1_CAT
, A.ACTV_DTIME
, A.ACTV_CD
, A.ACTV_NAME
, A.[CPT/HCPCs]
, CAST(A.UNIT_PRICE AS MONEY)                          AS UNIT_PRICE
, A.QUANTITY
, ROUND(CAST((A.QUANTITY * A.UNIT_PRICE) AS MONEY), 2) AS [TOTAL ACTIVITY CHARGES]

INTO #TBL_7

FROM #TBL_6 AS A

WHERE A.[Child Ord Drop Flag] <> 1
-----------------------------------------------------------------------
/*
Sum up all the activity charges per encoutner without excluded child
orders that do not belong.
*/
SELECT A.PT_ID
, SUM(A.[TOTAL ACTIVITY CHARGES]) AS [TOTAL ENCOUNTER CHARGES]

INTO #TBL_8

FROM #TBL_7 AS A

GROUP BY A.PT_ID
-----------------------------------------------------------------------
/*
Get a row number for ever line of a patient encounter, this will be used
to clean up the results in the end.
*/
SELECT A.*
, B.[TOTAL ENCOUNTER CHARGES]
, ROW_NUMBER() OVER(
	PARTITION BY A.PT_ID
	ORDER BY A.PT_ID
) AS RN

INTO #TBL_9

FROM #TBL_7      AS A
LEFT JOIN #TBL_8 AS B
ON A.PT_ID = B.PT_ID
-----------------------------------------------------------------------
-- cleaning up result set
SELECT A.PT_ID
, A.PT_NAME
, A.USER_PYR1_CAT
, A.ACTV_DTIME
, A.ACTV_CD
, A.ACTV_NAME
, A.[CPT/HCPCs]
, A.UNIT_PRICE
, A.QUANTITY
, A.[TOTAL ACTIVITY CHARGES]
, CASE
	WHEN A.[TOTAL ENCOUNTER CHARGES] != 0
		AND A.RN <> 1
			THEN ''
			ELSE A.[TOTAL ENCOUNTER CHARGES]
  END AS [TOTAL ENCOUNTER CHARGES]

INTO #TBL_10

FROM #TBL_9 AS A
-----------------------------------------------------------------------
-- cleaning up result set
SELECT *
, CAST(A.[TOTAL ENCOUNTER CHARGES] AS VARCHAR) AS [TOTAL ENC CHARGES]
, CASE
	WHEN A.[TOTAL ENCOUNTER CHARGES] <> 0
		THEN ROUND(CAST((A.[TOTAL ENCOUNTER CHARGES] * 0.80) AS MONEY), 2)
  END AS [20% REDUCTION]
, CASE
	WHEN A.[TOTAL ENCOUNTER CHARGES] <> 0
		THEN ROUND(CAST((A.[TOTAL ENCOUNTER CHARGES] * 0.75) AS MONEY), 2)
  END AS [25% REDUCTION]

INTO #TBL_11

FROM #TBL_10 AS A
-----------------------------------------------------------------------
-- cleaning up result set
SELECT A.PT_ID
, A.PT_NAME
, A.USER_PYR1_CAT
, A.ACTV_DTIME
, A.ACTV_CD
, A.ACTV_NAME
, A.[CPT/HCPCs]
, A.UNIT_PRICE
, A.QUANTITY
, A.[TOTAL ACTIVITY CHARGES]
, CASE
	WHEN A.[TOTAL ENC CHARGES] = '0.00'
		THEN ''
		ELSE A.[TOTAL ENC CHARGES]
  END AS [TOTAL ENCOUNTER CHARGES]
, CAST(A.[20% REDUCTION] AS VARCHAR) AS [20% REDUCTION]
, CAST(A.[25% REDUCTION] AS VARCHAR) AS [25% REDUCTION]

INTO #TBL_12

FROM #TBL_11 AS A
-----------------------------------------------------------------------
-- Final join and result set
SELECT A.PT_ID
, A.PT_NAME
, A.USER_PYR1_CAT
, A.ACTV_DTIME
, A.ACTV_CD
, A.ACTV_NAME
, A.[CPT/HCPCs]
, A.UNIT_PRICE
, A.QUANTITY
, A.[TOTAL ACTIVITY CHARGES]
, A.[TOTAL ENCOUNTER CHARGES]
, CASE
	WHEN A.[20% REDUCTION] IS NULL
		THEN ''
		ELSE A.[20% REDUCTION]
  END AS [20% REDCUTION]
, CASE
	WHEN A.[25% REDUCTION] IS NULL
		THEN ''
		ELSE A.[25% REDUCTION]
  END AS [25% REDUCTION]

FROM #TBL_12 AS A
-----------------------------------------------------------------------
-- DROP TABLE STATEMENTS
DROP TABLE #TBL_1
DROP TABLE #TBL_2
DROP TABLE #TBL_3
DROP TABLE #TBL_4
DROP TABLE #TBL_5
DROP TABLE #TBL_6
DROP TABLE #TBL_7
DROP TABLE #TBL_8
DROP TABLE #TBL_9
DROP TABLE #TBL_10
DROP TABLE #TBL_11
DROP TABLE #TBL_12