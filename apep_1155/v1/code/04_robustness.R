## 04_robustness.R — Robustness checks for apep_1155

source("00_packages.R")
data_dir <- "../data/"

panel <- readRDS(file.path(data_dir, "panel.rds"))
muni_data <- readRDS(file.path(data_dir, "muni_data.rds"))

# ============================================================
# 1. Placebo treatment dates
# ============================================================
cat("=== Placebo Tests ===\n")

# Placebo 1: Assign truce to 2005 (pre-2012 subsample only)
panel_pre <- panel[year < 2012]
panel_pre[, placebo_truce_05 := as.integer(year %in% c(2005, 2006))]
panel_pre[, placebo_post_05 := as.integer(year >= 2007)]

placebo_2005 <- feols(hom_rate ~ gang_intensity_std:placebo_truce_05 +
                        gang_intensity_std:placebo_post_05 | muni_id + year,
                      data = panel_pre, cluster = ~muni_id)

# Placebo 2: Assign truce to 2008 (pre-2012 subsample only)
panel_pre[, placebo_truce_08 := as.integer(year %in% c(2008, 2009))]
panel_pre[, placebo_post_08 := as.integer(year >= 2010)]

placebo_2008 <- feols(hom_rate ~ gang_intensity_std:placebo_truce_08 +
                        gang_intensity_std:placebo_post_08 | muni_id + year,
                      data = panel_pre, cluster = ~muni_id)

cat("  Placebo 2005:\n"); print(coeftable(placebo_2005))
cat("  Placebo 2008:\n"); print(coeftable(placebo_2008))

# ============================================================
# 2. Alternative treatment: pre-truce homicide rate
# ============================================================
cat("\n=== Alternative Treatment: Pre-Truce Homicide Rate ===\n")

# Average homicide rate 2005-2011 as treatment intensity
pre_hom <- panel[year >= 2005 & year <= 2011,
                 .(avg_hom_pre = mean(hom_rate, na.rm = TRUE)), by = muni_id]
panel <- merge(panel, pre_hom, by = "muni_id", all.x = TRUE)
panel[, avg_hom_pre_std := (avg_hom_pre - mean(avg_hom_pre, na.rm = TRUE)) /
        sd(avg_hom_pre, na.rm = TRUE)]

m_alt_treat <- feols(hom_rate ~ avg_hom_pre_std:truce + avg_hom_pre_std:post_collapse |
                       muni_id + year,
                     data = panel, cluster = ~muni_id)
cat("  Alternative treatment:\n"); print(coeftable(m_alt_treat))

# ============================================================
# 3. Department × Year FE
# ============================================================
cat("\n=== Department × Year Fixed Effects ===\n")

m_dept_yr <- feols(hom_rate ~ gang_intensity_std:truce + gang_intensity_std:post_collapse |
                     muni_id + dept_name^year,
                   data = panel, cluster = ~muni_id)
cat("  Dept×Year FE:\n"); print(coeftable(m_dept_yr))

# ============================================================
# 4. Leave-one-department-out
# ============================================================
cat("\n=== Leave-One-Department-Out ===\n")

depts <- unique(panel$dept_name)
lodo_results <- data.table(
  dept_excluded = character(),
  beta_truce = numeric(),
  se_truce = numeric(),
  beta_collapse = numeric(),
  se_collapse = numeric()
)

for (d in depts) {
  m_lodo <- feols(hom_rate ~ gang_intensity_std:truce + gang_intensity_std:post_collapse |
                    muni_id + year,
                  data = panel[dept_name != d], cluster = ~muni_id)
  ct <- coeftable(m_lodo)
  lodo_results <- rbind(lodo_results, data.table(
    dept_excluded = d,
    beta_truce = ct[1, "Estimate"],
    se_truce = ct[1, "Std. Error"],
    beta_collapse = ct[2, "Estimate"],
    se_collapse = ct[2, "Std. Error"]
  ))
}

cat("  LODO range (truce β):", sprintf("[%.3f, %.3f]",
    min(lodo_results$beta_truce), max(lodo_results$beta_truce)), "\n")
cat("  LODO range (collapse β):", sprintf("[%.3f, %.3f]",
    min(lodo_results$beta_collapse), max(lodo_results$beta_collapse)), "\n")

# ============================================================
# 5. Tercile treatment
# ============================================================
cat("\n=== Tercile Treatment ===\n")

# Use unique quantile breaks to avoid ties at zero
q33 <- quantile(panel$gang_intensity[panel$gang_intensity > 0], 0.5, na.rm = TRUE)
panel[, gang_tercile := fifelse(gang_intensity == 0, "Zero",
                                fifelse(gang_intensity <= q33, "Low", "High"))]

m_tercile <- feols(hom_rate ~ i(gang_tercile, truce, ref = "Zero") +
                     i(gang_tercile, post_collapse, ref = "Zero") | muni_id + year,
                   data = panel, cluster = ~muni_id)
cat("  Tercile results:\n"); print(coeftable(m_tercile))

# ============================================================
# 6. Log outcome
# ============================================================
cat("\n=== Log Outcome ===\n")

m_log <- feols(log_hom ~ gang_intensity_std:truce + gang_intensity_std:post_collapse |
                 muni_id + year,
               data = panel, cluster = ~muni_id)
cat("  Log homicide rate:\n"); print(coeftable(m_log))

# ============================================================
# 7. Wild cluster bootstrap (department level)
# ============================================================
cat("\n=== Wild Cluster Bootstrap ===\n")

tryCatch({
  m_base <- feols(hom_rate ~ gang_intensity_std:truce + gang_intensity_std:post_collapse |
                    muni_id + year, data = panel)

  boot_truce <- boottest(m_base,
                         param = "gang_intensity_std:truce",
                         clustid = ~dept_name,
                         B = 9999, type = "webb")
  cat("  Truce: bootstrap p =", boot_truce$p_val,
      "CI =", boot_truce$conf_int, "\n")

  boot_collapse <- boottest(m_base,
                            param = "gang_intensity_std:post_collapse",
                            clustid = ~dept_name,
                            B = 9999, type = "webb")
  cat("  Collapse: bootstrap p =", boot_collapse$p_val,
      "CI =", boot_collapse$conf_int, "\n")
}, error = function(e) {
  cat("  Wild bootstrap failed:", e$message, "\n")
})

# ============================================================
# 8. Poisson regression (count outcome)
# ============================================================
cat("\n=== Poisson Regression ===\n")

# Approximate count with offset for population
panel[, log_pop := log(population)]
tryCatch({
  m_poisson <- fepois(hom_count ~ gang_intensity_std:truce + gang_intensity_std:post_collapse |
                        muni_id + year,
                      data = panel[hom_count >= 0 & !is.na(hom_count)],
                      cluster = ~muni_id)
  cat("  Poisson:\n"); print(coeftable(m_poisson))
}, error = function(e) {
  cat("  Poisson failed:", e$message, "\n")
  m_poisson <<- NULL
})

# ============================================================
# 9. Save all robustness results
# ============================================================
rob_results <- list(
  placebo_2005 = placebo_2005,
  placebo_2008 = placebo_2008,
  m_alt_treat = m_alt_treat,
  m_dept_yr = m_dept_yr,
  lodo_results = lodo_results,
  m_tercile = m_tercile,
  m_log = m_log
)

saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))
cat("\n=== Robustness checks complete ===\n")
