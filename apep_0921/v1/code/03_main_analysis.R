## 03_main_analysis.R — Callaway-Sant'Anna DiD + TWFE
## apep_0917: Civil Asset Forfeiture Regulatory Leakage

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

## ---------- Load panel ----------
df <- readRDS(file.path(data_dir, "agency_panel.rds"))
state_df <- readRDS(file.path(data_dir, "state_panel.rds"))
reforms <- readRDS(file.path(data_dir, "reforms.rds"))

## Drop NC (reform year 2000, before panel starts in 2009 — always treated, never observed pre)
df <- df %>% filter(state != "NC")

## Restrict panel to 2014-2024 (contemporaneous reform window)
## Keep pre-period from 2009 for pre-trends
cat("Agency panel:", nrow(df), "obs,", n_distinct(df$ncic_cd), "agencies\n")
cat("FY range:", min(df$fy), "-", max(df$fy), "\n")
cat("Treatment cohorts:", paste(sort(unique(df$first_treat[df$first_treat > 0])),
                                 collapse = ", "), "\n")

## ---------- Summary statistics ----------
summ_overall <- df %>%
  summarize(
    N = n(),
    N_agencies = n_distinct(ncic_cd),
    N_states = n_distinct(state),
    mean_es_funds = mean(es_funds),
    sd_es_funds = sd(es_funds),
    median_es_funds = median(es_funds),
    mean_log_es = mean(log_es_funds),
    sd_log_es = sd(log_es_funds),
    share_positive = mean(has_es),
    mean_budget = mean(budget, na.rm = TRUE)
  )

# By reform status
summ_by_status <- df %>%
  mutate(treated_ever = first_treat > 0) %>%
  group_by(treated_ever) %>%
  summarize(
    N = n(),
    N_agencies = n_distinct(ncic_cd),
    mean_es_funds = mean(es_funds),
    sd_es_funds = sd(es_funds),
    mean_log_es = mean(log_es_funds),
    share_positive = mean(has_es),
    mean_budget = mean(budget, na.rm = TRUE),
    .groups = "drop"
  )

cat("\n=== Summary Stats ===\n")
print(summ_overall)
cat("\nBy treatment status:\n")
print(summ_by_status)

## ---------- Pre-treatment SD(Y) for SDE ----------
pre_treat_stats <- df %>%
  filter(post_reform == 0) %>%
  summarize(
    sd_es_funds = sd(es_funds),
    sd_log_es = sd(log_es_funds),
    sd_has_es = sd(has_es),
    mean_es_funds = mean(es_funds),
    mean_log_es = mean(log_es_funds),
    mean_has_es = mean(has_es)
  )
cat("\nPre-treatment SDs:\n")
print(pre_treat_stats)
saveRDS(pre_treat_stats, file.path(data_dir, "pre_treat_stats.rds"))

## ---------- 1. TWFE Baseline ----------
cat("\n=== TWFE Regressions ===\n")

# Main outcome: log equitable sharing funds
twfe1 <- feols(log_es_funds ~ post_reform | ncic_cd + fy,
               data = df, cluster = ~state)
cat("\nTWFE: log(ES funds + 1)\n")
summary(twfe1)

# Extensive margin: participation
twfe2 <- feols(has_es ~ post_reform | ncic_cd + fy,
               data = df, cluster = ~state)
cat("\nTWFE: Participation (extensive margin)\n")
summary(twfe2)

# Level outcome
twfe3 <- feols(es_funds ~ post_reform | ncic_cd + fy,
               data = df, cluster = ~state)
cat("\nTWFE: ES funds (levels)\n")
summary(twfe3)

## ---------- 2. Callaway-Sant'Anna ----------
cat("\n=== Callaway-Sant'Anna ===\n")

# Need numeric agency ID
df <- df %>%
  mutate(agency_id = as.integer(factor(ncic_cd)))

# CS-DiD: log equitable sharing funds
cs_log <- att_gt(
  yname = "log_es_funds",
  tname = "fy",
  idname = "agency_id",
  gname = "first_treat",
  data = df,
  control_group = "nevertreated",
  base_period = "varying",
  allow_unbalanced_panel = TRUE,
  clustervars = "state"
)

# Aggregate to overall ATT
cs_log_agg <- aggte(cs_log, type = "simple", na.rm = TRUE)
cat("\nCS-DiD Overall ATT (log ES funds):\n")
summary(cs_log_agg)

# Event study
cs_log_es <- aggte(cs_log, type = "dynamic", min_e = -5, max_e = 5, na.rm = TRUE)
cat("\nCS-DiD Event Study (log ES funds):\n")
summary(cs_log_es)

