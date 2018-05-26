SELECT MR#
, Account
, Disposition

FROM smsdss.c_Wellsoft_Rpt_tbl

WHERE Arrival >= '2018-01-01'
AND Disposition IN (
	'ama'
	, 'lwbs'
	, 'Transfer Med/Surg'
	, 'Transfer Med/Surg (Stony Brook)'
	, 'Transfer Med/Surg (Stony Brook, North Shore)'
	, 'Transfer Med/Surg (Stony Brook, North Shore, Saint Francis)'
	, 'Transfer Psych or Substance Facility'
	, 'Transfer Specialty'
	, 'Transfer Specialty (Sloan, Schneiders)'
	, 'Transfer Specialty Cancer or Childrens Hospital (Sloan, Schneiders)'
	, 'Transfer Specialty Cancer/Childrens Hosp (Sloan)'
	, 'Transfer to Brunswick Hos'
	, 'Transfer To Hospital (VA)'
	, 'Transfer to SBUH'
	, 'Transfer to VA'
)