## 04_robustness.R — Robustness checks
## apep_0665: Fornero pension reform

source("code/00_packages.R")
panel <- readRDS("data/panel.rds")

cat("=== Robustness ===\n")

## 1. Pre-crisis sample (end 2019)
r1 <- feols(ln_gfcf ~ treat_intensity | region + year,
            data = panel %>% filter(year <= 2019), cluster = ~region)
cat("R1 (Pre-COVID):\n"); print(summary(r1))

## 2. Exclude islands (Sicilia, Sardegna)
r2 <- feols(ln_gfcf ~ treat_intensity | region + year,
            data = panel %>% filter(!region %in% c("ITG1", "ITG2")),
            cluster = ~region)
cat("\nR2 (Excl islands):\n"); print(summary(r2))

## 3. Placebo: 2006 treatment
panel_placebo <- panel %>%
  filter(year <= 2011) %>%
  mutate(post_placebo = as.integer(year >= 2006),
         treat_placebo = fornero_bite * post_placebo)

r3 <- feols(ln_gfcf ~ treat_placebo | region + year,
            data = panel_placebo, cluster = ~region)
cat("\nR3 (Placebo 2006):\n"); print(summary(r3))

## 4. Leave-one-region-out
regions <- unique(panel$region)
loo <- list()
for (reg in regions) {
  fit <- feols(ln_gfcf ~ treat_intensity | region + year,
               data = panel %>% filter(region != reg), cluster = ~region)
  loo[[reg]] <- data.frame(excluded = reg,
                           beta = coef(fit)["treat_intensity"],
                           se = se(fit)["treat_intensity"])
}
loo_df <- bind_rows(loo)
cat("\nLeave-one-region-out:\n"); print(loo_df)

## Save
saveRDS(list(pre_covid = r1, no_islands = r2, placebo = r3, loo = loo_df),
        "data/results_robustness.rds")
cat("\nRobustness complete.\n")
