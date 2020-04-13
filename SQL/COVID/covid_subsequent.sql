SELECT A.*,
	b.Med_Rec_No,
	b.Adm_Date
INTO #TEMPA
FROM smsdss.c_positive_covid_visits_tbl AS A
INNER JOIN SMSDSS.BMH_PLM_PTACCT_V AS B ON A.PatientAccountID = B.PtNo_Num;

SELECT A.Med_Rec_No,
	A.PtNo_Num,
	A.Pt_Name,
	A.Pt_Age,
	A.Pt_Sex,
	A.Adm_Date
FROM SMSDSS.BMH_PLM_PTACCT_V AS A
WHERE A.Med_Rec_No IN (
		SELECT DISTINCT MED_REC_NO
		FROM #TEMPA
		WHERE ADM_DATE < A.Adm_Date
		)
