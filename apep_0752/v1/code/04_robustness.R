## 04_robustness.R — Robustness checks for apep_0752
source("00_packages.R")
data_dir <- "../data"

state_panel <- readRDS(file.path(data_dir, "state_panel_analysis.rds"))
county_panel <- readRDS(file.path(data_dir, "county_panel_analysis.rds"))

median_aian <- median(state_panel$state_aian_share[state_panel$gaming_state], na.rm = TRUE)
state_panel <- state_panel |>
  mutate(
    high_aian = state_aian_share > median_aian,
    gaming_x_highaian = gaming_state & high_aian,
    period = case_when(
      year <= 2006 ~ "pre_opioid",
      year <= 2013 ~ "rx_wave",
      year <= 2019 ~ "synth_wave",
      TRUE ~ "post_covid"
    ),
    period_f = factor(period, levels = c("pre_opioid", "rx_wave", "synth_wave", "post_covid"))
  )

cat("=== Robustness Checks ===\n")

# ============================================================
# R1: Log specification
# ============================================================
cat("\n--- R1: Log specification ---\n")
r1 <- feols(log(od_rate + 0.1) ~ gaming_state * high_aian * period_f | year,
            data = state_panel |> filter(period != "post_covid"),
            cluster = ~state)
cat("Gaming × HighAIAN × SynthWave (log):",
    round(coef(r1)["gaming_stateTRUE:high_aianTRUE:period_fsynth_wave"], 4), "\n")

# ============================================================
# R2: Excluding COVID-adjacent years
# ============================================================
cat("\n--- R2: Excluding 2019-2021 ---\n")
r2 <- feols(od_rate ~ gaming_state * high_aian * period_f | year,
            data = state_panel |> filter(year <= 2018),
            cluster = ~state)
cat("Gaming × HighAIAN × SynthWave (excl COVID):",
    round(coef(r2)["gaming_stateTRUE:high_aianTRUE:period_fsynth_wave"], 4), "\n")

# ============================================================
# R3: Continuous AI/AN share instead of binary
# ============================================================
cat("\n--- R3: Continuous AI/AN share ---\n")
r3 <- feols(od_rate ~ gaming_state * state_aian_share * period_f | year,
            data = state_panel |> filter(period != "post_covid"),
            cluster = ~state)
# Show the triple interaction
r3_coefs <- coef(r3)
synth_triple <- r3_coefs[grepl("gaming.*aian.*synth", names(r3_coefs))]
cat("Gaming × AIANshare × SynthWave:", round(synth_triple, 2), "\n")

# ============================================================
# R4: Placebo outcome — check that gaming doesn't affect
# heart disease or cancer mortality (should be null)
# ============================================================
cat("\n--- R4: Placebo test (no access to non-OD mortality via API) ---\n")
cat("Note: CDC NCHS state-level data only provides drug overdose rates.\n")
cat("Placebo test requires manual CDC WONDER query for heart disease/cancer.\n")
cat("Skipping placebo outcome test — documented as limitation.\n")

# ============================================================
# R5: Drop states with very small AI/AN populations
# ============================================================
cat("\n--- R5: Drop states with AI/AN share < 0.5% ---\n")
r5 <- feols(od_rate ~ gaming_state * high_aian * period_f | year,
            data = state_panel |> filter(period != "post_covid", state_aian_share >= 0.005),
            cluster = ~state)
cat("N states:", n_distinct(state_panel$state[state_panel$state_aian_share >= 0.005]), "\n")
cat("Gaming × HighAIAN × SynthWave:",
    round(coef(r5)["gaming_stateTRUE:high_aianTRUE:period_fsynth_wave"], 4), "\n")

# ============================================================
# R6: County-level — restrict to high AI/AN counties
# ============================================================
cat("\n--- R6: County-level, AI/AN share > 5% ---\n")
high_aian_counties <- county_panel |> filter(aian_share_2010 > 0.05)
cat("Counties:", n_distinct(high_aian_counties$fips), "\n")
if (n_distinct(high_aian_counties$fips) >= 10) {
  r6 <- feols(od_rate_per_100k ~ has_casino | year,
              data = high_aian_counties,
              cluster = ~fips)
  cat("Casino effect in high-AI/AN counties:",
      round(coef(r6)["has_casinoTRUE"], 2), "\n")
  print(summary(r6))
}

# Save robustness models
saveRDS(list(r1 = r1, r2 = r2, r3 = r3, r5 = r5),
        file.path(data_dir, "robustness_models.rds"))

cat("\nRobustness checks complete.\n")
