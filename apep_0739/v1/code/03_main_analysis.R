## 03_main_analysis.R — Main event study and DiD analysis
## APEP-0739: GP Practice Closures and A&E Utilization

source("code/00_packages.R")

ae_qtr    <- readRDS("data/ae_analysis.rds")
gp_closures <- readRDS("data/gp_closures_mapped.rds")

cat("=== STEP 1: Descriptive checks ===\n")

## Treatment rollout
rollout <- ae_qtr[first_treat_qtr > 0, .(first_treat_qtr = first_treat_qtr[1]), by = provider_code]
cat("Treatment cohort sizes:\n")
print(rollout[, .N, by = first_treat_qtr][order(first_treat_qtr)])

## Average outcomes by treatment status
means <- ae_qtr[, .(
  mean_type1 = mean(type1_att, na.rm = TRUE),
  sd_type1 = sd(type1_att, na.rm = TRUE),
  n_trusts = uniqueN(provider_code)
), by = .(treated = first_treat_qtr > 0)]
cat("\nMean Type 1 A&E attendances by treatment status:\n")
print(means)


cat("\n=== STEP 2: Callaway-Sant'Anna DiD ===\n")

cs_data <- copy(ae_qtr)
cs_data[, g := first_treat_qtr]

cs_out <- att_gt(
  yname = "log_type1",
  tname = "qtr_num",
  idname = "trust_id",
  gname = "g",
  data = cs_data,
  control_group = "nevertreated",
  base_period = "universal",
  est_method = "dr",
  clustervars = "provider_code",
  print_details = FALSE
)

## Dynamic aggregation (event study)
cs_es <- aggte(cs_out, type = "dynamic", min_e = -6, max_e = 6, na.rm = TRUE)
cat("\nCS Dynamic Event Study:\n")
print(summary(cs_es))

## Overall ATT
cs_overall <- aggte(cs_out, type = "simple", na.rm = TRUE)
cat("\nCS Overall ATT:\n")
cat(sprintf("  ATT = %.4f (SE = %.4f, 95%% CI: [%.4f, %.4f])\n",
            cs_overall$overall.att, cs_overall$overall.se,
            cs_overall$overall.att - 1.96 * cs_overall$overall.se,
            cs_overall$overall.att + 1.96 * cs_overall$overall.se))

## Calendar-time aggregation
cs_cal <- aggte(cs_out, type = "calendar", na.rm = TRUE)
cat("\nCS Calendar-Time Aggregation:\n")
print(summary(cs_cal))


cat("\n=== STEP 3: TWFE Regressions ===\n")

## Post indicator
ae_qtr[, post := as.integer(qtr_num >= first_treat_qtr & first_treat_qtr > 0)]

## Spec 1: Binary treatment (any nearby closure)
twfe1 <- feols(
  log_type1 ~ post | provider_code + qtr_num,
  data = ae_qtr,
  cluster = ~provider_code
)

## Spec 2: Treatment intensity (cumulative closures)
twfe2 <- feols(
  log_type1 ~ cum_closures | provider_code + qtr_num,
  data = ae_qtr,
  cluster = ~provider_code
)

## Spec 3: Levels (not logs)
twfe3 <- feols(
  type1_att ~ post | provider_code + qtr_num,
  data = ae_qtr,
  cluster = ~provider_code
)

## Spec 4: Total attendances (including minor A&E)
twfe4 <- feols(
  log_total ~ post | provider_code + qtr_num,
  data = ae_qtr,
  cluster = ~provider_code
)

cat("\nTWFE Results:\n")
cat("Spec 1 (log Type 1, binary): β =", coef(twfe1), " SE =", se(twfe1), "\n")
cat("Spec 2 (log Type 1, intensity): β =", coef(twfe2), " SE =", se(twfe2), "\n")
cat("Spec 3 (levels Type 1, binary): β =", coef(twfe3), " SE =", se(twfe3), "\n")
cat("Spec 4 (log Total, binary): β =", coef(twfe4), " SE =", se(twfe4), "\n")


cat("\n=== STEP 4: TWFE Event Study (fixest) ===\n")

## Simple event study using fixest (not sunab — too many cohorts)
ae_qtr[, event_time := ifelse(first_treat_qtr > 0, qtr_num - first_treat_qtr, NA_real_)]

## Restrict event window to -6 to +6 and bin endpoints
ae_es <- copy(ae_qtr[!is.na(event_time)])
ae_es[, event_time_binned := pmax(-6, pmin(6, event_time))]
ae_es[, event_time_binned := factor(event_time_binned)]
ae_es[, event_time_binned := relevel(event_time_binned, ref = "-1")]

twfe_es <- feols(
  log_type1 ~ event_time_binned | provider_code + qtr_num,
  data = ae_es,
  cluster = ~provider_code
)

cat("\nTWFE Event Study:\n")
print(summary(twfe_es))


cat("\n=== STEP 5: Save results ===\n")

results <- list(
  cs_out = cs_out,
  cs_es = cs_es,
  cs_overall = cs_overall,
  cs_cal = cs_cal,
  twfe1 = twfe1,
  twfe2 = twfe2,
  twfe3 = twfe3,
  twfe4 = twfe4,
  twfe_es = twfe_es
)
saveRDS(results, "data/main_results.rds")

## Diagnostics for validator
n_treated_units <- uniqueN(ae_qtr[first_treat_qtr > 0, provider_code])
n_pre_periods <- 6  # We use 6 pre-periods in event study
n_obs <- nrow(ae_qtr)

jsonlite::write_json(
  list(n_treated = n_treated_units, n_pre = n_pre_periods, n_obs = n_obs),
  "data/diagnostics.json",
  auto_unbox = TRUE
)

cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            n_treated_units, n_pre_periods, n_obs))
cat("Main analysis complete.\n")
