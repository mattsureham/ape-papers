## 03_main_analysis.R — Main econometric analysis
## apep_0616: Police Austerity and Criminal Justice Quality
##
## Design: Continuous-treatment DiD using cross-force variation in officer cuts
## Outcome: Charge/summons rate from the consistent outcomes framework (2014-2021)
## Treatment: % officer cut from 2010 peak (driven by austerity)
## Mechanism: Investigation-intensive vs caught-in-act crime types

suppressPackageStartupMessages({
  library(tidyverse)
  library(fixest)
  library(modelsummary)
  library(sandwich)
  library(lmtest)
})

data_dir <- "data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
offgroup <- readRDS(file.path(data_dir, "offgroup_outcomes.rds"))
officers <- readRDS(file.path(data_dir, "officers_panel.rds"))

# ============================================================================
# A. Data preparation: consistent outcomes framework (2014-2021)
# ============================================================================
cat("=== A. Preparing Analysis Data ===\n")

# Main panel: force × year with officers and charge rate
# Use 2014-2021 for consistent outcomes framework
main <- panel |>
  filter(year >= 2014, year <= 2021) |>
  mutate(
    log_officers = log(officers_fte),
    charge_rate_pct = charge_rate * 100
  )

cat("  Main analysis panel: ", nrow(main), " rows\n")
cat("  Forces: ", n_distinct(main$force_name), "\n")
cat("  Years: ", paste(sort(unique(main$year)), collapse = ", "), "\n")

# Summary statistics
cat("\n  Summary statistics:\n")
main |>
  summarise(
    across(c(officers_fte, total_outcomes, charged, charge_rate_pct, pct_officer_cut),
           list(mean = ~mean(., na.rm = TRUE),
                sd = ~sd(., na.rm = TRUE),
                min = ~min(., na.rm = TRUE),
                max = ~max(., na.rm = TRUE)))
  ) |>
  pivot_longer(everything()) |>
  print(n = 25)

# ============================================================================
# B. National time series: document the aggregate decline
# ============================================================================
cat("\n=== B. National Aggregate Trends ===\n")

national <- main |>
  group_by(year) |>
  summarise(
    total_officers = sum(officers_fte),
    total_charged = sum(charged),
    total_outcomes = sum(total_outcomes),
    charge_rate = total_charged / total_outcomes,
    .groups = "drop"
  )

cat("  National trends:\n")
print(national)

# ============================================================================
# C. Main regression: officer cuts → charge rates
# ============================================================================
cat("\n=== C. Main Regressions ===\n")

# C1: Panel FE regression — within-force variation
# ChargeRate_{ft} = α_f + γ_t + β × log(Officers_{ft}) + ε
m1 <- feols(charge_rate_pct ~ log_officers | force_name + year,
            data = main, cluster = ~force_name)

cat("\nModel 1: Charge rate ~ log(officers), force + year FE\n")
summary(m1)

# C2: Continuous-treatment DiD
# ChargeRate_{ft} = α_f + γ_t + β × (OfficerCut_f × year) + ε
# Using pct_officer_cut interacted with year dummies
main <- main |>
  mutate(
    cut_intensity = -pct_officer_cut / 100,  # positive = larger cut
    year_centered = year - 2014
  )

m2 <- feols(charge_rate_pct ~ cut_intensity:i(year, ref = 2014) | force_name + year,
            data = main, cluster = ~force_name)

cat("\nModel 2: Continuous-treatment DiD (cut intensity × year)\n")
summary(m2)

# C3: Officers per reported crime (efficiency measure)
main <- main |>
  mutate(officers_per_1000crimes = officers_fte / (total_outcomes / 1000))

m3 <- feols(charge_rate_pct ~ log(officers_per_1000crimes) | force_name + year,
            data = main, cluster = ~force_name)

cat("\nModel 3: Charge rate ~ log(officers per 1000 crimes)\n")
summary(m3)

# ============================================================================
# D. Extended panel: use full 2007-2021 with officer levels
# ============================================================================
cat("\n=== D. Extended Panel (2007-2021) ===\n")

# For the extended panel, use charge COUNTS (not rates, since framework changed)
extended <- panel |>
  filter(year >= 2007, year <= 2021) |>
  mutate(
    log_officers = log(officers_fte),
    log_charges = log(charged + 1),  # +1 for zero charges in early years
    post_2010 = as.integer(year >= 2010)
  )

