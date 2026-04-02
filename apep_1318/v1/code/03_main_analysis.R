# 03_main_analysis.R — Main regressions
# APEP-1318: Beneficial Ownership Transparency and Corporate Formation

source("00_packages.R")

panel <- fread("../data/analysis_panel.csv")
fdi_panel <- fread("../data/fdi_panel.csv")
amld5 <- fread("../data/amld5_transposition_panel.csv")

cat("Panel loaded:", nrow(panel), "rows,", length(unique(panel$geo)), "countries\n")

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================
cat("\n=== TABLE 1: Summary Statistics ===\n")

# Pre-reform (2015-2018), transparency period (2020-2021), post-CJEU (2023)
panel[, period := fifelse(year <= 2018, "Pre-reform",
                   fifelse(year >= 2020 & year <= 2021, "Transparency",
                    fifelse(year >= 2023, "Post-CJEU", "Transition")))]

sumstats <- panel[period != "Transition", .(
  mean_reg = round(mean(reg_index, na.rm = TRUE), 1),
  sd_reg = round(sd(reg_index, na.rm = TRUE), 1),
  n_obs = .N,
  n_countries = length(unique(geo))
), by = period]

cat("\nSummary by period:\n")
print(sumstats)

# By treatment group (rolled back vs maintained)
panel[, group := fifelse(!is.na(register_closed_year), "Rolled Back", "Maintained")]
sumstats_group <- panel[, .(
  mean_reg = round(mean(reg_index, na.rm = TRUE), 1),
  sd_reg = round(sd(reg_index, na.rm = TRUE), 1),
  n_countries = length(unique(geo))
), by = .(group, period = fifelse(year <= 2018, "Pre-reform",
                           fifelse(year >= 2020 & year <= 2021, "Transparency",
                            fifelse(year >= 2023, "Post-CJEU", "Transition"))))]

cat("\nBy treatment group and period:\n")
print(sumstats_group[period != "Transition"][order(group, period)])

# ============================================================
# TABLE 2: Main DiD — Effect of Public Register on Registrations
# ============================================================
cat("\n=== TABLE 2: Main DiD Regressions ===\n")

# Model 1: Basic TWFE (country + quarter FEs)
# Create time period variable for FEs
panel[, time_id := as.integer(factor(paste0(year, "Q", quarter)))]

m1 <- feols(log_reg ~ register_public | geo + time_id, data = panel, cluster = ~geo)
cat("\nModel 1 — TWFE (country + time FEs):\n")
summary(m1)

# Model 2: Add country-specific linear trends
panel[, geo_num := as.integer(factor(geo))]
panel[, trend := year - 2015 + (quarter - 1) / 4]

m2 <- feols(log_reg ~ register_public + i(geo_num, trend) | geo + time_id, data = panel, cluster = ~geo)
cat("\nModel 2 — TWFE + country trends:\n")
summary(m2)

# ============================================================
# TABLE 3: Reversal DiD — Effect of Rolling Back Transparency
# ============================================================
cat("\n=== TABLE 3: Reversal DiD ===\n")

# Restrict to post-AMLD5 period (all countries treated by 2021)
# Compare rolled-back vs maintained countries, post-CJEU
panel_post <- panel[year >= 2021]

m3 <- feols(log_reg ~ rolled_back | geo + time_id, data = panel_post, cluster = ~geo)
cat("\nModel 3 — Reversal DiD (post-2021, rolled_back treatment):\n")
summary(m3)

# Model 4: Full specification with both adoption and reversal
m4 <- feols(log_reg ~ register_public + rolled_back | geo + time_id, data = panel, cluster = ~geo)
cat("\nModel 4 — Full specification (adoption + reversal):\n")
summary(m4)

# ============================================================
# TABLE 4: Heterogeneity by Financial Secrecy Index
# ============================================================
cat("\n=== TABLE 4: Heterogeneity by FSI ===\n")

# Interaction with high secrecy
m5_adopt <- feols(log_reg ~ register_public * high_secrecy | geo + time_id,
                  data = panel, cluster = ~geo)
cat("\nModel 5 — Adoption × High Secrecy:\n")
summary(m5_adopt)

m5_reverse <- feols(log_reg ~ rolled_back * high_secrecy | geo + time_id,
                    data = panel_post, cluster = ~geo)
cat("\nModel 5b — Reversal × High Secrecy:\n")
summary(m5_reverse)

# ============================================================
# TABLE 5 (secondary): FDI Panel (annual, 2008-2023)
# ============================================================
cat("\n=== TABLE 5: FDI Regressions ===\n")

fdi_clean <- fdi_panel[!is.na(fdi) & fdi > 0]
fdi_clean[, log_fdi := log(fdi)]

m6 <- feols(log_fdi ~ register_public | geo + year, data = fdi_clean, cluster = ~geo)
cat("\nModel 6 — FDI and register transparency:\n")
summary(m6)

m7 <- feols(log_fdi ~ register_public + rolled_back | geo + year, data = fdi_clean, cluster = ~geo)
cat("\nModel 7 — FDI full specification:\n")
summary(m7)

# ============================================================
# Save diagnostics
# ============================================================
n_treated <- length(unique(panel[!is.na(register_closed_year)]$geo))
n_pre <- length(unique(panel[year < 2019]$time_id))
n_obs <- nrow(panel)

diag <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_countries = length(unique(panel$geo)),
  n_quarters = length(unique(panel$time_id)),
  main_coef = round(coef(m1)["register_public"], 4),
  main_se = round(se(m1)["register_public"], 4),
  reversal_coef = round(coef(m3)["rolled_back"], 4),
  reversal_se = round(se(m3)["rolled_back"], 4)
)

jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics saved.\n")
cat("n_treated:", diag$n_treated, "\n")
cat("n_pre:", diag$n_pre, "\n")
cat("n_obs:", diag$n_obs, "\n")
cat("Main coefficient (register_public):", diag$main_coef, "(SE:", diag$main_se, ")\n")
cat("Reversal coefficient (rolled_back):", diag$reversal_coef, "(SE:", diag$reversal_se, ")\n")

# Save all model objects for table generation
save(m1, m2, m3, m4, m5_adopt, m5_reverse, m6, m7, panel, panel_post, fdi_clean,
     file = "../data/models.RData")
cat("Models saved to models.RData\n")
