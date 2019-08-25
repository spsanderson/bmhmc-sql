-- This gets our base population, meaning all persons discharged in 2018
-- where the visit meets the finance filter
SELECT Med_Rec_No
, PtNo_Num
, Adm_Date
, Dsch_Date
, hosp_svc
-- we need the event_num flag because we care about the order of events
-- specifically we care about then in the order the occur by adm_date
, [Event_Num] = ROW_NUMBER() OVER(PARTITION BY med_rec_no ORDER BY ADM_date)
-- WE want a psy flag because we care about visit subsequent to a PSY visit
-- so we use this and the event_num flag in concert/conjunction with each other
, [PSY_Flag] = CASE WHEN hosp_svc = 'PSY' THEN '1' ELSE '0' END

INTO #TEMPA

FROM smsdss.bmh_plm_ptacct_v AS A

WHERE Dsch_Date >= '01-01-2018'
AND dsch_date < '12-31-2018'
-- finance filters
AND tot_chg_amt > 0
AND LEFT(PTNO_NUM, 1) != '2'
AND LEFT(PTNO_NUM, 4) != '1999'

ORDER BY Med_Rec_No, A.Adm_Date
;

-- Here we just want all the psy visits
SELECT A.*
INTO #TEMPB
FROM #TEMPA AS A
WHERE A.hosp_svc = 'PSY'
;

-- Here we want all the Non PSY visits of patients who ALSO have had a PSY visit
SELECT B.*
INTO #TEMPC
FROM #TEMPA AS B
WHERE B.hosp_svc != 'PSY'
-- This AND statement ensures that we get MRNS of those patients that have had
-- a PSY visit from above. This means a paitent has had both PSY AND Non-PSY visits
AND B.Med_Rec_No IN (
	SELECT DISTINCT Med_Rec_No
	FROM #TEMPB
)
;

-- Union the data together
SELECT Med_Rec_No
, PtNo_Num
, Adm_Date
, Dsch_Date
, hosp_svc
, Event_Num
, PSY_Flag
-- This keep_flag will be used once we query the table created
-- We will use this to ensure that a patient had at least 2 visits
, [Keep_Flag] = ROW_NUMBER() OVER(PARTITION BY MED_REC_NO ORDER BY ADM_DATE)

INTO #TEMPD

-- In this UNION ALL we want all PSY visits and then all non-psy and we want to make
-- sure that the non psy event number is > the psy event number as this will ensure
-- that the non-psy visit is subsequent to the psy visit.
FROM (
	SELECT B.*
	FROM #TEMPB AS B -- ALL PSY VISITS

	UNION ALL

	SELECT C.*
	FROM #TEMPC AS C -- ALL NON PSY VIISTS
	WHERE C.Med_Rec_No IN (
		SELECT ZZZ.Med_Rec_No
		FROM #TEMPB AS ZZZ
		WHERE ZZZ.Med_Rec_No = C.Med_Rec_No
		-- THE BELOW ENSURES THAT NON PSY EVENT NUMBER IS > PSY EVENT NUMBER
		AND C.Event_Num > ZZZ.Event_Num
	)
) AS A

ORDER BY MED_REC_NO, Event_Num
;

SELECT A.Med_Rec_No
, A.PtNo_Num
, CAST(A.ADM_DATE AS DATE) AS [Adm_Date]
, CAST(A.Dsch_Date AS DATE) AS [Dsch_Date]
, A.hosp_svc
, HS.hosp_svc_name

FROM #TEMPD AS A
LEFT OUTER JOIN SMSDSS.hosp_svc_dim_v AS HS
ON A.hosp_svc = HS.hosp_svc
	AND HS.orgz_cd = 'S0X0'
WHERE A.Med_Rec_No IN (
	SELECT DISTINCT ZZZ.MED_REC_NO
	FROM #TEMPD AS ZZZ
	-- This ensures that the med_rec_no in question had more than one visit, meaning
	-- they had more than just the initial PSY visit from #tempb
	WHERE Keep_Flag > 1
)
;

--SELECT * FROM #TEMPA WHERE Med_Rec_No = ''
--;
--SELECT * FROM #TEMPB WHERE Med_Rec_No = ''
--;
--SELECT * FROM #TEMPC WHERE Med_Rec_No = ''
--;
--SELECT * FROM #TEMPD WHERE Med_Rec_No = ''
--;

-- drop table statements
DROP TABLE #TEMPA;
DROP TABLE #TEMPB;
DROP TABLE #TEMPC;
DROP TABLE #TEMPD;

/*
Or use a CTE
*/
with ACC as (
  SELECT Med_Rec_No
       , PtNo_Num
       , Adm_Date
       , Dsch_Date
       , hosp_svc
       , CASE WHEN B.READMIT IS NULL THEN 'No' ELSE 'Yes' END AS [Readmit Status]
       , [Event_Num] = ROW_NUMBER() over(partition by med_rec_no order by ADM_date)
       , [PSY_Flag] = CASE WHEN hosp_svc = 'PSY' THEN '1' ELSE '0' END
  FROM smsdss.BMH_PLM_PtAcct_V AS A
  LEFT OUTER JOIN smsdss.vReadmits AS B
  ON A.PtNo_Num = b.[INDEX] AND B.INTERIM < 31
  WHERE Dsch_Date >= '01-01-2018'
  AND dsch_date < '12-31-2018'
  AND A.tot_chg_amt > 0
  AND LEFT(A.PTNO_NUM, 1) != '2'
  AND LEFT(A.PTNO_NUM, 4) != '1999'
)
, EMERG as (
  SELECT ACC.* FROM ACC WHERE hosp_svc = 'PSY'
)
, PSY as (
  SELECT ACC.*
  FROM ACC
  WHERE hosp_svc != 'PSY'
  AND Med_Rec_No IN (SELECT DISTINCT Med_Rec_No FROM EMERG)
)
, ACC_REL as (
  SELECT Med_Rec_No
       , PtNo_Num
       , Adm_Date
       , Dsch_Date
       , hosp_svc
       , [Readmit Status]
       , Event_Num
       , PSY_Flag
       , [Keep_Flag] = ROW_NUMBER() OVER(PARTITION BY MED_REC_NO ORDER BY ADM_DATE)
  FROM (
    SELECT * FROM EMERG
    UNION ALL
    SELECT * FROM PSY
    WHERE PSY.Med_Rec_No IN (
        SELECT e.Med_Rec_No
        FROM EMERG AS e
        WHERE e.Med_Rec_No = PSY.Med_Rec_No
        AND PSY.Event_Num > e.Event_Num
    )
  ) AS A
)
SELECT A.Med_Rec_No
     , A.PtNo_Num
     , CAST(A.ADM_DATE AS DATE) AS [Adm_Date]
     , CAST(A.Dsch_Date AS DATE) AS [Dsch_Date]
     , A.hosp_svc
     , HS.hosp_svc_name
     , A.[Readmit Status]
     , A.Event_Num
     , A.Keep_Flag
FROM ACC_REL AS A
LEFT OUTER JOIN SMSDSS.hosp_svc_dim_v AS HS
ON A.hosp_svc = HS.hosp_svc AND HS.orgz_cd = 'S0X0'
WHERE A.Med_Rec_No IN (
    SELECT DISTINCT rel.MED_REC_NO
    FROM ACC_REL AS rel
    WHERE Keep_Flag > 1
)
ORDER BY Med_Rec_No, Adm_Date
;