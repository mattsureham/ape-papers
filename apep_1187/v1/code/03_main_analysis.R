# =============================================================================
# 03_main_analysis.R — Main regression analysis
# Paper: apep_1187 — Sweden Pay Equity Audit RDD
# =============================================================================

source("00_packages.R")

df <- readRDS("../data/analysis_panel.rds")

# ============================================================================
# 1. DESCRIPTIVE: Aggregate gender wage ratio time series
# ============================================================================
cat("=== 1. Aggregate Gender Wage Ratio Trends ===\n")

agg <- readRDS("../data/agg_wage_ratio.rds")
cat("Standardized (occupation-weighted) ratio:\n")
print(agg)

# By-industry pre/post comparison
pre_post <- df %>%
  mutate(period = ifelse(year < 2017, "Pre (2014-2016)", "Post (2017-2024)")) %>%
  group_by(period) %>%
  summarise(
    mean_gap = mean(gap_monthly, na.rm = TRUE),
    sd_gap = sd(gap_monthly, na.rm = TRUE),
    n = n()
  )
cat("\nPre/post gender wage ratio:\n")
print(pre_post)

# ============================================================================
# 2. PRIMARY SPECIFICATION: Treatment Intensity DiD
#    gender_gap_it = α_i + δ_t + β(Post2017_t × TreatIntensity_i) + ε_it
#
#    TreatIntensity_i = pre-reform share of firms with 10-19 employees
#    This captures industry-level exposure to the 2017 mandate expansion
# ============================================================================
cat("\n=== 2. Primary Specification ===\n")

# Main outcome: female wages as % of male wages
# Model 1: Baseline (industry + year FE)
m1 <- feols(gap_monthly ~ post_treat | industry + year,
            data = df, cluster = ~industry)
cat("\nModel 1: Gap ~ Post × TreatIntensity | industry + year FE\n")
summary(m1)

# Model 2: With standardized treatment intensity
m2 <- feols(gap_monthly ~ post_treat_std | industry + year,
            data = df, cluster = ~industry)

# Model 3: Log wage gap (more standard in labor economics)
m3 <- feols(log_gap ~ post_treat | industry + year,
            data = df, cluster = ~industry)

# Model 4: Basic salary gap (excludes variable pay components)
m4 <- feols(gap_basic ~ post_treat | industry + year,
            data = df, cluster = ~industry)

# Model 5: Absolute gap in SEK
m5 <- feols(abs_gap ~ post_treat | industry + year,
            data = df, cluster = ~industry)

cat("\n=== Main Results Summary ===\n")
etable(m1, m2, m3, m4, m5,
       headers = c("Monthly Gap (%)", "Monthly Gap (std)", "Log Gap",
                    "Basic Gap (%)", "Abs Gap (SEK)"))

# ============================================================================
# 3. EVENT STUDY: Year-by-year interaction with treatment intensity
# ============================================================================
cat("\n=== 3. Event Study ===\n")

# Create year interactions (omit 2016 as baseline)
df$event_year <- factor(df$year)
df$event_treat <- df$treat_intensity_pre

# Event study specification
es_formula <- as.formula(paste0(
  "gap_monthly ~ ",
  paste(sprintf("i(event_year, event_treat, ref = 2016)"),
        collapse = " + "),
  " | industry + year"
))

m_es <- feols(gap_monthly ~ i(year, treat_intensity_pre, ref = 2016) | industry + year,
              data = df, cluster = ~industry)
cat("\nEvent Study:\n")
summary(m_es)

# ============================================================================
# 4. SECTOR HETEROGENEITY: Private vs. Public
#    Private sector firms are more exposed to the mandate
# ============================================================================
cat("\n=== 4. Sector Heterogeneity ===\n")

# High private share industries vs. low private share
median_private <- median(df$private_share, na.rm = TRUE)
df$high_private <- as.integer(df$private_share > median_private)