# Charges per officer as an alternative outcome
extended <- extended |>
  mutate(charges_per_officer = charged / officers_fte)

# M4: log(charges) ~ log(officers), force + year FE
# Tests whether officer reductions caused fewer charges
m4 <- feols(log_charges ~ log_officers | force_name + year,
            data = extended |> filter(charged > 0),
            cluster = ~force_name)

cat("\nModel 4: log(charges) ~ log(officers), extended panel\n")
summary(m4)

# M5: Continuous-treatment DiD on extended panel
treatment_df <- panel |>
  filter(year %in% c(2010, 2015)) |>
  select(force_name, year, officers_fte) |>
  pivot_wider(names_from = year, values_from = officers_fte, names_prefix = "fte_") |>
  mutate(cut_intensity = -(fte_2015 - fte_2010) / fte_2010) |>
  select(force_name, cut_intensity_ext = cut_intensity)

extended2 <- extended |>
  filter(charged > 0) |>
  left_join(treatment_df, by = "force_name")

m5 <- feols(log_charges ~ cut_intensity_ext:post_2010 | force_name + year,
            data = extended2, cluster = ~force_name)

cat("\nModel 5: log(charges) ~ cut_intensity × post, extended panel\n")
summary(m5)

# ============================================================================
# E. Offense group heterogeneity
# ============================================================================
cat("\n=== E. Offense Group Heterogeneity ===\n")

# Merge officers with offense-group outcomes
std_force <- function(x) str_trim(str_to_lower(x))

offgroup_panel <- offgroup |>
  mutate(force_std = std_force(force_name), year = fy_start) |>
  inner_join(
    officers |> mutate(force_std = std_force(force_name)),
    by = c("force_std", "year")
  ) |>
  filter(year >= 2014, year <= 2021) |>
  mutate(
    charge_rate_pct = charge_rate * 100,
    log_officers = log(officers_fte)
  ) |>
  filter(!is.na(charge_rate_pct), total_outcomes > 0)

# Classify crime types by investigation intensity
offgroup_panel <- offgroup_panel |>
  mutate(
    crime_category = case_when(
      offence_group %in% c("Drug offences", "Possession of weapons offences") ~ "Caught-in-act",
      offence_group %in% c("Sexual offences", "Violence against the person") ~ "Investigation-intensive",
      offence_group %in% c("Theft offences", "Criminal damage and arson") ~ "Volume crime",
      offence_group == "Robbery" ~ "Investigation-intensive",
      TRUE ~ "Other"
    )
  )

# Regression by offense group
cat("  Regressions by offense group:\n\n")

offense_results <- list()
for (grp in unique(offgroup_panel$offence_group)) {
  sub <- offgroup_panel |> filter(offence_group == grp, total_outcomes > 100)
  if (nrow(sub) < 50) next

  m <- feols(charge_rate_pct ~ log_officers | force_name.x + year,
             data = sub, cluster = ~force_name.x)

  offense_results[[grp]] <- list(
    group = grp,
    coef = coef(m)["log_officers"],
    se = se(m)["log_officers"],
    n = nrow(sub)
  )

  cat(sprintf("  %-40s β=%.3f (%.3f)  N=%d\n",
              grp, coef(m)["log_officers"], se(m)["log_officers"], nrow(sub)))
}

# By category
cat("\n  Regressions by investigation intensity category:\n")
for (cat_name in c("Investigation-intensive", "Volume crime", "Caught-in-act")) {
  sub <- offgroup_panel |>
    filter(crime_category == cat_name, total_outcomes > 100)

  m <- feols(charge_rate_pct ~ log_officers | force_name.x + year + offence_group,
             data = sub, cluster = ~force_name.x)

  cat(sprintf("  %-25s β=%.3f (%.3f)  N=%d\n",
              cat_name, coef(m)["log_officers"], se(m)["log_officers"], nrow(sub)))
}

# ============================================================================
# F. Save results
# ============================================================================
cat("\n=== F. Saving Results ===\n")

saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4),
        file.path(data_dir, "main_models.rds"))
saveRDS(offense_results, file.path(data_dir, "offense_results.rds"))

# Update diagnostics
diag <- jsonlite::fromJSON(file.path(data_dir, "diagnostics.json"))
diag$n_treated <- n_distinct(main$force_name)
diag$n_pre <- sum(unique(panel$year) < 2014)  # pre-outcomes-framework years used for pre-trends
diag$n_obs <- nrow(main)
jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat("Done.\n")
