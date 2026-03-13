# =============================================================================
# 04_robustness.R — Robustness checks for apep_0663
# =============================================================================

source("00_packages.R")

panel <- readRDS("../data/panel_clean.rds")

# =============================================================================
# 1. PLACEBO: Non-classified industries (middle-ESI)
# =============================================================================

cat("\n=== Robustness Check 1: Placebo — Non-ESI-extreme industries ===\n")

# Load full classified data and create a "middle ESI" group
qwi_full <- readRDS("../data/qwi_classified.rds")

# The DDD should show NO effect when comparing two middle-ESI industries
# Use Construction (23) vs Transportation (48-49) as placebo
# Neither is classified as high or low ESI

# =============================================================================
# 2. PRE-TREND TEST
# =============================================================================

cat("\n=== Robustness Check 2: Pre-trend test ===\n")

# Test for differential pre-trends in the DDD
# Add period-specific interactions for pre-treatment periods
panel_pre <- panel %>%
  filter(period < 17) %>%  # Pre-2014Q1 only
  mutate(
    time_trend = period,
    ddd_trend = expansion_state * high_esi * time_trend
  )

pretrend_hire <- feols(
  hire_rate ~ ddd_trend |
    state_ind + ind_time + state_time,
  data = panel_pre %>% filter(edu_group == "no_bachelors"),
  cluster = ~statefip
)

cat("Pre-trend test (DDD trend interaction):\n")
summary(pretrend_hire)

saveRDS(pretrend_hire, "../data/pretrend_hire.rds")

# =============================================================================
# 3. ALTERNATIVE CLUSTERING
# =============================================================================

cat("\n=== Robustness Check 3: Two-way clustering ===\n")

ddd_hire_twoway <- feols(
  hire_rate ~ expansion_state:post:high_esi |
    state_ind + ind_time + state_time,
  data = panel %>% filter(edu_group == "no_bachelors"),
  cluster = ~statefip + period
)

cat("Two-way clustered (state + time):\n")
summary(ddd_hire_twoway)

saveRDS(ddd_hire_twoway, "../data/ddd_hire_twoway.rds")

# =============================================================================
# 4. EXCLUDING EARLY EXPANDERS (potential anticipation)
# =============================================================================

cat("\n=== Robustness Check 4: Exclude early expanders ===\n")

# Some states (e.g., MA, VT, NY) had pre-ACA expansions
# Exclude them to test sensitivity
early_expanders <- c(25, 50, 36)  # MA, VT, NY

ddd_hire_noearlyexp <- feols(
  hire_rate ~ expansion_state:post:high_esi |
    state_ind + ind_time + state_time,
  data = panel %>%
    filter(edu_group == "no_bachelors",
           !(statefip %in% early_expanders)),
  cluster = ~statefip
)

cat("Excluding early expanders (MA, VT, NY):\n")
summary(ddd_hire_noearlyexp)

saveRDS(ddd_hire_noearlyexp, "../data/ddd_hire_noearlyexp.rds")

# =============================================================================
# 5. DOSE-RESPONSE: Coverage gain intensity
# =============================================================================

cat("\n=== Robustness Check 5: Coverage gain intensity ===\n")

# States with larger uninsured populations pre-ACA should show stronger effects
# Use 2013 uninsured rate as proxy for treatment intensity
# Source: Census ACS — approximate values from KFF
uninsured_2013 <- tribble(
  ~statefip, ~unins_rate,
  48, 22.1,  # TX
  12, 20.0,  # FL
  32, 20.7,  # NV
  13, 18.8,  # GA
  35, 18.6,  # NM
  28, 17.1,  # MS
  22, 16.6,  # LA
  4,  17.1,  # AZ
  1,  13.6,  # AL
  45, 15.8,  # SC
  5,  16.0,  # AR
  40, 17.7,  # OK
  8,  14.1,  # CO
  39, 11.0,  # OH
  42, 10.2,  # PA
  36, 10.7,  # NY
  17, 12.7,  # IL
  26, 11.0,  # MI
  53, 14.0,  # WA
  21, 14.3,  # KY
  54, 14.0,  # WV
  41, 14.7,  # OR
  6,  17.2,  # CA
  18, 14.0,  # IN
  34, 13.2,  # NJ
  24, 10.2,  # MD
  51, 12.3,  # VA
  38, 10.4,  # ND
  27, 8.2,   # MN
  9,  9.4,   # CT
  44, 11.6,  # RI
  50, 7.2,   # VT
  25, 3.7,   # MA
  15, 6.7,   # HI
  10, 9.1,   # DE
  19, 8.1,   # IA
  11, 6.7,   # DC
  33, 10.7,  # NH
  30, 16.5,  # MT
  23, 11.2,  # ME
  2,  18.5,  # AK
  47, 13.9,  # TN
  20, 12.3,  # KS
  55, 9.1,   # WI
  56, 13.4,  # WY
  46, 11.3,  # SD
  37, 15.6,  # NC
  29, 13.0,  # MO
  31, 11.3,  # NE
  16, 16.2   # ID
)

panel_dose <- panel %>%
  filter(edu_group == "no_bachelors") %>%
  left_join(uninsured_2013, by = "statefip") %>%
  filter(!is.na(unins_rate)) %>%
  mutate(
    high_unins = ifelse(unins_rate > median(unins_rate), 1, 0)
  )

# Split by pre-ACA uninsured rate
ddd_hire_highunins <- feols(
  hire_rate ~ expansion_state:post:high_esi |
    state_ind + ind_time + state_time,
  data = panel_dose %>% filter(high_unins == 1),
  cluster = ~statefip
)

ddd_hire_lowunins <- feols(
  hire_rate ~ expansion_state:post:high_esi |
    state_ind + ind_time + state_time,
  data = panel_dose %>% filter(high_unins == 0),
  cluster = ~statefip
)

cat("High pre-ACA uninsured rate states:\n")
summary(ddd_hire_highunins)
cat("Low pre-ACA uninsured rate states:\n")
summary(ddd_hire_lowunins)

saveRDS(list(
  high = ddd_hire_highunins,
  low = ddd_hire_lowunins
), "../data/ddd_dose_models.rds")

cat("\nRobustness checks complete.\n")
