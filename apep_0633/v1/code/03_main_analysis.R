## 03_main_analysis.R — Callaway-Sant'Anna DiD estimation
## apep_0633: Marijuana tax earmarking and education spending fungibility

source("00_packages.R")

data_dir <- "../data/"
panel <- read_csv(file.path(data_dir, "analysis_panel.csv"), show_col_types = FALSE)

cat("Panel loaded:", nrow(panel), "observations\n")
cat("Treatment year distribution:\n")
print(table(panel$treatment_year[!duplicated(paste(panel$state_abbr, panel$treatment_year))]))

## ──────────────────────────────────────────────────
## 1. Callaway-Sant'Anna: Total expenditure per pupil
## ──────────────────────────────────────────────────

# Convert state to numeric id for did package
panel <- panel %>%
  mutate(state_id = as.numeric(factor(state_abbr)))

cat("\n=== CS-DiD: Total Expenditure Per Pupil ===\n")

cs_exp <- att_gt(
  yname = "exp_pp",
  tname = "year",
  idname = "state_id",
  gname = "treatment_year",
  data = panel %>% filter(!is.na(exp_pp)),
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",  # doubly robust
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000,
  pl = FALSE
)

cat("\nGroup-time ATTs (Total Expenditure PP):\n")
summary(cs_exp)

# Aggregate to overall ATT
agg_exp <- aggte(cs_exp, type = "simple")
cat("\nOverall ATT (Total Expenditure PP):\n")
summary(agg_exp)

# Dynamic event-study aggregation
es_exp <- aggte(cs_exp, type = "dynamic", min_e = -6, max_e = 8)
cat("\nEvent Study (Total Expenditure PP):\n")
summary(es_exp)

## ──────────────────────────────────────────────────
## 2. CS-DiD: Revenue decomposition
## ──────────────────────────────────────────────────

# State revenue per pupil
cat("\n=== CS-DiD: State Revenue Per Pupil ===\n")
cs_strev <- att_gt(
  yname = "st_rev_pp",
  tname = "year",
  idname = "state_id",
  gname = "treatment_year",
  data = panel %>% filter(!is.na(st_rev_pp)),
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  bstrap = TRUE,
  biters = 1000
)
agg_strev <- aggte(cs_strev, type = "simple")
cat("Overall ATT (State Revenue PP):\n")
summary(agg_strev)

# Federal revenue per pupil (PLACEBO)
cat("\n=== CS-DiD: Federal Revenue Per Pupil (Placebo) ===\n")
cs_fedrev <- att_gt(
  yname = "fed_rev_pp",
  tname = "year",
  idname = "state_id",
  gname = "treatment_year",
  data = panel %>% filter(!is.na(fed_rev_pp)),
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  bstrap = TRUE,
  biters = 1000
)
agg_fedrev <- aggte(cs_fedrev, type = "simple")
cat("Overall ATT (Federal Revenue PP - Placebo):\n")
summary(agg_fedrev)

# Local revenue per pupil
cat("\n=== CS-DiD: Local Revenue Per Pupil ===\n")
cs_locrev <- att_gt(
  yname = "loc_rev_pp",
  tname = "year",
  idname = "state_id",
  gname = "treatment_year",
  data = panel %>% filter(!is.na(loc_rev_pp)),
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  bstrap = TRUE,
  biters = 1000
)
agg_locrev <- aggte(cs_locrev, type = "simple")
cat("Overall ATT (Local Revenue PP):\n")
summary(agg_locrev)

# Total revenue per pupil
cat("\n=== CS-DiD: Total Revenue Per Pupil ===\n")
cs_rev <- att_gt(
  yname = "rev_pp",
  tname = "year",
  idname = "state_id",
  gname = "treatment_year",
  data = panel %>% filter(!is.na(rev_pp)),
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  bstrap = TRUE,
  biters = 1000
)
agg_rev <- aggte(cs_rev, type = "simple")
cat("Overall ATT (Total Revenue PP):\n")
summary(agg_rev)

es_rev <- aggte(cs_rev, type = "dynamic", min_e = -6, max_e = 8)

## ──────────────────────────────────────────────────
## 3. CS-DiD: Current spending per pupil
## ──────────────────────────────────────────────────

