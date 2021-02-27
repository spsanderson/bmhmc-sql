#' Automatically Geocode Addresses
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' Get discharged accounts from DSS and geocode them with Nominatim OpenStreet Maps
#'
#' @details
#' - Requires a connection to DSS, uses both [db_connect()] and [db_disconnect()]
#' - Uses the [geocode_discharges_query()] internally.
#' - Saves a file to where you specify for accounts that could not be automatically geocoded
#' - This can be run numerous times a day since the records are inserted into a table after
#' geocoding and lookedup to make sure they do not already exist there.
#' - This will look back at discharges starting with a discharge date of six months prior
#' to the SQL GETEDATE() function
#'
#' @return
#' A tibble
#'
#' @export
#'
geocode_discharges_automation <- function() {

  # File path to save non-geocoded records
  file_path <- utils::choose.dir()

  # Get discharges to geocode
  query <- LICHospitalR::geocode_discharges_query() %>%
    tibble::as_tibble() %>%
    dplyr::filter(stringr::str_sub(PtNo_Num, 1, 1) != 2)

  # Exit with no records ----
  # If there are no records then stop out of function
  if (base::nrow(query) == 0) {
    base::return(base::print("There were no records returned by the query."))
  }

  # Make intermediate tables
  origAddress <- query %>%
    dplyr::select(PtNo_Num, FullAddress, Pt_Addr_Zip, PartialAddress) %>%
    dplyr::rename(
      Encounter = PtNo_Num,
      ZipCode = Pt_Addr_Zip
    )
  geocoded <- base::data.frame(stringsAsFactors = FALSE)

  # First Loop ----
  for (i in 1:nrow(origAddress)) {
    base::print(base::paste("Working on geocoding: ", origAddress$FullAddress[i]))
    if (
      is.null(
        suppressWarnings(
          suppressMessages(
            tmaptools::geocode_OSM(
              origAddress$FullAddress[i]
            )
          )
        )
      )
    ) {
      base::print(
        base::paste(
          "Could not get record for: ",
          origAddress$FullAddress[i],
          ". Trying next record..."
        )
      )
      origAddress$lon[i] <- ""
      origAddress$lat[i] <- ""
    } else {
      base::print(
        base::paste(
          "Getting Result For: ",
          origAddress$FullAddress[i]
        )
      )
      result <- tmaptools::geocode_OSM(
        origAddress$FullAddress[i],
        return.first.only = T,
        as.data.frame = T
      )
      origAddress$lon[i] <- base::as.numeric(result[3])
      origAddress$lat[i] <- base::as.numeric(result[2])
    }
  }

  # Get Non Found Records ----
  # Get all records that were not found and geocode on city/town, state, zip
  for (i in 1:nrow(origAddress)) {
    if (origAddress[i, "lon"] == "") {
      base::print(
        base::paste(
          "Working on geocoding:",
          origAddress$PartialAddress[i]
        )
      )
      result <- tryCatch(
        suppressWarnings(
          tmaptools::geocode_OSM(
            origAddress$PartialAddress[i],
            return.first.only = T,
            as.data.frame = T
          )
        ),
        warning = function(w) {
          base::print("Can't get record")
          tmaptools::geocode_OSM(origAddress$PartialAddress[i])
        },
        error = function(e) {
          print("geocode_OSM() function failed to produce result")
          NaN
        }
      )
      origAddress$lon[i] <- as.numeric(result[3])
      origAddress$lat[i] <- as.numeric(result[2])
    } else {
      base::print("Trying next record...")
    }
  }

  # Clean up Records ----
  geocoded <- origAddress %>%
    dplyr::filter(
      origAddress$lat != "" | origAddress$lon != ""
    ) %>%
    dplyr::select(Encounter, FullAddress, ZipCode, lon, lat)

  # Connect to DSS ----
  db_con_obj <- LICHospitalR::db_connect()

  # Insert into tbl ----
  DBI::dbWriteTable(
    conn = db_con_obj,
    DBI::Id(
      schema = "smsdss",
      table = "c_geocoded_address"
    ),
    geocoded,
    append = T
  )

  # Delete Duplicates ----
  DBI::dbGetQuery(
    conn = db_con_obj,
    statement = base::paste0(
      "
      DELETE X
      FROM (
      	SELECT Encounter
      	, FullAddress
      	, ZipCode
      	, lon
      	, lat
      	, RN = ROW_NUMBER() OVER(
      		PARTITION BY Encounter
      	, FullAddress
      	, ZipCode
      	, lon
      	, lat
      	ORDER BY Encounter
      	, FullAddress
      	, ZipCode
      	, lon
      	, lat
      	)
      	FROM SMSDSS.c_geocoded_address
      ) X
      WHERE X.RN > 1
      "
    )
  )

  # DB Disconnect ----
  LICHospitalR::db_disconnect(.connection = db_con_obj)

  # Save Missing records ----
  missing_records_tbl <- origAddress %>%
    tibble::as_tibble() %>%
    dplyr::filter(base::is.na(lat) | lat == "") %>%
    dplyr::select(Encounter, FullAddress, ZipCode, PartialAddress)

  missing_records_tbl %>%
    writexl::write_xlsx(
      path = base::paste0(file_path, "geocoded_failures.xlsx"),
      col_names = TRUE
    )

  # Return missing records
  base::return(missing_records_tbl)
}

