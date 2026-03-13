# ==============================================================================
# 04_robustness.R — Robustness checks and placebo tests
# The Enclave as Insurance and Trap
# ==============================================================================

source("00_packages.R")

df <- readRDS("../data/analysis_sample.rds")
panel_boom <- readRDS("../data/panel_boom.rds")
county_pops <- readRDS("../data/county_coethnic_1920.rds")
county_totals <- readRDS("../data/county_totals_1920.rds")

# Standardize as in main analysis
df <- df %>%
  mutate(
    coethnic_share_z = (coethnic_share - mean(coethnic_share)) / sd(coethnic_share),
    high_selfempl_natl = as.integer(natl_selfempl_rate > median(natl_selfempl_rate, na.rm = TRUE))
  )

# --------------------------------------------------------------------------
# 1. PLACEBO: Boom-period (1920-1930) — enclave effect should be near zero
# --------------------------------------------------------------------------

cat("=== Placebo: Boom Period (1920-1930) ===\n")

# Prepare boom panel with same variables
bpl_labels <- tribble(
  ~bpl_code, ~nationality,
  410, "England", 411, "Scotland", 412, "Wales", 413, "N. Ireland",
  414, "Ireland", 420, "France", 421, "Albania",
  425, "Netherlands", 426, "Belgium", 429, "Germany",
  430, "Poland", 433, "Austria", 434, "Hungary", 436, "Czechoslovakia",
  438, "Switzerland", 440, "Denmark", 441, "Norway", 442, "Sweden",
  443, "Finland", 450, "Italy", 451, "Portugal", 452, "Spain",
  453, "Greece", 454, "Turkey", 455, "Romania", 457, "Yugoslavia",
  460, "Russia/USSR", 461, "Lithuania", 462, "Latvia", 463, "Estonia",
  465, "Other USSR"
)

county_data <- county_pops %>%
  left_join(county_totals, by = c("statefip_1920", "countyicp_1920")) %>%
  mutate(coethnic_share = n_coethnic / county_pop)

natl_selfempl <- readRDS("../data/natl_selfempl.rds")

boom <- panel_boom %>%
  left_join(bpl_labels, by = c("bpl_1920" = "bpl_code")) %>%
  left_join(
    county_data %>% select(statefip_1920, countyicp_1920, bpl_1920, coethnic_share),
    by = c("statefip_1920", "countyicp_1920", "bpl_1920")
  ) %>%
  left_join(
    natl_selfempl %>% select(bpl_1920, natl_selfempl_rate),
    by = "bpl_1920"
  ) %>%
  filter(
    !is.na(occscore_1920) & occscore_1920 > 0,
    !is.na(occscore_1930) & occscore_1930 > 0,
    !is.na(coethnic_share),
    coethnic_share > 0,
    !is.na(nationality)
  ) %>%
  mutate(
    delta_occscore_boom = occscore_1930 - occscore_1920,
    selfempl_1920 = as.integer(classwkr_1920 == 1),
    in_school_1920 = as.integer(school_1920 == 2),
    county_id = paste0(statefip_1920, "_", countyicp_1920)
  )

# Keep same nationalities as main analysis
natl_keep <- unique(df$nationality)
boom <- boom %>% filter(nationality %in% natl_keep)

boom <- boom %>%
  mutate(coethnic_share_z = (coethnic_share - mean(coethnic_share)) / sd(coethnic_share))

# Placebo regression
m_placebo <- feols(delta_occscore_boom ~ coethnic_share_z + age_1920 +
                     I(age_1920^2) + in_school_1920 + selfempl_1920 + occscore_1920 |
                     nationality + statefip_1920,
                   data = boom,
                   cluster = ~county_id)

cat("\nPlacebo (boom period) vs Main (bust period):\n")
m_bust <- feols(delta_occscore_bust ~ coethnic_share_z + age_1920 +
                  I(age_1920^2) + in_school_1920 + selfempl_1920 + occscore_1920 |
                  nationality + statefip_1920,
                data = df,
                cluster = ~county_id)

etable(m_placebo, m_bust,
       headers = c("Boom (1920-30)", "Bust (1930-40)"),
       dict = c(coethnic_share_z = "Co-ethnic share (std)"))

# --------------------------------------------------------------------------
# 2. Nationality-specific placebo (boom period)
# --------------------------------------------------------------------------

cat("\n=== Nationality-Specific Placebo ===\n")

placebo_natl <- boom %>%
  group_by(nationality) %>%
  filter(n() >= 5000) %>%
  group_split() %>%
  map_dfr(function(d) {
    natl <- unique(d$nationality)
    mod <- feols(delta_occscore_boom ~ coethnic_share_z + age_1920 +
                   I(age_1920^2) + in_school_1920 + selfempl_1920 + occscore_1920 |
                   statefip_1920,
                 data = d,
                 cluster = ~county_id)
    tibble(
      nationality = natl,
      N_boom = nrow(d),
      beta_boom = coef(mod)["coethnic_share_z"],
      se_boom = se(mod)["coethnic_share_z"]
    )
  })

