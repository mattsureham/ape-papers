# ==============================================================================
# 03_main_analysis.R — Main DiD analysis: TMDL coverage and dissolved oxygen
# ==============================================================================

source("00_packages.R")
DATA_DIR <- "../data"

cat("=== Loading analysis panel ===\n")
panel <- readRDS(file.path(DATA_DIR, "analysis_panel.rds"))
panel <- panel %>% filter(has_tmdl_data)

cat(sprintf("Panel: %d station-years, %d stations, %d HUC8s\n",
            nrow(panel), n_distinct(panel$station_id),
            n_distinct(panel$huc8)))


# ---- Main specification: TWFE with continuous treatment ----
cat("\n=== Main Specification: TWFE ===\n")

# Create numeric station and HUC8 IDs for fixest
panel <- panel %>%
  mutate(
    station_num = as.numeric(factor(station_id)),
    huc8_num = as.numeric(factor(huc8))
  )

# Specification 1: Station FE + Year FE, continuous TMDL share
# Interpretation: within a station, does higher watershed-level TMDL coverage
# associate with higher DO over time?
# Since TMDL share is cross-sectional (2022 snapshot), we interact it with a
# post-period indicator. Treatment = high TMDL share × post-2010 (when most TMDLs
# in our sample were completed under consent decrees)

panel <- panel %>%
  mutate(post = as.numeric(year >= 2010))

# Main regression: continuous treatment
m1 <- feols(do_mean ~ tmdl_share:post | station_num + year,
            data = panel,
            cluster = ~huc8_num)

cat("\n--- Model 1: Continuous TMDL share × Post ---\n")
summary(m1)

# Specification 2: Binary treatment (high vs low TMDL)
m2 <- feols(do_mean ~ high_tmdl:post | station_num + year,
            data = panel,
            cluster = ~huc8_num)

cat("\n--- Model 2: Binary TMDL coverage × Post ---\n")
summary(m2)

# Specification 3: Dose-response with year interactions
m3 <- feols(do_mean ~ i(year, tmdl_share, ref = 2005) | station_num,
            data = panel,
            cluster = ~huc8_num)

cat("\n--- Model 3: Event study (TMDL share × year) ---\n")
summary(m3)


# ---- Alternative: HUC8-level panel ----
cat("\n=== HUC8-level analysis ===\n")

huc_panel <- panel %>%
  group_by(huc8, year, tmdl_share, high_tmdl, huc8_num) %>%
  summarize(
    do_mean = weighted.mean(do_mean, w = do_n),
    n_stations = n_distinct(station_id),
    n_readings = sum(do_n),
    .groups = "drop"
  ) %>%
  mutate(post = as.numeric(year >= 2010))

cat(sprintf("HUC8 panel: %d observations, %d HUC8s\n",
            nrow(huc_panel), n_distinct(huc_panel$huc8)))

# HUC8-level TWFE
m4 <- feols(do_mean ~ tmdl_share:post | huc8_num + year,
            data = huc_panel,
            cluster = ~huc8_num)

cat("\n--- Model 4: HUC8-level, continuous TMDL × Post ---\n")
summary(m4)

m5 <- feols(do_mean ~ high_tmdl:post | huc8_num + year,
            data = huc_panel,
            cluster = ~huc8_num)

cat("\n--- Model 5: HUC8-level, binary TMDL × Post ---\n")
summary(m5)


# ---- Store results ----
cat("\n=== Saving results ===\n")

results <- list(
  m1 = m1,
  m2 = m2,
  m3 = m3,
  m4 = m4,
  m5 = m5,
  panel_summary = list(
    n_obs = nrow(panel),
    n_stations = n_distinct(panel$station_id),
    n_huc8 = n_distinct(panel$huc8),
    mean_do = mean(panel$do_mean),
    sd_do = sd(panel$do_mean),
    mean_tmdl_share = mean(panel$tmdl_share, na.rm = TRUE),
    sd_tmdl_share = sd(panel$tmdl_share, na.rm = TRUE),
    years = range(panel$year)
  )
)
saveRDS(results, file.path(DATA_DIR, "main_results.rds"))

# Update diagnostics
diag <- jsonlite::fromJSON(file.path(DATA_DIR, "diagnostics.json"))
diag$n_treated <- n_distinct(panel$station_id[panel$high_tmdl == 1])
diag$n_pre <- length(unique(panel$year[panel$year < 2010]))
diag$n_obs <- nrow(panel)
jsonlite::write_json(diag, file.path(DATA_DIR, "diagnostics.json"), auto_unbox = TRUE)

cat("\n=== Main analysis complete ===\n")
