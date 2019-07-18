SELECT a.pt_id
--, User_Pyr1_Cat
--, pyr1_Co_plan_Cd
,[obv_strt_Dtime]
--, [Obv_Svc_Cd]
--, [Obv_Svc_Desc]
,[adm_strt_dtime]
--, [Adm_Svc_Cd]
--, [Adm_Svc_Desc]
,[dsch_strt_dtime]
--, [Dsch_Svc_Cd]
--, [Dsch_Svc_Desc]
,[Nursing_Home]
--, b.tot_chg_amt
,CASE
	WHEN dsch_Strt_dtime IS NULL 
		AND adm_strt_dtime IS NULL 
		THEN (DATEDIFF(mi, obv_strt_Dtime, getdate())/60)
	WHEN adm_strt_dtime IS NOT NULL 
		THEN (DATEDIFF(mi, obv_strt_Dtime, adm_strt_Dtime)/60)
	ELSE (DATEDIFF(mi, obv_strt_Dtime, dsch_strt_dtime)/60)
  END AS [Hrs_In_Obs]
--, datediff(mi,obv_Strt_Dtime,adm_Strt_dtime)/60 as 'Hrs_To_Admit'
--, datediff(mi,obv_Strt_dtime,dsch_Strt_Dtime)/60 as 'Hrs_In_Obsv'
, b.Adm_Date                                  AS [Start_Encounter_Date]
, b.dsch_Dtime                                AS [End_Encounter_Date]
--, b.tot_pay_Amt
--, c.userdatatext as 'Date to Avia_Code'
--, LEFT(d.UserDataText,6) as 'Coded_Date'
, b.fc
, b.User_Pyr1_Cat
, a.adm_dx
, f.dx_cd                                    AS [Final_Prin_Dx]
, g.clasf_desc                               AS [Final_Prin_Dx_Desc]
, b.Atn_Dr_No
, e.pract_rpt_name
, BH.TOT                                     AS [Billable_Hrs_Obsv]
      
FROM [SMSPHDSSS0X0].[smsdss].[c_obv_Comb_1]  AS A
LEFT OUTER JOIN smsdss.bmh_plm_ptAcct_v      AS B
ON a.pt_id = b.ptno_num
LEFT OUTER JOIN smsdss.BMH_UserTwoFact_V     AS C
ON a.pt_id = c.ptno_num
	AND c.UserDataKey = '585' --'2TOAVIDT'
LEFT OUTER JOIN smsdss.BMH_UserTwoFact_V     AS D
ON a.pt_id = d.ptno_num 
	AND d.UserDataKey = '584' --'2ABSTRBY'
LEFT OUTER JOIN smsmir.mir_pract_mstr        AS E
ON b.Atn_Dr_No = e.pract_no 
	AND e.src_sys_id = '#PMSNTX0'
LEFT OUTER JOIN smsmir.mir_dx_grp            AS F
ON a.pt_id = f.pt_id 
	AND LEFT(f.dx_cd_type,2) = 'DF' 
	AND f.dx_cd_prio = '01'
	AND F.dx_cd_schm = '9'
LEFT OUTER JOIN smsmir.mir_clasf_mstr        AS G
On f.dx_cd = g.clasf_cd
left outer join smsmir.mir_cen_hist          AS H
ON a.pt_id = h.episode_no 
	AND h.cng_type = 'R' 
	AND h.bed IS NULL 
LEFT OUTER JOIN (
	SELECT TT.pt_id
	, SUM(actv_tot_Qty) AS TOT
	
	FROM smsdss.c_obv_Comb_1        AS A
	LEFT OUTER JOIN smsmir.mir_Actv AS TT
	ON a.pt_id = tt.pt_id
	AND tt.actv_cd='04700019'
	GROUP BY tt.pt_id
)                                   AS BH                                           
ON A.pt_id = BH.pt_id

WHERE Adm_Date BETWEEN '10/01/2015' AND '10/31/2015'
and obv_strt_Dtime IS NOT NULL
and b.tot_chg_amt > '0'
AND e.spclty_cd1 = 'HOSIM'
  
ORDER BY c.userdatatext
,pt_id