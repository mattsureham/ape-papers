# 04_robustness.R — Robustness checks for null result
# APEP Working Paper apep_1290

source("00_packages.R")

panel <- readRDS("../data/panel_scm.rds")
params <- readRDS("../data/params.rds")
geo_ids <- readRDS("../data/geo_ids.rds")
time_ids <- readRDS("../data/time_ids.rds")
results <- readRDS("../data/results.rds")

ireland_id <- params$ireland_id
treat_start <- params$treat_start
event2_time <- time_ids$time_id[time_ids$yq == zoo::as.yearqtr("2020 Q3")]
event3_time <- time_ids$time_id[time_ids$yq == zoo::as.yearqtr("2024 Q3")]

# Full panel units
full_units <- unique(panel$geo_id)
donor_ids <- setdiff(full_units, ireland_id)

# Pre-period definitions
pre_periods <- time_ids$time_id[time_ids$time_id < treat_start]
mid_pre <- median(pre_periods)
first_half <- pre_periods[pre_periods <= mid_pre]
second_half <- pre_periods[pre_periods > mid_pre]

# ---------------------------------------------------------------
# 1. SCM on log(tax levels in EUR millions)
#    Avoids GDP denominator problem
# ---------------------------------------------------------------

cat("=== Robustness 1: SCM on log(tax revenue EUR mn) ===\n")

scm_lev <- panel %>%
  filter(!is.na(log_tax)) %>%
  select(geo_id, time_id, log_tax, yq) %>%
  as.data.frame()

# Balance check
bal <- scm_lev %>% group_by(geo_id) %>% summarise(n = n(), .groups = "drop")
full_lev <- bal$geo_id[bal$n == max(bal$n)]
scm_lev <- scm_lev %>% filter(geo_id %in% full_lev)
donor_lev <- setdiff(full_lev, ireland_id)

dp_lev <- tryCatch({
  dataprep(
    foo = scm_lev,
    predictors = "log_tax",
    predictors.op = "mean",
    time.predictors.prior = first_half,
    special.predictors = list(
      list("log_tax", second_half, "mean"),
      list("log_tax", c(treat_start - 4, treat_start - 3,
                         treat_start - 2, treat_start - 1), "mean")
    ),
    dependent = "log_tax",
    unit.variable = "geo_id",
    time.variable = "time_id",
    treatment.identifier = ireland_id,
    controls.identifier = donor_lev,
    time.optimize.ssr = pre_periods,
    time.plot = sort(unique(scm_lev$time_id))
  )
}, error = function(e) { cat("  dataprep error:", conditionMessage(e), "\n"); NULL })

if (!is.null(dp_lev)) {
  synth_lev <- synth(dp_lev, verbose = FALSE)
  gaps_lev <- dp_lev$Y1plot - (dp_lev$Y0plot %*% synth_lev$solution.w)
  gap_lev_df <- data.frame(
    time_id = as.numeric(rownames(gaps_lev)),
    gap = as.numeric(gaps_lev)
  ) %>% left_join(time_ids, by = "time_id")

  pre_rmspe_lev <- sqrt(mean(gap_lev_df$gap[gap_lev_df$time_id < treat_start]^2))
  post_mean_lev <- mean(gap_lev_df$gap[gap_lev_df$time_id >= treat_start])

  # Period-specific gaps
  gap_lev_p1 <- mean(gap_lev_df$gap[gap_lev_df$time_id >= treat_start & gap_lev_df$time_id < event2_time])
  gap_lev_p2 <- mean(gap_lev_df$gap[gap_lev_df$time_id >= event2_time & gap_lev_df$time_id < event3_time])
  gap_lev_p3 <- mean(gap_lev_df$gap[gap_lev_df$time_id >= event3_time])

  cat(sprintf("  Pre-RMSPE (log levels): %.3f\n", pre_rmspe_lev))
  cat(sprintf("  Post gap (log levels): %.3f (= %.1f%% relative)\n",
              post_mean_lev, (exp(post_mean_lev) - 1) * 100))
  cat(sprintf("  Period 1 gap: %.3f (%.1f%%)\n", gap_lev_p1, (exp(gap_lev_p1) - 1) * 100))
  cat(sprintf("  Period 2 gap: %.3f (%.1f%%)\n", gap_lev_p2, (exp(gap_lev_p2) - 1) * 100))
  cat(sprintf("  Period 3 gap: %.3f (%.1f%%)\n", gap_lev_p3, (exp(gap_lev_p3) - 1) * 100))

  # Weights
  w_lev <- data.frame(geo_id = donor_lev, weight = as.numeric(synth_lev$solution.w)) %>%
    left_join(geo_ids, by = "geo_id") %>% arrange(desc(weight))
  cat("  Top weights (levels):\n")
  print(head(w_lev, 5))
} else {
  gap_lev_df <- NULL
  pre_rmspe_lev <- NA
  post_mean_lev <- NA
  gap_lev_p1 <- NA; gap_lev_p2 <- NA; gap_lev_p3 <- NA
}

