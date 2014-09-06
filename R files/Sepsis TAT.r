library(XLConnectJars)
library(XLConnect)
library(lubridate)
library(ggplot2)
library(knitr)
library(grid)
library(gridExtra)
library(timeDate)

# Load the workbook
sepsis.workbook <- loadWorkbook("SEPSIS.xlsx")
data <- readWorksheet(sepsis.workbook, sheet = "DATA")
# We are dropping this column for now since there is a read issue with
# it when we are trying to bring the data in
# Clear out some other uneeded columns
data$FINAL.DISPOSITION <- NULL
data$NAME              <- NULL
data$MRN               <- NULL
data$DISPO             <- NULL
data$ARRIVAL.MONTH     <- NULL
data$ARRIVAL.YR        <- NULL

# Just to see some of the data
summary(data)
head(data)

# We now want to make a new dataset that gets rid of the rows where
# one of the orders were not placed and where some of them have
# no inprogress time.
noIP = "No In Progress Time"
dataOrdClean  <- data[data$IV.FLUIDS                  == "Y"  &
                        data$CXR                      == "Y"  &
                        data$AB                       == "Y"  &
                        data$WBC                      == "Y"  & 
                        data$LACTATE                  == "Y"  &
                        data$TRIAGE.TO.IP.MINUTES     != noIP &
                        data$TRIAGE.TO.IP.MINUTES.1   != noIP &
                        data$TRIAGE.TO.IP.MINUTES.2   != noIP &
                        data$TRIAGE.TO.IP.MINUTES.3   != noIP &
                        data$TRIAGE.TO.IP.MINUTES.4   != noIP &
                        data$TRIAGE.TO.COMP.MINUTES   != "NC" &
                        data$TRIAGE.TO.COMP.MINUTES.1 != "NC" &
                        data$TRIAGE.TO.COMP.MINUTES.2 != "NC" &
                        data$TRIAGE.TO.COMP.MINUTES.3 != "NC" &
                        data$TRIAGE.TO.COMP.MINUTES.4 != "NC",]

# Now we can get rid of the following columns
dataOrdClean$LACTATE           <- NULL
dataOrdClean$IV.FLUIDS         <- NULL
dataOrdClean$CXR               <- NULL
dataOrdClean$AB                <- NULL
dataOrdClean$WBC               <- NULL

# These columns we are going to clear out because we will recalculate
# them using the lubridate package to make sure there are no excel 
# errors in the sheet
dataOrdClean$ARR.TO.TRIAGE.MINUTES     <- NULL
dataOrdClean$ARR.TO.DISC.HRS           <- NULL
dataOrdClean$TRIAGE.TO.ORDER.MINUTES   <- NULL
dataOrdClean$TRIAGE.TO.ORDER.MINUTES.1 <- NULL
dataOrdClean$TRIAGE.TO.ORDER.MINUTES.2 <- NULL
dataOrdClean$TRIAGE.TO.ORDER.MINUTES.3 <- NULL
dataOrdClean$TRIAGE.TO.ORDER.MINUTES.4 <- NULL
dataOrdClean$TRIAGE.TO.IP.MINUTES      <- NULL
dataOrdClean$TRIAGE.TO.IP.MINUTES.1    <- NULL
dataOrdClean$TRIAGE.TO.IP.MINUTES.2    <- NULL
dataOrdClean$TRIAGE.TO.IP.MINUTES.3    <- NULL
dataOrdClean$TRIAGE.TO.IP.MINUTES.4    <- NULL
dataOrdClean$TRIAGE.TO.COMP.MINUTES    <- NULL
dataOrdClean$TRIAGE.TO.COMP.MINUTES.1  <- NULL
dataOrdClean$TRIAGE.TO.COMP.MINUTES.2  <- NULL
dataOrdClean$TRIAGE.TO.COMP.MINUTES.3  <- NULL
dataOrdClean$TRIAGE.TO.COMP.MINUTES.4  <- NULL

