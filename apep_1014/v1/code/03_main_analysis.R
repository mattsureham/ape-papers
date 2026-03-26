# =============================================================================
# 03_main_analysis.R — DDD and Event-Study DiD
# =============================================================================

source("00_packages.R")

analysis <- arrow::read_parquet("../data/analysis_sample.parquet")
earn_long <- arrow::read_parquet("../data/earn_long.parquet")

cat(sprintf("Analysis sample: %s obs\n", format(nrow(analysis), big.mark = ",")))

# ============================================================================
# 1. SUMMARY STATISTICS
# ============================================================================

summ_stats <- analysis %>%
  filter(year <= 2016) %>%
  group_by(tipped_group, industry) %>%
  summarise(
    n_obs = n(),
    n_states = n_distinct(state_fips),
    mean_bw_ratio = mean(bw_ratio, na.rm = TRUE),
    sd_bw_ratio = sd(bw_ratio, na.rm = TRUE),
    mean_earn_black = mean(EarnS_Black, na.rm = TRUE),
    mean_earn_white = mean(EarnS_White, na.rm = TRUE),
    mean_earn_hisp = mean(EarnS_Hispanic, na.rm = TRUE),
    mean_emp_black = mean(Emp_Black, na.rm = TRUE),
    mean_emp_white = mean(Emp_White, na.rm = TRUE),
    mean_hisp_ratio = mean(hisp_ratio, na.rm = TRUE),
    .groups = "drop"
  )

cat("\n=== Pre-Reform Summary (2005-2016) ===\n")
print(summ_stats %>%
        filter(industry == "72", tipped_group %in% c("OFW", "Reform", "LowTipped")) %>%
        select(tipped_group, n_states, mean_bw_ratio, sd_bw_ratio,
               mean_earn_black, mean_earn_white))

# ============================================================================
# 2. DD on B-W RATIO: Food Services Only (Reform vs Low-Tipped)
# ============================================================================

# This is the core specification: reform effect on the racial earnings gap
# in food services, with state and time FE
dd_food <- analysis %>%
  filter(industry == "72") %>%
  filter(tipped_group %in% c("Reform", "LowTipped")) %>%
  mutate(
    treated = as.integer(tipped_group == "Reform"),
    post = post_reform,
    yearq_id = as.integer(factor(yearq))
  )

# DD: B-W ratio
dd_bw <- feols(
  bw_ratio ~ treated:post | state_fips + yearq,
  data = dd_food,
  cluster = ~state_fips
)

cat("\n=== DD: B-W Ratio in Food Services (Reform vs Low-Tipped) ===\n")
summary(dd_bw)

# DD: log B-W gap
dd_ln_bw <- feols(
  ln_bw_gap ~ treated:post | state_fips + yearq,
  data = dd_food,
  cluster = ~state_fips
)

cat("\n=== DD: Log B-W Gap in Food Services ===\n")
summary(dd_ln_bw)

# DD: Hispanic ratio
dd_hisp <- feols(
  hisp_ratio ~ treated:post | state_fips + yearq,
  data = dd_food %>% filter(!is.na(hisp_ratio)),
  cluster = ~state_fips
)

cat("\n=== DD: Hisp-NonHisp Ratio in Food Services ===\n")
summary(dd_hisp)

# DD: log Hispanic gap
dd_ln_hisp <- feols(
  ln_hisp_gap ~ treated:post | state_fips + yearq,
  data = dd_food %>% filter(!is.na(ln_hisp_gap)),
  cluster = ~state_fips
)

cat("\n=== DD: Log Hisp Gap in Food Services ===\n")
summary(dd_ln_hisp)

# ============================================================================
# 3. DDD: Within-State Industry Control (Food Services vs Retail)
# ============================================================================

# The DDD uses retail as within-state control. Create an explicit treatment indicator:
# treated_post = 1 for reform states after reform in food services
# Compare to: same state retail, and control state food services

ddd_data <- analysis %>%
  filter(tipped_group %in% c("Reform", "LowTipped")) %>%
  mutate(
    treated_state = as.integer(tipped_group == "Reform"),
    food_svc = food_services,
    post = post_reform,
    # The DDD treatment: reform state × food services × post-reform
    treat_ddd = treated_state * food_svc * post
  )

# DDD on B-W ratio with state×industry and year-quarter FE
# The key insight: treat_ddd captures the DIFFERENTIAL effect in food services
# relative to retail in the same reform state, relative to control states
ddd_bw <- feols(
  bw_ratio ~ treat_ddd + treated_state:post + food_svc:post |
    state_fips + industry + yearq,
  data = ddd_data,
  cluster = ~state_fips
)

cat("\n=== DDD: B-W Ratio (Food vs Retail × Reform vs Control × Post) ===\n")
summary(ddd_bw)

# DDD on log gap
ddd_ln_bw <- feols(
  ln_bw_gap ~ treat_ddd + treated_state:post + food_svc:post |
    state_fips + industry + yearq,
  data = ddd_data,
  cluster = ~state_fips
)

cat("\n=== DDD: Log B-W Gap ===\n")
summary(ddd_ln_bw)

# DDD on Hispanic ratio
ddd_hisp <- feols(
  hisp_ratio ~ treat_ddd + treated_state:post + food_svc:post |
    state_fips + industry + yearq,
  data = ddd_data %>% filter(!is.na(hisp_ratio)),
  cluster = ~state_fips
)

cat("\n=== DDD: Hispanic Ratio ===\n")
summary(ddd_hisp)

