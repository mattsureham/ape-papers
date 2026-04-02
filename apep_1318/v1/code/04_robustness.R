# 04_robustness.R — Robustness checks and placebos
# APEP-1318: Beneficial Ownership Transparency and Corporate Formation

source("00_packages.R")
load("../data/models.RData")
amld5 <- fread("../data/amld5_transposition_panel.csv")

cat("=== ROBUSTNESS CHECKS ===\n")

# ============================================================
# 1. Callaway-Sant'Anna Staggered DiD (avoids TWFE bias)
# ============================================================
cat("\n--- 1. Callaway-Sant'Anna Staggered DiD ---\n")

# Need: panel with unit ID, time period, treatment group (first treat year), outcome
panel[, unit_id := as.integer(factor(geo))]
panel[, time_period := (year - 2015) * 4 + quarter]  # continuous quarter index

# CS requires: gname = first treatment period (0 = never treated)
# All EU countries were treated (opened registers), so we have no pure never-treated
# For CS: use the REVERSAL as treatment — who rolled back
# Alternative: use late adopters (2021) vs early (2019)

# Design A: Early vs late adoption
panel[, cs_group := fifelse(register_open_year <= 2019, (2019 - 2015) * 4 + 1,
                     fifelse(register_open_year == 2020, (2020 - 2015) * 4 + 1,
                      fifelse(register_open_year >= 2021, (2021 - 2015) * 4 + 1, 0L)))]

# Some countries may not be in the data
cs_data <- panel[!is.na(reg_index) & !is.na(cs_group)]
cat("CS data:", nrow(cs_data), "rows,", length(unique(cs_data$unit_id)), "units\n")
cat("Treatment groups:", paste(sort(unique(cs_data$cs_group)), collapse = ", "), "\n")

cs_result <- tryCatch({
  att_gt(yname = "log_reg",
         gname = "cs_group",
         idname = "unit_id",
         tname = "time_period",
         data = as.data.frame(cs_data),
         control_group = "notyettreated",
         anticipation = 0,
         est_method = "reg")
}, error = function(e) {
  cat("CS estimation error:", e$message, "\n")
  NULL
})

if (!is.null(cs_result)) {
  cs_agg <- aggte(cs_result, type = "simple")
  cat("\nCS aggregate ATT:", round(cs_agg$overall.att, 4),
      "SE:", round(cs_agg$overall.se, 4),
      "p:", round(cs_agg$overall.att / cs_agg$overall.se, 3), "\n")

  # Event study aggregation
  cs_es <- tryCatch({
    aggte(cs_result, type = "dynamic", min_e = -8, max_e = 8)
  }, error = function(e) {
    cat("CS event study error:", e$message, "\n")
    NULL
  })
} else {
  cat("CS estimation failed.\n")
}

# ============================================================
# 2. Placebo: Manufacturing sector (should not respond to ownership transparency)
# ============================================================
cat("\n--- 2. Manufacturing Sector Placebo ---\n")

if ("log_reg_mfg" %in% names(panel)) {
  placebo_mfg <- feols(log_reg_mfg ~ register_public | geo + time_id,
                       data = panel[!is.na(log_reg_mfg)], cluster = ~geo)
  cat("Manufacturing placebo — register_public:\n")
  summary(placebo_mfg)

  placebo_mfg_rev <- feols(log_reg_mfg ~ rolled_back | geo + time_id,
                           data = panel[!is.na(log_reg_mfg) & year >= 2021], cluster = ~geo)
  cat("Manufacturing placebo — rolled_back:\n")
  summary(placebo_mfg_rev)
} else {
  cat("No manufacturing sector data available for placebo.\n")
}

# ============================================================
# 3. Financial sector (opacity-sensitive — should respond MORE)
# ============================================================
cat("\n--- 3. Financial Sector (Mechanism) ---\n")

if ("log_reg_finance" %in% names(panel)) {
  mech_fin <- feols(log_reg_finance ~ register_public | geo + time_id,
                    data = panel[!is.na(log_reg_finance)], cluster = ~geo)
  cat("Financial sector — register_public:\n")
  summary(mech_fin)

  mech_fin_rev <- feols(log_reg_finance ~ rolled_back | geo + time_id,
                        data = panel[!is.na(log_reg_finance) & year >= 2021], cluster = ~geo)
  cat("Financial sector — rolled_back:\n")
  summary(mech_fin_rev)
} else {
  cat("No financial sector data available.\n")
}

# ============================================================
# 4. Leave-one-out: Drop each rolled-back country
# ============================================================
cat("\n--- 4. Leave-One-Out (Dropped Country) ---\n")

rolled_back_countries <- amld5[!is.na(register_closed_year)]$geo
loo_results <- data.table()

