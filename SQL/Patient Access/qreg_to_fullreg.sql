SELECT [PT_ID]
, [Episode_No]
, [Preadmit_No]
, [QR_Fin_Class]
, [Pt_Name]
, [Hosp_Svc]
, [Full_Reg_Dtime]
, [Full_Registrar]
, [Full_Rgstr_Name]
, [FR_Date]
, [FR_Hour]
, [FR_Day]
, [QuickReg_Dtime]
, [QR_Date]
, [QR_Hour]
, [QR_Day]
, [Quick_Registrar]
, [Quick_Rgstr_Name]
, [ER_Reg_Loc]
, [Minutes_QR_to_FR]
, (
	SELECT MIN(ent_dtime)
	FROM smsdss.c_sr_orders_finance_rpt_v as xx
	WHERE a.episode_no=xx.episode_no
	GROUP BY xx.episode_no
) as '1st_Order_Dtime'
,(
	SELECT MIN(order_str_dtime)
	FROM smsdss.c_sr_orders_finance_rpt_v as zz
	WHERE a.episode_no=zz.episode_no
	GROUP BY zz.episode_no
) as '1st_Order_Strt_Dtime'

FROM [SMSPHDSSS0X0].[smsmir].[c_er_QReg_FReg_v] as a
  
WHERE QuickReg_Dtime bETWEEN '2015-04-01 00:00:00.000' AND '2015-04-30 23:59:59.000'
  
ORDER BY episode_no
