library(tidyverse)
library(lubridate)

file <- readxl::read_excel(
  path = "C:/Users/bha485/Desktop/InvisionMPIl060222.xlsx"
)

cleaned_file <- file %>%
  mutate(DOB = format(mdy(DOB), "%m/%d/%Y")) %>%
  mutate(`LAST ACTIO` = format(mdy(`LAST ACTIO`), "%m/%d/%Y")) %>%
  mutate(`ADM DATE` = format(mdy(`ADM DATE`), "%m/%d/%Y")) %>%
  mutate(SSN_L = nchar(SSN)) %>%
  mutate(SSN = ifelse(SSN_L < 7, NA, SSN)) %>%
  mutate(SSN = ifelse(SSN_L == 7, paste0("00", SSN), SSN)) %>%
  mutate(SSN = ifelse(SSN_L == 8, paste0("0", SSN), SSN)) %>%
  mutate(SSN = ifelse(
    !is.na(SSN), 
    paste0(
      substr(SSN, 1, 3),
      "-",
      substr(SSN, 4, 5),
      "-",
      substr(SSN, 6, 9)
    ),
    SSN
    )
  ) %>%
  mutate(ZIP_L = nchar(ZIP)) %>%
  mutate(ZIP = ifelse(ZIP_L < 4, NA, ZIP)) %>%
  mutate(ZIP = ifelse(ZIP_L == 4, paste0("0", ZIP), ZIP)) %>%
  select(-SSN_L, -ZIP_L)

writexl::write_xlsx(
  x = cleaned_file,
  path = "G:/IS/C Wurtz/invision_file.xlsx"
)
