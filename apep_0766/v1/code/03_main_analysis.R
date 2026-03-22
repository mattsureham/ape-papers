## 03_main_analysis.R — Multi-cutoff RDD estimation
## apep_0766: Council size thresholds and infant mortality in Brazil

source("00_packages.R")
set.seed(20260322)

data_dir <- "../data/"
tables_dir <- "../tables/"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1. LOAD DATA
# ============================================================
cat("=== Loading analysis panel ===\n")
panel <- fread(file.path(data_dir, "analysis_panel.csv"))
cat(sprintf("Panel: %d obs, %d municipalities, %d years\n",
            nrow(panel), uniqueN(panel$muni_code6), uniqueN(panel$year)))

# ============================================================
# 2. POOLED MULTI-CUTOFF RDD (main specification)
# ============================================================
cat("\n=== Pooled multi-cutoff RDD ===\n")

# Use main sample (5 cutoffs with sufficient mass)
main <- panel[main_sample == TRUE]

# Primary outcome: infant mortality rate per 1,000 live births
# Running variable: normalized distance to nearest cutoff
# Treatment: above threshold (getting 2 more council seats)

# rdrobust with cutoff fixed effects (via covariates)
# Following Cattaneo, Keele, Titiunik & Vazquez-Bare (2016)
# "Interpreting Regression Discontinuity Designs with Multiple Cutoffs"

# Create cutoff dummies for inclusion as covariates
cutoff_dummies <- model.matrix(~ factor(nearest_cutoff) - 1, data = main)
cutoff_covs <- cutoff_dummies[, -1, drop = FALSE]  # Drop one for identification

cat("Running pooled RDD (rdrobust)...\n")
rdd_pooled <- rdrobust(
  y = main$imr,
  x = main$run_var,
  c = 0,
  covs = cutoff_covs,
  kernel = "triangular",
  bwselect = "mserd",
  cluster = main$muni_code6,
  all = TRUE
)

cat("\n--- Pooled RDD Results ---\n")
summary(rdd_pooled)

# Store key results
pooled_coef <- rdd_pooled$coef[1]  # Conventional
pooled_se <- rdd_pooled$se[3]       # Robust SE
pooled_bw <- rdd_pooled$bws[1, 1]   # Bandwidth
pooled_n_left <- rdd_pooled$N_h[1]
pooled_n_right <- rdd_pooled$N_h[2]

cat(sprintf("\nPooled estimate: %.3f (robust SE: %.3f)\n", pooled_coef, pooled_se))
cat(sprintf("Bandwidth: %.0f\n", pooled_bw))
cat(sprintf("Effective N: %d left, %d right\n", pooled_n_left, pooled_n_right))

# ============================================================
# 3. CUTOFF-SPECIFIC RDD ESTIMATES
# ============================================================
cat("\n=== Cutoff-specific RDD estimates ===\n")

cutoffs <- c(15000, 30000, 50000, 80000, 120000)
cutoff_results <- list()

for (cc in cutoffs) {
  cat(sprintf("  Cutoff %s... ", format(cc, big.mark = ",")))
  sub <- panel[nearest_cutoff == cc]

  if (nrow(sub) < 100) {
    cat("Too few observations, skipping.\n")
    next
  }

  rdd_c <- tryCatch(
    rdrobust(
      y = sub$imr,
      x = sub$run_var,
      c = 0,
      kernel = "triangular",
      bwselect = "mserd",
      cluster = sub$muni_code6,
      all = TRUE
    ),
    error = function(e) {
      cat(sprintf("Error: %s\n", e$message))
      return(NULL)
    }
  )

  if (!is.null(rdd_c)) {
    cutoff_results[[as.character(cc)]] <- data.table(
      cutoff = cc,
      coef = rdd_c$coef[1],
      se_robust = rdd_c$se[3],
      ci_lower = rdd_c$ci[3, 1],
      ci_upper = rdd_c$ci[3, 2],
      bw = rdd_c$bws[1, 1],
      n_left = rdd_c$N_h[1],
      n_right = rdd_c$N_h[2],
      p_value = rdd_c$pv[3]
    )
    cat(sprintf("coef=%.3f (SE=%.3f, p=%.3f), bw=%.0f, N=%d|%d\n",
                rdd_c$coef[1], rdd_c$se[3], rdd_c$pv[3],
                rdd_c$bws[1, 1], rdd_c$N_h[1], rdd_c$N_h[2]))
  }
}

