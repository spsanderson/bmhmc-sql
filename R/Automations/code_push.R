# Lib Load ----
if(!require(pacman)) install.packages("pacman")
pacman::p_load(
    "zip"
    , "RDCOMClient"
    , "fs"
    , "dplyr"
)

# Zip Files ----
zipr(
    zipfile = "C:\\Users\\bha485\\Desktop\\Code.zip"
    , files = c(
        "S:\\Global Finance\\1 REVENUE CYCLE\\Steve Sanderson II\\Code\\R"
        ,"S:\\Global Finance\\1 REVENUE CYCLE\\Steve Sanderson II\\Code\\SQL"
        ,"S:\\Global Finance\\1 REVENUE CYCLE\\Steve Sanderson II\\Code\\VB"
        ,"C:\\Users\\bha485\\Documents\\PowerShell_Scripts"
        ,"C:\\Users\\bha485\\Desktop\\LICHospitalR\\R"
        ,dir_ls(path = "G://R Studio Projects//") %>% 
          list.files(pattern = ".R$", recursive = TRUE, full.names = TRUE)
        )
    , include_directories = TRUE
    )

# Compose Email ----
# Open Outlook
Outlook <- COMCreate("Outlook.Application")

# Create Email
Email = Outlook$CreateItem(0)

# Set the recipeitn, subject, and body
Email[["to"]] = "spsanderson@manchucorp.com"
Email[["cc"]] = ""
Email[["bcc"]] = ""
Email[["subject"]] = "Code"
Email[["body"]] = "git push attached"
Email[["attachments"]]$Add("C:\\Users\\bha485\\Desktop\\Code.zip")

# Send the email
Email$Send()

# Close Outlook, clear the message
rm(list = ls())
