select COUNT(distinct(pt_id))

from smsmir.pay

where pay_cd = '10501229'
and pay_date >= '2017-11-01'
and pay_date < '2017-12-01'