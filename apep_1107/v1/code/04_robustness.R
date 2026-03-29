## 04_robustness.R — Robustness checks and placebo tests
## apep_1107: Romania Overnight Payroll Tax Shift

source("00_packages.R")

core_agg <- readRDS("../data/core_agg.rds")
core_sectors <- readRDS("../data/core_sectors.rds")
full_agg <- readRDS("../data/full_agg.rds")

cat("=== Robustness Checks ===\n")

## ══════════════════════════════════════════════════════════════════════
## 1. PLACEBO TEST: False treatment date (2017-Q1)
## ══════════════════════════════════════════════════════════════════════

cat("\n--- Placebo: 2017-Q1 false treatment ---\n")

placebo_agg <- core_agg |>
  filter(time < as.Date("2018-01-01")) |>
  mutate(
    placebo_post = as.integer(time >= as.Date("2017-01-01")),
    placebo_treat = treated_country * placebo_post
  )

p_wages <- feols(log_wages ~ placebo_treat | country + time,
                 data = placebo_agg, cluster = ~country)
p_nonwage <- feols(log_nonwage ~ placebo_treat | country + time,
                   data = placebo_agg, cluster = ~country)

cat("Placebo wages:\n"); print(summary(p_wages))
cat("Placebo non-wage:\n"); print(summary(p_nonwage))

## ══════════════════════════════════════════════════════════════════════
## 2. PERMUTATION INFERENCE: Treat each control country as Romania
## ══════════════════════════════════════════════════════════════════════

cat("\n--- Permutation inference ---\n")

control_countries <- unique(core_agg$country[core_agg$country != "RO"])

perm_results <- tibble(
  country = character(),
  outcome = character(),
  beta = numeric(),
  se = numeric()
)

for (cc in control_countries) {
  perm_data <- core_agg |>
    mutate(
      perm_treated = as.integer(country == cc),
      perm_treat_post = perm_treated * post
    )

  pw <- tryCatch({
    m <- feols(log_wages ~ perm_treat_post | country + time,
               data = perm_data, cluster = ~country)
    tibble(country = cc, outcome = "wages",
           beta = coef(m)["perm_treat_post"],
           se = se(m)["perm_treat_post"])
  }, error = function(e) NULL)

  pn <- tryCatch({
    m <- feols(log_nonwage ~ perm_treat_post | country + time,
               data = perm_data, cluster = ~country)
    tibble(country = cc, outcome = "nonwage",
           beta = coef(m)["perm_treat_post"],
           se = se(m)["perm_treat_post"])
  }, error = function(e) NULL)

  if (!is.null(pw)) perm_results <- bind_rows(perm_results, pw)
  if (!is.null(pn)) perm_results <- bind_rows(perm_results, pn)
}

## Romania's actual effect
ro_wages_beta <- coef(feols(log_wages ~ treat_post | country + time,
                            data = core_agg, cluster = ~country))["treat_post"]
ro_nonwage_beta <- coef(feols(log_nonwage ~ treat_post | country + time,
                              data = core_agg, cluster = ~country))["treat_post"]

cat(sprintf("\nRomania wage effect: %.4f\n", ro_wages_beta))
cat(sprintf("Romania non-wage effect: %.4f\n", ro_nonwage_beta))

## Permutation p-value
perm_wages <- perm_results |> filter(outcome == "wages")
perm_nonwage <- perm_results |> filter(outcome == "nonwage")

p_val_wages <- mean(abs(perm_wages$beta) >= abs(ro_wages_beta))
p_val_nonwage <- mean(abs(perm_nonwage$beta) >= abs(ro_nonwage_beta))

cat(sprintf("Permutation p-value (wages): %.3f (n_perms=%d)\n",
            p_val_wages, nrow(perm_wages)))
cat(sprintf("Permutation p-value (non-wage): %.3f (n_perms=%d)\n",
            p_val_nonwage, nrow(perm_nonwage)))

## ══════════════════════════════════════════════════════════════════════
## 3. SECTOR HETEROGENEITY: Tradeable vs Non-tradeable
## ══════════════════════════════════════════════════════════════════════

cat("\n--- Sector heterogeneity ---\n")

## Classify sectors
tradeable <- c("B", "C", "D", "E")  # mining, manufacturing, utilities
nontradeable <- c("G", "H", "I", "J", "K", "L", "M", "N", "P", "Q", "R", "S")

het_data <- core_sectors |>
  mutate(
    tradeable = as.integer(sector %in% tradeable),
    sector_type = ifelse(tradeable == 1, "Tradeable", "Non-tradeable")
  ) |>
  filter(sector %in% c(tradeable, nontradeable))

if (nrow(het_data) > 0) {
  ## Interact treatment with sector type
  het_wages <- feols(log_wages ~ treat_post * tradeable |
                       country_sector + time,
                     data = het_data, cluster = ~country)

  het_nonwage <- feols(log_nonwage ~ treat_post * tradeable |
                         country_sector + time,
                       data = het_data, cluster = ~country)

  cat("Sector heterogeneity wages:\n"); print(summary(het_wages))
  cat("Sector heterogeneity non-wage:\n"); print(summary(het_nonwage))
} else {
  cat("  No sector-level data available for heterogeneity test.\n")
  het_wages <- NULL
  het_nonwage <- NULL
}

## ══════════════════════════════════════════════════════════════════════
## 4. LONGER PRE-PERIOD (2012-Q1 to 2019-Q4)
## ══════════════════════════════════════════════════════════════════════

cat("\n--- Extended pre-period ---\n")

## Already have full 2012-2019 data in full_agg
long_wages <- feols(log_wages ~ treat_post | country + time,
                    data = full_agg, cluster = ~country)

long_nonwage <- feols(log_nonwage ~ treat_post | country + time,
                      data = full_agg, cluster = ~country)

cat("Long-panel wages:\n"); print(summary(long_wages))
cat("Long-panel non-wage:\n"); print(summary(long_nonwage))

## ══════════════════════════════════════════════════════════════════════
## Save robustness results
## ══════════════════════════════════════════════════════════════════════

robustness <- list(
  placebo_wages = p_wages,
  placebo_nonwage = p_nonwage,
  perm_results = perm_results,
  perm_pvals = tibble(
    outcome = c("wages", "nonwage"),
    ro_beta = c(ro_wages_beta, ro_nonwage_beta),
    perm_pval = c(p_val_wages, p_val_nonwage)
  ),
  het_wages = het_wages,
  het_nonwage = het_nonwage,
  long_wages = long_wages,
  long_nonwage = long_nonwage
)

saveRDS(robustness, "../data/robustness_results.rds")

cat("\n=== Robustness checks complete ===\n")
