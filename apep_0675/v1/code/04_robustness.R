## 04_robustness.R — Robustness checks
## apep_0675

source("00_packages.R")

## ── Load panels ──
price_panel   <- readRDS("../data/price_panel.rds")
iv_panel      <- readRDS("../data/iv_panel.rds")
epov_income   <- readRDS("../data/epov_income.rds")
results       <- readRDS("../data/main_results.rds")

## ═══════════════════════════════════════════════
## R1. Exclude France (gilets jaunes freeze)
## ═══════════════════════════════════════════════

cat("=== R1: Exclude France ===\n")

iv_no_fr <- feols(
  log_q ~ log_hdd | geo + year | log_p ~ log_tax,
  data = iv_panel %>% filter(geo != "FR"),
  cluster = ~geo
)
cat("IV without France:\n")
summary(iv_no_fr)

## ═══════════════════════════════════════════════
## R2. Exclude Germany & Austria (recent adopters)
## ═══════════════════════════════════════════════

cat("=== R2: Exclude late adopters ===\n")

iv_early <- feols(
  log_q ~ log_hdd | geo + year | log_p ~ log_tax,
  data = iv_panel %>% filter(!geo %in% c("DE", "AT")),
  cluster = ~geo
)
cat("IV early adopters only:\n")
summary(iv_early)

## ═══════════════════════════════════════════════
## R3. Energy poverty by income group
## ═══════════════════════════════════════════════

cat("=== R3: Energy poverty heterogeneity by income ===\n")

epov_low <- feols(
  pct_unable_warm ~ treated:post | geo + year,
  data = epov_income %>%
    filter(low_income == 1) %>%
    mutate(
      treated = if_else(first_treat > 0, 1L, 0L),
      post = if_else(first_treat > 0 & year >= first_treat, 1L, 0L)
    ),
  cluster = ~geo
)

epov_high <- feols(
  pct_unable_warm ~ treated:post | geo + year,
  data = epov_income %>%
    filter(low_income == 0) %>%
    mutate(
      treated = if_else(first_treat > 0, 1L, 0L),
      post = if_else(first_treat > 0 & year >= first_treat, 1L, 0L)
    ),
  cluster = ~geo
)

cat(sprintf("  Low income (<60%% median): coef=%.3f, se=%.3f\n",
            coef(epov_low)[1], se(epov_low)[1]))
cat(sprintf("  High income (≥60%% median): coef=%.3f, se=%.3f\n",
            coef(epov_high)[1], se(epov_high)[1]))

## ═══════════════════════════════════════════════
## R4. Pre-trend test: placebo treatment 2 years early
## ═══════════════════════════════════════════════

cat("=== R4: Placebo pre-trend test ===\n")

iv_placebo <- iv_panel %>%
  mutate(
    placebo_treat = if_else(!is.na(treat_year), treat_year - 2L, NA_integer_),
    placebo_post = if_else(!is.na(placebo_treat) & year >= placebo_treat & year < treat_year, 1L, 0L),
    pre_only = if_else(is.na(treat_year) | year < treat_year, TRUE, FALSE)
  )

placebo_reg <- feols(
  log_q ~ placebo_post + log_hdd | geo + year,
  data = iv_placebo %>% filter(pre_only),
  cluster = ~geo
)
cat("Placebo (2yr early):\n")
summary(placebo_reg)

## ═══════════════════════════════════════════════
## R5. Country-specific pass-through
## ═══════════════════════════════════════════════

cat("=== R5: Country-specific pass-through ===\n")

treated_geos <- c("IE", "FR", "PT", "DE", "AT")
country_pt <- map(treated_geos, function(g) {
  d <- price_panel %>% filter(geo == g | treated == 0)
  feols(price_incl_tax ~ tax_wedge | geo + TIME_PERIOD, data = d, cluster = ~geo)
})
names(country_pt) <- treated_geos

for (g in treated_geos) {
  cat(sprintf("  %s: pass-through = %.3f (%.3f)\n",
              g, coef(country_pt[[g]])[1], se(country_pt[[g]])[1]))
}

## ── Save robustness results ──
rob_results <- list(
  iv_no_fr    = iv_no_fr,
  iv_early    = iv_early,
  epov_low    = epov_low,
  epov_high   = epov_high,
  placebo     = placebo_reg,
  country_pt  = country_pt
)
saveRDS(rob_results, "../data/robustness_results.rds")

cat("=== Robustness checks complete ===\n")
