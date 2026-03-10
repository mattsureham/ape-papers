## =============================================================================
## 04_robustness.R — Robustness checks
## apep_0571: Voting reform and public safety in Chile
## =============================================================================

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))

cat("=== ROBUSTNESS CHECKS ===\n")

## ===========================================================================
## 1. ALTERNATIVE TREATMENT DEFINITIONS
## ===========================================================================
cat("\n--- Alternative treatment definitions ---\n")

# (a) Standardized turnout decline
r1a <- feols(ln_discretionary ~ turnout_decline_std:post | comuna_clean + year,
             data = panel, cluster = ~comuna_clean)

# (b) Tercile indicators instead of continuous
r1b <- feols(ln_discretionary ~ i(decline_tercile, post, ref = 1) | comuna_clean + year,
             data = panel, cluster = ~comuna_clean)

# (c) Using 2008 turnout level as treatment intensity
# Higher 2008 turnout = more affected (more compelled voters who exited)
r1c <- feols(ln_discretionary ~ turnout_2008:post | comuna_clean + year,
             data = panel, cluster = ~comuna_clean)

cat("(a) Standardized decline:\n")
summary(r1a)
cat("\n(b) Tercile indicators:\n")
summary(r1b)
cat("\n(c) 2008 turnout level:\n")
summary(r1c)

## ===========================================================================
## 2. ALTERNATIVE OUTCOMES
## ===========================================================================
cat("\n--- Alternative outcome measures ---\n")

# Level specification (not logs)
r2a <- feols(total_rate ~ turnout_decline_pct:post | comuna_clean + year,
             data = panel, cluster = ~comuna_clean)
r2b <- feols(discretionary_rate ~ turnout_decline_pct:post | comuna_clean + year,
             data = panel, cluster = ~comuna_clean)
r2c <- feols(homicide_rate ~ turnout_decline_pct:post | comuna_clean + year,
             data = panel, cluster = ~comuna_clean)

cat("(a) Total crime rate (level):\n")
etable(r2a, r2b, r2c,
       headers = c("Total rate", "Discr. rate", "Homicide rate"))

## ===========================================================================
## 3. RANDOMIZATION INFERENCE
## ===========================================================================
cat("\n--- Randomization Inference ---\n")
set.seed(42)

n_perms <- 1000
actual_beta <- coef(feols(ln_homicide ~ turnout_decline_pct:post |
                            comuna_clean + year, data = panel,
                          cluster = ~comuna_clean))["turnout_decline_pct:post"]

# Permute treatment across comunas
comuna_treat <- panel %>%
  distinct(comuna_clean, turnout_decline_pct)

perm_betas <- numeric(n_perms)
for (i in 1:n_perms) {
  shuffled <- comuna_treat %>%
    mutate(turnout_decline_pct_perm = sample(turnout_decline_pct))

  panel_perm <- panel %>%
    select(-turnout_decline_pct) %>%
    left_join(shuffled %>% select(comuna_clean, turnout_decline_pct = turnout_decline_pct_perm),
              by = "comuna_clean")

  perm_betas[i] <- tryCatch(
    coef(feols(ln_homicide ~ turnout_decline_pct:post | comuna_clean + year,
               data = panel_perm))["turnout_decline_pct:post"],
    error = function(e) NA
  )
}

ri_pval <- mean(abs(perm_betas) >= abs(actual_beta), na.rm = TRUE)
cat("  Homicide RI p-value:", round(ri_pval, 4), "(", n_perms, "permutations)\n")
cat("  Actual beta:", round(actual_beta, 6), "\n")
cat("  Perm distribution: mean=", round(mean(perm_betas, na.rm=TRUE), 6),
    " sd=", round(sd(perm_betas, na.rm=TRUE), 6), "\n")

# RI for drugs
actual_beta_drugs <- coef(feols(ln_drugs ~ turnout_decline_pct:post |
                                  comuna_clean + year, data = panel,
                                cluster = ~comuna_clean))["turnout_decline_pct:post"]

perm_betas_drugs <- numeric(n_perms)
for (i in 1:n_perms) {
  shuffled <- comuna_treat %>%
    mutate(turnout_decline_pct_perm = sample(turnout_decline_pct))

  panel_perm <- panel %>%
    select(-turnout_decline_pct) %>%
    left_join(shuffled %>% select(comuna_clean, turnout_decline_pct = turnout_decline_pct_perm),
              by = "comuna_clean")

  perm_betas_drugs[i] <- tryCatch(
    coef(feols(ln_drugs ~ turnout_decline_pct:post | comuna_clean + year,
               data = panel_perm))["turnout_decline_pct:post"],
    error = function(e) NA
  )
}