#' CDI QEC Numbers
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description Gather Admit / Discharges counts for CDI QEC dashboard
#'
#' @details
#' - Requires a connection to DSS, uses both [db_connect()] and [db_disconnect()]
#' - Will ask you where you want to save the file so you can email it out
#' - Uses the [qec_cdi_query()] to automatically set the .data argument internally
#' - Email currently goes to PMcKenna at LICommunityHospital.org, should this change
#' please call Steven Sanderson at 2995 to update the email, and redistribute package.
#' - Outlook may ask you to Allow the message to send
#'
#' @param .delete_file Default is FALSE, TRUE will delete the file.
#' @param .email Provide the email address for the recipient. The email must be
#' in double quotes like so: \email{c("person@@licommunityhospital.org;person2@@licommunityhospital.org")}
#' using a semi-colon if there is more than one address.
#'
#' @examples
#' \dontrun{
#' library(RDCOMClient)
#' library(tidyverse)
#' qec_cdi_automation(.email = "someone@@email.com")
#' }
#'
#' @export
#'

qec_cdi_automation <- function(.delete_file = FALSE, .email) {

  # * Tidyeval ----
  email <- .email

  # * Get Data ----
  data_tbl <- LICHospitalR::qec_cdi_query()

  # * File Path ----
  file_path <- utils::choose.dir()
  file_name <- "\\QEC_CDI.xlsx"
  f_pn <- base::paste0(file_path, file_name)

  writexl::write_xlsx(x = data_tbl, path = f_pn)

  # * Compose Email ----
  # Open Outlook
  Outlook <- RDCOMClient::COMCreate("Outlook.Application")

  # Create Email
  Email <- Outlook$CreateItem(0)

  # Set fields
  Email[["to"]] <- email
  Email[["cc"]] <- ""
  Email[["bcc"]] <- ""
  Email[["subject"]] <- "CDI QEC Numbers"
  Email[["body"]] <- "Please see the attached for the latest CDI QEC numbers"
  Email[["attachments"]]$Add(f_pn)

  # Send the email
  Email$Send()

  # Delete saved file
  if (.delete_file == TRUE) {
    if (file.exists(f_pn)) {
      file.remove(f_pn)
    }
  }
}

#' Code 64 Email Automation
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' Run the [code64_charged_accounts_query()] and email them to Performance Improvement
#' and the Medical Chairperson
#'
#' The RDCOMClient Library must be called into the `namespace` first with any of the following
#' - library(RDCOMClient)
#' - require(RDCOMClient)
#' - if(!require(pacman)) {install.packages("pacman")}
#' - pacman::p_load("RDCOMClient")
#'
#' @details
#' - Requires a connection to DSS, uses both [db_connect()] and [db_disconnect()]
#' - Will ask you where you want to save the file so you can email it out, will
#' delete the file upon email send.
#' - Uses the [code64_charged_accounts_query()] internally.
#'
#' @param .delete_file Default is FALSE, TRUE will delete file.
#' @param .email Provide the email address for the recipient. The email must be
#' in double quotes like so: \email{c("person@@licommunityhospital.org;person2@@licommunityhospital.org")}
#' using a semi-colon if there is more than one address.
#'
#' @examples
#' \dontrun{
#' library(RDCOMClient)
#' code64_automation(.email = "someone@@email.com")
#' }
#'
#' @export
#'
code64_automation <- function(.delete_file = FALSE, .email) {

  # * Tidyeval ----
  email <- .email

  # * Get Data ----
  data_tbl <- LICHospitalR::code64_charged_accounts_query()

  end_date <- data_tbl %>%
    dplyr::select(actv_date) %>%
    dplyr::pull() %>%
    base::max() %>%
    base::as.Date()
  file_rundate <- base::Sys.Date() %>% stringr::str_replace_all("-", "_")

  # * File Path ----
  file_path <- utils::choose.dir()
  file_month <- end_date %>% lubridate::month()
  file_year <- end_date %>% lubridate::year()
  file_name <- base::paste0(
    "\\code_64_charged_accounts_",
    file_year,
    "_",
    file_month,
    "_rundate_",
    file_rundate,
    ".xlsx"
  )
  f_pn <- base::paste0(file_path, file_name)

  writexl::write_xlsx(x = data_tbl, path = f_pn)

  # * Compose Email ----
  # Open Outlook
  Outlook <- RDCOMClient::COMCreate("Outlook.Application")

  # Create Email
  Email <- Outlook$CreateItem(0)

  # Set fields
  Email[["to"]] <- email
  Email[["cc"]] <- ""
  Email[["bcc"]] <- ""
  Email[["subject"]] <- "Accounts Charged with a Code 64"
  Email[["body"]] <- "Please see the attached for the latest report for Accounts Charged with a Code 64"
  Email[["attachments"]]$Add(f_pn)

  # Send the email
  Email$Send()

  # Delete saved file
  if (.delete_file == TRUE) {
    if (file.exists(f_pn)) {
      file.remove(f_pn)
    }
  }
}

