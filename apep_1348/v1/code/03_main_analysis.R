# 03_main_analysis.R — Primary regressions
# apep_1348: Groningen Regulatory Rebound

source("00_packages.R")

data_dir <- "../data/"
tables_dir <- "../tables/"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

cat("=== Main Analysis ===\n")
cat(sprintf("Panel: %d obs, %d municipalities, %d years\n",
    nrow(panel), n_distinct(panel$region_code), n_distinct(panel$year)))

# ============================================================
# 1. Event Study — Distance Bin × Year Interactions
# ============================================================
cat("\nRunning event study (distance bin × year)...\n")

# Reference: >150km bin, year 2011 (t-1)
panel <- panel %>%
  mutate(
    event_year = factor(event_time),
    dist_bin_f = relevel(dist_bin, ref = ">150km")
  )

# Event study: bins × year indicators
# Focus on the 0-20km bin (most treated)
es_model <- feols(
  log_price ~ i(event_time, treat_intensity, ref = -1) |
    region_code + year,
  data = panel,
  cluster = ~region_code
)

cat("Event study coefficients:\n")
summary(es_model)

# Save coefficients for the paper
es_coefs <- as.data.frame(coeftable(es_model))
es_coefs$event_time <- as.numeric(gsub(".*::(-?[0-9]+)$", "\\1",
                                        rownames(es_coefs)))
saveRDS(es_coefs, file.path(data_dir, "event_study_coefs.rds"))

# ============================================================
# 2. Main DiD — Pre vs Post Huizinge × Distance
# ============================================================
cat("\nRunning main DiD specifications...\n")

# Specification 1: Post-Huizinge × inverse distance
did1 <- feols(
  log_price ~ post_huizinge:treat_intensity |
    region_code + year,
  data = panel,
  cluster = ~region_code
)

# Specification 2: Three-period model (pre-2012, 2013-2017, 2018+)
panel <- panel %>%
  mutate(
    period = case_when(
      year <= 2012 ~ "pre",
      year >= 2013 & year <= 2017 ~ "decline",
      year >= 2018 ~ "recovery"
    ),
    period = factor(period, levels = c("pre", "decline", "recovery"))
  )

did2 <- feols(
  log_price ~ i(period, treat_intensity, ref = "pre") |
    region_code + year,
  data = panel,
  cluster = ~region_code
)

# Specification 3: Continuous distance (donut: drop <10km)
panel_donut <- panel %>% filter(dist_km >= 10)

did3 <- feols(
  log_price ~ post_huizinge:treat_intensity |
    region_code + year,
  data = panel_donut,
  cluster = ~region_code
)

# Specification 4: Distance bins instead of continuous
did4 <- feols(
  log_price ~ i(post_huizinge, dist_bin_f) |
    region_code + year,
  data = panel,
  cluster = ~region_code
)

cat("\n--- Specification 1: Post × Inverse Distance ---\n")
summary(did1)

cat("\n--- Specification 2: Three-Period Model ---\n")
summary(did2)

cat("\n--- Specification 3: Donut (>10km) ---\n")
summary(did3)

cat("\n--- Specification 4: Distance Bins ---\n")
summary(did4)

# ============================================================
# 3. Production-Earthquake Mechanism
# ============================================================
cat("\nRunning production-earthquake mechanism test...\n")

eq_annual <- readRDS(file.path(data_dir, "earthquake_annual.rds"))
production <- readRDS(file.path(data_dir, "groningen_production.rds"))

mechanism_df <- production %>%
  left_join(eq_annual, by = "year") %>%
  mutate(
    n_quakes = replace_na(n_quakes, 0),
    max_mag = replace_na(max_mag, 0),
    log_prod = log(production_bcm + 0.1)
  )

# Production → earthquake frequency
mech1 <- lm(n_quakes ~ log_prod, data = mechanism_df)
cat("\nProduction → Earthquake frequency:\n")
summary(mech1)

# ============================================================
# 4. Save diagnostics
# ============================================================

# Count treated units (within 75km — municipalities with meaningful earthquake exposure)
n_treated <- n_distinct(panel$region_code[panel$dist_km <= 75])
n_pre <- length(unique(panel$year[panel$year < 2013]))
n_obs <- nrow(panel)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_municipalities = n_distinct(panel$region_code),
  n_years = n_distinct(panel$year),
  mean_price = mean(panel$value, na.rm = TRUE),
  sd_price = sd(panel$value, na.rm = TRUE),
  sd_log_price = sd(panel$log_price, na.rm = TRUE)
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE)

# Save models
saveRDS(list(did1 = did1, did2 = did2, did3 = did3, did4 = did4,
             es = es_model, mech1 = mech1),
        file.path(data_dir, "models.rds"))

cat("\n=== Main analysis complete ===\n")
cat(sprintf("  Treated municipalities (≤50km): %d\n", n_treated))
cat(sprintf("  Pre-periods: %d\n", n_pre))
cat(sprintf("  Total observations: %d\n", n_obs))
