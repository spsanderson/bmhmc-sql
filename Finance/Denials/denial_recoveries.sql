SELECT a.*
, d.drg_name
, b.pay_cd
--, b.svc_date
--, b.pay_entry_Date
, c.actv_name
, b.pyr_cd
, SUM(b.tot_pay_adj_amt) as 'Recovr_Amt'


FROM smsdss.c_clin_appeals_v as a 
LEFT OUTER JOIN smsmir.mir_pay as b
ON a.PtNumber = b.Pt_Id 
	AND a.reviewdtime <= b.pay_dtime 
	AND a.InsurancePlan = b.pyr_cd 
LEFT JOIN smsmir.actv_mstr as c
ON b.pay_cd = c.actv_cd 
LEFT JOIN smsmir.mir_drg_mstr as d
ON a.Concurrent_DRG_Schm = d.drg_schm 
	AND a.drg_no = d.drg_no

WHERE (
	b.pay_cd BETWEEN '09600000' AND '09699999'
	OR pay_cd BETWEEN '00990000' AND '00999994'
	OR b.pay_cd BETWEEN '00999996' AND '00999999'
	OR pay_cd BETWEEN '09900000' AND '09999999'
	OR pay_cd IN (
		'00980300','00980409','00980508','00980607','00980656','00980706','00980755','00980805'
		,'00980813','00980821','09800095','09800277','09800301','09800400','09800459','09800509'
		,'09800558','09800608','09800707','09800715','09800806','09800814','09800905','09800913'
		,'09800921','09800939','09800947','09800962','09800970','09800988','09800996','09801002'
		,'09801010','09801028','09801036','09801044','09801051','09801069','09801077','09801085'
		,'09801093'
		)
	)

--AND pay_cd not in ('09730037','09730078','09730110','09730136','09730011','09730052','09701517')

--(b.svc_cd BETWEEN '00990000' AND '00999999' OR b.svc_cd BETWEEN '09900000' AND '09999999' OR b.svc_cd BETWEEN '09800000' AND '09899999' OR b.svc_cd BETWEEN '00980000' AND '00989999')

--('10501211', '10500106')

AND b.pay_dtime BETWEEN '01/15/2017' AND '01/31/2017'

GROUP BY a.PtNumber
, a.pt_id_start_dtime
, a.PtName
, a.DenialDtime
, a.ReviewDtime
, a.InsurancePlan
, a.AdmitDate
, a.DschDate
, a.LOS
, a.adm_src
, a.prin_dx_cd
, a.vst_type_cd
, a.ward_cd
, a.drg_no
, a.concurrent_drg_schm
, d.drg_name
, a.alt_med_rec_no
, a.AttendingPhys
, a.attend_dr_name
, a.AdmitPhys
, a.admit_dr_name
, a.PrimaryIns
, a.PlanBalance
, b.pay_cd
, c.actv_name
, b.pyr_cd

ORDER BY a.ptnumber