#' ORSOS to SPROC Case Reconcilliation Automation
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This automation uses the [orsos_to_sproc_query()] to get data that is then
#' manipulated to find the cases done by providers in the smsdss.c_ORSOS_Post_Case_Rpt_tbl
#' but not in smsmir.sproc, meaning they have not for some reason been coded by
#' HIM.
#'
#' The RDCOMClient Library must be called into the `namespace` first with any of the following
#' - library(RDCOMClient)
#' - require(RDCOMClient)
#' - if(!require(pacman)) {install.packages("pacman")}
#' - pacman::p_load("RDCOMClient")
#'
#' @details
#' - Takes data from the [orsos_to_sproc_tbl()] function, and makes an excel file to save off
#' for sending
#'
#' @param .data The data that is passed from [orsos_to_sproc_tbl()]
#' @param .delete_file Default is FALSE, TRUE will delete file
#' @param .email Provide the email address for the recipient. The email must be
#' in double quotes like so: \email{c("person@@licommunityhospital.org;person2@@licommunityhospital.org")}
#' using a semi-colon if there is more than one address.
#'
#' @examples
#' \dontrun{
#' library(RDCOMClient)
#' library(tidyverse)
#' orsos_to_sproc_query() %>%
#'   orsos_to_sproc_tbl() %>%
#'   orsos_to_sproc_automation(.email = "someone@@email.com")
#' }
#'
#' @export
#'

orsos_to_sproc_automation <- function(.data, .delete_file = FALSE, .email) {

  # * Tidyeval ----
  email <- .email

  # * Get Data ----
  data_tbl <- .data

  # * File Path ----
  file_path <- utils::choose.dir()
  file_name <- "\\orsos_to_sproc_reconcilliation.xlsx"
  f_pn <- base::paste0(file_path, file_name)

  writexl::write_xlsx(x = data_tbl, path = f_pn)

  # * Compose Email ----
  # Open Outlook
  Outlook <- RDCOMClient::COMCreate("Outlook.Application")

  # Create Email
  Email <- Outlook$CreateItem(0)

  # Set fields
  Email[["to"]] <- email
  Email[["cc"]] <- ""
  Email[["bcc"]] <- ""
  Email[["subject"]] <- "ORSOS to SPROC Reconcilliation"
  Email[["body"]] <- "
  Please see the attached for the latest report for accounts in ORSOS that cannot
  be found in our data warehouse as coded for the provider specified.
  "
  Email[["attachments"]]$Add(f_pn)

  # Send the email
  Email$Send()

  # Delete saved file
  if (.delete_file == TRUE) {
    if (file.exists(f_pn)) {
      file.remove(f_pn)
    }
  }
}

#' Congenital Malformation Automation for HIM
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This automation will send information on congenital malformations that comes
#' from the [congenital_malformation_query()] to HIM
#'
#' The RDCOMClient Library must be called into the `namespace` first with any of the following
#' - library(RDCOMClient)
#' - require(RDCOMClient)
#' - if(!require(pacman)) {install.packages("pacman")}
#' - pacman::p_load("RDCOMClient")
#'
#' @details
#' - Uses the [congenital_malformation_query()] internally.
#' - Requires a connection to DSS and uses [db_connect()] and [db_disconnect()]
#'
#' @param .delete_file Default is FALSE, TRUE will delete file
#' @param .email Provide the email address for the recipient. The email must be
#' in double quotes like so: \email{c("person@@licommunityhospital.org;person2@@licommunityhospital.org")}
#' using a semi-colon if there is more than one address.
#'
#' @examples
#' \dontrun{
#' library(RDCOMClient)
#' congenital_malformation_automation(.email= "someone@@email.com")
#' }
#'
#' @export
#'

congenital_malformation_automation <- function(.delete_file = FALSE, .email) {

  # * Tidyeval ----
  email <- .email

  # * Get Data ----
  data_tbl <- LICHospitalR::congenital_malformation_query()

  # * File Path ----
  file_path <- utils::choose.dir()
  file_name <- "\\congenital_malformation.xlsx"
  f_pn <- base::paste0(file_path, file_name)

  writexl::write_xlsx(x = data_tbl, path = f_pn)

  # * Compose Email ----
  # Open Outlook
  Outlook <- RDCOMClient::COMCreate("Outlook.Application")

  # Create Email
  Email <- Outlook$CreateItem(0)

  # Set fields
  Email[["to"]] <- email
  Email[["cc"]] <- ""
  Email[["bcc"]] <- ""
  Email[["subject"]] <- "Congenital Malformation Data"
  Email[["body"]] <- "
  Please see the attached for the latest report for accounts that meet the
  congenital malformation criteria.
  "
  Email[["attachments"]]$Add(f_pn)

  # Send the email
  Email$Send()

  # Delete saved file
  if (.delete_file == TRUE) {
    if (file.exists(f_pn)) {
      file.remove(f_pn)
    }
  }
}

#' Discharge Order to Discharge Automation
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' Uses the [discharge_order_to_discharge_query()] to get information from DSS
#' for processing.
#'
#' The RDCOMClient Library must be called into the `namespace` first with any of the following
#' - library(RDCOMClient)
#' - require(RDCOMClient)
#' - if(!require(pacman)) {install.packages("pacman")}
#' - pacman::p_load("RDCOMClient")
#'
#' @details
#' - Gets the last discharge order written for a visit and compares that with the
#' time that was input as the discharge date time
#' - Uses the [discharge_order_to_discharge_query()] internally to get the data.
#'
#' @param .delete_file Default is FALSE, TRUE will delete file
#' @param .email Provide the email address for the recipient. The email must be
#' in double quotes like so: \email{c("person@@licommunityhospital.org;person2@@licommunityhospital.org")}
#' using a semi-colon if there is more than one address.
#'
#' @examples
#' \dontrun{
#' library(RDCOMClient)
#' discharge_order_to_discharge_automation(.email = "someone@@gmail.com")
#' }
#'
#' @export
#'