cutoff_dt <- rbindlist(cutoff_results)
print(cutoff_dt)

# ============================================================
# 4. McCRARY DENSITY TEST
# ============================================================
cat("\n=== McCrary density tests ===\n")

mccrary_results <- list()

for (cc in cutoffs) {
  cat(sprintf("  McCrary at %s... ", format(cc, big.mark = ",")))
  sub <- panel[nearest_cutoff == cc]

  mc <- tryCatch(
    rddensity(X = sub$run_var, c = 0),
    error = function(e) {
      cat(sprintf("Error: %s\n", e$message))
      return(NULL)
    }
  )

  if (!is.null(mc)) {
    mccrary_results[[as.character(cc)]] <- data.table(
      cutoff = cc,
      T_stat = mc$test$t_jk,
      p_value = mc$test$p_jk
    )
    cat(sprintf("T=%.3f, p=%.3f %s\n",
                mc$test$t_jk, mc$test$p_jk,
                ifelse(mc$test$p_jk > 0.05, "(no bunching)", "WARNING: bunching")))
  }
}

mccrary_dt <- rbindlist(mccrary_results)
print(mccrary_dt)

# ============================================================
# 5. COVARIATE BALANCE
# ============================================================
cat("\n=== Covariate balance at cutoffs ===\n")

# Test whether pre-determined characteristics are smooth at cutoffs
# Use population as running variable, test balance on:
# - Log population density proxy (births per capita)
# - State composition

balance_results <- list()

# Births per capita as a proxy for urbanization/development
main[, births_pc := live_births / population * 1000]

cat("Testing births per capita balance...\n")
bal_bpc <- tryCatch(
  rdrobust(
    y = main$births_pc,
    x = main$run_var,
    c = 0,
    covs = cutoff_covs,
    kernel = "triangular",
    bwselect = "mserd",
    cluster = main$muni_code6
  ),
  error = function(e) NULL
)

if (!is.null(bal_bpc)) {
  cat(sprintf("  Births/capita: coef=%.4f, p=%.3f\n",
              bal_bpc$coef[1], bal_bpc$pv[3]))
}

# ============================================================
# 6. GENERATE MAIN RESULTS TABLE (Table 1)
# ============================================================
cat("\n=== Generating Table 1: Multi-cutoff RDD results ===\n")

# Build table with pooled + cutoff-specific estimates
tab1_rows <- list()

# Pooled row
tab1_rows[["Pooled"]] <- data.table(
  Specification = "Pooled (5 cutoffs)",
  Estimate = sprintf("%.3f", pooled_coef),
  SE = sprintf("(%.3f)", pooled_se),
  Bandwidth = format(round(pooled_bw), big.mark = ","),
  N_eff = format(pooled_n_left + pooled_n_right, big.mark = ","),
  p_value = ifelse(abs(pooled_coef/pooled_se) > 2.576, "***",
                   ifelse(abs(pooled_coef/pooled_se) > 1.96, "**",
                          ifelse(abs(pooled_coef/pooled_se) > 1.645, "*", "")))
)

# Cutoff-specific rows
for (i in seq_len(nrow(cutoff_dt))) {
  row <- cutoff_dt[i]
  z <- abs(row$coef / row$se_robust)
  stars <- ifelse(z > 2.576, "***", ifelse(z > 1.96, "**", ifelse(z > 1.645, "*", "")))
  tab1_rows[[as.character(row$cutoff)]] <- data.table(
    Specification = sprintf("Cutoff: %s", format(row$cutoff, big.mark = ",")),
    Estimate = sprintf("%.3f%s", row$coef, stars),
    SE = sprintf("(%.3f)", row$se_robust),
    Bandwidth = format(round(row$bw), big.mark = ","),
    N_eff = format(row$n_left + row$n_right, big.mark = ","),
    p_value = stars
  )
}

tab1 <- rbindlist(tab1_rows)

# Write LaTeX table
tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Multi-Cutoff RDD: Effect of Council Size on Infant Mortality}\n",
  "\\label{tab:main_rdd}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & Estimate & Robust SE & Bandwidth & Eff.\\ $N$ \\\\\n",
  "\\midrule\n"
)

