select pay_cd
, p.[2012]
, p.[2013]
, p.[2014]
, p.[2015]

from (
	select pay_cd
	, tot_pay_adj_amt
	, DATEPART(year, pay_entry_date) as pay_yr

	from smsmir.pay

	where pay_entry_date >= '2012-01-01'
	and pay_entry_date < '2016-01-01'
	and pay_cd in (
		'09750100', '09750308', '09700691'
	)
) a

pivot(
	sum(tot_pay_adj_amt)
	for pay_yr in ("2012", "2013", "2014", "2015")
) p

union

select 'Grand Total'
, (
	select SUM(tot_pay_adj_amt)
	from smsmir.pay
	where DATEPART(year, pay_entry_date) = '2012'
	and pay_cd in (
		'09750100', '09750308', '09700691'
	)
) as '2012'
, (
	select SUM(tot_pay_adj_amt)
	from smsmir.pay
	where DATEPART(year, pay_entry_date) = '2012'
	and pay_cd in (
		'09750100', '09750308', '09700691'
	)
) as '2013'
, (
	select SUM(tot_pay_adj_amt)
	from smsmir.pay
	where DATEPART(year, pay_entry_date) = '2012'
	and pay_cd in (
		'09750100', '09750308', '09700691'
	)
) as '2014'
, (
	select SUM(tot_pay_adj_amt)
	from smsmir.pay
	where DATEPART(year, pay_entry_date) = '2012'
	and pay_cd in (
		'09750100', '09750308', '09700691'
	)
) as '2015'