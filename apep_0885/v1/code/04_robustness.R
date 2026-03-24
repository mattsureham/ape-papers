## 04_robustness.R — Robustness checks and mechanism tests
## APEP-0885: Gotthard Base Tunnel and Regional Economic Integration

source("00_packages.R")

DATA_DIR <- "../data"

panel_canton <- readRDS(file.path(DATA_DIR, "panel_canton.rds"))
panel_muni <- readRDS(file.path(DATA_DIR, "panel_muni.rds"))
panel_tourism <- readRDS(file.path(DATA_DIR, "panel_tourism_canton.rds"))

## ============================================================================
## 1. Exclude COVID Years (2020–2021)
## ============================================================================

cat("=== Robustness: Exclude COVID Years ===\n")

panel_nocovid <- panel_canton %>%
  filter(in_sample == 1, !(year %in% c(2020, 2021)))

r1 <- feols(log_construction ~ treat_post | canton + year,
            data = panel_nocovid, cluster = ~canton)

# Full sample excluding COVID
r1_full <- feols(log_construction ~ treat_post | canton + year,
                 data = panel_canton %>% filter(!(year %in% c(2020, 2021))),
                 cluster = ~canton)

cat("Excl. COVID (alpine sample):\n")
etable(r1, se.below = TRUE)
cat("Excl. COVID (full sample):\n")
etable(r1_full, se.below = TRUE)

## ============================================================================
## 2. Short Post-Window (2017–2019 only, clean pre-COVID)
## ============================================================================

cat("\n=== Robustness: Short Post-Window (2017-2019) ===\n")

panel_short <- panel_canton %>%
  filter(in_sample == 1, year <= 2019)

r2 <- feols(log_construction ~ treat_post | canton + year,
            data = panel_short, cluster = ~canton)

r2_full <- feols(log_construction ~ treat_post | canton + year,
                 data = panel_canton %>% filter(year <= 2019),
                 cluster = ~canton)

cat("Short window (alpine):\n")
etable(r2, se.below = TRUE)
cat("Short window (full):\n")
etable(r2_full, se.below = TRUE)

## ============================================================================
## 3. Placebo Treatment Dates
## ============================================================================

cat("\n=== Placebo Tests ===\n")

# Placebo 1: Pretend tunnel opened in 2010
panel_placebo1 <- panel_canton %>%
  filter(in_sample == 1, year <= 2016) %>%
  mutate(
    post_placebo = as.integer(year >= 2010),
    treat_placebo = is_ticino * post_placebo
  )

p1 <- feols(log_construction ~ treat_placebo | canton + year,
            data = panel_placebo1, cluster = ~canton)

# Placebo 2: Pretend tunnel opened in 2013
panel_placebo2 <- panel_canton %>%
  filter(in_sample == 1, year <= 2016) %>%
  mutate(
    post_placebo = as.integer(year >= 2013),
    treat_placebo = is_ticino * post_placebo
  )

p2 <- feols(log_construction ~ treat_placebo | canton + year,
            data = panel_placebo2, cluster = ~canton)

cat("Placebo tests:\n")
etable(p1, p2, headers = c("Placebo 2010", "Placebo 2013"), se.below = TRUE)

## ============================================================================
## 4. Leave-One-Out (Drop each control canton)
## ============================================================================

cat("\n=== Leave-One-Out ===\n")

control_cantons <- c("GR", "VS", "UR")
loo_results <- list()

for (drop in control_cantons) {
  sample_loo <- panel_canton %>%
    filter(in_sample == 1, canton != drop)
  loo_results[[drop]] <- feols(log_construction ~ treat_post | canton + year,
                                data = sample_loo, cluster = ~canton)
}

cat("Leave-one-out results:\n")
for (drop in control_cantons) {
  cat("  Drop", drop, ": coef =", round(coef(loo_results[[drop]]), 4),
      ", SE =", round(sqrt(diag(vcov(loo_results[[drop]]))), 4), "\n")
}

## ============================================================================
## 5. Per-Capita Construction
## ============================================================================

cat("\n=== Per-Capita Construction ===\n")

r_pc <- feols(construction_pc ~ treat_post | canton + year,
              data = panel_canton %>% filter(in_sample == 1),
              cluster = ~canton)

r_pc_full <- feols(construction_pc ~ treat_post | canton + year,
                   data = panel_canton,
                   cluster = ~canton)

cat("Per-capita (alpine):\n")
etable(r_pc, se.below = TRUE)
cat("Per-capita (full):\n")
etable(r_pc_full, se.below = TRUE)

## ============================================================================
## 6. Investment and New Construction Decomposition
## ============================================================================

cat("\n=== Investment Decomposition ===\n")

r_inv <- feols(investment_pc ~ treat_post | canton + year,
               data = panel_canton %>% filter(in_sample == 1),
               cluster = ~canton)

r_new <- feols(new_construction_pc ~ treat_post | canton + year,
               data = panel_canton %>% filter(in_sample == 1),
               cluster = ~canton)

cat("Decomposition:\n")
etable(r_pc, r_inv, r_new,
       headers = c("Total", "Investment", "New Construction"),
       se.below = TRUE)

