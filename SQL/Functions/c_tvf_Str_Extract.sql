/*
Much help from the following link
https://stackoverflow.com/questions/52723494/html-escape-in-t-sql-sql-server-2014/52724050#52724050
*/
CREATE FUNCTION [dbo].[c_tvf_Str_Extract] (
	@String varchar(max)
	, @Delimiter1 varchar(100)
	, @Delimiter2 varchar(100)
)
RETURNS TABLE
AS
RETURN(

	WITH CTE1(N) AS (
		SELECT 1 FROM (
			VALUES(1)
			,(1)
			,(1)
			,(1)
			,(1)
			,(1)
			,(1)
			,(1)
			,(1)
			,(1)
			) 
		 N(N)),
		 CTE2(N) AS (
		 SELECT TOP (ISNULL(DATALENGTH(@STRING), 0)) 
		 ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) 
		 FROM (
			SELECT N=1 
			FROM CTE1 N1
			, CTE1 N2
			, CTE1 N3
			, CTE1 N4
			, CTE1 N5
			, CTE1 N6
			) 
			A
		),
		CTE3(N) AS (
			SELECT 1 UNION ALL SELECT T.N + DATALENGTH(@DELIMITER1) FROM CTE2 T
			WHERE SUBSTRING(@STRING, T.N, DATALENGTH(@DELIMITER1)) = @DELIMITER1
		),
		CTE4(N, L) AS (
			SELECT S.N, ISNULL(NULLIF(CHARINDEX(@DELIMITER1, @STRING, S.N), 0) -S.N, 8000) 
			FROM CTE3 S
		)

	SELECT RETSEQ = ROW_NUMBER() OVER(ORDER BY N)
	, RETPOS = N
	, RETVAL = LEFT(RETVAL, CHARINDEX(@DELIMITER2, RETVAL) - 1)
	FROM (
		SELECT *
		, RETVAL = SUBSTRING(@STRING, N, L)
		FROM CTE4
	) A
	WHERE CHARINDEX(@DELIMITER2, RETVAL) > 1
)