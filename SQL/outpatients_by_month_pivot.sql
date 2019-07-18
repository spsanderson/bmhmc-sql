SELECT UPPER(h_svc) AS [Service]
, pvt.[1]           AS [Jan]
, pvt.[2]           AS [Feb]
, pvt.[3]           AS [Mar]
, pvt.[4]           AS [Apr]
, pvt.[5]           AS [May]
, pvt.[6]           AS [Jun]
, pvt.[7]           AS [Jul]
, pvt.[8]           AS [Aug]
, pvt.[9]           AS [Sep]
, pvt.[10]          AS [Oct]
, pvt.[11]          AS [Nov]
, pvt.[12]          AS [Dec]

FROM
(
	SELECT B.hosp_svc
	, B.hosp_svc_name           AS h_svc
	, datepart(month, Adm_Date) AS adm_month

	FROM smsdss.bmh_plm_ptacct_v
	LEFT OUTER JOIN SMSDSS.hosp_svc_dim_v B
	ON SMSDSS.BMH_PLM_PtAcct_V.hosp_svc = B.hosp_svc
		AND B.orgz_cd = 'NTX0'

	WHERE Adm_Date >= '2015-01-01'
	AND Adm_Date < '2016-01-01'
	AND pt_type NOT IN ('C', 'K', 'R', 'V')
	AND Plm_Pt_Acct_Type = 'O'
	AND tot_chg_amt > 0

) p

PIVOT (
	COUNT(hosp_svc)
	FOR adm_month IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12])
) AS pvt