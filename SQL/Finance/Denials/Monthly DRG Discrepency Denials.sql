WITH CTE AS (
SELECT b.visit_attend_phys
, f.name 					AS Attend_Dr
, f.provno 					AS Attend_Dr_No
, SPCTLYA.Attend_Spclty
, CAST(
	rtrim(
		ltrim('0000' + CAST(a.bill_no AS char(13)))
		) AS CHAR(13)
	) COLLATE SQL_LATIN1_GENERAL_PREF_CP1_CI_AS   
							AS bill_no
, '1' 						AS Discharge_Cnt
, a.last_name
, a.first_name
, e.rvw_date
, a.patient_type
, CASE
	WHEN e.rvw_date IS NOT NULL THEN '1'
	ELSE '0'
  END 						AS Initial_Denial
,e.appl_type
,e.appl_status
,CASE
	WHEN LTRIM(RTRIM(e.appl_Status))='PEND' THEN '1'
	ELSE '0'
  END 						AS Pending
, CASE 
	WHEN LTRIM(RTRIM(e.appl_status))<>'PEND' 
	AND e.rvw_date IS NOT NULL THEN '1'
	ELSE '0'
  END 						AS Finalized
, e.appl_dollars_appealed
, CASE
	WHEN e.appl_dollars_appealed IS NOT NULL THEN '1'
	WHEN e.appl_dollars_appealed <> '0' THEN '1'
    ELSE '0'
  END                       AS [1st_Lvl_Appealed_Ind]
, CASE
	WHEN e.appl_dollars_appealed IS NOT NULL 
	AND [s_qm_subseq_appeal] IN ('4','9')THEN '1'
	WHEN e.appl_dollars_appealed <> '0' 
	AND [s_qm_subseq_appeal] IN ('4','9') THEN '1'
	ELSE '0'
  END                       AS [2nd_Lvl_Appealed_Ind]
, e.s_cpm_Dollars_not_appealed
, CASE
	WHEN e.s_cpm_Dollars_not_appealed IS NOT NULL THEN '1'
	ELSE '0'
  END                       AS No_Appeal
, e.appl_dollars_recovered
, CASE
	WHEN [s_qm_subseq_appeal] IS NULL 
	AND e.appl_dollars_recovered > '0' THEN '1'
	ELSE 0
  END                       AS [1st_Lvl_Recovery]
, CASE
	WHEN [s_qm_subseq_appeal] IS NOT NULL 
	AND e.appl_dollars_recovered > '0' THEN '1'
	ELSE 0
  END                       AS DRA_Lvl_Recovery
, e.s_qm_subseq_appeal
, CASE
	WHEN e.s_qm_subseq_appeal IS NOT NULL THEN '1'
	ELSE '0'
  END                       AS External_Appeal
, e.s_qm_subseq_appeal_date
, d.assoc_prvdr
, g.name                    AS Denial_Dr
, g.provno                  AS Denial_Dr_No
, i.spclty_Cd1              AS BMH_Specialty
, SPCLTYB.Denial_Spclty
, e.s_rvw_dnl_rsn
, a.v_financial_cls
, a.length_of_stay
, CASE
	WHEN a.length_of_stay < '3' THEN CAST('1' AS INT)
	ELSE CAST('0' AS INT)
  END                       AS Short_Stay_Indicator
, CASE 
	WHEN a.length_of_stay > '2' THEN CAST('1' AS INT)
	ELSE CAST('0' AS INT)
  END                       AS Long_Stay_Indicator
, CASE
	WHEN a.length_of_stay < '3' 
	AND d.assoc_prvdr IS NOT NULL THEN CAST('1' AS INT)
	ELSE CAST('0' AS INT)
  END                       AS Short_Stay_Appeal_Indicator
, CASE 
	WHEN a.length_of_stay > '2' 
	AND d.assoc_prvdr IS NOT NULL THEN CAST('1' AS INT)
	ELSE CAST('0' AS INT)
  END                       AS Long_Stay_Appeal_Indicator
, b.visit_admit_diag
, b.admit_diag_Description
, a.admission_date
, a.discharged
, YEAR(a.discharged)        AS Dsch_Yr
, MONTH(a.discharged)       AS Dsch_Mo
, q.[cerm_review_status]
, q.[cerm_rvwr_id]
, q.[cerm_rvw_date]
, q.[cerm_case_notes]
, s.pyr_cd
, s.pyr_seq_no
, t.pyr_name
, d.rvw_Date               AS UM_Review_Date
, d.rvw_Dnl_type           AS UM_Review_Denial_Type
, d.rvw_Dys_dnd            AS UM_Days_Denied
, d.rvw_Dts_dnd			   AS UM_Rvw_Dates_Denied
, d.s_cpm_Denial_date	   AS UM_Denial_Date
, e.rvw_appl_dt			   AS Appeal_Date
, u.dx_cd				   AS Adm_Dx


FROM [BMH-3MHIS-DB].MMM_COR_BMH_LIVE.dbo.visit_view               AS a 
LEFT JOIN [BMH-3MHIS-DB].MMM_COR_BMH_LIVE.dbo.CTC_VISIT           AS b
ON a.visit_id=b._fk_visit
LEFT JOIN [BMH-3MHIS-DB].MMM_COR_BMH_LIVE.dbo.CTC_INSURANCE       AS c
ON a.visit_id=c._fk_visit
LEFT JOIN [BMH-3MHIS-DB].[MMM_COR_BMH_LIVE].[dbo].[CTC_UM_Denial] AS d
ON c._pk=d._fk_insurance 
LEFT OUTER JOIN [BMH-3MHIS-DB].MMM_COR_BMH_LIVE.dbo.CTC_UM_APPEAL AS e
ON d._pk=e._fk_UM_Denial
LEFT OUTER JOIN [BMH-3MHIS-DB].MMM_COR_BMH_LIVE.dbo.pdb_master    AS f
ON b.visit_attend_phys=f._pk
LEFT OUTER JOIN [BMH-3MHIS-DB].MMM_COR_BMH_LIVE.dbo.pdb_master    AS g
ON d.assoc_prvdr=g._pk
LEFT OUTER JOIN SMSPHDSSS0X0.smsmir.mir_pract_mstr                AS h
ON (RIGHT(LTRIM(RTRIM(f.provno)),6)=h.pract_no COLLATE SQL_Latin1_General_CP1_CI_AS)
	AND (h.src_sys_id='#PMSNTX0' COLLATE SQL_Latin1_General_CP1_CI_AS)
LEFT OUTER JOIN SMSPHDSSS0X0.smsmir.mir_pract_mstr				  AS i
ON (RIGHT(LTRIM(RTRIM(g.provno)),6)=i.pract_no COLLATE SQL_Latin1_General_CP1_CI_AS)
	AND (i.src_sys_id='#PMSNTX0' COLLATE SQL_Latin1_General_CP1_CI_AS)
LEFT OUTER JOIN [BMH-3MHIS-DB].[MMM_COR_BMH_LIVE].[dbo].[CTC_UM_CERM] AS q
ON a.visit_id=q._fk_visit  AND q.cerm_review_type='Admission'
LEFT OUTER JOIN smsmir.mir_pyr_plan                               AS s
ON CAST(a.bill_no AS INT)=CAST(s.pt_id AS INT) 
	AND s.pyr_seq_no = '1' 
	AND s.pyr_cd <> 'Z28'
LEFT OUTER JOIN smsmir.mir_pyr_mstr                               AS t
ON s.pyr_cd=t.pyr_cd
LEFT OUTER JOIN smsmir.mir_dx_grp                                 AS u
On CAST(a.bill_no AS INT)=CAST(u.pt_id AS INT) 
	AND u.dx_cd_type = 'DA' 
	AND dx_cd_prio IN ('1','01')

CROSS APPLY (
	SELECT
		CASE
			WHEN h.spclty_cd1 = 'AIMIM' THEN 'Internal Medicine'
			WHEN h.spclty_cd1 = 'AIMPE' THEN 'Pediatrics'
			WHEN h.spclty_cd1 = 'AMDSG' THEN 'Surgery'
			WHEN h.spclty_cd1 = 'ANSAN' THEN 'Anesthesiology'
			WHEN h.spclty_cd1 = 'CARIM' THEN 'Internal Medicine'
			WHEN h.spclty_cd1 = 'CIVIM' THEN 'Internal Medicine'
			WHEN h.spclty_cd1 = 'CRSSG' THEN 'Surgery'
			WHEN h.spclty_cd1 = 'CSGSG' THEN 'Surgery'
			WHEN h.spclty_cd1 = 'DDSDT' THEN 'Dentistry'
			WHEN h.spclty_cd1 = 'DERIM' THEN 'Internal Medicine'
			WHEN h.spclty_cd1 = 'DTNIM' THEN 'Internal Medicine'
			WHEN h.spclty_cd1 = 'EDCIM' THEN 'Internal Medicine'
			WHEN h.spclty_cd1 = 'EMRED' THEN 'Emergency Department'
			WHEN h.spclty_cd1 = 'EMRFP' THEN 'Family Practice'
			WHEN h.spclty_cd1 = 'EMRIM' THEN 'Internal Medicine'
			WHEN h.spclty_cd1 = 'ENTSG' THEN 'Surgery'
			WHEN h.spclty_cd1 = 'FAMFP' THEN 'Family Practice'
			WHEN h.spclty_cd1 = 'FAMSG' THEN 'Surgery'
			WHEN h.spclty_cd1 = 'GSGSG' THEN 'Surgery'
			WHEN h.spclty_cd1 = 'GTEIM' THEN 'Internal Medicine'
			WHEN h.spclty_cd1 = 'GYNOB' THEN 'Ob/Gyn'
			WHEN h.spclty_cd1 = 'HEMIM' THEN 'Internal Medicine'
			WHEN h.spclty_cd1 = 'HOSIM' THEN 'Internal Medicine'
			WHEN h.spclty_cd1 = 'HOYIM' THEN 'Internal Medicine'
			WHEN h.spclty_cd1 = 'IFDIM' THEN 'Internal Medicine'
			WHEN h.spclty_cd1 = 'IMDIM' THEN 'Internal Medicine'
			WHEN h.spclty_cd1 = 'IMDIP' THEN 'Internal Medicine/Pediatrics'
			WHEN h.spclty_cd1 = 'IMDPE' THEN 'Pediatrics'
			WHEN h.spclty_cd1 = 'NCMRD' THEN 'Radiology'
			WHEN h.spclty_cd1 = 'NEOPE' THEN 'Pediatrics'
			WHEN h.spclty_cd1 = 'NEPIM' THEN 'Internal Medicine'
			WHEN h.spclty_cd1 = 'NEUFP' THEN 'Family Practice'
			WHEN h.spclty_cd1 = 'NEUIM' THEN 'Internal Medicine'
			WHEN h.spclty_cd1 = 'NEUPS' THEN 'Psychiatry'
			WHEN h.spclty_cd1 = 'NEURD' THEN 'Radiology'
			WHEN h.spclty_cd1 = 'NEUSG' THEN 'Surgery'
			WHEN h.spclty_cd1 = 'NSGSG' THEN 'Surgery'
			WHEN h.spclty_cd1 = 'OBGOB' THEN 'Ob/Gyn'
			WHEN h.spclty_cd1 = 'OBGSG' THEN 'Surgery'
			WHEN h.spclty_cd1 = 'OGNOB' THEN 'Ob/Gyn'
			WHEN h.spclty_cd1 = 'OMFDT' THEN 'Dentistry'
			WHEN h.spclty_cd1 = 'OMFSG' THEN 'Surgery'
			WHEN h.spclty_cd1 = 'ONCIM' THEN 'Internal Medicine'
			WHEN h.spclty_cd1 = 'OPHSG' THEN 'Surgery'
			WHEN h.spclty_cd1 = 'ORTFP' THEN 'Family Practice'
			WHEN h.spclty_cd1 = 'ORTSG' THEN 'Surgery'
			WHEN h.spclty_cd1 = 'PATPA' THEN 'Pathology'
			WHEN h.spclty_cd1 = 'PATPE' THEN 'Pediatrics'
			WHEN h.spclty_cd1 = 'PCRPE' THEN 'Pediatrics'
			WHEN h.spclty_cd1 = 'PDDDT' THEN 'Dentistry'
			WHEN h.spclty_cd1 = 'UROSG' THEN 'Surgery'
			WHEN h.spclty_cd1 = 'VSGSG' THEN 'Surgery'
			WHEN h.spclty_cd1 = 'PEDIP' THEN 'Internal Medicine/Pediatrics'
			WHEN h.spclty_cd1 = 'PEDPE' THEN 'Pediatrics'
			WHEN h.spclty_cd1 = 'PEDPS' THEN 'Psychiatry'
			WHEN h.spclty_cd1 = 'PERDT' THEN 'Dentistry'
			WHEN h.spclty_cd1 = 'PLSSG' THEN 'Surgery'
			WHEN h.spclty_cd1 = 'PMGAN' THEN 'Anesthesiology'
			WHEN h.spclty_cd1 = 'PMGSG' THEN 'Surgery'
			WHEN h.spclty_cd1 = 'PMRIM' THEN 'Internal Medicine'
			WHEN h.spclty_cd1 = 'PODSG' THEN 'Surgery'
			WHEN h.spclty_cd1 = 'PSGSG' THEN 'Surgery'
			WHEN h.spclty_cd1 = 'PSOIM' THEN 'Internal Medicine'
			WHEN h.spclty_cd1 = 'PSYIM' THEN 'Internal Medicine'
			WHEN h.spclty_cd1 = 'PSYPS' THEN 'Psychiatry'
			WHEN h.spclty_cd1 = 'PULIM' THEN 'Internal Medicine'
			WHEN h.spclty_cd1 = 'PURSG' THEN 'Surgery'
			WHEN h.spclty_cd1 = 'RADRD' THEN 'Radiology'
			WHEN h.spclty_cd1 = 'RHEIM' THEN 'Internal Medicine'
			WHEN h.spclty_cd1 = 'RONRD' THEN 'Radiology'
			WHEN h.spclty_cd1 = 'SURFP' THEN 'Family Practice'
			WHEN h.spclty_cd1 = 'SURSG' THEN 'Surgery'
			WHEN h.spclty_cd1 = 'TSGSG' THEN 'Surgery'
			WHEN h.spclty_cd1 = 'OBGYN' THEN 'Ob/Gyn'
			WHEN h.spclty_cd1 = 'PSYPY' THEN 'Psychiatry'
			ELSE ''
		END AS 'Attend_Spclty'
) SPCTLYA

CROSS APPLY (
	SELECT
		CASE
			WHEN i.spclty_cd1 = 'AIMIM' THEN 'Internal Medicine'
			WHEN i.spclty_cd1 = 'AIMPE' THEN 'Pediatrics'
			WHEN i.spclty_cd1 = 'AMDSG' THEN 'Surgery'
			WHEN i.spclty_cd1 = 'ANSAN' THEN 'Anesthesiology'
			WHEN i.spclty_cd1 = 'CARIM' THEN 'Internal Medicine'
			WHEN i.spclty_cd1 = 'CIVIM' THEN 'Internal Medicine'
			WHEN i.spclty_cd1 = 'CRSSG' THEN 'Surgery'
			WHEN i.spclty_cd1 = 'CSGSG' THEN 'Surgery'
			WHEN i.spclty_cd1 = 'DDSDT' THEN 'Dentistry'
			WHEN i.spclty_cd1 = 'DERIM' THEN 'Internal Medicine'
			WHEN i.spclty_cd1 = 'DTNIM' THEN 'Internal Medicine'
			WHEN i.spclty_cd1 = 'EDCIM' THEN 'Internal Medicine'
			WHEN i.spclty_cd1 = 'EMRED' THEN 'Emergency Department'
			WHEN i.spclty_cd1 = 'EMRFP' THEN 'Family Practice'
			WHEN i.spclty_cd1 = 'EMRIM' THEN 'Internal Medicine'
			WHEN i.spclty_cd1 = 'ENTSG' THEN 'Surgery'
			WHEN i.spclty_cd1 = 'FAMFP' THEN 'Family Practice'
			WHEN i.spclty_cd1 = 'FAMSG' THEN 'Surgery'
			WHEN i.spclty_cd1 = 'GSGSG' THEN 'Surgery'
			WHEN i.spclty_cd1 = 'GTEIM' THEN 'Internal Medicine'
			WHEN i.spclty_cd1 = 'GYNOB' THEN 'Ob/Gyn'
			WHEN i.spclty_cd1 = 'HEMIM' THEN 'Internal Medicine'
			WHEN i.spclty_cd1 = 'HOSIM' THEN 'Internal Medicine'
			WHEN i.spclty_cd1 = 'HOYIM' THEN 'Internal Medicine'
			WHEN i.spclty_cd1 = 'IFDIM' THEN 'Internal Medicine'
			WHEN i.spclty_cd1 = 'IMDIM' THEN 'Internal Medicine'
			WHEN i.spclty_cd1 = 'IMDIP' THEN 'Internal Medicine/Pediatrics'
			WHEN i.spclty_cd1 = 'IMDPE' THEN 'Pediatrics'
			WHEN i.spclty_cd1 = 'NCMRD' THEN 'Radiology'
			WHEN i.spclty_cd1 = 'NEOPE' THEN 'Pediatrics'
			WHEN i.spclty_cd1 = 'NEPIM' THEN 'Internal Medicine'
			WHEN i.spclty_cd1 = 'NEUFP' THEN 'Family Practice'
			WHEN i.spclty_cd1 = 'NEUIM' THEN 'Internal Medicine'
			WHEN i.spclty_cd1 = 'NEUPS' THEN 'Psychiatry'
			WHEN i.spclty_cd1 = 'NEURD' THEN 'Radiology'
			WHEN i.spclty_cd1 = 'NEUSG' THEN 'Surgery'
			WHEN i.spclty_cd1 = 'NSGSG' THEN 'Surgery'
			WHEN i.spclty_cd1 = 'OBGOB' THEN 'Ob/Gyn'
			WHEN i.spclty_cd1 = 'OBGSG' THEN 'Surgery'
			WHEN i.spclty_cd1 = 'OGNOB' THEN 'Ob/Gyn'
			WHEN i.spclty_cd1 = 'OMFDT' THEN 'Dentistry'
			WHEN i.spclty_cd1 = 'OMFSG' THEN 'Surgery'
			WHEN i.spclty_cd1 = 'ONCIM' THEN 'Internal Medicine'
			WHEN i.spclty_cd1 = 'OPHSG' THEN 'Surgery'
			WHEN i.spclty_cd1 = 'ORTFP' THEN 'Family Practice'
			WHEN i.spclty_cd1 = 'ORTSG' THEN 'Surgery'
			WHEN i.spclty_cd1 = 'PATPA' THEN 'Pathology'
			WHEN i.spclty_cd1 = 'PATPE' THEN 'Pediatrics'
			WHEN i.spclty_cd1 = 'PCRPE' THEN 'Pediatrics'
			WHEN i.spclty_cd1 = 'PDDDT' THEN 'Dentistry'
			WHEN i.spclty_cd1 = 'UROSG' THEN 'Surgery'
			WHEN i.spclty_cd1 = 'VSGSG' THEN 'Surgery'
			WHEN i.spclty_cd1 = 'PEDIP' THEN 'Internal Medicine/Pediatrics'
			WHEN i.spclty_cd1 = 'PEDPE' THEN 'Pediatrics'
			WHEN i.spclty_cd1 = 'PEDPS' THEN 'Psychiatry'
			WHEN i.spclty_cd1 = 'PERDT' THEN 'Dentistry'
			WHEN i.spclty_cd1 = 'PLSSG' THEN 'Surgery'
			WHEN i.spclty_cd1 = 'PMGAN' THEN 'Anesthesiology'
			WHEN i.spclty_cd1 = 'PMGSG' THEN 'Surgery'
			WHEN i.spclty_cd1 = 'PMRIM' THEN 'Internal Medicine'
			WHEN i.spclty_cd1 = 'PODSG' THEN 'Surgery'
			WHEN i.spclty_cd1 = 'PSGSG' THEN 'Surgery'
			WHEN i.spclty_cd1 = 'PSOIM' THEN 'Internal Medicine'
			WHEN i.spclty_cd1 = 'PSYIM' THEN 'Internal Medicine'
			WHEN i.spclty_cd1 = 'PSYPS' THEN 'Psychiatry'
			WHEN i.spclty_cd1 = 'PULIM' THEN 'Internal Medicine'
			WHEN i.spclty_cd1 = 'PURSG' THEN 'Surgery'
			WHEN i.spclty_cd1 = 'RADRD' THEN 'Radiology'
			WHEN i.spclty_cd1 = 'RHEIM' THEN 'Internal Medicine'
			WHEN i.spclty_cd1 = 'RONRD' THEN 'Radiology'
			WHEN i.spclty_cd1 = 'SURFP' THEN 'Family Practice'
			WHEN i.spclty_cd1 = 'SURSG' THEN 'Surgery'
			WHEN i.spclty_cd1 = 'TSGSG' THEN 'Surgery'
			WHEN i.spclty_cd1 = 'OBGYN' THEN 'Ob/Gyn'
			WHEN i.spclty_cd1 = 'PSYPY' THEN 'Psychiatry'
			ELSE ''
		END AS 'Denial_Spclty'
) SPCLTYB



WHERE (
	b._pk IS NOT NULL 
	AND NOT(b.s_cpm_Patient_Status IN('OP','IP'))
	AND (d._pk IS NOT NULL)
	AND (
		d.rvw_dnl_type IS NULL 
		OR
		d.rvw_dnl_type = '5' -- DRG Denial Code in Softmed
		)
	)
)

