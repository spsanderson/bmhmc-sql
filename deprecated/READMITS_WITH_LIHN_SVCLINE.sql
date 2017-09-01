/****** Script for SelectTopNRows command from SSMS  ******/
SELECT [INDEX]
, b.Pt_Name
, b.Pt_Age
, b.pt_zip_cd
, [READMIT]
, [READMIT SOURCE DESC]
, [MRN]
, [INITIAL DISCHARGE]
, [READMIT DATE]
, [INTERIM]
, [30D RA COUNT]
, b.adm_date
, b.dsch_dtime
, MONTH(b.adm_date) as 'Adm_Mo'
, YEAR(b.adm_date) as 'Adm_Yr'
, CASE
	WHEN b.User_Pyr1_Cat IN ('AAA','ZZZ') Then 'Medicare'
	WHEN b.User_Pyr1_Cat IN ('EEE') Then 'Managed Medicare'
	WHEN b.User_Pyr1_Cat = 'WWW' Then 'Medicaid'
	ELSE 'Other'
  END as 'Payer Category'
, INS.[Payer Category]
, b.dsch_disp
, c.dsch_disp_desc
, b.Atn_Dr_No
, d.pract_rpt_name
, CASE
	WHEN e.drg_no IN ('34','35','36','37','38','39') THEN 'Carotid Endarterectomy'
	WHEN e.drg_no IN ('61','62','63','64','65','66') THEN 'CVA'
	WHEN e.drg_no IN ('67','68','69') THEN 'TIA'
	WHEN e.drg_no IN ('190','191','192') THEN 'COPD'
	WHEN e.drg_no IN ('193','194','195') THEN 'Pneumonia'
	WHEN e.drg_no IN ('216','217','218') THEN 'Valve Replacement W Cath'
	WHEN e.drg_no IN ('219','220','221') THEN 'Valve Replacement W/O Cath'
	WHEN e.drg_no IN ('231','232','233') AND (NOT(Diag01 IN ('41412','4150','42292','4230','42490','4275','4295','4296','44322','44329')) OR NOT(LEFT(Diag01,3)IN ('420','421','441','444','785','861','996'))) THEN 'CABG W Cath'
	WHEN e.drg_no IN ('235','236') AND (NOT (Diag01 IN ('41412','4150','42292','4230','42490','4275','4295','4296','44322','44329')) OR NOT(LEFT(Diag01,3) IN ('420','421','441','444','785','861','996'))) THEN 'CABG W/O Cath'
	WHEN e.drg_no IN ('250','251','249','247','248','246') AND Proc01 IN ('0066','3606','3607') THEN 'PTCA'
	WHEN e.drg_no IN ('280','281','282','283','284','285') AND LEFT(Diag01,4) IN ('4100','4101','4102','4103','4104','4105','4106','4107','4108','4109') THEN 'MI'
	WHEN e.drg_no IN ('291') AND Shock_Ind IS NULL THEN 'Heart Failure'
	WHEN e.drg_no IN ('313') OR (e.drg_no IN ('287') AND Diag01 IN ('78650','78651','78652','78659','7850','7851','7859','V717')) THEN 'Chest Pain'
	WHEN e.drg_no IN ('377','378','379') THEN 'GI Hemorrhage'
	WHEN e.drg_no IN ('469','470') AND Proc01 IN ('8151','8152','8154') AND (NOT(Diag01 IN ('73314','73315','8220','8221')) OR NOT(LEFT(Diag01,3) IN ('820','821'))) THEN 'Hip & Knee Replacement'
	WHEN e.drg_no IN ('739','740','741','742','743') AND LEFT(Proc01,3) IN ('683','684','685','689') THEN 'Hysterectomy'
	WHEN e.drg_no IN ('765','766') THEN 'C-Section'
	WHEN e.drg_no IN ('774','775') THEN 'Vaginal Delivery'
	WHEN e.drg_no IN ('795') THEN 'Normal Newborn'
	WHEN e.drg_no IN ('417','418','419') THEN 'Lap Chole'
	WHEN e.drg_no IN ('945','946') THEN 'Rehab'
	WHEN e.drg_no IN ('312') THEN 'Syncope'
	WHEN e.drg_no IN ('881') OR (e.drg_no IN ('885') AND Diag01 IN ('29620','29621','29622','29623','29625','29626','29630','29631','29632','29633','29635','29636')) THEN 'Psychoses-Major Depression'
	WHEN e.drg_no IN ('885') AND Diag01 IN ('29600','29601','29602','29603','29605','29606','29640','29641',
	'29642','29643','29645','29646','29650','29651','29652','29653','29655','29656','29660','29661','29662','29663',
	'29665','2967','29680','29681','29682','29689','29690','29699') THEN 'Psychoses/Bipolar Affective Disorders'
	WHEN e.drg_no IN ('885') AND (Diag01 IN ('29604','29624','29634','29644','29654','29664') OR LEFT(Diag01,3) IN ('295','297','298')) THEN 'Psychoses/Schizophrenia'
	WHEN (e.drg_no IN ('286','302','303','311') AND NOT ('Intermed_Coronary_Synd_Ind' Is NULL)) OR
	(e.drg_no IN ('287') AND NOT('Intermed_Coronary_Synd_Ind' IS NULL) AND Diag01 NOT IN ('78650','78651','78652','78659','7850','7851','7859','V717')) THEN 'Acute Coronary Syndrome'
	WHEN e.drg_no IN ('582','583','584','585') AND LEFT(Proc01 ,3)='854' THEN 'Mastectomy'
	WHEN e.drg_no IN ('896','897') AND Diag01 IN ('2910','2911','2912','2913','2914','2915','2918','29181','29189','2919','30300',
	'30301','30302','30303','30390','30391','30392','30393','30500','30501','30502','30503','3030','3039','3050') THEN 'Alcohol Abuse'
	WHEN e.drg_no IN ('619','620','621') AND LEFT(Diag01,3) IN ('443') THEN 'Gastric By-pass'
	WHEN e.drg_no IN ('602','603') AND LEFT(Diag01,3) IN ('681','682') THEN 'Cellulitis'
	WHEN e.drg_no BETWEEN 1 AND 8 OR e.drg_no BETWEEN 10 and 14  OR e.drg_no IN (16,17) OR e.drg_no BETWEEN 20 and 42 THEN 'Surgical'
	ELSE 'Medical'
