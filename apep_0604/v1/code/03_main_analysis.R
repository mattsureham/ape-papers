# 03_main_analysis.R — Main DiD analysis
# APEP-0604: Colombia FARC Peace and Education

source("code/00_packages.R")

panel <- read_csv("data/analysis_panel.csv", show_col_types = FALSE)

cat("=== Panel loaded:", nrow(panel), "rows,", n_distinct(panel$mun_code), "municipalities\n")
cat("Years:", sort(unique(panel$year)), "\n")

# ---------------------------------------------------------------
# 1. Continuous-treatment DiD: FARC intensity × post-ceasefire
# Primary outcome: net secondary enrollment
# ---------------------------------------------------------------
cat("\n=== Main specification: Continuous-treatment DiD ===\n")

# Main spec: municipality + year FE, cluster at department level
# Y_mt = alpha_m + gamma_t + beta * (farc_intensity_m * Post_t) + eps
m1_secondary <- feols(
  net_secondary ~ farc_events_pre:post_ceasefire |
    mun_code + year,
  data = panel,
  cluster = ~dept_code
)

cat("Model 1: Secondary enrollment\n")
summary(m1_secondary)

# Primary enrollment (PLACEBO — should show smaller effect)
m1_primary <- feols(
  net_primary ~ farc_events_pre:post_ceasefire |
    mun_code + year,
  data = panel,
  cluster = ~dept_code
)

cat("\nModel 2: Primary enrollment (placebo)\n")
summary(m1_primary)

# Dropout rate
m1_dropout <- feols(
  dropout_total ~ farc_events_pre:post_ceasefire |
    mun_code + year,
  data = panel,
  cluster = ~dept_code
)

cat("\nModel 3: Dropout rate\n")
summary(m1_dropout)

# Secondary dropout
m1_dropout_sec <- feols(
  dropout_secondary ~ farc_events_pre:post_ceasefire |
    mun_code + year,
  data = panel,
  cluster = ~dept_code
)

cat("\nModel 4: Secondary dropout\n")
summary(m1_dropout_sec)

# Approval rate
m1_approval <- feols(
  approval_total ~ farc_events_pre:post_ceasefire |
    mun_code + year,
  data = panel,
  cluster = ~dept_code
)

cat("\nModel 5: Approval rate\n")
summary(m1_approval)

# ---------------------------------------------------------------
# 2. Two-shock decomposition: Ceasefire vs PDET
# ---------------------------------------------------------------
cat("\n=== Two-shock decomposition ===\n")

# Create period indicators
panel <- panel %>%
  mutate(
    period = case_when(
      year <= 2014 ~ "pre",
      year >= 2015 & year <= 2017 ~ "ceasefire_only",
      year >= 2018 ~ "ceasefire_plus_pdet"
    ),
    post1_ceasefire_only = as.integer(year >= 2016 & year <= 2017),
    post2_pdet = as.integer(year >= 2018)
  )

# Two-period decomposition for secondary enrollment
m2_secondary <- feols(
  net_secondary ~ farc_events_pre:post1_ceasefire_only +
    farc_events_pre:post2_pdet |
    mun_code + year,
  data = panel,
  cluster = ~dept_code
)

cat("Two-shock: Secondary enrollment\n")
summary(m2_secondary)

# Two-period decomposition for dropout
m2_dropout <- feols(
  dropout_total ~ farc_events_pre:post1_ceasefire_only +
    farc_events_pre:post2_pdet |
    mun_code + year,
  data = panel,
  cluster = ~dept_code
)

cat("\nTwo-shock: Dropout\n")
summary(m2_dropout)

# ---------------------------------------------------------------
# 3. PDET-specific analysis (triple-difference)
# ---------------------------------------------------------------
cat("\n=== PDET triple-difference ===\n")

# Among FARC-affected municipalities, compare PDET vs non-PDET
m3_pdet <- feols(
  net_secondary ~ farc_events_pre:post_ceasefire +
    pdet:post_pdet +
    farc_events_pre:pdet:post_pdet |
    mun_code + year,
  data = panel,
  cluster = ~dept_code
)

cat("Triple-diff: FARC x PDET x Post\n")
summary(m3_pdet)

# ---------------------------------------------------------------
# 4. Event study — year-by-year effects
# ---------------------------------------------------------------
cat("\n=== Event study ===\n")

# Create year indicators relative to ceasefire (2014 = last pre-period)
panel <- panel %>%
  mutate(
    event_time = year - 2016,  # 2016 = first post year (event_time = 0)
    # Create factor with 2014 (event_time = -1) as reference
    event_factor = factor(event_time)
  )

# Event study: secondary enrollment
m4_es <- feols(
  net_secondary ~ i(event_factor, farc_events_pre, ref = "-1") |
    mun_code + year,
  data = panel,
  cluster = ~dept_code
)

cat("Event study: Secondary enrollment\n")
summary(m4_es)

# Event study: dropout
m4_es_dropout <- feols(
  dropout_total ~ i(event_factor, farc_events_pre, ref = "-1") |
    mun_code + year,
  data = panel,
  cluster = ~dept_code
)

cat("\nEvent study: Dropout\n")
summary(m4_es_dropout)

# ---------------------------------------------------------------
# 5. Binary treatment specification (robustness)
# ---------------------------------------------------------------
cat("\n=== Binary treatment specification ===\n")

m5_binary <- feols(
  net_secondary ~ any_farc:post_ceasefire |
    mun_code + year,
  data = panel,
  cluster = ~dept_code
)

cat("Binary DiD: Secondary enrollment\n")
summary(m5_binary)

m5_binary_dropout <- feols(
  dropout_total ~ any_farc:post_ceasefire |
    mun_code + year,
  data = panel,
  cluster = ~dept_code
)

cat("\nBinary DiD: Dropout\n")
summary(m5_binary_dropout)

# ---------------------------------------------------------------
# 6. Save diagnostics
# ---------------------------------------------------------------
cat("\n=== Writing diagnostics ===\n")

diag <- list(
  n_treated = sum(panel$any_farc[panel$year == 2011]),
  n_pre = length(unique(panel$year[panel$year < 2016])),
  n_obs = nrow(panel),
  n_municipalities = n_distinct(panel$mun_code),
  n_years = n_distinct(panel$year),
  n_pdet = sum(panel$pdet[panel$year == 2011]),
  n_departments = n_distinct(panel$dept_code)
)

jsonlite::write_json(diag, "data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
cat("Diagnostics:\n")
print(diag)

# ---------------------------------------------------------------
# 7. Save model objects for table generation
# ---------------------------------------------------------------
save(
  m1_secondary, m1_primary, m1_dropout, m1_dropout_sec, m1_approval,
  m2_secondary, m2_dropout,
  m3_pdet,
  m4_es, m4_es_dropout,
  m5_binary, m5_binary_dropout,
  panel,
  file = "data/models.RData"
)

cat("\nAll models saved to data/models.RData\n")
cat("=== Main analysis complete ===\n")
