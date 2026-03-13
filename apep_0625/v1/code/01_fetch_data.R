# =============================================================================
# 01_fetch_data.R — Fetch QWI data from Azure Blob Storage
# =============================================================================
# Reads sex×age×NAICS-sector QWI Parquet for all 50 states + DC,
# filters to 2013Q1–2023Q4, and writes a state-level analytical panel.
# =============================================================================

source("00_packages.R")
source("../../../../scripts/lib/azure_data.R")

con <- apep_azure_connect()

# ── Treatment coding ─────────────────────────────────────────────────────────
# Salary history ban effective dates (private-employer coverage)
ban_dates <- tribble(
  ~state_fips, ~state_abbr, ~ban_date,
  "10", "DE", "2017-12-14",
  "41", "OR", "2017-10-01",
  "06", "CA", "2018-01-01",
  "25", "MA", "2018-07-01",
  "50", "VT", "2018-07-01",
  "09", "CT", "2019-01-01",
  "15", "HI", "2019-01-01",
  "17", "IL", "2019-09-29",
  "53", "WA", "2019-07-28",
  "23", "ME", "2019-09-17",
  "01", "AL", "2019-09-01",
  "34", "NJ", "2020-01-01",
  "24", "MD", "2020-10-01",
  "08", "CO", "2021-01-01",
  "32", "NV", "2021-10-01",
  "44", "RI", "2023-01-01"
) %>%
  mutate(
    ban_date = as.Date(ban_date),
    ban_year = year(ban_date),
    ban_quarter = quarter(ban_date),
    # Treatment quarter (year-quarter numeric: 2017Q4 = 2017.75, etc.)
    first_treat_yq = ban_year + (ban_quarter - 1) / 4
  )

cat("Treatment states:", nrow(ban_dates), "\n")
cat("Treatment cohorts:\n")
print(ban_dates %>% count(first_treat_yq) %>% arrange(first_treat_yq))

# ── Read QWI from Azure ──────────────────────────────────────────────────────
# Query: state-level, sex=male/female (not combined), all NAICS supersectors
# Period: 2013-2023

cat("\nQuerying QWI sex×age data from Azure...\n")

qwi_raw <- apep_azure_query(con, "
  SELECT geography, year, quarter, sex, agegrp, industry,
         Emp, EmpEnd, HirA, HirN, Sep, FrmJbGn, FrmJbLs,
         EarnS, EarnHirNS, TurnOvrS
  FROM 'az://derived/qwi/sa/ns/*.parquet'
  WHERE geo_level = 'S'
    AND year BETWEEN 2013 AND 2023
    AND sex IN (1, 2)
    AND agegrp = 'A00'
    AND industry != '00'
")

cat("QWI raw rows:", nrow(qwi_raw), "\n")
cat("States:", n_distinct(qwi_raw$geography), "\n")
cat("Industries:", n_distinct(qwi_raw$industry), "\n")

stopifnot(nrow(qwi_raw) > 50000)
stopifnot(n_distinct(qwi_raw$geography) >= 50)

# ── Merge treatment status ───────────────────────────────────────────────────
# State FIPS from geography (2-digit state code)
qwi <- qwi_raw %>%
  mutate(
    state_fips = str_pad(as.character(geography), 2, pad = "0"),
    yq = year + (quarter - 1) / 4,
    sex_label = ifelse(sex == 1, "Male", "Female")
  ) %>%
  left_join(ban_dates %>% select(state_fips, state_abbr, first_treat_yq, ban_date),
            by = "state_fips") %>%
  mutate(
    # Never-treated states get first_treat_yq = 0 (for CS-DiD)
    first_treat_yq = replace_na(first_treat_yq, 0),
    treated = first_treat_yq > 0,
    post = ifelse(treated, yq >= first_treat_yq, FALSE)
  )

cat("\nTreated states:", n_distinct(qwi$state_fips[qwi$treated]), "\n")
cat("Never-treated states:", n_distinct(qwi$state_fips[!qwi$treated]), "\n")
cat("Total observations:", nrow(qwi), "\n")

# ── Also fetch race×ethnicity data for mechanism test ────────────────────────
cat("\nQuerying QWI race×ethnicity data from Azure...\n")

qwi_race_raw <- apep_azure_query(con, "
  SELECT geography, year, quarter, race, ethnicity, industry,
         Emp, HirN, EarnHirNS, EarnS
  FROM 'az://derived/qwi/rh/ns/*.parquet'
  WHERE geo_level = 'S'
    AND year BETWEEN 2013 AND 2023
    AND race IN ('A1', 'A2')
    AND ethnicity = 'A0'
    AND industry != '00'
")

cat("Race QWI raw rows:", nrow(qwi_race_raw), "\n")

qwi_race <- qwi_race_raw %>%
  mutate(
    state_fips = str_pad(as.character(geography), 2, pad = "0"),
    yq = year + (quarter - 1) / 4,
    race_label = case_when(
      race == "A1" ~ "White",
      race == "A2" ~ "Black",
      TRUE ~ "Other"
    )
  ) %>%
  left_join(ban_dates %>% select(state_fips, first_treat_yq),
            by = "state_fips") %>%
  mutate(
    first_treat_yq = replace_na(first_treat_yq, 0),
    treated = first_treat_yq > 0,
    post = ifelse(treated, yq >= first_treat_yq, FALSE)
  )

apep_azure_disconnect(con)

# ── Save ─────────────────────────────────────────────────────────────────────
saveRDS(qwi, "../data/qwi_panel.rds")
saveRDS(qwi_race, "../data/qwi_race_panel.rds")
saveRDS(ban_dates, "../data/ban_dates.rds")

cat("\n=== Data fetch complete ===\n")
cat("Main panel:", nrow(qwi), "obs\n")
cat("Race panel:", nrow(qwi_race), "obs\n")
cat("Files saved to data/\n")