END as 'LIHN_Svc_Line'
, f.drg_no as 'MS-DRG_No'
, g.drg_name
, h.edMD
, jj.userdatatext




FROM [SMSPHDSSS0X0].[smsdss].[vReadmits] left outer join smsdss.bmh_plm_ptacct_v as b
ON [INDEX] = b.ptno_num
LEFT OUTER JOIN smsdss.dsch_disp_mstr c
ON b.dsch_disp=c.dsch_disp and c.src_sys_id='#PMSNTX0'
LEFT OUTER JOIN smsmir.mir_pract_mstr d
ON b.Atn_Dr_No=d.pract_no AND d.src_sys_id='#PMSNTX0'
LEFT OUTER JOIN smsdss.c_LIHN_Svc_Lines_1_v as e
ON [INDEX]=CAST(e.pt_id as INT) 
LEFT OUTER JOIN smsmir.mir_drg f
ON [INDEX]=CAST(f.pt_id as INT) and f.drg_type='1'
LEFT OUTER JOIN smsmir.mir_drg_mstr g
ON f.drg_no=g.drg_no AND f.drg_schm=g.drg_schm
LEFT OUTER JOIN smsdss.c_wellsoft_rpt_v h
ON [READMIT]=h.Account
left join smsdss.BMH_UserTwoFact_V as jj
ON [READMIT] = jj.PtNo_Num and jj.UserDataKey='25'

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

CROSS APPLY (

)

where 
(b.adm_date BETWEEN '2015-09-01 00:00:00.000' AND '2015-09-30 23:59:59.000')--OR b.adm_date BETWEEN '2014-01-01 00:00:00.000' AND '2014-06-30 23:59:59.000')
AND b.hosp_svc <> 'PSY'
AND INTERIM < '31'


GROUP BY [INDEX]
, b.Pt_Name
, b.pt_age
, b.pt_zip_cd
, [READMIT]
, [READMIT SOURCE DESC]
, [MRN]
, [INITIAL DISCHARGE]
, [READMIT DATE]
, [INTERIM]
, [30D RA COUNT]
, b.adm_date
, b.dsch_dtime
, MONTH(b.adm_date)
, YEAR(b.adm_date)
, b.User_Pyr1_Cat
, INS.[Payer Category]
, b.dsch_disp
, c.dsch_disp_desc
, b.atn_dr_no
, d.pract_rpt_name
, e.drg_no
, e.Diag01
, e.Shock_Ind
, e.proc01
, f.drg_no
, g.drg_name
, h.EDMD
, jj.userdatatext

ORDER BY [INDEX]
