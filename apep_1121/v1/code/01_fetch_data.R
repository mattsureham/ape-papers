## 01_fetch_data.R — Fetch and parse EFV cantonal finance data
## Paper: apep_1121 — Swiss cantonal debt brakes and spending composition

source("00_packages.R")

if (!requireNamespace("readxl", quietly = TRUE)) {
  install.packages("readxl", repos = "https://cloud.r-project.org")
}
library(readxl)

cat("=== Fetching EFV cantonal public finance data ===\n")

# ---------------------------------------------------------------
# 1. DEBT BRAKE ADOPTION TIMING
# Sources: Feld & Kirchgässner (2008), Luechinger & Schaltegger (2013),
#          Burret & Feld (2018), Yerly (2013), Krogstrup & Wälti (2008)
# ---------------------------------------------------------------

debt_brake_timing <- tribble(
  ~canton_abbr, ~canton_name, ~adoption_year, ~rule_type,
  "sg", "St. Gallen",          1929, "hard",
  "fr", "Fribourg",            1960, "hard",
  "so", "Solothurn",           1994, "hard",
  "gr", "Graubünden",          1998, "hard",
  "lu", "Lucerne",             2001, "hard",
  "nw", "Nidwalden",           2001, "hard",
  "zh", "Zurich",              2001, "hard",
  "be", "Bern",                2002, "hard",
  "vs", "Valais",              2002, "hard",
  "ow", "Obwalden",            2003, "hard",
  "sh", "Schaffhausen",        2003, "hard",
  "tg", "Thurgau",             2003, "hard",
  "ar", "Appenzell A.Rh.",     2004, "soft",
  "zg", "Zug",                 2004, "hard",
  "ag", "Aargau",              2005, "hard",
  "bl", "Basel-Landschaft",    2005, "hard",
  "ai", "Appenzell I.Rh.",     2006, "soft",
  "gl", "Glarus",              2006, "hard",
  "sz", "Schwyz",              2006, "hard",
  "ur", "Uri",                 2007, "hard",
  "ne", "Neuchâtel",           2009, "hard",
  "ti", "Ticino",              2014, "hard",
  # Never-treated
  "bs", "Basel-Stadt",         Inf,  "none",
  "ge", "Genève",              Inf,  "none",
  "ju", "Jura",                Inf,  "none",
  "vd", "Vaud",                Inf,  "none"
)

cat("Debt brake timing compiled for", nrow(debt_brake_timing), "cantons.\n")
cat("Treated:", sum(is.finite(debt_brake_timing$adoption_year)), "cantons\n")
cat("Never-treated:", sum(!is.finite(debt_brake_timing$adoption_year)), "cantons\n")

# ---------------------------------------------------------------
# 2. DOWNLOAD INDIVIDUAL CANTON FILES FROM EFV
# ---------------------------------------------------------------

cat("\n=== Downloading individual canton files from EFV ===\n")

canton_codes <- debt_brake_timing$canton_abbr

for (cc in canton_codes) {
  dest <- sprintf("../data/ktn_%s.xlsx", cc)
  if (file.exists(dest) && file.size(dest) > 10000) {
    cat(sprintf("  %s: already downloaded (%d bytes)\n", cc, file.size(dest)))
    next
  }
  url <- sprintf("https://www.data.finance.admin.ch/static/assets/datasets/fs_dashboard/ktn_%s-e.xlsx", cc)
  tryCatch({
    download.file(url, dest, mode = "wb", quiet = TRUE)
    cat(sprintf("  %s: downloaded (%d bytes)\n", cc, file.size(dest)))
  }, error = function(e) {
    stop(sprintf("FATAL: Cannot download canton file for %s: %s", cc, e$message))
  })
  Sys.sleep(0.5)
}

# ---------------------------------------------------------------
# 3. PARSE EXPENDITURE BY FUNCTION FROM EACH CANTON
# ---------------------------------------------------------------

cat("\n=== Parsing expenditure by function (ausgaben_funk) ===\n")

