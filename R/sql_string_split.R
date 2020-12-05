#' Use SQL LEFT type function in R
#'
#' @author Steven P Sanderson II, MPH
#'
#' @description
#' Perform a SQL LEFT() on a piece of data
#'
#' @param text A piece of text or data you want to take a left part of
#' @param num_char How many characters of the text you want to take
#'
#' @details
#' - Returns a substring of text from the left side
#'
#' @return
#' A left sided substring of data
#'
#' @examples
#' sql_left("This is some text", 4)
#'
#' @export
#'

sql_left <- function(text, num_char) {
  base::substr(text, 1, num_char)
}

#' Use SQL SUBSTRING() or Excel MID() type function in R
#'
#' @author Steven P Sanderson II, MPH
#'
#' @description
#' Perform a SQL SUBSTRING() or Excel MID() type function on a piece of data
#'
#' @param text A piece of text or data you want to take a substring/mid of
#' @param start_num Where you want to start your manipulation
#' @param num_char How many characters o fthe text you want to take
#'
#' @details
#' - Returns a substring of text from the substring/mid point chosen
#'
#' @return
#' A substring/mid section of text
#'
#' @examples
#' sql_mid("this is some text", 6, 2)
#'
#' @export
#'

sql_mid <- function(text, start_num, num_char) {
  base::substr(text, start_num, start_num + num_char - 1)
}

#' Use SQL RIGHT type function in R
#'
#' @author Steven P Sanderson II, MPH
#'
#' @description
#' Perform a SQL RIGHT() on a piece of data
#'
#' @param text A piece of text or data you want to take a right part of
#' @param num_char How many characters of the text you want to take
#'
#' @details
#' - Returns a substring of text from the right side
#'
#' @return
#' A right sided substring of data
#'
#' @examples
#' sql_right("This is some text", 4)
#'
#' @export
#'

sql_right <- function(text, num_char) {
  base::substr(text, base::nchar(text) - (num_char-1), base::nchar(text))
}
