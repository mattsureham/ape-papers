## 04_robustness.R — Robustness checks and placebo tests
## apep_0513: Welsh 20mph Speed Limit

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"

# ============================================================
# 1. Load Data
# ============================================================
cat("=== Loading panels ===\n")

panel <- fread(file.path(data_dir, "panel_pfa_month.csv"))
panel[, ym := as.Date(ym)]
placebo <- fread(file.path(data_dir, "panel_placebo_pfa.csv"))
placebo[, ym := as.Date(ym)]
scot <- fread(file.path(data_dir, "panel_scottish_placebo.csv"))
scot[, ym := as.Date(ym)]

# ============================================================
# 2. PLACEBO 1: High-Speed Roads (40+ mph)
# ============================================================
cat("\n=== Placebo 1: 40+ mph roads (should be null) ===\n")

placebo[, log_collisions := log(collisions + 1)]
p1 <- feols(log_collisions ~ treat | pfa + ym, data = placebo, cluster = ~pfa)
cat(sprintf("  40+ mph road effect: %.4f (SE: %.4f, p: %.4f)\n",
            coef(p1)["treat"], se(p1)["treat"], fixest::pvalue(p1)["treat"]))

# ============================================================
# 3. PLACEBO 2: Scotland vs England
# ============================================================
cat("\n=== Placebo 2: Scotland vs England (should be null) ===\n")

p2 <- feols(log_collisions ~ treat | pfa + ym, data = scot, cluster = ~pfa)
cat(sprintf("  Scotland placebo effect: %.4f (SE: %.4f, p: %.4f)\n",
            coef(p2)["treat"], se(p2)["treat"], fixest::pvalue(p2)["treat"]))

# ============================================================
# 4. PLACEBO 3: Fake Treatment Date (September 2022)
# ============================================================
cat("\n=== Placebo 3: Fake treatment date (Sept 2022) ===\n")

panel_pre <- panel[ym < as.Date("2023-09-01")]
panel_pre[, fake_post := as.integer(ym >= as.Date("2022-09-01"))]
panel_pre[, fake_treat := welsh * fake_post]

p3 <- feols(log_collisions ~ fake_treat | pfa + ym, data = panel_pre, cluster = ~pfa)
cat(sprintf("  Fake Sept 2022 effect: %.4f (SE: %.4f, p: %.4f)\n",
            coef(p3)["fake_treat"], se(p3)["fake_treat"], fixest::pvalue(p3)["fake_treat"]))

# ============================================================
# 5. Excluding COVID Period (2020-2021)
# ============================================================
cat("\n=== Robustness: Excluding COVID period ===\n")

panel_nocovid <- panel[!(year %in% c(2020, 2021))]
r1 <- feols(log_collisions ~ treat | pfa + ym, data = panel_nocovid, cluster = ~pfa)
cat(sprintf("  Excl. COVID effect: %.4f (SE: %.4f, p: %.4f)\n",
            coef(r1)["treat"], se(r1)["treat"], fixest::pvalue(r1)["treat"]))

# ============================================================
# 6. Border LAs Only
# ============================================================
cat("\n=== Robustness: English border PFAs only ===\n")

# English PFAs bordering Wales
border_english <- c("West Mercia", "Gloucestershire", "Avon and Somerset",
                     "Cheshire", "Merseyside")

panel_border <- panel[welsh == 1 | pfa %in% border_english]
r2 <- feols(log_collisions ~ treat | pfa + ym, data = panel_border, cluster = ~pfa)
cat(sprintf("  Border-only effect: %.4f (SE: %.4f, p: %.4f)\n",
            coef(r2)["treat"], se(r2)["treat"], fixest::pvalue(r2)["treat"]))

# ============================================================
# 7. Region-Specific Trends
# ============================================================
cat("\n=== Robustness: Adding nation-specific linear trends ===\n")

