BEGIN TRY
	SELECT 1/0
	PRINT 'No Errors'
END TRY

BEGIN CATCH
	SELECT ERROR_NUMBER() AS ErrorNumber
	, ERROR_SEVERITY()    AS ErrorSeverity
	, ERROR_STATE()       AS ErrorState
	, ERROR_PROCEDURE()   AS ErrorProcedure
	, ERROR_LINE()        AS ErrorLine
	, ERROR_MESSAGE()     AS ErrorMessage
	PRINT ''
	PRINT '***** Errors Encountered *****'
	PRINT ''
	PRINT 'ErrorNumber:      ' + ISNULL(CAST(ERROR_NUMBER() AS VARCHAR), 'None')
	PRINT 'ErrorSeverity:    ' + ISNULL(CAST(ERROR_SEVERITY() AS VARCHAR), 'None')
	PRINT 'ErrorState:       ' + ISNULL(CAST(ERROR_STATE() AS VARCHAR), 'None')
	PRINT 'ErrorProcedure:   ' + ISNULL(CAST(ERROR_PROCEDURE() AS VARCHAR), 'None')
	PRINT 'ErrorLine:        ' + ISNULL(CAST(ERROR_LINE() AS VARCHAR), 'None')
	PRINT 'ErrorMessage:     ' + ISNULL(CAST(ERROR_MESSAGE() AS VARCHAR), 'None')
	;
END CATCH