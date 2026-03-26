# 03_main_analysis.R — Main DDD regressions
# APEP Working Paper apep_0992

source("code/00_packages.R")

panel <- readRDS("data/analysis_panel.rds")

cat("Analysis panel:", nrow(panel), "observations\n")
cat("Departments:", uniqueN(panel$dept_id), "\n")

# ==========================================================================
# SPECIFICATION NOTES
# Treatment (treated_crop × post) varies at the crop × time level only.
# Including crop×year FE would absorb the treatment variable.
# The preferred spec uses dept×crop + dept×year FE:
#   - dept×crop: absorbs time-invariant comparative advantage
#   - dept×year: absorbs all department-level shocks (devaluation, weather, etc.)
# Identification: within-department differential changes in planted area
# between treated and control crops, after absorbing dept-level shocks.
# ==========================================================================

# --- Create continuous treatment intensity (tax cut in pp) ---
panel[, tax_cut := fcase(
  crop == "Wheat", 23,
  crop == "Corn", 20,
  crop == "Sunflower", 32,
  crop == "Soybean", 5
)]
panel[, tax_cut_post := tax_cut * post]

# Model 1: Simple DiD with dept + year FE
m1 <- feols(log_planted ~ treat_post | dept_id + campaign_year,
            data = panel, cluster = ~dept_id)

# Model 2: Dept + year + crop FE
m2 <- feols(log_planted ~ treat_post | dept_id + campaign_year + crop,
            data = panel, cluster = ~dept_id)

# Model 3: Dept×crop + year FE
m3 <- feols(log_planted ~ treat_post | dept_crop + campaign_year,
            data = panel, cluster = ~dept_id)

# Model 4: PREFERRED — Dept×crop + dept×year FE
# This absorbs all department-level time-varying shocks (devaluation, weather)
# Treatment effect identified by within-department, across-crop differential change
m4 <- feols(log_planted ~ treat_post | dept_crop + dept_year,
            data = panel, cluster = ~dept_id)

# Model 5: Production outcome (preferred spec)
m5 <- feols(log_production ~ treat_post | dept_crop + dept_year,
            data = panel, cluster = ~dept_id)

cat("\n=== MAIN RESULTS ===\n")
etable(m1, m2, m3, m4, m5,
       headers = c("Dept+Year", "Dept+Year+Crop", "DeptCrop+Year",
                    "DeptCrop+DeptYear", "Production"),
       se.below = TRUE)

# ==========================================================================
# CONTINUOUS TREATMENT (tax cut size)
# ==========================================================================
# Uses the actual pp tax cut (23, 20, 32, 5) to exploit dose-response
m4b <- feols(log_planted ~ tax_cut_post | dept_crop + dept_year,
             data = panel, cluster = ~dept_id)
cat("\nContinuous treatment (tax cut pp × post):\n")
print(summary(m4b))

# ==========================================================================
# CROP-SPECIFIC EFFECTS
# ==========================================================================
panel[, wheat_post := as.integer(crop == "Wheat") * post]
panel[, corn_post := as.integer(crop == "Corn") * post]
panel[, sunflower_post := as.integer(crop == "Sunflower") * post]

m6 <- feols(log_planted ~ wheat_post + corn_post + sunflower_post |
              dept_crop + dept_year,
            data = panel, cluster = ~dept_id)
cat("\nCrop-specific effects:\n")
print(summary(m6))

# ==========================================================================
# EVENT STUDY
# ==========================================================================
panel[, rel_time := campaign_year - 2015]

m_es <- feols(log_planted ~ i(rel_time, treated_crop, ref = -1) |
                dept_crop + dept_year,
              data = panel, cluster = ~dept_id)
cat("\nEvent Study:\n")
print(summary(m_es))

# Check pre-trends: test joint significance of pre-treatment coefficients
pre_coefs <- coef(m_es)[grepl("rel_time::-[2-5]:", names(coef(m_es)))]
cat("\nPre-treatment coefficients:\n")
print(pre_coefs)
# Wald test for joint significance of pre-treatment effects
pre_test <- wald(m_es, "rel_time::-[2-5]")
cat("\nJoint F-test of pre-treatment effects:\n")
print(pre_test)

# ==========================================================================
# HETEROGENEITY: Initial soybean concentration
# ==========================================================================
m_het_high <- feols(log_planted ~ treat_post | dept_crop + dept_year,
                    data = panel[high_soy == 1], cluster = ~dept_id)
m_het_low <- feols(log_planted ~ treat_post | dept_crop + dept_year,
                   data = panel[high_soy == 0], cluster = ~dept_id)

cat("\nHigh soybean concentration:\n")
print(summary(m_het_high))
cat("\nLow soybean concentration:\n")
print(summary(m_het_low))

# ==========================================================================
# AREA SHARE OUTCOME
# ==========================================================================
m_share <- feols(area_share ~ treat_post | dept_crop + dept_year,
                 data = panel, cluster = ~dept_id)
cat("\nArea share outcome:\n")
print(summary(m_share))

# ==========================================================================
# SAVE
# ==========================================================================
save(m1, m2, m3, m4, m4b, m5, m6, m_es, m_het_high, m_het_low, m_share,
     file = "data/main_results.RData")

# Write diagnostics.json
diagnostics <- list(
  n_treated = uniqueN(panel[treated_crop == 1, dept_crop]),
  n_pre = length(unique(panel$campaign_year[panel$campaign_year < 2015])),
  n_obs = nrow(panel)
)
write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics:", toJSON(diagnostics, auto_unbox = TRUE), "\n")
cat("Main analysis complete.\n")
