# 04_robustness.R — Robustness checks and placebo tests
# apep_0955: AAA Cotton Acreage Reduction and Black Sharecropper Children

source("00_packages.R")

sibling_dt <- readRDS("../data/analysis_siblings.rds")
results <- readRDS("../data/main_results.rds")

cat("Robustness sample:", nrow(sibling_dt), "siblings\n")

# ============================================================================
# 1. Leave-one-state-out
# ============================================================================
cat("\n=== Leave-one-state-out ===\n")

states <- unique(sibling_dt$statefip_1930)
loso_educ <- lapply(states, function(s) {
  sub_dt <- sibling_dt[statefip_1930 != s]
  m <- feols(educ_years_1940 ~ aaa_intensity_z:school_age + age_1930 + female |
               serial_1930, data = sub_dt, cluster = ~countyicp_1930)
  data.table(
    dropped_state = s,
    coef = coef(m)["aaa_intensity_z:school_age"],
    se = se(m)["aaa_intensity_z:school_age"],
    n = nrow(sub_dt)
  )
})
loso_educ <- rbindlist(loso_educ)
cat("LOSO coefficients (educ_years_1940):\n")
print(loso_educ)

loso_occ <- lapply(states, function(s) {
  sub_dt <- sibling_dt[statefip_1930 != s]
  m <- feols(occscore_1950 ~ aaa_intensity_z:school_age + age_1930 + female |
               serial_1930, data = sub_dt, cluster = ~countyicp_1930)
  data.table(
    dropped_state = s,
    coef = coef(m)["aaa_intensity_z:school_age"],
    se = se(m)["aaa_intensity_z:school_age"]
  )
})
loso_occ <- rbindlist(loso_occ)
cat("LOSO coefficients (occscore_1950):\n")
print(loso_occ)

# ============================================================================
# 2. Alternative clustering (state level)
# ============================================================================
cat("\n=== Alternative clustering ===\n")

m_state_cluster <- feols(educ_years_1940 ~ aaa_intensity_z:school_age + age_1930 + female |
                           serial_1930,
                         data = sibling_dt, cluster = ~statefip_1930)
cat("State-clustered SE:", se(m_state_cluster)["aaa_intensity_z:school_age"], "\n")
cat("County-clustered SE:", se(results$main$educ_years_1940)["aaa_intensity_z:school_age"], "\n")

# ============================================================================
# 3. Placebo age cutoff — children too young to be affected
# ============================================================================
cat("\n=== Placebo: Very young children (0-3 in 1930, 3-6 in 1933) ===\n")

# Among siblings who were ALL under 8 in 1933, there should be no
# differential effect of AAA by age
young_only <- sibling_dt[age_1933 <= 8]
young_only[, n_sib_young := .N, by = serial_1930]
young_only <- young_only[n_sib_young >= 2]

if (nrow(young_only) > 1000) {
  # Use continuous age for this subsample
  m_placebo_young <- feols(educ_years_1940 ~ aaa_intensity_z:age_1930 + female |
                             serial_1930,
                           data = young_only, cluster = ~countyicp_1930)
  cat("Placebo (young only):", coef(m_placebo_young)["aaa_intensity_z:age_1930"],
      "se:", se(m_placebo_young)["aaa_intensity_z:age_1930"], "\n")
} else {
  cat("Placebo: insufficient young-only sample (n =", nrow(young_only), ")\n")
  m_placebo_young <- NULL
}

# ============================================================================
# 4. Continuous age interaction (dose-response)
# ============================================================================
cat("\n=== Continuous age interaction ===\n")

m_cont_educ <- feols(educ_years_1940 ~ aaa_intensity_z:age_at_aaa +
                       I(aaa_intensity_z * age_at_aaa^2) + female |
                       serial_1930,
                     data = sibling_dt, cluster = ~countyicp_1930)

cat("Linear age × AAA:", coef(m_cont_educ)["aaa_intensity_z:age_at_aaa"], "\n")

# ============================================================================
# 5. Gender heterogeneity
# ============================================================================
cat("\n=== Gender heterogeneity ===\n")

m_male <- feols(educ_years_1940 ~ aaa_intensity_z:school_age + age_1930 |
                  serial_1930,
                data = sibling_dt[female == 0], cluster = ~countyicp_1930)

m_female <- feols(educ_years_1940 ~ aaa_intensity_z:school_age + age_1930 |
                    serial_1930,
                  data = sibling_dt[female == 1], cluster = ~countyicp_1930)

cat("Male coef:", coef(m_male)["aaa_intensity_z:school_age"],
    "se:", se(m_male)["aaa_intensity_z:school_age"], "\n")
cat("Female coef:", coef(m_female)["aaa_intensity_z:school_age"],
    "se:", se(m_female)["aaa_intensity_z:school_age"], "\n")

# ============================================================================
# 6. High vs Low AAA terciles
# ============================================================================
cat("\n=== High vs Low AAA terciles ===\n")

m_high <- feols(educ_years_1940 ~ school_age + age_1930 + female | serial_1930,
                data = sibling_dt[aaa_tercile == "high"], cluster = ~countyicp_1930)

m_low <- feols(educ_years_1940 ~ school_age + age_1930 + female | serial_1930,
               data = sibling_dt[aaa_tercile == "low"], cluster = ~countyicp_1930)

cat("High AAA tercile, school_age:", coef(m_high)["school_age"],
    "se:", se(m_high)["school_age"], "\n")
cat("Low AAA tercile, school_age:", coef(m_low)["school_age"],
    "se:", se(m_low)["school_age"], "\n")

# ============================================================================
# Save robustness results
# ============================================================================
robust_results <- list(
  loso_educ = loso_educ,
  loso_occ = loso_occ,
  state_cluster = m_state_cluster,
  placebo_young = m_placebo_young,
  continuous_age = m_cont_educ,
  gender = list(male = m_male, female = m_female),
  terciles = list(high = m_high, low = m_low)
)

saveRDS(robust_results, "../data/robustness_results.rds")
cat("\n=== Robustness checks complete ===\n")
