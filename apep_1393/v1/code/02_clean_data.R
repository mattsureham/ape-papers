## 02_clean_data.R — Clean and merge FDIC + HMDA into tract-year panel
## apep_1393: Merger-Induced Branch Closures and Racial Mortgage Gaps

source("00_packages.R")

data_dir <- "../data"

# ============================================================================
# 1. Process SOD: Branch counts by tract-year
# ============================================================================
cat("=== Processing SOD data ===\n")
sod <- readRDS(file.path(data_dir, "fdic_sod.rds"))

# Clean tract FIPS (stcntybr is state+county FIPS, need to map to full tract)
# SOD gives state+county FIPS at branch level, not tract. We'll use county-level.
# Actually stcntybr IS the state+county+branch FIPS — let's check
cat("Sample stcntybr values:", head(unique(sod$stcntybr), 10), "\n")
cat("stcntybr nchar distribution:\n")
print(table(nchar(sod$stcntybr), useNA = "ifany"))

# stcntybr is 5-digit state+county FIPS (e.g., "06001" for Alameda, CA)
# We'll work at county level for the branch count panel
sod <- sod %>%
  filter(!is.na(stcntybr), nchar(stcntybr) >= 4) %>%
  mutate(
    county_fips = str_pad(stcntybr, 5, pad = "0"),
    state_fips = substr(county_fips, 1, 2)
  )

# Branch counts by county-year
branch_panel <- sod %>%
  group_by(county_fips, year) %>%
  summarise(
    n_branches = n(),
    total_deposits = sum(deposits, na.rm = TRUE),
    n_banks = n_distinct(cert),
    .groups = "drop"
  )

cat("Branch panel: ", n_distinct(branch_panel$county_fips), "counties,",
    min(branch_panel$year), "-", max(branch_panel$year), "\n")

# ============================================================================
# 2. Construct merger exposure instrument
# ============================================================================
cat("\n=== Constructing merger exposure instrument ===\n")
mergers <- readRDS(file.path(data_dir, "fdic_mergers.rds"))

# For each merger, identify branches of target AND acquirer
# Merger exposure for county i in year t = share of branches in county i
# belonging to banks that merged in (t-3, t)

mergers <- mergers %>%
  mutate(merger_year = as.integer(format(eff_date, "%Y")))

# Get list of CERTs involved in mergers by year
# Target CERTs are institutions that disappeared through merger
# Their branches either transfer to acquirer or close
merger_certs <- mergers %>%
  select(cert = target_cert, merger_year) %>%
  filter(!is.na(cert)) %>%
  distinct(cert, merger_year)

cat("Unique CERTs involved in mergers:", n_distinct(merger_certs$cert), "\n")

# For each county-year, compute merger exposure
# = share of branches in that county belonging to banks that merged in prior 3 years
compute_merger_exposure <- function(sod_data, merger_certs_data) {
  results <- list()

  for (yr in sort(unique(sod_data$year))) {
    # Banks that merged in year yr (1-year window for sharper variation)
    recent_merger_certs <- merger_certs_data %>%
      filter(merger_year == yr) %>%
      pull(cert) %>% unique()

    yr_sod <- sod_data %>% filter(year == yr)

    county_exposure <- yr_sod %>%
      mutate(is_merger_bank = cert %in% recent_merger_certs) %>%
      group_by(county_fips) %>%
      summarise(
        n_branches_total = n(),
        n_merger_branches = sum(is_merger_bank),
        merger_exposure = n_merger_branches / n_branches_total,
        merger_deposits_share = sum(deposits[is_merger_bank], na.rm = TRUE) /
          sum(deposits, na.rm = TRUE),
        .groups = "drop"
      ) %>%
      mutate(year = yr)

    results[[as.character(yr)]] <- county_exposure
    cat("  Year", yr, ":", sum(county_exposure$n_merger_branches > 0), "counties with merger exposure\n")
  }

  bind_rows(results)
}

exposure <- compute_merger_exposure(sod, merger_certs)

# Merge with branch panel to get branch changes
branch_changes <- branch_panel %>%
  arrange(county_fips, year) %>%
  group_by(county_fips) %>%
  mutate(
    branch_change = n_branches - lag(n_branches),
    branch_change_pct = branch_change / lag(n_branches),
    hhi_deposits = NA_real_  # placeholder — compute if needed
  ) %>%
  ungroup()

instrument <- left_join(branch_changes, exposure, by = c("county_fips", "year"))

cat("Instrument panel:", nrow(instrument), "county-years\n")

# ============================================================================
# 3. Process HMDA: Tract-year-race aggregates → county-year racial gaps
# ============================================================================
cat("\n=== Processing HMDA data ===\n")
hmda <- readRDS(file.path(data_dir, "hmda_raw.rds"))

# Clean race categories
# Note: HMDA derived_race does not have "Hispanic or Latino" — that's in derived_ethnicity
# We use derived_race categories as available
hmda <- hmda %>%
  mutate(
    race_clean = case_when(
      derived_race == "White" ~ "White",
      derived_race == "Black or African American" ~ "Black",
      derived_race == "Asian" ~ "Asian",
      TRUE ~ "Other"
    ),
    denied = as.integer(action_taken == 3),
    originated = as.integer(action_taken == 1),
    interest_rate_num = suppressWarnings(as.numeric(interest_rate)),
    rate_spread_num = suppressWarnings(as.numeric(rate_spread)),
    loan_amount_num = suppressWarnings(as.numeric(loan_amount)),
    income_num = suppressWarnings(as.numeric(income))
  ) %>%
  filter(race_clean %in% c("White", "Black", "Asian"))

