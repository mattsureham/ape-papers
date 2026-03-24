## 03_main_analysis.R — Main econometric analysis: Triple-Difference
## APEP-0884: The World's Highest Minimum Wage

source("00_packages.R")
library(fixest)  # For feols, event studies
library(dplyr)   # For data manipulation

panel <- readRDS("../data/panel_statent.rds")
udemo <- readRDS("../data/panel_udemo.rds")

# ============================================================================
# Identify Geneva and Vaud codes
# ============================================================================

ge_code <- panel %>% filter(grepl("Gen", canton_name)) %>% pull(canton_code) %>% unique()
vd_code <- panel %>% filter(grepl("Vaud", canton_name)) %>% pull(canton_code) %>% unique()

cat("Geneva code:", ge_code, "| Vaud code:", vd_code, "\n")

# ============================================================================
# Restrict to Geneva and Vaud for main analysis
# ============================================================================

df <- panel %>%
  filter(canton_code %in% c(ge_code, vd_code)) %>%
  filter(!is.na(employment), employment > 0,
         !is.na(establishments), establishments > 0) %>%
  mutate(
    log_emp = log(employment),
    log_est = log(establishments),
    log_fte = log(fte + 1),
    # Interaction terms for DDD
    geneva_post = geneva * post,
    high_bite = as.integer(bite_group == "high_bite"),
    geneva_high = geneva * high_bite,
    post_high = post * high_bite,
    geneva_post_high = geneva * post * high_bite,
    # Factor variables for FE
    canton_noga_fe = factor(canton_noga),
    canton_year_fe = factor(canton_year),
    noga_year_fe = factor(noga_year)
  )

cat("Analysis sample: ", nrow(df), " obs\n")
cat("Geneva sectors:", sum(df$geneva == 1) / length(unique(df$year)), "\n")
cat("Vaud sectors:", sum(df$geneva == 0) / length(unique(df$year)), "\n")
cat("High-bite obs:", sum(df$high_bite == 1), "\n")
cat("Treatment group (GE x HighBite x Post):", sum(df$geneva_post_high == 1), "\n")

# ============================================================================
# Specification 1: Simple DiD (Geneva vs Vaud, all sectors pooled)
# Y_ct = α_c + γ_t + β(Geneva × Post) + ε_ct
# ============================================================================

cat("\n=== Specification 1: Simple DiD (pooled) ===\n")

