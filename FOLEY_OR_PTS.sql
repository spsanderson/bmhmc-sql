DECLARE @SD DATETIME
DECLARE @ED DATETIME
SET @SD = '2013-06-01';
SET @ED = '2013-06-30';

WITH [SX FLAG] AS (
    SELECT DISTINCT 
    PV.PtNo_Num AS [VISIT ID]
    , PV.Med_Rec_No AS MRN
    , PV.vst_start_dtime AS ADM
    , PV.vst_end_dtime AS DISCH
    , PV.Days_Stay AS LOS
    , PV.pt_type AS [PT TYPE]
    , PV.hosp_svc AS [HOSP SVC]
    , SO.ord_no AS [ORD NUM]
    , X.[ORD DESC]
    , SO.pty_name AS [PARTY NAME]
    , OSM.ord_sts AS [ORD STS]
    , SOS.prcs_dtime AS [ORD STS TIME]
    , DATEDIFF(DAY,PV.vst_start_dtime,SOS.prcs_dtime) AS [ADM TO ORD STS IN DAYS]
    , MAX(CASE WHEN [ORD DESC] IN ('INSERT FOLEY', 'REMOVE FOLEY') THEN 1 ELSE 0 END)
        OVER (PARTITION BY PV.PTNO_NUM) AS HasInsertRemoveFoley
    , MAX(CASE WHEN ACDV.actv_group = 'OR' THEN 1 ELSE 0 END)
        OVER (PARTITION BY PV.PTNO_NUM) AS HasORTime

    FROM smsdss.BMH_PLM_PtAcct_V PV
    JOIN smsmir.sr_ord SO
    ON PV.PtNo_Num = SO.episode_no
    JOIN smsmir.sr_ord_sts_hist SOS
    ON SO.ord_no = SOS.ord_no
    JOIN smsmir.ord_sts_modf_mstr OSM
    ON SOS.hist_sts = OSM.ord_sts_modf_cd
    JOIN smsdss.actv_fct_v AFV
    ON PV.Pt_No = AFV.pt_id
    JOIN smsdss.actv_cd_dim_v ACDV
    ON AFV.actv_cd = ACDV.actv_cd

    CROSS APPLY (
        SELECT
            CASE
                WHEN SO.svc_desc = 'INSERT FOLEY CATHETER' THEN 'INSERT FOLEY'
                WHEN SO.svc_desc = 'INSERT INDWELLING URINARY CATHETER TO GRAVITY DRAINAGE' THEN 'INSERT FOLEY'
                WHEN SO.svc_desc = 'REMOVE INDWELLING URINARY CATHETER' THEN 'REMOVE FOLEY'
                ELSE SO.svc_desc
            END AS [ORD DESC]
            ) X


    WHERE PV.Adm_Date BETWEEN @SD AND @ED
    AND SO.svc_cd IN ('PCO_REMFOLEY' -- <-- The orders I am looking for
        ,'PCO_INSRTFOLEY'            -- <-- for patients who have had a
        ,'PCO_INSTFOLEY'             -- <-- surgical procedure
        ,'PCO_URIMETER'
        )
     -- I don't want patients who fall into these pt types
    AND PV.hosp_svc NOT IN (
        'DIA'
        ,'DMS'
        ,'EME'
        )
     -- This is supposed to kick out orders that were 'Discontinued'
     -- or orders that were 'Canceled'
    AND SO.ord_no NOT IN (
        SELECT SO.ord_no

        FROM smsdss.BMH_PLM_PtAcct_V PV
        JOIN smsmir.sr_ord SO
        ON PV.PtNo_Num = SO.episode_no
        JOIN smsmir.sr_ord_sts_hist SOS
        ON SO.ord_no = SOS.ord_no
        JOIN smsmir.ord_sts_modf_mstr OSM
        ON SOS.hist_sts = OSM.ord_sts_modf_cd
        JOIN smsdss.actv_fct_v AFV        -- <-- gets pt activity
        ON PV.Pt_No = AFV.pt_id
        JOIN smsdss.actv_cd_dim_v ACDV    -- <-- tells me if pt had OR Time
        ON AFV.actv_cd = ACDV.actv_cd

        WHERE OSM.ord_sts = 'DISCONTINUE' -- <-- don't want these orders
        AND SO.svc_cd IN ('PCO_REMFOLEY'  -- <-- to show if they were
        ,'PCO_INSRTFOLEY'                 -- <-- canned / discontinued
        ,'PCO_INSTFOLEY'
        ,'PCO_URIMETER'
        )
    )
)
SELECT *
FROM [SX FLAG]
WHERE HasInsertRemoveFoley = 1
AND HasORTime = 1 