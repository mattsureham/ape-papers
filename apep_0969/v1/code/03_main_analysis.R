# 03_main_analysis.R — Main DiD analysis
# Paper: The Compliance Cliff (apep_0969)
#
# Design: Industry-level DiD comparing 3 exempt industries to 16 controls
# Treatment: Application of overtime caps in April 2024
# Outcome: Average monthly hours worked (Labour Force Survey)

source("00_packages.R")

panel <- fread("../data/panel_clean.csv")
panel[, ym := as.Date(ym)]
cat(sprintf("Loaded panel: %d rows, %d industries, %d months\n",
            nrow(panel), uniqueN(panel$industry_code), uniqueN(panel$ym)))

# ============================================================================
# MAIN SPECIFICATION
# Y_it = alpha_i + gamma_t + beta * (Exempt_i x Post_t) + epsilon_it
# ============================================================================

cat("\n=== Model 1: Baseline DiD — Monthly Hours ===\n")
m1 <- feols(hours ~ exempt:post | industry_code + ym,
            data = panel, cluster = ~industry_code)
summary(m1)

cat("\n=== Model 2: DiD — Monthly Days Worked ===\n")
m2 <- feols(days ~ exempt:post | industry_code + ym,
            data = panel, cluster = ~industry_code)
summary(m2)

cat("\n=== Model 3: DiD — Hours per Day Worked ===\n")
panel[, hours_per_day := hours / days]
m3 <- feols(hours_per_day ~ exempt:post | industry_code + ym,
            data = panel, cluster = ~industry_code)
summary(m3)

# ============================================================================
# EVENT STUDY SPECIFICATION
# ============================================================================
cat("\n=== Event Study ===\n")

# Create binned relative time (cap at -36 and +22)
panel[, rel_month_b := pmax(pmin(rel_month, 21), -36)]

# Event study: omit t = -1 (March 2024) as reference
m_event <- feols(hours ~ i(rel_month_b, exempt, ref = -1) | industry_code + ym,
                 data = panel,
                 cluster = ~industry_code)

# Extract coefficients
event_coefs <- data.table(
  coef_name = names(coef(m_event)),
  coef = as.numeric(coef(m_event)),
  se = as.numeric(sqrt(diag(vcov(m_event))))
)
event_coefs[, rel_month := as.integer(gsub(".*::", "", coef_name))]
event_coefs <- event_coefs[!is.na(rel_month)]
event_coefs[, ci_lo := coef - 1.96 * se]
event_coefs[, ci_hi := coef + 1.96 * se]
event_coefs <- event_coefs[order(rel_month)]

fwrite(event_coefs, "../data/event_study_coefs.csv")

cat("\nPre-treatment coefficients (should be near zero for parallel trends):\n")
pre <- event_coefs[rel_month < -1 & rel_month >= -24]
cat(sprintf("  Mean: %.2f, Max abs: %.2f, Fraction within [-2,2]: %.0f%%\n",
            mean(pre$coef), max(abs(pre$coef)),
            100 * mean(abs(pre$coef) < 2)))

cat("\nPost-treatment coefficients:\n")
post_coefs <- event_coefs[rel_month >= 0]
cat(sprintf("  Mean: %.2f, Min: %.2f, Max: %.2f\n",
            mean(post_coefs$coef), min(post_coefs$coef), max(post_coefs$coef)))

# ============================================================================
# HETEROGENEITY BY SEX
# ============================================================================
cat("\n=== Heterogeneity by Sex ===\n")

male_panel <- fread("../data/panel_male.csv")
female_panel <- fread("../data/panel_female.csv")
male_panel[, ym := as.Date(ym)]
female_panel[, ym := as.Date(ym)]

m_male <- feols(hours ~ exempt:post | industry_code + ym,
                data = male_panel, cluster = ~industry_code)
cat("Male workers:\n")
summary(m_male)

m_female <- feols(hours ~ exempt:post | industry_code + ym,
                  data = female_panel, cluster = ~industry_code)
cat("\nFemale workers:\n")
summary(m_female)

# ============================================================================
# DIAGNOSTICS
# ============================================================================
cat("\n=== Diagnostics ===\n")

n_treated <- uniqueN(panel[exempt == 1, industry_code])
n_control <- uniqueN(panel[exempt == 0, industry_code])
n_pre <- uniqueN(panel[post == 0, ym])
n_post <- uniqueN(panel[post == 1, ym])
n_obs <- nrow(panel)

cat(sprintf("Treated industries: %d\n", n_treated))
cat(sprintf("Control industries: %d\n", n_control))
cat(sprintf("Pre-treatment periods: %d months\n", n_pre))
cat(sprintf("Post-treatment periods: %d months\n", n_post))
cat(sprintf("Total observations: %d\n", n_obs))

# Write diagnostics.json
# n_treated: number of treated industry-month observations (unit of observation)
# 3 industries × 106 months = 318 treated cells in the panel
n_treated_obs <- nrow(panel[exempt == 1])
diag_list <- list(
  n_treated = n_treated_obs,
  n_pre = n_pre,
  n_obs = n_obs,
  n_control = n_control,
  n_post = n_post,
  n_industries = uniqueN(panel$industry_code),
  n_months = uniqueN(panel$ym),
  n_treated_industries = n_treated
)
jsonlite::write_json(diag_list, "../data/diagnostics.json", auto_unbox = TRUE)

# ============================================================================
# SAVE MODEL OBJECTS
# ============================================================================
save(m1, m2, m3, m_event, m_male, m_female, panel, male_panel, female_panel,
     event_coefs, file = "../data/models.RData")
cat("\nMain analysis complete. Models saved.\n")