# Aggregate to canton-year level
did_agg <- df %>%
  group_by(canton_code, canton_name, year, geneva, post) %>%
  summarise(
    employment = sum(employment, na.rm = TRUE),
    establishments = sum(establishments, na.rm = TRUE),
    fte = sum(fte, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    log_emp = log(employment),
    log_est = log(establishments),
    log_fte = log(fte),
    geneva_post = geneva * post
  )

# DiD regressions (canton + year FE)
did_emp <- feols(log_emp ~ geneva_post | canton_code + year,
                 data = did_agg, vcov = "hetero")
did_est <- feols(log_est ~ geneva_post | canton_code + year,
                 data = did_agg, vcov = "hetero")
did_fte <- feols(log_fte ~ geneva_post | canton_code + year,
                 data = did_agg, vcov = "hetero")

cat("\nDiD Employment:\n")
summary(did_emp)
cat("\nDiD Establishments:\n")
summary(did_est)

# ============================================================================
# Specification 2: Triple-Difference (DDD)
# Y_cst = α_cs + γ_ct + δ_st + β(Geneva × HighBite × Post) + ε_cst
# ============================================================================

cat("\n=== Specification 2: Triple-Difference (DDD) ===\n")

# Main DDD: canton-sector FE + canton-year FE + sector-year FE
ddd_emp <- feols(log_emp ~ geneva_post_high |
                   canton_noga + canton_year_fe + noga_year_fe,
                 data = df,
                 cluster = ~canton_noga)

ddd_est <- feols(log_est ~ geneva_post_high |
                   canton_noga + canton_year_fe + noga_year_fe,
                 data = df,
                 cluster = ~canton_noga)

ddd_fte <- feols(log_fte ~ geneva_post_high |
                   canton_noga + canton_year_fe + noga_year_fe,
                 data = df,
                 cluster = ~canton_noga)

cat("\nDDD Employment (main):\n")
summary(ddd_emp)
cat("\nDDD Establishments (main):\n")
summary(ddd_est)
cat("\nDDD FTE (main):\n")
summary(ddd_fte)

# ============================================================================
# Specification 3: Event Study (DDD with year interactions)
# ============================================================================

cat("\n=== Specification 3: Event Study ===\n")

# Create event time relative to 2020 (policy year)
df <- df %>%
  mutate(
    event_time = year - 2020,
    # Interaction: Geneva × HighBite × year dummies
    ge_high = geneva * high_bite
  )

# Event study using i() syntax in fixest
# Reference period: event_time = -1 (year 2019)
es_emp <- feols(log_emp ~ i(event_time, ge_high, ref = -1) |
                  canton_noga + canton_year_fe + noga_year_fe,
                data = df,
                cluster = ~canton_noga)

es_est <- feols(log_est ~ i(event_time, ge_high, ref = -1) |
                  canton_noga + canton_year_fe + noga_year_fe,
                data = df,
                cluster = ~canton_noga)

cat("\nEvent Study Employment:\n")
summary(es_emp)
cat("\nEvent Study Establishments:\n")
summary(es_est)

# ============================================================================
# Specification 4: Continuous treatment (sector bite intensity)
# Use employment share in low-wage NOGA as continuous treatment
# ============================================================================

cat("\n=== Specification 4: Continuous Bite ===\n")

# Assign bite intensity: 1 for high-bite, 0.5 for medium, 0 for low-bite
df <- df %>%
  mutate(
    bite_intensity = case_when(
      bite_group == "high_bite" ~ 1,
      bite_group == "medium" ~ 0.5,
      bite_group == "low_bite" ~ 0
    ),
    geneva_post_bite = geneva * post * bite_intensity
  )

cont_emp <- feols(log_emp ~ geneva_post_bite |
                    canton_noga + canton_year_fe + noga_year_fe,
                  data = df,
                  cluster = ~canton_noga)

cat("\nContinuous Bite Employment:\n")
summary(cont_emp)

# ============================================================================
# UDEMO: Simple DiD on firm births and deaths
# ============================================================================

cat("\n=== UDEMO: Firm Births and Deaths ===\n")

udemo_did <- udemo %>%
  mutate(
    log_births = log(births),
    log_closures = log(closures),
    log_active = log(active_firms),
    log_net = log(pmax(net_creation, 1)),
    geneva_post = geneva * post
  )

did_births <- feols(log_births ~ geneva_post | canton_code + year,
                    data = udemo_did, vcov = "hetero")
did_closures <- feols(log_closures ~ geneva_post | canton_code + year,
                      data = udemo_did, vcov = "hetero")
did_birth_rate <- feols(birth_rate ~ geneva_post | canton_code + year,
                        data = udemo_did, vcov = "hetero")

cat("\nDiD Firm Births:\n")
summary(did_births)
cat("\nDiD Firm Closures:\n")
summary(did_closures)
cat("\nDiD Birth Rate:\n")
summary(did_birth_rate)

# ============================================================================
# Save all results
# ============================================================================

results <- list(
  # DiD
  did_emp = did_emp,
  did_est = did_est,
  did_fte = did_fte,
  # DDD
  ddd_emp = ddd_emp,
  ddd_est = ddd_est,
  ddd_fte = ddd_fte,
  # Event study
  es_emp = es_emp,
  es_est = es_est,
  # Continuous
  cont_emp = cont_emp,
  # UDEMO
  did_births = did_births,
  did_closures = did_closures,
  did_birth_rate = did_birth_rate
)

saveRDS(results, "../data/main_results.rds")

# ============================================================================
# Write diagnostics.json for validator
# ============================================================================

# Count treated units and pre-periods
## In a DDD, treated units are canton-sector cells with non-zero bite classification
## across both cantons (high-bite + low-bite in GE and VD)
n_treated <- df %>%
  filter(bite_group %in% c("high_bite", "low_bite")) %>%
  pull(canton_noga) %>%
  n_distinct()

n_pre <- df %>%
  filter(year < 2021) %>%
  pull(year) %>%
  n_distinct()

diagnostics <- list(
  n_treated = n_treated,  # Canton-sector cells with bite variation in DDD
  n_pre = n_pre,
  n_obs = nrow(df),
  n_sectors = n_distinct(df$noga2),
  n_cantons = n_distinct(df$canton_code),
  n_years = n_distinct(df$year),
  treatment_year = 2021,
  ddd_coef_emp = coef(ddd_emp)["geneva_post_high"],
  ddd_se_emp = se(ddd_emp)["geneva_post_high"],
  ddd_coef_est = coef(ddd_est)["geneva_post_high"],
  ddd_se_est = se(ddd_est)["geneva_post_high"],
  sd_y_emp = sd(df$log_emp[df$year < 2021]),
  sd_y_est = sd(df$log_est[df$year < 2021])
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics saved to data/diagnostics.json\n")

# Print key results summary
cat("\n========================================\n")
cat("KEY RESULTS SUMMARY\n")
cat("========================================\n")
cat("DiD (pooled, Geneva vs Vaud):\n")
cat("  Employment:", round(coef(did_emp), 4), "(SE:", round(se(did_emp), 4), ")\n")
cat("  Establishments:", round(coef(did_est), 4), "(SE:", round(se(did_est), 4), ")\n")
cat("\nDDD (Geneva x HighBite x Post):\n")
cat("  Employment:", round(coef(ddd_emp), 4), "(SE:", round(se(ddd_emp), 4), ")\n")
cat("  Establishments:", round(coef(ddd_est), 4), "(SE:", round(se(ddd_est), 4), ")\n")
cat("  FTE:", round(coef(ddd_fte), 4), "(SE:", round(se(ddd_fte), 4), ")\n")
cat("\nUDEMO:\n")
cat("  Firm births:", round(coef(did_births), 4), "(SE:", round(se(did_births), 4), ")\n")
cat("  Firm closures:", round(coef(did_closures), 4), "(SE:", round(se(did_closures), 4), ")\n")
cat("========================================\n")
