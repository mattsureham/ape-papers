## 03_main_analysis.R — apep_0728
## Triple-Difference estimation: PNTR × Race × Manufacturing Earnings

source("00_packages.R")

qwi <- readRDS("../data/qwi_clean.rds")
bw_gap <- readRDS("../data/bw_gap_panel.rds")

cat("Loaded race-level panel:", nrow(qwi), "rows\n")
cat("Loaded BW gap panel:", nrow(bw_gap), "rows\n")

# ── Restrict to Black and White workers for main analysis ─────────────────────
df <- qwi %>%
  filter(race %in% c("BK", "WH"))

cat("Analysis sample (BK + WH):", nrow(df), "\n")
cat("Counties:", n_distinct(df$county_fips), "\n")
cat("Industries:", n_distinct(df$naics3), "\n")
cat("States:", n_distinct(df$state_fips), "\n")

# ══════════════════════════════════════════════════════════════════════════════
# TABLE 1: Triple-Difference (Main Results)
# ══════════════════════════════════════════════════════════════════════════════

cat("\n=== TABLE 1: TRIPLE-DIFFERENCE RESULTS ===\n")

# Model 1: Baseline DDD — NTR gap × Black × Post
# Outcome: log earnings at county × industry × race × quarter level
m1 <- feols(
  log_earnings ~ ntr_x_black_x_post + ntr_x_post + black_x_post + ntr_x_black |
    county_industry + county_quarter,
  data = df,
  cluster = ~state_fips
)
cat("Model 1 (baseline DDD):\n")
summary(m1)

# Model 2: Add industry×quarter FE (absorbs industry-level shocks)
m2 <- feols(
  log_earnings ~ ntr_x_black_x_post + black_x_post + ntr_x_black |
    county_industry + county_quarter + industry_quarter,
  data = df,
  cluster = ~state_fips
)
cat("\nModel 2 (+ industry×quarter FE):\n")
summary(m2)

# Model 3: Saturated — county×industry, county×quarter, industry×quarter FE
# Only the triple interaction varies within all three FE dimensions
m3 <- feols(
  log_earnings ~ ntr_x_black_x_post |
    county_industry + county_quarter + industry_quarter,
  data = df,
  cluster = ~state_fips
)
cat("\nModel 3 (saturated FE):\n")
summary(m3)

# Model 4: Continuous Black share version (BW gap panel)
# Outcome: Black-White log earnings gap
m4 <- feols(
  bw_earnings_gap ~ ntr_gap:post_pntr |
    county_industry + county_quarter,
  data = bw_gap,
  cluster = ~state_fips
)
cat("\nModel 4 (BW gap ~ NTR×Post):\n")
summary(m4)

# ══════════════════════════════════════════════════════════════════════════════
# TABLE 2: Event Study (Pre-Trend Validation)
# ══════════════════════════════════════════════════════════════════════════════

cat("\n=== TABLE 2: EVENT STUDY ===\n")

# Create year indicators (relative to 2000)
df <- df %>%
  mutate(
    rel_year = year - 2000,
    # Bin endpoints
    rel_year_binned = case_when(
      rel_year <= -4 ~ -4L,
      rel_year >= 8 ~ 8L,
      TRUE ~ as.integer(rel_year)
    )
  )

# Event study: interaction of NTR gap × Black × year dummies
# Reference year: 2000 (rel_year = 0)
m_es <- feols(
  log_earnings ~ i(rel_year_binned, ntr_x_black, ref = 0) |
    county_industry + county_quarter + industry_quarter,
  data = df,
  cluster = ~state_fips
)
cat("Event study coefficients:\n")
summary(m_es)

# Extract event study coefficients for table
es_coefs <- as.data.frame(coeftable(m_es))
es_coefs$term <- rownames(es_coefs)

# ══════════════════════════════════════════════════════════════════════════════
# TABLE 3: Mechanism Decomposition (Employment vs Earnings)
# ══════════════════════════════════════════════════════════════════════════════

cat("\n=== TABLE 3: MECHANISMS ===\n")

# Employment (extensive margin)
m_emp <- feols(
  log(employment + 1) ~ ntr_x_black_x_post |
    county_industry + county_quarter + industry_quarter,
  data = df %>% filter(!is.na(employment)),
  cluster = ~state_fips
)
cat("Employment effect:\n")
summary(m_emp)

# Hires (entry margin)
m_hire <- feols(
  log(hires + 1) ~ ntr_x_black_x_post |
    county_industry + county_quarter + industry_quarter,
  data = df %>% filter(!is.na(hires)),
  cluster = ~state_fips
)
cat("Hires effect:\n")
summary(m_hire)

# Separations (exit margin)
m_sep <- feols(
  log(separations + 1) ~ ntr_x_black_x_post |
    county_industry + county_quarter + industry_quarter,
  data = df %>% filter(!is.na(separations)),
  cluster = ~state_fips
)
cat("Separations effect:\n")
summary(m_sep)

# ══════════════════════════════════════════════════════════════════════════════
# Save all model objects
# ══════════════════════════════════════════════════════════════════════════════

models <- list(
  m1_baseline = m1,
  m2_ind_fe = m2,
  m3_saturated = m3,
  m4_bw_gap = m4,
  m_es = m_es,
  m_emp = m_emp,
  m_hire = m_hire,
  m_sep = m_sep
)
saveRDS(models, "../data/models.rds")

# ── Write diagnostics.json ────────────────────────────────────────────────────
n_treated_industries <- df %>%
  filter(ntr_gap > median(ntr_gap)) %>%
  pull(naics3) %>%
  n_distinct()

n_pre <- df %>% filter(year < 2001) %>% pull(year) %>% n_distinct()

diagnostics <- list(
  n_treated = n_treated_industries,
  n_pre = n_pre,
  n_obs = nrow(df),
  n_counties = n_distinct(df$county_fips),
  n_industries = n_distinct(df$naics3),
  n_states = n_distinct(df$state_fips),
  n_quarters = n_distinct(paste(df$year, df$quarter)),
  main_coef = coef(m3)["ntr_x_black_x_post"],
  main_se = sqrt(vcov(m3)["ntr_x_black_x_post", "ntr_x_black_x_post"]),
  bw_gap_coef = coef(m4)["ntr_gap:post_pntr"],
  bw_gap_se = sqrt(vcov(m4)["ntr_gap:post_pntr", "ntr_gap:post_pntr"])
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
cat("Main DDD coefficient (β₁):", round(diagnostics$main_coef, 4), "\n")
cat("Standard error:", round(diagnostics$main_se, 4), "\n")
cat("t-stat:", round(diagnostics$main_coef / diagnostics$main_se, 2), "\n")
cat("BW gap coefficient:", round(diagnostics$bw_gap_coef, 4), "\n")
