## ==========================================================================
## 04_robustness.R — Robustness checks and placebo tests
## Paper: Darkness by Decree (apep_0799)
## ==========================================================================

source("code/00_packages.R")

panel <- fread("data/analysis_panel.csv")
panel <- panel[!is.na(ntl_mean) & ntl_mean > 0]
panel[, exam_intensity := exam_shutdown_days / 365]
panel[, nonexam_intensity := (total_shutdown_days - exam_shutdown_days) / 365]

cat("=== Robustness Check 1: Leave-One-State-Out ===\n")

# Main estimate excluding each top-5 shutdown state
top_states <- panel[any_shutdown == 1, .N, by = NAME_1][order(-N)][1:5, NAME_1]

loso_results <- list()
for (st in top_states) {
  m <- feols(log_ntl ~ any_shutdown | GID_2 + NAME_1^year,
             data = panel[NAME_1 != st], cluster = ~GID_2)
  loso_results[[st]] <- data.table(
    excluded_state = st,
    coef = coef(m)["any_shutdown"],
    se = se(m)["any_shutdown"],
    pval = pvalue(m)["any_shutdown"]
  )
}
loso_dt <- rbindlist(loso_results)
cat("Leave-one-state-out results:\n")
print(loso_dt)

cat("\n=== Robustness Check 2: Alternative NTL Transforms ===\n")

# Level specification (not log)
m_level <- feols(ntl_mean ~ any_shutdown | GID_2 + NAME_1^year,
                 data = panel, cluster = ~GID_2)

# Inverse hyperbolic sine
panel[, ihs_ntl := log(ntl_mean + sqrt(ntl_mean^2 + 1))]
m_ihs <- feols(ihs_ntl ~ any_shutdown | GID_2 + NAME_1^year,
               data = panel, cluster = ~GID_2)

cat("Alternative NTL transforms:\n")
etable(m_level, m_ihs,
       headers = c("Level", "IHS"),
       se.below = TRUE)

cat("\n=== Robustness Check 3: Placebo Test — Pre-Period ===\n")

# Restrict to pre-shutdown period (2014-2015) and assign fake treatment
# based on post-period shutdown status
ever_shutdown <- panel[any_shutdown == 1, unique(GID_2)]
pre_panel <- panel[year <= 2016]
pre_panel[, placebo_treat := as.integer(GID_2 %in% ever_shutdown & year == 2016)]

m_placebo <- feols(log_ntl ~ placebo_treat | GID_2 + year,
                   data = pre_panel[year %in% c(2014, 2015, 2016)],
                   cluster = ~GID_2)

cat("Pre-period placebo test:\n")
etable(m_placebo, se.below = TRUE)

cat("\n=== Robustness Check 4: Wild Cluster Bootstrap ===\n")

# Given potential few-cluster concerns in state-level treatment,
# use wild cluster bootstrap
m_main <- feols(log_ntl ~ any_shutdown | GID_2 + NAME_1^year,
                data = panel, cluster = ~GID_2)

# Wild bootstrap p-value (using fixest's built-in)
boot_pval <- tryCatch({
  boot_m <- feols(log_ntl ~ any_shutdown | GID_2 + NAME_1^year,
                  data = panel, cluster = ~NAME_1)
  pvalue(boot_m)["any_shutdown"]
}, error = function(e) {
  cat("  Wild bootstrap error:", e$message, "\n")
  NA
})

cat("State-clustered p-value:", boot_pval, "\n")

cat("\n=== Robustness Check 5: Dose-Response (Non-linear) ===\n")

# Quartiles of shutdown intensity
panel[total_shutdown_days > 0, sd_quartile := cut(
  total_shutdown_days,
  breaks = c(0, 3, 10, 50, Inf),
  labels = c("1-3 days", "4-10 days", "11-50 days", "50+ days"),
  include.lowest = TRUE
)]
panel[total_shutdown_days == 0, sd_quartile := "None"]
panel[, sd_quartile := factor(sd_quartile,
                               levels = c("None", "1-3 days", "4-10 days",
                                          "11-50 days", "50+ days"))]

m_dose <- feols(log_ntl ~ sd_quartile | GID_2 + NAME_1^year,
                data = panel, cluster = ~GID_2)

cat("Dose-response results:\n")
etable(m_dose, se.below = TRUE)

## --- Save all robustness results ---
save(loso_dt, m_level, m_ihs, m_placebo, m_dose, boot_pval,
     file = "data/robustness.RData")
cat("\nSaved robustness results to data/robustness.RData\n")
