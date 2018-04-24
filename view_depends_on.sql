SELECT view_name
, VIEW_SCHEMA
, Table_Name
, TABLE_SCHEMA
FROM INFORMATION_SCHEMA.VIEW_TABLE_USAGE
WHERE View_Name = 'bmh_plm_ptacct_v'
ORDER BY view_name
, VIEW_SCHEMA
, Table_Name
, TABLE_SCHEMA
GO