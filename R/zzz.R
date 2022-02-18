# On librazry attachment, print message to user.
.onAttach <- function(libname, pkgname){

  msg <- paste0(
    "Welcome to LICHospitalR---------------------------------------------------",
    "\n",
    "\nIf you encounter a bug or want to request an enhancement, please send either",
    "\na help desk ticket for Steven Sanderson, or an email to:",
    "\n    ssanderson@licommunityhospital.org",
    "\n",
    "\nThank you for using LICHospitalR",
    "\n"
  )

  packageStartupMessage(msg)

}
