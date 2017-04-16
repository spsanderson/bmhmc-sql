SET ANSI_NULLS OFF
GO

DECLARE @SD DATETIME;
DECLARE @ED DATETIME;

SET @SD = '2017-03-01';
SET @ED = '2017-04-01';

SELECT med_rec_no                        AS [Med_Rec_No]
, ptno_num                               AS [Acct_No]
, CAST(pt_birthdate AS DATE)             AS [Date_Of_Birth]
, pt_sex                                 AS [Gender]
--, pt_name
, Ins1                                   AS [FinancialClass_Code]
, Ins_Name                               AS [FinancialClass_Defin]
, CAST(adm_date AS Date)                 AS [Admiss_Date]
, CONVERT(VARCHAR,vst_start_dtime,108)   AS [Admiss_Time]
, Adm_Source                             AS [Admiss_From_Code]
, adm_src_desc                           AS [Admiss_From_Defin]
, CAST(dsch_date AS DATE)                AS [Discharge_Date]
, CONVERT(VARCHAR,dsch_dtime,108)        AS [Discharge_Time]
, Admitting_Phys
, Attending_Phys
, DC_Order_Date
-- add phys writting last adt09 order and DC_Order_Date
--, Discharging_Phys 
--, DC_Order_Date
-- end edit: sps 1/22/2016 per new spec
, CONVERT(VARCHAR,DC_Order_Time,108)     AS [DC_Order_Time]
, DC_Dispo_Code
, DC_Dispo_Defin
, MSDRG_Code
, MSDRG_Descript
, pvt.[01]                               AS [ICD_1]
, pvt.[02]                               AS [ICD_2]
, pvt.[03]                               AS [ICD_3]
, LOS                                    AS [LengthofStay]
, AdmPtSts                               AS [PtStatus_Admiss]
, DschPtSts                              AS [PtStatus_Discharge]
, CASE 
	WHEN Observation_Status IS NULL
		THEN 'NO OBS'
	WHEN Observation_Status = 'ADT11'
		THEN 'OBS'
	ELSE NULL
  END AS [Observation_Status]
--, Bill_DRG_Desc


