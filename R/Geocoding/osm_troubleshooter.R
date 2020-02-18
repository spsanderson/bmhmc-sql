library(XML)
server = "http://nominatim.openstreetmap.org"
q = "78 MOWBRAY ST, PATCHOGUE, NY, 11772"
n = length(q)
q2 = gsub(" ", "+", enc2utf8(q), fixed = T)
addr <- paste0(
  server, "/search?q=", q2, "&format=xml&polygon=0&addressdetails=0"
)

output2 <- lapply(1:n, function(k) {
  tmpfile <- tempfile()
  suppressWarnings(
    download.file(
      addr
      , destfile = tmpfile
      , method = "wininet"
      , mode= "wb"
      , quiet = TRUE
    )
  )
  doc <- xmlTreeParse(tmpfile, encoding="UTF-8")
  unlink(tmpfile)
  res <- xmlChildren(xmlRoot(doc))
  
  if (length(res) == 0) {
    warning(paste("No Results found for \"", q[k], "\".", sep = ""))
    return(NULL)
  }
})

