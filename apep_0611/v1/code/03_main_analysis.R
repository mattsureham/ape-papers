## 03_main_analysis.R — Main RDD and diff-in-disc estimation
## APEP paper apep_0611: CRA Lookback Cutoff and Midnight Rulemaking

source("00_packages.R")
library(rdrobust)
library(fixest)
library(dplyr)

df <- readRDS("../data/rules_analysis.rds")
df_weekly <- readRDS("../data/rules_weekly.rds")
transitions <- readRDS("../data/transitions.rds")

cat(sprintf("Analysis dataset: %d individual rules, %d weekly obs\n",
            nrow(df), nrow(df_weekly)))

# ═══════════════════════════════════════════════════════════════════════
# 1. DENSITY DISCONTINUITY TEST (McCrary/rddensity)
# ═══════════════════════════════════════════════════════════════════════
# Test whether rule publication density is discontinuous at the
# CRA lookback cutoff — evidence of strategic timing.

cat("\n═══ DENSITY DISCONTINUITY TESTS ═══\n")

# (a) All transitions pooled
density_all <- rddensity(X = df$days_from_cutoff, c = 0)
cat(sprintf("All transitions: T-stat = %.3f, p = %.4f\n",
            density_all$test$t_jk, density_all$test$p_jk))

# (b) Cross-party transitions only
density_cross <- rddensity(
  X = df$days_from_cutoff[df$cross_party],
  c = 0
)
cat(sprintf("Cross-party: T-stat = %.3f, p = %.4f\n",
            density_cross$test$t_jk, density_cross$test$p_jk))

# (c) Same-party transitions only
density_same <- rddensity(
  X = df$days_from_cutoff[!df$cross_party],
  c = 0
)
cat(sprintf("Same-party: T-stat = %.3f, p = %.4f\n",
            density_same$test$t_jk, density_same$test$p_jk))

# (d) By individual transition year
density_by_year <- list()
for (yr in sort(unique(df$transition_year))) {
  sub <- df %>% filter(transition_year == yr)
  if (nrow(sub) > 50) {
    dens <- rddensity(X = sub$days_from_cutoff, c = 0)
    density_by_year[[as.character(yr)]] <- tibble(
      transition_year = yr,
      cross_party = unique(sub$cross_party),
      n = nrow(sub),
      t_stat = dens$test$t_jk,
      p_value = dens$test$p_jk,
      n_left = dens$N$eff_left,
      n_right = dens$N$eff_right
    )
    cat(sprintf("  %d (%s): T=%.3f, p=%.4f, N_left=%d, N_right=%d\n",
                yr,
                ifelse(unique(sub$cross_party), "cross", "same"),
                dens$test$t_jk, dens$test$p_jk,
                dens$N$eff_left, dens$N$eff_right))
  }
}
density_results <- bind_rows(density_by_year)
saveRDS(density_results, "../data/density_results.rds")

# ═══════════════════════════════════════════════════════════════════════
# 2. RDD ON RULE CHARACTERISTICS AT THE CUTOFF
# ═══════════════════════════════════════════════════════════════════════
# Test whether rule quality/type changes discontinuously at the cutoff.
# Outcomes: significant flag, page_length, n_cfr_parts

cat("\n═══ RULE CHARACTERISTICS RDD ═══\n")

# Restrict to MSE-optimal bandwidth window
# Run rdrobust for each outcome

# (a) Significant rule indicator — cross-party transitions
rdd_sig_cross <- tryCatch({
  rdrobust(
    y = as.numeric(df$significant[df$cross_party]),
    x = df$days_from_cutoff[df$cross_party],
    c = 0,
    kernel = "triangular",
    bwselect = "mserd"
  )
}, error = function(e) {
  cat(sprintf("  rdrobust significant (cross): %s\n", e$message))
  NULL
})

if (!is.null(rdd_sig_cross)) {
  cat(sprintf("Significant (cross-party): coef=%.4f, p=%.4f, bw=%.0f days, N_eff=%d/%d\n",
              rdd_sig_cross$coef[1], rdd_sig_cross$pv[3],
              rdd_sig_cross$bws[1, 1],
              rdd_sig_cross$N_h[1], rdd_sig_cross$N_h[2]))
}