## ============================================================================
## 7. Full-Sample Event Study (All 26 Cantons)
## ============================================================================

cat("\n=== Full-Sample Event Study ===\n")

panel_canton <- panel_canton %>%
  mutate(rel_year_trim = pmax(pmin(rel_year, 6), -10))

es_full <- feols(log_construction ~ i(rel_year_trim, is_ticino, ref = -1) | canton + year,
                 data = panel_canton,
                 cluster = ~canton)

es_full_coefs <- data.frame(
  rel_year = as.numeric(names(coef(es_full))),
  estimate = coef(es_full),
  se = sqrt(diag(vcov(es_full)))
)

# Parse event study coefficients properly
es_coef_names <- names(coef(es_full))
es_times <- as.numeric(gsub(".*::", "", gsub(":is_ticino", "", es_coef_names)))
es_full_coefs <- data.frame(
  rel_year = es_times,
  estimate = as.numeric(coef(es_full)),
  se = sqrt(diag(vcov(es_full)))
) %>%
  mutate(ci_lo = estimate - 1.96 * se, ci_hi = estimate + 1.96 * se)

es_full_coefs <- bind_rows(
  es_full_coefs,
  data.frame(rel_year = -1, estimate = 0, se = 0, ci_lo = 0, ci_hi = 0)
) %>%
  filter(!is.na(rel_year)) %>%
  arrange(rel_year)

cat("Full-sample event study coefficients:\n")
print(es_full_coefs)

saveRDS(es_full_coefs, file.path(DATA_DIR, "event_study_full_coefs.rds"))

## ============================================================================
## 8. Tourism Event Study
## ============================================================================

cat("\n=== Tourism Event Study ===\n")

sample_tourism <- panel_tourism %>%
  filter(in_sample == 1) %>%
  mutate(rel_year_trim = pmax(pmin(rel_year, 6), -10))

es_tourism <- feols(log_nights_swiss ~ i(rel_year_trim, is_ticino, ref = -1) |
                      canton_abbr + year,
                    data = sample_tourism,
                    cluster = ~canton_abbr)

cat("Tourism event study (Swiss overnights):\n")
print(coeftable(es_tourism))

## ============================================================================
## 9. Save Robustness Results
## ============================================================================

robustness <- list(
  nocovid_alpine = r1,
  nocovid_full = r1_full,
  short_alpine = r2,
  short_full = r2_full,
  placebo_2010 = p1,
  placebo_2013 = p2,
  loo = loo_results,
  pc_alpine = r_pc,
  pc_full = r_pc_full,
  investment = r_inv,
  new_construction = r_new,
  es_full = es_full,
  es_tourism_swiss = es_tourism
)

saveRDS(robustness, file.path(DATA_DIR, "robustness_models.rds"))
saveRDS(es_full_coefs, file.path(DATA_DIR, "event_study_full_coefs.rds"))

## ============================================================================
## 10. Compute key statistics for paper text
## ============================================================================

cat("\n=== Key Statistics for Paper ===\n")

# Pre-treatment SD of log construction
pre_sd <- panel_canton %>%
  filter(in_sample == 1, year < 2017) %>%
  pull(log_construction) %>%
  sd()
cat("SD(log_construction), pre-treatment alpine sample:", round(pre_sd, 4), "\n")

# Pre-treatment SD of construction per capita
pre_sd_pc <- panel_canton %>%
  filter(in_sample == 1, year < 2017) %>%
  pull(construction_pc) %>%
  sd()
cat("SD(construction_pc), pre-treatment alpine sample:", round(pre_sd_pc, 2), "\n")

# Pre-treatment mean
pre_mean_pc <- panel_canton %>%
  filter(in_sample == 1, year < 2017, is_ticino == 1) %>%
  pull(construction_pc) %>%
  mean()
cat("Mean(construction_pc), Ticino pre-treatment:", round(pre_mean_pc, 2), "\n")

# Full-sample DiD magnitude
full_coef <- coef(r1_full)["treat_post"]
cat("Full-sample excl-COVID DiD coefficient:", round(full_coef, 4), "\n")
cat("  Implied % change:", round((exp(full_coef) - 1) * 100, 2), "%\n")

# MDE calculation (at 80% power, significance 0.05)
# MDE = 2.8 * SE  (approx for t-test)
se_full <- sqrt(diag(vcov(r1_full)))["treat_post"]
mde <- 2.8 * se_full
cat("MDE (full sample, excl COVID):", round(mde, 4),
    "(", round((exp(mde) - 1) * 100, 2), "% change)\n")

# SDE for key outcomes
sde_construction <- coef(r1_full)["treat_post"] / pre_sd
cat("SDE (construction, full excl-COVID):", round(sde_construction, 4), "\n")

# Save summary stats
stats <- list(
  pre_sd_log = pre_sd,
  pre_sd_pc = pre_sd_pc,
  pre_mean_ticino_pc = pre_mean_pc,
  full_did_coef = as.numeric(full_coef),
  full_did_se = as.numeric(se_full),
  mde = as.numeric(mde),
  sde_construction = as.numeric(sde_construction)
)
saveRDS(stats, file.path(DATA_DIR, "summary_stats.rds"))

cat("\n=== Robustness Analysis Complete ===\n")
