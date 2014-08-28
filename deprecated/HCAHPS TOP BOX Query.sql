SELECT UCase([HCAHPS TOP BOX].[Doctor Name]) AS [Doctor Name]
, UCase([HCAHPS TOP BOX].[LAST NAME LINK]) AS [LAST NAME LINK]
, [HCAHPS TOP BOX].[HCAHPS Question]
, [HCAHPS TOP BOX].[Average Response Value]
, Round([HCAHPS TOP BOX].[Top Box Rate]*100,0) & "%" AS [TOP BOX PERCENT] 

INTO [HCAHPS REPORT TABLE]

FROM [HCAHPS TOP BOX]
WHERE ((([HCAHPS TOP BOX].[Discharge Quarter (YYYYqN)])='2013Q3'));

