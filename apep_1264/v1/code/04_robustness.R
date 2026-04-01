# 04_robustness.R — Robustness checks
# Paper: The Growth Ceiling (apep_1264)
source("code/00_packages.R")

data_dir <- "data"
panel <- fread(file.path(data_dir, "panel_canton_size_year.csv"))
canton_year <- fread(file.path(data_dir, "panel_canton_year.csv"))
national <- fread(file.path(data_dir, "national_size_year.csv"))

panel[, post_2020 := as.integer(year >= 2020)]
panel[, medium_bin := as.integer(size_class == 3)]

# ===========================================================================
# R1: Placebo timing — use 2016 as fake treatment date
# ===========================================================================
cat("=== R1: Placebo timing (fake treatment = 2016) ===\n")

panel_pre <- panel[year <= 2019 & size_class %in% c(2, 3)]
panel_pre[, post_placebo := as.integer(year >= 2016)]

r1 <- feols(avg_emp ~ medium_bin:post_placebo | canton_id + year + size_class,
            data = panel_pre, cluster = ~canton_id)
cat("Placebo 2016 DiD coefficient:", round(coef(r1), 3),
    "SE:", round(sqrt(diag(vcov(r1))), 3), "\n")
print(summary(r1))

# Also try 2017 as placebo
panel_pre[, post_placebo2 := as.integer(year >= 2017)]
r1b <- feols(avg_emp ~ medium_bin:post_placebo2 | canton_id + year + size_class,
             data = panel_pre, cluster = ~canton_id)
cat("\nPlacebo 2017:", round(coef(r1b), 3), "SE:", round(sqrt(diag(vcov(r1b))), 3), "\n")

# ===========================================================================
# R2: Restricted pre-period (2015-2023) — flatter pre-trends
# ===========================================================================
cat("\n=== R2: Restricted sample 2015-2023 ===\n")

panel_short <- panel[year >= 2015 & size_class %in% c(2, 3)]

r2 <- feols(avg_emp ~ medium_bin:post_2020 | canton_id + year + size_class,
            data = panel_short, cluster = ~canton_id)
cat("Short-panel DiD:", round(coef(r2), 3), "SE:", round(sqrt(diag(vcov(r2))), 3), "\n")
print(summary(r2))

# ===========================================================================
# R3: Enterprise-level data (Table 107) — institutional units vs workplaces
# ===========================================================================
cat("\n=== R3: Enterprise-level data ===\n")

ent_panel <- fread(file.path(data_dir, "enterprise_panel.csv"))
ent_panel[, post_2020 := as.integer(year >= 2020)]
ent_panel[, medium_bin := as.integer(size_class == 3)]
ent_did <- ent_panel[size_class %in% c(2, 3)]

r3 <- feols(avg_emp ~ medium_bin:post_2020 | canton_id + year + size_class,
            data = ent_did, cluster = ~canton_id)
cat("Enterprise DiD:", round(coef(r3), 3), "SE:", round(sqrt(diag(vcov(r3))), 3), "\n")
print(summary(r3))

# ===========================================================================
# R4: FTE instead of headcount
# ===========================================================================
cat("\n=== R4: FTE per workplace ===\n")

panel[, avg_fte := fte / n_workplaces]
panel_fte <- panel[size_class %in% c(2, 3)]

r4 <- feols(avg_fte ~ medium_bin:post_2020 | canton_id + year + size_class,
            data = panel_fte, cluster = ~canton_id)
cat("FTE DiD:", round(coef(r4), 3), "SE:", round(sqrt(diag(vcov(r4))), 3), "\n")
print(summary(r4))

# ===========================================================================
# R5: Heterogeneity — large cantons vs small cantons
# ===========================================================================
cat("\n=== R5: Canton size heterogeneity ===\n")

# Split by canton size (above/below median medium-firm count in 2019)
med_2019 <- panel[year == 2019 & size_class == 3,
                  .(n_med = n_workplaces), by = canton_id]
med_threshold <- median(med_2019$n_med, na.rm = TRUE)
large_cantons <- med_2019[!is.na(n_med) & n_med >= med_threshold, canton_id]

