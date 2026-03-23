## ==========================================================================
## 03_main_analysis.R — Main regressions: shutdown → nightlights
## Paper: Darkness by Decree (apep_0799)
## ==========================================================================

source("code/00_packages.R")

cat("=== Load Analysis Panel ===\n")
panel <- fread("data/analysis_panel.csv")
cat("Loaded:", nrow(panel), "obs,", uniqueN(panel$GID_2), "districts,",
    length(unique(panel$year)), "years\n")

## Drop rows with missing NTL
panel <- panel[!is.na(ntl_mean) & ntl_mean > 0]
cat("After dropping missing/zero NTL:", nrow(panel), "obs\n")

## =====================================================================
## TABLE 1: Summary Statistics
## =====================================================================
cat("\n=== Table 1: Summary Statistics ===\n")

# Panel A: Full sample
summary_vars <- c("ntl_mean", "n_shutdowns", "total_shutdown_days",
                   "any_shutdown", "any_exam_shutdown")

summ_all <- panel[, .(
  Variable = c("Nighttime lights (mean radiance)",
               "Number of shutdowns", "Total shutdown days",
               "Any shutdown (0/1)", "Any exam shutdown (0/1)"),
  Mean = sapply(.SD, mean, na.rm = TRUE),
  SD = sapply(.SD, sd, na.rm = TRUE),
  Min = sapply(.SD, min, na.rm = TRUE),
  Max = sapply(.SD, max, na.rm = TRUE),
  N = sapply(.SD, function(x) sum(!is.na(x)))
), .SDcols = summary_vars]

cat("Panel A: Full Sample\n")
print(summ_all)

# Panel B: by shutdown status
summ_by <- panel[, .(
  mean_ntl = mean(ntl_mean, na.rm = TRUE),
  sd_ntl = sd(ntl_mean, na.rm = TRUE),
  n_obs = .N,
  n_districts = uniqueN(GID_2)
), by = any_shutdown]

cat("\nPanel B: By Shutdown Status\n")
print(summ_by)

## =====================================================================
## TABLE 2: Main Results — TWFE
## =====================================================================
cat("\n=== Table 2: Main TWFE Results ===\n")

## --- Specification 1: Binary treatment, full sample ---
m1 <- feols(log_ntl ~ any_shutdown | GID_2 + year,
            data = panel, cluster = ~GID_2)

## --- Specification 2: Continuous treatment (shutdown days) ---
m2 <- feols(log_ntl ~ shutdown_intensity | GID_2 + year,
            data = panel, cluster = ~GID_2)

## --- Specification 3: With state × year FE ---
m3 <- feols(log_ntl ~ any_shutdown | GID_2 + NAME_1^year,
            data = panel, cluster = ~GID_2)

## --- Specification 4: Continuous with state × year FE ---
m4 <- feols(log_ntl ~ shutdown_intensity | GID_2 + NAME_1^year,
            data = panel, cluster = ~GID_2)

## --- Specification 5: Excluding J&K ---
m5 <- feols(log_ntl ~ any_shutdown | GID_2 + NAME_1^year,
            data = panel[is_jk == 0], cluster = ~GID_2)

## --- Specification 6: Excluding J&K, continuous ---
m6 <- feols(log_ntl ~ shutdown_intensity | GID_2 + NAME_1^year,
            data = panel[is_jk == 0], cluster = ~GID_2)

cat("Main results:\n")
etable(m1, m2, m3, m4, m5, m6,
       headers = c("(1)", "(2)", "(3)", "(4)", "(5)", "(6)"),
       dict = c(any_shutdown = "Any Shutdown",
                shutdown_intensity = "Shutdown Intensity"),
       se.below = TRUE)

## =====================================================================
## TABLE 3: Exam Shutdowns (Exogenous Subsample)
## =====================================================================
cat("\n=== Table 3: Exam Shutdown Identification ===\n")

## --- Only exam shutdowns ---
m_exam1 <- feols(log_ntl ~ any_exam_shutdown | GID_2 + year,
                 data = panel, cluster = ~GID_2)