panel[, month_num := as.integer(ym - min(ym)) / 30]
r3 <- feols(log_collisions ~ treat + i(welsh, month_num) | pfa + ym,
            data = panel, cluster = ~pfa)
cat(sprintf("  With nation trends: %.4f (SE: %.4f, p: %.4f)\n",
            coef(r3)["treat"], se(r3)["treat"], fixest::pvalue(r3)["treat"]))

# ============================================================
# 8. Poisson Specification
# ============================================================
cat("\n=== Robustness: Poisson regression ===\n")

r4 <- tryCatch({
  fepois(collisions ~ treat | pfa + ym, data = panel, cluster = ~pfa)
}, error = function(e) {
  cat("  Poisson failed:", e$message, "\n")
  NULL
})

if (!is.null(r4)) {
  cat(sprintf("  Poisson effect: %.4f (SE: %.4f, p: %.4f)\n",
              coef(r4)["treat"], se(r4)["treat"], fixest::pvalue(r4)["treat"]))
  cat(sprintf("  Implied IRR: %.3f (%.1f%% change)\n",
              exp(coef(r4)["treat"]), (exp(coef(r4)["treat"]) - 1) * 100))
}

# ============================================================
# 9. Randomization Inference
# ============================================================
cat("\n=== Randomization Inference ===\n")

# Permute Welsh/English assignment across PFAs
set.seed(42)
n_perms <- 999
pfa_list <- unique(panel$pfa)
n_welsh <- sum(unique(panel[welsh == 1])$welsh)
n_welsh_pfas <- n_distinct(panel[welsh == 1]$pfa)

# Observed coefficient
obs_coef <- coef(feols(log_collisions ~ treat | pfa + ym, data = panel))["treat"]

perm_coefs <- numeric(n_perms)
for (i in seq_len(n_perms)) {
  # Randomly assign n_welsh_pfas PFAs as "treated"
  fake_welsh <- sample(pfa_list, n_welsh_pfas)
  panel_perm <- copy(panel)
  panel_perm[, welsh_perm := as.integer(pfa %in% fake_welsh)]
  panel_perm[, treat_perm := welsh_perm * post]

  perm_fit <- tryCatch(
    feols(log_collisions ~ treat_perm | pfa + ym, data = panel_perm),
    error = function(e) NULL
  )
  if (!is.null(perm_fit)) {
    perm_coefs[i] <- coef(perm_fit)["treat_perm"]
  } else {
    perm_coefs[i] <- NA
  }
}

ri_pvalue <- mean(abs(perm_coefs) >= abs(obs_coef), na.rm = TRUE)
cat(sprintf("  Observed coefficient: %.4f\n", obs_coef))
cat(sprintf("  RI p-value (two-sided): %.4f\n", ri_pvalue))

# ============================================================
# 10. Property Value DiD
# ============================================================
cat("\n=== Property Value DiD ===\n")

if (file.exists(file.path(data_dir, "land_registry_clean.csv"))) {
  lr <- fread(file.path(data_dir, "land_registry_clean.csv"))
  lr[, date := as.Date(date)]

  # Restrict to standard residential (PPD category A)
  lr_std <- lr[ppd_cat == "A" & !is.na(welsh)]

  # Property value DiD
  lr_std[, yq_factor := as.factor(yq)]
  lr_std[, district_factor := as.factor(district)]

  pv1 <- feols(log_price ~ treat | district_factor + yq_factor,
               data = lr_std,
               cluster = ~district_factor)
  cat(sprintf("  Property value DiD: %.4f (SE: %.4f, p: %.4f)\n",
              coef(pv1)["treat"], se(pv1)["treat"], fixest::pvalue(pv1)["treat"]))
  cat(sprintf("  Implied price change: %.2f%%\n",
              (exp(coef(pv1)["treat"]) - 1) * 100))

  # With property controls
  lr_std[, new_build_ind := as.integer(new_build == "Y")]
  lr_std[, freehold := as.integer(tenure == "F")]
  lr_std[, prop_type_factor := as.factor(prop_type)]

  pv2 <- feols(log_price ~ treat + new_build_ind + freehold + prop_type_factor |
               district_factor + yq_factor,
               data = lr_std,
               cluster = ~district_factor)
  cat(sprintf("  With controls: %.4f (SE: %.4f, p: %.4f)\n",
              coef(pv2)["treat"], se(pv2)["treat"], fixest::pvalue(pv2)["treat"]))

  saveRDS(list(pv_basic = pv1, pv_controls = pv2), file.path(data_dir, "property_results.rds"))
} else {
  cat("  No Land Registry data available.\n")
}

