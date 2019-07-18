select distinct(pt_id)
, pay_cd
, pay_date
, DATEPART(year, pay_date)
, DATEPART(month, pay_date)
from smsmir.pay
where pay_cd = '10501104'
and pay_date >= '2017-11-01'
order by pay_date
