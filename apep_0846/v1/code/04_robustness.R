# 04_robustness.R — Robustness checks and heterogeneity
source("00_packages.R")

load("../data/models.RData")

# ─── 1. CS with not-yet-treated control group ───
cat("=== CS with not-yet-treated controls ===\n")
cs_nyt <- att_gt(
  yname = "black_homeown_rate",
  tname = "year",
  idname = "county_fips",
  gname = "first_treat",
  data = as.data.frame(panel),
  control_group = "notyettreated",
  clustervars = "state_fips",
  base_period = "universal"
)
cs_nyt_agg <- aggte(cs_nyt, type = "simple")
cat("CS (not-yet-treated) ATT:\n")
summary(cs_nyt_agg)

# ─── 2. Bacon decomposition ───
cat("\n=== Bacon Decomposition ===\n")
# Using fixest's Bacon decomposition via sunab
sunab_main <- feols(
  black_homeown_rate ~ sunab(first_treat, year) | county_fips + year,
  data = panel |> filter(first_treat > 0 | first_treat == 0),
  cluster = ~state_fips
)
cat("Sun-Abraham event study:\n")
summary(sunab_main)

# ─── 3. Leave-one-state-out ───
cat("\n=== Leave-one-state-out sensitivity ===\n")
treated_states <- unique(panel$state_fips[panel$treated == 1])

loo_results <- map_dfr(treated_states, function(s) {
  sub <- panel |> filter(state_fips != s)
  fit <- feols(
    black_homeown_rate ~ post | county_fips + year,
    data = sub,
    cluster = ~state_fips
  )
  tibble(
    dropped_state = s,
    beta = coef(fit)["post"],
    se = se(fit)["post"]
  )
})

cat("Leave-one-out range:\n")
cat(sprintf("  Min beta: %.5f (dropped state %d)\n",
            min(loo_results$beta), loo_results$dropped_state[which.min(loo_results$beta)]))
cat(sprintf("  Max beta: %.5f (dropped state %d)\n",
            max(loo_results$beta), loo_results$dropped_state[which.max(loo_results$beta)]))
cat(sprintf("  Full-sample beta: %.5f\n", coef(twfe_main)["post"]))

write_csv(loo_results, "../data/leave_one_out.csv")

# ─── 4. Heterogeneity: Southern vs Non-Southern states ───
cat("\n=== Heterogeneity: South vs Non-South ===\n")
southern_fips <- c(1L, 5L, 12L, 13L, 21L, 22L, 28L, 37L, 40L, 45L, 47L, 48L, 51L, 54L)

panel <- panel |>
  mutate(south = as.integer(state_fips %in% southern_fips))

twfe_south <- feols(
  black_homeown_rate ~ post | county_fips + year,
  data = panel |> filter(south == 1),
  cluster = ~state_fips
)

twfe_nonsouth <- feols(
  black_homeown_rate ~ post | county_fips + year,
  data = panel |> filter(south == 0),
  cluster = ~state_fips
)

cat("Southern states:\n")
summary(twfe_south)
cat("Non-Southern states:\n")
summary(twfe_nonsouth)

# ─── 5. Heterogeneity: Pre/Post 2018 Farm Bill ───
cat("\n=== Heterogeneity: Pre vs Post Farm Bill 2018 ===\n")
# States adopting UPHPA before Farm Bill (2011-2017) vs after (2018-2023)
panel <- panel |>
  mutate(
    early_adopter = as.integer(first_treat > 0 & first_treat <= 2017),
    late_adopter = as.integer(first_treat > 0 & first_treat > 2017)
  )

twfe_early <- feols(
  black_homeown_rate ~ post | county_fips + year,
  data = panel |> filter(early_adopter == 1 | treated == 0),
  cluster = ~state_fips
)

twfe_late <- feols(
  black_homeown_rate ~ post | county_fips + year,
  data = panel |> filter(late_adopter == 1 | treated == 0),
  cluster = ~state_fips
)

cat("Early adopters (2011-2017, pre-Farm Bill):\n")
summary(twfe_early)
cat("Late adopters (2018-2023, post-Farm Bill):\n")
summary(twfe_late)

# ─── 6. Heterogeneity: High vs Low Black population share ───
cat("\n=== Heterogeneity: High vs Low Black HH share ===\n")
panel <- panel |>
  group_by(county_fips) |>
  mutate(
    black_share_base = mean(
      black_totalE / (black_totalE + white_totalE),
      na.rm = TRUE
    )
  ) |>
  ungroup() |>
  mutate(high_black = as.integer(black_share_base >= median(black_share_base, na.rm = TRUE)))

twfe_high_black <- feols(
  black_homeown_rate ~ post | county_fips + year,
  data = panel |> filter(high_black == 1),
  cluster = ~state_fips
)

twfe_low_black <- feols(
  black_homeown_rate ~ post | county_fips + year,
  data = panel |> filter(high_black == 0),
  cluster = ~state_fips
)

cat("High Black HH share:\n")
summary(twfe_high_black)
cat("Low Black HH share:\n")
summary(twfe_low_black)

# ─── Save robustness estimates ───
robust_estimates <- list(
  cs_nyt = list(beta = cs_nyt_agg$overall.att, se = cs_nyt_agg$overall.se),
  twfe_south = list(beta = coef(twfe_south)["post"], se = se(twfe_south)["post"],
                    n = twfe_south$nobs),
  twfe_nonsouth = list(beta = coef(twfe_nonsouth)["post"], se = se(twfe_nonsouth)["post"],
                       n = twfe_nonsouth$nobs),
  twfe_early = list(beta = coef(twfe_early)["post"], se = se(twfe_early)["post"],
                    n = twfe_early$nobs),
  twfe_late = list(beta = coef(twfe_late)["post"], se = se(twfe_late)["post"],
                   n = twfe_late$nobs),
  twfe_high_black = list(beta = coef(twfe_high_black)["post"], se = se(twfe_high_black)["post"],
                         n = twfe_high_black$nobs),
  twfe_low_black = list(beta = coef(twfe_low_black)["post"], se = se(twfe_low_black)["post"],
                        n = twfe_low_black$nobs),
  loo_min = min(loo_results$beta),
  loo_max = max(loo_results$beta)
)
write_json(robust_estimates, "../data/robust_estimates.json", auto_unbox = TRUE, pretty = TRUE)

# Save updated panel and robustness models
save(list = ls(), file = "../data/all_models.RData")
cat("\nAll robustness checks complete.\n")
