# ==============================================================================
# 04_robustness.R — Robustness checks
# Paper: Frictionless Highways (apep_0798)
# ==============================================================================

source("code/00_packages.R")

data_dir <- "data"
mob <- fread(file.path(data_dir, "mobility_weekly_panel.csv"))
mob[, district_id := as.factor(sub_region_2)]
mob[, state_id := as.factor(sub_region_1)]
mob[, week_id := as.factor(year_week)]

cat("=== ROBUSTNESS CHECKS ===\n")

# ── 1. Placebo Treatment Date ────────────────────────────────────────────────
cat("\n--- Placebo: Treatment at Oct 2020 (4 months before actual) ---\n")

mob[, post_placebo := as.integer(year * 100 + month >= 202010)]

did_placebo <- feols(
  transit ~ has_plaza:post_placebo | district_id + state_id^week_id,
  data = mob[year * 100 + month <= 202102],  # Restrict to pre-mandate data only
  cluster = ~state_id
)
cat("Placebo Oct 2020:\n")
print(summary(did_placebo))

# ── 2. Placebo Treatment: Aug 2020 ──────────────────────────────────────────
cat("\n--- Placebo: Treatment at Aug 2020 ---\n")

mob[, post_placebo2 := as.integer(year * 100 + month >= 202008)]

did_placebo2 <- feols(
  transit ~ has_plaza:post_placebo2 | district_id + state_id^week_id,
  data = mob[year * 100 + month <= 202102],
  cluster = ~state_id
)
cat("Placebo Aug 2020:\n")
print(summary(did_placebo2))

# ── 3. Restrict to Highway-Adjacent Districts ────────────────────────────────
cat("\n--- Restrict to States with At Least 1 Plaza ---\n")

# Only compare within states that have toll plazas
states_with_plazas <- mob[has_plaza == 1, unique(sub_region_1)]
mob_highway <- mob[sub_region_1 %in% states_with_plazas]

did_highway <- feols(
  transit ~ has_plaza:post_mandate | district_id + state_id^week_id,
  data = mob_highway,
  cluster = ~state_id
)
cat(sprintf("Highway states only (%d states, %d districts):\n",
            length(states_with_plazas), uniqueN(mob_highway$sub_region_2)))
print(summary(did_highway))

# ── 4. Drop COVID Wave Periods ───────────────────────────────────────────────
cat("\n--- Drop Delta Wave (Apr-Jun 2021) ---\n")

mob[, delta_wave := as.integer(year == 2021 & month %in% 4:6)]

did_no_delta <- feols(
  transit ~ has_plaza:post_mandate | district_id + state_id^week_id,
  data = mob[delta_wave == 0],
  cluster = ~state_id
)
cat("Excluding Delta wave:\n")
print(summary(did_no_delta))

# ── 5. State-Level Clustering vs District-Level ─────────────────────────────
cat("\n--- Alternative Clustering ---\n")

did_dist_cluster <- feols(
  transit ~ has_plaza:post_mandate | district_id + state_id^week_id,
  data = mob,
  cluster = ~district_id
)
cat("District-level clustering:\n")
print(summary(did_dist_cluster))

# ── 6. Balanced Panel Only ──────────────────────────────────────────────────
cat("\n--- Balanced Panel ---\n")

# Keep only districts present in every week
week_counts <- mob[!is.na(transit), .N, by = sub_region_2]
max_weeks <- max(week_counts$N)
balanced_dist <- week_counts[N >= max_weeks * 0.9, sub_region_2]

did_balanced <- feols(
  transit ~ has_plaza:post_mandate | district_id + state_id^week_id,
  data = mob[sub_region_2 %in% balanced_dist],
  cluster = ~state_id
)
cat(sprintf("Balanced panel (%d districts with 90%%+ coverage):\n",
            length(balanced_dist)))
print(summary(did_balanced))

# ── 7. Log Number of Plazas (Intensive Margin) ──────────────────────────────
cat("\n--- Log Plazas Treatment ---\n")

mob[, log_plazas := log(n_plazas + 1)]

did_log <- feols(
  transit ~ log_plazas:post_mandate | district_id + state_id^week_id,
  data = mob,
  cluster = ~state_id
)
cat("Log(1 + plazas) treatment:\n")
print(summary(did_log))

# ── 8. Alternative Pre-Period Window ─────────────────────────────────────────
cat("\n--- Short Pre-Period (Oct 2020 - Oct 2022) ---\n")

did_short <- feols(
  transit ~ has_plaza:post_mandate | district_id + state_id^week_id,
  data = mob[year * 100 + month >= 202010],
  cluster = ~state_id
)
cat("Short window:\n")
print(summary(did_short))

# ── 9. Save Robustness Results ───────────────────────────────────────────────
rob_results <- list(
  placebo_oct = did_placebo,
  placebo_aug = did_placebo2,
  highway_only = did_highway,
  no_delta = did_no_delta,
  dist_cluster = did_dist_cluster,
  balanced = did_balanced,
  log_plazas = did_log,
  short_window = did_short
)
saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))

# ── 10. Summary Table ────────────────────────────────────────────────────────
cat("\n=== ROBUSTNESS SUMMARY ===\n")

specs <- list(
  "Main (state×week FE)" = c(-1.696, 0.967),
  "Placebo Oct 2020" = c(coef(did_placebo)[1], se(did_placebo)[1]),
  "Placebo Aug 2020" = c(coef(did_placebo2)[1], se(did_placebo2)[1]),
  "Highway states only" = c(coef(did_highway)[1], se(did_highway)[1]),
  "Drop Delta wave" = c(coef(did_no_delta)[1], se(did_no_delta)[1]),
  "District clustering" = c(coef(did_dist_cluster)[1], se(did_dist_cluster)[1]),
  "Balanced panel" = c(coef(did_balanced)[1], se(did_balanced)[1]),
  "Log(1+plazas)" = c(coef(did_log)[1], se(did_log)[1]),
  "Short pre-period" = c(coef(did_short)[1], se(did_short)[1])
)

for (nm in names(specs)) {
  cat(sprintf("%-25s  β=%.3f  SE=%.3f  p=%.3f\n",
              nm, specs[[nm]][1], specs[[nm]][2],
              2 * pnorm(-abs(specs[[nm]][1] / specs[[nm]][2]))))
}

cat("\nRobustness checks complete.\n")
