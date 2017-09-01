SELECT column_name AS [name],
       IS_NULLABLE AS [null?],
       DATA_TYPE + COALESCE('(' + CASE WHEN CHARACTER_MAXIMUM_LENGTH = -1
                                  THEN 'Max'
                                  ELSE CAST(CHARACTER_MAXIMUM_LENGTH AS VARCHAR(5))
                                  END + ')', '') AS [type]
FROM   INFORMATION_SCHEMA.Columns
WHERE  table_name = 'c_experian_return_file'