# (b) Significant rule indicator — same-party transitions
rdd_sig_same <- tryCatch({
  rdrobust(
    y = as.numeric(df$significant[!df$cross_party]),
    x = df$days_from_cutoff[!df$cross_party],
    c = 0,
    kernel = "triangular",
    bwselect = "mserd"
  )
}, error = function(e) {
  cat(sprintf("  rdrobust significant (same): %s\n", e$message))
  NULL
})

if (!is.null(rdd_sig_same)) {
  cat(sprintf("Significant (same-party): coef=%.4f, p=%.4f, bw=%.0f days, N_eff=%d/%d\n",
              rdd_sig_same$coef[1], rdd_sig_same$pv[3],
              rdd_sig_same$bws[1, 1],
              rdd_sig_same$N_h[1], rdd_sig_same$N_h[2]))
}

# (c) Page length — cross-party
rdd_pages_cross <- tryCatch({
  sub <- df %>% filter(cross_party, !is.na(page_length), page_length > 0)
  rdrobust(
    y = sub$page_length,
    x = sub$days_from_cutoff,
    c = 0,
    kernel = "triangular",
    bwselect = "mserd"
  )
}, error = function(e) {
  cat(sprintf("  rdrobust pages (cross): %s\n", e$message))
  NULL
})

if (!is.null(rdd_pages_cross)) {
  cat(sprintf("Page length (cross-party): coef=%.2f, p=%.4f, bw=%.0f days\n",
              rdd_pages_cross$coef[1], rdd_pages_cross$pv[3],
              rdd_pages_cross$bws[1, 1]))
}

# (d) Page length — same-party
rdd_pages_same <- tryCatch({
  sub <- df %>% filter(!cross_party, !is.na(page_length), page_length > 0)
  rdrobust(
    y = sub$page_length,
    x = sub$days_from_cutoff,
    c = 0,
    kernel = "triangular",
    bwselect = "mserd"
  )
}, error = function(e) {
  cat(sprintf("  rdrobust pages (same): %s\n", e$message))
  NULL
})

if (!is.null(rdd_pages_same)) {
  cat(sprintf("Page length (same-party): coef=%.2f, p=%.4f, bw=%.0f days\n",
              rdd_pages_same$coef[1], rdd_pages_same$pv[3],
              rdd_pages_same$bws[1, 1]))
}

# ═══════════════════════════════════════════════════════════════════════
# 3. DIFFERENCE-IN-DISCONTINUITIES (parametric)
# ═══════════════════════════════════════════════════════════════════════
# Estimate the diff-in-disc: compare the RDD effect at the cutoff
# in cross-party vs same-party transitions.
#
# Y_i = α + β₁ CRA_vulnerable + β₂ CrossParty + β₃ (CRA × Cross)
#       + f(days) + f(days) × CrossParty + ε
#
# β₃ = diff-in-discontinuities estimand

cat("\n═══ DIFFERENCE-IN-DISCONTINUITIES ═══\n")

# Use optimal bandwidth from cross-party RDD for the parametric model
bw_opt <- if (!is.null(rdd_sig_cross)) rdd_sig_cross$bws[1, 1] else 120

# Filter to bandwidth
df_bw <- df %>% filter(abs(days_from_cutoff) <= bw_opt)

cat(sprintf("Bandwidth: ±%.0f days, N = %d\n", bw_opt, nrow(df_bw)))

# (a) Significant rules
did_sig <- feols(
  significant ~ cra_vulnerable * cross_party +
    days_from_cutoff + I(days_from_cutoff * cra_vulnerable) +
    days_from_cutoff:cross_party + I(days_from_cutoff * cra_vulnerable):cross_party,
  data = df_bw,
  vcov = "HC1"
)
cat("\nDiff-in-disc: Significant rules\n")
print(summary(did_sig))

