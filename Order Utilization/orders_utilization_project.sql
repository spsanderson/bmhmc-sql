--DROP TABLE smsdss.c_Lab_Rad_Order_Utilization

DECLARE @T1 TABLE (
       PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
       , MRN                 INT
       , Encounter           INT
       , Order_No            INT
       , Order_Loc           VARCHAR(100)
       , Svc_Cd              VARCHAR(100)
       , Svc_Desc            VARCHAR(500)
       , Ord_Set_ID          VARCHAR(200)
       , Ordering_Party      VARCHAR(500)
       , Ord_Pty_Number      CHAR(6)
       , Ord_Pty_Spclty      CHAR(5)
       , Performing_Dept     VARCHAR(100)
       , Svc_Dept            VARCHAR(100)
       , Svc_Sub_Dept        VARCHAR(100)
       , Ord_Occ_No          INT
       , Ord_Occ_Obj_ID      INT
       , Ord_Entry_DTime     DATETIME
       , Ord_Start_DTime     DATETIME
       , Ord_Stop_DTime      DATETIME
       , Order_Status        VARCHAR(250)
       , Order_Occ_sts_cd    CHAR(1)
       , Order_Occ_Status    VARCHAR(250)
       , Admit_DateTime      DATETIME
       , Admit_Year          VARCHAR(100) 
       , Dup_Order           CHAR(1)
);

WITH T1 AS (
       SELECT A.med_rec_no
       , A.episode_no
       , A.ord_no
       , A.ord_loc
       , A.svc_cd
       , A.svc_desc
       , A.ord_set_id
       , A.pty_name
       , A.pty_cd
       , E.src_spclty_cd
       , A.perf_dept
       , A.svc_dept
       , A.svc_subdept
       , A.ord_occr_no
       , A.ord_occr_obj_id
       , A.ent_dtime
       , A.Order_Str_Dtime
       , A.stp_dtime
       , C.ord_sts_modf  AS [Order_Status]
       , B.occr_sts_cd
       , B.occr_sts_modf AS [Order_Occ_Status]
       , D.adm_dtime
       , YEAR(d.adm_Dtime) AS [Admit_Year]
       , a.ovrd_dup_ind

       FROM smsdss.c_sr_orders_finance_rpt_v    AS A
       INNER JOIN SMSMIR.ord_occr_sts_modf_mstr AS B
       ON A.Occr_Sts = B.occr_sts_modf_cd
       INNER JOIN SMSMIR.ord_sts_modf_mstr      AS C
       ON A.ord_sts = C.ord_sts_modf_cd
       LEFT OUTER JOIN smsmir.acct              AS D
       ON A.episode_no = SUBSTRING(D.pt_id, 5, 8)
       LEFT OUTER JOIN smsdss.pract_dim_v       AS E
       ON A.pty_cd = E.src_pract_no
       AND E.orgz_cd = 'S0X0'

       WHERE LEFT(A.svc_cd, 3) IN (
              '004', '005', '006', '013', '014', '023'
       )
       AND C.ord_sts_modf IN ('Complete', 'Discontinue')
       AND D.adm_date >= '2018-11-01'
       AND D.adm_date <  '2018-12-01'
       -- CAN ADD UNITIZED ACCOUNTS BACK IN IF NEEDED
       --AND LEFT(A.episode_no, 1) != '7'
       AND (
              A.episode_no < '20000000'
              OR
                     (
                     A.episode_no > '80000000'
                     AND
                     A.episode_no < '99999999'
                     )
              )
)

INSERT INTO @T1
SELECT * FROM T1

INSERT INTO smsdss.c_Lab_Rad_Order_Utilization

SELECT t1.MRN
, t1.Encounter
, t1.Order_No
, t1.Order_Loc
, CASE
       WHEN T1.Order_Loc = 'EDICMS'
              THEN 'ED'
       WHEN T1.Order_Loc != 'EDICMS'
              AND LEFT(T1.Encounter, 1) = '8'
              THEN 'ED'
       WHEN T1.Order_Loc != 'EDICMS'
              AND T1.Ord_Pty_Spclty = 'EMRED'
              THEN 'ED'
       ELSE 'IP'
  END AS [ED_IP_FLAG]
