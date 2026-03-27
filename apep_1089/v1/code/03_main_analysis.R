## 03_main_analysis.R — Main DiD and DDD analysis
## apep_1089: NIS2 Cybersecurity Regulation and Firm Security Investment

source("code/00_packages.R")

cat("=== Main Analysis ===\n")

# ----------------------------------------------------------------
# 1. Load cleaned data
# ----------------------------------------------------------------

indices <- readRDS("data/indices.rds")
indicator_panel <- readRDS("data/indicator_panel.rds")
df_clean <- readRDS("data/ict_security_clean.rds")

# ----------------------------------------------------------------
# 2. Main DiD: Technical Security Index
# ----------------------------------------------------------------

cat("\n--- DiD: Technical Security Index ---\n")

# Restrict to treated (50-249) and control (10-49) — exclude GE250 for clean DiD
did_data <- indices %>%
  filter(size_class %in% c("10-49", "50-249"))

# Spec 1: Basic DiD with size and year FE
m1_tech <- feols(index_technical ~ treat_post | size_factor + factor(year),
                 data = did_data, cluster = ~country)

# Spec 2: Add country FE
m2_tech <- feols(index_technical ~ treat_post | country + size_factor + factor(year),
                 data = did_data, cluster = ~country)

# Spec 3: Add country × year FE (absorbs country-level ICT trends)
m3_tech <- feols(index_technical ~ treat_post | country + size_factor + country^factor(year),
                 data = did_data, cluster = ~country)

cat("Technical Index Results:\n")
etable(m1_tech, m2_tech, m3_tech, se = "cluster")

# ----------------------------------------------------------------
# 3. Main DiD: Formal Compliance Index
# ----------------------------------------------------------------

cat("\n--- DiD: Formal Compliance Index ---\n")

m1_formal <- feols(index_formal ~ treat_post | size_factor + factor(year),
                   data = did_data, cluster = ~country)

m2_formal <- feols(index_formal ~ treat_post | country + size_factor + factor(year),
                   data = did_data, cluster = ~country)

m3_formal <- feols(index_formal ~ treat_post | country + size_factor + country^factor(year),
                   data = did_data, cluster = ~country)

cat("Formal Compliance Index Results:\n")
etable(m1_formal, m2_formal, m3_formal, se = "cluster")

# ----------------------------------------------------------------
# 4. Main DiD: Compliance Gap (Formal - Technical)
# ----------------------------------------------------------------

cat("\n--- DiD: Compliance Gap ---\n")

m1_gap <- feols(compliance_gap ~ treat_post | size_factor + factor(year),
                data = did_data, cluster = ~country)

m2_gap <- feols(compliance_gap ~ treat_post | country + size_factor + factor(year),
                data = did_data, cluster = ~country)

m3_gap <- feols(compliance_gap ~ treat_post | country + size_factor + country^factor(year),
                data = did_data, cluster = ~country)

cat("Compliance Gap Results:\n")
etable(m1_gap, m2_gap, m3_gap, se = "cluster")

# ----------------------------------------------------------------
# 5. Individual indicator-level DiD
# ----------------------------------------------------------------

cat("\n--- Individual Indicator DiD ---\n")

ind_panel <- indicator_panel %>%
  filter(size_class %in% c("10-49", "50-249"))

# Run DiD for each indicator with country × year FE
indicator_results <- ind_panel %>%
  group_by(indicator, measure_type) %>%
  group_modify(~{
    m <- tryCatch(
      feols(value ~ treat_post | country + size_factor + country^factor(year),
            data = .x, cluster = ~country),
      error = function(e) NULL
    )
    if (is.null(m)) return(tibble(beta = NA, se = NA, pval = NA, n = nrow(.x)))
    tibble(
      beta = coef(m)["treat_post"],
      se = se(m)["treat_post"],
      pval = pvalue(m)["treat_post"],
      n = nrow(.x)
    )
  }) %>%
  ungroup() %>%
  arrange(measure_type, desc(abs(beta)))

cat("\nIndividual indicator effects (country × year FE, clustered by country):\n")
print(indicator_results, n = 20)

# ----------------------------------------------------------------
# 6. Triple-Difference (DDD): Transposition timing
# ----------------------------------------------------------------

cat("\n--- Triple-Difference: Transposition Status ---\n")

# DDD: treated × post × transposed
m_ddd_tech <- feols(index_technical ~ treat_post + treat_post_trans +
                      post:transposed |
                      country + size_factor + factor(year),
                    data = did_data, cluster = ~country)

m_ddd_formal <- feols(index_formal ~ treat_post + treat_post_trans +
                        post:transposed |
                        country + size_factor + factor(year),
                      data = did_data, cluster = ~country)

cat("DDD - Technical:\n")
summary(m_ddd_tech)
cat("\nDDD - Formal:\n")
summary(m_ddd_formal)

# ----------------------------------------------------------------
# 7. Dosage test: Include GE250 firms
# ----------------------------------------------------------------

cat("\n--- Dosage Test: Including 250+ Firms ---\n")

dosage_data <- indices %>%
  mutate(
    # GE250 already under NIS1 — intensification, not new coverage
    newly_covered = as.integer(size_class == "50-249"),
    intensified = as.integer(size_class == "GE250"),
    newly_post = newly_covered * post,
    intensified_post = intensified * post
  )