discharge_order_to_discharge_automation <- function(.delete_file = FALSE, .email) {

  # * Tidyeval ----
  email <- .email

  # * Get Data ----
  data_tbl <- LICHospitalR::discharge_order_to_discharge_query()

  # * File Path ----
  file_path <- utils::choose.dir()
  file_name <- "\\discharge_order_to_discharge.xlsx"
  f_pn <- base::paste0(file_path, file_name)

  writexl::write_xlsx(x = data_tbl, path = f_pn)

  # * Compose Email ----
  # Open Outlook
  Outlook <- RDCOMClient::COMCreate("Outlook.Application")

  # Create Email
  Email <- Outlook$CreateItem(0)

  # Set fields
  Email[["to"]] <- email
  Email[["cc"]] <- ""
  Email[["bcc"]] <- ""
  Email[["subject"]] <- "Discharge Order to Discharge Time"
  Email[["body"]] <- "Please see the attached for the latest numbers"
  Email[["attachments"]]$Add(f_pn)

  # Send the email
  Email$Send()

  # Delete saved file
  if (.delete_file == TRUE) {
    if (file.exists(f_pn)) {
      file.remove(f_pn)
    }
  }
}

#' Duplicate Coded Cataracts Query
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' Uses the [duplicate_coded_cataract_query()] to get information from DSS
#' for processing.
#'
#' The RDCOMClient Library must be called into the `namespace` first with any of the following
#' - library(RDCOMClient)
#' - require(RDCOMClient)
#' - if(!require(pacman)) {install.packages("pacman")}
#' - pacman::p_load("RDCOMClient")
#'
#' @details
#' - Gets the last discharge order written for a visit and compares that with the
#' time that was input as the discharge date time
#' - Uses the [duplicate_coded_cataract_query()] internally to get data.
#'
#' @param .delete_file Default is FALSE, TRUE will delete file
#' @param .email Provide the email address for the recipient. The email must be
#' in double quotes like so: \email{c("person@@licommunityhospital.org;person2@@licommunityhospital.org")}
#' using a semi-colon if there is more than one address.
#'
#' @examples
#' \dontrun{
#' library(RDCOMClient)
#' library(tidyverse)
#' discharge_order_to_discharge_automation(.email = "someone@@email.com")
#' }
#'
#' @export
#'

duplicate_coded_cataracts_automation <- function(.delete_file = FALSE, .email) {

  # * Tidyeval ----
  email <- .email

  # * Get Data ----
  data_tbl <- LICHospitalR::duplicate_coded_cataract_query()

  # Check if data exists
  if(nrow(data_tbl) == 0){
    return(print("No data - exiting function"))
  }

  # * File Path ----
  file_path <- utils::choose.dir()
  file_name <- "\\duplicate_coded_cataracts.xlsx"
  f_pn <- base::paste0(file_path, file_name)

  writexl::write_xlsx(x = data_tbl, path = f_pn)

  # * Compose Email ----
  # Open Outlook
  Outlook <- RDCOMClient::COMCreate("Outlook.Application")

  # Create Email
  Email <- Outlook$CreateItem(0)

  # Set fields
  Email[["to"]] <- email
  Email[["cc"]] <- ""
  Email[["bcc"]] <- ""
  Email[["subject"]] <- "Duplicate Cataracts"
  Email[["body"]] <- "Please see the attached for the latest report"
  Email[["attachments"]]$Add(f_pn)

  # Send the email
  Email$Send()

  # Delete saved file
  if (.delete_file == TRUE) {
    if (file.exists(f_pn)) {
      file.remove(f_pn)
    }
  }
}

#' Inpatient Coding Lag Automation
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This takes in data from the function [inpatient_coding_lag_tbl()]
#'
#' The RDCOMClient Library must be called into the `namespace` first with any of the following
#' - library(RDCOMClient)
#' - require(RDCOMClient)
#' - if(!require(pacman)) {install.packages("pacman")}
#' - pacman::p_load("RDCOMClient")
#'
#' @details
#' - This function will ask you where you want to save the data so that it can be emailed out
#' - After the email is sent the function will delete the saved file
#'
#' @param .data The data that comes in typically from the [inpatient_coding_lag_tbl()]
#' @param .delete_file Default is FALSE, TRUE will delete file
#' @param .email Provide the email address for the recipient. The email must be
#' in double quotes like so: \email{c("person@@licommunityhospital.org;person2@@licommunityhospital.org")}
#' using a semi-colon if there is more than one address.
#'
#' @examples
#' \dontrun{
#' library(RDCOMClient)
#' library(tidyverse)
#' inpatient_coding_lag_query() %>%
#'   inpatient_coding_lag_tbl() %>%
#'   inpatient_coding_lag_automation(.email = "someone@@email.com")
#' }
#'
#' @export
#'

