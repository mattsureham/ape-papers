## 03_main_analysis.R — Primary regressions
## apep_1095: Induced seismicity and self-regulation in Texas Permian Basin

source("00_packages.R")

panel <- readRDS("../data/panel_clean.rds")
ring_panel <- readRDS("../data/ring_panel.rds")
sra_monthly <- readRDS("../data/sra_monthly.rds")

# ========================================================================
# 1. Main DiD: Grid-cell level, Poisson FE
# ========================================================================
cat("=== Main Analysis ===\n\n")

# Drop NAs in treated (grid cells not matched to SRA grid)
panel <- panel %>%
  filter(!is.na(treated)) %>%
  mutate(
    post_treat = as.integer(treated & post),
    treated_int = as.integer(treated)
  )

cat(sprintf("Panel after dropping NAs: %d obs, %d treated cells, %d control cells\n",
            nrow(panel), n_distinct(panel$grid_id[panel$treated]),
            n_distinct(panel$grid_id[!panel$treated])))

# Specification 1: Binary treatment (in SRA × post)
cat("Model 1: Binary DiD (Poisson FE)\n")
m1_pois <- feglm(eq_count ~ post_treat | grid_id + ym,
                  data = panel,
                  family = poisson,
                  cluster = ~sra_name + ym)

# Specification 2: Treatment intensity (dose-response)
cat("Model 2: Dose-response (treatment intensity)\n")
m2_dose <- feglm(eq_count ~ treat_intensity | grid_id + ym,
                  data = panel,
                  family = poisson,
                  cluster = ~sra_name + ym)

# Specification 3: OLS for comparison
cat("Model 3: OLS DiD\n")
m3_ols <- feols(eq_count ~ post_treat | grid_id + ym,
                data = panel,
                cluster = ~sra_name + ym)

# Specification 4: Log outcome OLS
cat("Model 4: Log(1+count) OLS\n")
m4_log <- feols(log_eq_count ~ post_treat | grid_id + ym,
                data = panel,
                cluster = ~sra_name + ym)

cat("\n--- Main results ---\n")
cat("Model 1 (Poisson binary DiD):\n")
summary(m1_pois)
cat("\nModel 2 (Poisson dose-response):\n")
summary(m2_dose)
cat("\nModel 3 (OLS binary DiD):\n")
summary(m3_ols)
cat("\nModel 4 (Log OLS binary DiD):\n")
summary(m4_log)

# ========================================================================
# 2. Event Study (SRA-level)
# ========================================================================
cat("\n=== Event Study ===\n")

# Create event-time dummies relative to SRA enforcement
# Use grid-cell panel, bin at event time relative to each SRA's enforcement date
es_panel <- panel %>%
  filter(in_any_sra | pre_any_eq == 1) %>%
  filter(!is.na(rel_month) | !in_any_sra) %>%
  # For treated cells: use rel_month

  # For control cells: assign rel_month based on average treatment date (Feb 2022)
  mutate(
    rel_month_es = if_else(
      in_any_sra,
      rel_month,
      as.integer(difftime(month_date, as.Date("2022-02-01"), units = "days")) %/% 30L
    ),
    # Bin into 6-month bins for cleaner estimation
    rel_bin = case_when(
      rel_month_es < -36 ~ -36L,
      rel_month_es > 24 ~ 24L,
      TRUE ~ rel_month_es
    )
  )

# Event study with monthly indicators
cat("Event study (monthly, Poisson):\n")
# Omit rel_month_es == -1 as reference
es_panel <- es_panel %>% mutate(treated_int = as.integer(in_any_sra))
es_model <- feglm(
  eq_count ~ i(rel_bin, treated_int, ref = -1) | grid_id + ym,
  data = es_panel %>% filter(rel_bin >= -24 & rel_bin <= 24),
  family = poisson,
  cluster = ~sra_name + ym
)
summary(es_model)

# Extract event study coefficients
es_coefs <- as.data.frame(coeftable(es_model)) %>%
  rownames_to_column("term") %>%
  filter(grepl("rel_bin", term)) %>%
  mutate(
    rel_month = as.integer(gsub(".*::", "", gsub("rel_bin::", "", term))),
    estimate = Estimate,
    se = `Std. Error`,
    ci_lo = estimate - 1.96 * se,
    ci_hi = estimate + 1.96 * se
  )

saveRDS(es_coefs, "../data/event_study_coefs.rds")

# ========================================================================
# 3. Ring-zone displacement analysis
# ========================================================================
cat("\n=== Displacement Analysis ===\n")

