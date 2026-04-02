# 07_loglevel_placebos.R — Permutation inference for log-level SCM
# Addresses reviewer concern: levels result needs placebo p-values

source("00_packages.R")

panel <- readRDS("../data/panel_scm.rds")
params <- readRDS("../data/params.rds")
geo_ids <- readRDS("../data/geo_ids.rds")
time_ids <- readRDS("../data/time_ids.rds")
robustness <- readRDS("../data/robustness.rds")

ireland_id <- params$ireland_id
treat_start <- params$treat_start

pre_periods <- time_ids$time_id[time_ids$time_id < treat_start]
mid_pre <- median(pre_periods)
first_half <- pre_periods[pre_periods <= mid_pre]
second_half <- pre_periods[pre_periods > mid_pre]

# Balanced log-level panel
scm_lev <- panel %>%
  filter(!is.na(log_tax)) %>%
  select(geo_id, time_id, log_tax, yq) %>%
  as.data.frame()

bal <- scm_lev %>% group_by(geo_id) %>% summarise(n = n(), .groups = "drop")
full_lev <- bal$geo_id[bal$n == max(bal$n)]
scm_lev <- scm_lev %>% filter(geo_id %in% full_lev)
donor_lev <- setdiff(full_lev, ireland_id)

# Ireland's log-level gaps (from robustness.rds)
gap_lev_df <- robustness$gap_lev_df
ie_pre_mspe <- mean(gap_lev_df$gap[gap_lev_df$time_id < treat_start]^2)
ie_post_mspe <- mean(gap_lev_df$gap[gap_lev_df$time_id >= treat_start]^2)
ie_ratio <- ie_post_mspe / ie_pre_mspe

cat(sprintf("Ireland log-level: pre-MSPE=%.4f, post-MSPE=%.4f, ratio=%.2f\n",
            ie_pre_mspe, ie_post_mspe, ie_ratio))

# Run placebos
cat("\n=== Running log-level placebos ===\n")
placebo_ratios_lev <- numeric()
placebo_gaps_lev <- list()

for (i in seq_along(donor_lev)) {
  did <- donor_lev[i]
  geo_name <- geo_ids$geo[geo_ids$geo_id == did]
  cat(sprintf("  Placebo %d/%d: %s...\n", i, length(donor_lev), geo_name))

  remaining <- setdiff(donor_lev, did)

  dp_p <- tryCatch({
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
      treatment.identifier = did,
      controls.identifier = remaining,
      time.optimize.ssr = pre_periods,
      time.plot = sort(unique(scm_lev$time_id))
    )
  }, error = function(e) NULL)

  if (is.null(dp_p)) { cat("    SKIPPED\n"); next }

  synth_p <- tryCatch(synth(dp_p, verbose = FALSE), error = function(e) NULL)
  if (is.null(synth_p)) { cat("    SKIPPED\n"); next }

  pg <- dp_p$Y1plot - (dp_p$Y0plot %*% synth_p$solution.w)
  pre_pg <- pg[as.numeric(rownames(pg)) < treat_start, ]
  post_pg <- pg[as.numeric(rownames(pg)) >= treat_start, ]

  p_pre_mspe <- mean(pre_pg^2)
  p_post_mspe <- mean(post_pg^2)
  p_ratio <- p_post_mspe / p_pre_mspe

  placebo_ratios_lev[[geo_name]] <- p_ratio
  placebo_gaps_lev[[geo_name]] <- data.frame(
    time_id = as.numeric(rownames(pg)),
    gap = as.numeric(pg),
    geo = geo_name
  )
}

cat(sprintf("\nCompleted %d placebos\n", length(placebo_ratios_lev)))

# P-value for log-level
all_ratios <- c(Ireland = ie_ratio, unlist(placebo_ratios_lev))
p_value_lev <- mean(all_ratios >= ie_ratio)
cat(sprintf("Ireland log-level MSPE ratio: %.2f\n", ie_ratio))
cat(sprintf("P-value (log-level): %.3f\n", p_value_lev))
cat(sprintf("Ireland rank: %d / %d\n", sum(all_ratios >= ie_ratio), length(all_ratios)))

# Also compute one-sided p-value for positive average gap
ie_avg_gap <- mean(gap_lev_df$gap[gap_lev_df$time_id >= treat_start])
placebo_avg <- sapply(placebo_gaps_lev, function(pg) {
  mean(pg$gap[pg$time_id >= treat_start])
})
p_value_avg_lev <- mean(c(placebo_avg, ie_avg_gap) >= ie_avg_gap)
cat(sprintf("P-value (avg positive gap, one-sided): %.3f\n", p_value_avg_lev))

# Save
loglevel_inference <- list(
  ie_ratio = ie_ratio,
  ie_pre_mspe = ie_pre_mspe,
  ie_post_mspe = ie_post_mspe,
  placebo_ratios_lev = placebo_ratios_lev,
  placebo_gaps_lev = placebo_gaps_lev,
  p_value_ratio = p_value_lev,
  p_value_avg = p_value_avg_lev,
  ie_avg_gap = ie_avg_gap,
  placebo_avg_gaps = placebo_avg
)

saveRDS(loglevel_inference, "../data/loglevel_inference.rds")

cat("\n=== Log-level permutation inference complete ===\n")
