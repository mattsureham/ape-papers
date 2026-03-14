## 04_robustness.R — Robustness checks
## apep_0664: Finland Competitiveness Pact

source("code/00_packages.R")

panel <- readRDS("data/panel.rds")

cat("=== Robustness Checks ===\n")

## ---- 1. Drop COVID years (end at 2019) ----
panel_pre_covid <- panel %>% filter(year <= 2019)

r1 <- feols(ln_hours ~ treat_did | country_sector + year,
            data = panel_pre_covid, cluster = ~country)

cat("R1 (Pre-COVID, 2008-2019):\n")
print(summary(r1))

## ---- 2. Placebo treatment year (2013) ----
panel_placebo <- panel %>%
  filter(year <= 2016) %>%
  mutate(
    post_placebo = as.integer(year >= 2013),
    treat_placebo = finland * post_placebo
  )

r2 <- feols(ln_hours ~ treat_placebo | country_sector + year,
            data = panel_placebo, cluster = ~country)

cat("\nR2 (Placebo 2013):\n")
print(summary(r2))

## ---- 3. Exclude Norway (oil economy concern) ----
panel_no_no <- panel %>% filter(country != "NO")

r3 <- feols(ln_hours ~ treat_did | country_sector + year,
            data = panel_no_no, cluster = ~country)

cat("\nR3 (Exclude Norway):\n")
print(summary(r3))

## ---- 4. Leave-one-sector-out ----
sectors <- unique(panel$sector)
loo_results <- list()
for (s in sectors) {
  df_loo <- panel %>% filter(sector != s)
  fit <- feols(ln_hours ~ treat_did | country_sector + year,
               data = df_loo, cluster = ~country)
  loo_results[[s]] <- data.frame(
    excluded_sector = s,
    beta = coef(fit)["treat_did"],
    se = se(fit)["treat_did"]
  )
}
loo_df <- bind_rows(loo_results)
cat("\nLeave-one-sector-out:\n")
print(loo_df)

## ---- 5. Sector-specific effects ----
sector_results <- list()
for (s in sectors) {
  df_s <- panel %>% filter(sector == s)
  if (nrow(df_s) > 10) {
    fit <- feols(ln_hours ~ treat_did | country + year,
                 data = df_s, cluster = ~country)
    sector_results[[s]] <- data.frame(
      sector = s,
      beta = coef(fit)["treat_did"],
      se = se(fit)["treat_did"],
      n = nrow(df_s)
    )
  }
}
sector_df <- bind_rows(sector_results)
cat("\nSector-specific effects:\n")
print(sector_df)

## ---- 6. Triple-DiD pre-COVID ----
r6 <- feols(ln_hours ~ treat_did + triple_did | country_sector + year,
            data = panel_pre_covid, cluster = ~country)

cat("\nR6 (Triple-DiD, pre-COVID):\n")
print(summary(r6))

## ---- Save ----
robustness <- list(
  pre_covid = r1, placebo = r2, no_norway = r3,
  loo = loo_df, by_sector = sector_df, triple_pre_covid = r6
)
saveRDS(robustness, "data/results_robustness.rds")
saveRDS(panel_pre_covid, "data/panel_pre_covid.rds")

cat("\nRobustness checks complete.\n")