# ============================================================
# 10b. Early vs Late Post-Period (Reversal Timing)
# ============================================================
cat("\n=== Robustness: Early vs late post-period ===\n")

panel[, early_post := as.integer(ym >= as.Date("2023-09-01") & ym < as.Date("2024-03-01"))]
panel[, late_post := as.integer(ym >= as.Date("2024-03-01"))]
panel[, treat_early := welsh * early_post]
panel[, treat_late := welsh * late_post]

r5 <- feols(log_collisions ~ treat_early + treat_late | pfa + ym,
            data = panel, cluster = ~pfa)
cat(sprintf("  Early post (Sep23-Feb24): %.4f (SE: %.4f, p: %.4f)\n",
            coef(r5)["treat_early"], se(r5)["treat_early"], fixest::pvalue(r5)["treat_early"]))
cat(sprintf("  Late post (Mar24-Dec24):  %.4f (SE: %.4f, p: %.4f)\n",
            coef(r5)["treat_late"], se(r5)["treat_late"], fixest::pvalue(r5)["treat_late"]))

# ============================================================
# 11. Save All Robustness Results
# ============================================================
cat("\n=== Saving robustness results ===\n")

rob_results <- list(
  placebo_high_speed = p1,
  placebo_scotland = p2,
  placebo_fake_date = p3,
  excl_covid = r1,
  border_only = r2,
  nation_trends = r3,
  poisson = r4,
  ri_pvalue = ri_pvalue,
  ri_coefs = perm_coefs,
  obs_coef = obs_coef,
  early_late = r5
)

saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))

# Summary table
sink(file.path(tables_dir, "robustness_summary.txt"))
cat("=============================================\n")
cat("ROBUSTNESS AND PLACEBO RESULTS\n")
cat("=============================================\n\n")
cat("Placebo Tests:\n")
cat(sprintf("  40+ mph roads:    %.4f (p = %.4f) [should be null]\n",
            coef(p1)["treat"], fixest::pvalue(p1)["treat"]))
cat(sprintf("  Scotland:         %.4f (p = %.4f) [should be null]\n",
            coef(p2)["treat"], fixest::pvalue(p2)["treat"]))
cat(sprintf("  Fake Sept 2022:   %.4f (p = %.4f) [should be null]\n",
            coef(p3)["fake_treat"], fixest::pvalue(p3)["fake_treat"]))
cat(sprintf("\nRobustness:\n"))
cat(sprintf("  Excl. COVID:      %.4f (p = %.4f)\n",
            coef(r1)["treat"], fixest::pvalue(r1)["treat"]))
cat(sprintf("  Border PFAs only: %.4f (p = %.4f)\n",
            coef(r2)["treat"], fixest::pvalue(r2)["treat"]))
cat(sprintf("  Nation trends:    %.4f (p = %.4f)\n",
            coef(r3)["treat"], fixest::pvalue(r3)["treat"]))
if (!is.null(r4)) {
  cat(sprintf("  Poisson:          %.4f (p = %.4f)\n",
              coef(r4)["treat"], fixest::pvalue(r4)["treat"]))
}
cat(sprintf("\nRandomization Inference p-value: %.4f\n", ri_pvalue))
sink()

cat("  Saved robustness_results.rds and robustness_summary.txt\n")
cat("\n=== Robustness checks complete ===\n")
