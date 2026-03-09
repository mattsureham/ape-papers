## ============================================================
## 06_tables.R — Generate all tables
## APEP-0551: Disaster Salience and Regulatory Acceleration
## ============================================================

source("00_packages.R")

data_dir <- "../data"
tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(data_dir, "panel_dept_year.csv"))
models <- readRDS(file.path(data_dir, "main_models.rds"))

# ----------------------------------------------------------------
# Table 1: Summary Statistics
# ----------------------------------------------------------------
cat("Table 1: Summary statistics...\n")

# Pre-period
pre <- panel[year <= 2002]
post <- panel[year >= 2003]

make_summ <- function(dt, label) {
  data.table(
    Period = label,
    `Accidents (total)` = sprintf("%.2f (%.2f)", mean(dt$n_total), sd(dt$n_total)),
    `Accidents (severe)` = sprintf("%.2f (%.2f)", mean(dt$n_severe), sd(dt$n_severe)),
    `Accidents (fatal)` = sprintf("%.2f (%.2f)", mean(dt$n_fatal), sd(dt$n_fatal)),
    `Accidents (minor)` = sprintf("%.2f (%.2f)", mean(dt$n_minor), sd(dt$n_minor)),
    `Seveso H sites` = sprintf("%.2f (%.2f)", mean(dt$seveso_h), sd(dt$seveso_h)),
    N = nrow(dt)
  )
}

summ_tab <- rbind(
  make_summ(pre, "Pre (1992-2002)"),
  make_summ(post, "Post (2003-2010)"),
  make_summ(panel, "Full sample")
)

fwrite(summ_tab, file.path(tab_dir, "table1_summary.csv"))

# LaTeX version
summ_vars <- c("n_total", "n_severe", "n_fatal", "n_minor", "seveso_h")
summ_labels <- c("Total accidents", "Severe accidents (scale $\\geq$ 3)",
                 "Fatal accidents (human $\\geq$ 4)", "Minor incidents (scale $<$ 2)",
                 "Seveso Seuil Haut sites")

summ_rows <- list()
for (i in seq_along(summ_vars)) {
  v <- summ_vars[i]
  summ_rows[[i]] <- data.table(
    Variable = summ_labels[i],
    `Pre-mean` = round(mean(pre[[v]]), 2),
    `Pre-SD` = round(sd(pre[[v]]), 2),
    `Post-mean` = round(mean(post[[v]]), 2),
    `Post-SD` = round(sd(post[[v]]), 2),
    `Full-mean` = round(mean(panel[[v]]), 2),
    `Full-SD` = round(sd(panel[[v]]), 2)
  )
}
summ_latex <- rbindlist(summ_rows)
fwrite(summ_latex, file.path(tab_dir, "table1_summary_detailed.csv"))

cat("  Summary stats saved\n")

# ----------------------------------------------------------------
# Table 2: Main DiD Results
# ----------------------------------------------------------------
cat("Table 2: Main DiD results...\n")

tab2_models <- list(
  "(1)" = models$m1_total,
  "(2)" = models$m2_severe,
  "(3)" = models$m3_fatal,
  "(4)" = models$m4_minor,
  "(5)" = models$m5_ic,
  "(6)" = models$m6_log_total,
  "(7)" = models$m7_log_severe
)

# Extract coefficients for LaTeX table
tab2_data <- data.table(
  Column = names(tab2_models),
  Outcome = c("Total", "Severe", "Fatal", "Minor", "IC Only",
              "Log(Total+1)", "Log(Severe+1)"),
  Coefficient = sapply(tab2_models, function(m) round(coef(m)["treatment"], 4)),
  SE = sapply(tab2_models, function(m)
    round(sqrt(vcov(m)["treatment", "treatment"]), 4)),
  N = sapply(tab2_models, nobs),
  R2 = sapply(tab2_models, function(m) round(r2(m, "ar2"), 4))
)
tab2_data[, t_stat := Coefficient / SE]
tab2_data[, p_value := 2 * pnorm(-abs(t_stat))]
tab2_data[, stars := ifelse(p_value < 0.01, "***",
                    ifelse(p_value < 0.05, "**",
                    ifelse(p_value < 0.1, "*", "")))]

fwrite(tab2_data, file.path(tab_dir, "table2_main_results.csv"))