ri_pval_drugs <- mean(abs(perm_betas_drugs) >= abs(actual_beta_drugs), na.rm = TRUE)
cat("  Drugs RI p-value:", round(ri_pval_drugs, 4), "\n")

## ===========================================================================
## 4. LEAVE-ONE-OUT REGION STABILITY
## ===========================================================================
cat("\n--- Leave-one-out region stability ---\n")

# Identify regions from comuna names (first word pattern)
# Use turnout data for region info
panel_regions <- panel %>%
  mutate(region_proxy = substr(comuna_clean, 1, 3))

# Actually, use the tipologia as a grouping
tipologias <- sort(unique(panel$tipologia))
cat("  Tipologias:", paste(tipologias, collapse=", "), "\n")

loo_results <- list()
for (tip in tipologias) {
  sub <- panel %>% filter(tipologia != tip)
  m <- feols(ln_homicide ~ turnout_decline_pct:post | comuna_clean + year,
             data = sub, cluster = ~comuna_clean)
  loo_results[[as.character(tip)]] <- data.frame(
    excluded = tip,
    beta = coef(m)["turnout_decline_pct:post"],
    se = se(m)["turnout_decline_pct:post"],
    n = nrow(sub)
  )
}
loo_df <- bind_rows(loo_results)
cat("  Leave-one-tipologia-out (homicide):\n")
print(loo_df %>% mutate(across(where(is.numeric), ~round(., 4))))

## ===========================================================================
## 5. EXCLUDING COVID YEARS
## ===========================================================================
cat("\n--- Excluding COVID years ---\n")

panel_nocovid <- panel %>% filter(!year %in% c(2020, 2021))
r5a <- feols(ln_homicide ~ turnout_decline_pct:post | comuna_clean + year,
             data = panel_nocovid, cluster = ~comuna_clean)
r5b <- feols(ln_drugs ~ turnout_decline_pct:post | comuna_clean + year,
             data = panel_nocovid, cluster = ~comuna_clean)
r5c <- feols(ln_burglary ~ turnout_decline_pct:post | comuna_clean + year,
             data = panel_nocovid, cluster = ~comuna_clean)

cat("Excluding 2020-2021:\n")
etable(r5a, r5b, r5c, headers = c("Homicide", "Drugs", "Burglary"))

## ===========================================================================
## 6. HONESTDID SENSITIVITY (if available)
## ===========================================================================
cat("\n--- HonestDiD sensitivity ---\n")
tryCatch({
  if (requireNamespace("HonestDiD", quietly = TRUE)) {
    library(HonestDiD)
    cat("  HonestDiD available but not applicable to continuous-treatment design\n")
    cat("  (designed for binary treatment staggered DiD)\n")
  } else {
    cat("  HonestDiD not installed — skipping\n")
  }
}, error = function(e) cat("  HonestDiD check failed:", e$message, "\n"))

## ===========================================================================
## SAVE
## ===========================================================================
ri_data <- data.frame(
  outcome = rep(c("Homicide", "Drugs"), each = n_perms),
  perm_beta = c(perm_betas, perm_betas_drugs)
)
fwrite(ri_data, file.path(data_dir, "ri_permutations.csv"))
fwrite(loo_df, file.path(data_dir, "loo_results.csv"))

# Save key robustness results
get_pval <- function(m, coef_name) {
  ct <- coeftable(m)
  ct[coef_name, "Pr(>|t|)"]
}
robust_summary <- data.frame(
  check = c("RI_homicide", "RI_drugs", "COVID_excl_homicide",
            "COVID_excl_drugs", "COVID_excl_burglary"),
  beta = c(actual_beta, actual_beta_drugs,
           coef(r5a)["turnout_decline_pct:post"],
           coef(r5b)["turnout_decline_pct:post"],
           coef(r5c)["turnout_decline_pct:post"]),
  pval = c(ri_pval, ri_pval_drugs,
           get_pval(r5a, "turnout_decline_pct:post"),
           get_pval(r5b, "turnout_decline_pct:post"),
           get_pval(r5c, "turnout_decline_pct:post"))
)
fwrite(robust_summary, file.path(data_dir, "robustness_summary.csv"))

