# 03_main_analysis.R — Synthetic Control Method + Triple-Event Analysis
# APEP Working Paper apep_1290

source("00_packages.R")

panel <- readRDS("../data/panel_scm.rds")
params <- readRDS("../data/params.rds")
geo_ids <- readRDS("../data/geo_ids.rds")
time_ids <- readRDS("../data/time_ids.rds")
sector_panel <- readRDS("../data/sector_panel.rds")

ireland_id <- params$ireland_id
treat_start <- params$treat_start  # time_id for 2016-Q3
donor_ids <- geo_ids$geo_id[geo_ids$geo != "IE"]

cat("=== Main Analysis: Synthetic Control Method ===\n")
cat(sprintf("  Ireland ID: %d, Treatment starts: period %d\n", ireland_id, treat_start))
cat(sprintf("  Donor pool: %d countries\n", length(donor_ids)))

# ---------------------------------------------------------------
# 1. Prepare Synth data
# ---------------------------------------------------------------

# The Synth package requires balanced panel, no missing values
# Use tax_pct_gdp as the main outcome
scm_data <- panel %>%
  filter(!is.na(tax_pct_gdp)) %>%
  select(geo_id, time_id, tax_pct_gdp, log_tax, gdp_meur, yq) %>%
  as.data.frame()

# Check balance
n_periods <- n_distinct(scm_data$time_id)
balance_check <- scm_data %>%
  group_by(geo_id) %>%
  summarise(n = n(), .groups = "drop")

# Keep only units with full panel
full_units <- balance_check$geo_id[balance_check$n == n_periods]
scm_data <- scm_data %>% filter(geo_id %in% full_units)

# Ensure Ireland is still in the sample
stopifnot("Ireland dropped from balanced panel" = ireland_id %in% full_units)

donor_ids_balanced <- setdiff(full_units, ireland_id)
cat(sprintf("  Balanced panel: %d units, %d periods\n",
            length(full_units), n_periods))

# ---------------------------------------------------------------
# 2. Run SCM using Synth package
# ---------------------------------------------------------------

# Compute pre-treatment period averages for predictors
pre_periods <- time_ids$time_id[time_ids$time_id < treat_start]
# Split pre-period into halves for matching
mid_pre <- median(pre_periods)
first_half <- pre_periods[pre_periods <= mid_pre]
second_half <- pre_periods[pre_periods > mid_pre]

# Prepare data for dataprep
cat("  Running dataprep...\n")

dp <- dataprep(
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
  controls.identifier = donor_ids_balanced,
  time.optimize.ssr = pre_periods,
  time.plot = sort(unique(scm_data$time_id))
)

cat("  Running synth optimization...\n")
synth_out <- synth(dp, verbose = FALSE)

# ---------------------------------------------------------------
# 3. Extract results
# ---------------------------------------------------------------

# Weights
weights_df <- data.frame(
  geo_id = donor_ids_balanced,
  weight = as.numeric(synth_out$solution.w)
) %>%
  left_join(geo_ids, by = "geo_id") %>%
  arrange(desc(weight))

cat("\n=== SCM Weights (top 10) ===\n")
print(head(weights_df, 10))

# Gaps (actual - synthetic)
gaps <- dp$Y1plot - (dp$Y0plot %*% synth_out$solution.w)
gap_df <- data.frame(
  time_id = as.numeric(rownames(gaps)),
  gap = as.numeric(gaps)
) %>%
  left_join(time_ids, by = "time_id")

# Pre-treatment MSPE (root)
pre_gaps <- gap_df %>% filter(time_id < treat_start)
pre_mspe <- mean(pre_gaps$gap^2)
pre_rmspe <- sqrt(pre_mspe)

# Post-treatment average gap (by sub-periods)
# Period 1: 2016-Q3 to 2020-Q2 (ruling to annulment)
event2_time <- time_ids$time_id[time_ids$yq == zoo::as.yearqtr("2020 Q3")]
event3_time <- time_ids$time_id[time_ids$yq == zoo::as.yearqtr("2024 Q3")]

gap_period1 <- gap_df %>%
  filter(time_id >= treat_start, time_id < event2_time) %>%
  summarise(mean_gap = mean(gap), sd_gap = sd(gap), n = n())

