DECLARE @Practice_Info TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, [Practice Name]      VARCHAR(MAX)
	, [Address Line 1]     VARCHAR(100)
	, [Address Line 2]     VARCHAR(100)
	, [Address Line 3]     VARCHAR(100)
	, [City]               VARCHAR(100)
	, [State]              VARCHAR(100)
	, [Zip Code]           VARCHAR(100)
	, [Phone]              VARCHAR(100)
	, [Fax]                VARCHAR(100)
	, [SoftMed Prov Num]   VARCHAR(100)
	, [Prof Title]         VARCHAR(100)
	, [Doc Name]           VARCHAR(100)
	, [Suffix]             VARCHAR(100)
	, [Status]             VARCHAR(100)
	, [Reason]             VARCHAR(MAX)
	, [DSS Prov Num]       VARCHAR(100)
	, [DSS Doc Name]       VARCHAR(100)
	, [DSS Med Staff Dept] VARCHAR(100)
	, [DSS Specialty]      VARCHAR(100)
	, [DSS Spclty Code]    VARCHAR(100)
);

WITH CTE AS (
	select a.name AS PRACTICE_NAME
	, a.address1
	, a.address2
	, a.address3
	, a.city
	, a.state
	, a.postcode
	, a.phone
	, a.fax
	, c.provnum
	, c.proftitle
	, c.name
	, c.suffix
	, c.status
	, c.reason
	, d.src_pract_no
	, d.pract_rpt_name
	, d.med_staff_dept
	, d.spclty_desc
	, d.spclty_cd

	from [bmh-3mhis-db].[mmm_cor_bmh_live].[dbo].[cre_practice] as a
	left join [BMH-3mhis-DB].[mmm_cor_BMH_LIVE].[dbo].[cre_provider_practice] as b
	on a._PK = b.pPractice
	left join [BMH-3mhis-DB].[mmm_cor_BMH_LIVE].[dbo].[cre_provider] as c
	on b._parent = c._PK
	left join smsdss.pract_dim_v as d
	on SUBSTRING(c.provnum, 3, 6) = rtrim(ltrim(d.src_pract_no))COLLATE SQL_Latin1_General_CP1_CI_AS
		and d.orgz_cd = 's0x0'
		
	--where a._pk = '1'
)

INSERT INTO @Practice_Info
SELECT * FROM CTE

SELECT [Address Line 1] + ', ' + [City] + ', ' + [State] + ', ' + [Zip Code] as [FullAddress]
, [Status]
, [Practice Name]
, [Phone]
, [Doc Name]
, [DSS Med Staff Dept]
FROM @Practice_Info
WHERE [Status] = 'Approved'
AND [Address Line 1] != ''
AND [Doc Name] NOT IN ('', 'Test, Doc')
ORDER BY [Practice Name], [Doc Name]