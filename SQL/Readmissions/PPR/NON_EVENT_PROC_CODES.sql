/*
########################################################################

THIS QUERY WILL OBTAIN THOSE EVENTS THAT ARE NOT NON-EVENTS, THAT IS TO
SAY THAT ALL NON-EVENT PROCEDURE CODE ACCOUNTS ARE KICKED OUT

########################################################################
*/

DECLARE @NONEVENTPROC TABLE (
ID INT NOT NULL PRIMARY KEY,
[CPT CODE] VARCHAR(5)
)

INSERT INTO @NONEVENTPROC(ID, [CPT CODE])
VALUES
(1,'00.10'), (2,'00.15'), (3,'17.70'), (4,'92.30'),
(5,'92.31'), (6,'92.32'), (7,'92.33'), (8,'92.39'),
(9,'99.25'), (10,'99.28')
;

SELECT CODE.pt_id, CODE.proc_cd

FROM smsmir.mir_sproc CODE
LEFT JOIN @NONEVENTPROC                     NOCD
ON CODE.proc_Cd = NOCD.[CPT CODE]

WHERE Pt_id BETWEEN '000010000000' AND '0000299999999'
AND proc_Eff_Dtime > '2014-01-01'
AND NOCD.[CPT CODE] IS NULL
AND CODE.proc_cd <> 'CONSULT'