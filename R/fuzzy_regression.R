library(tidyverse)

fuzzy_regression <- function(.x, .y, .z, .proportion = 0.8, .max_splines = 5000,
                             .r = 2, .smoother = 1.5, .thresh1 = 25.0,
                             .thresh2 = 1.5, .thresh3 = 0.001){
  
  # Tidyeval ----
  x <- as.numeric(.x)
  y <- as.numeric(.y)
  z <- as.numeric(.z)
  P <- as.numeric(.proportion)
  M <- as.numeric(.max_splines)
  r <- as.numeric(.r)
  smoother <- as.numeric(.smoother)
  thresh1 <- as.numeric(.thresh1)
  thresh2 <- as.numeric(.thresh2)
  
  # Other vars
  zmin <- min(z)
  zmax <- max(z)
  zavg <- mean(z, na.rm = TRUE)
  zdev <- sd(z, na.rm = TRUE)
  n <- length(x)
  
  zz <- 0
  distmin <- 1
  error <- 0
  idx <- tibble(
    i = 0:r,
    idx = replicate(3, as.integer(n * P * rnorm(1)))
  )
  
  
  tibble(
    zmin = zmin,
    zmax = zmax,
    zavg = zavg,
    zdev = zdev,
    n = n
  )
  
  prod <- 1.0
  for(i in 0:r){
    for(j in i+1:r){
      prod = 
    }
  }
  
}

x <- rnorm(1000)
y <- rnorm(1000, 1)
z <- rnorm(1000, 2)

fuzzy_regression(x, y, z)
