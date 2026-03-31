# 03_main_analysis.R — Main Callaway-Sant'Anna DiD analysis
# APEP-1194: Positive Train Control and Railroad Accident Prevention

source("00_packages.R")

panel_raw <- readRDS("../data/panel_clean.rds")

# ---- Balance the panel ----
# CS DiD requires balanced panel. Fill missing railroad-years with zeros.
all_rr <- unique(panel_raw$railroad)
all_years <- min(panel_raw$year):max(panel_raw$year)
full_grid <- expand.grid(railroad = all_rr, year = all_years, stringsAsFactors = FALSE)

# Get railroad-level info (first_treat, railroad_id)
rr_info <- panel_raw %>%
  distinct(railroad, first_treat, railroad_id)

panel <- full_grid %>%
  left_join(panel_raw %>% select(-first_treat, -railroad_id), by = c("railroad", "year")) %>%
  left_join(rr_info, by = "railroad") %>%
  mutate(
    across(c(total_accidents, human_factor_accidents, non_human_accidents,
             track_accidents, equipment_accidents, signal_accidents,
             total_killed, total_injured, total_damage,
             human_killed, human_injured, ptc_accident_count),
           ~replace_na(., 0)),
    # CRITICAL: first_treat must be double (not integer) for did package
    # The did package internally sets never-treated gname to Inf,
    # which truncates if column is integer
    first_treat = as.double(first_treat),
    post_ptc = ifelse(first_treat > 0 & year >= first_treat, 1, 0),
    asinh_total = asinh(total_accidents),
    asinh_human = asinh(human_factor_accidents),
    asinh_nonhuman = asinh(non_human_accidents),
    asinh_track = asinh(track_accidents),
    asinh_equip = asinh(equipment_accidents),
    asinh_killed = asinh(total_killed),
    asinh_injured = asinh(total_injured),
    log_damage = log1p(total_damage)
  )

cat(sprintf("Balanced panel: %d obs, %d railroads, %d treated\n",
            nrow(panel), n_distinct(panel$railroad),
            n_distinct(panel$railroad[panel$first_treat > 0])))

# ---- Pre-treatment summary statistics ----
pre_stats <- panel %>%
  filter(first_treat == 0 | year < first_treat) %>%
  summarise(
    across(c(total_accidents, human_factor_accidents, non_human_accidents,
             total_killed, total_injured, total_damage),
           list(mean = mean, sd = sd), .names = "{.col}_{.fn}")
  )

cat("\n=== Pre-treatment outcome means (all railroads) ===\n")
pre_stats %>%
  pivot_longer(everything()) %>%
  print(n = 20)

# Save pre-treatment SDs for SDE computation
pre_sds <- list(
  total_accidents = pre_stats$total_accidents_sd,
  human_factor_accidents = pre_stats$human_factor_accidents_sd,
  non_human_accidents = pre_stats$non_human_accidents_sd,
  total_killed = pre_stats$total_killed_sd,
  total_injured = pre_stats$total_injured_sd,
  total_damage = pre_stats$total_damage_sd
)
saveRDS(pre_sds, "../data/pre_sds.rds")
saveRDS(pre_stats, "../data/pre_stats.rds")

# ---- Callaway-Sant'Anna: Main specification (human-factor accidents) ----
cat("\n=== CS DiD: Human Factor Accidents (asinh) ===\n")
cs_human <- att_gt(
  yname = "asinh_human",
  tname = "year",
  idname = "railroad_id",
  gname = "first_treat",
  data = panel,
  control_group = "nevertreated",
  base_period = "universal"
)

# Simple aggregate ATT
agg_human <- aggte(cs_human, type = "simple")
cat("\nAggregate ATT (human-factor accidents, asinh):\n")
summary(agg_human)

# Dynamic/event-study aggregation
es_human <- aggte(cs_human, type = "dynamic", min_e = -8, max_e = 5)
cat("\nEvent study (human-factor accidents):\n")
summary(es_human)

# ---- CS DiD: Non-human-factor accidents (PLACEBO) ----
cat("\n=== CS DiD: Non-Human-Factor Accidents (PLACEBO, asinh) ===\n")
cs_nonhuman <- att_gt(
  yname = "asinh_nonhuman",
  tname = "year",
  idname = "railroad_id",
  gname = "first_treat",
  data = panel,
  control_group = "nevertreated",
  base_period = "universal"
)

agg_nonhuman <- aggte(cs_nonhuman, type = "simple")
cat("\nAggregate ATT (non-human-factor accidents, asinh):\n")
summary(agg_nonhuman)

es_nonhuman <- aggte(cs_nonhuman, type = "dynamic", min_e = -8, max_e = 5)
cat("\nEvent study (non-human-factor accidents):\n")
summary(es_nonhuman)

# ---- CS DiD: Total accidents ----
cat("\n=== CS DiD: Total Accidents (asinh) ===\n")
cs_total <- att_gt(
  yname = "asinh_total",
  tname = "year",
  idname = "railroad_id",
  gname = "first_treat",
  data = panel,
  control_group = "nevertreated",
  base_period = "universal"
)