# DDD on log Hispanic gap
ddd_ln_hisp <- feols(
  ln_hisp_gap ~ treat_ddd + treated_state:post + food_svc:post |
    state_fips + industry + yearq,
  data = ddd_data %>% filter(!is.na(ln_hisp_gap)),
  cluster = ~state_fips
)

cat("\n=== DDD: Log Hisp Gap ===\n")
summary(ddd_ln_hisp)

# ============================================================================
# 4. EVENT-STUDY: AZ Reform (sunab, food services only)
# ============================================================================

es_data <- analysis %>%
  filter(industry == "72") %>%
  filter(tipped_group %in% c("Reform", "LowTipped")) %>%
  filter(!is.na(ln_bw_gap)) %>%
  filter(quarter == 1) %>%  # annual for clean event study
  mutate(
    first_treat_es = ifelse(state_fips == "04", 2017L, 0L)
  )

# Only AZ as treated (cleanest single reform)
es_az <- feols(
  ln_bw_gap ~ sunab(first_treat_es, year) | state_fips + year,
  data = es_data %>% filter(state_fips == "04" | tipped_group == "LowTipped"),
  cluster = ~state_fips
)

cat("\n=== Event Study: AZ B-W Gap (annual, sunab) ===\n")
summary(es_az)

# Event study on B-W ratio (levels)
es_az_level <- feols(
  bw_ratio ~ sunab(first_treat_es, year) | state_fips + year,
  data = es_data %>%
    filter(state_fips == "04" | tipped_group == "LowTipped") %>%
    filter(!is.na(bw_ratio)),
  cluster = ~state_fips
)

cat("\n=== Event Study: AZ B-W Ratio (levels, sunab) ===\n")
summary(es_az_level)

# ============================================================================
# 5. OFW CROSS-SECTION (always-treated vs never-treated)
# ============================================================================

ofw_data <- analysis %>%
  filter(industry == "72") %>%
  filter(tipped_group %in% c("OFW", "LowTipped"))

# OFW is time-invariant → absorbed by state FE
# Use year + quarter FE to estimate the average gap
ofw_cross <- feols(
  bw_ratio ~ I(tipped_group == "OFW") | year + quarter,
  data = ofw_data,
  cluster = ~state_fips
)

cat("\n=== OFW Cross-Section: B-W Ratio (year+quarter FE) ===\n")
summary(ofw_cross)

# ============================================================================
# 6. EMPLOYMENT EFFECTS
# ============================================================================

emp_data <- earn_long %>%
  filter(industry == "72", race_group %in% c("Black", "Hispanic")) %>%
  filter(year >= 2005, year <= 2024) %>%
  mutate(
    ln_emp = log(Emp),
    treated = as.integer(state_fips == "04"),
    post = as.integer(year >= 2017),
    yearq = paste0(year, "Q", quarter)
  ) %>%
  filter(tipped_group %in% c("Reform", "LowTipped") | state_fips == "04") %>%
  filter(!is.na(Emp), Emp > 0)

emp_did_black <- feols(
  ln_emp ~ treated:post | state_fips + yearq,
  data = emp_data %>% filter(race_group == "Black"),
  cluster = ~state_fips
)

cat("\n=== Employment DiD: Black Food Services Emp (AZ vs Controls) ===\n")
summary(emp_did_black)

emp_did_hisp <- feols(
  ln_emp ~ treated:post | state_fips + yearq,
  data = emp_data %>% filter(race_group == "Hispanic"),
  cluster = ~state_fips
)

cat("\n=== Employment DiD: Hispanic Food Services Emp ===\n")
summary(emp_did_hisp)

# ============================================================================
# 7. DIAGNOSTICS
# ============================================================================

# n_treated: count treated state-quarter observations (treatment varies at state×quarter)
n_treated_sq <- nrow(dd_food %>% filter(treated == 1, post == 1))
n_treated_states <- n_distinct(dd_food$state_fips[dd_food$treated == 1])
n_pre <- length(unique(dd_food$year[dd_food$year < 2017]))
n_obs_total <- nrow(ddd_data)

# Extract DDD coefficient
ddd_coef_name <- "treat_ddd"
ddd_bw_coef <- coef(ddd_bw)[[ddd_coef_name]]
ddd_bw_se <- sqrt(vcov(ddd_bw)[[ddd_coef_name, ddd_coef_name]])

# Extract DD coefficient
dd_coef_name <- "treated:post"
dd_bw_coef <- coef(dd_bw)[[dd_coef_name]]
dd_bw_se <- sqrt(vcov(dd_bw)[[dd_coef_name, dd_coef_name]])

diagnostics <- list(
  n_treated = n_treated_sq,  # treated state-quarter cells
  n_pre = n_pre,
  n_obs = n_obs_total,
  n_states = n_distinct(ddd_data$state_fips),
  dd_coef_bw = dd_bw_coef,
  dd_se_bw = dd_bw_se,
  ddd_coef_bw = ddd_bw_coef,
  ddd_se_bw = ddd_bw_se,
  ofw_gap = coef(ofw_cross)[[1]],
  emp_coef_black = coef(emp_did_black)[[1]],
  emp_coef_hisp = coef(emp_did_hisp)[[1]]
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics written to data/diagnostics.json\n")
print(diagnostics)

# Save model objects for tables
save(dd_bw, dd_ln_bw, dd_hisp, dd_ln_hisp,
     ddd_bw, ddd_ln_bw, ddd_hisp, ddd_ln_hisp,
     es_az, es_az_level, ofw_cross,
     emp_did_black, emp_did_hisp,
     summ_stats, ddd_data, dd_food, analysis,
     file = "../data/models.RData")
cat("Model objects saved.\n")
