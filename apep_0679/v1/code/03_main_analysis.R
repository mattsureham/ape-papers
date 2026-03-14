## 03_main_analysis.R — Main regressions
## apep_0679: Apprenticeship Levy and Entry-Level Training Crowding Out
##
## Bartik shift-share DiD:
##   log(Starts)_{lt} = alpha_l + gamma_t + beta * (LevyExposure_l x Post_t) + epsilon
##
## Treatment: April 2017 Apprenticeship Levy (0.5% payroll tax on >£3M employers)
## Instrument: Share of 250+ employee enterprises in 2016 (pre-Levy)
## Panel: 2010/11 to 2019/20 (7 pre, 3 post)

source("00_packages.R")

paper_dir <- dirname(getwd())
data_dir <- file.path(paper_dir, "data")
tables_dir <- file.path(paper_dir, "tables")
dir.create(tables_dir, showWarnings = FALSE)

# Load panel
panel <- fread(file.path(data_dir, "analysis_panel.csv"))
cat(sprintf("Panel: %d rows, %d LAs, years %d-%d\n",
            nrow(panel), n_distinct(panel$la_code),
            min(panel$acad_year), max(panel$acad_year)))

# ==============================================================================
# 1. Main DiD Regressions
# ==============================================================================
cat("\n=== Main DiD Regressions ===\n")

# Spec 1: Basic TWFE with log starts
m1 <- feols(log_starts ~ levy_x_post | la_code + acad_year,
            data = panel, cluster = ~la_code)
cat("\n--- Spec 1: log(starts) ~ LevyExposure x Post ---\n")
summary(m1)

# Spec 2: Levels
m2 <- feols(starts ~ levy_x_post | la_code + acad_year,
            data = panel, cluster = ~la_code)
cat("\n--- Spec 2: starts (levels) ---\n")
summary(m2)

# Spec 3: Per capita (where available)
panel_pc <- panel[!is.na(starts_per_10k)]
m3 <- if (nrow(panel_pc) > 100) {
  feols(starts_per_10k ~ levy_x_post | la_code + acad_year,
        data = panel_pc, cluster = ~la_code)
} else {
  cat("  Insufficient per-capita data, skipping.\n")
  m2  # Placeholder
}

# Spec 4: Asinh transformation (handles zeros better than log)
panel[, asinh_starts := asinh(starts)]
m4 <- feols(asinh_starts ~ levy_x_post | la_code + acad_year,
            data = panel, cluster = ~la_code)

cat("\n--- Summary of main results ---\n")
cat(sprintf("Spec 1 (log): beta=%.4f, se=%.4f, p=%.4f\n",
            coef(m1)[1], se(m1)[1], pvalue(m1)[1]))
cat(sprintf("Spec 2 (levels): beta=%.1f, se=%.1f, p=%.4f\n",
            coef(m2)[1], se(m2)[1], pvalue(m2)[1]))
cat(sprintf("Spec 4 (asinh): beta=%.4f, se=%.4f, p=%.4f\n",
            coef(m4)[1], se(m4)[1], pvalue(m4)[1]))

# ==============================================================================
# 2. Event Study — Dynamic Effects
# ==============================================================================
cat("\n=== Event Study ===\n")

m_es <- feols(log_starts ~ i(event_time, levy_exposure, ref = -1) |
                la_code + acad_year,
              data = panel, cluster = ~la_code)

cat("Event study coefficients:\n")
es_tab <- coeftable(m_es)
print(es_tab)

# Extract and save event study coefficients
es_coefs <- as.data.table(es_tab, keep.rownames = "term")
es_coefs[, event_time := as.numeric(gsub(".*::(-?[0-9]+).*", "\\1", term))]
es_coefs <- es_coefs[!is.na(event_time)]
setnames(es_coefs, c("Estimate", "Std. Error"), c("estimate", "se"), skip_absent = TRUE)
es_coefs[, ci_lo := estimate - 1.96 * se]
es_coefs[, ci_hi := estimate + 1.96 * se]

# Add reference period
es_coefs <- rbindlist(list(
  es_coefs,
  data.table(term = "ref", estimate = 0, se = 0, event_time = -1, ci_lo = 0, ci_hi = 0)
), fill = TRUE)
setorder(es_coefs, event_time)

fwrite(es_coefs[, .(event_time, estimate, se, ci_lo, ci_hi)],
       file.path(data_dir, "event_study_coefs.csv"))
cat("Event study coefficients saved.\n")

# Joint test of pre-trends
pre_terms <- es_coefs[event_time < -1]$term
pre_terms <- pre_terms[!is.na(pre_terms) & pre_terms != "ref"]
if (length(pre_terms) > 1) {
  wald_res <- tryCatch(wald(m_es, pre_terms), error = function(e) NULL)
  if (!is.null(wald_res)) {
    cat(sprintf("\nJoint F-test of pre-trends: F=%.2f, p=%.4f\n",
                wald_res$stat, wald_res$p))
  }
}

# ==============================================================================
# 3. Heterogeneity by Tercile
# ==============================================================================
cat("\n=== Heterogeneity by Tercile ===\n")

# Create tercile-level event study for figure
panel[, levy_high := as.numeric(levy_exposure > quantile(levy_exposure, 0.67, na.rm = TRUE))]
panel[, levy_low := as.numeric(levy_exposure <= quantile(levy_exposure, 0.33, na.rm = TRUE))]

# Simple difference: high vs low tercile
m_het <- feols(log_starts ~ i(acad_year, levy_high, ref = 2016) |
                 la_code + acad_year,
               data = panel, cluster = ~la_code)
cat("\nHigh-tercile event study:\n")
summary(m_het)

# Tercile means by year for descriptive figure
tercile_means <- panel[!is.na(levy_tercile),
                        .(mean_starts = mean(starts, na.rm = TRUE),
                          mean_log = mean(log_starts, na.rm = TRUE),
                          n = .N),
                        by = .(acad_year, levy_tercile)]
fwrite(tercile_means, file.path(data_dir, "tercile_means.csv"))

# ==============================================================================
# 4. Save all model objects
# ==============================================================================
saveRDS(list(
  m1 = m1, m2 = m2, m3 = m3, m4 = m4,
  m_es = m_es, m_het = m_het
), file.path(data_dir, "main_models.rds"))

# ==============================================================================
# 5. Write diagnostics.json for validator
# ==============================================================================
diag <- list(
  n_treated = n_distinct(panel$la_code[panel$levy_exposure > median(panel$levy_exposure)]),
  n_pre = length(unique(panel$acad_year[panel$post_levy == 0])),
  n_obs = nrow(panel),
  n_clusters = n_distinct(panel$la_code),
  treatment_var = "levy_exposure (continuous, Bartik share 250+ firms)",
  main_coefficient = coef(m1)[[1]],
  main_se = se(m1)[[1]],
  main_pvalue = pvalue(m1)[[1]]
)
jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE, pretty = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d, n_clusters=%d\n",
            diag$n_treated, diag$n_pre, diag$n_obs, diag$n_clusters))
cat(sprintf("Main result: beta=%.4f (se=%.4f, p=%.4f)\n",
            diag$main_coefficient, diag$main_se, diag$main_pvalue))
