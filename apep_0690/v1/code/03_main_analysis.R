## 03_main_analysis.R — Main Bartik DiD regressions
## Paper: apep_0690 — UK Office-to-Residential PD Rights

source("00_packages.R")
setwd(file.path(dirname(getwd()), "data"))

panel <- fread("analysis_panel.csv")
cat("Panel loaded:", nrow(panel), "rows\n")

# Drop rows missing office share (treatment variable)
panel <- panel[!is.na(office_share)]
cat("After dropping missing office_share:", nrow(panel), "rows,",
    uniqueN(panel$ons_code), "LAs\n")

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("\n=== Summary Statistics ===\n")

# Pre-period (2012) vs Post-period (2013+)
sum_pre <- panel[post == 0, .(
  net_additions_mean = mean(net_additions, na.rm = TRUE),
  net_additions_sd = sd(net_additions, na.rm = TRUE),
  additions_pc_mean = mean(additions_pc, na.rm = TRUE),
  additions_pc_sd = sd(additions_pc, na.rm = TRUE),
  avg_price_mean = mean(AveragePrice, na.rm = TRUE),
  avg_price_sd = sd(AveragePrice, na.rm = TRUE),
  flat_price_mean = mean(FlatPrice, na.rm = TRUE),
  flat_price_sd = sd(FlatPrice, na.rm = TRUE),
  office_share_mean = mean(office_share, na.rm = TRUE),
  office_share_sd = sd(office_share, na.rm = TRUE),
  n_obs = .N,
  n_las = uniqueN(ons_code)
)]

sum_post <- panel[post == 1, .(
  net_additions_mean = mean(net_additions, na.rm = TRUE),
  net_additions_sd = sd(net_additions, na.rm = TRUE),
  additions_pc_mean = mean(additions_pc, na.rm = TRUE),
  additions_pc_sd = sd(additions_pc, na.rm = TRUE),
  avg_price_mean = mean(AveragePrice, na.rm = TRUE),
  avg_price_sd = sd(AveragePrice, na.rm = TRUE),
  flat_price_mean = mean(FlatPrice, na.rm = TRUE),
  flat_price_sd = sd(FlatPrice, na.rm = TRUE),
  pdr_office_mean = mean(pdr_office, na.rm = TRUE),
  pdr_office_sd = sd(pdr_office, na.rm = TRUE),
  n_obs = .N,
  n_las = uniqueN(ons_code)
)]

cat("Pre-period (2012):", sum_pre$n_obs, "obs,", sum_pre$n_las, "LAs\n")
cat("Post-period (2013-2024):", sum_post$n_obs, "obs,", sum_post$n_las, "LAs\n")
cat(sprintf("Net additions: Pre=%.1f (%.1f), Post=%.1f (%.1f)\n",
            sum_pre$net_additions_mean, sum_pre$net_additions_sd,
            sum_post$net_additions_mean, sum_post$net_additions_sd))
cat(sprintf("Additions per 1K: Pre=%.2f (%.2f), Post=%.2f (%.2f)\n",
            sum_pre$additions_pc_mean, sum_pre$additions_pc_sd,
            sum_post$additions_pc_mean, sum_post$additions_pc_sd))

# ============================================================
# Table 2: Main Bartik DiD Results
# ============================================================
cat("\n=== Main Bartik DiD Regressions ===\n")

# Spec 1: Net additions (levels)
m1 <- feols(net_additions ~ office_x_post | ons_code + year,
            data = panel, cluster = "ons_code")

# Spec 2: Log net additions
m2 <- feols(log_additions ~ office_x_post | ons_code + year,
            data = panel, cluster = "ons_code")

# Spec 3: Additions per 1000 population
m3 <- feols(additions_pc ~ office_x_post | ons_code + year,
            data = panel, cluster = "ons_code")

# Spec 4: Log additions per capita
m4 <- feols(log_additions_pc ~ office_x_post | ons_code + year,
            data = panel, cluster = "ons_code")