# ---------------------------------------------------------------
# 2. SCM on tax revenue as share of total government revenue
# ---------------------------------------------------------------

cat("\n=== Robustness 2: SCM on income tax / total revenue ===\n")

scm_share <- panel %>%
  filter(!is.na(tax_share_rev), is.finite(tax_share_rev)) %>%
  select(geo_id, time_id, tax_share_rev, yq) %>%
  as.data.frame()

bal_s <- scm_share %>% group_by(geo_id) %>% summarise(n = n(), .groups = "drop")
full_s <- bal_s$geo_id[bal_s$n == max(bal_s$n)]
scm_share <- scm_share %>% filter(geo_id %in% full_s)
donor_s <- setdiff(full_s, ireland_id)

dp_share <- tryCatch({
  dataprep(
    foo = scm_share,
    predictors = "tax_share_rev",
    predictors.op = "mean",
    time.predictors.prior = first_half,
    special.predictors = list(
      list("tax_share_rev", second_half, "mean"),
      list("tax_share_rev", c(treat_start - 4, treat_start - 3,
                               treat_start - 2, treat_start - 1), "mean")
    ),
    dependent = "tax_share_rev",
    unit.variable = "geo_id",
    time.variable = "time_id",
    treatment.identifier = ireland_id,
    controls.identifier = donor_s,
    time.optimize.ssr = pre_periods,
    time.plot = sort(unique(scm_share$time_id))
  )
}, error = function(e) { cat("  dataprep error:", conditionMessage(e), "\n"); NULL })

if (!is.null(dp_share)) {
  synth_share <- synth(dp_share, verbose = FALSE)
  gaps_share <- dp_share$Y1plot - (dp_share$Y0plot %*% synth_share$solution.w)
  gap_share_df <- data.frame(
    time_id = as.numeric(rownames(gaps_share)),
    gap = as.numeric(gaps_share)
  ) %>% left_join(time_ids, by = "time_id")

  pre_rmspe_share <- sqrt(mean(gap_share_df$gap[gap_share_df$time_id < treat_start]^2))
  post_mean_share <- mean(gap_share_df$gap[gap_share_df$time_id >= treat_start])
  gap_share_p1 <- mean(gap_share_df$gap[gap_share_df$time_id >= treat_start & gap_share_df$time_id < event2_time])

  cat(sprintf("  Pre-RMSPE (share): %.3f pp\n", pre_rmspe_share))
  cat(sprintf("  Post gap (share): %.3f pp\n", post_mean_share))
  cat(sprintf("  Period 1 gap: %.3f pp\n", gap_share_p1))

  w_share <- data.frame(geo_id = donor_s, weight = as.numeric(synth_share$solution.w)) %>%
    left_join(geo_ids, by = "geo_id") %>% arrange(desc(weight))
  cat("  Top weights (share):\n")
  print(head(w_share, 5))
} else {
  gap_share_df <- NULL
  pre_rmspe_share <- NA
  post_mean_share <- NA
  gap_share_p1 <- NA
}