# (b) Page length (proxy for rule complexity)
df_bw_pages <- df_bw %>% filter(!is.na(page_length), page_length > 0)
did_pages <- feols(
  page_length ~ cra_vulnerable * cross_party +
    days_from_cutoff + I(days_from_cutoff * cra_vulnerable) +
    days_from_cutoff:cross_party + I(days_from_cutoff * cra_vulnerable):cross_party,
  data = df_bw_pages,
  vcov = "HC1"
)
cat("\nDiff-in-disc: Page length\n")
print(summary(did_pages))

# (c) CFR parts (scope of rule)
did_cfr <- feols(
  n_cfr_parts ~ cra_vulnerable * cross_party +
    days_from_cutoff + I(days_from_cutoff * cra_vulnerable) +
    days_from_cutoff:cross_party + I(days_from_cutoff * cra_vulnerable):cross_party,
  data = df_bw,
  vcov = "HC1"
)
cat("\nDiff-in-disc: CFR parts\n")
print(summary(did_cfr))

# ═══════════════════════════════════════════════════════════════════════
# 4. WEEKLY RULE VOLUME RDD
# ═══════════════════════════════════════════════════════════════════════
# Test whether weekly rule count jumps at the cutoff

cat("\n═══ WEEKLY VOLUME RDD ═══\n")

# Cross-party weekly volume
wk_cross <- df_weekly %>% filter(cross_party)
rdd_vol_cross <- tryCatch({
  rdrobust(
    y = wk_cross$n_rules,
    x = wk_cross$mid_day,
    c = 0,
    kernel = "triangular",
    bwselect = "mserd"
  )
}, error = function(e) {
  cat(sprintf("  rdrobust volume (cross): %s\n", e$message))
  NULL
})

if (!is.null(rdd_vol_cross)) {
  cat(sprintf("Weekly volume (cross-party): coef=%.2f, p=%.4f, bw=%.0f days\n",
              rdd_vol_cross$coef[1], rdd_vol_cross$pv[3],
              rdd_vol_cross$bws[1, 1]))
}

# Same-party weekly volume
wk_same <- df_weekly %>% filter(!cross_party)
rdd_vol_same <- tryCatch({
  rdrobust(
    y = wk_same$n_rules,
    x = wk_same$mid_day,
    c = 0,
    kernel = "triangular",
    bwselect = "mserd"
  )
}, error = function(e) {
  cat(sprintf("  rdrobust volume (same): %s\n", e$message))
  NULL
})

if (!is.null(rdd_vol_same)) {
  cat(sprintf("Weekly volume (same-party): coef=%.2f, p=%.4f, bw=%.0f days\n",
              rdd_vol_same$coef[1], rdd_vol_same$pv[3],
              rdd_vol_same$bws[1, 1]))
}

# ═══════════════════════════════════════════════════════════════════════
# 5. SAVE ALL RESULTS
# ═══════════════════════════════════════════════════════════════════════

results <- list(
  density_all = density_all,
  density_cross = density_cross,
  density_same = density_same,
  density_by_year = density_results,
  rdd_sig_cross = rdd_sig_cross,
  rdd_sig_same = rdd_sig_same,
  rdd_pages_cross = rdd_pages_cross,
  rdd_pages_same = rdd_pages_same,
  did_sig = did_sig,
  did_pages = did_pages,
  did_cfr = did_cfr,
  rdd_vol_cross = rdd_vol_cross,
  rdd_vol_same = rdd_vol_same,
  bw_opt = bw_opt
)

saveRDS(results, "../data/main_results.rds")

# ── Diagnostics for validator ────────────────────────────────────────
n_cross <- sum(df$cross_party)
n_same <- sum(!df$cross_party)

diagnostics <- list(
  n_treated = n_cross,
  n_pre = n_same,
  n_obs = nrow(df),
  n_transitions = nrow(transitions),
  n_cross_party = sum(transitions$cross_party),
  n_same_party = sum(!transitions$cross_party),
  bw_optimal = bw_opt
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\n03_main_analysis.R completed successfully.\n")
cat(sprintf("Results saved. Key: bw_opt=%.0f, N_bw=%d\n", bw_opt, nrow(df_bw)))
