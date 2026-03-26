# 02_clean_data.R — Construct analysis panel for apep_0985
# Merges Google Trends (catalytic converter theft search interest),
# palladium prices, law enactment dates, and state unemployment.

source("00_packages.R")

# ============================================================
# Load raw data
# ============================================================
gtrends   <- readRDS("../data/gtrends_state_ts.rds")
palladium <- readRDS("../data/palladium_prices.rds")
law_dates <- readRDS("../data/law_dates.rds")
unemp_raw <- readRDS("../data/unemp_raw.rds")
pop_raw   <- readRDS("../data/pop_raw.rds")

cat("Raw data loaded.\n")

# ============================================================
# 1. Clean Google Trends state-month panel
# ============================================================
gt <- gtrends %>%
  select(date, state_abbr, hits) %>%
  mutate(
    date  = as.Date(date),
    hits  = as.numeric(hits),
    year  = year(date),
    month = month(date)
  ) %>%
  filter(!is.na(hits))

cat(sprintf("Google Trends: %d obs, %d states, %s to %s\n",
            nrow(gt), n_distinct(gt$state_abbr),
            min(gt$date), max(gt$date)))

# ============================================================
# 2. Merge palladium prices (monthly)
# ============================================================
pd <- palladium %>%
  select(date, pd_close, log_pd) %>%
  mutate(year = year(date), month = month(date))

panel <- gt %>%
  left_join(pd %>% select(year, month, pd_close, log_pd),
            by = c("year", "month"))

cat(sprintf("After palladium merge: %d obs\n", nrow(panel)))

# ============================================================
# 3. Add treatment indicators from law enactment dates
# ============================================================
# Treatment = 1 from the month the law takes effect onward
# Cohort = month of first law enactment (for CS estimator)

law_info <- law_dates %>%
  select(state_abbr, enact_date, enact_ym, law_type)

panel <- panel %>%
  left_join(law_info, by = "state_abbr") %>%
  mutate(
    treated    = ifelse(!is.na(enact_date) & date >= enact_ym, 1L, 0L),
    ever_treat = ifelse(!is.na(enact_date), 1L, 0L),
    # Cohort indicator for CS: year-month of treatment as numeric
    cohort_ym  = if_else(!is.na(enact_ym),
                         as.numeric(format(enact_ym, "%Y")) +
                           (as.numeric(format(enact_ym, "%m")) - 1) / 12,
                         0)  # 0 = never-treated
  )

# Relative time indicator (months since treatment)
panel <- panel %>%
  mutate(
    rel_time = if_else(ever_treat == 1L,
                       as.integer(round(difftime(date, enact_ym, units = "days") / 30.44)),
                       NA_integer_)
  )

cat(sprintf("Treatment: %d treated obs, %d control obs\n",
            sum(panel$treated), sum(panel$treated == 0)))
cat(sprintf("  Ever-treated states: %d, Never-treated: %d\n",
            n_distinct(panel$state_abbr[panel$ever_treat == 1]),
            n_distinct(panel$state_abbr[panel$ever_treat == 0])))

# ============================================================
# 4. Add unemployment (monthly)
# ============================================================
unemp <- unemp_raw %>%
  transmute(
    date        = as.Date(date),
    state_abbr  = state_abbr,
    unemp_rate  = as.numeric(value)
  ) %>%
  mutate(year = year(date), month = month(date)) %>%
  filter(!is.na(unemp_rate))

panel <- panel %>%
  left_join(unemp %>% select(state_abbr, year, month, unemp_rate),
            by = c("state_abbr", "year", "month"))

cat(sprintf("Unemployment coverage: %.1f%%\n",
            100 * mean(!is.na(panel$unemp_rate))))

# ============================================================
# 5. Add population (annual, interpolated to monthly)
# ============================================================
# State name to abbreviation mapping
state_xwalk <- data.frame(
  state_name = c(state.name, "District of Columbia"),
  state_abbr = c(state.abb, "DC"),
  stringsAsFactors = FALSE
)

if (nrow(pop_raw) > 0 && "NAME" %in% names(pop_raw)) {
  pop <- pop_raw %>%
    left_join(state_xwalk, by = c("NAME" = "state_name")) %>%
    filter(!is.na(state_abbr)) %>%
    transmute(state_abbr, year = as.integer(year), pop = as.numeric(POP))

  # Forward-fill population for missing years
  all_years <- data.frame(year = 2016:2025)
  pop_full <- pop %>%
    group_by(state_abbr) %>%
    complete(year = 2016:2025) %>%
    fill(pop, .direction = "downup") %>%
    ungroup()

  panel <- panel %>%
    left_join(pop_full %>% select(state_abbr, year, pop),
              by = c("state_abbr", "year"))

  cat(sprintf("Population coverage: %.1f%%\n", 100 * mean(!is.na(panel$pop))))
}

# ============================================================
# 6. Create analysis variables
# ============================================================
panel <- panel %>%
  mutate(
    # Log transform of search hits (add 1 for zeros)
    log_hits  = log(hits + 1),
    # IHS transform (handles zeros better)
    ihs_hits  = log(hits + sqrt(hits^2 + 1)),
    # Numeric state ID for fixest
    state_id  = as.integer(factor(state_abbr)),
    # Year-month numeric ID
    ym_id     = year * 12 + month,
    # Felony law indicator
    felony    = if_else(!is.na(law_type) & grepl("felony", law_type), 1L, 0L),
    # Interaction: law x palladium price
    law_x_pd  = treated * log_pd
  )

# ============================================================
# 7. Summary statistics
# ============================================================
cat("\n=== Panel Summary ===\n")
cat(sprintf("  Observations: %d\n", nrow(panel)))
cat(sprintf("  States: %d\n", n_distinct(panel$state_abbr)))
cat(sprintf("  Time range: %s to %s\n", min(panel$date), max(panel$date)))
cat(sprintf("  Treated (ever): %d states\n", n_distinct(panel$state_abbr[panel$ever_treat == 1])))
cat(sprintf("  Never-treated: %d states\n", n_distinct(panel$state_abbr[panel$ever_treat == 0])))
cat(sprintf("  Mean hits (pre): %.1f\n", mean(panel$hits[panel$treated == 0], na.rm = TRUE)))
cat(sprintf("  Mean hits (post-treat): %.1f\n",
            mean(panel$hits[panel$treated == 1 & panel$ever_treat == 1], na.rm = TRUE)))

# Save analysis panel
saveRDS(panel, "../data/analysis_panel.rds")
cat("\nAnalysis panel saved: ../data/analysis_panel.rds\n")