# ---------------------------------------------------------------
# 3. Leave-one-out analysis for main SCM
# ---------------------------------------------------------------

cat("\n=== Robustness 3: Leave-one-out SCM ===\n")

# Re-run main SCM dropping each top donor
main_weights <- results$weights_df %>% filter(weight > 0.01) %>% pull(geo_id)

loo_gaps <- list()
for (drop_id in main_weights) {
  geo_name <- geo_ids$geo[geo_ids$geo_id == drop_id]
  remaining <- setdiff(donor_ids, drop_id)

  dp_loo <- tryCatch({
    scm_data <- panel %>%
      filter(!is.na(tax_pct_gdp), geo_id %in% c(ireland_id, remaining)) %>%
      select(geo_id, time_id, tax_pct_gdp, yq) %>%
      as.data.frame()

    dataprep(
      foo = scm_data,
      predictors = "tax_pct_gdp",
      predictors.op = "mean",
      time.predictors.prior = first_half,
      special.predictors = list(
        list("tax_pct_gdp", second_half, "mean"),
        list("tax_pct_gdp", c(treat_start - 4, treat_start - 3,
                               treat_start - 2, treat_start - 1), "mean")
      ),
      dependent = "tax_pct_gdp",
      unit.variable = "geo_id",
      time.variable = "time_id",
      treatment.identifier = ireland_id,
      controls.identifier = remaining,
      time.optimize.ssr = pre_periods,
      time.plot = sort(unique(panel$time_id))
    )
  }, error = function(e) NULL)

  if (is.null(dp_loo)) { next }

  synth_loo <- tryCatch(synth(dp_loo, verbose = FALSE), error = function(e) NULL)
  if (is.null(synth_loo)) { next }

  g <- dp_loo$Y1plot - (dp_loo$Y0plot %*% synth_loo$solution.w)
  post_gap <- mean(g[as.numeric(rownames(g)) >= treat_start, ])
  loo_gaps[[geo_name]] <- post_gap
  cat(sprintf("  Drop %s: post-treatment gap = %.3f pp\n", geo_name, post_gap))
}

cat("\nLeave-one-out: main result is robust if all gaps have same sign.\n")
cat(sprintf("  Main gap: %.3f pp\n", results$gap_period1$mean_gap))
cat(sprintf("  LOO range: [%.3f, %.3f]\n",
            min(unlist(loo_gaps)), max(unlist(loo_gaps))))

# ---------------------------------------------------------------
# 4. Placebo treatment date (2014-Q1 — before any Apple events)
# ---------------------------------------------------------------

cat("\n=== Robustness 4: Placebo treatment date (2014-Q1) ===\n")

placebo_treat <- time_ids$time_id[time_ids$yq == zoo::as.yearqtr("2014 Q1")]
placebo_pre <- pre_periods[pre_periods < placebo_treat]

