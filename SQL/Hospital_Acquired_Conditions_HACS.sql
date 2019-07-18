DECLARE @START DATE;
DECLARE @END   DATE;

SET @START = '2016-01-01';
SET @END   = '2016-02-01';

SELECT * FROM smsdss.c_hac_1_fy17_v WHERE dsch_date >= @START AND dsch_date < @END;
SELECT * FROM smsdss.c_hac_2_fy17_v WHERE dsch_date >= @START AND dsch_date < @END;
SELECT * FROM smsdss.c_hac_3_fy17_v WHERE dsch_date >= @START AND dsch_date < @END;
SELECT * FROM smsdss.c_hac_4_fy17_v WHERE dsch_date >= @START AND dsch_date < @END;
SELECT * FROM smsdss.c_hac_5_fy17_v WHERE dsch_date >= @START AND dsch_date < @END;
SELECT * FROM smsdss.c_hac_6_fy17_v WHERE dsch_date >= @START AND dsch_date < @END;
SELECT * FROM smsdss.c_hac_7_fy17_v WHERE dsch_date >= @START AND dsch_date < @END;
SELECT * FROM smsdss.c_hac_8_fy17_v WHERE dsch_date >= @START AND dsch_date < @END;
SELECT * FROM smsdss.c_hac_9_fy17_v WHERE dsch_date >= @START AND dsch_date < @END;
SELECT * FROM smsdss.c_hac_10_fy17_v WHERE dsch_date >= @START AND dsch_date < @END;
SELECT * FROM smsdss.c_hac_11_fy17_v WHERE dsch_date >= @START AND dsch_date < @END;
SELECT * FROM smsdss.c_hac_12_fy17_v WHERE dsch_date >= @START AND dsch_date < @END;
SELECT * FROM smsdss.c_hac_13_fy17_v WHERE dsch_date >= @START AND dsch_date < @END;