, T1.svc_cd
, t1.Svc_Desc
, t1.Ord_Set_ID
, t1.Ord_Pty_Number
, t1.Ordering_Party
, t1.Ord_Pty_Spclty
, t1.Performing_Dept
, CASE
       WHEN T1.Performing_Dept='BMHEKG' THEN 'EKG'
       WHEN t1.Svc_Sub_Dept IN (
       '114', '7', '2', '137', '127', '3', '135', '6'  --117
       )
              THEN 'Laboratory'
       WHEN t1.Svc_Sub_Dept IN (
       '1045', '16', '13', '12', '11', '14', '17', '10', '1004' --133
       )
              THEN 'Radiology'
  END AS [Svc_Dept_Desc]
, T1.Svc_sub_Dept
, CASE
       WHEN T1.Performing_Dept = 'BMHEKG' THEN 'EKG'
       WHEN t1.Svc_Sub_Dept = '114'  THEN 'Cytology'
       WHEN t1.Svc_Sub_Dept = '7'    THEN 'Hematology'
       WHEN t1.Svc_Sub_Dept = '2'    THEN 'Blood Bank'
       WHEN t1.Svc_Sub_Dept = '137'  THEN 'Serology'
       WHEN t1.Svc_Sub_Dept = '127'  THEN 'Other'
       WHEN t1.Svc_Sub_Dept = '3'    THEN 'Microbiology'
       WHEN t1.Svc_Sub_Dept = '135'  THEN 'Reference'
       --WHEN t1.Svc_Sub_Dept = '117'  THEN 'Lab Order Only' Remove Per Jim Carr.  SCM 3-25-16
       WHEN t1.Svc_Sub_Dept = '6'    THEN 'Chemistry'
       WHEN t1.Svc_Sub_Dept = '1045' THEN 'Mobile PET Scan'
       WHEN t1.Svc_Sub_Dept = '16'   THEN 'Special Procedures'
       WHEN t1.Svc_Sub_Dept = '13'   THEN 'MRI'
       WHEN t1.Svc_Sub_Dept = '12'   THEN 'Mammography'
       WHEN t1.Svc_Sub_Dept = '11'   THEN 'DX Radiology'
       --WHEN t1.Svc_Sub_Dept = '133'  THEN 'Rad Order Only' Remove Per Chris Schneider. SCM 3-25-16
       WHEN t1.Svc_Sub_Dept = '14'   THEN 'Nuclear Medicine'
       WHEN t1.Svc_Sub_Dept = '17'   THEN 'Ultrasound'
       WHEN t1.Svc_Sub_Dept = '10'   THEN 'Cat Scan'
       WHEN t1.Svc_Sub_Dept = '1004' THEN 'BNL'
  END AS [Svc_Sub_Dept_Desc]
, t1.Ord_Occ_No
, t1.Ord_Occ_Obj_ID
, t1.Ord_Entry_DTime
, t1.Ord_Start_DTime
, t1.Ord_Stop_DTime
, t1.Order_Status
, t1.Order_Occ_Status
, t1.Admit_DateTime
, t1.Dup_Order
, T1.Admit_Year

FROM @T1 T1
WHERE T1.Order_Occ_sts_cd = '4'
AND T1.SVC_SUB_DEPT NOT IN ('133','117')

SELECT *
FROM  smsdss.c_Lab_Rad_Order_Utilization ZZZ
WHERE ZZZ.ED_IP_FLAG IN ('IP','ED')  -- ED OR IP
AND ZZZ.Svc_Dept_Desc IN ('Laboratory','Radiology') -- Laboratory OR Radiology
ORDER BY ED_IP_FLAG, Svc_Dept_Desc
--DROP TABLE #order_tmp_tbl
