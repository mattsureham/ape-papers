## 04_robustness.R — Robustness checks and heterogeneity
## APEP paper apep_0627: Wales 20mph Speed Limit

source("00_packages.R")

data_dir <- "../data/"
panel <- fread(file.path(data_dir, "la_month_panel.csv"))

panel[, `:=`(
  la_factor = factor(la_code),
  ym        = factor(paste0(year, "-", sprintf("%02d", month)))
)]

## ------------------------------------------------------------------
## 1. Border LAs only
## ------------------------------------------------------------------
cat("\n=== BORDER LAs ONLY ===\n")

border_panel <- panel[border_la == 1]
cat("Border LAs:", uniqueN(border_panel$la_code), "\n")
cat("  Welsh border:", uniqueN(border_panel[welsh == 1]$la_code), "\n")
cat("  English border:", uniqueN(border_panel[welsh == 0]$la_code), "\n")

rob_border_total <- feols(
  n_collisions ~ welsh:post | la_factor + ym,
  data = border_panel,
  cluster = ~la_code
)

rob_border_ksi <- feols(
  n_ksi ~ welsh:post | la_factor + ym,
  data = border_panel,
  cluster = ~la_code
)

rob_border_ped <- feols(
  n_ped_ksi ~ welsh:post | la_factor + ym,
  data = border_panel,
  cluster = ~la_code
)

cat("Border DiD - Total:", round(coef(rob_border_total), 3), "\n")
cat("Border DiD - KSI:", round(coef(rob_border_ksi), 3), "\n")
cat("Border DiD - Ped KSI:", round(coef(rob_border_ped), 3), "\n")

## ------------------------------------------------------------------
## 2. Poisson regression (count data model)
## ------------------------------------------------------------------
cat("\n=== POISSON REGRESSION ===\n")

rob_pois_total <- fepois(
  n_collisions ~ welsh:post | la_factor + ym,
  data = panel,
  cluster = ~la_code
)

rob_pois_ksi <- fepois(
  n_ksi ~ welsh:post | la_factor + ym,
  data = panel,
  cluster = ~la_code
)

cat("Poisson - Total:", round(coef(rob_pois_total), 4),
    " (IRR:", round(exp(coef(rob_pois_total)), 3), ")\n")
cat("Poisson - KSI:", round(coef(rob_pois_ksi), 4),
    " (IRR:", round(exp(coef(rob_pois_ksi)), 3), ")\n")

## ------------------------------------------------------------------
## 3. Placebo test: September 2022 pseudo-treatment
## ------------------------------------------------------------------
cat("\n=== PLACEBO TEST (Sep 2022) ===\n")

# Restrict to pre-treatment period only
placebo_data <- panel[post == 0]
placebo_data[, pseudo_post := as.integer(
  year > 2022 | (year == 2022 & month >= 9)
)]

rob_placebo_total <- feols(
  n_collisions ~ welsh:pseudo_post | la_factor + ym,
  data = placebo_data,
  cluster = ~la_code
)

rob_placebo_ksi <- feols(
  n_ksi ~ welsh:pseudo_post | la_factor + ym,
  data = placebo_data,
  cluster = ~la_code
)

cat("Placebo - Total:", round(coef(rob_placebo_total), 3),
    " (p=", round(pvalue(rob_placebo_total), 3), ")\n")
cat("Placebo - KSI:", round(coef(rob_placebo_ksi), 3),
    " (p=", round(pvalue(rob_placebo_ksi), 3), ")\n")

## ------------------------------------------------------------------
## 4. Severity decomposition
## ------------------------------------------------------------------
cat("\n=== SEVERITY DECOMPOSITION ===\n")

rob_fatal <- feols(
  n_fatal ~ welsh:post | la_factor + ym,
  data = panel,
  cluster = ~la_code
)

rob_serious <- feols(
  n_serious ~ welsh:post | la_factor + ym,
  data = panel,
  cluster = ~la_code
)

rob_slight <- feols(
  n_slight ~ welsh:post | la_factor + ym,
  data = panel,
  cluster = ~la_code
)

cat("Fatal:", round(coef(rob_fatal), 4), " (p=", round(pvalue(rob_fatal), 3), ")\n")
cat("Serious:", round(coef(rob_serious), 4), " (p=", round(pvalue(rob_serious), 3), ")\n")
cat("Slight:", round(coef(rob_slight), 4), " (p=", round(pvalue(rob_slight), 3), ")\n")

## ------------------------------------------------------------------
## 5. Excluding London
## ------------------------------------------------------------------
cat("\n=== EXCLUDING LONDON ===\n")

# London boroughs have LA codes starting with E09
no_london <- panel[!grepl("^E09", la_code)]

rob_nolondon_ksi <- feols(
  n_ksi ~ welsh:post | la_factor + ym,
  data = no_london,
  cluster = ~la_code
)

cat("Excluding London - KSI:", round(coef(rob_nolondon_ksi), 3), "\n")

## ------------------------------------------------------------------
## 6. Log specification
## ------------------------------------------------------------------
cat("\n=== LOG SPECIFICATION ===\n")

rob_log_collisions <- feols(
  log_collisions ~ welsh:post | la_factor + ym,
  data = panel,
  cluster = ~la_code
)

rob_log_ksi <- feols(
  log_ksi ~ welsh:post | la_factor + ym,
  data = panel,
  cluster = ~la_code
)

cat("Log - Collisions:", round(coef(rob_log_collisions), 4), "\n")
cat("Log - KSI:", round(coef(rob_log_ksi), 4), "\n")

## ------------------------------------------------------------------
## 7. Save all robustness results
## ------------------------------------------------------------------
save(
  rob_border_total, rob_border_ksi, rob_border_ped,
  rob_pois_total, rob_pois_ksi,
  rob_placebo_total, rob_placebo_ksi,
  rob_fatal, rob_serious, rob_slight,
  rob_nolondon_ksi,
  rob_log_collisions, rob_log_ksi,
  file = file.path(data_dir, "robustness_results.RData")
)

cat("\nRobustness analysis complete.\n")