## ===========================================================================
## 7. IHS TRANSFORMATION (addressing log(count+1) concern for sparse outcomes)
## ===========================================================================
cat("\n--- Inverse Hyperbolic Sine transformation ---\n")

panel <- panel %>%
  mutate(
    ihs_homicide = log(homicide + sqrt(homicide^2 + 1)),
    ihs_drugs = log(drugs + sqrt(drugs^2 + 1)),
    ihs_discretionary = log(discretionary_crime + sqrt(discretionary_crime^2 + 1)),
    ihs_total = log(total_crime + sqrt(total_crime^2 + 1)),
    ihs_burglary = log(burglary + sqrt(burglary^2 + 1)),
    ihs_dv = log(domestic_violence + sqrt(domestic_violence^2 + 1))
  )

r7_hom <- feols(ihs_homicide ~ turnout_decline_pct:post | comuna_clean + year,
                data = panel, cluster = ~comuna_clean)
r7_drugs <- feols(ihs_drugs ~ turnout_decline_pct:post | comuna_clean + year,
                  data = panel, cluster = ~comuna_clean)
r7_disc <- feols(ihs_discretionary ~ turnout_decline_pct:post | comuna_clean + year,
                 data = panel, cluster = ~comuna_clean)
r7_burg <- feols(ihs_burglary ~ turnout_decline_pct:post | comuna_clean + year,
                 data = panel, cluster = ~comuna_clean)

cat("IHS transformation results:\n")
etable(r7_hom, r7_drugs, r7_disc, r7_burg,
       headers = c("Homicide", "Drugs", "Discretionary", "Burglary"))

## ===========================================================================
## 8. TIPOLOGIA × YEAR FE (proxy for region-by-year)
## ===========================================================================
cat("\n--- Tipologia × Year fixed effects ---\n")

# tipologia captures urban/rural/mixed classification — acts as region-type proxy
panel <- panel %>%
  mutate(tipologia_year = paste0(tipologia, "_", year))

r8_hom <- feols(ln_homicide ~ turnout_decline_pct:post | comuna_clean + tipologia_year,
                data = panel, cluster = ~comuna_clean)
r8_drugs <- feols(ln_drugs ~ turnout_decline_pct:post | comuna_clean + tipologia_year,
                  data = panel, cluster = ~comuna_clean)
r8_disc <- feols(ln_discretionary ~ turnout_decline_pct:post | comuna_clean + tipologia_year,
                 data = panel, cluster = ~comuna_clean)
r8_burg <- feols(ln_burglary ~ turnout_decline_pct:post | comuna_clean + tipologia_year,
                 data = panel, cluster = ~comuna_clean)

cat("Tipologia × Year FE results:\n")
etable(r8_hom, r8_drugs, r8_disc, r8_burg,
       headers = c("Homicide", "Drugs", "Discretionary", "Burglary"))

## ===========================================================================
## 9. COVARIATE × POST INTERACTIONS
## ===========================================================================
cat("\n--- Covariate × Post interactions ---\n")

# Construct baseline characteristics: use 2008 turnout and padron as proxies
# for urbanicity and size
panel <- panel %>%
  mutate(
    ln_padron = log(padron_2012),
    padron_post = ln_padron * post,
    turnout08_post = turnout_2008 * post
  )

r9_hom <- feols(ln_homicide ~ turnout_decline_pct:post + padron_post + turnout08_post |
                  comuna_clean + year,
                data = panel, cluster = ~comuna_clean)
r9_drugs <- feols(ln_drugs ~ turnout_decline_pct:post + padron_post + turnout08_post |
                    comuna_clean + year,
                  data = panel, cluster = ~comuna_clean)
r9_disc <- feols(ln_discretionary ~ turnout_decline_pct:post + padron_post + turnout08_post |
                   comuna_clean + year,
                 data = panel, cluster = ~comuna_clean)
r9_burg <- feols(ln_burglary ~ turnout_decline_pct:post + padron_post + turnout08_post |
                   comuna_clean + year,
                 data = panel, cluster = ~comuna_clean)

cat("Covariate × Post interaction results:\n")
etable(r9_hom, r9_drugs, r9_disc, r9_burg,
       headers = c("Homicide", "Drugs", "Discretionary", "Burglary"))

## ===========================================================================
## 10. CRIME RATES PER 100K (population-scaled)
## ===========================================================================
cat("\n--- Crime rates per 100K registered voters ---\n")

