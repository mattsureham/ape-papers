# 03_main_analysis.R — Primary specifications
source("00_packages.R")

panel <- read_csv("../data/panel.csv", show_col_types = FALSE)

# ─── 1. Summary statistics ───
sumstats <- panel |>
  summarize(
    across(
      c(black_homeown_rate, white_homeown_rate, homeown_gap,
        black_totalE, white_totalE, total_popE, med_hvalueE),
      list(mean = ~mean(., na.rm = TRUE),
           sd = ~sd(., na.rm = TRUE),
           min = ~min(., na.rm = TRUE),
           max = ~max(., na.rm = TRUE)),
      .names = "{.col}__{.fn}"
    )
  )

write_csv(sumstats, "../data/sumstats.csv")
cat("Summary statistics saved.\n")

# Pre-treatment SD of Black homeownership rate (for SDE computation)
pre_treat_data <- panel |>
  filter(first_treat == 0 | year < first_treat)
sd_y_black <- sd(pre_treat_data$black_homeown_rate, na.rm = TRUE)
cat(sprintf("Pre-treatment SD(Black homeownership rate) = %.4f\n", sd_y_black))

# ─── 2. TWFE baseline ───
twfe_main <- feols(
  black_homeown_rate ~ post | county_fips + year,
  data = panel,
  cluster = ~state_fips
)
cat("\n=== TWFE: Black homeownership ===\n")
summary(twfe_main)

# TWFE placebo: White homeownership
twfe_placebo <- feols(
  white_homeown_rate ~ post | county_fips + year,
  data = panel,
  cluster = ~state_fips
)
cat("\n=== TWFE Placebo: White homeownership ===\n")
summary(twfe_placebo)

# TWFE: homeownership gap
twfe_gap <- feols(
  homeown_gap ~ post | county_fips + year,
  data = panel,
  cluster = ~state_fips
)
cat("\n=== TWFE: Homeownership gap ===\n")
summary(twfe_gap)

# ─── 3. Callaway-Sant'Anna (heterogeneity-robust) ───
cat("\n=== Callaway-Sant'Anna ATT(g,t) ===\n")

cs_out <- att_gt(
  yname = "black_homeown_rate",
  tname = "year",
  idname = "county_fips",
  gname = "first_treat",
  data = as.data.frame(panel),
  control_group = "nevertreated",
  clustervars = "state_fips",
  base_period = "universal"
)

# Overall ATT
cs_agg <- aggte(cs_out, type = "simple")
cat("\nCS Overall ATT:\n")
summary(cs_agg)

# Dynamic event study
cs_es <- aggte(cs_out, type = "dynamic", min_e = -6, max_e = 8)
cat("\nCS Event Study:\n")
summary(cs_es)

# Save event study coefficients for tables
es_df <- data.frame(
  event_time = cs_es$egt,
  att = cs_es$att.egt,
  se = cs_es$se.egt
)
write_csv(es_df, "../data/event_study.csv")

# ─── 4. Triple-difference: Black vs White ───
# Stack Black and White outcomes
triple_panel <- bind_rows(
  panel |> mutate(homeown_rate = black_homeown_rate, black = 1L),
  panel |> mutate(homeown_rate = white_homeown_rate, black = 0L)
) |>
  mutate(
    county_race = paste0(county_fips, "_", black),
    post_black = post * black
  )

# Triple-diff with county-race and race-year FE
triple_diff <- feols(
  homeown_rate ~ post_black + post | county_race + year^black,
  data = triple_panel,
  cluster = ~state_fips
)
cat("\n=== Triple-Difference (Black vs White) ===\n")
summary(triple_diff)

# ─── 5. CS for placebo: White homeownership ───
cs_placebo <- att_gt(
  yname = "white_homeown_rate",
  tname = "year",
  idname = "county_fips",
  gname = "first_treat",
  data = as.data.frame(panel),
  control_group = "nevertreated",
  clustervars = "state_fips",
  base_period = "universal"
)
cs_placebo_agg <- aggte(cs_placebo, type = "simple")
cat("\nCS Placebo (White homeownership) ATT:\n")
summary(cs_placebo_agg)

# ─── 6. Save key estimates for tables ───
estimates <- list(
  twfe_main = list(
    beta = coef(twfe_main)["post"],
    se = se(twfe_main)["post"],
    n = twfe_main$nobs,
    n_clusters = twfe_main$nparams
  ),
  twfe_placebo = list(
    beta = coef(twfe_placebo)["post"],
    se = se(twfe_placebo)["post"]
  ),
  twfe_gap = list(
    beta = coef(twfe_gap)["post"],
    se = se(twfe_gap)["post"]
  ),
  cs_att = list(
    beta = cs_agg$overall.att,
    se = cs_agg$overall.se
  ),
  cs_placebo = list(
    beta = cs_placebo_agg$overall.att,
    se = cs_placebo_agg$overall.se
  ),
  triple_diff = list(
    beta = coef(triple_diff)["post_black"],
    se = se(triple_diff)["post_black"]
  ),
  sd_y_black = sd_y_black,
  sd_y_white = sd(pre_treat_data$white_homeown_rate, na.rm = TRUE),
  sd_y_gap = sd(pre_treat_data$homeown_gap, na.rm = TRUE)
)

write_json(estimates, "../data/estimates.json", auto_unbox = TRUE, pretty = TRUE)

# ─── 7. Diagnostics for validate_v1.py ───
diagnostics <- list(
  n_treated = n_distinct(panel$state_fips[panel$treated == 1]),
  n_pre = length(unique(panel$year[panel$year < 2011])),  # pre-periods before first treatment
  n_obs = nrow(panel)
)
write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diagnostics$n_treated, diagnostics$n_pre, diagnostics$n_obs))

# Save model objects for robustness
save(twfe_main, twfe_placebo, twfe_gap, cs_out, cs_agg, cs_es,
     cs_placebo, cs_placebo_agg, triple_diff, triple_panel,
     sd_y_black, estimates, panel,
     file = "../data/models.RData")
cat("All models saved.\n")