cat("\n--- Main Results ---\n")
etable(m1, m2, m3, m4,
       headers = c("Net Add.", "Log Add.", "Add./1K", "Log Add./1K"),
       se.below = TRUE, signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1))

# ============================================================
# Table 3: Price Effects (Flats vs Houses)
# ============================================================
cat("\n=== Price Regressions ===\n")

# Flat prices
if ("log_FlatPrice" %in% names(panel)) {
  m_flat <- feols(log_FlatPrice ~ office_x_post | ons_code + year,
                  data = panel[!is.na(FlatPrice) & FlatPrice > 0],
                  cluster = "ons_code")

  m_avg <- feols(log_AveragePrice ~ office_x_post | ons_code + year,
                 data = panel[!is.na(AveragePrice) & AveragePrice > 0],
                 cluster = "ons_code")

  m_det <- feols(log_DetachedPrice ~ office_x_post | ons_code + year,
                 data = panel[!is.na(DetachedPrice) & DetachedPrice > 0],
                 cluster = "ons_code")

  m_ter <- feols(log_TerracedPrice ~ office_x_post | ons_code + year,
                 data = panel[!is.na(TerracedPrice) & TerracedPrice > 0],
                 cluster = "ons_code")

  cat("\n--- Price Effects ---\n")
  etable(m_avg, m_flat, m_det, m_ter,
         headers = c("Average", "Flat", "Detached", "Terraced"),
         se.below = TRUE, signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1))
}

# ============================================================
# Table 4: Event Study (dynamic Bartik)
# ============================================================
cat("\n=== Event Study ===\n")

# Create year dummies interacted with office share (omit year = 2012)
panel[, event_time_f := factor(event_time)]
panel[, event_time_f := relevel(event_time_f, ref = "-1")]

m_es <- feols(additions_pc ~ i(event_time, office_share, ref = -1) | ons_code + year,
              data = panel, cluster = "ons_code")

cat("Event study coefficients:\n")
print(summary(m_es))

# Extract coefficients for the event study
es_coefs <- as.data.table(broom::tidy(m_es, conf.int = TRUE))
es_coefs <- es_coefs[grepl("event_time", term)]
es_coefs[, event_year := as.integer(gsub("event_time::", "", gsub(":office_share", "", term)))]
es_coefs <- es_coefs[order(event_year)]
cat("\nEvent study summary:\n")
print(es_coefs[, .(event_year, estimate, std.error, p.value)])

# ============================================================
# Article 4 Triple-Difference
# ============================================================
cat("\n=== Article 4 Triple-Difference ===\n")

panel[, art4_x_office_x_post := article4 * office_share * post]
m_art4 <- feols(additions_pc ~ office_x_post + art4_x_office_x_post | ons_code + year,
                data = panel, cluster = "ons_code")

cat("Article 4 triple-diff:\n")
etable(m_art4, se.below = TRUE)

# ============================================================
# Save key results
# ============================================================

# Write diagnostics for validation
diagnostics <- list(
  n_treated = uniqueN(panel$ons_code[panel$office_share > median(panel$office_share, na.rm = TRUE)]),
  n_pre = uniqueN(panel$year[panel$post == 0]),
  n_obs = nrow(panel),
  n_las = uniqueN(panel$ons_code),
  n_years = uniqueN(panel$year),
  main_coef = coef(m3)["office_x_post"],
  main_se = se(m3)["office_x_post"],
  main_pval = pvalue(m3)["office_x_post"]
)
jsonlite::write_json(diagnostics, "diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics saved to data/diagnostics.json\n")

# Save regression objects for table generation
save(m1, m2, m3, m4, m_es, m_art4, panel, es_coefs,
     file = "regression_results.RData")
cat("Regression results saved.\n")

# Save price models if they exist
if (exists("m_flat")) {
  save(m_avg, m_flat, m_det, m_ter, file = "price_results.RData")
  cat("Price results saved.\n")
}
