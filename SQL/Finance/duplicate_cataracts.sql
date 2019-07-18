SELECT B.Med_Rec_No
, A.pt_id
, A.proc_cd
, A.proc_cd_modf1
, A.proc_cd_modf2
, A.proc_cd_modf3
, A.proc_eff_date
, RN = ROW_NUMBER() OVER(
	PARTITION BY B.MED_REC_NO
	ORDER BY A.PROC_EFF_DATE
)

INTO #TEMPA

FROM smsmir.sproc AS A
LEFT JOIN smsdss.BMH_PLM_PtAcct_V AS B
ON A.PT_ID = B.Pt_No

--WHERE A.PT_ID = ''
--WHERE B.Med_Rec_No = ''
WHERE A.proc_eff_date >= '2013-01-01'
AND A.proc_cd BETWEEN '66830' AND '66984'
AND LEFT(pt_id, 4) = '0000'

ORDER BY B.MED_REC_NO
, A.proc_eff_date;

-----

SELECT A.*
, MODF_RN = ROW_NUMBER() OVER (
	PARTITION BY A.MED_REC_NO, A.PROC_CD_MODF1
	ORDER BY PROC_EFF_DATE
)

INTO #TEMPB

FROM #TEMPA AS A

WHERE A.Med_Rec_No IN (
	SELECT ZZZ.Med_Rec_No
	FROM #TEMPA AS ZZZ
	WHERE ZZZ.RN = 2
);

-----

SELECT B.*

FROM #TEMPB AS B

WHERE B.Med_Rec_No IN (
	SELECT ZZZ.MED_REC_NO
	FROM #TEMPB AS ZZZ
	WHERE ZZZ.MODF_RN =2
)

ORDER BY B.Med_Rec_No, B.proc_eff_date;