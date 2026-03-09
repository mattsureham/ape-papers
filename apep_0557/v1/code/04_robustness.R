## ============================================================
## 04_robustness.R — Robustness checks and placebo tests
## Paper: Does Foreign Aid Buffer Oil Revenue Shocks?
##        Geocoded Evidence from Nigeria
## ============================================================

source("00_packages.R")

DATA_DIR <- "../data"

panel <- readRDS(file.path(DATA_DIR, "analysis_panel.rds"))
cat(sprintf("Panel loaded: %d obs\n", nrow(panel)))

## ============================================================
## 1) Wild cluster bootstrap
## ============================================================

cat("\n========== WILD CLUSTER BOOTSTRAP ==========\n")

## Using fwildclusterboot for wild cluster bootstrap with 37 clusters
if (requireNamespace("fwildclusterboot", quietly = TRUE)) {
  library(fwildclusterboot)

  ## Base model
  m_base <- feols(log_events ~ log_aid_x_post | state + ym,
                  data = panel, cluster = ~state)

  set.seed(42)
  boot_res <- tryCatch({
    boottest(m_base, param = "log_aid_x_post",
             clustid = ~state, B = 999, type = "webb")
  }, error = function(e) {
    cat("Wild bootstrap failed:", e$message, "\n")
    NULL
  })

  if (!is.null(boot_res)) {
    cat(sprintf("Wild cluster bootstrap p-value: %.4f\n", boot_res$p_val))
    cat(sprintf("Wild bootstrap CI: [%.4f, %.4f]\n",
                boot_res$conf_int[1], boot_res$conf_int[2]))

    wcb_results <- data.table(
      test = "Wild Cluster Bootstrap",
      p_value = boot_res$p_val,
      ci_lo = boot_res$conf_int[1],
      ci_hi = boot_res$conf_int[2]
    )
    fwrite(wcb_results, file.path(DATA_DIR, "wild_bootstrap.csv"))
  }
} else {
  cat("fwildclusterboot not available. Installing...\n")
  install.packages("fwildclusterboot", repos = "https://cloud.r-project.org")
  cat("Please re-run after installation.\n")
}

## ============================================================
## 2) Randomization inference
## ============================================================

cat("\n========== RANDOMIZATION INFERENCE ==========\n")

## Permute aid exposure across states
set.seed(42)
n_perms <- 1000

## Original estimate
m_orig <- feols(log_events ~ log_aid_x_post | state + ym,
                data = panel, cluster = ~state)
orig_coef <- coef(m_orig)["log_aid_x_post"]

## Get unique states and their aid exposure
state_aid <- unique(panel[, .(state, log_aid)])
n_states <- nrow(state_aid)

perm_coefs <- numeric(n_perms)
for (i in seq_len(n_perms)) {
  ## Shuffle aid exposure across states
  perm_aid <- state_aid[sample(.N)]
  perm_map <- data.table(state = state_aid$state,
                          log_aid_perm = perm_aid$log_aid)

  panel_perm <- merge(panel, perm_map, by = "state")
  panel_perm[, log_aid_x_post_perm := log_aid_perm * post_shock]

  m_perm <- tryCatch({
    feols(log_events ~ log_aid_x_post_perm | state + ym,
          data = panel_perm, cluster = ~state)
  }, error = function(e) NULL)

  if (!is.null(m_perm)) {
    perm_coefs[i] <- coef(m_perm)["log_aid_x_post_perm"]
  } else {
    perm_coefs[i] <- NA
  }

  if (i %% 100 == 0) cat(sprintf("  RI permutation %d / %d\n", i, n_perms))
}

perm_coefs <- perm_coefs[!is.na(perm_coefs)]
ri_pvalue <- mean(abs(perm_coefs) >= abs(orig_coef))

cat(sprintf("\nRandomization Inference:\n"))
cat(sprintf("  Original coefficient: %.4f\n", orig_coef))
cat(sprintf("  RI p-value (two-sided): %.4f\n", ri_pvalue))
cat(sprintf("  Permutation distribution: mean=%.4f, sd=%.4f\n",
            mean(perm_coefs), sd(perm_coefs)))

ri_results <- data.table(
  original_coef = orig_coef,
  ri_pvalue = ri_pvalue,
  perm_mean = mean(perm_coefs),
  perm_sd = sd(perm_coefs),
  n_perms = length(perm_coefs)
)
fwrite(ri_results, file.path(DATA_DIR, "ri_results.csv"))

