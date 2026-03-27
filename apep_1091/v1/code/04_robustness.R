# ==============================================================================
# 04_robustness.R — Robustness checks and additional analyses
# Paper: The Picture Bride Premium
# ==============================================================================

source("00_packages.R")

dt <- readRDS("../data/analysis_sample.rds")
load("../data/models.rda")

# ==========================================================================
# A. PRE-TREND TEST: 1900→1910 (before picture brides)
# ==========================================================================

cat("=== PRE-TREND: 1900→1910 ===\n")

# Restrict to pre-period only
dt_pre <- dt[YEAR %in% c(1900, 1910)]
dt_pre[, post_1910 := as.integer(YEAR == 1910)]
dt_pre[, treat_pre := japanese * post_1910]

pre_occ <- feols(OCCSCORE ~ treat_pre + AGE + age_sq + literate | STATEFIP^YEAR + RACE,
                 data = dt_pre, cluster = ~STATEFIP)

cat("Pre-trend (1900→1910) OCCSCORE:", round(coef(pre_occ)["treat_pre"], 4),
    "(SE:", round(se(pre_occ)["treat_pre"], 4), ")\n")
cat("p-value:", round(pvalue(pre_occ)["treat_pre"], 4), "\n")

pre_sp <- feols(spouse_present ~ treat_pre + AGE + age_sq + literate | STATEFIP^YEAR + RACE,
                data = dt_pre, cluster = ~STATEFIP)

cat("Pre-trend (1900→1910) Spouse present:", round(coef(pre_sp)["treat_pre"], 4),
    "(SE:", round(se(pre_sp)["treat_pre"], 4), ")\n\n")

# ==========================================================================
# B. AGE-RESTRICTED SAMPLE: Men 25-45 (prime working age)
# ==========================================================================

cat("=== AGE-RESTRICTED: Men 25-45 ===\n")

dt_prime <- dt[AGE >= 25 & AGE <= 45]
rob_prime <- feols(OCCSCORE ~ treat + AGE + age_sq + literate | STATEFIP^YEAR + RACE,
                   data = dt_prime, cluster = ~STATEFIP)

cat("Prime-age (25-45):", round(coef(rob_prime)["treat"], 4),
    "(SE:", round(se(rob_prime)["treat"], 4), "), N =", nrow(dt_prime), "\n")

# ==========================================================================
# C. EXCLUDING CALIFORNIA (dominant state)
# ==========================================================================

cat("\n=== EXCLUDING CALIFORNIA ===\n")

dt_no_ca <- dt[STATEFIP != 6]
rob_no_ca <- feols(OCCSCORE ~ treat + AGE + age_sq + literate | STATEFIP^YEAR + RACE,
                   data = dt_no_ca, cluster = ~STATEFIP)

cat("Excluding CA:", round(coef(rob_no_ca)["treat"], 4),
    "(SE:", round(se(rob_no_ca)["treat"], 4), "), N =", nrow(dt_no_ca), "\n")

# ==========================================================================
# D. WEST COAST ONLY (where both groups concentrated)
# ==========================================================================

cat("\n=== WEST COAST ONLY (CA, WA, OR) ===\n")

dt_west <- dt[STATEFIP %in% c(6, 53, 41)]
rob_west <- feols(OCCSCORE ~ treat + AGE + age_sq + literate | STATEFIP^YEAR + RACE,
                  data = dt_west, cluster = ~STATEFIP)

cat("West Coast only:", round(coef(rob_west)["treat"], 4),
    "(SE:", round(se(rob_west)["treat"], 4), "), N =", nrow(dt_west), "\n")

# ==========================================================================
# E. FARM OWNERSHIP — DDD with Alien Land Laws
# ==========================================================================

cat("\n=== FARM OWNERSHIP: ALI interaction ===\n")

# Full DDD: Japanese × Post × ALI
dt[, treat_ali := japanese * post * ali_state]
dt[, treat_no_ali := japanese * post * (1 - ali_state)]

rob_ddd <- feols(farm_owner ~ treat + treat_ali + AGE + age_sq + literate |
                   STATEFIP^YEAR + RACE,
                 data = dt, cluster = ~STATEFIP)

cat("Farm ownership DDD:\n")
cat("  Japanese×Post:", round(coef(rob_ddd)["treat"], 4), "\n")
cat("  Japanese×Post×ALI:", round(coef(rob_ddd)["treat_ali"], 4), "\n\n")

# ==========================================================================
# F. OCCUPATIONAL UPGRADING: Share in higher-skill occupations
# ==========================================================================

cat("=== OCCUPATIONAL COMPOSITION ===\n")

# Create occupational category dummies based on OCC1950
# Professional/managerial (OCC1950 0-99)
# Clerical/sales (100-399)
# Craft/operative (400-699)
# Service (700-799)
# Farm labor (800-899)
# Laborers (900-970)
dt[, occ_prof := as.integer(OCC1950 >= 0 & OCC1950 < 100)]
dt[, occ_service := as.integer(OCC1950 >= 700 & OCC1950 < 800)]
dt[, occ_farm_labor := as.integer(OCC1950 >= 800 & OCC1950 < 900)]
dt[, occ_laborer := as.integer(OCC1950 >= 900 & OCC1950 <= 970)]

rob_prof <- feols(occ_prof ~ treat + AGE + age_sq + literate | STATEFIP^YEAR + RACE,
                  data = dt, cluster = ~STATEFIP)
rob_farm_l <- feols(occ_farm_labor ~ treat + AGE + age_sq + literate | STATEFIP^YEAR + RACE,
                    data = dt, cluster = ~STATEFIP)
rob_labor <- feols(occ_laborer ~ treat + AGE + age_sq + literate | STATEFIP^YEAR + RACE,
                   data = dt, cluster = ~STATEFIP)

cat("Professional:", round(coef(rob_prof)["treat"], 4), "\n")
cat("Farm labor:", round(coef(rob_farm_l)["treat"], 4), "\n")
cat("Laborer:", round(coef(rob_labor)["treat"], 4), "\n")

# ==========================================================================
# G. Save robustness models
# ==========================================================================

save(pre_occ, pre_sp, rob_prime, rob_no_ca, rob_west, rob_ddd,
     rob_prof, rob_farm_l, rob_labor,
     file = "../data/robustness_models.rda")

cat("\nRobustness checks complete.\n")
