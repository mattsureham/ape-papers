library(readxl)
library(data.table)

# Each XLSX has an "Outcomes_open_data_YYYY-YY" sheet with the actual data
files <- list(
  list(f = "../data/outcomes_open_mar2015.xlsx", sheet = "Outcomes_open_data_2014-15"),
  list(f = "../data/outcomes_open_mar2016.xlsx", sheet = "Outcomes_open_data_2015-16"),
  list(f = "../data/outcomes_open_mar2017.xlsx", sheet = "Outcomes_open_data_2016-17"),
  list(f = "../data/outcomes_open_mar2018.xlsx", sheet = "Outcomes_open_data_2017-18"),
  list(f = "../data/outcomes_open_aprjun2018.xlsx", sheet = "Outcomes_open_data_2019_20")
)

for (item in files) {
  cat(sprintf("\n=== %s, sheet: %s ===\n", basename(item$f), item$sheet))
  tryCatch({
    dt <- read_excel(item$f, sheet = item$sheet, n_max = 10)
    cat(sprintf("  Cols (%d): %s\n", ncol(dt), paste(names(dt), collapse = " | ")))
    print(head(dt, 5))
  }, error = function(e) cat(sprintf("  Error: %s\n", e$message)))
}

# Also check the full row count for each
for (item in files) {
  cat(sprintf("\n%s rows: ", basename(item$f)))
  tryCatch({
    dt <- read_excel(item$f, sheet = item$sheet)
    cat(sprintf("%d\n", nrow(dt)))
  }, error = function(e) cat(sprintf("Error: %s\n", e$message)))
}