SELECT c1.visit_attend_phys
, c1.Attend_Dr
, c1.Attend_Dr_No
, c1.Attend_Spclty
, c1.bill_no
, c1.Initial_Denial
, c1.appl_type
, c1.appl_status
, c1.pending
, c1.Finalized
, c1.[1st_Lvl_Appealed_Ind]
, c1.[2nd_Lvl_Appealed_Ind]
, c1.No_Appeal
, c1.[1st_Lvl_Recovery]
, c1.DRA_Lvl_Recovery
, c1.External_Appeal
, c1.Denial_Dr
, c1.Denial_Dr_No
, c1.BMH_Specialty
, c1.Denial_Spclty
, c1.s_rvw_dnl_rsn
, c1.v_financial_cls
, c1.length_of_stay
, c1.Short_Stay_Indicator
, c1.Long_Stay_Indicator
, c1.Short_Stay_Appeal_Indicator
, c1.Long_Stay_Appeal_Indicator
, c1.visit_admit_diag
, c1.admit_diag_description
, c1.admission_date
, c1.discharged
, c1.cerm_review_status
, c1.cerm_rvwr_id
, c1.cerm_rvw_date
--, c1.cerm_case_notes
, c1.pyr_cd
, c1.pyr_seq_no
, c1.pyr_name
, c1.UM_Review_Date
, c1.UM_Review_Denial_Type
, c1.UM_Days_Denied
, c1.UM_Rvw_Dates_Denied
, c1.UM_Denial_Date
, c1.Appeal_Date
, c1.Adm_Dx
, B.tot_pay_adj_amt

FROM CTE C1
LEFT OUTER JOIN SMSMIR.mir_pay B
ON C1.bill_no = B.pt_id
	AND LEFT(B.PAY_CD, 4) = '0974'
