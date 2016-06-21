Declare @sd smalldatetime, @ed smalldatetime;
DECLARE @readmit TABLE(name varchar(80), mrn varchar(10), account varchar(10), start1 datetime, drg1 varchar(80),dc1 datetime,account2 varchar(10),start2 datetime, drg2 varchar(80), dc2 datetime, days decimal)
DECLARE @dispo TABLE(encounter varchar(10),dispolocation varchar(80))
set @sd='4/12/2010';
set @ed='4/11/2011';

----------------------------------------------------------------------------------------------------------------

insert into @readmit
SELECT 
      IP1.PT_NAME,
      IP1.MRN,
      IP1.ACCOUNT,
      IP1.START_DATE,
      IP1.DRG_FEDERAL_CODE,
      IP1.D_C_DATE,
      IP2.ACCOUNT,
      IP2.START_DATE,
      IP2.DRG_FEDERAL_CODE,
      IP2.D_C_DATE,
      datediff(day,IP1.D_C_DATE,IP2.START_DATE) AS 'DC to Next Admit (days)'
      
FROM 
      dbo.INPATIENTS_FOR_CHF_VIEW IP1
            left join dbo.INPATIENTS_FOR_CHF_VIEW IP2
                  ON IP1.MRN=IP2.MRN
WHERE 
      IP1.MRN in (SELECT DISTINCT MRN FROM dbo.HFFOCUS_PATIENT_LIST_VIEW HF where HF.DATE_OF_FOCUS<=IP1.D_C_DATE)
      and IP1.D_C_DATE>=@sd
      and IP1.D_C_DATE<@ed
      and IP2.START_DATE > IP1.D_C_DATE
      and IP1.DRG_FEDERAL_CODE in ('291','292','293')
      and IP2.DRG_FEDERAL_CODE in ('291','292','293')
      and datediff(day,IP1.D_C_DATE,IP2.START_DATE)<31
      and IP2.START_DATE=     (
                                    SELECT MIN(IPTEMP.START_DATE)
                                    FROM dbo.INPATIENTS_FOR_CHF_VIEW IPTEMP
                                    WHERE 
                                          IPTEMP.MRN=IP1.MRN
                                          AND IPTEMP.START_DATE>IP1.D_C_DATE
                                          and IPTEMP.DRG_FEDERAL_CODE in ('291','292','293')
                                    )

ORDER BY IP1.START_DATE

---------------------------------------------------------------------------------------------------------

insert into @dispo
SELECT ENCOUNTER_NUMBER, DISPO_LOCATION
FROM dbo.HFFOCUS_PATIENT_LIST_VIEW

-----------------------------------------------------------------------------------------------------------

SELECT 
      name,
      mrn,
      account,
      start1,
      dc1,
      drg1,
      account2,   
      start2,
      dc2,
      drg2,
      days,
      d.dispolocation
FROM
      @readmit r
      left join @dispo d
      on r.account=d.encounter