m_hetero <- feols(gap_monthly ~ post_treat + post_treat:high_private | industry + year,
                  data = df, cluster = ~industry)
cat("\nHeterogeneity by private sector share:\n")
summary(m_hetero)

# ============================================================================
# 5. FEMALE-DOMINATED vs MALE-DOMINATED INDUSTRIES
# ============================================================================
cat("\n=== 5. Female/Male-Dominated Industry Heterogeneity ===\n")

# Industries where gap < median (more equal = potentially female-dominated)
pre_gaps <- df %>%
  filter(year < 2017) %>%
  group_by(industry) %>%
  summarise(pre_gap = mean(gap_monthly, na.rm = TRUE))

median_gap <- median(pre_gaps$pre_gap)
cat("Median pre-reform gap:", median_gap, "\n")

df <- df %>%
  left_join(pre_gaps, by = "industry", suffix = c("", ".pre_avg"))

df$fem_dominated <- as.integer(df$pre_gap >= median_gap)  # Higher ratio = more equal

m_fem <- feols(gap_monthly ~ post_treat + post_treat:fem_dominated | industry + year,
               data = df, cluster = ~industry)
cat("\nHeterogeneity by pre-reform gender equality:\n")
summary(m_fem)

# ============================================================================
# 6. SAVE DIAGNOSTICS FOR VALIDATOR
# ============================================================================
cat("\n=== Saving diagnostics ===\n")

diagnostics <- list(
  n_treated = length(unique(df$industry[df$treat_intensity_pre > median(df$treat_intensity_pre)])),
  n_pre = length(unique(df$year[df$year < 2017])),
  n_obs = nrow(df),
  n_industries = length(unique(df$industry)),
  n_years = length(unique(df$year)),
  treatment_var = "share of firms with 10-19 employees (pre-reform average)",
  outcome_var = "gender wage ratio (female/male × 100)",
  design = "continuous treatment intensity DiD",
  main_coef = coef(m1)["post_treat"],
  main_se = se(m1)["post_treat"],
  main_pvalue = pvalue(m1)["post_treat"]
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
cat("Diagnostics saved.\n")

# Save models for table generation
save(m1, m2, m3, m4, m5, m_es, m_hetero, m_fem, file = "../data/models.RData")
cat("Models saved.\n")

# ============================================================================
# 7. COMPUTE PRE-TREATMENT SD(Y) FOR SDE CALCULATION
# ============================================================================
cat("\n=== Pre-treatment SD(Y) ===\n")

pre_sd_gap <- sd(df$gap_monthly[df$year < 2017], na.rm = TRUE)
pre_sd_log <- sd(df$log_gap[df$year < 2017], na.rm = TRUE)
pre_sd_abs <- sd(df$abs_gap[df$year < 2017], na.rm = TRUE)

cat(sprintf("SD(gap_monthly) pre-2017: %.3f\n", pre_sd_gap))
cat(sprintf("SD(log_gap) pre-2017: %.4f\n", pre_sd_log))
cat(sprintf("SD(abs_gap) pre-2017: %.1f\n", pre_sd_abs))

# SDE for continuous treatment: β × SD(X) / SD(Y)
sd_treat <- sd(df$treat_intensity_pre, na.rm = TRUE)
sde_main <- coef(m1)["post_treat"] * sd_treat / pre_sd_gap
cat(sprintf("\nSDE (main, monthly gap): β=%.3f × SD(X)=%.4f / SD(Y)=%.3f = %.4f\n",
            coef(m1)["post_treat"], sd_treat, pre_sd_gap, sde_main))

# Save SDE inputs
sde_inputs <- list(
  pre_sd_gap = pre_sd_gap,
  pre_sd_log = pre_sd_log,
  pre_sd_abs = pre_sd_abs,
  sd_treat = sd_treat,
  sde_main = as.numeric(sde_main)
)
saveRDS(sde_inputs, "../data/sde_inputs.rds")
cat("SDE inputs saved.\n")
