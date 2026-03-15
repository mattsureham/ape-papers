## 04_robustness.R — Robustness checks
## apep_0694: HomeBuilder Net Additionality

source("00_packages.R")

nat <- readRDS("../data/national_ts.rds")
state <- readRDS("../data/state_panel.rds")
results <- readRDS("../data/main_results.rds")

# ------------------------------------------------------------------
# 1. Alternative windows
# ------------------------------------------------------------------
cat("\n=== Robustness: Alternative ITS windows ===\n")

# Narrower window: 2019-2022
its_narrow <- nat %>%
  filter(date >= "2019-01-01" & date <= "2022-12-01") %>%
  mutate(
    trend = as.numeric(difftime(date, as.Date("2020-06-01"), units = "days")) / 30.44,
    trend_post = pmax(0, as.numeric(difftime(date, as.Date("2021-04-01"), units = "days")) / 30.44),
    month_factor = factor(month)
  )

its_narrow_fit <- lm(log_houses ~ trend + homebuilder_any + post_program + trend_post + month_factor,
                     data = its_narrow)
cat("Narrow window (2019-2022):\n")
print(coef(summary(its_narrow_fit))[c("homebuilder_any", "post_program", "trend_post"), ])

# Wider window: 2017-2024
its_wide <- nat %>%
  filter(date >= "2017-01-01" & date <= "2024-12-01") %>%
  mutate(
    trend = as.numeric(difftime(date, as.Date("2020-06-01"), units = "days")) / 30.44,
    trend_post = pmax(0, as.numeric(difftime(date, as.Date("2021-04-01"), units = "days")) / 30.44),
    month_factor = factor(month)
  )

its_wide_fit <- lm(log_houses ~ trend + homebuilder_any + post_program + trend_post + month_factor,
                   data = its_wide)
cat("\nWide window (2017-2024):\n")
print(coef(summary(its_wide_fit))[c("homebuilder_any", "post_program", "trend_post"), ])

# ------------------------------------------------------------------
# 2. Seasonally adjusted (using month FE is equivalent)
# ------------------------------------------------------------------
cat("\n=== Robustness: Without seasonal adjustment ===\n")
its_no_season <- lm(log_houses ~ trend + homebuilder_any + post_program + trend_post,
                    data = its_narrow)
cat("No seasonal FE:\n")
print(coef(summary(its_no_season))[c("homebuilder_any", "post_program", "trend_post"), ])

# ------------------------------------------------------------------
# 3. Level instead of log
# ------------------------------------------------------------------
cat("\n=== Robustness: Level specification ===\n")
its_level <- lm(houses ~ trend + homebuilder_any + post_program + trend_post + month_factor,
                data = its_narrow)
cat("Level specification:\n")
print(coef(summary(its_level))[c("homebuilder_any", "post_program", "trend_post"), ])

# ------------------------------------------------------------------
# 4. Leave-one-state-out for DDD
# ------------------------------------------------------------------
cat("\n=== Robustness: Leave-One-State-Out DDD ===\n")

state_long <- state %>%
  pivot_longer(cols = c(houses, other_residential),
               names_to = "type", values_to = "approvals") %>%
  mutate(
    is_house = ifelse(type == "houses", 1L, 0L),
    log_approvals = log(approvals + 1),
    hb_x_house = homebuilder_any * is_house,
    unit_id = paste0(state, "_", type),
    unit_num = as.integer(factor(unit_id))
  )

loo_results <- tibble(dropped = character(), coef = numeric(), se = numeric())

for (s in unique(state$state)) {
  sub <- state_long %>% filter(state != s) %>%
    mutate(unit_num = as.integer(factor(unit_id)))

  fit <- tryCatch({
    feols(log_approvals ~ hb_x_house | unit_num + date,
          data = sub, cluster = ~state)
  }, error = function(e) NULL)

  if (!is.null(fit)) {
    loo_results <- bind_rows(loo_results, tibble(
      dropped = s,
      coef = coef(fit)["hb_x_house"],
      se = se(fit)["hb_x_house"]
    ))
    cat(sprintf("  Drop %s: DDD=%.4f (SE=%.4f)\n", s, coef(fit)["hb_x_house"], se(fit)["hb_x_house"]))
  }
}

# ------------------------------------------------------------------
# 5. Additionality with DDD-adjusted counterfactual
# ------------------------------------------------------------------
cat("\n=== DDD-Adjusted Additionality ===\n")

# The DDD coefficient of 0.468 on log scale = exp(0.468)-1 = 59.7% surge
# relative to apartment counterfactual
ddd_coef <- coef(results$ddd)["hb_x_house"]
pct_surge <- exp(ddd_coef) - 1
cat(sprintf("DDD-implied surge: %.1f%%\n", pct_surge * 100))

# Pre-program mean houses
pre_houses <- mean(nat$houses[nat$date >= "2019-01-01" & nat$date <= "2020-05-01"], na.rm = TRUE)
hb_months <- 10  # June 2020 - March 2021
ddd_surge <- pre_houses * pct_surge * hb_months
cat(sprintf("DDD-implied additional approvals: %.0f\n", ddd_surge))
cat(sprintf("Fiscal cost per DDD-additional dwelling: $%.0f\n", 2.4e9 / ddd_surge))

# ------------------------------------------------------------------
# 6. Save robustness results
# ------------------------------------------------------------------
robust <- list(
  its_narrow = its_narrow_fit,
  its_wide = its_wide_fit,
  its_no_season = its_no_season,
  its_level = its_level,
  loo = loo_results,
  ddd_surge = ddd_surge
)
saveRDS(robust, "../data/robustness_results.rds")

cat("\nRobustness checks complete.\n")
