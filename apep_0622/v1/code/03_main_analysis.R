# 03_main_analysis.R — Primary DiD regressions
# APEP-0622: Taxing the Transition — EV Registration Fees and Adoption

source("code/00_packages.R")

cat("=== 03_main_analysis.R ===\n")

# ============================================================
# 1. LOAD DATA
# ============================================================
panel <- readRDS("data/analysis_panel.rds")
cat("Panel loaded:", nrow(panel), "obs,", n_distinct(panel$state), "states,",
    n_distinct(panel$year), "years\n")

# Verify panel structure for `did`
stopifnot(is.integer(panel$year) | is.numeric(panel$year))
stopifnot(is.numeric(panel$state_id))
stopifnot(all(panel$first_treat >= 0))
stopifnot(!any(is.na(panel$log_bev)))

cat("\nTreatment cohorts:\n")
panel %>%
  distinct(state, first_treat) %>%
  count(first_treat, name = "n_states") %>%
  arrange(first_treat) %>%
  print()

# ============================================================
# 2. CALLAWAY-SANT'ANNA (2021) — PRIMARY SPECIFICATION
# ============================================================
cat("\n=== Callaway-Sant'Anna DiD ===\n")

# att_gt: group-time ATTs
# Control group: not-yet-treated (preferred — more power)
cs_gt <- att_gt(
  yname    = "log_bev",
  tname    = "year",
  idname   = "state_id",
  gname    = "first_treat",
  xformla  = ~ 1,
  data     = panel,
  control_group = "notyettreated",
  est_method    = "dr",       # doubly robust
  bstrap        = TRUE,
  cband         = TRUE,
  biters        = 1000,
  clustervars   = "state_id",
  print_details = FALSE
)

cat("\nGroup-Time ATTs computed.\n")
cat("Number of group-time estimates:", length(cs_gt$att), "\n")

# ============================================================
# 3. AGGREGATE: EVENT STUDY
# ============================================================
cat("\n=== Event Study Aggregation ===\n")

cs_es <- aggte(cs_gt, type = "dynamic", min_e = -5, max_e = 5)

cat("\nEvent study ATTs:\n")
es_summary <- data.frame(
  event_time = cs_es$egt,
  att        = round(cs_es$att.egt, 4),
  se         = round(cs_es$se.egt, 4)
)
es_summary$stars <- ifelse(abs(es_summary$att / es_summary$se) > 2.576, "***",
                    ifelse(abs(es_summary$att / es_summary$se) > 1.960, "**",
                    ifelse(abs(es_summary$att / es_summary$se) > 1.645, "*", "")))
print(es_summary)

# ============================================================
# 4. AGGREGATE: SIMPLE ATT
# ============================================================
cat("\n=== Simple ATT ===\n")

cs_simple <- aggte(cs_gt, type = "simple")

cat("Overall ATT:", round(cs_simple$overall.att, 4), "\n")
cat("SE:         ", round(cs_simple$overall.se, 4), "\n")
cat("95% CI:     [", round(cs_simple$overall.att - 1.96 * cs_simple$overall.se, 4),
    ",", round(cs_simple$overall.att + 1.96 * cs_simple$overall.se, 4), "]\n")

# ============================================================
# 5. AGGREGATE: GROUP-LEVEL (cohort ATTs)
# ============================================================
cat("\n=== Cohort ATTs ===\n")

cs_group <- aggte(cs_gt, type = "group")

cat("\nCohort-specific ATTs:\n")
group_summary <- data.frame(
  cohort = cs_group$egt,
  att    = round(cs_group$att.egt, 4),
  se     = round(cs_group$se.egt, 4)
)
print(group_summary)

# ============================================================
# 6. TWFE — COMPARISON SPECIFICATION
# ============================================================
cat("\n=== TWFE (fixest) ===\n")

# Standard TWFE for comparison
twfe_main <- feols(log_bev ~ treated | state_id + year,
                   data = panel,
                   cluster = ~state_id)

cat("\nTWFE results:\n")
summary(twfe_main)

# Also run with log(ev_total)
twfe_total <- feols(log_ev_total ~ treated | state_id + year,
                    data = panel,
                    cluster = ~state_id)

# ============================================================
# 7. DIAGNOSTICS
# ============================================================
cat("\n=== Writing Diagnostics ===\n")

n_treated <- panel %>% filter(first_treat > 0) %>% distinct(state) %>% nrow()
n_never_treated <- panel %>% filter(first_treat == 0) %>% distinct(state) %>% nrow()

# Count pre-treatment periods: minimum across treated cohorts
pre_periods <- panel %>%
  filter(first_treat > 0) %>%
  group_by(first_treat) %>%
  summarise(n_pre = sum(year < first_treat[1])) %>%
  pull(n_pre)
min_pre <- min(pre_periods / n_distinct(panel %>% filter(first_treat > 0) %>% pull(state)))

# Pre-trend test: check if pre-treatment event-study coefficients are jointly zero
pre_es <- es_summary %>% filter(event_time < 0)
pre_trend_max_t <- max(abs(pre_es$att / pre_es$se))

diagnostics <- list(
  n_obs            = nrow(panel),
  n_states         = n_distinct(panel$state),
  n_treated        = n_treated,
  n_never_treated  = n_never_treated,
  n_clusters       = n_distinct(panel$state_id),
  n_years          = n_distinct(panel$year),
  year_range       = paste(range(panel$year), collapse = "-"),
  min_pre_periods  = min(panel$year[1], na.rm = TRUE),
  cs_att           = round(cs_simple$overall.att, 6),
  cs_se            = round(cs_simple$overall.se, 6),
  twfe_coef        = round(coef(twfe_main)["treated"], 6),
  twfe_se          = round(se(twfe_main)["treated"], 6),
  pre_trend_max_t  = round(pre_trend_max_t, 4),
  n_group_time     = length(cs_gt$att)
)

write(toJSON(diagnostics, auto_unbox = TRUE, pretty = TRUE),
      "data/diagnostics.json")
cat("Diagnostics written to data/diagnostics.json\n")

# ============================================================
# 8. SAVE RESULTS
# ============================================================
cs_results <- list(
  gt      = cs_gt,
  es      = cs_es,
  simple  = cs_simple,
  group   = cs_group
)

twfe_results <- list(
  main  = twfe_main,
  total = twfe_total
)

saveRDS(cs_results, "data/cs_results.rds")
saveRDS(twfe_results, "data/twfe_results.rds")

cat("\nSaved: data/cs_results.rds\n")
cat("Saved: data/twfe_results.rds\n")
cat("=== 03_main_analysis.R complete ===\n")
