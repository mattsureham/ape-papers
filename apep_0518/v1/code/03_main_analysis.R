## =============================================================================
## 03_main_analysis.R — Primary DiD and event study
## =============================================================================

source("00_packages.R")

data_dir <- "../data"

## ---- 1. Load panel ----
panel_nozfu <- fread(file.path(data_dir, "panel_nozfu.csv"))
panel_main <- fread(file.path(data_dir, "panel_main.csv"))
zus_dt <- fread(file.path(data_dir, "zus_treatment_status.csv"))

cat("Panel loaded. N(lost):", panel_nozfu[lost_status == 1, uniqueN(zus_id)],
    "| N(kept):", panel_nozfu[lost_status == 0, uniqueN(zus_id)], "\n")

## ---- 2. Summary statistics ----
cat("\n=== Summary Statistics ===\n")

sumstats <- panel_nozfu[year %in% 2010:2014, .(
  mean_firms = mean(n_firms_created),
  sd_firms = sd(n_firms_created),
  median_firms = median(n_firms_created),
  p25 = quantile(n_firms_created, 0.25),
  p75 = quantile(n_firms_created, 0.75),
  n_obs = .N,
  n_neighborhoods = uniqueN(zus_id)
), by = .(Group = fifelse(lost_status == 1, "Lost Status", "Kept Status"))]

print(sumstats)
fwrite(sumstats, file.path(data_dir, "summary_stats_pre.csv"))

# Balance table
balance <- panel_nozfu[year == 2014, .(
  firms_2014 = mean(n_firms_created),
  log_firms_2014 = mean(log_firms)
), by = .(Group = fifelse(lost_status == 1, "Lost Status", "Kept Status"))]

fwrite(balance, file.path(data_dir, "balance_table.csv"))

## ---- 3. Static DiD (pooled pre/post) ----
cat("\n=== Static DiD ===\n")

# Main specification: TWFE with neighborhood + year FE
did_main <- feols(n_firms_created ~ lost_status:post | zus_id + year,
                  data = panel_nozfu, cluster = ~zus_id)

# Log specification
did_log <- feols(log_firms ~ lost_status:post | zus_id + year,
                 data = panel_nozfu, cluster = ~zus_id)

# Poisson specification
did_pois <- fepois(n_firms_created ~ lost_status:post | zus_id + year,
                   data = panel_nozfu, cluster = ~zus_id)

cat("\nStatic DiD results (excluding ZFU):\n")
etable(did_main, did_log, did_pois,
       headers = c("Levels", "Log(firms+1)", "Poisson"))

# Save coefficients
did_results <- data.table(
  specification = c("Levels", "Log", "Poisson"),
  coef = c(coef(did_main)["lost_status:post"],
           coef(did_log)["lost_status:post"],
           coef(did_pois)["lost_status:post"]),
  se = c(se(did_main)["lost_status:post"],
         se(did_log)["lost_status:post"],
         se(did_pois)["lost_status:post"]),
  pval = c(pvalue(did_main)["lost_status:post"],
           pvalue(did_log)["lost_status:post"],
           pvalue(did_pois)["lost_status:post"])
)
fwrite(did_results, file.path(data_dir, "did_static_results.csv"))

## ---- 4. Event Study ----
cat("\n=== Event Study ===\n")

# Create relative year factor (omit -1)
panel_nozfu[, rel_year_f := factor(rel_year)]

# Event study specification
es_main <- feols(n_firms_created ~ i(rel_year, lost_status, ref = -1) | zus_id + year,
                 data = panel_nozfu[rel_year >= -5 & rel_year <= 9],
                 cluster = ~zus_id)

es_log <- feols(log_firms ~ i(rel_year, lost_status, ref = -1) | zus_id + year,
                data = panel_nozfu[rel_year >= -5 & rel_year <= 9],
                cluster = ~zus_id)

cat("\nEvent study (levels):\n")
summary(es_main)

# Extract event-study coefficients
es_coefs <- as.data.table(coeftable(es_main))
es_coefs[, rel_year := as.integer(gsub("rel_year::([-0-9]+):lost_status", "\\1",
                                        rownames(coeftable(es_main))))]
setnames(es_coefs, c("estimate", "se", "tval", "pval", "rel_year"))
es_coefs <- es_coefs[!is.na(rel_year)]

