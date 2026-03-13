# ==============================================================================
# 03_main_analysis.R — Main regressions
# The Enclave as Insurance and Trap
# ==============================================================================

source("00_packages.R")

df <- readRDS("../data/analysis_sample.rds")

# --------------------------------------------------------------------------
# 1. Main specification: Pooled enclave effect on Depression-era mobility
# --------------------------------------------------------------------------

cat("=== Main Specification: Pooled Enclave Effect ===\n")

# Standardize co-ethnic share (mean 0, SD 1) for interpretability
df <- df %>%
  mutate(coethnic_share_z = (coethnic_share - mean(coethnic_share)) / sd(coethnic_share))

# Main OLS: occupational score change on enclave density
# Cluster SEs at county level (unit of treatment variation)
m1 <- feols(delta_occscore_bust ~ coethnic_share_z |
              nationality + statefip_1920,
            data = df,
            cluster = ~county_id)

# Add individual controls
m2 <- feols(delta_occscore_bust ~ coethnic_share_z + age_1920 +
              I(age_1920^2) + in_school_1920 + selfempl_1920 + occscore_1920 |
              nationality + statefip_1920,
            data = df,
            cluster = ~county_id)

# Binary outcomes
m3 <- feols(downgrade_bust ~ coethnic_share_z + age_1920 +
              I(age_1920^2) + in_school_1920 + selfempl_1920 + occscore_1920 |
              nationality + statefip_1920,
            data = df,
            cluster = ~county_id)

m4 <- feols(large_downgrade_bust ~ coethnic_share_z + age_1920 +
              I(age_1920^2) + in_school_1920 + selfempl_1920 + occscore_1920 |
              nationality + statefip_1920,
            data = df,
            cluster = ~county_id)

m5 <- feols(lost_home ~ coethnic_share_z + age_1920 +
              I(age_1920^2) + in_school_1920 + selfempl_1920 + occscore_1920 |
              nationality + statefip_1920,
            data = df,
            cluster = ~county_id)

cat("\nPooled results:\n")
etable(m1, m2, m3, m4, m5,
       dict = c(coethnic_share_z = "Co-ethnic share (std)",
                delta_occscore_bust = "ΔOccScore",
                downgrade_bust = "Downgrade",
                large_downgrade_bust = "Large downgrade",
                lost_home = "Lost home"))

# --------------------------------------------------------------------------
# 2. Heterogeneity by nationality: The Insurance vs Trap pattern
# --------------------------------------------------------------------------

cat("\n=== Nationality-Specific Enclave Effects ===\n")

natl_results <- df %>%
  group_by(nationality) %>%
  filter(n() >= 5000) %>%
  group_split() %>%
  map_dfr(function(d) {
    natl <- unique(d$nationality)
    mod <- feols(delta_occscore_bust ~ coethnic_share_z + age_1920 +
                   I(age_1920^2) + in_school_1920 + selfempl_1920 + occscore_1920 |
                   statefip_1920,
                 data = d,
                 cluster = ~county_id)
    tibble(
      nationality = natl,
      N = nrow(d),
      beta = coef(mod)["coethnic_share_z"],
      se = se(mod)["coethnic_share_z"],
      selfempl_rate = unique(d$natl_selfempl_rate),
      mean_delta_occ = mean(d$delta_occscore_bust)
    )
  }) %>%
  arrange(desc(beta))

cat("\nNationality-specific enclave effects (sorted by β):\n")
natl_results %>%
  mutate(
    stars = case_when(
      abs(beta / se) > 2.576 ~ "***",
      abs(beta / se) > 1.96 ~ "**",
      abs(beta / se) > 1.645 ~ "*",
      TRUE ~ ""
    ),
    type = ifelse(beta > 0, "INSURANCE", "TRAP")
  ) %>%
  select(nationality, N, beta, se, stars, selfempl_rate, type) %>%
  print(n = 30)

# Save for table generation
saveRDS(natl_results, "../data/natl_results.rds")

# --------------------------------------------------------------------------
# 3. Mechanism test: Enclave × Self-employment interaction
# --------------------------------------------------------------------------

cat("\n=== Mechanism: Enclave × Self-Employment Structure ===\n")

# Create nationality-level high self-employment indicator
df <- df %>%
  mutate(high_selfempl_natl = as.integer(natl_selfempl_rate > median(natl_selfempl_rate, na.rm = TRUE)))

# Triple interaction
m_mech1 <- feols(delta_occscore_bust ~ coethnic_share_z * high_selfempl_natl +
                   age_1920 + I(age_1920^2) + in_school_1920 + selfempl_1920 + occscore_1920 |
                   nationality + statefip_1920,
                 data = df,
                 cluster = ~county_id)

# Continuous interaction with nationality self-employment rate
m_mech2 <- feols(delta_occscore_bust ~ coethnic_share_z * natl_selfempl_rate +
                   age_1920 + I(age_1920^2) + in_school_1920 + selfempl_1920 + occscore_1920 |
                   statefip_1920,
                 data = df,
                 cluster = ~county_id)

cat("\nMechanism results:\n")
etable(m_mech1, m_mech2,
       dict = c(coethnic_share_z = "Co-ethnic share (std)",
                high_selfempl_natl = "High self-empl nationality",
                natl_selfempl_rate = "Natl self-empl rate"))

# --------------------------------------------------------------------------
# 4. High-enclave vs low-enclave means by nationality type
# --------------------------------------------------------------------------

cat("\n=== Enclave Density and Depression Outcomes ===\n")

enclave_means <- df %>%
  mutate(type = ifelse(high_selfempl_natl == 1,
                       "Self-employed networks",
                       "Wage-dependent networks")) %>%
  group_by(type, high_enclave) %>%
  summarise(
    N = n(),
    mean_delta_occ = mean(delta_occscore_bust),
    se_delta_occ = sd(delta_occscore_bust) / sqrt(n()),
    downgrade_rate = mean(downgrade_bust),
    homeownership_loss = mean(lost_home, na.rm = TRUE),
    .groups = "drop"
  )

cat("\nEnclave density effects by network type:\n")
print(enclave_means)

# --------------------------------------------------------------------------
# 5. Save main model objects for table generation
# --------------------------------------------------------------------------

main_models <- list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5)
mech_models <- list(m_mech1 = m_mech1, m_mech2 = m_mech2)

saveRDS(main_models, "../data/main_models.rds")
saveRDS(mech_models, "../data/mech_models.rds")
saveRDS(enclave_means, "../data/enclave_means.rds")

# --------------------------------------------------------------------------
# 6. Write diagnostics.json
# --------------------------------------------------------------------------

diagnostics <- list(
  n_treated = n_distinct(df$county_id[df$high_enclave == 1]),
  n_pre = 1L,  # 1 pre-period decade (boom: 1920-1930)
  n_obs = nrow(df),
  n_nationalities = n_distinct(df$nationality),
  n_counties = n_distinct(df$county_id),
  mean_outcome = mean(df$delta_occscore_bust),
  sd_outcome = sd(df$delta_occscore_bust),
  method = "IV"  # Cross-sectional OLS with instrumental variation (not DiD)
)

write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\nDiagnostics written.\n")
cat(sprintf("  n_obs: %s\n", format(diagnostics$n_obs, big.mark = ",")))
cat(sprintf("  n_counties: %s\n", format(diagnostics$n_counties, big.mark = ",")))
cat(sprintf("  n_nationalities: %d\n", diagnostics$n_nationalities))
