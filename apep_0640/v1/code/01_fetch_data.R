## 01_fetch_data.R — Fetch QWI race/ethnicity data from Azure
## apep_0640: E-Verify Mandates and Hispanic Employment

source("00_packages.R")
source("../../../../scripts/lib/azure_data.R")

cat("Connecting to Azure...\n")
con <- apep_azure_connect()

# ============================================================================
# E-Verify mandate states and treatment dates (quarter of activation)
# ============================================================================
everify_states <- tribble(
  ~state_fips, ~state_abbr, ~treat_year, ~treat_quarter, ~treat_yq, ~mandate_scope,
  4,  "AZ", 2008, 1, "2008-Q1", "all employers",
  49, "UT", 2010, 3, "2010-Q3", "15+ employees",
  28, "MS", 2011, 3, "2011-Q3", "all employers (phased)",
  22, "LA", 2011, 3, "2011-Q3", "all employers",
  1,  "AL", 2012, 1, "2012-Q1", "all employers",
  13, "GA", 2012, 3, "2012-Q3", "10+ employees (phased)",
  37, "NC", 2013, 4, "2013-Q4", "25+ employees",
  47, "TN", 2017, 1, "2017-Q1", "35+ employees (phased)",
  45, "SC", 2021, 1, "2021-Q1", "all employers",
  12, "FL", 2023, 3, "2023-Q3", "25+ employees"
)

cat("E-Verify mandate states:\n")
print(everify_states)

# ============================================================================
# Strategy: Aggregate to state level directly in DuckDB to avoid memory issues
# ============================================================================

cat("\nFetching state-level QWI RH aggregates from Azure...\n")

# State-level totals across all industries
state_agg <- dbGetQuery(con, "
  SELECT
    CAST(FLOOR(CAST(geography AS INTEGER) / 1000) AS INTEGER) AS state_fips,
    year,
    quarter,
    ethnicity,
    SUM(Emp) AS Emp,
    SUM(HirA) AS HirA,
    SUM(Sep) AS Sep,
    SUM(FrmJbGn) AS FrmJbGn,
    SUM(FrmJbLs) AS FrmJbLs,
    SUM(Emp * EarnS) / NULLIF(SUM(Emp), 0) AS EarnS,
    COUNT(DISTINCT geography) AS n_counties
  FROM 'az://derived/qwi/rh/ns/*.parquet'
  WHERE industry = '00'
    AND ethnicity IN ('A1', 'A2')
    AND year >= 2003
    AND year <= 2024
    AND Emp > 0
  GROUP BY 1, 2, 3, 4
")

cat(sprintf("State-level aggregate: %s rows\n", format(nrow(state_agg), big.mark = ",")))

# State × industry level for heterogeneity
cat("Fetching state-industry QWI RH aggregates...\n")
state_ind_agg <- dbGetQuery(con, "
  SELECT
    CAST(FLOOR(CAST(geography AS INTEGER) / 1000) AS INTEGER) AS state_fips,
    year,
    quarter,
    industry,
    ethnicity,
    SUM(Emp) AS Emp,
    SUM(HirA) AS HirA,
    SUM(Sep) AS Sep,
    SUM(Emp * EarnS) / NULLIF(SUM(Emp), 0) AS EarnS,
    COUNT(DISTINCT geography) AS n_counties
  FROM 'az://derived/qwi/rh/ns/*.parquet'
  WHERE industry IN ('11', '23', '31-33', '44-45', '56', '72', '51', '52', '54', '62')
    AND ethnicity IN ('A1', 'A2')
    AND year >= 2003
    AND year <= 2024
    AND Emp > 0
  GROUP BY 1, 2, 3, 4, 5
")

cat(sprintf("State-industry aggregate: %s rows\n", format(nrow(state_ind_agg), big.mark = ",")))

# ============================================================================
# Label ethnicity
# ============================================================================
label_eth <- function(df) {
  df %>% mutate(
    ethnicity_label = ifelse(ethnicity == "A2", "Hispanic", "Non-Hispanic"),
    hispanic = as.integer(ethnicity == "A2"),
    time_index = (year - 2003) * 4 + quarter,
    yq = paste0(year, "-Q", quarter)
  )
}

state_agg <- label_eth(state_agg)
state_ind_agg <- label_eth(state_ind_agg)

# ============================================================================
# Merge treatment information
# ============================================================================
merge_treat <- function(df) {
  df %>%
    left_join(
      everify_states %>% select(state_fips, state_abbr, treat_year, treat_quarter),
      by = "state_fips"
    ) %>%
    mutate(
      first_treat_time = ifelse(!is.na(treat_year),
                                (treat_year - 2003) * 4 + treat_quarter,
                                0L),
      treated = !is.na(treat_year),
      post = ifelse(treated, time_index >= first_treat_time, FALSE)
    )
}

state_agg <- merge_treat(state_agg)
state_ind_agg <- merge_treat(state_ind_agg)

# ============================================================================
# Add log outcomes
# ============================================================================
state_agg <- state_agg %>%
  mutate(
    log_emp = log(Emp),
    log_earn = log(EarnS),
    log_hir = log(HirA),
    log_sep = log(Sep),
    hire_rate = HirA / Emp,
    sep_rate = Sep / Emp,
    state_eth = paste0(state_fips, "_", ethnicity_label)
  )

# ============================================================================
# Summary
# ============================================================================
cat(sprintf("\nStates covered: %d\n", n_distinct(state_agg$state_fips)))
cat(sprintf("Treated states: %d\n",
            n_distinct(state_agg$state_fips[state_agg$treated])))
cat(sprintf("Control states: %d\n",
            n_distinct(state_agg$state_fips[!state_agg$treated])))
cat(sprintf("Time range: %s to %s\n",
            min(state_agg$yq), max(state_agg$yq)))

cat("\n=== Pre-treatment (2003-2007) Summary ===\n")
state_agg %>%
  filter(year >= 2003, year <= 2007) %>%
  group_by(ethnicity_label) %>%
  summarise(
    mean_emp = mean(Emp),
    sd_emp = sd(Emp),
    mean_earn = mean(EarnS, na.rm = TRUE),
    mean_hire_rate = mean(hire_rate, na.rm = TRUE),
    n_states = n_distinct(state_fips),
    .groups = "drop"
  ) %>%
  print()

cat("\n=== Treatment Cohorts ===\n")
state_agg %>%
  filter(hispanic == 1) %>%
  distinct(state_fips, first_treat_time, treated, state_abbr) %>%
  mutate(
    cohort = case_when(
      !treated ~ "Never treated",
      first_treat_time <= 24 ~ "2008-2009",
      first_treat_time <= 40 ~ "2010-2012",
      first_treat_time <= 56 ~ "2013-2016",
      TRUE ~ "2017+"
    )
  ) %>%
  count(cohort) %>%
  print()

# ============================================================================
# Save
# ============================================================================
saveRDS(state_agg, "../data/state_panel.rds")
saveRDS(state_ind_agg, "../data/state_ind_panel.rds")
saveRDS(everify_states, "../data/everify_states.rds")

cat("\nData saved.\n")
apep_azure_disconnect(con)
cat("Done.\n")
