## 03_main_analysis.R — First stage, reduced form, and 2SLS
## apep_0820: Gaussian Plume IV for Pollution and Test Scores

source("00_packages.R")

DATA_DIR <- normalizePath("../data", mustWork = FALSE)
TABLE_DIR <- normalizePath("../tables", mustWork = FALSE)
dir.create(TABLE_DIR, showWarnings = FALSE, recursive = TRUE)

df <- readRDS(file.path(DATA_DIR, "analysis_panel.rds"))
cat("Analysis panel:", nrow(df), "obs,", n_distinct(df$ncessch), "schools\n")

# ============================================================
# Prepare variables
# ============================================================
pre_sd_score <- sd(df$test_score, na.rm = TRUE)
cat("SD of test score:", round(pre_sd_score, 2), "\n")
cat("SD of pred_exposure:", round(sd(df$pred_exposure, na.rm = TRUE), 8), "\n")

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("\n=== Summary Statistics ===\n")

summ_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  "Variable & Mean & SD \\\\",
  "\\hline",
  sprintf("Math proficiency (\\%%) & %.1f & %.1f \\\\",
          mean(df$test_score, na.rm = TRUE), sd(df$test_score, na.rm = TRUE)),
  sprintf("Predicted exposure (std.) & %.3f & %.3f \\\\",
          mean(df$pred_exposure_std, na.rm = TRUE), sd(df$pred_exposure_std, na.rm = TRUE)),
  sprintf("Facilities within 50km & %.1f & %.1f \\\\",
          mean(df$n_facilities, na.rm = TRUE), sd(df$n_facilities, na.rm = TRUE)),
  sprintf("Mean distance to facility (km) & %.1f & %.1f \\\\",
          mean(df$mean_dist_km, na.rm = TRUE), sd(df$mean_dist_km, na.rm = TRUE)),
  ifelse("conc_so2" %in% names(df),
         sprintf("County SO\\textsubscript{2} (ppb) & %.2f & %.2f \\\\",
                 mean(df$conc_so2, na.rm = TRUE), sd(df$conc_so2, na.rm = TRUE)),
         ""),
  ifelse("conc_pm25" %in% names(df),
         sprintf("County PM\\textsubscript{2.5} ($\\mu$g/m$^3$) & %.2f & %.2f \\\\",
                 mean(df$conc_pm25, na.rm = TRUE), sd(df$conc_pm25, na.rm = TRUE)),
         ""),
  "\\hline",
  sprintf("Observations & \\multicolumn{2}{c}{%s} \\\\", format(nrow(df), big.mark = ",")),
  sprintf("Schools & \\multicolumn{2}{c}{%s} \\\\", format(n_distinct(df$ncessch), big.mark = ",")),
  sprintf("Years & \\multicolumn{2}{c}{%s} \\\\", paste(sort(unique(df$year)), collapse = ", ")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Sample restricted to U.S. public schools (grades 3--8) within 50km of at least one EPA-monitored major air-emitting facility. Math proficiency is the school-level percentage of students scoring at or above proficiency on state assessments (EdFacts). Predicted exposure is the Gaussian plume dispersion-model predicted ground-level concentration (arbitrary units) from all nearby facilities, based on plant-school geometry and ASOS wind patterns.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(summ_tex, file.path(TABLE_DIR, "tab1_summary.tex"))

# ============================================================
# Table 2: Main Results — Reduced Form
# ============================================================
cat("\n=== Main Results ===\n")

# Spec 1: School + Year FE
rf1 <- feols(test_score_std ~ pred_exposure_std | ncessch + year,
              data = df, cluster = ~fips_county)

# Spec 2: School + State×Year FE
rf2 <- feols(test_score_std ~ pred_exposure_std | ncessch + fips_state^year,
              data = df, cluster = ~fips_county)

# Spec 3: With county pollution control (if available)
if ("conc_so2" %in% names(df)) {
  rf3 <- feols(test_score_std ~ pred_exposure_std + conc_so2 | ncessch + year,
                data = df, cluster = ~fips_county)
} else {
  rf3 <- rf1
}

cat("RF1 (School+Year FE):\n")
cat("  beta:", round(coef(rf1)["pred_exposure_std"], 5), "\n")
cat("  SE:", round(se(rf1)["pred_exposure_std"], 5), "\n")
cat("  t:", round(coef(rf1)["pred_exposure_std"] / se(rf1)["pred_exposure_std"], 2), "\n")

cat("\nRF2 (School+State×Year FE):\n")
cat("  beta:", round(coef(rf2)["pred_exposure_std"], 5), "\n")
cat("  SE:", round(se(rf2)["pred_exposure_std"], 5), "\n")

# 2SLS: Use predicted exposure as IV for county-level SO2
if ("conc_so2" %in% names(df) && sum(!is.na(df$conc_so2)) > 100) {
  cat("\n=== 2SLS: Predicted Exposure → County SO2 → Test Scores ===\n")

  # First stage
  fs <- feols(conc_so2 ~ pred_exposure_std | ncessch + year,
               data = df, cluster = ~fips_county)
  fs_f <- summary(fs)$fstatistic
  if (!is.null(fs_f)) cat("First stage F:", round(fs_f, 2), "\n")

  # 2SLS
  iv1 <- feols(test_score_std ~ 1 | ncessch + year | conc_so2 ~ pred_exposure_std,
                data = df, cluster = ~fips_county)
  cat("2SLS beta:", round(coef(iv1)["fit_conc_so2"], 5), "\n")
  cat("2SLS SE:", round(se(iv1)["fit_conc_so2"], 5), "\n")
}

# Generate LaTeX
models_main <- list("RF: School+Year FE" = rf1, "RF: School+State×Year FE" = rf2)
if ("conc_so2" %in% names(df) && exists("iv1")) {
  models_main[["2SLS"]] <- iv1
}

msummary(models_main,
         output = file.path(TABLE_DIR, "tab2_main_results.tex"),
         stars = c('*' = 0.10, '**' = 0.05, '***' = 0.01),
         gof_map = c("nobs", "r.squared"),
         title = "Effect of Predicted Pollution Exposure on Math Proficiency",
         notes = c("Clustered standard errors at county level.",
                    "Dependent variable: standardized math proficiency.",
                    "Predicted exposure from Gaussian plume model."))

# ============================================================
# Save diagnostics
# ============================================================
beta_hat <- as.numeric(coef(rf1)["pred_exposure_std"])
se_hat <- as.numeric(se(rf1)["pred_exposure_std"])

diagnostics <- list(
  n_treated = n_distinct(df$ncessch[df$pred_exposure_std > 0]),
  n_pre = length(unique(df$year)) - 1,
  n_obs = nrow(df),
  n_schools = n_distinct(df$ncessch),
  n_counties = n_distinct(df$fips_county),
  beta_main = beta_hat,
  se_main = se_hat,
  pre_sd_score = pre_sd_score,
  sd_exposure = sd(df$pred_exposure, na.rm = TRUE)
)

jsonlite::write_json(diagnostics, file.path(DATA_DIR, "diagnostics.json"), auto_unbox = TRUE)
saveRDS(list(rf1 = rf1, rf2 = rf2), file.path(DATA_DIR, "main_models.rds"))

cat("\n=== Key Result ===\n")
cat("1 SD predicted exposure → ", round(beta_hat, 4), " SD test scores\n")
cat("95% CI: [", round(beta_hat - 1.96*se_hat, 4), ",", round(beta_hat + 1.96*se_hat, 4), "]\n")
cat("\n03_main_analysis.R COMPLETE\n")