if (length(placebo_pre) >= 20) {
  ph1 <- placebo_pre[placebo_pre <= median(placebo_pre)]
  ph2 <- placebo_pre[placebo_pre > median(placebo_pre)]

  scm_data_p <- panel %>%
    filter(!is.na(tax_pct_gdp)) %>%
    select(geo_id, time_id, tax_pct_gdp, yq) %>%
    as.data.frame()

  dp_placebo <- tryCatch({
    dataprep(
      foo = scm_data_p,
      predictors = "tax_pct_gdp",
      predictors.op = "mean",
      time.predictors.prior = ph1,
      special.predictors = list(
        list("tax_pct_gdp", ph2, "mean"),
        list("tax_pct_gdp", c(placebo_treat - 4, placebo_treat - 3,
                               placebo_treat - 2, placebo_treat - 1), "mean")
      ),
      dependent = "tax_pct_gdp",
      unit.variable = "geo_id",
      time.variable = "time_id",
      treatment.identifier = ireland_id,
      controls.identifier = donor_ids,
      time.optimize.ssr = placebo_pre,
      time.plot = time_ids$time_id[time_ids$time_id >= min(placebo_pre) &
                                     time_ids$time_id <= treat_start]
    )
  }, error = function(e) { cat("Error:", conditionMessage(e), "\n"); NULL })

  if (!is.null(dp_placebo)) {
    synth_p <- tryCatch(synth(dp_placebo, verbose = FALSE), error = function(e) NULL)
    if (!is.null(synth_p)) {
      g_p <- dp_placebo$Y1plot - (dp_placebo$Y0plot %*% synth_p$solution.w)
      # Gap between placebo treatment (2014) and actual treatment (2016)
      window <- time_ids$time_id[time_ids$time_id >= placebo_treat &
                                   time_ids$time_id < treat_start]
      placebo_gap <- mean(g_p[as.character(window), ])
      cat(sprintf("  Placebo gap (2014-Q1 to 2016-Q3): %.3f pp\n", placebo_gap))
    }
  }
}

# ---------------------------------------------------------------
# 5. Irish income tax levels — descriptive decomposition
# ---------------------------------------------------------------

cat("\n=== Descriptive: Irish income tax levels ===\n")

ie_data <- panel %>%
  filter(geo_id == ireland_id) %>%
  select(yq, tax_pct_gdp, tax_mio_eur, gdp_meur)

# Pre-2016 vs post-2016 comparison
ie_pre <- ie_data %>% filter(yq < zoo::as.yearqtr("2016 Q3"))
ie_post <- ie_data %>% filter(yq >= zoo::as.yearqtr("2016 Q3"))

cat(sprintf("  Pre-ruling mean tax/GDP: %.2f%%\n", mean(ie_pre$tax_pct_gdp, na.rm=T)))
cat(sprintf("  Post-ruling mean tax/GDP: %.2f%%\n", mean(ie_post$tax_pct_gdp, na.rm=T)))
cat(sprintf("  Pre-ruling mean tax (EUR mn): %.0f\n", mean(ie_pre$tax_mio_eur, na.rm=T)))
cat(sprintf("  Post-ruling mean tax (EUR mn): %.0f\n", mean(ie_post$tax_mio_eur, na.rm=T)))
cat(sprintf("  Pre-ruling mean GDP (EUR mn): %.0f\n", mean(ie_pre$gdp_meur, na.rm=T)))
cat(sprintf("  Post-ruling mean GDP (EUR mn): %.0f\n", mean(ie_post$gdp_meur, na.rm=T)))
cat(sprintf("  GDP growth (pre to post mean): %.1f%%\n",
            (mean(ie_post$gdp_meur, na.rm=T) / mean(ie_pre$gdp_meur, na.rm=T) - 1) * 100))
cat(sprintf("  Tax growth (pre to post mean): %.1f%%\n",
            (mean(ie_post$tax_mio_eur, na.rm=T) / mean(ie_pre$tax_mio_eur, na.rm=T) - 1) * 100))

# ---------------------------------------------------------------
# Save robustness results
# ---------------------------------------------------------------

robustness <- list(
  gap_lev_df = gap_lev_df,
  pre_rmspe_lev = pre_rmspe_lev,
  post_mean_lev = post_mean_lev,
  gap_lev_p1 = gap_lev_p1,
  gap_lev_p2 = gap_lev_p2,
  gap_lev_p3 = gap_lev_p3,
  gap_share_df = gap_share_df,
  pre_rmspe_share = pre_rmspe_share,
  post_mean_share = post_mean_share,
  gap_share_p1 = gap_share_p1,
  loo_gaps = loo_gaps
)

saveRDS(robustness, "../data/robustness.rds")

cat("\n=== Robustness analysis complete ===\n")