inpatient_coding_lag_automation <- function(.data, .delete_file = FALSE, .email) {

  # * Tidyeval ----
  email <- .email

  # * Get Data ----
  data_tbl <- .data

  # * File Path ----
  file_path <- utils::choose.dir()
  file_date <- base::Sys.Date()
  rpt_date <- lubridate::floor_date(file_date, "months") - base::months(1)
  file_year <- lubridate::year(rpt_date)
  file_month <- lubridate::month(rpt_date, abbr = FALSE, label = TRUE) %>%
    base::as.character()
  file_name <- base::paste0(
    "\\",
    file_month, file_year, "_IP_Coding_Lag.xlsx"
  )
  f_pn <- base::paste0(file_path, file_name)

  writexl::write_xlsx(x = data_tbl, path = f_pn)

  # * Compose Email ----
  # Open Outlook
  Outlook <- RDCOMClient::COMCreate("Outlook.Application")

  # Create Email
  Email <- Outlook$CreateItem(0)

  # Set fields
  Email[["to"]] <- email
  Email[["cc"]] <- ""
  Email[["bcc"]] <- ""
  Email[["subject"]] <- "IP Coding Lag Report"
  Email[["body"]] <- "Please see the attached for the latest report"
  Email[["attachments"]]$Add(f_pn)

  # Send the email
  Email$Send()

  # Delete saved file
  if (.delete_file == TRUE) {
    if (file.exists(f_pn)) {
      file.remove(f_pn)
    }
  }
}

#' Monthly PSY Admit and Discharge Automation
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This takes in the data from [monthly_psy_admits_query()] and [monthly_psy_discharges_query()]
#' puts them in a single excel workbook on different sheets and sends.
#'
#' The RDCOMClient Library must be called into the `namespace` first with any of the following
#' - library(RDCOMClient)
#' - require(RDCOMClient)
#' - if(!require(pacman)) {install.packages("pacman")}
#' - pacman::p_load("RDCOMClient")
#'
#' @details
#' Takes the output from [monthly_psy_admits_discharges_tbl()] and saves it to
#' an excel workbook using the [xlsx::saveWorkbook()] function. The file is saved
#' to a location specified by the user and upon successful function completion the
#' file is deleted.
#'
#' @param .data The output from the tbl function [monthly_psy_admits_discharges_tbl()]
#' @param .delete_file Default is FALSE, TRUE will delete file
#' @param .email Provide the email address for the recipient. The email must be
#' in double quotes like so: \email{c("person@@licommunityhospital.org;person2@@licommunityhospital.org")}
#' using a semi-colon if there is more than one address.
#'
#' @examples
#' \dontrun{
#' library(RDCOMClient)
#' library(tidyverse)
#' monthly_psy_admits_discharges_tbl() %>%
#'   monthly_psy_admits_discharges_automation(.email = "someone@@email.com")
#' }
#'
#' @export
#'

monthly_psy_admits_discharges_automation <- function(.data, .delete_file = FALSE, .email) {

  # * Tidyeval ----
  email <- .email

  # * Get Data ----
  data_wb <- .data

  # * File Path ----
  file_path <- utils::choose.dir()
  file_name <- "\\monthly_psy_admits_discharges.xlsx"
  f_pn <- base::paste0(file_path, file_name)

  # Save file
  xlsx::saveWorkbook(wb = data_wb, file = f_pn)

  # * Compose Email ----
  # Open Outlook
  Outlook <- RDCOMClient::COMCreate("Outlook.Application")

  # Create Email
  Email <- Outlook$CreateItem(0)

  # Set fields
  Email[["to"]] <- email
  Email[["cc"]] <- ""
  Email[["bcc"]] <- ""
  Email[["subject"]] <- "Monthly PSY Admits and Discharges"
  Email[["body"]] <- "Please see the attached for the latest report"
  Email[["attachments"]]$Add(f_pn)

  # Send the email
  Email$Send()

  # Delete saved file
  if (.delete_file == TRUE) {
    if (file.exists(f_pn)) {
      file.remove(f_pn)
    }
  }
}

#' Monthly Trauma Automation
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This takes in the data from [monthly_trauma_tbl()] and puts the results into
#' and excel file with the admits on one sheet and the discharges on another. The
#' file is saved to a location specified by the user and upon successful completion
#' the file is deleted.
#'
#' The RDCOMClient Library must be called into the `namespace` first with any of the following
#' - library(RDCOMClient)
#' - require(RDCOMClient)
#' - if(!require(pacman)) {install.packages("pacman")}
#' - pacman::p_load("RDCOMClient")
#'
#' @param .data The output from the tbl function [monthly_trauma_tbl()]
#' @param .delete_file Default is FALSE, TRUE will delete file
#' @param .email Provide the email address for the recipient. The email must be
#' in double quotes like so: \email{c("person@@licommunityhospital.org;person2@@licommunityhospital.org")}
#' using a semi-colon if there is more than one address.
#'
#' @examples
#' \dontrun{
#' library(RDCOMClient)
#' library(tidyverse)
#' monthly_trauma_tbl() %>%
#'   monthly_trauma_automation(.email = "someone@@email.com")
#' }
#'
#' @export
#'

