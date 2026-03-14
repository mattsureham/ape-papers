## 04_robustness.R — Robustness
## apep_0666: EU smoking bans

source("code/00_packages.R")
panel <- readRDS("data/panel.rds")
hosp <- panel %>% filter(sector == "G-I")

cat("=== Robustness ===\n")

## 1. Pre-COVID (end 2019)
r1 <- feols(ln_emp ~ treat_post | country + year,
            data = hosp %>% filter(year <= 2019), cluster = ~country)
cat("R1 (Pre-COVID):\n"); print(summary(r1))

## 2. Exclude early adopters (Ireland, Norway)
r2 <- feols(ln_emp ~ treat_post | country + year,
            data = hosp %>% filter(!country %in% c("IE", "NO")),
            cluster = ~country)
cat("\nR2 (Excl IE/NO):\n"); print(summary(r2))

## 3. Leave-one-country-out
countries <- unique(hosp$country)
loo <- list()
for (c in countries) {
  fit <- feols(ln_emp ~ treat_post | country + year,
               data = hosp %>% filter(country != c), cluster = ~country)
  loo[[c]] <- data.frame(excluded = c, beta = coef(fit)["treat_post"],
                         se = se(fit)["treat_post"])
}
loo_df <- bind_rows(loo)
cat("\nLeave-one-country-out:\n"); print(loo_df)

## 4. Total employment (should show null for ban effect)
total <- panel %>% filter(sector == "TOTAL")
r4 <- feols(ln_emp ~ treat_post | country + year,
            data = total, cluster = ~country)
cat("\nR4 (Total employment - should be null):\n"); print(summary(r4))

## Save
saveRDS(list(pre_covid = r1, no_early = r2, loo = loo_df, total = r4),
        "data/results_robustness.rds")
cat("\nRobustness complete.\n")
