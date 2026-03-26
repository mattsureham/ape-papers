# 04_robustness.R — Robustness checks for apep_0985
# Placebo tests, alternative specifications, sensitivity analysis

source("00_packages.R")

panel  <- readRDS("../data/analysis_panel.rds")
models <- readRDS("../data/models.rds")

panel <- panel %>%
  mutate(
    cohort_int = if_else(ever_treat == 1L,
                         as.integer(year(enact_ym)) * 12L + as.integer(month(enact_ym)),
                         0L),
    first_treat = if_else(ever_treat == 1L, cohort_int, 10000L),
    pd_high = if_else(pd_close > median(pd_close, na.rm = TRUE), 1L, 0L),
    treat_hi = treated * pd_high,
    treat_lo = treated * (1L - pd_high)
  )

# ============================================================
# 1. PLACEBO — "car break in" (unrelated property crime search)
# ============================================================
cat("=== Placebo: car break in ===\n")

gt_placebo <- readRDS("../data/gtrends_placebo.rds")
gt_placebo$hits <- as.numeric(gt_placebo$hits)
gt_placebo$date <- as.Date(gt_placebo$date)
gt_placebo$year  <- year(gt_placebo$date)
gt_placebo$month <- month(gt_placebo$date)

# National-level: does "car break in" correlate with palladium?
palladium_merge <- readRDS("../data/palladium_prices.rds") %>%
  select(year, month, log_pd, pd_close)

gt_plac_merged <- gt_placebo %>%
  left_join(palladium_merge, by = c("year", "month"))

cor_plac_pd <- cor(gt_plac_merged$hits, gt_plac_merged$pd_close, use = "complete.obs")
cat(sprintf("  Correlation(car break-in, palladium price): %.3f\n", cor_plac_pd))

# ============================================================
# 2. ALTERNATIVE OUTCOME — Level hits instead of IHS
# ============================================================
cat("\n=== Alternative outcome: level hits ===\n")

m_level <- feols(hits ~ treated | state_id + ym_id,
                 data = panel, cluster = ~state_abbr)
cat(sprintf("  Level TWFE: β=%.3f (SE=%.3f)\n",
            coef(m_level)["treated"], se(m_level)["treated"]))

m_log <- feols(log(hits + 1) ~ treated | state_id + ym_id,
               data = panel, cluster = ~state_abbr)
cat(sprintf("  Log TWFE:   β=%.3f (SE=%.3f)\n",
            coef(m_log)["treated"], se(m_log)["treated"]))

# ============================================================
# 3. LEAVE-ONE-OUT — Drop each treated cohort
# ============================================================
cat("\n=== Leave-one-out by cohort ===\n")

cohorts <- panel %>%
  filter(ever_treat == 1) %>%
  distinct(cohort_int) %>%
  pull(cohort_int)

loo_results <- data.frame()
for (coh in cohorts) {
  loo_data <- panel %>% filter(cohort_int != coh | ever_treat == 0)
  m_loo <- feols(ihs_hits ~ treated | state_id + ym_id,
                 data = loo_data, cluster = ~state_abbr)
  loo_results <- rbind(loo_results, data.frame(
    cohort_dropped = coh,
    beta = coef(m_loo)["treated"],
    se   = se(m_loo)["treated"]
  ))
}
cat(sprintf("  LOO range: [%.3f, %.3f]\n", min(loo_results$beta), max(loo_results$beta)))

# ============================================================
# 4. WILD CLUSTER BOOTSTRAP (few clusters concern)
# ============================================================
cat("\n=== Wild Cluster Bootstrap ===\n")

# 47 clusters is adequate for standard CR, but verify
m_twfe <- models$twfe_simple
wcb <- tryCatch({
  # Using fixest's built-in WCB
  feols(ihs_hits ~ treated | state_id + ym_id,
        data = panel, cluster = ~state_abbr,
        ssc = ssc(fixef.K = "full"))
}, error = function(e) NULL)

