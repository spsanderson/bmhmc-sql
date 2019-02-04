/*
***********************************************************************
File: consults_coded_ordered_reconscile.sql

Input Parameters:
	None

Tables/Views:
	smsdss.c_Coaded_Consults_v
	smsmir.sr_ord AS SO
	smsmir.sr_ord_sts_hist AS SOSH
	smsdss.BMH_PLM_PtAcct_V AS PAV
	smsdss.pract_dim_v AS PDV

Creates Table:
	Enter Here

Functions:
	Enter Here

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Entere Here

Revision History:
Date		Version		Description
----		----		----
2018-12-20	v1			Initial Creation
***********************************************************************
*/
DECLARE @TODAY DATE;
DECLARE @START DATE;
DECLARE @END   DATE;

SET @TODAY = CAST(GETDATE() AS date);
SET @START = DATEADD(MONTH, DATEDIFF(MONTH, 0, @TODAY) - 18, 0);
SET @END   = DATEADD(MONTH, DATEDIFF(MONTH, 0, @TODAY), 0);

SELECT A.Med_Rec_No
, A.episode_no
, A.Adm_Date
, A.Dsch_Date
, A.Days_Stay
, A.Atn_Dr_No
, CASE
	WHEN SUBSTRING(A.Attending_MD, 1,
	CHARINDEX(' X', A.Attending_MD, 1)) = ''
		THEN UPPER(A.Attending_MD)
		ELSE SUBSTRING(A.Attending_MD, 1,
			CHARINDEX(' X', A.Attending_MD, 1))
  END AS [Attending_MD]
, A.Attending_Flag
, A.Order_Coded_Flag
, A.Ordering_pty_cd
, A.Ordering_pty_name
, A.ord_no
, A.ord_obj_id
, A.ent_date
, A.str_dtime
, A.stp_dtime
, A.Ord_sts
, A.sts_no
, A.prcs_dtime
, A.no_of_occrs
, A.signon_id
, A.ClasfCd
, A.Consultant_Contacted
, A.Consultant_Spec

INTO #TEMPA