# How many observations were excluded due to the fact that they were
# missing at least one order or there was no Inprogress time for it
missing.orders = nrow(data)-nrow(dataOrdClean)
missing.orders
missing.order.ratio = round(missing.orders/nrow(data), digits = 2)
missing.order.ratio

# Clean up dates
# Make the Arrival Datetime a lubridate format of ymd_hms
dataOrdClean$ARRIVAL <- ymd_hms(dataOrdClean$ARRIVAL, tz = "UTC",
                                locale = Sys.getlocale("LC_TIME"),
                                truncated = 0)

dataOrdClean$TRIAGE.TIME <- ymd_hms(dataOrdClean$TRIAGE.TIME,
                                    tz = "UTC", 
                                    locale = Sys.getlocale("LC_TIME"),
                                    truncated = 0)

dataOrdClean$DISC.TIME <- ymd_hms(dataOrdClean$DISC.TIME, tz = "UTC",
                                  locale = Sys.getlocale("LC_TIME"),
                                  truncated = 0)

dataOrdClean$IV.ORDER  <- ymd_hms(dataOrdClean$IV.ORDER, tz = "UTC",
                                  locale = Sys.getlocale("LC_TIME"),
                                  truncated = 0)

dataOrdClean$IV.IP     <- ymd_hms(dataOrdClean$IV.IP, tz = "UTC",
                                  locale = Sys.getlocale("LC_TIME"),
                                  truncated = 0)

dataOrdClean$IV.COMP   <- ymd_hms(dataOrdClean$IV.COMP, tz = "UTC",
                                  locale = Sys.getlocale("LC_TIME"),
                                  truncated = 0)

dataOrdClean$CXR.ORDER <- ymd_hms(dataOrdClean$CXR.ORDER, tz = "UTC",
                                  locale = Sys.getlocale("LC_TIME"),
                                  truncated = 0)

dataOrdClean$CXR.IP    <- ymd_hms(dataOrdClean$CXR.IP, tz = "UTC",
                                  locale = Sys.getlocale("LC_TIME"),
                                  truncated = 0)

dataOrdClean$CXR.COMP  <- ymd_hms(dataOrdClean$CXR.COMP, tz = "UTC",
                                  locale = Sys.getlocale("LC_TIME"),
                                  trucated = 0)

dataOrdClean$AB.ORDER  <- ymd_hms(dataOrdClean$AB.ORDER, tz = "UTC",
                                  locale = Sys.getlocale("LC_TIME"),
                                  trucated = 0)

dataOrdClean$AB.IP     <- ymd_hms(dataOrdClean$AB.IP, tz = "UTC",
                                  locale = Sys.getlocale("LC_TIME"),
                                  truncated = 0)

dataOrdClean$AB.COMP   <- ymd_hms(dataOrdClean$AB.COMP, tz = "UTC",
                                  locale = Sys.getlocale("LC_TIME"),
                                  truncated = 0)

dataOrdClean$WBC.ORDER.TIME <- ymd_hms(dataOrdClean$WBC.ORDER.TIME,
                                       tz = "UTC",
                                       locale = Sys.getlocale("LC_TIME"),
                                       truncated = 0)

dataOrdClean$WBC.IP    <- ymd_hms(dataOrdClean$WBC.IP, tz = "UTC",
                                  locale = Sys.getlocale("LC_TIME"),
                                  truncated = 0)

dataOrdClean$WBC.COMP  <- ymd_hms(dataOrdClean$WBC.COMP, tz = "UTC",
                                  locale = Sys.getlocale("LC_TIME"),
                                  truncated = 0)

dataOrdClean$LACTATE.ORDER.TIME <- ymd_hms(
  dataOrdClean$LACTATE.ORDER.TIME, tz = "UTC",
  locale = Sys.getlocale("LC_TIME"), truncated = 0)