## Save permutation distribution for plotting
fwrite(data.table(perm_coef = perm_coefs),
       file.path(DATA_DIR, "ri_permutation_dist.csv"))

## ============================================================
## 3) Alternative shock windows
## ============================================================

cat("\n========== ALTERNATIVE SHOCK WINDOWS ==========\n")

shock_dates <- c("2008-07-01", "2008-10-01", "2009-01-01", "2009-04-01")
alt_shock_results <- list()

for (sd in shock_dates) {
  panel[, post_alt := as.integer(ym >= as.Date(sd))]
  panel[, aid_post_alt := log_aid * post_alt]

  m_alt <- feols(log_events ~ aid_post_alt | state + ym,
                 data = panel, cluster = ~state)

  alt_shock_results[[sd]] <- data.table(
    shock_date = sd,
    estimate = coef(m_alt)["aid_post_alt"],
    se = se(m_alt)["aid_post_alt"],
    pvalue = pvalue(m_alt)["aid_post_alt"]
  )
}

alt_shocks <- rbindlist(alt_shock_results)
alt_shocks[, ci_lo := estimate - 1.96 * se]
alt_shocks[, ci_hi := estimate + 1.96 * se]
fwrite(alt_shocks, file.path(DATA_DIR, "alt_shock_results.csv"))
cat("Alternative shock results:\n")
print(alt_shocks)

## ============================================================
## 4) Placebo shocks (non-event years)
## ============================================================

cat("\n========== PLACEBO SHOCKS ==========\n")

placebo_dates <- c("2003-09-01", "2005-09-01", "2011-09-01")
placebo_results <- list()

for (pd in placebo_dates) {
  ## Use only pre-shock or post-recovery data for placebos
  if (as.Date(pd) < as.Date("2008-09-01")) {
    panel_sub <- panel[ym < as.Date("2008-09-01")]
  } else {
    panel_sub <- panel[ym >= as.Date("2010-01-01")]
  }

  panel_sub[, post_placebo := as.integer(ym >= as.Date(pd))]
  panel_sub[, aid_post_placebo := log_aid * post_placebo]

  m_placebo <- feols(log_events ~ aid_post_placebo | state + ym,
                     data = panel_sub, cluster = ~state)

  placebo_results[[pd]] <- data.table(
    placebo_date = pd,
    estimate = coef(m_placebo)["aid_post_placebo"],
    se = se(m_placebo)["aid_post_placebo"],
    pvalue = pvalue(m_placebo)["aid_post_placebo"]
  )
}

placebos <- rbindlist(placebo_results)
placebos[, ci_lo := estimate - 1.96 * se]
placebos[, ci_hi := estimate + 1.96 * se]
fwrite(placebos, file.path(DATA_DIR, "placebo_results.csv"))
cat("Placebo shock results:\n")
print(placebos)

## ============================================================
## 5) Leave-one-out (drop each state)
## ============================================================

cat("\n========== LEAVE-ONE-OUT ==========\n")

loo_results <- list()
states <- sort(unique(panel$state))

for (st in states) {
  m_loo <- feols(log_events ~ log_aid_x_post | state + ym,
                 data = panel[state != st], cluster = ~state)
  loo_results[[st]] <- data.table(
    dropped_state = st,
    estimate = coef(m_loo)["log_aid_x_post"],
    se = se(m_loo)["log_aid_x_post"]
  )
}

loo <- rbindlist(loo_results)
loo[, ci_lo := estimate - 1.96 * se]
loo[, ci_hi := estimate + 1.96 * se]
fwrite(loo, file.path(DATA_DIR, "loo_results.csv"))

cat(sprintf("LOO range: [%.4f, %.4f]\n", min(loo$estimate), max(loo$estimate)))
cat(sprintf("Full sample estimate: %.4f\n", orig_coef))

## ============================================================
## 6) Poisson PPML
## ============================================================

cat("\n========== POISSON PPML ==========\n")

m_pois <- tryCatch({
  fepois(n_events ~ log_aid_x_post | state + ym,
         data = panel, cluster = ~state)
}, error = function(e) {
  cat("Poisson estimation failed:", e$message, "\n")
  NULL
})

