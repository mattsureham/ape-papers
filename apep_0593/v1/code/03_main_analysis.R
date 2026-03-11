# ============================================================================
# 03_main_analysis.R — Primary DiD regressions and event studies
# APEP-0593: Roaming Abolition and Cross-Border Tourism
# ============================================================================

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))

# Use pre-COVID window (2012-2019) as primary sample
panel_main <- panel[time >= 2012 & time <= 2019]
cat("Analysis sample:", nrow(panel_main), "obs,",
    uniqueN(panel_main$geo), "regions,",
    length(unique(panel_main$time)), "years\n")

# -----------------------------------------------------------------------
# 1. PRIMARY SPECIFICATION: Binary border × post DiD
# -----------------------------------------------------------------------
cat("\n=== PRIMARY SPECIFICATION ===\n")

# Baseline: log foreign nights ~ border × post + region FE + year FE
m1 <- feols(log_foreign ~ border_post | geo + time,
            data = panel_main, cluster = ~country)
cat("Model 1 (binary border DiD, log foreign nights):\n")
print(summary(m1))

# Level specification
m1_level <- feols(foreign_nights ~ border_post | geo + time,
                  data = panel_main, cluster = ~country)

# Per-capita specification
m1_pc <- feols(foreign_pc ~ border_post | geo + time,
               data = panel_main, cluster = ~country)

# -----------------------------------------------------------------------
# 2. CONTINUOUS TREATMENT: Pre-treatment cross-border share × post
# -----------------------------------------------------------------------
cat("\n=== CONTINUOUS TREATMENT ===\n")

m2 <- feols(log_foreign ~ share_post | geo + time,
            data = panel_main, cluster = ~country)
cat("Model 2 (continuous treatment, log foreign nights):\n")
print(summary(m2))

# -----------------------------------------------------------------------
# 3. EVENT STUDY: Annual leads and lags
# -----------------------------------------------------------------------
cat("\n=== EVENT STUDY ===\n")

# Create event-time dummies interacted with border
# Reference: event_time = -1 (2016)
panel_main[, et := factor(event_time)]

# Event study with border interaction
m_es <- feols(log_foreign ~ i(event_time, border, ref = -1) | geo + time,
              data = panel_main, cluster = ~country)
cat("Event study coefficients:\n")
print(coeftable(m_es))

# Joint F-test on pre-treatment coefficients
pre_coefs <- grep("event_time::-[2-5]", names(coef(m_es)), value = TRUE)
if (length(pre_coefs) > 0) {
  f_test <- wald(m_es, pre_coefs)
  cat("\nJoint F-test on pre-treatment coefficients:\n")
  print(f_test)
}

# Continuous treatment event study
m_es_cont <- feols(log_foreign ~ i(event_time, pre_foreign_share, ref = -1) | geo + time,
                   data = panel_main, cluster = ~country)

# -----------------------------------------------------------------------
# 4. PLACEBO OUTCOMES
# -----------------------------------------------------------------------
cat("\n=== PLACEBO: DOMESTIC TOURISM ===\n")

# Placebo 1: Domestic tourist nights (should show null)
m_dom <- feols(log_domestic ~ border_post | geo + time,
               data = panel_main, cluster = ~country)
cat("Domestic nights placebo:\n")
print(summary(m_dom))

# -----------------------------------------------------------------------
# 5. TRIPLE DIFFERENCE: External border as placebo geography
# -----------------------------------------------------------------------
cat("\n=== EXTERNAL BORDER PLACEBO ===\n")

# Compare internal border vs external border (both are "border" but only
# internal border regions have EU neighbors benefiting from RLAH)
panel_borders <- panel_main[border_type %in% c("internal_border", "external_border")]
panel_borders[, internal := as.integer(border_type == "internal_border")]
panel_borders[, internal_post := internal * post]

m_ext <- feols(log_foreign ~ internal_post | geo + time,
               data = panel_borders, cluster = ~country)