m_exam2 <- feols(log_ntl ~ any_exam_shutdown | GID_2 + NAME_1^year,
                 data = panel, cluster = ~GID_2)

## --- Exam shutdown days ---
panel[, exam_intensity := exam_shutdown_days / 365]

m_exam3 <- feols(log_ntl ~ exam_intensity | GID_2 + NAME_1^year,
                 data = panel, cluster = ~GID_2)

## --- Exam vs non-exam shutdowns ---
panel[, nonexam_intensity := (total_shutdown_days - exam_shutdown_days) / 365]

m_exam4 <- feols(log_ntl ~ exam_intensity + nonexam_intensity | GID_2 + NAME_1^year,
                 data = panel, cluster = ~GID_2)

cat("Exam shutdown results:\n")
etable(m_exam1, m_exam2, m_exam3, m_exam4,
       headers = c("(1)", "(2)", "(3)", "(4)"),
       se.below = TRUE)

## =====================================================================
## TABLE 4: Heterogeneity
## =====================================================================
cat("\n=== Table 4: Heterogeneity ===\n")

## --- Duration heterogeneity ---
panel[, long_shutdown := as.integer(total_shutdown_days > 30)]
panel[, short_shutdown := as.integer(any_shutdown == 1 & total_shutdown_days <= 30)]

m_het1 <- feols(log_ntl ~ short_shutdown + long_shutdown | GID_2 + NAME_1^year,
                data = panel, cluster = ~GID_2)

## --- By cause ---
panel[, protest_shutdown := as.integer(n_protest_shutdowns > 0)]
panel[, political_shutdown := as.integer(n_political_shutdowns > 0)]

m_het2 <- feols(log_ntl ~ protest_shutdown + political_shutdown +
                  any_exam_shutdown | GID_2 + NAME_1^year,
                data = panel, cluster = ~GID_2)

## --- Frequency (number of shutdowns) ---
panel[, many_shutdowns := as.integer(n_shutdowns >= 5)]
panel[, few_shutdowns := as.integer(n_shutdowns > 0 & n_shutdowns < 5)]

m_het3 <- feols(log_ntl ~ few_shutdowns + many_shutdowns | GID_2 + NAME_1^year,
                data = panel, cluster = ~GID_2)

cat("Heterogeneity results:\n")
etable(m_het1, m_het2, m_het3,
       headers = c("Duration", "Cause", "Frequency"),
       se.below = TRUE)

## =====================================================================
## DIAGNOSTICS
## =====================================================================
cat("\n=== Diagnostics ===\n")

# Treatment starts 2016, but became substantial in 2017
# Pre-treatment: 2012-2016 (5 years) — 2016 has partial treatment (75 districts)
n_treated <- uniqueN(panel[any_shutdown == 1, GID_2])
n_pre <- length(unique(panel$year[panel$year < 2017]))
n_obs <- nrow(panel)

cat("Treated districts:", n_treated, "\n")
cat("Pre-periods:", n_pre, "\n")
cat("Total observations:", n_obs, "\n")

## Save diagnostics
diag <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_districts = uniqueN(panel$GID_2),
  n_years = length(unique(panel$year)),
  main_coef = coef(m3)["any_shutdown"],
  main_se = se(m3)["any_shutdown"],
  main_pval = pvalue(m3)["any_shutdown"],
  exam_coef = coef(m_exam2)["any_exam_shutdown"],
  exam_se = se(m_exam2)["any_exam_shutdown"],
  sd_y = sd(panel$log_ntl, na.rm = TRUE)
)

write_json(diag, "data/diagnostics.json", auto_unbox = TRUE)
cat("Saved diagnostics to data/diagnostics.json\n")

## Save models for tables script
save(m1, m2, m3, m4, m5, m6, m_exam1, m_exam2, m_exam3, m_exam4,
     m_het1, m_het2, m_het3, panel,
     file = "data/models.RData")
cat("Saved models to data/models.RData\n")
