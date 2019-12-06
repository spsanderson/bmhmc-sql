/*
***********************************************************************
File: remove_lab_rad_duplicates.sql

Input Parameters:
	None

Tables/Views:
	smsdss.c_lab_rad_order_utilization

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Remove duplicate records from the table

Revision History:
Date		Version		Description
----		----		----
2019-11-07	v1			Initial Creation
***********************************************************************
*/
SELECT *
FROM (
	SELECT MRN,
		Encounter,
		Order_No,
		Order_Loc,
		ED_IP_FLAG,
		svc_cd,
		Svc_Desc,
		Ord_Set_ID,
		Ord_Pty_Number,
		Ordering_Party,
		Ord_Pty_Spclty,
		Performing_Dept,
		Svc_Dept_Desc,
		Svc_sub_Dept,
		Svc_Sub_Dept_Desc,
		Ord_Occ_No,
		Ord_Occ_Obj_ID,
		Ord_Entry_DTime,
		Ord_Start_DTime,
		Ord_Stop_DTime,
		Order_Status,
		Order_Occ_Status,
		Admit_DateTime,
		Dup_Order,
		Admit_Year,
		RN = ROW_NUMBER() OVER (
			PARTITION BY MRN,
			Encounter,
			Order_No,
			Order_Loc,
			ED_IP_FLAG,
			svc_cd,
			Svc_Desc,
			Ord_Set_ID,
			Ord_Pty_Number,
			Ordering_Party,
			Ord_Pty_Spclty,
			Performing_Dept,
			Svc_Dept_Desc,
			Svc_sub_Dept,
			Svc_Sub_Dept_Desc,
			Ord_Occ_No,
			Ord_Occ_Obj_ID,
			Ord_Entry_DTime,
			Ord_Start_DTime,
			Ord_Stop_DTime,
			Order_Status,
			Order_Occ_Status,
			Admit_DateTime,
			Dup_Order,
			Admit_Year ORDER BY MRN,
				Encounter,
				Order_No,
				Order_Loc,
				ED_IP_FLAG,
				svc_cd,
				Svc_Desc,
				Ord_Set_ID,
				Ord_Pty_Number,
				Ordering_Party,
				Ord_Pty_Spclty,
				Performing_Dept,
				Svc_Dept_Desc,
				Svc_sub_Dept,
				Svc_Sub_Dept_Desc,
				Ord_Occ_No,
				Ord_Occ_Obj_ID,
				Ord_Entry_DTime,
				Ord_Start_DTime,
				Ord_Stop_DTime,
				Order_Status,
				Order_Occ_Status,
				Admit_DateTime,
				Dup_Order,
				Admit_Year
			)
	FROM SMSDSS.c_Lab_Rad_Order_Utilization
	) X
WHERE RN > 1