# county_code in HMDA is already the full 5-digit FIPS (e.g., "06037")
hmda <- hmda %>%
  mutate(county_fips = county_code)

cat("HMDA records after cleaning:", nrow(hmda), "\n")
cat("Race distribution:\n")
print(table(hmda$race_clean))

# Aggregate to county-year-race level
hmda_county <- hmda %>%
  group_by(county_fips, year, race_clean) %>%
  summarise(
    n_apps = n(),
    n_denied = sum(denied),
    n_originated = sum(originated),
    denial_rate = mean(denied),
    mean_rate_spread = mean(rate_spread_num, na.rm = TRUE),
    mean_interest_rate = mean(interest_rate_num, na.rm = TRUE),
    mean_loan_amount = mean(loan_amount_num, na.rm = TRUE),
    mean_income = mean(income_num, na.rm = TRUE),
    .groups = "drop"
  )

# Compute racial gaps: Black-White and Asian-White
white <- hmda_county %>% filter(race_clean == "White") %>%
  select(county_fips, year, denial_rate_w = denial_rate,
         rate_spread_w = mean_rate_spread, interest_rate_w = mean_interest_rate,
         n_apps_w = n_apps, income_w = mean_income, loan_amount_w = mean_loan_amount)

black <- hmda_county %>% filter(race_clean == "Black") %>%
  select(county_fips, year, denial_rate_b = denial_rate,
         rate_spread_b = mean_rate_spread, interest_rate_b = mean_interest_rate,
         n_apps_b = n_apps, income_b = mean_income, loan_amount_b = mean_loan_amount)

asian <- hmda_county %>% filter(race_clean == "Asian") %>%
  select(county_fips, year, denial_rate_a = denial_rate,
         rate_spread_a = mean_rate_spread, interest_rate_a = mean_interest_rate,
         n_apps_a = n_apps, income_a = mean_income, loan_amount_a = mean_loan_amount)

racial_gaps <- white %>%
  left_join(black, by = c("county_fips", "year")) %>%
  left_join(asian, by = c("county_fips", "year")) %>%
  mutate(
    bw_denial_gap = denial_rate_b - denial_rate_w,
    aw_denial_gap = denial_rate_a - denial_rate_w,
    bw_rate_gap = rate_spread_b - rate_spread_w,
    aw_rate_gap = rate_spread_a - rate_spread_w,
    bw_interest_gap = interest_rate_b - interest_rate_w,
    aw_interest_gap = interest_rate_a - interest_rate_w
  )

cat("Racial gap panel:", nrow(racial_gaps), "county-years\n")

# ============================================================================
# 4. Merge everything into analysis panel
# ============================================================================
cat("\n=== Building analysis panel ===\n")

# Also need race-specific counts for overall outcomes
hmda_county_all <- hmda %>%
  group_by(county_fips, year) %>%
  summarise(
    total_apps = n(),
    total_denied = sum(denied),
    overall_denial_rate = mean(denied),
    black_share = mean(race_clean == "Black"),
    hispanic_share = mean(race_clean == "Hispanic"),
    .groups = "drop"
  )

cat("Instrument rows:", nrow(instrument), "\n")
cat("Racial gaps rows:", nrow(racial_gaps), "\n")
cat("Instrument county sample:", head(instrument$county_fips, 5), "\n")
cat("Racial gaps county sample:", head(racial_gaps$county_fips, 5), "\n")

panel <- instrument %>%
  inner_join(racial_gaps, by = c("county_fips", "year")) %>%
  inner_join(hmda_county_all, by = c("county_fips", "year"))

cat("After inner join:", nrow(panel), "rows\n")

panel <- panel %>%
  filter(!is.na(merger_exposure), !is.na(bw_denial_gap))

# Extract state FIPS for fixed effects
panel <- panel %>%
  mutate(state_fips = substr(county_fips, 1, 2))

# Minimum cell size: require at least 20 Black applications per county-year
panel <- panel %>%
  filter(n_apps_b >= 20, n_apps_w >= 50)

cat("Final analysis panel:", nrow(panel), "county-years\n")
cat("Counties:", n_distinct(panel$county_fips), "\n")
cat("Years:", sort(unique(panel$year)), "\n")
cat("Mean BW denial gap:", round(mean(panel$bw_denial_gap, na.rm = TRUE), 4), "\n")
cat("Mean merger exposure:", round(mean(panel$merger_exposure, na.rm = TRUE), 4), "\n")

saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))
cat("Saved analysis_panel.rds\n")

# Save summary stats for validation
summary_stats <- list(
  n_county_years = nrow(panel),
  n_counties = n_distinct(panel$county_fips),
  years = sort(unique(panel$year)),
  mean_bw_gap = mean(panel$bw_denial_gap, na.rm = TRUE),
  mean_aw_gap = mean(panel$aw_denial_gap, na.rm = TRUE),
  mean_merger_exposure = mean(panel$merger_exposure, na.rm = TRUE),
  mean_branch_change = mean(panel$branch_change, na.rm = TRUE)
)
jsonlite::write_json(summary_stats, file.path(data_dir, "summary_stats.json"), auto_unbox = TRUE, pretty = TRUE)
cat("Saved summary_stats.json\n")
