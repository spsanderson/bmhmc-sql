/*
Identify Excluded Admissions

1. Major Metastatic Malignancy
2. Trauma
3. Other global exclusions
4. Error APR DRG's
5. Other Malignancy
6. Burn
7. Newborn
8. Left Against Medical Advice
9. Age Exclusions

*/

/*
VARIABLE DECLARATION AND INITIALIZATION
*/
DECLARE @VISIT_ID VARCHAR(8);
SET @VISIT_ID  = '20000000';

/*
#######################################################################

CREATE AND POPULATE TABLE WITH GLOBALLY EXCLUDED APR-DRG'S

#######################################################################
*/
DECLARE @EXCLUSIONS TABLE (
ID INT NOT NULL PRIMARY KEY,
[APR-DRG] VARCHAR (3)
)

INSERT INTO @EXCLUSIONS(ID, [APR-DRG])
VALUES
-- GLOBAL EXCLUSIONS 
(1,'041'),(2,'070'),(3,'073'),(4,'080'),(5,'082'),(6,'131'),(7,'580'),
(8,'581'),(9,'583'),(10,'588'),(11,'589'),(12,'591'),(13,'593'),
(14,'602'),(15,'603'),(16,'607'),(17,'608'),(18,'609'),(19,'611'),
(20,'612'),(21,'613'),(22,'614'),(23,'621'),(24,'622'),(25,'623'),
(26,'625'),(27,'626'),(28,'630'),(29,'631'),(30,'633'),(31,'634'),
(32,'636'),(33,'639'),(34,'640'),(35,'690'),(36,'691'),(37,'692'),
(38,'693'),(39,'694'),(40,'770'),(41,'890'),(42,'892'),(43,'893'),
(44,'955'),(45,'956'),

-- AGE EXCLUSION APR-DRG'S
(46,'053'),(47,'248'),(48,'463'),(49,'812'),(50,'816'),

-- TRUMA EXCLUSIONS
(51,'308'),(52,'309'),
(53,'384'),(54,'711'),(55,'910'),(56,'911'),(57,'912'),(58,'930'),

-- NON-EVENT DRG'S
(59,'110'),(60,'136'),(61,'240'),(62,'281'),(63,'343'),(64,'382'),
(65,'442'),(66,'461'),(67,'500'),(68,'530'),(69,'680'),(70,'681'),
(71,'860'),(72,'862'),(73,'863')
;
SELECT *

FROM SMSDSS.c_readmissions_v RAV
LEFT JOIN @EXCLUSIONS  GE
ON RAV.APR_DRG_Initial_Vst = GE.[APR-DRG]
LEFT JOIN @EXCLUSIONS  GE2
ON RAV.B_Vst_APR_DRG_No = GE2.[APR-DRG]

WHERE GE.[APR-DRG] IS NULL
AND GE2.[APR-DRG] IS NULL
AND adm_src_desc   != 'Scheduled Admission'
AND B_Adm_Src_Desc != 'Scheduled Admission'
AND pt_no   < @VISIT_ID
AND B_Pt_No < @VISIT_ID