# Add the reference year
es_coefs <- rbind(es_coefs, data.table(estimate = 0, se = 0, tval = NA, pval = NA, rel_year = -1))
es_coefs <- es_coefs[order(rel_year)]
es_coefs[, `:=`(ci_lo = estimate - 1.96 * se, ci_hi = estimate + 1.96 * se)]

fwrite(es_coefs, file.path(data_dir, "event_study_coefs.csv"))

# Log version
es_log_coefs <- as.data.table(coeftable(es_log))
es_log_coefs[, rel_year := as.integer(gsub("rel_year::([-0-9]+):lost_status", "\\1",
                                            rownames(coeftable(es_log))))]
setnames(es_log_coefs, c("estimate", "se", "tval", "pval", "rel_year"))
es_log_coefs <- es_log_coefs[!is.na(rel_year)]
es_log_coefs <- rbind(es_log_coefs, data.table(estimate = 0, se = 0, tval = NA, pval = NA, rel_year = -1))
es_log_coefs <- es_log_coefs[order(rel_year)]
es_log_coefs[, `:=`(ci_lo = estimate - 1.96 * se, ci_hi = estimate + 1.96 * se)]

fwrite(es_log_coefs, file.path(data_dir, "event_study_log_coefs.csv"))

## ---- 5. Pre-trend test ----
cat("\n=== Pre-trend joint F-test ===\n")

# Test: all pre-treatment coefficients = 0
pre_coefs <- es_coefs[rel_year < -1 & rel_year >= -5]
if (nrow(pre_coefs) > 0) {
  pre_test <- wald(es_main, paste0("rel_year::", -5:-2, ":lost_status"))
  cat("Pre-trend F-test p-value:", pre_test$p, "\n")
  fwrite(data.table(f_stat = pre_test$stat, df1 = pre_test$df1,
                    df2 = pre_test$df2, p_value = pre_test$p),
         file.path(data_dir, "pre_trend_test.csv"))
} else {
  cat("Insufficient pre-treatment coefficients for F-test.\n")
}

## ---- 6. Including ZFU sample ----
cat("\n=== Full sample (including ZFU) ===\n")

did_full <- feols(n_firms_created ~ lost_status:post | zus_id + year,
                  data = panel_main, cluster = ~zus_id)

# Interact with ZFU status
panel_main[, is_zfu_num := as.integer(is_zfu)]
did_zfu_interact <- feols(n_firms_created ~ lost_status:post +
                            lost_status:post:is_zfu_num | zus_id + year,
                          data = panel_main, cluster = ~zus_id)

cat("\nComparison: excluding vs. including ZFU:\n")
etable(did_main, did_full, did_zfu_interact,
       headers = c("Excl. ZFU", "Incl. ZFU", "ZFU interaction"))

## ---- 7. Displacement test ----
cat("\n=== Displacement Test ===\n")

# For displacement, we need the "gained" group
panel_full <- fread(file.path(data_dir, "panel_full.csv"))

# If we have gained-status neighborhoods
if ("gained" %in% panel_full$status || nrow(panel_full[status == "ambiguous"]) > 0) {
  cat("Note: Displacement test requires QPV-only neighborhoods (not in ZUS).\n")
  cat("This will be implemented with QPV centroids in extended analysis.\n")
}

# For now, test aggregate effect within ZUS universe
agg_by_status <- panel_nozfu[, .(total_firms = sum(n_firms_created)),
                              by = .(status, period = fifelse(year < 2015, "pre", "post"))]
agg_wide <- dcast(agg_by_status, status ~ period, value.var = "total_firms")
agg_wide[, change := post - pre]
agg_wide[, pct_change := round(100 * (post - pre) / pre, 1)]

cat("\nAggregate firm creation changes:\n")
print(agg_wide)
fwrite(agg_wide, file.path(data_dir, "displacement_aggregate.csv"))

## ---- 8. Save model objects ----
cat("\n=== Saving analysis results ===\n")
saveRDS(list(
  did_main = did_main,
  did_log = did_log,
  did_pois = did_pois,
  es_main = es_main,
  es_log = es_log,
  did_full = did_full
), file.path(data_dir, "models.rds"))

cat("Main analysis complete.\n")