if (!is.null(m_pois)) {
  cat("Poisson PPML result:\n")
  print(summary(m_pois))

  pois_coef <- data.table(
    model = "Poisson PPML",
    estimate = coef(m_pois)["log_aid_x_post"],
    se = se(m_pois)["log_aid_x_post"],
    pvalue = pvalue(m_pois)["log_aid_x_post"]
  )
  fwrite(pois_coef, file.path(DATA_DIR, "poisson_results.csv"))
}

## ============================================================
## 7) Exclude FCT Abuja
## ============================================================

cat("\n========== EXCLUDE FCT ==========\n")

m_no_fct <- feols(log_events ~ log_aid_x_post | state + ym,
                  data = panel[state != "Federal Capital Territory"],
                  cluster = ~state)
cat("Excluding FCT:\n")
print(summary(m_no_fct))

## ============================================================
## 8) Oil-producing states triple interaction
## ============================================================

cat("\n========== OIL STATE TRIPLE DIFF ==========\n")

m_triple <- feols(log_events ~ log_aid_x_post +
                    oil_state:post_shock +
                    I(log_aid * oil_state * post_shock) | state + ym,
                  data = panel, cluster = ~state)
cat("Triple-diff (Aid × Post × Oil State):\n")
print(summary(m_triple))

triple_coef <- data.table(
  model = "Triple Diff",
  aid_post = coef(m_triple)["log_aid_x_post"],
  oil_post = coef(m_triple)["oil_state:post_shock"],
  triple = coef(m_triple)["I(log_aid * oil_state * post_shock)"]
)
fwrite(triple_coef, file.path(DATA_DIR, "triple_diff_results.csv"))

## ============================================================
## 9) Annual panel (alternative aggregation)
## ============================================================

cat("\n========== ANNUAL PANEL ==========\n")

panel_annual <- panel[, .(
  n_events      = sum(n_events),
  n_state_based = sum(n_state_based),
  n_non_state   = sum(n_non_state),
  fatalities    = sum(fatalities),
  civ_deaths    = sum(civ_deaths),
  oil_price   = mean(oil_price, na.rm = TRUE)
), by = .(state, year, state_id, aid_projects_2007, log_aid,
          high_aid, oil_state, post_shock = as.integer(year >= 2009))]

panel_annual[, log_events := log(n_events + 1)]
panel_annual[, log_fatalities := log(fatalities + 1)]
panel_annual[, log_aid_x_post := log_aid * post_shock]

m_annual <- feols(log_events ~ log_aid_x_post | state + year,
                  data = panel_annual, cluster = ~state)
cat("Annual panel result:\n")
print(summary(m_annual))

annual_coef <- data.table(
  model = "Annual Panel",
  estimate = coef(m_annual)["log_aid_x_post"],
  se = se(m_annual)["log_aid_x_post"],
  pvalue = pvalue(m_annual)["log_aid_x_post"]
)
fwrite(annual_coef, file.path(DATA_DIR, "annual_panel_results.csv"))

## ============================================================
## Compile robustness summary
## ============================================================

cat("\n========== ROBUSTNESS SUMMARY ==========\n")

robustness_summary <- rbindlist(list(
  data.table(test = "Main (monthly)", estimate = orig_coef,
             se = se(m_orig)["log_aid_x_post"],
             pvalue = pvalue(m_orig)["log_aid_x_post"]),
  data.table(test = "Annual panel",
             estimate = coef(m_annual)["log_aid_x_post"],
             se = se(m_annual)["log_aid_x_post"],
             pvalue = pvalue(m_annual)["log_aid_x_post"]),
  data.table(test = "Exclude FCT",
             estimate = coef(m_no_fct)["log_aid_x_post"],
             se = se(m_no_fct)["log_aid_x_post"],
             pvalue = pvalue(m_no_fct)["log_aid_x_post"]),
  if (!is.null(m_pois)) data.table(
    test = "Poisson PPML",
    estimate = coef(m_pois)["log_aid_x_post"],
    se = se(m_pois)["log_aid_x_post"],
    pvalue = pvalue(m_pois)["log_aid_x_post"]
  ),
  data.table(test = "RI p-value",
             estimate = orig_coef,
             se = NA_real_,
             pvalue = ri_pvalue)
), fill = TRUE)