FROM (
	SELECT Med_Rec_No
	, SUBSTRING(pt_no, 5, 8) as [episode_no]
	, Adm_Date
	, Dsch_Date
	, Days_Stay
	, Atn_Dr_No
	, Attending_MD
	, Attending_Flag
	, '' AS [Ordering_pty_cd]
	, '' AS [Ordering_pty_name]
	, '' AS [ord_no]
	, '' AS [ord_obj_id]
	, ClasfCd
	, CONSULTANT AS [Consultant_Contacted]
	, Consultant_Spec
	, '' AS [ent_date]
	, '' AS [str_dtime]
	, '' AS [stp_dtime]
	, '' AS [Ord_sts]
	, '' AS [sts_no]
	, '' AS [no_of_occrs]
	, '' AS [signon_id]
	, '' AS [prcs_dtime]
	, 'Coded Consult' AS [Order_Coded_Flag]

	FROM smsdss.c_Coaded_Consults_v
	WHERE Dsch_Date >= @START
	AND Dsch_Date < @END
	AND LEFT(PT_NO, 5) = '00001'
	AND Pt_No IN (
	SELECT Pt_No
	FROM smsdss.BMH_PLM_PtAcct_V
	WHERE tot_chg_amt > 0
	)
	--WHERE Pt_No = '000014506190'

	UNION

	SELECT PAV.Med_Rec_No
	, SO.episode_no
	, CAST(PAV.ADM_DATE AS date) AS [Adm_Date]
	, CAST(PAV.DSCH_DATE AS date) AS [Dsch_Date]
	, PAV.DAYS_STAY AS [Days_Stay]
	, PAV.Atn_Dr_No
	, CASE
		WHEN SUBSTRING(PDV.pract_rpt_name, 1,
		CHARINDEX(' X', PDV.PRACT_RPT_NAME, 1)) = ''
			THEN UPPER(PDV.PRACT_RPT_NAME)
			ELSE SUBSTRING(PDV.PRACT_RPT_NAME, 1,
				CHARINDEX(' X', PDV.pract_rpt_name, 1))
	  END AS [Attending_MD]
	, CASE
	WHEN PDV.src_spclty_cd = 'HOSIM'
	THEN 'Hospitalist'
	ELSE 'Private'
	  END AS [Attending_Flag]
	, SO.pty_cd AS [Ordering_pty_cd]
	, SO.pty_name AS [Ordering_pty_name]
	, SO.ord_no
	, SO.ord_obj_id
	, SO.svc_cd AS [ClasfCd]
	, RTRIM(
		REPLACE(
			REPLACE(
				REPLACE(
					SUBSTRING(SO.DESC_AS_WRITTEN, 21, 40)
				, 'Today', '')
			,'Stat','')
		,'In Am','')
	  ) AS [Consultant_Contacted]
	, '' AS [Consultant_Spec]
	, SO.ent_date
	, SO.str_dtime
	, SO.stp_dtime
	, SO.ord_sts
	, SO.sts_no
	, SO.no_of_occrs
	, SOSH.signon_id
	, SOSH.prcs_dtime
	, 'Ordered Consult' AS [Order_Coded_Flag]

	FROM smsmir.sr_ord AS SO
	LEFT OUTER JOIN smsmir.sr_ord_sts_hist AS SOSH
	ON SO.ord_no = SOSH.ord_no
	AND SO.ord_obj_id = SOSH.ord_obj_id
	AND SO.ord_sts = SOSH.hist_sts
	AND SO.sts_no = SOSH.hist_no
	LEFT OUTER JOIN smsdss.BMH_PLM_PtAcct_V AS PAV
	ON SO.EPISODE_NO = PAV.PtNo_Num
	LEFT OUTER JOIN smsdss.pract_dim_v AS PDV
	ON PAV.Atn_Dr_No = PDV.src_pract_no
	AND PAV.Regn_Hosp = PDV.orgz_cd

	WHERE SO.svc_cd = 'Consult: Doctor'
	AND PAV.Dsch_Date >= @START
	AND PAV.Dsch_Date < @END
	AND PAV.Plm_Pt_Acct_Type = 'I'
	AND PAV.tot_chg_amt > 0
	--AND SO.episode_no = '14506190'
) AS A

;

SELECT A.*
, CASE
	WHEN A.Ordering_pty_name = ''
		THEN UPPER(RTRIM(LTRIM(REPLACE(Pos1, ',', ''))))
	WHEN A.Ordering_pty_name != ''
	AND LEN(Pos2) < 2
		THEN UPPER(RTRIM(LTRIM(REPLACE(Pos3, ',', ''))))
		ELSE UPPER(RTRIM(LTRIM(REPLACE(Pos2, ',', ''))))
  END AS [Consultant_Last_Name]
, CASE
	WHEN A.Ordering_pty_name = ''
		THEN UPPER(RTRIM(LTRIM(REPLACE(Pos2, ',', ''))))
		ELSE UPPER(RTRIM(LTRIM(REPLACE(Pos1, ',', ''))))
  END AS [Consultant_First_Name]

INTO #TEMPB

FROM #TEMPA AS A

CROSS APPLY (
	Select Pos1 = n.value('/x[1]','varchar(100)')
	, Pos2 = n.value('/x[2]','varchar(100)')
	, Pos3 = n.value('/x[3]','varchar(100)')

	FROM (
		SELECT CAST('<x>' + replace(A.Consultant_Contacted,' ','</x><x>')+'</x>' as xml) as n
	) X
) B
;

WITH CTE AS (
	SELECT *
	, [Consultant_Full_Name] = CONCAT(A.Consultant_Last_Name, ', ', A.Consultant_First_Name)
	, [RN] = ROW_NUMBER() OVER(
	PARTITION BY A.EPISODE_NO, CONCAT(A.Consultant_Last_Name, ', ', A.Consultant_First_Name)
	Order BY A.EPISODE_NO, CONCAT(A.Consultant_Last_Name, ', ', A.Consultant_First_Name), A.ORDER_CODED_FLAG desc
	)
	FROM #TEMPB AS A
)

