# 04_robustness.R — Robustness checks
# APEP 1456: DPA Enforcement Intensity and Startup Survival

source("00_packages.R")

cat("=== Robustness checks for APEP 1456 ===\n")

ict_panel <- readRDS("../data/ict_panel.rds")
construction_panel <- readRDS("../data/construction_panel.rds")
results <- readRDS("../data/main_results.rds")

# ---------------------------------------------------------------
# 1. Placebo sector: Construction (NACE F)
# ---------------------------------------------------------------
cat("\n--- Placebo: Construction sector ---\n")

const_data <- construction_panel %>%
  filter(year >= 2013, year <= 2021, !is.na(surv_1yr))

placebo_surv <- feols(surv_1yr ~ post_enforcement | geo + year,
                      data = const_data, cluster = ~geo)
placebo_birth <- feols(birth_rate ~ post_enforcement | geo + year,
                       data = const_data %>% filter(!is.na(birth_rate)),
                       cluster = ~geo)

cat("Placebo (Construction) — 1-year survival:\n")
summary(placebo_surv)
cat("Placebo (Construction) — Birth rate:\n")
summary(placebo_birth)

# ---------------------------------------------------------------
# 2. Exclude COVID year (2020)
# ---------------------------------------------------------------
cat("\n--- Excluding COVID year 2020 ---\n")

ict_no_covid <- ict_panel %>%
  filter(year >= 2013, year <= 2021, year != 2020, !is.na(surv_1yr))

nocovid_surv <- feols(surv_1yr ~ post_enforcement | geo + year,
                      data = ict_no_covid, cluster = ~geo)
nocovid_birth <- feols(birth_rate ~ post_enforcement | geo + year,
                       data = ict_no_covid %>% filter(!is.na(birth_rate)),
                       cluster = ~geo)

cat("No-COVID — 1-year survival:\n")
summary(nocovid_surv)

# ---------------------------------------------------------------
# 3. Pre-2018 placebo test (fake treatment in 2016)
# ---------------------------------------------------------------
cat("\n--- Pre-2018 placebo (fake treatment 2016) ---\n")

# Assign same enforcement groups but shift treatment to 2016
ict_preplacebo <- ict_panel %>%
  filter(year >= 2012, year <= 2017) %>%
  mutate(
    fake_post = as.integer(year >= 2016)
  ) %>%
  filter(!is.na(surv_1yr))

if (nrow(ict_preplacebo) > 20) {
  # Only run for countries that eventually got treated (early enforcers)
  early_enforcers <- ict_panel %>%
    filter(first_fine_year <= 2019) %>%
    pull(geo) %>%
    unique()

  late_enforcers <- ict_panel %>%
    filter(first_fine_year > 2019 | first_fine_year >= 9999L) %>%
    pull(geo) %>%
    unique()

  preplacebo_data <- ict_preplacebo %>%
    mutate(
      fake_treated = as.integer(geo %in% early_enforcers),
      fake_post_x_treat = fake_post * fake_treated
    )

  preplacebo_surv <- feols(surv_1yr ~ fake_post_x_treat | geo + year,
                           data = preplacebo_data, cluster = ~geo)
  cat("Pre-placebo — 1-year survival (fake 2016 treatment):\n")
  summary(preplacebo_surv)
} else {
  cat("Insufficient pre-period data for pre-placebo test\n")
  preplacebo_surv <- NULL
}

# ---------------------------------------------------------------
# 4. Continuous treatment: cumulative fines per GDP
# ---------------------------------------------------------------
cat("\n--- Continuous treatment intensity ---\n")

cont_data <- ict_panel %>%
  filter(year >= 2013, year <= 2021, !is.na(surv_1yr))

cont_surv <- feols(surv_1yr ~ cum_fines_per_gdp | geo + year,
                   data = cont_data, cluster = ~geo)
cont_birth <- feols(birth_rate ~ cum_fines_per_gdp | geo + year,
                    data = cont_data %>% filter(!is.na(birth_rate)),
                    cluster = ~geo)

cat("Continuous treatment — 1-year survival:\n")
summary(cont_surv)

# ---------------------------------------------------------------
# 5. 3-year survival rate (longer-term effect)
# ---------------------------------------------------------------
cat("\n--- 3-year survival rate ---\n")

surv3_data <- ict_panel %>%
  filter(year >= 2013, year <= 2021, !is.na(surv_3yr))

if (nrow(surv3_data) > 20) {
  surv3_model <- feols(surv_3yr ~ post_enforcement | geo + year,
                       data = surv3_data, cluster = ~geo)
  cat("3-year survival:\n")
  summary(surv3_model)
} else {
  cat("Insufficient data for 3-year survival analysis\n")
  surv3_model <- NULL
}

# ---------------------------------------------------------------
# Save robustness results
# ---------------------------------------------------------------
robust_results <- list(
  placebo_surv = placebo_surv,
  placebo_birth = placebo_birth,
  nocovid_surv = nocovid_surv,
  nocovid_birth = nocovid_birth,
  preplacebo_surv = preplacebo_surv,
  cont_surv = cont_surv,
  cont_birth = cont_birth,
  surv3_model = surv3_model
)

saveRDS(robust_results, "../data/robust_results.rds")

cat("=== Robustness checks complete ===\n")
