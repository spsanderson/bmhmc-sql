SELECT c.pt_id
, d.unit_seq_no
, d.Adm_Date
, d.Dsch_DTime
, c.Svc_Date
, CASE
	WHEN a.pt_acct_pyr_seq_no='0' THEN 'Patient'
	WHEN a.pt_acct_pyr_seq_no='1' THEN 'Primary'
	WHEN a.pt_acct_pyr_seq_no IN ('2','3','4') THEN 'Secondary'
	ELSE ''
  END as 'Source'
, a.payor_co_plan_cd
, b.pyr_name
, 
--CASE
--WHEN c.pay_cd IN ('09730235','09735234','09731241') THEN 'Charity'
--WHEN a.Payor_Co_Plan_Cd BETWEEN '09600000' AND '09699999' THEN 'Payment'
--WHEN a.Payor_Co_Plan_Cd BETWEEN '00990000' AND '00999999' THEN 'Payment'
--WHEN a.Payor_Co_Plan_Cd BETWEEN '09900000' AND '09999999' THEN 'Payment'
--'09800277','09800301','09800400','09800459','09800509','09800558','09800608'
--,'09800707','09800715','09800806','09800814','09800905',
--'09800913','09800921','09800939','09800947','09800962','09800970','09800988'
--,'09800996','09801002','09801010','09801028','09801036','09801044',
--'09801051','09801069','09801077','09801085','09801093')THEN 'Payment'
--ELSE 'Undefined'
--END as 'Pay_Type',
SUM(c.tot_pay_adj_amt) as 'Trans_Totals'

FROM smsdss.BMH_PLM_PtAcct_Pay_V              as c
LEFT OUTER JOIN smsdss.BMH_PLM_PtAcct_Payor_V as a 
ON a.pt_id=c.pt_id 
	AND a.bl_unit_key=c.bl_unit_key 
	AND a.Payor_Co_Plan_Cd=c.pyr_co_plan_Cd 
LEFT OUTER JOIN smsmir.mir_pyr_mstr           as b
ON c.pyr_co_plan_cd=b.pyr_cd
LEFT OUTER JOIN smsdss.bmh_plm_ptacct_v       as d
ON a.pt_id=d.pt_no 
	AND a.Bl_Unit_Key=d.bl_unit_key
--inner join smsdss.c_2013_item_12_dsh_encs     as zzz
--on c.Pt_Id = zzz.pt_id

WHERE (--(c.pay_cd IN ('09730235','09735234','09731241') 
	(c.svc_cd BETWEEN '09600000' AND '09699999'
	OR c.svc_cd BETWEEN '00990000' AND '00999999' 
	OR c.svc_cd BETWEEN '09900000' AND '09999999'
	OR c.svc_cd IN (
		'00980300','00980409','00980508','00980607','00980656',
		'00980706','00980755','00980805','00980813','00980821',
		'09800277','09800301','09800400','09800459','09800509',
		'09800558','09800608','09800707','09800715','09800806',
		'09800814','09800905','09800913','09800921','09800939',
		'09800947','09800962','09800970','09800988','09800996',
		'09801002','09801010','09801028','09801036','09801044',
		'09801051','09801069','09801077','09801085','09801093',
		'09800095'
		)
	)
	AND (d.unit_seq_no ='0' OR SUBSTRING(CAST(d.unit_Seq_no as varchar),1,2)='13')--CHANGE ME - '11' for 2011 Audit, '12' for 2012, etc......
	AND c.pt_id IN (
		select zzz.pt_id
		from [smsdss].[c_2013_item_12_dsh_encs] as zzz -- change to new table
	)
)

GROUP BY c.pt_id,
d.unit_seq_no,
a.pt_acct_pyr_seq_no,
d.Adm_Date,
d.Dsch_DTime,
c.Svc_Date,
a.payor_co_plan_cd,
b.pyr_name

option(force order);
