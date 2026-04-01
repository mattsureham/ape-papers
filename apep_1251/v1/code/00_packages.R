# Package loader for apep_1251.

required_packages <- c(
  "data.table",
  "fixest",
  "jsonlite",
  "readxl",
  "lubridate",
  "glue"
)

missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0) {
  install.packages(missing_packages, repos = "https://cloud.r-project.org")
}

invisible(lapply(required_packages, library, character.only = TRUE))

setFixest_nthreads(max(1L, parallel::detectCores(logical = FALSE) - 1L))
options(stringsAsFactors = FALSE, scipen = 999)