agg_total <- aggte(cs_total, type = "simple")
cat("\nAggregate ATT (total accidents, asinh):\n")
summary(agg_total)

es_total <- aggte(cs_total, type = "dynamic", min_e = -8, max_e = 5)

# ---- CS DiD: Injuries ----
cat("\n=== CS DiD: Injuries (asinh) ===\n")
cs_injured <- att_gt(
  yname = "asinh_injured",
  tname = "year",
  idname = "railroad_id",
  gname = "first_treat",
  data = panel,
  control_group = "nevertreated",
  base_period = "universal"
)

agg_injured <- aggte(cs_injured, type = "simple")
cat("\nAggregate ATT (injuries, asinh):\n")
summary(agg_injured)

es_injured <- aggte(cs_injured, type = "dynamic", min_e = -8, max_e = 5)

# ---- CS DiD: Damage cost ----
cat("\n=== CS DiD: Damage Cost (log) ===\n")
cs_damage <- att_gt(
  yname = "log_damage",
  tname = "year",
  idname = "railroad_id",
  gname = "first_treat",
  data = panel,
  control_group = "nevertreated",
  base_period = "universal"
)

agg_damage <- aggte(cs_damage, type = "simple")
cat("\nAggregate ATT (damage cost, log):\n")
summary(agg_damage)

es_damage <- aggte(cs_damage, type = "dynamic", min_e = -8, max_e = 5)

# ---- CS DiD: Fatalities ----
cat("\n=== CS DiD: Fatalities (asinh) ===\n")
cs_killed <- att_gt(
  yname = "asinh_killed",
  tname = "year",
  idname = "railroad_id",
  gname = "first_treat",
  data = panel,
  control_group = "nevertreated",
  base_period = "universal"
)

agg_killed <- aggte(cs_killed, type = "simple")
cat("\nAggregate ATT (fatalities, asinh):\n")
summary(agg_killed)

# ---- Save all results ----
results <- list(
  cs_human = cs_human,
  cs_nonhuman = cs_nonhuman,
  cs_total = cs_total,
  cs_injured = cs_injured,
  cs_damage = cs_damage,
  cs_killed = cs_killed,
  agg_human = agg_human,
  agg_nonhuman = agg_nonhuman,
  agg_total = agg_total,
  agg_injured = agg_injured,
  agg_damage = agg_damage,
  agg_killed = agg_killed,
  es_human = es_human,
  es_nonhuman = es_nonhuman,
  es_total = es_total,
  es_injured = es_injured,
  es_damage = es_damage
)

saveRDS(results, "../data/cs_results.rds")
cat("\nAll CS DiD results saved.\n")

# ---- TWFE comparison (for robustness) ----
cat("\n=== TWFE (fixest) for comparison ===\n")
twfe_human <- feols(asinh_human ~ post_ptc | railroad_id + year,
                    data = panel, cluster = ~railroad_id)
twfe_nonhuman <- feols(asinh_nonhuman ~ post_ptc | railroad_id + year,
                       data = panel, cluster = ~railroad_id)
twfe_total <- feols(asinh_total ~ post_ptc | railroad_id + year,
                    data = panel, cluster = ~railroad_id)
twfe_injured <- feols(asinh_injured ~ post_ptc | railroad_id + year,
                      data = panel, cluster = ~railroad_id)
twfe_damage <- feols(log_damage ~ post_ptc | railroad_id + year,
                     data = panel, cluster = ~railroad_id)
twfe_killed <- feols(asinh_killed ~ post_ptc | railroad_id + year,
                     data = panel, cluster = ~railroad_id)

cat("\nTWFE Results:\n")
etable(twfe_human, twfe_nonhuman, twfe_total, twfe_injured, twfe_damage, twfe_killed,
       headers = c("Human", "Non-Human", "Total", "Injured", "Damage", "Killed"))

twfe_results <- list(
  twfe_human = twfe_human,
  twfe_nonhuman = twfe_nonhuman,
  twfe_total = twfe_total,
  twfe_injured = twfe_injured,
  twfe_damage = twfe_damage,
  twfe_killed = twfe_killed
)
saveRDS(twfe_results, "../data/twfe_results.rds")

# ---- Write diagnostics.json ----
diagnostics <- list(
  n_treated = n_distinct(panel$railroad[panel$first_treat > 0]),
  n_pre = length(unique(panel$year[panel$year < 2011])),  # Pre-earliest treatment
  n_obs = nrow(panel),
  n_railroads = n_distinct(panel$railroad),
  n_never_treated = n_distinct(panel$railroad[panel$first_treat == 0]),
  n_cohorts = n_distinct(panel$first_treat[panel$first_treat > 0]),
  year_range = paste(range(panel$year), collapse = "-"),
  att_human_factor = round(agg_human$overall.att, 4),
  att_human_factor_se = round(agg_human$overall.se, 4),
  att_nonhuman = round(agg_nonhuman$overall.att, 4),
  att_nonhuman_se = round(agg_nonhuman$overall.se, 4)
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
cat("\nDiagnostics saved to data/diagnostics.json\n")
