CREATE FUNCTION dbo.c_udf_AlphaNumericChars
(
	@String     VARCHAR(MAX)
)
RETURNS VARCHAR(MAX)
AS
BEGIN

  DECLARE @RemovingCharIndex INT
  SET @RemovingCharIndex = PATINDEX('%[^0-9A-Za-z]%',@String)

  WHILE @RemovingCharIndex > 0
  BEGIN
    SET @String = STUFF(@String,@RemovingCharIndex,1,'')
    SET @RemovingCharIndex = PATINDEX('%[^0-9A-Za-z]%',@String)
  END

  RETURN @String

END
