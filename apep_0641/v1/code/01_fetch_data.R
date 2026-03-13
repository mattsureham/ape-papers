## 01_fetch_data.R — Fetch QWI data from Azure Parquet files
## apep_0641: Salary History Bans and the Industry Geography of Pay Compression

source("00_packages.R")

cat("=== Fetching QWI data from Azure ===\n")

# ---- Azure connection ----
dotenv <- readLines("../../../../.env", warn = FALSE)
az_line <- grep("^AZURE_STORAGE_CONNECTION_STRING=", dotenv, value = TRUE)
if (length(az_line) == 0) stop("AZURE_STORAGE_CONNECTION_STRING not found in .env")
az_conn <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", az_line[1])

con <- dbConnect(duckdb())
dbExecute(con, "INSTALL azure; LOAD azure;")
dbExecute(con, sprintf("SET azure_storage_connection_string = '%s';", az_conn))

# ---- Treatment definitions ----
# State salary history bans (private employer coverage), effective dates
ban_states <- data.frame(
  state_fips = c("10", "41", "06", "25", "50",
                 "09", "15", "17", "53", "23", "01",
                 "34", "24",
                 "08", "32",
                 "44"),
  state_abbr = c("DE", "OR", "CA", "MA", "VT",
                 "CT", "HI", "IL", "WA", "ME", "AL",
                 "NJ", "MD",
                 "CO", "NV",
                 "RI"),
  ban_date = as.Date(c("2017-12-14", "2017-10-06", "2018-01-01", "2018-07-01", "2018-07-01",
                        "2019-01-01", "2019-01-01", "2019-09-29", "2019-07-28", "2019-09-17", "2019-09-01",
                        "2020-01-01", "2020-10-01",
                        "2021-01-01", "2021-10-01",
                        "2023-01-01")),
  stringsAsFactors = FALSE
)

# Convert ban date to treatment quarter (first full quarter after effective date)
ban_states$ban_year <- as.integer(format(ban_states$ban_date, "%Y"))
ban_states$ban_qtr <- as.integer(ceiling(as.numeric(format(ban_states$ban_date, "%m")) / 3))
# If law takes effect mid-quarter, treatment starts next quarter
ban_states$treat_quarter <- ifelse(
  as.numeric(format(ban_states$ban_date, "%d")) > 15,
  ban_states$ban_year * 4 + ban_states$ban_qtr,
  ban_states$ban_year * 4 + ban_states$ban_qtr - 1
)

write_csv(ban_states, "../data/ban_states.csv")
cat("Saved treatment timing for", nrow(ban_states), "states\n")

# ---- Fetch QWI sex x age data ----
cat("Querying QWI sex x age panel from Azure...\n")

# We need: state-level, by sex, by industry, quarterly
# Focus on counties in treated + control states, aggregate to state
qwi_sa <- dbGetQuery(con, "
  SELECT
    CAST(geography AS VARCHAR) AS geo,
    SUBSTRING(CAST(geography AS VARCHAR), 1, 2) AS state_fips,
    CAST(sex AS VARCHAR) AS sex,
    CAST(agegrp AS VARCHAR) AS agegrp,
    CAST(industry AS VARCHAR) AS industry,
    year, quarter,
    \"Emp\" AS emp,
    \"EmpS\" AS emp_s,
    \"EarnS\" AS earn_s,
    \"EarnHirNS\" AS earn_hir,
    \"HirA\" AS hir_a,
    \"HirN\" AS hir_n,
    \"Sep\" AS sep,
    \"FrmJbGn\" AS frm_jb_gn,
    \"FrmJbLs\" AS frm_jb_ls,
    \"TurnOvrS\" AS turnover
  FROM read_parquet('az://derived/qwi/sa/ns/*.parquet')
  WHERE year >= 2013 AND year <= 2025
    AND CAST(agegrp AS VARCHAR) IN ('A03', 'A04', 'A05')
    AND CAST(sex AS VARCHAR) IN ('1', '2')
    AND CAST(industry AS VARCHAR) IN ('00', '11', '21', '22', '23', '31-33', '42', '44-45', '48-49',
                     '51', '52', '53', '54', '55', '56', '61', '62', '71', '72', '81', '92')
")

cat("QWI sex x age rows:", nrow(qwi_sa), "\n")
stopifnot(nrow(qwi_sa) > 100000)

# ---- Aggregate to state-industry-sex-quarter level ----
cat("Aggregating to state-industry-sex-quarter level...\n")

qwi_state <- qwi_sa %>%
  filter(agegrp %in% c("A03", "A04", "A05")) %>%  # ages 25-34, 35-44, 45-54
  filter(!is.na(emp), emp > 0) %>%
  group_by(state_fips, sex, industry, year, quarter) %>%
  summarise(
    earn_hir = {
      valid <- !is.na(earn_hir) & !is.na(hir_n) & hir_n > 0
      if (sum(valid) == 0) NA_real_
      else weighted.mean(earn_hir[valid], hir_n[valid])
    },
    earn_s = {
      valid <- !is.na(earn_s) & !is.na(emp)
      if (sum(valid) == 0) NA_real_
      else weighted.mean(earn_s[valid], emp[valid])
    },
    hir_n = sum(hir_n, na.rm = TRUE),
    sep = sum(sep, na.rm = TRUE),
    turnover = sum(turnover, na.rm = TRUE),
    emp = sum(emp, na.rm = TRUE),
    .groups = "drop"
  )

cat("State-level panel rows:", nrow(qwi_state), "\n")
stopifnot(nrow(qwi_state) > 10000)

# ---- Fetch QWI race x ethnicity data for Doleac-Hansen test ----
cat("Querying QWI race x ethnicity panel from Azure...\n")

qwi_rh <- dbGetQuery(con, "
  SELECT
    SUBSTRING(CAST(geography AS VARCHAR), 1, 2) AS state_fips,
    CAST(sex AS VARCHAR) AS sex,
    CAST(race AS VARCHAR) AS race,
    CAST(ethnicity AS VARCHAR) AS ethnicity,
    CAST(industry AS VARCHAR) AS industry,
    year, quarter,
    \"Emp\" AS emp,
    \"EarnS\" AS earn_s,
    \"EarnHirNS\" AS earn_hir,
    \"HirN\" AS hir_n,
    \"Sep\" AS sep
  FROM read_parquet('az://derived/qwi/rh/ns/*.parquet')
  WHERE year >= 2013 AND year <= 2025
    AND CAST(race AS VARCHAR) IN ('A1', 'A2', 'A3', 'A4', 'A5', 'A6', 'A7')
    AND CAST(ethnicity AS VARCHAR) IN ('A0')
    AND CAST(industry AS VARCHAR) IN ('00', '52', '54', '62', '72', '44-45', '31-33', '42')
")

cat("QWI race rows:", nrow(qwi_rh), "\n")

# ---- Save ----
arrow::write_parquet(qwi_state, "../data/qwi_state_panel.parquet")
arrow::write_parquet(qwi_rh, "../data/qwi_race_panel.parquet")

dbDisconnect(con, shutdown = TRUE)
cat("=== Data fetch complete ===\n")
cat("Files saved to data/\n")