gap_period2 <- gap_df %>%
  filter(time_id >= event2_time, time_id < event3_time) %>%
  summarise(mean_gap = mean(gap), sd_gap = sd(gap), n = n())

gap_period3 <- gap_df %>%
  filter(time_id >= event3_time) %>%
  summarise(mean_gap = mean(gap), sd_gap = sd(gap), n = n())

cat("\n=== Gap Analysis ===\n")
cat(sprintf("  Pre-treatment RMSPE: %.3f pp\n", pre_rmspe))
cat(sprintf("  Period 1 (Ruling 2016-Q3 to 2020-Q2): mean gap = %.3f pp (SD=%.3f, n=%d)\n",
            gap_period1$mean_gap, gap_period1$sd_gap, gap_period1$n))
cat(sprintf("  Period 2 (Annulment 2020-Q3 to 2024-Q2): mean gap = %.3f pp (SD=%.3f, n=%d)\n",
            gap_period2$mean_gap, gap_period2$sd_gap, gap_period2$n))
cat(sprintf("  Period 3 (Reinstatement 2024-Q3+): mean gap = %.3f pp (SD=%.3f, n=%d)\n",
            gap_period3$mean_gap, gap_period3$sd_gap, gap_period3$n))

# ---------------------------------------------------------------
# 4. Permutation Inference (in-space placebos)
# ---------------------------------------------------------------

cat("\n=== Running Permutation Inference ===\n")

placebo_gaps <- list()
placebo_mspe <- numeric()

for (i in seq_along(donor_ids_balanced)) {
  did <- donor_ids_balanced[i]
  geo_name <- geo_ids$geo[geo_ids$geo_id == did]
  cat(sprintf("  Placebo %d/%d: %s (id=%d)...\n", i, length(donor_ids_balanced), geo_name, did))

  remaining_donors <- setdiff(donor_ids_balanced, did)

  dp_placebo <- tryCatch({
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
      treatment.identifier = did,
      controls.identifier = remaining_donors,
      time.optimize.ssr = pre_periods,
      time.plot = sort(unique(scm_data$time_id))
    )
  }, error = function(e) NULL)

  if (is.null(dp_placebo)) {
    cat("    SKIPPED (dataprep error)\n")
    next
  }

  synth_placebo <- tryCatch(
    synth(dp_placebo, verbose = FALSE),
    error = function(e) NULL
  )

  if (is.null(synth_placebo)) {
    cat("    SKIPPED (synth error)\n")
    next
  }

  pg <- dp_placebo$Y1plot - (dp_placebo$Y0plot %*% synth_placebo$solution.w)
  pre_pg <- pg[as.numeric(rownames(pg)) < treat_start, ]
  p_mspe <- mean(pre_pg^2)

  placebo_gaps[[geo_name]] <- data.frame(
    time_id = as.numeric(rownames(pg)),
    gap = as.numeric(pg),
    geo = geo_name
  )
  placebo_mspe[[geo_name]] <- p_mspe
}

cat(sprintf("  Completed %d/%d placebos\n", length(placebo_gaps), length(donor_ids_balanced)))

# ---------------------------------------------------------------
# 5. Compute p-values
# ---------------------------------------------------------------

# Post/pre MSPE ratio
post_periods_all <- gap_df$time_id[gap_df$time_id >= treat_start]
post_mspe_ireland <- mean(gap_df$gap[gap_df$time_id >= treat_start]^2)
mspe_ratio_ireland <- post_mspe_ireland / pre_mspe

placebo_ratios <- sapply(names(placebo_gaps), function(g) {
  pg <- placebo_gaps[[g]]
  pre_pg <- pg$gap[pg$time_id < treat_start]
  post_pg <- pg$gap[pg$time_id >= treat_start]
  mean(post_pg^2) / mean(pre_pg^2)
})

# p-value: fraction of placebos with ratio >= Ireland's
p_value_ratio <- mean(c(placebo_ratios, mspe_ratio_ireland) >= mspe_ratio_ireland)

cat(sprintf("\n=== Permutation Inference ===\n"))
cat(sprintf("  Ireland post/pre MSPE ratio: %.2f\n", mspe_ratio_ireland))
cat(sprintf("  Placebo ratios: median=%.2f, max=%.2f\n",
            median(placebo_ratios), max(placebo_ratios)))