# Does seismicity shift to buffer zones after SRA designation?
# Simpler: within SRA vs nearby buffer × post
ring_panel_did <- ring_panel %>%
  filter(ring_zone %in% c("Within SRA", "0-20km buffer", "20-50km buffer")) %>%
  mutate(
    close = as.integer(ring_zone == "Within SRA"),
    post_close = as.integer(ring_zone == "Within SRA" & post_any)
  )

m_ring_did <- feglm(
  eq_count ~ post_close | ring_zone + ym,
  data = ring_panel_did,
  family = poisson
)
cat("\nWithin-SRA vs. buffer DiD:\n")
summary(m_ring_did)

# ========================================================================
# 4. SRA-specific effects
# ========================================================================
cat("\n=== SRA-Specific Effects ===\n")

panel_sra <- panel %>%
  filter(in_any_sra) %>%
  mutate(
    post_gardendale = as.integer(post_gardendale),
    post_ncr = as.integer(post_ncr),
    post_stanton = as.integer(post_stanton)
  )

m_sra_specific <- feglm(
  eq_count ~ post_gardendale + post_ncr + post_stanton | grid_id + ym,
  data = panel_sra,
  family = poisson,
  cluster = ~sra_name + ym
)
cat("SRA-specific treatment effects:\n")
summary(m_sra_specific)

# ========================================================================
# 5. Oklahoma comparison (descriptive)
# ========================================================================
cat("\n=== Oklahoma Comparison (Descriptive) ===\n")

# Fetch Oklahoma earthquake data for comparison
cat("Fetching Oklahoma earthquake data...\n")
fetch_ok <- function(start, end) {
  url <- paste0(
    "https://earthquake.usgs.gov/fdsnws/event/1/query?format=geojson",
    "&starttime=", start, "&endtime=", end,
    "&minlatitude=34.0&maxlatitude=37.0",
    "&minlongitude=-100.0&maxlongitude=-96.0",
    "&minmagnitude=2.0&orderby=time"
  )
  resp <- httr::GET(url, httr::timeout(120))
  if (httr::status_code(resp) != 200) return(NULL)
  raw <- httr::content(resp, as = "text", encoding = "UTF-8")
  parsed <- jsonlite::fromJSON(raw, flatten = TRUE)
  if (is.null(parsed$features) || nrow(parsed$features) == 0) return(NULL)
  data.frame(
    year = year(as.POSIXct(parsed$features$properties.time / 1000,
                            origin = "1970-01-01", tz = "UTC")),
    mag = parsed$features$properties.mag,
    state = "Oklahoma"
  )
}

ok_list <- list()
for (yr in 2017:2024) {
  ok_list[[as.character(yr)]] <- fetch_ok(paste0(yr, "-01-01"), paste0(yr, "-12-31"))
  Sys.sleep(1)
}
ok_eq <- bind_rows(ok_list)

# Texas Permian Basin annual totals
tx_annual <- readRDS("../data/earthquakes_raw.rds") %>%
  group_by(year) %>%
  summarize(eq_count = n(), .groups = "drop") %>%
  mutate(state = "Texas (Permian)")

ok_annual <- ok_eq %>%
  group_by(year) %>%
  summarize(eq_count = n(), .groups = "drop") %>%
  mutate(state = "Oklahoma")

comparison <- bind_rows(tx_annual, ok_annual)
cat("\nAnnual comparison:\n")
comparison %>% pivot_wider(names_from = state, values_from = eq_count) %>% print()

saveRDS(comparison, "../data/ok_tx_comparison.rds")

# ========================================================================
# 6. Save diagnostics for validator
# ========================================================================
n_treated_cells <- n_distinct(panel$grid_id[panel$treated])
n_pre <- panel %>%
  filter(treated, !post) %>%
  pull(ym) %>%
  n_distinct()
n_obs <- nrow(panel)

diagnostics <- list(
  n_treated = n_treated_cells,
  n_pre = n_pre,
  n_obs = n_obs
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            n_treated_cells, n_pre, n_obs))

# Extract and save coefficient tables (model objects may lose data scope)
extract_ct <- function(m) {
  ct <- as.data.frame(coeftable(m))
  ct$term <- rownames(ct)
  ct
}

model_results <- list(
  m1_pois_ct = extract_ct(m1_pois),
  m2_dose_ct = extract_ct(m2_dose),
  m3_ols_ct = extract_ct(m3_ols),
  m4_log_ct = extract_ct(m4_log),
  m_ring_did_ct = extract_ct(m_ring_did),
  m_sra_specific_ct = extract_ct(m_sra_specific),
  n_obs = nrow(panel)
)

saveRDS(model_results, "../data/models.rds")

cat("\nMain analysis complete.\n")