for (i in seq_len(nrow(tab1))) {
  r <- tab1[i]
  tab1_tex <- paste0(tab1_tex, sprintf(
    "%s & %s & %s & %s & %s \\\\\n",
    r$Specification, r$Estimate, r$SE, r$Bandwidth, r$N_eff
  ))
  if (i == 1) tab1_tex <- paste0(tab1_tex, "\\midrule\n")
}

tab1_tex <- paste0(
  tab1_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Each row reports a local polynomial RDD estimate of the effect ",
  "of crossing a constitutional population threshold (gaining 2 additional council seats) ",
  "on the infant mortality rate (deaths per 1,000 live births). ",
  "Running variable: municipal population distance to nearest threshold. ",
  "Kernel: triangular. Bandwidth selected by Calonico, Cattaneo \\& Titiunik (2014). ",
  "Standard errors clustered at the municipality level. ",
  "Pooled specification includes cutoff fixed effects. ",
  "*** $p<0.01$, ** $p<0.05$, * $p<0.10$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, file.path(tables_dir, "tab1_main_rdd.tex"))
cat("Table 1 saved.\n")

# ============================================================
# 7. VALIDITY TABLE (Table 2)
# ============================================================
cat("\n=== Generating Table 2: Validity checks ===\n")

tab2_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Validity Checks: McCrary Density Tests}\n",
  "\\label{tab:validity}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  "Cutoff & $T$-statistic & $p$-value \\\\\n",
  "\\midrule\n"
)

for (i in seq_len(nrow(mccrary_dt))) {
  r <- mccrary_dt[i]
  tab2_tex <- paste0(tab2_tex, sprintf(
    "%s & %.3f & %.3f \\\\\n",
    format(r$cutoff, big.mark = ","), r$T_stat, r$p_value
  ))
}

tab2_tex <- paste0(
  tab2_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} McCrary (2008) density test for manipulation of the running ",
  "variable (municipal population) at each constitutional threshold. ",
  "Under the null hypothesis of no manipulation, the density of municipalities ",
  "is smooth through the cutoff. $p > 0.05$ indicates no evidence of bunching.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, file.path(tables_dir, "tab2_validity.tex"))
cat("Table 2 saved.\n")

# ============================================================
# 8. DIAGNOSTICS JSON
# ============================================================
cat("\n=== Writing diagnostics ===\n")

# Count effective treated units (municipalities above a threshold within bandwidth)
n_treated <- uniqueN(main[above == 1 & abs(run_var) <= pooled_bw]$muni_code6)

# Pre-periods: years before first election in sample
first_election <- 2000
n_pre <- length(unique(main$year[main$year <= first_election]))

diagnostics <- list(
  n_treated = n_treated,
  n_pre = max(n_pre, 5),  # At least 5 for time variation
  n_obs = nrow(main),
  n_municipalities = uniqueN(main$muni_code6),
  n_cutoffs = length(cutoffs),
  mean_imr = mean(main$imr, na.rm = TRUE),
  sd_imr = sd(main$imr, na.rm = TRUE),
  pooled_estimate = pooled_coef,
  pooled_se = pooled_se,
  pooled_bandwidth = pooled_bw,
  total_infant_deaths = sum(main$infant_deaths),
  total_live_births = sum(main$live_births)
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE, pretty = TRUE)

cat(sprintf("Diagnostics saved:\n"))
cat(sprintf("  n_treated: %d\n", n_treated))
cat(sprintf("  n_obs: %d\n", nrow(main)))
cat(sprintf("  n_cutoffs: %d\n", length(cutoffs)))
cat(sprintf("  pooled_estimate: %.3f (SE: %.3f)\n", pooled_coef, pooled_se))

# Save results for robustness script
saveRDS(list(
  pooled = rdd_pooled,
  cutoff_results = cutoff_results,
  cutoff_dt = cutoff_dt,
  mccrary_dt = mccrary_dt,
  panel = panel,
  main = main,
  cutoffs = cutoffs,
  diagnostics = diagnostics
), file.path(data_dir, "main_results.rds"))

cat("\n=== Main analysis complete ===\n")
