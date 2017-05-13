DECLARE @Specials_Doctors TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, [ID NUMBER]         CHAR(6)
	, [Name]              VARCHAR(50)
	, [Med Staff Dept]    VARCHAR(50)
	, [Specialty]         VARCHAR(50)
);

WITH CTE AS (
	SELECT src_pract_no
	, pract_rpt_name
	, med_staff_dept
	, spclty_desc

	FROM smsdss.pract_dim_v

	WHERE (
		pract_rpt_name like '%balak%'
		OR
		pract_rpt_name like '%broad%'
		OR
		pract_rpt_name like '%boykin%'
		OR
		pract_rpt_name like '%chang% %shu%'
		OR
		pract_rpt_name like '%cruz% %carlos%'
		OR
		pract_rpt_name like '%collyer% %k%'
		OR
		pract_rpt_name like '%pallan% %th%'
		OR
		pract_rpt_name like '%slattery% %mi%'
		
		-- cardiologists
		OR
		pract_rpt_name like '%pulipati% %r%'
		OR
		pract_rpt_name like '%schneider% %j%'
		OR
		pract_rpt_name like '%tomasula% %j%'
		OR
		pract_rpt_name like '%larosa% %ch%'
		OR
		pract_rpt_name like '%paslins%'
	)
	AND orgz_cd = 's0x0'
)

INSERT INTO @Specials_Doctors
SELECT * FROM CTE

SELECT * FROM @Specials_Doctors