## Use t-critical value with 36 df (37 clusters - 1) for consistency with p-values
t_crit <- qt(0.975, df = 36)
robustness_summary[, ci_lo := estimate - t_crit * se]
robustness_summary[, ci_hi := estimate + t_crit * se]
fwrite(robustness_summary, file.path(DATA_DIR, "robustness_summary.csv"))

cat("\nRobustness summary:\n")
print(robustness_summary)

## ============================================================
## 10) Exclude northeast states (Boko Haram core)
## ============================================================

cat("\n========== EXCLUDE NORTHEAST ==========\n")

northeast_states <- c("Borno", "Yobe", "Adamawa", "Bauchi", "Gombe", "Taraba")
m_no_ne <- feols(log_events ~ log_aid_x_post | state + ym,
                 data = panel[!state %in% northeast_states],
                 cluster = ~state)
cat("Excluding northeast (6 states):\n")
print(summary(m_no_ne))

ne_coef <- data.table(
  model = "Exclude Northeast",
  estimate = coef(m_no_ne)["log_aid_x_post"],
  se = se(m_no_ne)["log_aid_x_post"],
  pvalue = pvalue(m_no_ne)["log_aid_x_post"]
)
fwrite(ne_coef, file.path(DATA_DIR, "exclude_northeast_results.csv"))

## ============================================================
## 11) Region × post controls (geopolitical zone interactions)
## ============================================================

cat("\n========== REGION x POST CONTROLS ==========\n")

## Assign geopolitical zones
panel[, zone := fcase(
  state %in% c("Borno", "Yobe", "Adamawa", "Bauchi", "Gombe", "Taraba"), "NE",
  state %in% c("Jigawa", "Kaduna", "Kano", "Katsina", "Kebbi", "Sokoto", "Zamfara"), "NW",
  state %in% c("Benue", "Kogi", "Kwara", "Nasarawa", "Niger", "Plateau",
               "Federal Capital Territory"), "NC",
  state %in% c("Lagos", "Ogun", "Ondo", "Ekiti", "Osun", "Oyo"), "SW",
  state %in% c("Abia", "Anambra", "Ebonyi", "Enugu", "Imo"), "SE",
  state %in% c("Akwa Ibom", "Bayelsa", "Cross River", "Delta", "Edo", "Rivers"), "SS"
)]

m_zone_post <- feols(log_events ~ log_aid_x_post | state + ym + zone[post_shock],
                     data = panel, cluster = ~state)
cat("With zone × post controls:\n")
print(summary(m_zone_post))

zone_coef <- data.table(
  model = "Zone x Post FE",
  estimate = coef(m_zone_post)["log_aid_x_post"],
  se = se(m_zone_post)["log_aid_x_post"],
  pvalue = pvalue(m_zone_post)["log_aid_x_post"]
)
fwrite(zone_coef, file.path(DATA_DIR, "zone_post_results.csv"))

## ============================================================
## 12) Pre-trend joint F-test
## ============================================================

cat("\n========== PRE-TREND JOINT F-TEST ==========\n")

## Event study model
panel[, event_time := as.integer(difftime(ym, as.Date("2008-09-01"),
                                           units = "days")) / 30.44]
panel[, event_time := round(event_time)]
panel[, event_time_binned := pmax(pmin(event_time, 24), -24)]
m_es <- feols(log_events ~ i(event_time_binned, log_aid, ref = -1) | state + ym,
              data = panel, cluster = ~state)

## Extract pre-period coefficients
es_coefs <- coeftable(m_es)
pre_coef_names <- rownames(es_coefs)[grepl("event_time_binned::-", rownames(es_coefs))]
cat(sprintf("Pre-period coefficients: %d\n", length(pre_coef_names)))

## Joint F-test on pre-period coefficients
if (length(pre_coef_names) > 0) {
  f_test <- wald(m_es, pre_coef_names)
  cat(sprintf("Joint F-test on pre-trends: F = %.3f, p = %.4f\n",
              f_test$stat, f_test$p))

  pretrend_results <- data.table(
    f_stat = f_test$stat,
    p_value = f_test$p,
    n_coefs = length(pre_coef_names)
  )
  fwrite(pretrend_results, file.path(DATA_DIR, "pretrend_ftest.csv"))
}

## Save models
save(m_base, m_no_fct, m_triple, m_annual, m_no_ne, m_zone_post,
     file = file.path(DATA_DIR, "robustness_models.RData"))

cat("\nRobustness checks complete.\n")
