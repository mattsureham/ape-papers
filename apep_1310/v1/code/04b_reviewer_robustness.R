# 04b_reviewer_robustness.R — Additional robustness from reviewer feedback
# APEP-1310: The Compression Shock

source("00_packages.R")

results <- readRDS("../data/results.rds")
panel <- results$panel

# ── 1. Exclude high-Kaitz COVID-confounded sectors ─────────────
# Drop Accommodation (I) and Agriculture (A) — most exposed to COVID/seasonal
panel_no_ia <- panel %>% filter(!sector %in% c("I", "A"))

m_no_ia <- feols(
  ln_emp ~ treat_intensity | cs_f + cy_f,
  data = panel_no_ia,
  cluster = ~ cs_f
)
cat("=== Excluding Accommodation & Agriculture ===\n")
summary(m_no_ia)

# ── 2. Sector-specific linear time trends ──────────────────────
panel$sector_trend <- as.numeric(panel$year) * as.numeric(as.factor(panel$sector))

# Add sector-specific trends via sector × year interaction
m_trends <- feols(
  ln_emp ~ treat_intensity + i(sector, year) | cs_f + cy_f,
  data = panel,
  cluster = ~ cs_f
)
cat("\n=== With Sector-Specific Linear Trends ===\n")
# Extract treatment coefficient
cat("treat_intensity:", coef(m_trends)["treat_intensity"],
    "SE:", se(m_trends)["treat_intensity"],
    "p:", pvalue(m_trends)["treat_intensity"], "\n")

# ── 3. Narrow window: 2016-2020 ───────────────────────────────
panel_narrow <- panel %>% filter(year >= 2016 & year <= 2020)

m_narrow <- feols(
  ln_emp ~ treat_intensity | cs_f + cy_f,
  data = panel_narrow,
  cluster = ~ cs_f
)
cat("\n=== Narrow Window 2016-2020 ===\n")
summary(m_narrow)

# ── 4. Pre-2019 only (joint pre-trend test) ───────────────────
panel_pre <- panel %>% filter(year <= 2018)
panel_pre$year_f <- as.factor(panel_pre$year)
panel_pre$lt_kaitz <- panel_pre$lt * panel_pre$kaitz_2018

m_pretrend <- feols(
  ln_emp ~ i(year_f, lt_kaitz, ref = "2018") | cs_f + cy_f,
  data = panel_pre,
  cluster = ~ cs_f
)
cat("\n=== Pre-Trend Joint Test (2013-2018) ===\n")
summary(m_pretrend)

# Joint test that all pre-trend coefficients = 0
pre_coefs <- coef(m_pretrend)
pre_vcov <- vcov(m_pretrend)
wald_stat <- as.numeric(t(pre_coefs) %*% solve(pre_vcov) %*% pre_coefs)
df <- length(pre_coefs)
wald_p <- 1 - pchisq(wald_stat, df)
cat("Joint Wald test: chi2 =", wald_stat, ", df =", df, ", p =", wald_p, "\n")

# ── 5. 2019-only effect (immediate impact) ────────────────────
panel_1920 <- panel %>% filter(year %in% c(2018, 2019))

m_immediate <- feols(
  ln_emp ~ treat_intensity | cs_f + cy_f,
  data = panel_1920,
  cluster = ~ cs_f
)
cat("\n=== Immediate Effect (2018 vs 2019 only) ===\n")
summary(m_immediate)

# ── Save ──────────────────────────────────────────────────────
reviewer_robustness <- list(
  no_accommodation_agriculture = m_no_ia,
  sector_trends = m_trends,
  narrow_window = m_narrow,
  pretrend_joint = list(wald = wald_stat, df = df, p = wald_p),
  immediate_effect = m_immediate
)
saveRDS(reviewer_robustness, "../data/reviewer_robustness.rds")
cat("\nReviewer robustness results saved.\n")
