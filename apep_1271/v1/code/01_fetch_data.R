# 01_fetch_data.R — Fetch QWI data from Azure Blob Storage
# Paper: Mandated to Stay (apep_1271)

source("00_packages.R")

# ---- Azure connection via DuckDB ----
# Read connection string directly from .env (shell truncates at semicolons)
env_lines <- readLines("../../../../.env", warn = FALSE)
cs_line <- grep("^AZURE_STORAGE_CONNECTION_STRING=", env_lines, value = TRUE)
conn_str <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", cs_line)
conn_str <- gsub('^["\']|["\']$', "", conn_str)

stopifnot("Azure connection string not found in .env" = nchar(conn_str) > 50)

con <- dbConnect(duckdb())
dbExecute(con, "INSTALL azure; LOAD azure;")
dbExecute(con, paste0("CREATE SECRET apep (TYPE azure, CONNECTION_STRING '", conn_str, "');"))
cat("Connected to Azure via DuckDB.\n")

# ---- Define treated and control states ----
treated_states <- data.table(
  state_fips = c(9L, 6L, 25L, 41L, 50L, 4L, 53L, 24L, 34L),
  state_abbr = c("CT", "CA", "MA", "OR", "VT", "AZ", "WA", "MD", "NJ"),
  state_abbr_lower = c("ct", "ca", "ma", "or", "vt", "az", "wa", "md", "nj"),
  effective_date = as.Date(c(
    "2012-01-01", "2015-07-01", "2015-07-01", "2016-01-01",
    "2017-01-01", "2017-07-01", "2018-01-01", "2018-02-11", "2019-10-29"
  ))
)
treated_states[, treatment_year := year(effective_date)]
treated_states[, treatment_qtr := quarter(effective_date)]
treated_states[, treatment_quarter := treatment_year * 4L + treatment_qtr - 1L]

cat("Treated states:\n")
print(treated_states[, .(state_abbr, effective_date, treatment_year, treatment_qtr)])

# Control states: no statewide mandate through 2022
# Using large diverse set for robust comparison
control_abbr <- c("al", "ak", "ar", "co", "de", "fl", "ga", "hi", "id", "il",
                  "in", "ia", "ks", "ky", "la", "me", "mi", "mn", "ms", "mo",
                  "mt", "ne", "nv", "nh", "nm", "ny", "nc", "nd", "oh", "ok",
                  "pa", "ri", "sc", "sd", "tn", "tx", "ut", "va", "wv", "wi", "wy")

all_abbr <- c(treated_states$state_abbr_lower, control_abbr)
cat(sprintf("Total states: %d (treated: %d, control: %d)\n",
            length(all_abbr), nrow(treated_states), length(control_abbr)))

# ---- Fetch QWI food service (NAICS 722) from 3-digit files ----
cat("Fetching QWI food service data from Azure...\n")

file_list_n3 <- paste0("'az://derived/qwi/sa/n3/", all_abbr, ".parquet'")

query_food <- paste0(
  "SELECT geography, year, quarter, industry, sex, agegrp,\n",
  "       Emp, EmpS, HirA, HirN, HirR, Sep, TurnOvrS, EarnHirNS, EarnS\n",
  "FROM read_parquet([", paste(file_list_n3, collapse = ", "), "])\n",
  "WHERE industry = 722\n",
  "  AND year BETWEEN 2005 AND 2022\n",
  "  AND sex = 0\n",
  "  AND agegrp = 'A00'"
)

qwi_food <- dbGetQuery(con, query_food)
cat(sprintf("Food service (722) rows: %s\n", format(nrow(qwi_food), big.mark = ",")))

# ---- Fetch retail (NAICS 44-45) from sector-level files ----
cat("Fetching QWI retail data from Azure...\n")

file_list_ns <- paste0("'az://derived/qwi/sa/ns/", all_abbr, ".parquet'")

query_retail <- paste0(
  "SELECT geography, year, quarter, CAST(industry AS VARCHAR) AS industry, sex, agegrp,\n",
  "       Emp, EmpS, HirA, HirN, HirR, Sep, TurnOvrS, EarnHirNS, EarnS\n",
  "FROM read_parquet([", paste(file_list_ns, collapse = ", "), "])\n",
  "WHERE industry = '44-45'\n",
  "  AND year BETWEEN 2005 AND 2022\n",
  "  AND sex = 0\n",
  "  AND agegrp = 'A00'"
)

qwi_retail <- dbGetQuery(con, query_retail)
cat(sprintf("Retail (44-45) rows: %s\n", format(nrow(qwi_retail), big.mark = ",")))

# Combine food + retail
qwi_food$industry <- as.character(qwi_food$industry)
qwi_retail$industry <- as.character(qwi_retail$industry)
qwi_raw <- rbind(qwi_food, qwi_retail)
cat(sprintf("Combined rows: %s\n", format(nrow(qwi_raw), big.mark = ",")))

# ---- Fetch age-specific data for NAICS 722 only ----
cat("Fetching age-specific QWI data for food service...\n")

query_age <- paste0(
  "SELECT geography, year, quarter, industry, sex, agegrp,\n",
  "       Emp, EmpS, HirA, HirN, HirR, Sep, TurnOvrS\n",
  "FROM read_parquet([", paste(file_list_n3, collapse = ", "), "])\n",
  "WHERE industry = 722\n",
  "  AND year BETWEEN 2005 AND 2022\n",
  "  AND sex = 0\n",
  "  AND agegrp IN ('A03', 'A04', 'A05', 'A06', 'A07', 'A08')"
)

qwi_age <- dbGetQuery(con, query_age)
cat(sprintf("Age-specific QWI rows: %s\n", format(nrow(qwi_age), big.mark = ",")))

dbDisconnect(con, shutdown = TRUE)

# ---- Convert to data.table and add state FIPS ----
setDT(qwi_raw)
setDT(qwi_age)

# Rename geography -> county_fips
setnames(qwi_raw, "geography", "county_fips")
setnames(qwi_age, "geography", "county_fips")

# Extract state FIPS from county FIPS (first 1-2 digits)
qwi_raw[, state_fips := as.integer(county_fips %/% 1000L)]
qwi_age[, state_fips := as.integer(county_fips %/% 1000L)]

# ---- Validate data ----
stopifnot("No data returned from Azure" = nrow(qwi_raw) > 0)
stopifnot("Missing key columns" = all(c("HirA", "HirN", "HirR", "Sep", "EmpS") %in% names(qwi_raw)))

states_in_data <- sort(unique(qwi_raw$state_fips))
treated_in_data <- intersect(states_in_data, treated_states$state_fips)
cat(sprintf("States in data: %d total, %d treated\n",
            length(states_in_data), length(treated_in_data)))
stopifnot("Missing treated states" = length(treated_in_data) >= 8)

# ---- Save ----
fwrite(qwi_raw, "../data/qwi_main.csv")
fwrite(qwi_age, "../data/qwi_age.csv")
fwrite(treated_states, "../data/treated_states.csv")

cat("Data saved. 01_fetch_data.R completed successfully.\n")