parse_canton_expenditure <- function(file_path, canton_abbr) {
  df <- read_excel(file_path, sheet = "ausgaben_funk", col_names = FALSE, .name_repair = "minimal")

  # Row 6: column headers — first is "CHF 1 000", rest are years
  header_row <- as.character(df[6, ])
  years <- header_row[3:ncol(df)]  # Skip cols 1-2 (code, label)
  years <- as.integer(years[!is.na(years)])

  # Rows 7+: functional expenditure data
  # Col 1: function code, Col 2: function name, Cols 3+: values by year
  func_data <- df[7:nrow(df), ]

  # Extract function codes and names
  func_codes <- as.character(func_data[[1]])
  func_names <- as.character(func_data[[2]])

  # Only keep main function categories (1-digit codes: 0-9)
  # These are: 0=Admin, 1=Security, 2=Education, 3=Culture, 4=Health,
  #            5=Social, 6=Transport, 7=Environment, 8=Economy, 9=Finance
  main_funcs <- which(!is.na(func_codes) & nchar(func_codes) == 1)

  results <- list()
  for (idx in main_funcs) {
    code <- func_codes[idx]
    name <- func_names[idx]
    values <- as.numeric(as.character(func_data[idx, 3:(2 + length(years))]))

    results[[length(results) + 1]] <- tibble(
      canton = canton_abbr,
      year = years,
      func_code = code,
      func_name = name,
      expenditure = values
    )
  }

  # Also get total expenditure (row 7, which is the "Total expenditure" row)
  total_values <- as.numeric(as.character(df[7, 3:(2 + length(years))]))
  results[[length(results) + 1]] <- tibble(
    canton = canton_abbr,
    year = years,
    func_code = "total",
    func_name = "Total expenditure",
    expenditure = total_values
  )

  bind_rows(results)
}

# Parse all cantons
all_canton_data <- list()

for (cc in canton_codes) {
  file_path <- sprintf("../data/ktn_%s.xlsx", cc)
  if (!file.exists(file_path) || file.size(file_path) < 10000) {
    stop(sprintf("FATAL: Canton file missing or too small: %s", file_path))
  }
  cat(sprintf("  Parsing %s...\n", cc))
  canton_df <- tryCatch({
    parse_canton_expenditure(file_path, cc)
  }, error = function(e) {
    stop(sprintf("FATAL: Cannot parse %s: %s", cc, e$message))
  })
  all_canton_data[[cc]] <- canton_df
}

expenditure_panel <- bind_rows(all_canton_data)

cat("\nPanel constructed:\n")
cat("  Rows:", nrow(expenditure_panel), "\n")
cat("  Cantons:", n_distinct(expenditure_panel$canton), "\n")
cat("  Years:", min(expenditure_panel$year, na.rm=TRUE), "-", max(expenditure_panel$year, na.rm=TRUE), "\n")
cat("  Functions:", n_distinct(expenditure_panel$func_code), "\n")
cat("  Unique functions:", paste(unique(expenditure_panel$func_name[expenditure_panel$func_code != "total"]),
                                  collapse = "\n    "), "\n")

# ---------------------------------------------------------------
# 4. ALSO PARSE NET DEBT DATA
# ---------------------------------------------------------------

cat("\n=== Parsing net debt data ===\n")

debt_file <- "../data/ktn_nettoschuld.xlsx"
if (file.exists(debt_file)) {
  debt_df <- read_excel(debt_file, sheet = 1, col_names = FALSE, .name_repair = "minimal")
  cat("Net debt file dims:", nrow(debt_df), "x", ncol(debt_df), "\n")
  # Print structure for debugging
  for (i in 1:min(10, nrow(debt_df))) {
    vals <- as.character(debt_df[i, 1:min(6, ncol(debt_df))])
    cat(sprintf("  Row %2d: %s\n", i, paste(vals, collapse=" | ")))
  }
}

# ---------------------------------------------------------------
# 5. SAVE PROCESSED DATA
# ---------------------------------------------------------------

write_csv(debt_brake_timing, "../data/debt_brake_timing.csv")
write_csv(expenditure_panel, "../data/cantonal_expenditure_panel.csv")

cat("\n=== Data saved ===\n")
cat("  debt_brake_timing.csv:", nrow(debt_brake_timing), "rows\n")
cat("  cantonal_expenditure_panel.csv:", nrow(expenditure_panel), "rows\n")

# Summary stats
cat("\n=== Summary statistics ===\n")
expenditure_panel %>%
  filter(func_code != "total") %>%
  group_by(func_name) %>%
  summarise(
    n_obs = sum(!is.na(expenditure)),
    mean_exp = mean(expenditure, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(mean_exp)) %>%
  print(n = 15)
