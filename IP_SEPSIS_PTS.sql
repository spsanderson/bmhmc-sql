DECLARE @SD DATETIME
DECLARE @ED DATETIME
SET @SD = '2013-01-01';
SET @ED = '2013-07-08';

select *
--pdv.ptno_num
--, PDV.ClasfCd AS 'DX CD'
--, PV.Adm_Date AS 'ADMIT'
--, PV.Dsch_Date AS 'DISC'
--, dx.dx_cd_desc AS 'DX DESC'

FROM smsdss.BMH_PLM_PtAcct_Clasf_Dx_V PDV
JOIN smsdss.BMH_PLM_PtAcct_V PV
ON PDV.PtNo_Num = PV.PtNo_Num
JOIN smsdss.dx_cd_dim_v DX
ON PV.prin_dx_cd = DX.dx_cd

WHERE ClasfCd IN (
'785.52', '995.91', '995.92', '995.93', '995.94', '999.39', '999.89'
)
AND PV.Adm_Date BETWEEN @SD AND @ED

ORDER BY PDV.PtNo_Num
