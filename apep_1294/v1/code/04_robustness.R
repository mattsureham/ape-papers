## ── 04_robustness.R ────────────────────────────────────────────────
## Robustness checks for apep_1294
## ────────────────────────────────────────────────────────────────────
source("code/00_packages.R")

data_dir <- "data"
nl_panel <- fread(file.path(data_dir, "analysis_panel.csv"))
## Forest panel needs ST merge — load results from main analysis
results <- readRDS(file.path(data_dir, "main_results.rds"))

## ── 1. SC Placebo (main robustness check) ──────────────────────────
## If results are driven by general delimitation effects (not ST-specific),
## SC-switched constituencies should show similar effects. They should NOT.

cat("=== SC PLACEBO TEST ===\n")

## SC-only treatment (no ST)
sc_q75 <- quantile(nl_panel$sc_share, 0.75, na.rm = TRUE)
nl_panel[, high_sc := as.integer(sc_share >= sc_q75)]
nl_panel[, treat_high_sc := high_sc * post2008]

m_sc1 <- feols(log_nl ~ treat_high_sc | dist_id + year, data = nl_panel,
               cluster = ~dist_id)

## Horse race: ST vs SC
m_sc2 <- feols(log_nl ~ treat_st + treat_sc | dist_id + year, data = nl_panel,
               cluster = ~dist_id)

cat("SC-only treatment:\n")
print(summary(m_sc1))
cat("\nST vs SC horse race:\n")
print(summary(m_sc2))

## ── 2. Exclude extreme ST districts ────────────────────────────────
## Drop districts with ST share > 90% (nearly all ST — may have different dynamics)
nl_trim <- nl_panel[st_share <= 0.90]
m_trim <- feols(log_nl ~ treat_st | dist_id + year, data = nl_trim,
                cluster = ~dist_id)
cat("\n=== TRIMMED SAMPLE (ST < 90%) ===\n")
print(summary(m_trim))

## ── 3. Alternative clustering ─��────────────────────────────────────
## State-level clustering (more conservative)
nl_panel[, state_id := substr(dist_id, 1, regexpr("_", dist_id) - 1)]
m_state_cl <- feols(log_nl ~ treat_st | dist_id + year, data = nl_panel,
                    cluster = ~state_id)
cat("\n=== STATE-LEVEL CLUSTERING ===\n")
print(summary(m_state_cl))

## ── 4. Placebo treatment year (2004 instead of 2008) ───────────────
nl_panel[, post2004 := as.integer(year >= 2004)]
nl_panel[, treat_st_placebo := st_share * post2004]

## Use only pre-2008 data for placebo test
nl_pre <- nl_panel[year < 2008]
m_placebo_year <- feols(log_nl ~ treat_st_placebo | dist_id + year,
                        data = nl_pre, cluster = ~dist_id)
cat("\n=== PLACEBO YEAR (2004) ===\n")
print(summary(m_placebo_year))

## ── 5. Alternative outcome: mean nightlights ──────────────────────
m_mean_nl <- feols(log_mean_nl ~ treat_st | dist_id + year, data = nl_panel,
                   cluster = ~dist_id)
cat("\n=== MEAN NIGHTLIGHTS (instead of total) ===\n")
print(summary(m_mean_nl))

## ── 6. Trend-break robustness ──────────────────────────────────────
## Key specification: does ST × post-trend survive alternative controls?
nl_panel[, time_trend := year - 1994]
nl_panel[, post_trend := pmax(0, year - 2008)]

## Add state-specific trends
nl_panel[, state_id := substr(dist_id, 1, regexpr("_", dist_id) - 1)]
m_state_trend <- feols(log_nl ~ st_share:time_trend + st_share:post_trend |
                         dist_id + year + state_id[time_trend],
                       data = nl_panel, cluster = ~dist_id)
cat("\n=== TREND-BREAK WITH STATE TRENDS ===\n")
print(summary(m_state_trend))

## ── 7. Save robustness results ────────────────────────────────────
rob_results <- list(
  sc_only = m_sc1,
  sc_horse_race = m_sc2,
  trimmed = m_trim,
  state_cluster = m_state_cl,
  placebo_year = m_placebo_year,
  mean_nl = m_mean_nl
)
if (exists("m_state_trend")) {
  rob_results$state_trend <- m_state_trend
}

saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))
cat("\nRobustness results saved.\n")
