# =============================================================================
# 03_main_analysis.R — Main DiD estimation
# APEP Paper apep_0794: Testing Without Tests
# =============================================================================

source("00_packages.R")

panel <- readRDS("../data/panel.rds")

# =============================================================================
# 1. Descriptive statistics
# =============================================================================

# Pre-treatment means by treatment status
pre <- panel %>%
  filter(year <= 2019) %>%
  group_by(test_required_2019) %>%
  summarise(
    n_inst = n_distinct(unitid),
    mean_enrollment = mean(eftotlt, na.rm = TRUE),
    mean_black_share = mean(share_black, na.rm = TRUE),
    mean_hispanic_share = mean(share_hispanic, na.rm = TRUE),
    mean_white_share = mean(share_white, na.rm = TRUE),
    mean_asian_share = mean(share_asian, na.rm = TRUE),
    mean_urm_share = mean(share_urm, na.rm = TRUE),
    mean_admit_rate = mean(admit_rate, na.rm = TRUE),
    mean_apps = mean(applicants_total, na.rm = TRUE),
    .groups = "drop"
  )

cat("=== Pre-treatment means (2014-2019) ===\n")
print(as.data.frame(pre))

# =============================================================================
# 2. Main DiD: Binary treatment (required → optional)
# =============================================================================
cat("\n=== Main DiD: Binary Treatment ===\n")

# Spec 1: Simple DiD
m1_black <- feols(share_black ~ test_required_2019:post | unitid + year,
                  data = panel, cluster = ~unitid)
m1_hisp <- feols(share_hispanic ~ test_required_2019:post | unitid + year,
                 data = panel, cluster = ~unitid)
m1_white <- feols(share_white ~ test_required_2019:post | unitid + year,
                  data = panel, cluster = ~unitid)
m1_urm <- feols(share_urm ~ test_required_2019:post | unitid + year,
                data = panel, cluster = ~unitid)

cat("\nBlack share:\n")
summary(m1_black)
cat("\nHispanic share:\n")
summary(m1_hisp)
cat("\nWhite share:\n")
summary(m1_white)
cat("\nURM share:\n")
summary(m1_urm)

# =============================================================================
# 3. Continuous treatment intensity DiD
# =============================================================================
cat("\n=== Continuous Treatment Intensity (SAT 25th pctile) ===\n")

# Restrict to treated group (required tests in 2019) with SAT scores
treated <- panel %>% filter(test_required_2019 == 1, !is.na(sat_intensity))

m2_black <- feols(share_black ~ sat_intensity:post | unitid + year,
                  data = treated, cluster = ~unitid)
m2_hisp <- feols(share_hispanic ~ sat_intensity:post | unitid + year,
                 data = treated, cluster = ~unitid)
m2_white <- feols(share_white ~ sat_intensity:post | unitid + year,
                  data = treated, cluster = ~unitid)
m2_urm <- feols(share_urm ~ sat_intensity:post | unitid + year,
                data = treated, cluster = ~unitid)

cat("\nBlack share (intensity):\n")
summary(m2_black)
cat("\nHispanic share (intensity):\n")
summary(m2_hisp)
cat("\nURM share (intensity):\n")
summary(m2_urm)

# =============================================================================
# 4. Admissions outcomes
# =============================================================================
cat("\n=== Admissions Outcomes ===\n")

# Application volume (log)
panel <- panel %>%
  mutate(log_apps = ifelse(applicants_total > 0, log(applicants_total), NA_real_))

m3_apps <- feols(log_apps ~ test_required_2019:post | unitid + year,
                 data = panel, cluster = ~unitid)
m3_admit <- feols(admit_rate ~ test_required_2019:post | unitid + year,
                  data = panel, cluster = ~unitid)
m3_yield <- feols(yield_rate ~ test_required_2019:post | unitid + year,
                  data = panel, cluster = ~unitid)

cat("\nLog applications:\n")
summary(m3_apps)
cat("\nAdmission rate:\n")
summary(m3_admit)
cat("\nYield rate:\n")
summary(m3_yield)

# =============================================================================
# 5. Event study (binary treatment)
# =============================================================================
cat("\n=== Event Study ===\n")

panel <- panel %>%
  mutate(event_time = year - 2020,
         event_time_f = factor(event_time))

# Drop 2019 as reference period (event_time = -1)
es_black <- feols(share_black ~ i(event_time, test_required_2019, ref = -1) |
                    unitid + year,
                  data = panel, cluster = ~unitid)
es_hisp <- feols(share_hispanic ~ i(event_time, test_required_2019, ref = -1) |
                   unitid + year,
                 data = panel, cluster = ~unitid)
es_urm <- feols(share_urm ~ i(event_time, test_required_2019, ref = -1) |
                  unitid + year,
                data = panel, cluster = ~unitid)

cat("\nEvent study — Black share:\n")
summary(es_black)
cat("\nEvent study — Hispanic share:\n")
summary(es_hisp)
cat("\nEvent study — URM share:\n")
summary(es_urm)

# =============================================================================
# 6. Event study (continuous intensity, treated only)
# =============================================================================
cat("\n=== Event Study: Intensity ===\n")

treated <- treated %>%
  mutate(event_time = year - 2020)

es_int_black <- feols(share_black ~ i(event_time, sat_intensity, ref = -1) |
                        unitid + year,
                      data = treated, cluster = ~unitid)
es_int_hisp <- feols(share_hispanic ~ i(event_time, sat_intensity, ref = -1) |
                       unitid + year,
                     data = treated, cluster = ~unitid)

cat("\nEvent study (intensity) — Black share:\n")
summary(es_int_black)
cat("\nEvent study (intensity) — Hispanic share:\n")
summary(es_int_hisp)

# =============================================================================
# 7. Save results for tables
# =============================================================================

results <- list(
  binary_did = list(black = m1_black, hispanic = m1_hisp, white = m1_white, urm = m1_urm),
  intensity_did = list(black = m2_black, hispanic = m2_hisp, white = m2_white, urm = m2_urm),
  admissions = list(apps = m3_apps, admit = m3_admit, yield = m3_yield),
  event_study = list(black = es_black, hispanic = es_hisp, urm = es_urm),
  event_intensity = list(black = es_int_black, hispanic = es_int_hisp)
)
saveRDS(results, "../data/results.rds")

# Diagnostics for validator
n_treated <- n_distinct(panel$unitid[panel$test_required_2019 == 1])
n_pre <- length(unique(panel$year[panel$year < 2020]))
n_obs <- nrow(panel)

jsonlite::write_json(
  list(n_treated = n_treated, n_pre = n_pre, n_obs = n_obs),
  "../data/diagnostics.json", auto_unbox = TRUE
)

cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n", n_treated, n_pre, n_obs))
cat("Results saved.\n")
