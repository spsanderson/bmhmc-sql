SELECT [System]
, [Journal Entry Type]
, [Control Group]
, [Description]
, [Fiscal Year]
, [Account Period]
, [Operator]
, [Posting Date]
, [GLC-AUTO-REV-XLT]
, [Line Number]
, [Accounting Unit]
, [Account]
, [Source Code]
, -[GLT-BASE-AMT-DB]
, [GLT-BASE-AMT-CR]
, [Account Description]
, [Description1]

      
FROM [SMSPHDSSS0X0].[smsdss].[GL240_Dec_2013]
  
WHERE Account IS NOT NULL
AND (CAST([System] as varchar)+CAST([Control Group] as varchar)) IN (
	SELECT DISTINCT(CAST([System] as varchar)+CAST([Control Group] as varchar))
	FROM smsdss.gl240_dec_2013
	where [System]<>'SP'
	and left(account, 1) in ('4','5')
)

order by [System], [Control Group], [Posting Date], [Line Number]