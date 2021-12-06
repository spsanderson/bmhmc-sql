oppe_denials_detail_tbl <- function(provider_id) {
    
    # DB Connection ----
    db_con <- dbConnect(
        odbc(),
        Driver = "SQL Server",
        Server = "LI-HIDB",
        Database = "SMSPHDSSS0X0",
        Trusted_Connection = T
    )
    
    # Get Data ----
    denials_tbl <- dbGetQuery(
        db_con
        , paste0("
    DECLARE @TODAY DATE;
    DECLARE @START DATE;
    DECLARE @END   DATE;
    
    SET @TODAY = CAST(GETDATE() AS date);
    SET @START = DATEADD(YY, DATEDIFF(YY, 0, @TODAY) - 5, 0);
    SET @END   = DATEADD(MM, DATEDIFF(MM, 0, @TODAY), 0);
    
    SELECT PAV.Med_Rec_No,
	PAV.PtNo_Num,
	CAST(PAV.ADM_DATE AS DATE) AS [Adm_Date],
	CAST(PAV.Dsch_Date AS DATE) AS [Dsch_Date],
	CAST(PAV.DAYS_STAY AS INT) AS [Days_Stay],
	PAV.drg_no,
	DRG.drg_name,
	PAV.drg_cost_weight,
	PAV.Atn_Dr_No,
	PDV.pract_rpt_name,
	CASE 
		WHEN PAV.Plm_Pt_Acct_Type != 'I'
			THEN LIHNOP.LIHN_Svc_Line
		ELSE LIHNIP.LIHN_Svc_Line
		END AS [Svc_Line],
	CASE 
		WHEN DENIALS.pt_no IS NOT NULL
			THEN 1
		ELSE 0
		END AS [Denial_Flag],
	DENIALS.UM_Days_Denied,
	DENIALS.Dollars_Appealed,
	DENIALS.Dollars_Recovered,
	PAV.tot_chg_amt,
    PAV.Plm_Pt_Acct_Type
    FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV
    INNER JOIN SMSDSS.pract_dim_v AS PDV ON PAV.Atn_Dr_No = PDV.src_pract_no
	AND PAV.Regn_Hosp = PDV.orgz_cd
    LEFT OUTER JOIN SMSDSS.drg_dim_v AS DRG ON PAV.DRG_NO = DRG.DRG_NO
	AND DRG.drg_vers = 'MS-V25'
    LEFT OUTER JOIN SMSDSS.c_LIHN_Svc_Line_Tbl AS LIHNIP ON PAV.PtNo_Num = LIHNIP.Encounter
    LEFT OUTER JOIN SMSDSS.c_LIHN_OP_Svc_Line_Tbl AS LIHNOP ON PAV.PtNo_Num = LIHNOP.Encounter
    LEFT OUTER JOIN (
	SELECT CAST(rtrim(ltrim('0000' + CAST(a.bill_no AS CHAR(13)))) AS CHAR(13)) COLLATE SQL_LATIN1_GENERAL_PREF_CP1_CI_AS AS [Pt_No],
		e.appl_dollars_appealed AS [Dollars_Appealed],
		e.appl_dollars_recovered AS [Dollars_Recovered],
		d.rvw_Dys_dnd AS [UM_Days_Denied]
	FROM [BMH-3MHIS-DB].MMM_COR_BMH_LIVE.dbo.visit_view AS a
	LEFT JOIN [BMH-3MHIS-DB].MMM_COR_BMH_LIVE.dbo.CTC_VISIT AS b ON a.visit_id = b._fk_visit
	LEFT JOIN [BMH-3MHIS-DB].MMM_COR_BMH_LIVE.dbo.CTC_INSURANCE AS c ON a.visit_id = c._fk_visit
	LEFT JOIN [BMH-3MHIS-DB].[MMM_COR_BMH_LIVE].[dbo].[CTC_UM_Denial] AS d ON c._pk = d._fk_insurance
	LEFT OUTER JOIN [BMH-3MHIS-DB].MMM_COR_BMH_LIVE.dbo.CTC_UM_APPEAL AS e ON d._pk = e._fk_UM_Denial
	WHERE E.APPL_doLLARS_APPEALED IS NOT NULL
	) AS DENIALS ON PAV.Pt_NO = DENIALS.Pt_No
    WHERE Adm_Date >= @START
	AND Adm_Date < @END
	AND PAV.tot_chg_amt > 0
	AND LEFT(PAV.PTNO_NUM, 1) != '2'
	AND LEFT(PAV.PTNO_NUM, 4) != '1999'
	AND PAV.Atn_Dr_No = '", provider_id ,"'
	AND (
		(
			PAV.Plm_Pt_Acct_Type = 'I'
			AND PAV.drg_no IS NOT NULL
			)
		OR (
			PAV.Plm_Pt_Acct_Type != 'I'
			AND PAV.drg_no IS NULL
			)
		)
    ORDER BY PAV.Plm_Pt_Acct_Type,
	PAV.Adm_Date
    ")
    )
    
    # DB Disconnect ----
    dbDisconnect(db_con)
    
    # Return Data ----
    return(denials_tbl)
    
}