monthly_trauma_automation <- function(.data, .delete_file = FALSE, .email) {

  # * Tidyeval ----
  email <- .email

  # * Get Data ----
  data_wb <- .data

  # * File Path ----
  file_path <- utils::choose.dir()
  file_name <- "\\monthly_trauma_data.xlsx"
  f_pn <- base::paste0(file_path, file_name)

  # Save file
  xlsx::saveWorkbook(wb = data_wb, file = f_pn)

  # * Compose Email ----
  # Open Outlook
  Outlook <- RDCOMClient::COMCreate("Outlook.Application")

  # Create Email
  Email <- Outlook$CreateItem(0)

  # Set fields
  Email[["to"]] <- email
  Email[["cc"]] <- ""
  Email[["bcc"]] <- ""
  Email[["subject"]] <- "Monthly Trauma Data"
  Email[["body"]] <- "Please see the attached for the latest report"
  Email[["attachments"]]$Add(f_pn)

  # Send the email
  Email$Send()

  # Delete saved file
  if (.delete_file == TRUE) {
    if (file.exists(f_pn)) {
      file.remove(f_pn)
    }
  }
}

#' MyHealth Monthly Surgery Automation
#'
#' @author Steven P. Sanderson II
#'
#' @description
#' This function will send out the results of the [myhealth_monthly_surgery_tbl()]
#'
#' The RDCOMClient Library must be called into the `namespace` first with any of the following
#' - library(RDCOMClient)
#' - require(RDCOMClient)
#' - if(!require(pacman)) {install.packages("pacman")}
#' - pacman::p_load("RDCOMClient")
#'
#' @details
#' - Takes in the results of [myhealth_monthly_surgery_tbl()] function
#' - Asks user where to save the temporary file
#' - Will delete file after sending if parameter is set to true
#'
#' @param .data The data from [myhealth_monthly_surgery_tbl()]
#' @param .delete_file FALSE is the default, so the file will be kept, TRUE will
#' delete the file after function completion
#' @param .email Provide the email address for the recipient. The email must be
#' in double quotes like so: \email{c("person@@licommunityhospital.org;person2@@licommunityhospital.org")}
#' using a semi-colon if there is more than one address.
#'
#' @examples
#' \dontrun{
#' library(RDCOMClient)
#' library(tidyverse)
#' myhealth_monthly_surgery_query() %>%
#'   myhealth_monthly_surgery_tbl() %>%
#'   myhealth_monthly_surgery_automation(.email = "someone@@email.com")
#' }
#'
#' @export
#'

myhealth_monthly_surgery_automation <- function(.data, .delete_file = FALSE, .email) {

  # * Tidyeval ----
  email <- .email

  # Checks
  if (!is.data.frame(.data)) {
    stop(call. = FALSE, "(.data) is not a data.frame. Please supply.")
  }

  # * Get Data ----
  data_tbl <- tibble::as_tibble(.data)

  # * File Path ----
  file_path <- utils::choose.dir()
  file_name <- "\\myhealth_monthly_surgery_file.xlsx"
  f_pn <- base::paste0(file_path, file_name)

  # Save file
  writexl::write_xlsx(x = data_tbl, path = f_pn)

  # * Compose Email ----
  # Open Outlook
  Outlook <- RDCOMClient::COMCreate("Outlook.Application")

  # Create Email
  Email <- Outlook$CreateItem(0)

  # Set fields
  Email[["to"]] <- email
  Email[["cc"]] <- ""
  Email[["bcc"]] <- ""
  Email[["subject"]] <- "Monthly Surgery Data"
  Email[["body"]] <- "Please see the attached for the latest report"
  Email[["attachments"]]$Add(f_pn)

  # Send the email
  Email$Send()

  # Delete saved file
  if (.delete_file == TRUE) {
    if (file.exists(f_pn)) {
      file.remove(f_pn)
    }
  }
}

#' Weekly PSY Discharges Automation
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This takes in data directly from the [weekly_psy_discharges_query()] as the
#' data argument
#'
#' @details
#' - Will automatically keep the file unless otherwise specified
#' - Sends file via email in Outlook
#'
#' @param .data The data from [myhealth_monthly_surgery_tbl()]
#' @param .delete_file FALSE is the default, so the file will be kept, TRUE will
#' delete the file after function completion
#' @param .email Provide the email address for the recipient. The email must be
#' in double quotes like so: \email{c("person@@licommunityhospital.org;person2@@licommunityhospital.org")}
#' using a semi-colon if there is more than one address.
#'
#' @examples
#' \dontrun{
#' library(RDCOMClient)
#' library(tidyverse)
#' weekly_psy_discharges_query() %>%
#'   weekly_psy_discharges_automation(.email = "someone@@email.com")
#' }
#'
#' @export
#'

weekly_psy_discharges_automation <- function(.data, .delete_file = FALSE, .email) {

  # * Tidyeval ----
  email <- .email

  # Checks
  if (!is.data.frame(.data)) {
    stop(call. = FALSE, "(.data) is not a data.frame. Please supply.")
  }

  # * Get Data ----
  data_tbl <- tibble::as_tibble(.data)

  # * File Path ----
  file_path <- utils::choose.dir()
  file_name <- "\\weekly_psy_discharges.xlsx"
  f_pn <- base::paste0(file_path, file_name)

  # Save file
  writexl::write_xlsx(x = data_tbl, path = f_pn)

  # * Compose Email ----
  # Open Outlook
  Outlook <- RDCOMClient::COMCreate("Outlook.Application")

  # Create Email
  Email <- Outlook$CreateItem(0)

  # Set fields
  Email[["to"]] <- email
  Email[["cc"]] <- ""
  Email[["bcc"]] <- ""
  Email[["subject"]] <- "Weekly PSY Discharges"
  Email[["body"]] <- "Please see the attached for the latest report"
  Email[["attachments"]]$Add(f_pn)

  # Send the email
  Email$Send()

  # Delete saved file
  if (.delete_file == TRUE) {
    if (file.exists(f_pn)) {
      file.remove(f_pn)
    }
  }
}

