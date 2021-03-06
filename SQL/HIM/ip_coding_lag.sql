/****** Script for SelectTopNRows command from SSMS  ******/
SELECT [Patient_ID]
, [episode_no]
, [Coder]
, [Date_Coded]
, b.adm_dtime
, b.dsch_dtime
, DATEDIFF(dd,b.dsch_dtime, a.date_coded)
, DATEPART(YEAR, A.[Date_Coded]) AS [Year_Coded]
, DATEPART(MONTH, A.[Date_Coded]) AS [Month_Coded]
     
FROM [SMSPHDSSS0X0].[smsdss].[c_bmh_coder_activity_v] as a 
left outer join smsmir.mir_acct as b
ON a.Patient_ID = b.pt_id 
  
where Date_Coded >= '2018-12-01'
AND Date_Coded < '2019-01-01'
AND LEFT(patient_id,5) = '00001'
;