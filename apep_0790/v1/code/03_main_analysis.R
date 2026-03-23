# 03_main_analysis.R — Callaway-Sant'Anna DiD for fireworks legalization
# Main outcome: July 4th excess PM2.5

source("00_packages.R")

data_dir <- "../data"

# ── Load data ──
july4 <- fread(file.path(data_dir, "july4_monitor_year.csv"))
state_year <- fread(file.path(data_dir, "july4_state_year.csv"))

cat("── Main Analysis: Fireworks Legalization and July 4th Air Quality ──\n\n")

# ── Summary statistics ──
cat("── Summary Statistics ──\n")
cat(sprintf("Monitor-year obs: %s\n", format(nrow(july4), big.mark = ",")))
cat(sprintf("State-year obs: %d\n", nrow(state_year)))
cat(sprintf("Treated states: %d\n", uniqueN(state_year[treat_year > 0]$state_code)))
cat(sprintf("Control states: %d\n", uniqueN(state_year[treat_year == 0]$state_code)))
cat(sprintf("Years: %d-%d\n", min(state_year$year), max(state_year$year)))

cat(sprintf("\nExcess PM2.5 (all state-years):\n"))
cat(sprintf("  Mean: %.3f µg/m³\n", mean(state_year$excess_pm25)))
cat(sprintf("  SD: %.3f µg/m³\n", sd(state_year$excess_pm25)))
cat(sprintf("  Median: %.3f µg/m³\n", median(state_year$excess_pm25)))

# ── Prepare panel for CS estimator ──
cat("\n── Preparing panel for CS ──\n")

# Create numeric state ID
state_year[, state_id := as.integer(as.factor(state_code))]

# Balance the panel: keep only states present in all 21 years
state_counts <- state_year[, .N, by = state_code]
balanced_states <- state_counts[N == 21]$state_code
cat(sprintf("States in all 21 years: %d of %d\n",
            length(balanced_states), uniqueN(state_year$state_code)))

sy_bal <- state_year[state_code %in% balanced_states]
sy_bal[, state_id := as.integer(as.factor(state_code))]

cat(sprintf("Balanced panel: %d obs (%d states × %d years)\n",
            nrow(sy_bal), uniqueN(sy_bal$state_code), uniqueN(sy_bal$year)))

# Verify treat_year coding: 0 = never-treated
cat(sprintf("Treated in balanced panel: %d states\n",
            uniqueN(sy_bal[treat_year > 0]$state_code)))
cat(sprintf("Never-treated in balanced panel: %d states\n",
            uniqueN(sy_bal[treat_year == 0]$state_code)))

# ── Callaway-Sant'Anna at state-year level ──
cat("\n── Callaway-Sant'Anna DiD ──\n")

cs_out <- att_gt(
  yname = "excess_pm25",
  tname = "year",
  idname = "state_id",
  gname = "treat_year",
  data = as.data.frame(sy_bal),
  control_group = "notyettreated",
  anticipation = 0,
  est_method = "dr",
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)

cat("\nGroup-Time ATTs:\n")
summary(cs_out)

# ── Aggregate: overall ATT ──
agg_overall <- aggte(cs_out, type = "simple")
cat("\n── Overall ATT ──\n")
summary(agg_overall)

# ── Aggregate: dynamic / event study ──
agg_dynamic <- aggte(cs_out, type = "dynamic", min_e = -5, max_e = 8)
cat("\n── Dynamic ATT (Event Study) ──\n")
summary(agg_dynamic)

# ── Aggregate: by group (cohort) ──
agg_group <- aggte(cs_out, type = "group")
cat("\n── Group-specific ATTs ──\n")
summary(agg_group)

# ── TWFE comparison (for reference) ──
cat("\n── TWFE Comparison ──\n")
sy_bal[, post := as.integer(year >= treat_year & treat_year > 0)]

twfe <- feols(excess_pm25 ~ post | state_id + year, data = sy_bal,
              cluster = ~state_code)
cat("TWFE estimate:\n")
print(summary(twfe))

# ── Full legalization only (drop sparklers-only states NY, NJ) ──
cat("\n── Full Legalization Only (excluding sparklers-only states) ──\n")
sy_full <- sy_bal[type != "sparklers"]
sy_full[, state_id := as.integer(as.factor(state_code))]

cs_full <- att_gt(
  yname = "excess_pm25",
  tname = "year",
  idname = "state_id",
  gname = "treat_year",
  data = as.data.frame(sy_full),
  control_group = "notyettreated",
  anticipation = 0,
  est_method = "dr",
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)

agg_full <- aggte(cs_full, type = "simple")
cat("Full legalization ATT:\n")
summary(agg_full)

# ── Save results ──
results <- list(
  cs_out = cs_out,
  agg_overall = agg_overall,
  agg_dynamic = agg_dynamic,
  agg_group = agg_group,
  twfe = twfe,
  cs_full = cs_full,
  agg_full = agg_full
)

saveRDS(results, file.path(data_dir, "main_results.rds"))

# ── Diagnostics for validator ──
diagnostics <- list(
  n_treated = uniqueN(sy_bal[treat_year > 0]$state_code),
  n_pre = as.integer(median(sy_bal[treat_year > 0, .(n_pre = treat_year - min(sy_bal$year)),
                                   by = state_code]$n_pre)),
  n_obs = nrow(sy_bal),
  n_monitors = uniqueN(july4$monitor_id),
  n_states = uniqueN(sy_bal$state_code),
  overall_att = agg_overall$overall.att,
  overall_se = agg_overall$overall.se,
  sd_y = sd(sy_bal$excess_pm25)
)
jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat(sprintf("\nDiagnostics saved: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diagnostics$n_treated, diagnostics$n_pre, diagnostics$n_obs))

# Save ATT value for paper.tex
dir.create("../tables", showWarnings = FALSE)
writeLines(sprintf("%.2f", agg_overall$overall.att),
           file.path("../tables", "att_value.tex"))
cat(sprintf("ATT value (%.2f) saved to tables/att_value.tex\n", agg_overall$overall.att))

cat("\n=== Main analysis complete ===\n")
