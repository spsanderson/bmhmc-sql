Select A.mrn
, a.bill_no
, a.last_name
, a.first_name
, a.admission_date
, a.discharged
, b.visit_dc_status
, b.dc_to_dest
, a.v_financial_cls
, b.s_cpm_homecare_diagnosi
, b.s_homecare_vendor
, b.s_cpm_reasonforhomecare
--, c.ins_payor_search

From [BMH-3MHIS-DB].[MMM_COR_BMH_LIVE].[dbo].[VISIT_VIEW] a
LEFT JOIN [BMH-3MHIS-DB].[MMM_COR_BMH_LIVE].[dbo].[CTC_VISIT] b
ON a.visit_id = b._fk_visit 
--LEFT JOIN [BMH-3MHIS-DB].[MMM_COR_BMH_LIVE].[dbo].[CTC_INSURANCE] c
--ON a.visit_id = b._fk_visit

where b._pk IS NOT NULL 
AND (
		a.discharged >= '2015-10-01 00:00:00.000' 
		AND a.discharged <= '2015-10-31 23:59:59.997'
	) 
AND b.s_cpm_Patient_Status <> 'IP' 
AND ( 
		b.s_cpm_reasonforhomecare IS NOT NULL
		OR b.s_homecare_vendor IS NOT NULL 
		OR b.dc_to_dest IN ('02', '05')
		OR b.visit_dc_status = 'ATW'
	) 
--AND (c.ins_priority = '1') 
--AND (c.insurance_inactive <> 1)