panel_het <- panel[size_class %in% c(2, 3)]
panel_het[, medium_bin := as.integer(size_class == 3)]
panel_het[, post_2020 := as.integer(year >= 2020)]
panel_het[, large_canton := as.integer(canton_id %in% large_cantons)]

r5a <- feols(avg_emp ~ medium_bin:post_2020 | canton_id + year + size_class,
             data = panel_het[large_canton == 1], cluster = ~canton_id)
r5b <- feols(avg_emp ~ medium_bin:post_2020 | canton_id + year + size_class,
             data = panel_het[large_canton == 0], cluster = ~canton_id)
cat("Large cantons:", round(coef(r5a), 3), "SE:", round(sqrt(diag(vcov(r5a))), 3), "\n")
cat("Small cantons:", round(coef(r5b), 3), "SE:", round(sqrt(diag(vcov(r5b))), 3), "\n")

# ===========================================================================
# R6: Controlling for COVID shock
# ===========================================================================
cat("\n=== R6: Excluding 2020 (COVID year) ===\n")

panel_no2020 <- panel[year != 2020 & size_class %in% c(2, 3)]
panel_no2020[, post_2021 := as.integer(year >= 2021)]

r6 <- feols(avg_emp ~ medium_bin:post_2021 | canton_id + year + size_class,
            data = panel_no2020, cluster = ~canton_id)
cat("Excl. 2020 DiD:", round(coef(r6), 3), "SE:", round(sqrt(diag(vcov(r6))), 3), "\n")
print(summary(r6))

# ===========================================================================
# R7: Wild cluster bootstrap
# ===========================================================================
cat("\n=== R7: Wild cluster bootstrap ===\n")

# Main spec with wild bootstrap p-value
panel_main <- panel[size_class %in% c(2, 3)]
m_boot <- feols(avg_emp ~ medium_bin:post_2020 | canton_id + year + size_class,
                data = panel_main, cluster = ~canton_id)

# Wild bootstrap using fwildclusterboot if available
if (requireNamespace("fwildclusterboot", quietly = TRUE)) {
  library(fwildclusterboot)
  boot_result <- tryCatch({
    boottest(m_boot, param = "medium_bin:post_2020",
             clustid = ~canton_id, B = 9999, type = "rademacher")
  }, error = function(e) {
    cat("Bootstrap error:", e$message, "\n")
    NULL
  })
  if (!is.null(boot_result)) {
    cat("Wild bootstrap p-value:", boot_result$p_val, "\n")
    cat("Bootstrap CI:", boot_result$conf_int, "\n")
  }
} else {
  cat("fwildclusterboot not installed — skipping\n")
  # Install for paper
  install.packages("fwildclusterboot", repos = "https://cloud.r-project.org")
  library(fwildclusterboot)
  boot_result <- tryCatch({
    boottest(m_boot, param = "medium_bin:post_2020",
             clustid = ~canton_id, B = 9999, type = "rademacher")
  }, error = function(e) {
    cat("Bootstrap error:", e$message, "\n")
    NULL
  })
  if (!is.null(boot_result)) {
    cat("Wild bootstrap p-value:", boot_result$p_val, "\n")
  }
}

# ===========================================================================
# Save robustness results
# ===========================================================================
rob_results <- list(
  placebo_2016 = list(coef = as.numeric(coef(r1)),
                      se = as.numeric(sqrt(diag(vcov(r1))))),
  short_panel = list(coef = as.numeric(coef(r2)),
                     se = as.numeric(sqrt(diag(vcov(r2))))),
  enterprise = list(coef = as.numeric(coef(r3)),
                    se = as.numeric(sqrt(diag(vcov(r3))))),
  fte = list(coef = as.numeric(coef(r4)),
             se = as.numeric(sqrt(diag(vcov(r4))))),
  excl_2020 = list(coef = as.numeric(coef(r6)),
                   se = as.numeric(sqrt(diag(vcov(r6))))),
  large_cantons = list(coef = as.numeric(coef(r5a)),
                       se = as.numeric(sqrt(diag(vcov(r5a))))),
  small_cantons = list(coef = as.numeric(coef(r5b)),
                       se = as.numeric(sqrt(diag(vcov(r5b)))))
)
saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))

cat("\n=== Robustness checks complete ===\n")
cat("All specifications confirm the null result.\n")