for (drop_geo in rolled_back_countries) {
  m_loo <- feols(log_reg ~ register_public + rolled_back | geo + time_id,
                 data = panel[geo != drop_geo], cluster = ~geo)
  loo_results <- rbind(loo_results, data.table(
    dropped = drop_geo,
    adopt_coef = coef(m_loo)["register_public"],
    adopt_se = se(m_loo)["register_public"],
    reverse_coef = coef(m_loo)["rolled_back"],
    reverse_se = se(m_loo)["rolled_back"]
  ))
}

cat("Leave-one-out results:\n")
print(loo_results[, .(dropped,
                       adopt = paste0(round(adopt_coef, 3), " (", round(adopt_se, 3), ")"),
                       reverse = paste0(round(reverse_coef, 3), " (", round(reverse_se, 3), ")"))])

cat("\nAdoption coefficient range:", round(range(loo_results$adopt_coef), 3), "\n")
cat("Reversal coefficient range:", round(range(loo_results$reverse_coef), 3), "\n")

# ============================================================
# 5. Permutation inference (randomize rollback assignment)
# ============================================================
cat("\n--- 5. Permutation Inference ---\n")

set.seed(42)
n_perms <- 1000
perm_coefs <- numeric(n_perms)

# Actual rollback coefficient
actual_coef <- coef(feols(log_reg ~ rolled_back | geo + time_id,
                          data = panel[year >= 2021], cluster = ~geo))["rolled_back"]

# Permute rollback assignment across countries
countries <- unique(panel$geo)
n_rolled_back <- sum(!is.na(amld5[geo %in% countries]$register_closed_year))

for (i in seq_len(n_perms)) {
  # Randomly assign rollback to n_rolled_back countries
  fake_rb <- sample(countries, n_rolled_back)
  panel_perm <- copy(panel[year >= 2021])
  panel_perm[, fake_rolled_back := fifelse(geo %in% fake_rb & year >= 2022, 1L, 0L)]

  m_perm <- tryCatch({
    feols(log_reg ~ fake_rolled_back | geo + time_id, data = panel_perm, cluster = ~geo)
  }, error = function(e) NULL)

  if (!is.null(m_perm)) {
    perm_coefs[i] <- coef(m_perm)["fake_rolled_back"]
  } else {
    perm_coefs[i] <- NA
  }
}

perm_coefs <- perm_coefs[!is.na(perm_coefs)]
perm_p <- mean(abs(perm_coefs) >= abs(actual_coef))
cat("Actual reversal coefficient:", round(actual_coef, 4), "\n")
cat("Permutation p-value (two-sided):", round(perm_p, 3), "\n")
cat("Permutation distribution: mean =", round(mean(perm_coefs), 4),
    "SD =", round(sd(perm_coefs), 4), "\n")

# ============================================================
# 6. Pre-trends test (event study around adoption)
# ============================================================
cat("\n--- 6. Pre-Trends Event Study ---\n")

# Create event time relative to register opening
panel[, event_time := year - register_open_year]

# Bin event time at -4 and +3
panel[, event_time_binned := pmax(pmin(event_time, 3), -4)]

# Event study with fixest
es_model <- tryCatch({
  feols(log_reg ~ i(event_time_binned, ref = -1) | geo + time_id,
        data = panel, cluster = ~geo)
}, error = function(e) {
  cat("Event study error:", e$message, "\n")
  NULL
})

if (!is.null(es_model)) {
  cat("Event study coefficients:\n")
  summary(es_model)

  # Check pre-trends: are pre-period coefficients jointly zero?
  cat("\nPre-trend coefficients (event_time < 0, excl. -1):\n")
  pre_coefs <- coef(es_model)[grep("event_time_binned::-[2-4]", names(coef(es_model)))]
  cat("Pre-period coefficients:", round(pre_coefs, 4), "\n")
}

# ============================================================
# Save robustness results
# ============================================================
rob_results <- list(
  cs_agg_att = if (!is.null(cs_result)) round(aggte(cs_result, type = "simple")$overall.att, 4) else NA,
  cs_agg_se = if (!is.null(cs_result)) round(aggte(cs_result, type = "simple")$overall.se, 4) else NA,
  loo_adopt_range = round(range(loo_results$adopt_coef), 4),
  loo_reverse_range = round(range(loo_results$reverse_coef), 4),
  perm_p = round(perm_p, 3),
  actual_reversal = round(actual_coef, 4)
)

jsonlite::write_json(rob_results, "../data/robustness_results.json", auto_unbox = TRUE)
cat("\nRobustness results saved.\n")

# Save model objects for tables
objs_to_save <- c("placebo_mfg", "placebo_mfg_rev", "mech_fin", "mech_fin_rev",
                   "loo_results", "perm_coefs", "perm_p", "actual_coef", "es_model")
if (exists("cs_result")) objs_to_save <- c(objs_to_save, "cs_result")
if (exists("cs_agg")) objs_to_save <- c(objs_to_save, "cs_agg")
save(list = objs_to_save, file = "../data/robustness_models.RData")
cat("Robustness models saved.\n")