dataOrdClean$LACTATE.IP <- ymd_hms(dataOrdClean$LACTATE.IP,
                                   tz = "UTC",
                                   locale = Sys.getlocale("LC_TIME"),
                                   truncated = 0)

dataOrdClean$LACTATE.COMP <- ymd_hms(dataOrdClean$LACTATE.COMP,
                                     tz = "UTC",
                                     locale = Sys.getlocale("LC_TIME"),
                                     truncated = 0)


# Arrival Month
dataOrdClean$Arrival.Month <- month(dataOrdClean$ARRIVAL, label = TRUE, 
                                    abbr = TRUE)
# Arrival Year
dataOrdClean$Arrival.Year  <- year(dataOrdClean$ARRIVAL)

# Arrival to Triage Time
dataOrdClean$Arr.to.Triage.Min     <- as.numeric(
  difftime(
    dataOrdClean$TRIAGE.TIME, dataOrdClean$ARRIVAL,
    units = "mins")
)

# Arrival to Discharge in Hours
dataOrdClean$Arr.to.Discharge.Hrs  <- as.numeric(
  round(
    difftime(dataOrdClean$DISC.TIME, dataOrdClean$ARRIVAL,
             units = "hours"),
    digits = 2)
)

# Arrival to Discharge in Minutes
dataOrdClean$Arr.to.Discharge.Min  <- as.numeric(
  difftime(dataOrdClean$DISC.TIME, dataOrdClean$ARRIVAL,
           units = "mins")
)

# Triage to discharge in Hours
dataOrdClean$Triage.to.Discharge.Hrs <- as.numeric(
  round(
    difftime(dataOrdClean$DISC.TIME, dataOrdClean$TRIAGE.TIME,
             units = "hours"),
    digits = 2)
)


# Triage to Discharge in Minutes
dataOrdClean$Triage.to.Discharge.Min <- as.numeric(
  difftime(dataOrdClean$DISC.TIME, dataOrdClean$TRIAGE.TIME,
           units = "mins")
)

# Fix All Time from Triage to Ordered, In Progress and Complete then
# change all timediff's to as.numeric()

# Triage to Order IV Fluids
dataOrdClean$IV.Triage.to.Order <- as.numeric(
  difftime(dataOrdClean$IV.ORDER, dataOrdClean$TRIAGE.TIME,
           units = "mins")
)

# Triage to IP IV Fluids
dataOrdClean$IV.Triage.to.IP    <- as.numeric(
  difftime(dataOrdClean$IV.IP, dataOrdClean$TRIAGE.TIME,
           units = "mins")
)

# Triage to Complete IV Fluids
dataOrdClean$IV.Triage.to.Comp  <- as.numeric(
  difftime(dataOrdClean$IV.COMP, dataOrdClean$TRIAGE.TIME,
           units = "mins")
)

# IV Fluids Order to IP
dataOrdClean$IV.Order.to.IP  <- as.numeric(
  difftime(dataOrdClean$IV.IP, dataOrdClean$IV.ORDER,
           units = "mins")
)

# IV Fluids IP to Complete
dataOrdClean$IV.IP.to.Comp   <- as.numeric(
  difftime(dataOrdClean$IV.COMP, dataOrdClean$IV.IP,
           units = "mins")
)

# Triage to Order CXR
dataOrdClean$CX.Triage.to.Order <- as.numeric(
  difftime(dataOrdClean$CXR.ORDER, dataOrdClean$TRIAGE.TIME,
           units = "mins")
)

# Triage to IP CXR
dataOrdClean$CX.Triage.to.IP    <- as.numeric(
  difftime(dataOrdClean$CXR.IP, dataOrdClean$TRIAGE.TIME,
           units = "mins")
)

# Triage to Comp CXR
dataOrdClean$CX.Triage.to.Comp  <- as.numeric(
  difftime(dataOrdClean$CXR.COMP, dataOrdClean$TRIAGE.TIME,
           units = "mins")
)

