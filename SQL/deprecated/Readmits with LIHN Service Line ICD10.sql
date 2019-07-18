DECLARE @SD1 DATETIME;
DECLARE @ED1 DATETIME;

SET @SD1 = '2015-10-01 00:00:00.000';
SET @ED1 = '2015-11-01 00:00:00.000';

SELECT R.[INDEX]
, R.[READMIT]
, H.ED_MD            AS [Readmission ED MD]
, R.[READMIT SOURCE DESC]
, R.[MRN]
, R.[INITIAL DISCHARGE]
, R.[READMIT DATE]
, R.[INTERIM]       AS [Interval]
, B.Adm_Date
, B.Dsch_DTime
, MONTH(B.ADM_DATE) AS [Adm_Mo]
, YEAR(B.ADM_DATE)  AS [Adm_Yr]
, INS.[Payer Category]
, B.dsch_disp       AS [Index Discharge]
, C.dsch_disp_desc  AS [Index Dsch Disp Description]
, B.Atn_Dr_No       AS [Index Atn Dr]
, D.pract_rpt_name  AS [Index Atn Dr Name]
, E.LIHN_Svc_Line
, F.drg_no          AS [MS-DRG_NO]
, G.drg_name        AS [Medicare DRG Description]

FROM smsdss.vReadmits                         AS R
LEFT OUTER JOIN smsdss.bmh_plm_ptacct_v       AS b
ON R.[INDEX] = b.ptno_num
LEFT OUTER JOIN smsdss.dsch_disp_mstr         AS c
ON b.dsch_disp=c.dsch_disp 
	and c.src_sys_id='#PMSNTX0'
	and c.orgz_cd = '?'	
LEFT OUTER JOIN smsmir.mir_pract_mstr         AS d
ON b.Atn_Dr_No=d.pract_no 
	AND d.src_sys_id='#PMSNTX0'
LEFT OUTER JOIN smsdss.c_LIHN_Svc_Lines_Rpt_ICD10_v AS e
ON R.[INDEX]=CAST(e.pt_id AS INT) 
LEFT OUTER JOIN smsmir.mir_drg                AS f
ON R.[INDEX]=CAST(f.pt_id AS INT) 
	and f.drg_type='1'
LEFT OUTER JOIN smsmir.mir_drg_mstr           AS g
ON f.drg_no=g.drg_no 
	AND f.drg_schm=g.drg_schm
LEFT OUTER JOIN smsdss.c_Wellsoft_Rpt_tbl     AS h
ON [READMIT]=h.Account
LEFT JOIN smsdss.BMH_UserTwoFact_V            AS jj
ON R.[READMIT] = jj.PtNo_Num 
	and jj.UserDataKey='25'

/*
***********************************************************************
CROSS APPLY STATEMENTS BEING USED IN STEAD OF INDIVIDUAL CASE STATEMENTS
INSIDE OF THE SELECT CLAUSE
***********************************************************************
*/

CROSS APPLY (
SELECT
	CASE
	WHEN b.User_Pyr1_Cat IN ('AAA','ZZZ') 
		THEN 'Medicare'
	WHEN b.User_Pyr1_Cat IN ('EEE') 
		THEN 'Managed Medicare'
	WHEN b.User_Pyr1_Cat = 'WWW' 
		THEN 'Medicaid'
	ELSE 'Other'
	END AS [Payer Category]
) INS

WHERE B.Adm_Date >= @SD1 AND B.Adm_Date < @ED1
AND B.hosp_svc != 'PSY'
AND R.[READMIT SOURCE DESC] != 'Scheduled Admission'
AND INTERIM < 31

ORDER BY R.[INDEX]