SELECT C1.Med_Rec_No
, C1.episode_no
, C1.Adm_Date
, C1.Dsch_Date
, C1.Days_Stay
, C1.Atn_Dr_No
, C1.Attending_MD
, C1.Attending_Flag
, C1.Order_Coded_Flag
, C1.Ordering_pty_cd
, C1.Ordering_pty_name
, C1.ord_no
, C1.ord_obj_id
, C1.ent_date
, C1.str_dtime
, C1.stp_dtime
, C1.Ord_sts
, C1.sts_no
, C1.prcs_dtime
, C1.no_of_occrs
, C1.signon_id
, C1.ClasfCd
, C1.Consultant_Contacted
, C1.Consultant_Spec
, C1.Consultant_Last_Name
, C1.Consultant_First_Name
, C1.Consultant_Full_Name
, C1.RN
, C1.Order_Coded_Flag AS [Consult_Type_A]
, C1.Consultant_Full_Name AS [Consultant_Full_Name_A]
, C2.Order_Coded_Flag AS [Consult_Type_B]
, C2.Consultant_Full_Name AS [Consultant_Full_Name_B]
, C1.RN AS C1RN
, C2.RN AS C2RN
, CASE
	WHEN C1.Order_Coded_Flag = 'Ordered Consult'
	AND C2.Order_Coded_Flag = 'Coded Consult'
		THEN 'Ordered_and_Coded'
	WHEN C1.Order_Coded_Flag = 'Ordered Consult'
	AND C2.Order_Coded_Flag IS NULL
		THEN 'Ordered_not_Coded'
		ELSE 'Coded_not_Ordered'
  END AS [Possible_Consult_Order_Status]
, [Consult_RN] = ROW_NUMBER() OVER(PARTITION BY C1.EPISODE_NO ORDER BY C1.EPISODE_NO)
, [Consult_Flag] = 1
, CASE
	WHEN C1.ORDER_CODED_FLAG = 'Ordered Consult'
		THEN 1
		ELSE 0
  END AS [Ordered_Flag]
, CASE
	WHEN C1.ORDER_CODED_FLAG = 'Coded Consult'
		THEN 1
		ELSE 0
  END AS [Coded_Flag]
, YEAR(C1.Dsch_Date) AS [DSCH_YR]
, MONTH(C1.DSCH_DATE) AS [DSCH_MONTH]
, DATEPART(WEEKDAY, C1.DSCH_DATE) AS [DSCH_DAY]
, DATEPART(QUARTER, C1.DSCH_DATE) AS [DSCH_QTR]

--INTO #TEMPC

FROM CTE AS C1
LEFT OUTER JOIN CTE AS C2
ON C1.Med_Rec_No = C2.Med_Rec_No
	AND C1.episode_no = C2.episode_no
	AND C1.Consultant_Full_Name = C2.Consultant_Full_Name
	AND C1.Order_Coded_Flag <> C2.Order_Coded_Flag

--WHERE C1.Order_Coded_Flag = 'Ordered Consult'
WHERE (
	(
		C1.RN = 1
		AND C2.RN = 2
	)
	OR
	(
		C1.RN >= 1
		AND C2.RN IS NULL
	)
)

ORDER BY C1.episode_no, C2.Order_Coded_Flag DESC, C2.Consultant_Full_Name
;

;
--DROP TABLE #TEMPA, #TEMPB, #TEMPC
--;
SELECT A.*
, [Consultant_Full_Name] = CONCAT(A.Consultant_Last_Name, ', ', A.Consultant_First_Name)
, [Consult_RN] = ROW_NUMBER() OVER(PARTITION BY A.EPISODE_NO ORDER BY A.EPISODE_NO)
, [Consult_Flag] = 1
, CASE
	WHEN A.Order_Coded_Flag = 'Coded Consult'
		THEN 1
		ELSE 0
  END AS Coded_Flag
, CASE
	WHEN A.Order_Coded_Flag = 'Ordered Consult'
		THEN 1
		ELSE 0
  END AS Ordered_Flag

FROM #TEMPB AS A
;