cat("\n=== CS-DiD: Current Spending Per Pupil ===\n")
cs_cur <- att_gt(
  yname = "cur_exp_pp",
  tname = "year",
  idname = "state_id",
  gname = "treatment_year",
  data = panel %>% filter(!is.na(cur_exp_pp)),
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  bstrap = TRUE,
  biters = 1000
)
agg_cur <- aggte(cs_cur, type = "simple")
cat("Overall ATT (Current Spending PP):\n")
summary(agg_cur)

## ──────────────────────────────────────────────────
## 4. TWFE comparison (for robustness table)
## ──────────────────────────────────────────────────

cat("\n=== TWFE Comparison ===\n")

twfe_exp <- feols(exp_pp ~ post | state_id + year,
                  data = panel, cluster = ~state_id)
cat("TWFE Total Expenditure PP:\n")
print(summary(twfe_exp))

twfe_strev <- feols(st_rev_pp ~ post | state_id + year,
                    data = panel, cluster = ~state_id)
cat("\nTWFE State Revenue PP:\n")
print(summary(twfe_strev))

twfe_fedrev <- feols(fed_rev_pp ~ post | state_id + year,
                     data = panel, cluster = ~state_id)
cat("\nTWFE Federal Revenue PP (Placebo):\n")
print(summary(twfe_fedrev))

twfe_locrev <- feols(loc_rev_pp ~ post | state_id + year,
                     data = panel, cluster = ~state_id)
cat("\nTWFE Local Revenue PP:\n")
print(summary(twfe_locrev))

## ──────────────────────────────────────────────────
## 5. Save results
## ──────────────────────────────────────────────────

results <- list(
  cs_exp = cs_exp,
  cs_strev = cs_strev,
  cs_fedrev = cs_fedrev,
  cs_locrev = cs_locrev,
  cs_rev = cs_rev,
  cs_cur = cs_cur,
  agg_exp = agg_exp,
  agg_strev = agg_strev,
  agg_fedrev = agg_fedrev,
  agg_locrev = agg_locrev,
  agg_rev = agg_rev,
  agg_cur = agg_cur,
  es_exp = es_exp,
  es_rev = es_rev,
  twfe_exp = twfe_exp,
  twfe_strev = twfe_strev,
  twfe_fedrev = twfe_fedrev,
  twfe_locrev = twfe_locrev
)

saveRDS(results, file.path(data_dir, "main_results.rds"))

## ──────────────────────────────────────────────────
## 6. Diagnostics for validator
## ──────────────────────────────────────────────────

# Count all treated states in the design
treated_states <- panel %>%
  filter(treatment_year > 0) %>%
  group_by(state_abbr) %>%
  summarise(
    n_post = sum(year >= treatment_year),
    n_pre = sum(year < treatment_year),
    .groups = "drop"
  )

diagnostics <- list(
  n_treated = n_distinct(panel$state_abbr[panel$treatment_year > 0]),
  n_pre = min(treated_states$n_pre),
  n_obs = nrow(panel),
  att_exp = agg_exp$overall.att,
  se_exp = agg_exp$overall.se,
  att_strev = agg_strev$overall.att,
  se_strev = agg_strev$overall.se,
  att_fedrev = agg_fedrev$overall.att,
  se_fedrev = agg_fedrev$overall.se,
  att_locrev = agg_locrev$overall.att,
  se_locrev = agg_locrev$overall.se
)

write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat("\nDiagnostics saved.\n")
cat(sprintf("  n_treated: %d\n", diagnostics$n_treated))
cat(sprintf("  n_pre: %d\n", diagnostics$n_pre))
cat(sprintf("  n_obs: %d\n", diagnostics$n_obs))
cat(sprintf("  ATT(exp_pp): %.1f (SE=%.1f)\n", diagnostics$att_exp, diagnostics$se_exp))
cat(sprintf("  ATT(st_rev_pp): %.1f (SE=%.1f)\n", diagnostics$att_strev, diagnostics$se_strev))
cat(sprintf("  ATT(fed_rev_pp): %.1f (SE=%.1f)\n", diagnostics$att_fedrev, diagnostics$se_fedrev))

cat("\n=== Main analysis complete ===\n")