#' ORSOS J Accounts Automation
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This takes in data directly from the [orsos_j_accounts_query()] as the
#' data argument.
#'
#' The RDCOMClient Library must be called into the `namespace` first with any of the following
#' - library(RDCOMClient)
#' - require(RDCOMClient)
#' - if(!require(pacman)) {install.packages("pacman")}
#' - pacman::p_load("RDCOMClient")
#'
#' @details
#' - Takes in the results of [orsos_j_accounts_query()] function
#' - Asks user where to save the temporary file
#' - Will delete file after sending if parameter is set to true
#'
#' @param .data The data from [orsos_j_accounts_query()]
#' @param .delete_file FALSE is the default, so the file will be kept, TRUE will
#' delete the file after function completion
#' @param .email Provide the email address for the recipient. The email must be
#' in double quotes like so: \email{c("person@@licommunityhospital.org;person2@@licommunityhospital.org")}
#' using a semi-colon if there is more than one address.
#'
#' @examples
#' \dontrun{
#' library(RDCOMClient)
#' library(tidyverse)
#' orsos_j_accounts_query() %>%
#'   orsos_j_accounts_automation(.email = "somone@@email.com")
#' }
#'
#' @export
#'

orsos_j_accounts_automation <- function(.data, .delete_file = FALSE, .email) {

  # * Tidyeval ----
  email <- .email

  # Checks
  if (!is.data.frame(.data)) {
    stop(call. = FALSE, "(.data) is not a data.frame. Please supply.")
  }

  # * Get Data ----
  data_tbl <- tibble::as_tibble(.data)

  # * File Path ----
  file_path <- utils::choose.dir()
  file_name <- "\\orsos_j_accounts.xlsx"
  f_pn <- base::paste0(file_path, file_name)

  # Save file
  writexl::write_xlsx(x = data_tbl, path = f_pn)

  # * Compose Email ----
  # Open Outlook
  Outlook <- RDCOMClient::COMCreate("Outlook.Application")

  # Create Email
  Email <- Outlook$CreateItem(0)

  # Set fields
  Email[["to"]] <- email
  Email[["cc"]] <- ""
  Email[["bcc"]] <- ""
  Email[["subject"]] <- "ORSOS J Accounts"
  Email[["body"]] <- "Please see the attached for the latest report"
  Email[["attachments"]]$Add(f_pn)

  # Send the email
  Email$Send()

  # Delete saved file
  if (.delete_file == TRUE) {
    if (file.exists(f_pn)) {
      file.remove(f_pn)
    }
  }
}

#' Patient Days for Infection Prevention Automation
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This takes in the data from [infection_prevention_patient_days_query()] and [infection_prevention_patient_days_tbl()]
#' puts them in a single excel workbook on different sheets and sends.
#'
#' The RDCOMClient Library must be called into the `namespace` first with any of the following
#' - library(RDCOMClient)
#' - require(RDCOMClient)
#' - if(!require(pacman)) {install.packages("pacman")}
#' - pacman::p_load("RDCOMClient")
#'
#' @details
#' Takes the output from [infection_prevention_patient_days_tbl()] and saves it to
#' an excel workbook using the [xlsx::saveWorkbook()] function. The file is saved
#' to a location specified by the user and upon successful function completion the
#' file is deleted.
#'
#' @param .data The output from the tbl function [infection_prevention_patient_days_tbl()]
#' @param .delete_file Default is FALSE, TRUE will delete file
#' @param .email Provide the email address for the recipient. The email must be
#' in double quotes like so: \\email{c("person@@licommunityhospital.org;person2@@licommunityhospital.org")}
#' using a semi-colon if there is more than one address.
#'
#' @examples
#' \dontrun{
#' library(RDCOMClient)
#' library(tidyverse)
#' infection_prevention_patient_days_query() %>%
#'   infection_prevention_patient_days_tbl() %>%
#'   infection_prevention_patient_days_automation(.email = "someone@@email.com")
#' }
#'
#' @export
#'

infection_prevention_patient_days_automation <- function(.data, .delete_file = FALSE, .email) {

  # * Tidyeval ----
  email <- .email

  # * Get Data ----
  data_wb <- .data

  # * File Path ----
  file_path <- utils::choose.dir()
  file_name <- "\\infection_prevention_patient_days.xlsx"
  f_pn <- base::paste0(file_path, file_name)

  # Save file
  xlsx::saveWorkbook(wb = data_wb, file = f_pn)

  # * Compose Email ----
  # Open Outlook
  Outlook <- RDCOMClient::COMCreate("Outlook.Application")

  # Create Email
  Email <- Outlook$CreateItem(0)

  # Set fields
  Email[["to"]] <- email
  Email[["cc"]] <- ""
  Email[["bcc"]] <- ""
  Email[["subject"]] <- "Infection Prevention Patient Days"
  Email[["body"]] <- "Please see the attached for the latest report"
  Email[["attachments"]]$Add(f_pn)

  # Send the email
  Email$Send()

  # Delete saved file
  if (.delete_file == TRUE) {
    if (file.exists(f_pn)) {
      file.remove(f_pn)
    }
  }
}