cat("Internal vs External border:\n")
print(summary(m_ext))

# -----------------------------------------------------------------------
# 6. COUNTRY × YEAR FIXED EFFECTS (within-country variation)
# -----------------------------------------------------------------------
cat("\n=== WITHIN-COUNTRY SPECIFICATION ===\n")

m_cty <- feols(log_foreign ~ border_post | geo + country^time,
               data = panel_main, cluster = ~country)
cat("Country × Year FE specification:\n")
print(summary(m_cty))

# Continuous treatment with country × year FE
m_cty_cont <- feols(log_foreign ~ share_post | geo + country^time,
                    data = panel_main, cluster = ~country)

# -----------------------------------------------------------------------
# 7. Save results for figures and tables
# -----------------------------------------------------------------------

# Event study coefficients — extract event time from fixest naming
# Names look like "event_time::-5:border" → extract the number after first ::
extract_et <- function(nms) {
  as.integer(str_extract(nms, "(?<=::)-?\\d+"))
}

es_coefs <- data.table(
  event_time = extract_et(names(coef(m_es))),
  estimate = coef(m_es),
  se = se(m_es),
  ci_low = coef(m_es) - 1.96 * se(m_es),
  ci_high = coef(m_es) + 1.96 * se(m_es)
)
# Add reference period
es_coefs <- rbind(
  es_coefs,
  data.table(event_time = -1, estimate = 0, se = 0, ci_low = 0, ci_high = 0)
)
es_coefs <- es_coefs[order(event_time)]
fwrite(es_coefs, file.path(data_dir, "event_study_coefs.csv"))

# Continuous treatment event study
es_cont_coefs <- data.table(
  event_time = extract_et(names(coef(m_es_cont))),
  estimate = coef(m_es_cont),
  se = se(m_es_cont),
  ci_low = coef(m_es_cont) - 1.96 * se(m_es_cont),
  ci_high = coef(m_es_cont) + 1.96 * se(m_es_cont)
)
es_cont_coefs <- rbind(
  es_cont_coefs,
  data.table(event_time = -1, estimate = 0, se = 0, ci_low = 0, ci_high = 0)
)
es_cont_coefs <- es_cont_coefs[order(event_time)]
fwrite(es_cont_coefs, file.path(data_dir, "event_study_cont_coefs.csv"))

# Main regression results
main_results <- data.table(
  model = c("Binary DiD (log)", "Binary DiD (level)", "Binary DiD (per cap)",
            "Continuous (log)", "Domestic placebo",
            "Internal vs External", "Country×Year FE",
            "Continuous + Country×Year FE"),
  beta = c(coef(m1)[1], coef(m1_level)[1], coef(m1_pc)[1],
           coef(m2)[1], coef(m_dom)[1],
           coef(m_ext)[1], coef(m_cty)[1],
           coef(m_cty_cont)[1]),
  se = c(se(m1)[1], se(m1_level)[1], se(m1_pc)[1],
         se(m2)[1], se(m_dom)[1],
         se(m_ext)[1], se(m_cty)[1],
         se(m_cty_cont)[1]),
  n_obs = c(nobs(m1), nobs(m1_level), nobs(m1_pc),
            nobs(m2), nobs(m_dom),
            nobs(m_ext), nobs(m_cty),
            nobs(m_cty_cont)),
  n_regions = c(uniqueN(panel_main$geo), uniqueN(panel_main$geo),
                uniqueN(panel_main$geo), uniqueN(panel_main$geo),
                uniqueN(panel_main$geo),
                uniqueN(panel_borders$geo), uniqueN(panel_main$geo),
                uniqueN(panel_main$geo))
)
fwrite(main_results, file.path(data_dir, "main_results.csv"))

# Save fixest objects for table generation
save(m1, m1_level, m1_pc, m2, m_dom, m_ext, m_cty, m_cty_cont,
     m_es, m_es_cont,
     file = file.path(data_dir, "main_models.RData"))

cat("\nAll main analysis results saved.\n")
