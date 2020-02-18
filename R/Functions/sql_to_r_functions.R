left <- function(text, num_char) {
    substr(text, 1, num_char)
}

mid <- function(text, start_num, num_char) {
    substr(text, start_num, start_num + num_char - 1)
}

right <- function(text, num_char) {
    substr(text, nchar(text) - (num_char-1), nchar(text))
}