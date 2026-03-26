## 01b_fetch_bds.R — Fetch Census BDS state-level business dynamics data
## apep_1016: Fresh Start Dividend
##
## Run AFTER 01_fetch_data.R if BFS failed, OR run standalone.

library(httr)
library(jsonlite)
library(tidyverse)
library(data.table)

DATA_DIR <- file.path(dirname(getwd()), "data")
dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)

census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) == 0) {
  # Try loading from .env
  env_file <- file.path(dirname(dirname(dirname(getwd()))), ".env")
  if (file.exists(env_file)) {
    lines <- readLines(env_file)
    key_line <- grep("^CENSUS_API_KEY=", lines, value = TRUE)
    if (length(key_line) > 0) {
      census_key <- sub("^CENSUS_API_KEY=", "", key_line[1])
    }
  }
}
key_param <- ifelse(nchar(census_key) > 0, paste0("&key=", census_key), "")

# States covered by our courts
state_fips <- c("12", "17", "26", "48", "13", "47", "24", "34", "39", "51")
years <- 2010:2021

cat("=== Fetching Census BDS state-level data ===\n")
cat(sprintf("States: %s\n", paste(state_fips, collapse = ", ")))
cat(sprintf("Years: %d-%d\n", min(years), max(years)))

bds_list <- list()

for (yr in years) {
  for (st in state_fips) {
    url <- sprintf(
      "https://api.census.gov/data/timeseries/bds?get=FIRM,ESTAB,ESTABS_ENTRY,ESTABS_ENTRY_RATE,ESTABS_EXIT,ESTABS_EXIT_RATE,EMP,JOB_CREATION,JOB_CREATION_RATE&for=state:%s&YEAR=%d%s",
      st, yr, key_param
    )

    resp <- tryCatch(GET(url, timeout(15)), error = function(e) NULL)

    if (!is.null(resp) && status_code(resp) == 200) {
      parsed <- content(resp, as = "text", encoding = "UTF-8")
      df <- tryCatch(fromJSON(parsed), error = function(e) NULL)
      if (!is.null(df) && nrow(df) > 1) {
        header <- df[1, ]
        vals <- df[-1, , drop = FALSE]
        colnames(vals) <- header
        bds_list[[length(bds_list) + 1]] <- as.data.frame(vals)
      }
    } else {
      cat(sprintf("  Warning: BDS failed for state %s year %d\n", st, yr))
    }

    Sys.sleep(0.15)
  }
}

stopifnot("No BDS data fetched" = length(bds_list) > 0)

bds_df <- bind_rows(bds_list)
bds_df <- bds_df %>%
  mutate(
    state_fips = state,
    year = as.integer(YEAR),
    firms = as.numeric(FIRM),
    estabs = as.numeric(ESTAB),
    estabs_entry = as.numeric(ESTABS_ENTRY),
    estabs_entry_rate = as.numeric(ESTABS_ENTRY_RATE),
    estabs_exit = as.numeric(ESTABS_EXIT),
    estabs_exit_rate = as.numeric(ESTABS_EXIT_RATE),
    emp = as.numeric(EMP),
    job_creation = as.numeric(JOB_CREATION),
    job_creation_rate = as.numeric(JOB_CREATION_RATE)
  ) %>%
  select(state_fips, year, firms, estabs, estabs_entry, estabs_entry_rate,
         estabs_exit, estabs_exit_rate, emp, job_creation, job_creation_rate)

fwrite(bds_df, file.path(DATA_DIR, "census_bds_state_annual.csv"))
cat(sprintf("\nSaved census_bds_state_annual.csv (%d rows)\n", nrow(bds_df)))

# Also try BFS national-level data as supplementary
cat("\nFetching BFS national-level data...\n")

bfs_nat <- list()
for (yr in 2004:2022) {
  for (mn in 1:12) {
    time_str <- sprintf("%d-%02d", yr, mn)
    url <- sprintf(
      "https://api.census.gov/data/timeseries/eits/bfs?get=cell_value,data_type_code,category_code&for=us:*&time=%s&seasonally_adj=no%s",
      time_str, key_param
    )
    resp <- tryCatch(GET(url, timeout(10)), error = function(e) NULL)
    if (!is.null(resp) && status_code(resp) == 200) {
      parsed <- content(resp, as = "text", encoding = "UTF-8")
      df <- tryCatch(fromJSON(parsed), error = function(e) NULL)
      if (!is.null(df) && nrow(df) > 1) {
        header <- df[1, ]
        vals <- df[-1, , drop = FALSE]
        colnames(vals) <- header
        bfs_nat[[length(bfs_nat) + 1]] <- as.data.frame(vals)
      }
    }
    Sys.sleep(0.05)
  }
}

if (length(bfs_nat) > 0) {
  bfs_national <- bind_rows(bfs_nat) %>%
    filter(data_type_code %in% c("BA_BA", "BA_HBA", "BA_WBA"),
           category_code == "TOTAL") %>%
    mutate(
      value = as.numeric(cell_value),
      year = as.integer(substr(time, 1, 4)),
      month = as.integer(substr(time, 6, 7))
    ) %>%
    select(year, month, data_type_code, value) %>%
    pivot_wider(names_from = data_type_code, values_from = value)

  fwrite(bfs_national, file.path(DATA_DIR, "census_bfs_national_monthly.csv"))
  cat(sprintf("Saved census_bfs_national_monthly.csv (%d rows)\n", nrow(bfs_national)))
}

cat("\n=== BDS/BFS fetch complete ===\n")