#' Respiratory VAE Automation
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description This will email out the Respiratory VAE file to the email specified
#' in the function. It is expected that the `.data` parameter be filled in with the
#' results of the [respiratory_vae_tbl()] function.
#'
#' The RDCOMClient Library must be called into the `namespace` first with any of the following
#' - library(RDCOMClient)
#' - require(RDCOMClient)
#' - if(!require(pacman)) {install.packages("pacman")}
#' - pacman::p_load("RDCOMClient")
#'
#' @details
#' Takes the output from [respiratory_vae_tbl()] and saves it to
#' an excel workbook using the [writexl::write_xlsx()] function. The file is saved
#' to a location specified by the user and upon successful function completion the
#' file is deleted.
#'
#' @param .data The output from the tbl function [respiratory_vae_tbl()]
#' @param .delete_file Default is FALSE, TRUE will delete file
#' @param .email Provide the email address for the recipient. The email must be
#' in double quotes like so: \email{c("person@@licommunityhospital.org;person2@@licommunityhospital.org")}
#' using a semi-colon if there is more than one address.
#'
#' @examples
#' \dontrun{
#' library(RDCOMClient)
#' respiratory_vae_query() %>%
#'   respiratory_vae_tbl() %>%
#'   respiratory_vae_automation()
#' }
#'
#' @export
#'

respiratory_vae_automation <- function(.data, .delete_file = FALSE, .email) {

  # * Tidyeval ----
  email <- .email

  # Checks
  if (!is.data.frame(.data)) {
    stop(call. = FALSE, "(.data) is not a data.frame. Please supply.")
  }

  # * Get Data ----
  data_tbl <- tibble::as_tibble(.data)

  # * File Path ----
  file_path <- utils::choose.dir()
  file_name <- "\\respiratory_vae.xlsx"
  f_pn <- base::paste0(file_path, file_name)

  # Save file
  writexl::write_xlsx(x = data_tbl, path = f_pn)

  # * Compose Email ----
  # Open Outlook
  Outlook <- RDCOMClient::COMCreate("Outlook.Application")

  # Create Email
  Email <- Outlook$CreateItem(0)

  # Set fields
  Email[["to"]] <- email
  Email[["cc"]] <- ""
  Email[["bcc"]] <- ""
  Email[["subject"]] <- "Respiratory VAE File"
  Email[["body"]] <- "Please see the attached for the latest report"
  Email[["attachments"]]$Add(f_pn)

  # Send the email
  Email$Send()

  # Delete saved file
  if (.delete_file == TRUE) {
    if (file.exists(f_pn)) {
      file.remove(f_pn)
    }
  }
}

#' Readmit Psyh To Psyc Automation
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This takes in the data from [readmit_psy_to_psy_query()] and [readmit_psy_to_psy_tbl()]
#' puts it into an excel file using save_to_excel.
#'
#' The RDCOMClient Library must be called into the `namespace` first with any of the following
#' - library(RDCOMClient)
#' - require(RDCOMClient)
#' - if(!require(pacman)) {install.packages("pacman")}
#' - pacman::p_load("RDCOMClient")
#'
#' @details
#' Takes the output from [readmit_psy_to_psy_tbl()] and saves it to
#' an excel workbook using the [writexl::write_xlsx] function. The file is saved
#' to a location specified by the user and upon successful function completion the
#' file is deleted.
#'
#' @param .data The output from the tbl function [readmit_psy_to_psy_tbl()]
#' @param .delete_file Default is FALSE, TRUE will delete file
#' @param .email Provide the email address for the recipient. The email must be
#' in double quotes like so: \\email{c("person@@licommunityhospital.org;person2@@licommunityhospital.org")}
#' using a semi-colon if there is more than one address.
#'
#' @examples
#' \dontrun{
#' library(RDCOMClient)
#' library(magritter)
#' readmit_psy_to_psy_query() %>%
#'   readmit_psy_to_psy_tbl() %>%
#'   readmit_psy_to_psy_automation(.email = "someone@@email.com")
#' }
#'
#' @export
#'

readmit_psy_to_psy_automation <- function(.data, .delete_file = FALSE, .email){

  # * Tidyeval ----
  email <- .email

  # * Get Data ----
  data_wb <- .data

  # * File Path ----
  file_path <- utils::choose.dir()
  file_name <- "\\psy_to_psy_readmits.xlsx"
  f_pn <- base::paste0(file_path, file_name)

  # Save file
  writexl::write_xlsx(x = data_tbl, path = f_pn)

  # * Compose Email ----
  # Open Outlook
  Outlook <- RDCOMClient::COMCreate("Outlook.Application")

  # Create Email
  Email <- Outlook$CreateItem(0)

  # Set fields
  Email[["to"]] <- email
  Email[["cc"]] <- ""
  Email[["bcc"]] <- ""
  Email[["subject"]] <- "Psych to Psych Readmits"
  Email[["body"]] <- "Please see the attached for the latest report"
  Email[["attachments"]]$Add(f_pn)

  # Send the email
  Email$Send()

  # Delete saved file
  if (.delete_file == TRUE) {
    if (file.exists(f_pn)) {
      file.remove(f_pn)
    }
  }
}
