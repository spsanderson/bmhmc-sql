USE [SMSPHDSSS0X0]
GO
/****** Object:  UserDefinedFunction [dbo].[c_udf_NumericChars]    Script Date: 2/25/2016 9:25:37 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [dbo].[c_udf_NumericChars]
(
	@String     VARCHAR(MAX)
)
RETURNS VARCHAR(MAX)
AS
BEGIN

  DECLARE @RemovingCharIndex INT
  SET @RemovingCharIndex = PATINDEX('%[^0-9]%',@String)

  WHILE @RemovingCharIndex > 0
  BEGIN
    SET @String = STUFF(@String,@RemovingCharIndex,1,'')
    SET @RemovingCharIndex = PATINDEX('%[^0-9]%',@String)
  END

  RETURN @String

END