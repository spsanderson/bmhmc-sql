select pay_dtime,
pay_entry_Dtime,
a.pt_id,
CASE
WHEN LEN(a.unit_seq_no) = '8' THEN a.unit_Seq_no
ELSE NULL
END as 'Unit_No',
b.adm_date,
a.pay_cd,
c.actv_name,
tot_pay_adj_amt as 'tot_pymts_w_pip'


FROM smsmir.mir_pay a left outer join smsdss.BMH_PLM_PtAcct_V b
ON a.pt_id=b.Pt_No AND a.unit_seq_no=b.unit_seq_no
LEFT OUTER JOIN smsmir.mir_actv_mstr c
ON a.pay_cd=c.actv_cd

WHERE (pay_entry_dtime BETWEEN '2018-01-01 00:00:00.000' AND '2018-02-13 23:59:59.000'
and tot_pay_adj_amt <> '0'
AND (pay_cd BETWEEN '09600000' AND '09699999'
OR pay_cd BETWEEN '00990000' AND '00999999'
OR pay_cd BETWEEN '09900000' AND '09999999'
OR pay_cd IN ('00980300','00980409','00980508','00980607','00980656','00980706','00980755','00980805','00980813','00980821','09800095',
'09800277','09800301','09800400','09800459','09800509','09800558','09800608','09800707','09800715','09800806','09800814','09800905',
'09800913','09800921','09800939','09800947','09800962','09800970','09800988','09800996','09801002','09801010','09801028','09801036','09801044',
'09801051','09801069','09801077','09801085','09801093','09801101','09801119', '09801127','09801135'))
)


ORDER BY pay_entry_dtime, pay_cd