# CS-DiD: Extensive margin
cs_ext <- att_gt(
  yname = "has_es",
  tname = "fy",
  idname = "agency_id",
  gname = "first_treat",
  data = df,
  control_group = "nevertreated",
  base_period = "varying",
  allow_unbalanced_panel = TRUE,
  clustervars = "state"
)

cs_ext_agg <- aggte(cs_ext, type = "simple", na.rm = TRUE)
cat("\nCS-DiD Overall ATT (participation):\n")
summary(cs_ext_agg)

cs_ext_es <- aggte(cs_ext, type = "dynamic", min_e = -5, max_e = 5, na.rm = TRUE)
cat("\nCS-DiD Event Study (participation):\n")
summary(cs_ext_es)

# CS-DiD: Level outcome
cs_level <- att_gt(
  yname = "es_funds",
  tname = "fy",
  idname = "agency_id",
  gname = "first_treat",
  data = df,
  control_group = "nevertreated",
  base_period = "varying",
  allow_unbalanced_panel = TRUE,
  clustervars = "state"
)

cs_level_agg <- aggte(cs_level, type = "simple", na.rm = TRUE)
cat("\nCS-DiD Overall ATT (ES funds, levels):\n")
summary(cs_level_agg)

## ---------- 3. Heterogeneity: Anti-circumvention ----------
cat("\n=== Heterogeneity: Anti-circumvention ===\n")

# Split: states WITH anti-circumvention vs WITHOUT
df_no_anti <- df %>% filter(!anti_circumvention)
df_anti <- df %>% filter(anti_circumvention | first_treat == 0)

twfe_no_anti <- feols(log_es_funds ~ post_reform | ncic_cd + fy,
                      data = df_no_anti, cluster = ~state)
cat("\nTWFE without anti-circumvention:\n")
summary(twfe_no_anti)

twfe_anti <- feols(log_es_funds ~ post_reform | ncic_cd + fy,
                   data = df_anti, cluster = ~state)
cat("\nTWFE with anti-circumvention:\n")
summary(twfe_anti)

## ---------- 4. Heterogeneity: Reform stringency ----------
cat("\n=== Heterogeneity: Reform stringency ===\n")

# Split by stringency: high (abolition + conviction) vs low (burden + reporting)
df_strong <- df %>%
  filter(reform_stringency >= 3 | first_treat == 0) %>%
  mutate(post_reform = ifelse(first_treat > 0 & fy >= first_treat, 1L, 0L))

df_weak <- df %>%
  filter(reform_stringency %in% c(1, 2) | first_treat == 0) %>%
  mutate(post_reform = ifelse(first_treat > 0 & fy >= first_treat, 1L, 0L))

twfe_strong <- feols(log_es_funds ~ post_reform | ncic_cd + fy,
                     data = df_strong, cluster = ~state)
cat("\nTWFE strong reform (abolition + conviction req):\n")
summary(twfe_strong)

twfe_weak <- feols(log_es_funds ~ post_reform | ncic_cd + fy,
                   data = df_weak, cluster = ~state)
cat("\nTWFE weak reform (burden raised + reporting):\n")
summary(twfe_weak)

## ---------- Save results ----------
results <- list(
  twfe_log = twfe1,
  twfe_ext = twfe2,
  twfe_level = twfe3,
  cs_log = cs_log,
  cs_log_agg = cs_log_agg,
  cs_log_es = cs_log_es,
  cs_ext = cs_ext,
  cs_ext_agg = cs_ext_agg,
  cs_ext_es = cs_ext_es,
  cs_level = cs_level,
  cs_level_agg = cs_level_agg,
  twfe_no_anti = twfe_no_anti,
  twfe_anti = twfe_anti,
  twfe_strong = twfe_strong,
  twfe_weak = twfe_weak,
  summary_stats = summ_overall,
  summary_by_status = summ_by_status
)

saveRDS(results, file.path(data_dir, "results.rds"))

## ---------- diagnostics.json for validator ----------
# Earliest reform in analysis sample is 2014 (MN), panel starts 2009
min_reform_in_sample <- min(reforms$reform_year[reforms$state != "NC"])
diag <- list(
  n_treated = n_distinct(df$state[df$first_treat > 0]),
  n_pre = length(unique(df$fy[df$fy < min_reform_in_sample])),
  n_obs = nrow(df)
)
write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat("\n=== Main analysis complete ===\n")
cat("diagnostics.json written:", toJSON(diag, auto_unbox = TRUE), "\n")