panel <- panel %>%
  mutate(
    pop100k = padron_2012 / 100000,
    homicide_rate100k = homicide / pop100k,
    drugs_rate100k = drugs / pop100k,
    disc_rate100k = discretionary_crime / pop100k,
    burglary_rate100k = burglary / pop100k,
    total_rate100k = total_crime / pop100k,
    dv_rate100k = domestic_violence / pop100k
  )

r10_hom <- feols(homicide_rate100k ~ turnout_decline_pct:post | comuna_clean + year,
                 data = panel, cluster = ~comuna_clean)
r10_drugs <- feols(drugs_rate100k ~ turnout_decline_pct:post | comuna_clean + year,
                   data = panel, cluster = ~comuna_clean)
r10_disc <- feols(disc_rate100k ~ turnout_decline_pct:post | comuna_clean + year,
                  data = panel, cluster = ~comuna_clean)
r10_burg <- feols(burglary_rate100k ~ turnout_decline_pct:post | comuna_clean + year,
                  data = panel, cluster = ~comuna_clean)

cat("Crime rates per 100K results:\n")
etable(r10_hom, r10_drugs, r10_disc, r10_burg,
       headers = c("Homicide", "Drugs", "Discretionary", "Burglary"))

## ===========================================================================
## SAVE ADDITIONAL ROBUSTNESS RESULTS
## ===========================================================================
ihs_results <- data.frame(
  outcome = c("Homicide", "Drugs", "Discretionary", "Burglary"),
  beta_ihs = c(coef(r7_hom)["turnout_decline_pct:post"],
               coef(r7_drugs)["turnout_decline_pct:post"],
               coef(r7_disc)["turnout_decline_pct:post"],
               coef(r7_burg)["turnout_decline_pct:post"]),
  se_ihs = c(se(r7_hom)["turnout_decline_pct:post"],
             se(r7_drugs)["turnout_decline_pct:post"],
             se(r7_disc)["turnout_decline_pct:post"],
             se(r7_burg)["turnout_decline_pct:post"])
)
fwrite(ihs_results, file.path(data_dir, "ihs_results.csv"))

tipyear_results <- data.frame(
  outcome = c("Homicide", "Drugs", "Discretionary", "Burglary"),
  beta_tipyear = c(coef(r8_hom)["turnout_decline_pct:post"],
                   coef(r8_drugs)["turnout_decline_pct:post"],
                   coef(r8_disc)["turnout_decline_pct:post"],
                   coef(r8_burg)["turnout_decline_pct:post"]),
  se_tipyear = c(se(r8_hom)["turnout_decline_pct:post"],
                 se(r8_drugs)["turnout_decline_pct:post"],
                 se(r8_disc)["turnout_decline_pct:post"],
                 se(r8_burg)["turnout_decline_pct:post"])
)
fwrite(tipyear_results, file.path(data_dir, "tipyear_results.csv"))

covpost_results <- data.frame(
  outcome = c("Homicide", "Drugs", "Discretionary", "Burglary"),
  beta_covpost = c(coef(r9_hom)["turnout_decline_pct:post"],
                   coef(r9_drugs)["turnout_decline_pct:post"],
                   coef(r9_disc)["turnout_decline_pct:post"],
                   coef(r9_burg)["turnout_decline_pct:post"]),
  se_covpost = c(se(r9_hom)["turnout_decline_pct:post"],
                 se(r9_drugs)["turnout_decline_pct:post"],
                 se(r9_disc)["turnout_decline_pct:post"],
                 se(r9_burg)["turnout_decline_pct:post"])
)
fwrite(covpost_results, file.path(data_dir, "covpost_results.csv"))

rates_results <- data.frame(
  outcome = c("Homicide", "Drugs", "Discretionary", "Burglary"),
  beta_rate = c(coef(r10_hom)["turnout_decline_pct:post"],
                coef(r10_drugs)["turnout_decline_pct:post"],
                coef(r10_disc)["turnout_decline_pct:post"],
                coef(r10_burg)["turnout_decline_pct:post"]),
  se_rate = c(se(r10_hom)["turnout_decline_pct:post"],
              se(r10_drugs)["turnout_decline_pct:post"],
              se(r10_disc)["turnout_decline_pct:post"],
              se(r10_burg)["turnout_decline_pct:post"])
)
fwrite(rates_results, file.path(data_dir, "rates_results.csv"))

cat("\n=== Robustness checks complete ===\n")