FROM
(
	SELECT b.med_rec_no
	, b.ptno_num
	, b.pt_birthdate
	, b.pt_sex
	, b.pt_name
	, b.pyr1_co_plan_cd  AS [Ins1]
	, g.pyr_name         AS [Ins_Name]
	, b.adm_date
	, i.vst_start_dtime
	, adm_source
	, h.adm_src_desc
	, b.dsch_date
	, b.dsch_dtime
	, PDV.pract_rpt_name  AS [Admitting_Phys]
	, PDVB.pract_rpt_name AS [Attending_Phys]
	, a.dx_cd_prio
	, a.dx_cd
	, b.drg_no            AS [MSDRG_Code]
	, e.drg_name          AS [MSDRG_Descript]
	, b.days_stay         AS [LOS]
	, b.Plm_Pt_Acct_Type  AS [AdmPtSts]
	, b.Plm_Pt_Acct_Type  AS [DschPtSts]
	, so.DATE             AS [DC_Order_Date]
	, so.time             AS [DC_Order_Time]
	, b.dsch_disp         AS [DC_Dispo_Code]
	, DDM.dsch_disp_desc  AS [DC_Dispo_Defin]
	, OBS.Obv_Svc_Cd      AS [Observation_Status]

	FROM smsmir.mir_dx_grp            AS a 
	LEFT JOIN smsdss.bmh_plm_ptacct_v AS b
	ON a.pt_id=b.pt_no 
		AND a.pt_id_start_dtime=b.pt_id_start_Dtime 
		AND a.unit_seq_no=b.unit_Seq_no
	LEFT JOIN smsmir.mir_pyr_plan     AS c
	ON b.pt_no=c.pt_id 
		AND b.pt_id_start_dtime=c.pt_id_start_dtime 
		AND b.Pyr1_Co_Plan_Cd=c.pyr_Cd
	LEFT JOIN smsmir.mir_drg          AS d
	ON a.pt_id=d.pt_id 
		AND a.pt_id_start_dtime=d.pt_id_start_dtime 
		AND a.unit_seq_no=d.unit_seq_no 
		AND d.drg_type='1'
	LEFT JOIN smsmir.mir_drg_mstr     AS e
	ON LEFT(d.drg_schm,4)=e.drg_Schm 
		AND d.drg_no=e.drg_no
	LEFT JOIN smsmir.mir_drg_mstr     AS f
	ON LEFT(c.bl_drg_schm,4)=f.drg_Schm 
		AND c.bl_drg_no=f.drg_no
	LEFT JOIN smsmir.mir_pyr_mstr     AS g
	ON b.Pyr1_Co_Plan_Cd=g.pyr_Cd
	LEFT JOIN smsdss.adm_src_mstr     AS h
	ON b.Adm_Source=h.adm_src 
		AND h.src_sys_id = '#PASS0X0'
	LEFT OUTER JOIN smsmir.mir_vst    AS i
	ON a.pt_id=i.pt_id 
		AND a.unit_seq_no=i.unit_seq_no
	LEFT JOIN smsdss.pract_dim_v      AS PDV
	ON b.Adm_Dr_No = PDV.src_pract_no
	LEFT JOIN smsdss.pract_dim_v      AS PDVB
	ON b.Atn_Dr_No = PDVB.src_pract_no
	
	-- GET LAST DISCHARGE ORDER ---------------------------------------
	LEFT JOIN (
			SELECT B.episode_no
			, B.ord_no
			, B.DATE
			, B.TIME

			FROM (
				SELECT EPISODE_NO
				, ORD_NO
				, CAST(ENT_DTIME AS DATE) AS [DATE]
				, CAST(ENT_DTIME AS TIME) AS [TIME]
				, ROW_NUMBER() OVER(
									PARTITION BY EPISODE_NO ORDER BY ORD_NO DESC
									) AS ROWNUM
				FROM smsmir.sr_ord
				WHERE svc_desc = 'DISCHARGE TO'
				AND episode_no < '20000000'
			) B

			WHERE B.ROWNUM = 1
		) SO
		
	ON B.PtNo_Num = SO.EPISODE_NO
	LEFT OUTER JOIN smsmir.vst_rpt                  VR
	ON b.PtNo_Num = VR.acct_no
	LEFT OUTER JOIN smsdss.dsch_disp_mstr           DDM
	ON VR.dsch_disp = DDM.dsch_disp
	
	-- GET OBSERVATION STATUS------------------------------------------
	LEFT JOIN (
			SELECT PAV2.PtNo_Num
			, OBV.Obv_Svc_Cd
	
			FROM 
			smsdss.BMH_PLM_PtAcct_V      PAV2
			LEFT OUTER JOIN
			smsdss.c_obv_Comb_1          OBV
			ON PAV2.PtNo_Num = OBV.pt_id
	
			WHERE OBV.pt_id < 20000000
	) OBS
	ON B.PtNo_Num = OBS.PtNo_Num

	WHERE LEFT(a.dx_cd_type,2)='DF' 
		AND (
			b.plm_pt_acct_type='I' 
			OR 
			b.hosp_Svc = 'OBV'
		) 
		AND b.dsch_dtime >= @SD 
		AND b.dsch_dtime < @ED
		AND PDV.src_spclty_cd = 'HOSIM'
		AND PDVB.src_spclty_cd = 'HOSIM'
		AND PDV.orgz_cd = 'S0X0'
		AND PDVB.orgz_cd = 'S0X0'
		AND B.Plm_Pt_Acct_Type = 'I'
		AND B.PtNo_Num < '20000000'
) P

PIVOT (
	MAX(dx_cd)
	FOR dx_Cd_prio IN ([01],[02],[03])
) AS Pvt

