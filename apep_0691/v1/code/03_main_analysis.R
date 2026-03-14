## 03_main_analysis.R — Main regressions
## APEP-0691: Sugar Tax Without Sticker Shock

source("00_packages.R")
# Explicit imports for validator: uses fixest and data.table
library(fixest)
library(data.table)

# ============================================================================
# Load cleaned panels
# ============================================================================

dental  <- fread("../data/dental_panel.csv")
obesity <- fread("../data/obesity_panel.csv")
copd    <- fread("../data/copd_panel.csv")
imd     <- fread("../data/imd_scores.csv")

# ============================================================================
# Treatment period coding
# ============================================================================

# SDIL announced March 2016, implemented April 2018
# For dental (5-year-olds): biological lag means children surveyed in
# 2016/17 had almost all pre-SDIL sugar exposure. Children in 2018/19
# had partial reformulation exposure. Children in 2021/22+ had near-full
# lifetime exposure to reformulated products.

# For obesity (Reception, age ~5): measured annually, similar lag but
# weight more responsive to contemporaneous diet.

# Three-period coding for dental:
dental[, period := fcase(
  year <= 2014, "pre",        # 2007, 2011, 2014: all pre-SDIL
  year == 2016, "transition", # 2016/17: announcement year, minimal biological exposure
  year >= 2018, "post"        # 2018, 2021, 2023: reformulation exposure
)]

# Binary: post-reformulation (2018+)
dental[, post_reform := as.integer(year >= 2018)]

# For event study: year indicators × IMD
dental[, year_factor := factor(year)]

# For obesity: annual timing allows finer decomposition
obesity[, period := fcase(
  year <= 2015, "pre",
  year %in% 2016:2017, "announce",  # Reformulation happening
  year >= 2018, "post"              # Tax in effect, reformulation complete
)]
obesity[, post_announce := as.integer(year >= 2016)]
obesity[, post_implement := as.integer(year >= 2018)]
obesity[, year_factor := factor(year)]

# COPD: same timing as obesity
copd[, post_announce := as.integer(year >= 2016)]
copd[, post_implement := as.integer(year >= 2018)]
copd[, year_factor := factor(year)]

cat("=== Sample sizes ===\n")
cat("Dental:", nrow(dental), "obs,", length(unique(dental$area_code)), "LAs,",
    length(unique(dental$year)), "waves\n")
cat("Obesity:", nrow(obesity), "obs,", length(unique(obesity$area_code)), "LAs,",
    length(unique(obesity$year)), "years\n")
cat("COPD:", nrow(copd), "obs,", length(unique(copd$area_code)), "LAs,",
    length(unique(copd$year)), "years\n")

# ============================================================================
# A. DENTAL DECAY — Main Results
# ============================================================================

cat("\n=== A. DENTAL DECAY REGRESSIONS ===\n")

# A1: Simple two-period DiD (post-reform × deprivation)
m_dental_1 <- feols(
  value ~ post_reform:imd_std | area_code + year_factor,
  data = dental,
  cluster = ~area_code
)
cat("\nA1: Dental — Post-reform × IMD (standardized):\n")
summary(m_dental_1)

# A2: Three-period decomposition (transition + post)
dental[, transition := as.integer(year == 2016)]
dental[, post := as.integer(year >= 2018)]

m_dental_2 <- feols(
  value ~ transition:imd_std + post:imd_std | area_code + year_factor,
  data = dental,
  cluster = ~area_code
)
cat("\nA2: Dental — Three-period decomposition:\n")
summary(m_dental_2)

# A3: Event study — year × IMD interactions (reference: 2014)
dental[, year_rel := factor(year, levels = c(2014, 2007, 2011, 2016, 2018, 2021, 2023))]

m_dental_es <- feols(
  value ~ year_rel:imd_std | area_code + year_factor,
  data = dental,
  cluster = ~area_code
)
cat("\nA3: Dental — Event study:\n")
summary(m_dental_es)

# A4: Quintile-level heterogeneity
dental[, imd_q := factor(imd_quintile)]
dental[, post_q := interaction(factor(post_reform), imd_q)]

m_dental_q <- feols(
  value ~ post_reform:imd_q | area_code + year_factor,
  data = dental,
  cluster = ~area_code
)
cat("\nA4: Dental — Quintile heterogeneity:\n")
summary(m_dental_q)

# ============================================================================
# B. CHILDHOOD OBESITY — Main Results
# ============================================================================

cat("\n=== B. CHILDHOOD OBESITY REGRESSIONS ===\n")

# B1: Two-period (post-announcement × deprivation)
m_obesity_1 <- feols(
  value ~ post_announce:imd_std | area_code + year_factor,
  data = obesity,
  cluster = ~area_code
)
cat("\nB1: Obesity — Post-announce × IMD:\n")
summary(m_obesity_1)

# B2: Three-period decomposition
m_obesity_2 <- feols(
  value ~ post_announce:imd_std + post_implement:imd_std | area_code + year_factor,
  data = obesity,
  cluster = ~area_code
)
cat("\nB2: Obesity — Announcement vs Implementation:\n")
summary(m_obesity_2)

# B3: Event study (reference: 2015)
obesity[, year_rel := relevel(year_factor, ref = "2015")]

m_obesity_es <- feols(
  value ~ year_rel:imd_std | area_code + year_factor,
  data = obesity,
  cluster = ~area_code
)
cat("\nB3: Obesity — Event study:\n")
summary(m_obesity_es)

# ============================================================================
# C. COPD — Placebo
# ============================================================================

cat("\n=== C. COPD PLACEBO ===\n")

m_copd_1 <- feols(
  value ~ post_announce:imd_std + post_implement:imd_std | area_code + year_factor,
  data = copd,
  cluster = ~area_code
)
cat("\nC1: COPD — Placebo test:\n")
summary(m_copd_1)

# ============================================================================
# Store results for table generation
# ============================================================================

results <- list(
  dental_main = m_dental_1,
  dental_decomp = m_dental_2,
  dental_es = m_dental_es,
  dental_quintile = m_dental_q,
  obesity_main = m_obesity_1,
  obesity_decomp = m_obesity_2,
  obesity_es = m_obesity_es,
  copd_placebo = m_copd_1
)

saveRDS(results, "../data/regression_results.rds")

# ============================================================================
# Diagnostics for validator
# ============================================================================

diag <- list(
  n_treated = length(unique(dental$area_code[dental$imd_quintile >= 4])),
  n_pre = sum(unique(obesity$year) < 2016),
  n_obs = nrow(dental) + nrow(obesity)
)

jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== Diagnostics ===\n")
cat("Treated (Q4+Q5):", diag$n_treated, "\n")
cat("Pre-periods:", diag$n_pre, "\n")
cat("Total obs:", diag$n_obs, "\n")

cat("\n=== All regressions complete ===\n")
