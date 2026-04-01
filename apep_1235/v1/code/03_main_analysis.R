## 03_main_analysis.R — Primary regressions: continuous-treatment event study
source("00_packages.R")

cat("=== Main Analysis ===\n")

panel <- fread("../data/analysis_panel.csv")

## ---- Event study: continuous treatment ----
# Y_{mt} = alpha_m + gamma_t + sum_{k!=2014} beta_k * (ManufShare_{m,2014} * 1{t=k}) + eps
# Interaction of predetermined manufacturing share with year dummies

panel[, year_f := factor(year)]

# Create interaction terms (reference year = 2014)
panel[, rel_year := year - 2015]  # event time: -4 to 8

## ==============================
## Table 1: Event Study — Secondary Sector Employment Share
## ==============================
cat("\n--- Event Study: Manufacturing Employment Share ---\n")
es_manuf_share <- feols(
  manuf_share ~ i(year, manuf_share_2014, ref = 2014) | gem_id + year,
  data = panel,
  cluster = ~gem_id
)
cat("Event study (manufacturing share) estimated.\n")
print(summary(es_manuf_share))

## ==============================
## Table 1 (continued): Event Study — Tertiary Sector Employment Share
## ==============================
cat("\n--- Event Study: Service Employment Share ---\n")
es_service_share <- feols(
  service_share ~ i(year, manuf_share_2014, ref = 2014) | gem_id + year,
  data = panel,
  cluster = ~gem_id
)
cat("Event study (service share) estimated.\n")
print(summary(es_service_share))

## ==============================
## Table 2: DiD Specification — Static Effects
## ==============================
cat("\n--- Static DiD: Manufacturing share x Post ---\n")

# Main: secondary employment share
did_manuf <- feols(
  manuf_share ~ manuf_share_2014:post | gem_id + year,
  data = panel,
  cluster = ~gem_id
)

# Main: tertiary employment share
did_service <- feols(
  service_share ~ manuf_share_2014:post | gem_id + year,
  data = panel,
  cluster = ~gem_id
)

# Log employment: secondary
did_log_sec <- feols(
  log_emp_secondary ~ manuf_share_2014:post | gem_id + year,
  data = panel,
  cluster = ~gem_id
)

# Log employment: tertiary
did_log_tert <- feols(
  log_emp_tertiary ~ manuf_share_2014:post | gem_id + year,
  data = panel,
  cluster = ~gem_id
)

# Log total employment
did_log_total <- feols(
  log_emp_total ~ manuf_share_2014:post | gem_id + year,
  data = panel,
  cluster = ~gem_id
)

cat("Static DiD results:\n")
cat("  Manuf share: beta =", round(coef(did_manuf), 4),
    " SE =", round(se(did_manuf), 4), "\n")
cat("  Service share: beta =", round(coef(did_service), 4),
    " SE =", round(se(did_service), 4), "\n")
cat("  Log secondary emp: beta =", round(coef(did_log_sec), 4),
    " SE =", round(se(did_log_sec), 4), "\n")
cat("  Log tertiary emp: beta =", round(coef(did_log_tert), 4),
    " SE =", round(se(did_log_tert), 4), "\n")
cat("  Log total emp: beta =", round(coef(did_log_total), 4),
    " SE =", round(se(did_log_total), 4), "\n")

## ==============================
## Table 3: Mechanisms — Establishment Entry/Exit and Intensive Margin
## ==============================
cat("\n--- Mechanisms: Establishment counts and FTE/establishment ---\n")

# Establishments: secondary
did_est_sec <- feols(
  est_secondary ~ manuf_share_2014:post | gem_id + year,
  data = panel,
  cluster = ~gem_id
)

# Establishments: tertiary
did_est_tert <- feols(
  est_tertiary ~ manuf_share_2014:post | gem_id + year,
  data = panel,
  cluster = ~gem_id
)

# FTE per establishment: secondary
did_fte_sec <- feols(
  fte_per_est_sec ~ manuf_share_2014:post | gem_id + year,
  data = panel,
  cluster = ~gem_id
)

# FTE per establishment: tertiary
did_fte_tert <- feols(
  fte_per_est_tert ~ manuf_share_2014:post | gem_id + year,
  data = panel,
  cluster = ~gem_id
)

cat("Mechanism results:\n")
cat("  Est secondary: beta =", round(coef(did_est_sec), 4),
    " SE =", round(se(did_est_sec), 4), "\n")
cat("  Est tertiary: beta =", round(coef(did_est_tert), 4),
    " SE =", round(se(did_est_tert), 4), "\n")
cat("  FTE/est secondary: beta =", round(coef(did_fte_sec), 4),
    " SE =", round(se(did_fte_sec), 4), "\n")
cat("  FTE/est tertiary: beta =", round(coef(did_fte_tert), 4),
    " SE =", round(se(did_fte_tert), 4), "\n")

## ==============================
## Table 4: Short-run vs Long-run (Split Post into 2015-2017 and 2018-2023)
## ==============================
cat("\n--- Short-run vs Long-run Effects ---\n")

panel[, post_short := as.integer(year >= 2015 & year <= 2017)]
panel[, post_long  := as.integer(year >= 2018)]

did_short_long_manuf <- feols(
  manuf_share ~ manuf_share_2014:post_short + manuf_share_2014:post_long | gem_id + year,
  data = panel,
  cluster = ~gem_id
)

did_short_long_serv <- feols(
  service_share ~ manuf_share_2014:post_short + manuf_share_2014:post_long | gem_id + year,
  data = panel,
  cluster = ~gem_id
)

did_short_long_log_sec <- feols(
  log_emp_secondary ~ manuf_share_2014:post_short + manuf_share_2014:post_long | gem_id + year,
  data = panel,
  cluster = ~gem_id
)

did_short_long_log_tert <- feols(
  log_emp_tertiary ~ manuf_share_2014:post_short + manuf_share_2014:post_long | gem_id + year,
  data = panel,
  cluster = ~gem_id
)

cat("Short vs long (manuf share):\n")
print(summary(did_short_long_manuf))

cat("Short vs long (service share):\n")
print(summary(did_short_long_serv))

## ==============================
## Save all model objects and write diagnostics
## ==============================

# Compute diagnostics for validation
n_treated <- nrow(panel[year == 2014 & high_manuf == 1])
n_control <- nrow(panel[year == 2014 & high_manuf == 0])
n_pre <- length(unique(panel[year < 2015]$year))
n_obs <- nrow(panel)

cat("\n=== Diagnostics ===\n")
cat("Treated municipalities (>30% manuf):", n_treated, "\n")
cat("Control municipalities:", n_control, "\n")
cat("Pre-periods:", n_pre, "\n")
cat("Total observations:", n_obs, "\n")

# Write diagnostics.json
jsonlite::write_json(
  list(
    n_treated = n_treated,
    n_pre = n_pre,
    n_obs = n_obs,
    n_control = n_control,
    n_municipalities = uniqueN(panel$gem_id),
    n_years = uniqueN(panel$year)
  ),
  "../data/diagnostics.json",
  auto_unbox = TRUE
)

# Save model objects
save(
  es_manuf_share, es_service_share,
  did_manuf, did_service, did_log_sec, did_log_tert, did_log_total,
  did_est_sec, did_est_tert, did_fte_sec, did_fte_tert,
  did_short_long_manuf, did_short_long_serv,
  did_short_long_log_sec, did_short_long_log_tert,
  file = "../data/models.RData"
)

cat("\n=== Main analysis complete ===\n")