m_dose_tech <- feols(index_technical ~ newly_post + intensified_post |
                       country + size_factor + factor(year),
                     data = dosage_data, cluster = ~country)

m_dose_formal <- feols(index_formal ~ newly_post + intensified_post |
                         country + size_factor + factor(year),
                       data = dosage_data, cluster = ~country)

cat("Dosage - Technical:\n")
summary(m_dose_tech)
cat("\nDosage - Formal:\n")
summary(m_dose_formal)

# ----------------------------------------------------------------
# 8. Pre-trends check (event study with 3 periods)
# ----------------------------------------------------------------

cat("\n--- Pre-Trends Check ---\n")

did_data_es <- did_data %>%
  mutate(
    year_factor = factor(year, levels = c(2022, 2019, 2024)),  # 2022 as reference
    treat_2019 = treated * as.integer(year == 2019),
    treat_2024 = treated * as.integer(year == 2024)
  )

es_tech <- feols(index_technical ~ treat_2019 + treat_2024 |
                   country + size_factor + factor(year),
                 data = did_data_es, cluster = ~country)

es_formal <- feols(index_formal ~ treat_2019 + treat_2024 |
                     country + size_factor + factor(year),
                   data = did_data_es, cluster = ~country)

cat("Event study - Technical (2022 = reference):\n")
etable(es_tech, se = "cluster")

cat("\nEvent study - Formal (2022 = reference):\n")
etable(es_formal, se = "cluster")

# ----------------------------------------------------------------
# 9. Permutation inference (randomize country assignment)
# ----------------------------------------------------------------

cat("\n--- Permutation Inference ---\n")

set.seed(42)
n_perms <- 1000

# Get actual DiD coefficient (technical, preferred spec with country × year FE)
actual_beta_tech <- coef(m3_tech)["treat_post"]
actual_beta_formal <- coef(m3_formal)["treat_post"]

# Permute treatment across countries (not size classes — treatment is size-based)
# Instead, permute the country labels to break the country × year structure
countries <- unique(did_data$country)
n_countries <- length(countries)

perm_betas_tech <- numeric(n_perms)
perm_betas_formal <- numeric(n_perms)

for (i in 1:n_perms) {
  # Randomly reassign treated/control within each country-year
  # (shuffle size class labels)
  perm_data <- did_data %>%
    group_by(country, year) %>%
    mutate(
      perm_treated = sample(treated),
      perm_treat_post = perm_treated * post
    ) %>%
    ungroup()

  m_perm_tech <- tryCatch(
    feols(index_technical ~ perm_treat_post | country + size_factor + country^factor(year),
          data = perm_data, cluster = ~country),
    error = function(e) NULL
  )

  m_perm_formal <- tryCatch(
    feols(index_formal ~ perm_treat_post | country + size_factor + country^factor(year),
          data = perm_data, cluster = ~country),
    error = function(e) NULL
  )

  if (!is.null(m_perm_tech)) perm_betas_tech[i] <- coef(m_perm_tech)["perm_treat_post"]
  if (!is.null(m_perm_formal)) perm_betas_formal[i] <- coef(m_perm_formal)["perm_treat_post"]
}

ri_p_tech <- mean(abs(perm_betas_tech) >= abs(actual_beta_tech))
ri_p_formal <- mean(abs(perm_betas_formal) >= abs(actual_beta_formal))

cat(sprintf("RI p-value (Technical): %.3f (actual beta = %.3f)\n",
            ri_p_tech, actual_beta_tech))
cat(sprintf("RI p-value (Formal): %.3f (actual beta = %.3f)\n",
            ri_p_formal, actual_beta_formal))

# ----------------------------------------------------------------
# 10. Save results
# ----------------------------------------------------------------

results <- list(
  # Main DiD
  m1_tech = m1_tech, m2_tech = m2_tech, m3_tech = m3_tech,
  m1_formal = m1_formal, m2_formal = m2_formal, m3_formal = m3_formal,
  m1_gap = m1_gap, m2_gap = m2_gap, m3_gap = m3_gap,

  # Event study
  es_tech = es_tech, es_formal = es_formal,

  # DDD
  m_ddd_tech = m_ddd_tech, m_ddd_formal = m_ddd_formal,

  # Dosage
  m_dose_tech = m_dose_tech, m_dose_formal = m_dose_formal,

  # Individual indicators
  indicator_results = indicator_results,

  # Permutation inference
  ri_p_tech = ri_p_tech, ri_p_formal = ri_p_formal,
  perm_betas_tech = perm_betas_tech, perm_betas_formal = perm_betas_formal,
  actual_beta_tech = actual_beta_tech, actual_beta_formal = actual_beta_formal
)

saveRDS(results, "data/main_results.rds")

# ----------------------------------------------------------------
# 11. Diagnostics for validator
# ----------------------------------------------------------------

n_treated <- n_distinct(did_data$country[did_data$treated == 1])
n_pre <- length(unique(did_data$year[did_data$year < 2024]))
n_obs <- nrow(did_data)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs
)

jsonlite::write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE)

cat(sprintf("\n=== Diagnostics ===\n"))
cat(sprintf("n_treated (countries with 50-249 class): %d\n", n_treated))
cat(sprintf("n_pre (pre-treatment periods): %d\n", n_pre))
cat(sprintf("n_obs (total observations): %d\n", n_obs))
cat("=== Main analysis complete ===\n")