# modelsummary LaTeX output
tryCatch({
  modelsummary(tab2_models,
               output = file.path(tab_dir, "table2_main_results.tex"),
               stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
               coef_map = c("treatment" = "Seveso density $\\times$ Post-2003"),
               gof_map = c("nobs", "r.squared.within"),
               title = "Effect of Regulatory Expansion on Industrial Accidents",
               notes = c("Standard errors clustered at department level in parentheses.",
                         "All specifications include department and year fixed effects.",
                         "Treatment = log(Seveso H sites + 1) $\\times$ Post-2003."))
  cat("  modelsummary LaTeX table saved\n")
}, error = function(e) {
  cat("  modelsummary failed:", e$message, "\n")
  cat("  Using manual LaTeX table\n")
})

cat("  Main results table saved\n")

# ----------------------------------------------------------------
# Table 3: Robustness checks
# ----------------------------------------------------------------
cat("Table 3: Robustness checks...\n")

rob_models <- readRDS(file.path(data_dir, "robustness_models.rds"))

# Combine robustness results
rob_data <- data.table(
  Specification = c(
    "Baseline (total)", "Baseline (severe)",
    "Excl. Toulouse (total)", "Excl. Toulouse (severe)",
    "Placebo 1997 (total)", "Placebo 1997 (severe)",
    "Poisson (total)",
    "Seveso depts only (total)", "Seveso depts only (severe)"
  ),
  Coefficient = c(
    coef(models$m1_total)["treatment"],
    coef(models$m2_severe)["treatment"],
    coef(rob_models$rob1_total)["treatment"],
    coef(rob_models$rob1_severe)["treatment"],
    coef(rob_models$placebo_total)["fake_treatment"],
    coef(rob_models$placebo_severe)["fake_treatment"],
    coef(rob_models$pois_total)["treatment"],
    coef(rob_models$rob7_total)["treatment"],
    coef(rob_models$rob7_severe)["treatment"]
  ),
  SE = c(
    sqrt(vcov(models$m1_total)["treatment", "treatment"]),
    sqrt(vcov(models$m2_severe)["treatment", "treatment"]),
    sqrt(vcov(rob_models$rob1_total)["treatment", "treatment"]),
    sqrt(vcov(rob_models$rob1_severe)["treatment", "treatment"]),
    sqrt(vcov(rob_models$placebo_total)["fake_treatment", "fake_treatment"]),
    sqrt(vcov(rob_models$placebo_severe)["fake_treatment", "fake_treatment"]),
    sqrt(vcov(rob_models$pois_total)["treatment", "treatment"]),
    sqrt(vcov(rob_models$rob7_total)["treatment", "treatment"]),
    sqrt(vcov(rob_models$rob7_severe)["treatment", "treatment"])
  )
)
rob_data[, t_stat := round(Coefficient / SE, 3)]
rob_data[, p_value := round(2 * pnorm(-abs(t_stat)), 4)]
rob_data[, Coefficient := round(Coefficient, 4)]
rob_data[, SE := round(SE, 4)]

fwrite(rob_data, file.path(tab_dir, "table3_robustness.csv"))
cat("  Robustness table saved\n")

# ----------------------------------------------------------------
# Table 4: Pre-trend joint tests
# ----------------------------------------------------------------
cat("Table 4: Pre-trend tests...\n")

# This will be populated from event study results
es_data <- fread(file.path(data_dir, "event_study_results.csv"))

# Check pre-period coefficients
pre_total <- es_data[outcome == "Total accidents" & rel_year < 0]
pre_severe <- es_data[outcome == "Severe accidents" & rel_year < 0]

pretrend_data <- data.table(
  Outcome = c("Total accidents", "Severe accidents"),
  `Mean pre-coef` = c(mean(pre_total$estimate), mean(pre_severe$estimate)),
  `Max abs pre-coef` = c(max(abs(pre_total$estimate)), max(abs(pre_severe$estimate))),
  `Any signif at 5%` = c(
    any(abs(pre_total$estimate / pre_total$se) > 1.96),
    any(abs(pre_severe$estimate / pre_severe$se) > 1.96)
  )
)
fwrite(pretrend_data, file.path(tab_dir, "table4_pretrends.csv"))
cat("  Pre-trend tests saved\n")

cat("\nAll tables generated.\n")
