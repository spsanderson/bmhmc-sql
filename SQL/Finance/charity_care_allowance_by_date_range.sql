select a.pt_id
, a.pay_cd
, b.pay_cd_name
, a.pay_entry_date
, a.tot_pay_adj_amt
, case
	when c.[Visit Number / Account Number] IS null
		then 0
		else 1
  end as mjrf_pcc_flag

from smsmir.pay as a
left join smsdss.pay_cd_dim_v as b
on a.pay_cd = b.pay_cd
left join smsdss.c_MJRF_pcc as c
on SUBSTRING(a.pt_id, 5, 8) = c.[Visit Number / Account Number]

where a.pay_cd in (
	'09700097','09700287','09700840','09703604','09730235','09730243',
	'09731241','09731258','09735234','09735242','09735267','09735283',
	'09735291','09735309','09735317','09735325','09735333','09735341'
)
and a.pay_entry_date >= '2017-02-01'
and a.pay_entry_date < '2017-03-01'

order by a.pt_id, a.pay_entry_date
;