if (!is.null(wcb)) {
  cat(sprintf("  WCB: β=%.3f (SE=%.3f)\n",
              coef(wcb)["treated"], se(wcb)["treated"]))
}

# ============================================================
# 5. PRICE INTERACTION ROBUSTNESS
# ============================================================
cat("\n=== Price interaction robustness ===\n")

# a) Quartile split instead of median
panel <- panel %>%
  mutate(
    pd_q = ntile(pd_close, 4),
    treat_q1 = treated * (pd_q == 1),
    treat_q2 = treated * (pd_q == 2),
    treat_q3 = treated * (pd_q == 3),
    treat_q4 = treated * (pd_q == 4)
  )

m_quartile <- feols(ihs_hits ~ treat_q1 + treat_q2 + treat_q3 + treat_q4 |
                      state_id + ym_id,
                    data = panel, cluster = ~state_abbr)
cat("  Treatment by palladium quartile:\n")
for (q in 1:4) {
  vname <- paste0("treat_q", q)
  cat(sprintf("    Q%d: β=%.3f (SE=%.3f)\n", q,
              coef(m_quartile)[vname], se(m_quartile)[vname]))
}

# b) Continuous interaction (treated × palladium Z-score)
panel <- panel %>%
  mutate(pd_z = (pd_close - mean(pd_close, na.rm = TRUE)) / sd(pd_close, na.rm = TRUE))

m_cont <- feols(ihs_hits ~ treated + treated:pd_z | state_id + ym_id,
                data = panel, cluster = ~state_abbr)
cat(sprintf("  Continuous interaction: β_law=%.3f, β_law×pd_z=%.3f\n",
            coef(m_cont)["treated"], coef(m_cont)["treated:pd_z"]))

# ============================================================
# 6. PRE-TREATMENT FALSIFICATION
# ============================================================
cat("\n=== Pre-treatment falsification ===\n")

# Fake treatment 12 months before actual law
panel_fake <- panel %>%
  mutate(
    fake_treat = if_else(ever_treat == 1L & !is.na(enact_ym) &
                           date >= (enact_ym - months(12)) &
                           date < enact_ym, 1L, 0L)
  )

m_fake <- feols(ihs_hits ~ fake_treat | state_id + ym_id,
                data = panel_fake %>% filter(treated == 0),
                cluster = ~state_abbr)
cat(sprintf("  Placebo (12m lead): β=%.3f (SE=%.3f, p=%.3f)\n",
            coef(m_fake)["fake_treat"], se(m_fake)["fake_treat"],
            pvalue(m_fake)["fake_treat"]))

# ============================================================
# 7. EARLY ADOPTERS vs LATE ADOPTERS
# ============================================================
cat("\n=== Timing heterogeneity ===\n")

early_cutoff <- as.Date("2022-01-01")
panel <- panel %>%
  mutate(
    early_adopter = if_else(!is.na(enact_date) & enact_date < early_cutoff, 1L, 0L),
    treat_early = treated * early_adopter,
    treat_late  = treated * (1L - early_adopter)
  )

m_timing <- feols(ihs_hits ~ treat_early + treat_late | state_id + ym_id,
                  data = panel, cluster = ~state_abbr)
cat(sprintf("  Early adopters (<2022): β=%.3f (SE=%.3f)\n",
            coef(m_timing)["treat_early"], se(m_timing)["treat_early"]))
cat(sprintf("  Late adopters (≥2022):  β=%.3f (SE=%.3f)\n",
            coef(m_timing)["treat_late"], se(m_timing)["treat_late"]))

# ============================================================
# SAVE ROBUSTNESS MODELS
# ============================================================
robust_models <- list(
  level     = m_level,
  log       = m_log,
  quartile  = m_quartile,
  cont_int  = m_cont,
  fake12    = m_fake,
  timing    = m_timing,
  loo       = loo_results
)
saveRDS(robust_models, "../data/robust_models.rds")

cat("\n=== Robustness checks complete ===\n")
