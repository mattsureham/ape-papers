## 02_clean_data.R — Panel construction and treatment assignment
## apep_0843: RON Laws and New Business Formation

source("00_packages.R")

bfs_raw <- readRDS("../data/bfs_raw.rds")

# ------------------------------------------------------------------
# Treatment assignment: Permanent RON adoption dates (pre-COVID only)
# Source: National Notary Association, Notarize.com legal tracker,
#         individual state legislative records
# ------------------------------------------------------------------
# We use the effective date of the permanent RON statute.
# Emergency COVID-era RON orders are excluded from primary specification.

ron_treatment <- tribble(
  ~state, ~ron_date,        ~ron_ym,
  # 2012
  "VA",   "2012-07-01",     201207,
  # 2015
  "MT",   "2015-10-01",     201510,
  # 2017
  "TX",   "2017-09-01",     201709,
  "NV",   "2017-10-01",     201710,
  # 2018
  "IN",   "2018-07-01",     201807,
  "OH",   "2018-09-19",     201809,
  "MI",   "2018-12-28",     201812,
  "MN",   "2018-08-01",     201808,
  "TN",   "2018-07-01",     201807,
  "VT",   "2018-07-01",     201807,
  # 2019
  "AZ",   "2019-08-27",     201908,
  "FL",   "2019-01-01",     201901,
  "ID",   "2019-07-01",     201907,
  "IA",   "2019-07-01",     201907,
  "KY",   "2019-06-27",     201906,
  "MD",   "2019-10-01",     201910,
  "NE",   "2019-07-01",     201907,
  "ND",   "2019-08-01",     201908,
  "OK",   "2019-11-01",     201911,
  "SD",   "2019-07-01",     201907,
  "UT",   "2019-05-14",     201905,
  "WA",   "2019-07-28",     201907
) %>%
  mutate(ron_date = as.Date(ron_date))

cat("Treatment states:", nrow(ron_treatment), "\n")
cat("Treatment cohorts:\n")
ron_treatment %>%
  mutate(year = year(ron_date)) %>%
  count(year) %>%
  print()

# ------------------------------------------------------------------
# Construct panel
# ------------------------------------------------------------------
panel <- bfs_raw %>%
  mutate(
    year  = year(date),
    month = month(date),
    ym    = year * 100 + month
  ) %>%
  # Create numeric time index for did package (months since July 2004)
  mutate(
    time_index = (year - 2004) * 12 + month - 6  # July 2004 = 1
  ) %>%
  # Pivot to wide: one row per state-month with BA, HBA, WBA, CBA columns
  pivot_wider(
    id_cols = c(state, date, year, month, ym, time_index),
    names_from = series,
    values_from = value
  ) %>%
  # Join treatment info
  left_join(ron_treatment, by = "state") %>%
  mutate(
    # first_treat: the time_index of treatment (0 = never treated)
    first_treat_ym = if_else(is.na(ron_ym), 0L, as.integer(ron_ym)),
    first_treat = if_else(
      is.na(ron_date),
      0L,
      as.integer((year(ron_date) - 2004) * 12 + month(ron_date) - 6)
    ),
    # Binary treatment indicator
    treated_state = !is.na(ron_date),
    post = if_else(treated_state & ym >= ron_ym, 1L, 0L)
  ) %>%
  arrange(state, date)

# ------------------------------------------------------------------
# Primary sample: July 2004 through December 2019 (pre-COVID)
# ------------------------------------------------------------------
panel_primary <- panel %>%
  filter(date <= as.Date("2019-12-01"))

cat("\n=== Panel Summary (Primary Sample: 2004m7-2019m12) ===\n")
cat("Observations:", nrow(panel_primary), "\n")
cat("States:", n_distinct(panel_primary$state), "\n")
cat("Time periods:", n_distinct(panel_primary$time_index), "\n")
cat("Treated states:", sum(panel_primary$treated_state[!duplicated(panel_primary$state)]), "\n")
cat("Never-treated states:", sum(!panel_primary$treated_state[!duplicated(panel_primary$state)]), "\n")

# Validate no NAs in outcome
stopifnot(sum(is.na(panel_primary$BA)) == 0)
stopifnot(sum(is.na(panel_primary$CBA)) == 0)

# ------------------------------------------------------------------
# Log outcomes for percentage interpretation
# ------------------------------------------------------------------
panel_primary <- panel_primary %>%
  mutate(
    log_BA  = log(BA + 1),
    log_HBA = log(HBA + 1),
    log_WBA = log(WBA + 1),
    log_CBA = log(CBA + 1)
  )

# Extended sample (through 2024) for robustness
panel_extended <- panel %>%
  mutate(
    log_BA  = log(BA + 1),
    log_HBA = log(HBA + 1),
    log_WBA = log(WBA + 1),
    log_CBA = log(CBA + 1)
  )

# ------------------------------------------------------------------
# Save
# ------------------------------------------------------------------
saveRDS(panel_primary, "../data/panel_primary.rds")
saveRDS(panel_extended, "../data/panel_extended.rds")
saveRDS(ron_treatment, "../data/ron_treatment.rds")

cat("\nPanel saved. Ready for analysis.\n")

# Print cohort summary
cat("\n=== Treatment Cohort Summary ===\n")
panel_primary %>%
  filter(treated_state) %>%
  distinct(state, ron_date, first_treat) %>%
  arrange(ron_date) %>%
  print(n = 25)