# Merge with bust results
natl_results <- readRDS("../data/natl_results.rds")
comparison <- natl_results %>%
  select(nationality, N, beta_bust = beta, se_bust = se) %>%
  left_join(placebo_natl, by = "nationality") %>%
  mutate(
    diff = beta_bust - beta_boom,
    boom_sig = abs(beta_boom / se_boom) > 1.96
  )

cat("\nBoom vs Bust coefficients by nationality:\n")
comparison %>%
  arrange(desc(beta_bust)) %>%
  select(nationality, beta_boom, se_boom, boom_sig, beta_bust, se_bust, diff) %>%
  print(n = 30)

# --------------------------------------------------------------------------
# 3. Leave-one-nationality-out robustness
# --------------------------------------------------------------------------

cat("\n=== Leave-One-Nationality-Out ===\n")

lono_results <- unique(df$nationality) %>%
  map_dfr(function(natl) {
    d <- df %>% filter(nationality != natl)
    mod <- feols(delta_occscore_bust ~ coethnic_share_z * high_selfempl_natl +
                   age_1920 + I(age_1920^2) + in_school_1920 + selfempl_1920 + occscore_1920 |
                   nationality + statefip_1920,
                 data = d,
                 cluster = ~county_id)

    beta_main <- coef(mod)["coethnic_share_z"]
    beta_inter <- coef(mod)["coethnic_share_z:high_selfempl_natl"]

    tibble(
      dropped = natl,
      beta_enclave = beta_main,
      beta_interaction = beta_inter
    )
  })

cat("\nLeave-one-nationality-out (mechanism interaction):\n")
cat(sprintf("  Interaction range: [%.4f, %.4f]\n",
            min(lono_results$beta_interaction),
            max(lono_results$beta_interaction)))
cat(sprintf("  Mean: %.4f, SD: %.4f\n",
            mean(lono_results$beta_interaction),
            sd(lono_results$beta_interaction)))

# --------------------------------------------------------------------------
# 4. Alternative enclave measures
# --------------------------------------------------------------------------

cat("\n=== Alternative Enclave Measures ===\n")

# Log co-ethnic share
df <- df %>%
  mutate(log_coethnic = log(coethnic_share + 0.001))

m_log <- feols(delta_occscore_bust ~ log_coethnic + age_1920 +
                 I(age_1920^2) + in_school_1920 + selfempl_1920 + occscore_1920 |
                 nationality + statefip_1920,
               data = df,
               cluster = ~county_id)

# Quintile dummies (nonlinear effects)
m_quint <- feols(delta_occscore_bust ~ i(enclave_quintile, ref = 1) +
                   age_1920 + I(age_1920^2) + in_school_1920 + selfempl_1920 + occscore_1920 |
                   nationality + statefip_1920,
                 data = df,
                 cluster = ~county_id)

cat("\nAlternative measures:\n")
etable(m_bust, m_log, m_quint,
       headers = c("Std share", "Log share", "Quintiles"),
       dict = c(coethnic_share_z = "Co-ethnic share (std)",
                log_coethnic = "Log co-ethnic share"))

# --------------------------------------------------------------------------
# 5. County fixed effects (within-county, across-nationality variation)
# --------------------------------------------------------------------------

cat("\n=== County FE Specification ===\n")

m_county_fe <- feols(delta_occscore_bust ~ coethnic_share_z + age_1920 +
                       I(age_1920^2) + in_school_1920 + selfempl_1920 + occscore_1920 |
                       nationality + county_id,
                     data = df,
                     cluster = ~county_id)

m_county_mech <- feols(delta_occscore_bust ~ coethnic_share_z * high_selfempl_natl +
                         age_1920 + I(age_1920^2) + in_school_1920 + selfempl_1920 + occscore_1920 |
                         nationality + county_id,
                       data = df,
                       cluster = ~county_id)

cat("\nCounty FE results:\n")
etable(m_bust, m_county_fe, m_county_mech,
       headers = c("State FE", "County FE", "County FE + Mech"),
       dict = c(coethnic_share_z = "Co-ethnic share (std)"))

# --------------------------------------------------------------------------
# 6. Save robustness results
# --------------------------------------------------------------------------

robustness <- list(
  placebo = m_placebo,
  bust = m_bust,
  lono = lono_results,
  placebo_natl = comparison,
  county_fe = m_county_fe,
  county_mech = m_county_mech,
  log = m_log,
  quintile = m_quint
)

saveRDS(robustness, "../data/robustness_models.rds")

cat("\nRobustness checks complete.\n")