cat(sprintf("  P-value (MSPE ratio): %.3f\n", p_value_ratio))

# Also compute p-value for average post-treatment gap
avg_gap_ireland <- mean(gap_df$gap[gap_df$time_id >= treat_start])
avg_gap_placebos <- sapply(placebo_gaps, function(pg) {
  mean(pg$gap[pg$time_id >= treat_start])
})
p_value_avg <- mean(c(avg_gap_placebos, avg_gap_ireland) >= avg_gap_ireland)
cat(sprintf("  P-value (avg gap): %.3f\n", p_value_avg))

# ---------------------------------------------------------------
# 6. DiD with event study (parametric complement)
# ---------------------------------------------------------------

cat("\n=== Parametric DiD Event Study ===\n")

panel_did <- readRDS("../data/panel_clean.rds")

# Create event-time bins (4-quarter bins relative to 2016-Q3)
panel_did <- panel_did %>%
  mutate(
    yq = zoo::as.yearqtr(time),
    event_q = as.numeric((yq - zoo::as.yearqtr("2016 Q3")) * 4),
    event_bin = case_when(
      event_q < -8 ~ "pre_far",
      event_q >= -8 & event_q < -4 ~ "pre_mid",
      event_q >= -4 & event_q < 0 ~ "pre_near",  # reference
      event_q >= 0 & event_q < 16 ~ "post_ruling",
      event_q >= 16 & event_q < 32 ~ "post_annulment",
      event_q >= 32 ~ "post_reinstatement"
    ),
    event_bin = factor(event_bin, levels = c("pre_near", "pre_far", "pre_mid",
                                               "post_ruling", "post_annulment",
                                               "post_reinstatement"))
  )

# TWFE DiD with Ireland indicator × event bins
did_model <- fixest::feols(
  tax_pct_gdp ~ i(event_bin, treated, ref = "pre_near") | geo + yq,
  data = panel_did,
  cluster = ~geo
)

cat("\nDiD Event Study (TWFE):\n")
print(summary(did_model))

# ---------------------------------------------------------------
# 7. Sector DiD (mechanism)
# ---------------------------------------------------------------

cat("\n=== Sector DiD: Info & Comms vs Manufacturing ===\n")

sector_did <- sector_panel %>%
  filter(nace_r2 %in% c("J", "C")) %>%
  mutate(
    apple_sector = as.integer(nace_r2 == "J"),
    log_va = log(values + 1)
  )

if (nrow(sector_did) > 0 && n_distinct(sector_did$yq) > 10) {
  sector_model <- fixest::feols(
    log_va ~ apple_sector:post1 | nace_r2 + yq,
    data = sector_did,
    cluster = ~nace_r2
  )
  cat("Sector DiD results:\n")
  print(summary(sector_model))
} else {
  cat("  Insufficient sector data for DiD\n")
  sector_model <- NULL
}

# ---------------------------------------------------------------
# 8. Save results
# ---------------------------------------------------------------

results <- list(
  synth_out = synth_out,
  dp = dp,
  gap_df = gap_df,
  weights_df = weights_df,
  pre_rmspe = pre_rmspe,
  pre_mspe = pre_mspe,
  gap_period1 = gap_period1,
  gap_period2 = gap_period2,
  gap_period3 = gap_period3,
  mspe_ratio_ireland = mspe_ratio_ireland,
  p_value_ratio = p_value_ratio,
  p_value_avg = p_value_avg,
  placebo_gaps = placebo_gaps,
  placebo_ratios = placebo_ratios,
  did_model = did_model,
  sector_model = sector_model
)

saveRDS(results, "../data/results.rds")

# Write diagnostics.json for validator
diagnostics <- list(
  n_treated = as.integer(length(full_units)),  # SCM: total units (treated + donors)
  method = "SCM",
  n_pre = as.integer(treat_start - 1),
  n_obs = nrow(scm_data),
  n_donors = length(donor_ids_balanced),
  n_placebos = length(placebo_gaps),
  pre_rmspe = pre_rmspe,
  p_value_ratio = p_value_ratio,
  p_value_avg = p_value_avg,
  gap_period1_mean = gap_period1$mean_gap,
  gap_period2_mean = gap_period2$mean_gap,
  gap_period3_mean = gap_period3$mean_gap
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)

cat("\n=== Analysis complete. Results saved. ===\n")
