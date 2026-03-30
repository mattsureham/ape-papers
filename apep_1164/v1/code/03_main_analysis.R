## 03_main_analysis.R — Main difference-in-differences estimation
## apep_1164: The Formalization Dividend
source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "panel_clean.rds"))
panel_nc <- readRDS(file.path(data_dir, "panel_no_covid.rds"))

# ============================================================
# 1. Main Specification: Continuous DiD
# ============================================================
cat("=== Main DiD Results ===\n\n")

# Y_dt = α_d + γ_t + β(VenShare_d × Post_t) + ε_dt
# VenShare is time-invariant (pre-ETPV Venezuelan concentration)
# Post = 1 for years >= 2021

# (a) Employment rate (TO) — main outcome
m1_to <- feols(to ~ treat_intensity | dept_fe + year_fe, data = panel,
               cluster = ~department)

# (b) Unemployment rate (TD)
m1_td <- feols(td ~ treat_intensity | dept_fe + year_fe, data = panel,
               cluster = ~department)

# (c) Labor force participation (TGP)
m1_tgp <- feols(tgp ~ treat_intensity | dept_fe + year_fe, data = panel,
                cluster = ~department)

# (d) Underemployment rate (TS)
m1_ts <- feols(ts ~ treat_intensity | dept_fe + year_fe, data = panel,
               cluster = ~department)

cat("Main results (all years, including 2020):\n")
etable(m1_to, m1_td, m1_tgp, m1_ts,
       headers = c("Empl. Rate", "Unemp. Rate", "Participation", "Underempl."),
       se.below = TRUE)

# ============================================================
# 2. Excluding 2020 (COVID year)
# ============================================================
cat("\n=== Excluding 2020 ===\n\n")

m2_to <- feols(to ~ treat_intensity | dept_fe + year_fe, data = panel_nc,
               cluster = ~department)
m2_td <- feols(td ~ treat_intensity | dept_fe + year_fe, data = panel_nc,
               cluster = ~department)
m2_tgp <- feols(tgp ~ treat_intensity | dept_fe + year_fe, data = panel_nc,
                cluster = ~department)
m2_ts <- feols(ts ~ treat_intensity | dept_fe + year_fe, data = panel_nc,
               cluster = ~department)

cat("Results excluding 2020:\n")
etable(m2_to, m2_td, m2_tgp, m2_ts,
       headers = c("Empl. Rate", "Unemp. Rate", "Participation", "Underempl."),
       se.below = TRUE)

# ============================================================
# 3. Event Study
# ============================================================
cat("\n=== Event Study ===\n\n")

# Interact ven_share with each event-year dummy (omit t=-1, i.e. 2020)
# For the COVID-excluded version, omit t=-2 (2019)
panel_nc <- panel_nc %>%
  mutate(event_time_fct = factor(event_time))

# Event study: TO
m3_to <- feols(to ~ i(event_time_fct, ven_share, ref = "-2") | dept_fe + year_fe,
               data = panel_nc, cluster = ~department)

cat("Event study coefficients (employment rate, ref = 2019):\n")
print(coeftable(m3_to))

# Event study: TD
m3_td <- feols(td ~ i(event_time_fct, ven_share, ref = "-2") | dept_fe + year_fe,
               data = panel_nc, cluster = ~department)

cat("\nEvent study coefficients (unemployment rate, ref = 2019):\n")
print(coeftable(m3_td))

# ============================================================
# 4. Wild Cluster Bootstrap (23 clusters)
# ============================================================
cat("\n=== Wild Cluster Bootstrap ===\n\n")

# With 23 clusters, conventional cluster SEs may underperform
# Use Webb weights (better for <30 clusters)
boot_to <- boottest(m2_to, param = "treat_intensity", B = 9999,
                    clustid = "department", type = "webb")
cat("Employment rate — WCB p-value:", boot_to$p_val, "\n")
cat("Employment rate — WCB 95% CI:", boot_to$conf_int, "\n")

boot_td <- boottest(m2_td, param = "treat_intensity", B = 9999,
                    clustid = "department", type = "webb")
cat("Unemployment rate — WCB p-value:", boot_td$p_val, "\n")
cat("Unemployment rate — WCB 95% CI:", boot_td$conf_int, "\n")

boot_tgp <- boottest(m2_tgp, param = "treat_intensity", B = 9999,
                     clustid = "department", type = "webb")
cat("Participation rate — WCB p-value:", boot_tgp$p_val, "\n")
cat("Participation rate — WCB 95% CI:", boot_tgp$conf_int, "\n")

# ============================================================
# 5. Write diagnostics.json
# ============================================================
diag <- list(
  n_treated = length(unique(panel$department)),  # all treated (continuous)
  n_pre = length(unique(panel$year[panel$year < 2021])),
  n_obs = nrow(panel_nc),
  n_departments = length(unique(panel$department)),
  n_years = length(unique(panel_nc$year)),
  treatment_range = range(panel$ven_share),
  main_coef_to = coef(m2_to)["treat_intensity"],
  main_se_to = se(m2_to)["treat_intensity"],
  main_coef_td = coef(m2_td)["treat_intensity"],
  main_se_td = se(m2_td)["treat_intensity"],
  wcb_pval_to = boot_to$p_val,
  wcb_pval_td = boot_td$p_val
)
jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE, pretty = TRUE)

# ============================================================
# 6. Save model objects for tables
# ============================================================
saveRDS(list(
  m1_to = m1_to, m1_td = m1_td, m1_tgp = m1_tgp, m1_ts = m1_ts,
  m2_to = m2_to, m2_td = m2_td, m2_tgp = m2_tgp, m2_ts = m2_ts,
  m3_to = m3_to, m3_td = m3_td,
  boot_to = boot_to, boot_td = boot_td, boot_tgp = boot_tgp
), file.path(data_dir, "main_models.rds"))

cat("\n=== Main analysis complete ===\n")
