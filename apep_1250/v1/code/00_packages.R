suppressPackageStartupMessages({
  library(dplyr)
  library(fixest)
  library(glue)
  library(jsonlite)
  library(purrr)
  library(readr)
  library(readxl)
  library(stringr)
  library(tibble)
  library(tidyr)
})

setFixest_notes(FALSE)

ensure_dir <- function(path) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
}

fmt_int <- function(x) {
  format(round(x), big.mark = ",", scientific = FALSE, trim = TRUE)
}

fmt_num <- function(x, digits = 3) {
  ifelse(is.na(x), "", formatC(x, digits = digits, format = "f"))
}

fmt_pct <- function(x, digits = 1) {
  ifelse(is.na(x), "", paste0(formatC(100 * x, digits = digits, format = "f"), "\\%"))
}

fmt_p <- function(x) {
  ifelse(is.na(x), "", ifelse(x < 0.001, "<0.001", formatC(x, digits = 3, format = "f")))
}

latex_escape <- function(x) {
  x |>
    str_replace_all("\\\\", "\\\\textbackslash{}") |>
    str_replace_all("([%&_#])", "\\\\\\1")
}

add_stars <- function(p) {
  case_when(
    is.na(p) ~ "",
    p < 0.01 ~ "\\sym{***}",
    p < 0.05 ~ "\\sym{**}",
    p < 0.10 ~ "\\sym{*}",
    TRUE ~ ""
  )
}

write_text <- function(path, lines) {
  writeLines(lines, con = path, useBytes = TRUE)
}
