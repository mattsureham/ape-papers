# 03_main_analysis.R — Main DiD analysis
# apep_0972: Craft brewery self-distribution and beverage mfg employment

source("00_packages.R")

state_panel <- readRDS("../data/state_panel.rds")
county_entry <- readRDS("../data/county_entry.rds")

# ══════════════════════════════════════════════════════════════════════
# 1. TWFE — Baseline estimates (NAICS 312)
# ══════════════════════════════════════════════════════════════════════
sp312 <- state_panel %>% filter(industry == "312")

cat("=== TWFE: NAICS 312 Employment ===\n")
m1_emp <- feols(log_emp ~ treated | statefips + time_id,
                data = sp312, cluster = ~statefips)
summary(m1_emp)

m1_hire <- feols(hire_rate ~ treated | statefips + time_id,
                 data = sp312, cluster = ~statefips)
summary(m1_hire)

# Earnings: many NAs in weighted mean, use only non-missing
sp312_earn <- sp312 %>% filter(!is.na(EarnS_mean))
cat(sprintf("Earnings panel: %d obs (%.0f%% of full)\n",
            nrow(sp312_earn), 100 * nrow(sp312_earn) / nrow(sp312)))

m1_earn <- if (nrow(sp312_earn) > 200) {
  feols(EarnS_mean ~ treated | statefips + time_id,
        data = sp312_earn, cluster = ~statefips)
} else {
  cat("Too few earnings observations, skipping.\n")
  NULL
}
if (!is.null(m1_earn)) summary(m1_earn)

m1_net <- feols(net_job_creation ~ treated | statefips + time_id,
                data = sp312, cluster = ~statefips)
summary(m1_net)

# ══════════════════════════════════════════════════════════════════════
# 2. EVENT STUDY — Sun-Abraham (fixest::sunab)
# ══════════════════════════════════════════════════════════════════════
cat("\n=== Sun-Abraham Event Study ===\n")

# Create relative time variable
sp312 <- sp312 %>%
  mutate(
    rel_time = if_else(first_treat_time == 0L,
                       -1000L,  # never-treated placeholder
                       time_id - first_treat_time)
  )

# Trim to [-12, +16] quarters (3 years pre, 4 years post)
es_data <- sp312 %>%
  filter(rel_time >= -12 | first_treat_time == 0)

es_emp <- feols(log_emp ~ sunab(first_treat_time, time_id,
                                ref.p = -1) | statefips + time_id,
                data = sp312 %>% filter(first_treat_time > 0 | first_treat_time == 0),
                cluster = ~statefips)
summary(es_emp)

# Extract event study coefficients for table
es_coefs <- as.data.frame(coeftable(es_emp))
es_coefs$term <- rownames(es_coefs)
es_coefs <- es_coefs %>%
  filter(grepl("time_id::", term)) %>%
  mutate(
    rel_time = as.integer(gsub(".*::(-?\\d+)", "\\1", term))
  ) %>%
  filter(rel_time >= -12 & rel_time <= 16)

saveRDS(es_coefs, "../data/es_coefs.rds")

# ══════════════════════════════════════════════════════════════════════
# 3. TRIPLE DIFFERENCE: NAICS 312 vs 311
# ══════════════════════════════════════════════════════════════════════
cat("\n=== Triple Difference: 312 vs 311 ===\n")

# Stack 312 and 311
sp_both <- state_panel %>%
  filter(industry %in% c("311", "312"))

m3_ddd <- feols(log_emp ~ treated * is_312 | statefips^industry + time_id^industry,
                data = sp_both, cluster = ~statefips)
summary(m3_ddd)

# ══════════════════════════════════════════════════════════════════════
# 4. EXTENSIVE MARGIN: County entry into NAICS 312
# ══════════════════════════════════════════════════════════════════════
cat("\n=== County Entry (Extensive Margin) ===\n")

m4_entry <- feols(n_counties_312 ~ treated | statefips + time_id,
                  data = county_entry %>%
                    filter(first_treat_time > 0 | first_treat_time == 0),
                  cluster = ~statefips)
summary(m4_entry)

# Also in logs
county_entry <- county_entry %>%
  mutate(log_counties = log(pmax(n_counties_312, 1)))

m4_log <- feols(log_counties ~ treated | statefips + time_id,
                data = county_entry %>%
                  filter(first_treat_time > 0 | first_treat_time == 0),
                cluster = ~statefips)
summary(m4_log)

# ══════════════════════════════════════════════════════════════════════
# 5. CALLAWAY-SANT'ANNA (robustness)
# ══════════════════════════════════════════════════════════════════════
cat("\n=== Callaway-Sant'Anna DiD ===\n")

# Prepare data for CS: need balanced panel with unique id
cs_data <- sp312 %>%
  select(statefips, time_id, first_treat_time, log_emp, Emp) %>%
  filter(!is.na(log_emp))

# Check for duplicates
dups <- cs_data %>% count(statefips, time_id) %>% filter(n > 1)
if (nrow(dups) > 0) {
  cat("WARNING: Duplicates found, keeping first.\n")
  cs_data <- cs_data %>% distinct(statefips, time_id, .keep_all = TRUE)
}

# Balance the panel
all_combos <- expand.grid(
  statefips = unique(cs_data$statefips),
  time_id = unique(cs_data$time_id)
)
cs_balanced <- all_combos %>%
  left_join(cs_data, by = c("statefips", "time_id")) %>%
  group_by(statefips) %>%
  fill(first_treat_time, .direction = "downup") %>%
  ungroup() %>%
  filter(!is.na(first_treat_time))

# Fill NAs in log_emp with state mean (rare missing quarters)
cs_balanced <- cs_balanced %>%
  group_by(statefips) %>%
  mutate(log_emp = if_else(is.na(log_emp),
                           mean(log_emp, na.rm = TRUE),
                           log_emp)) %>%
  ungroup()

cs_out <- tryCatch({
  att_gt(
    yname = "log_emp",
    tname = "time_id",
    idname = "statefips",
    gname = "first_treat_time",
    data = as.data.frame(cs_balanced),
    control_group = "notyettreated",
    base_period = "universal"
  )
}, error = function(e) {
  cat("CS-DiD error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(cs_out)) {
  cat("\nCS-DiD ATT(g,t) summary:\n")
  cs_agg <- aggte(cs_out, type = "simple")
  print(summary(cs_agg))

  cs_es <- aggte(cs_out, type = "dynamic", min_e = -12, max_e = 16)
  cat("\nCS-DiD dynamic ATT:\n")
  print(summary(cs_es))

  saveRDS(cs_out, "../data/cs_did_out.rds")
  saveRDS(cs_es, "../data/cs_es_out.rds")
}

# ══════════════════════════════════════════════════════════════════════
# 6. DIAGNOSTICS
# ══════════════════════════════════════════════════════════════════════
n_treated <- n_distinct(sp312$statefips[sp312$treat_yq > 0])
n_control <- n_distinct(sp312$statefips[sp312$treat_yq == 0])

# Pre-periods: quarters before first treatment (2011Q3 = time_id 43)
earliest_treat <- min(sp312$first_treat_time[sp312$first_treat_time > 0])
n_pre <- earliest_treat - 1  # quarters before first treatment

diag <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = nrow(sp312),
  n_states = n_distinct(sp312$statefips),
  n_control_states = n_control,
  n_quarters = n_distinct(sp312$time_id),
  mean_emp_312 = round(mean(sp312$Emp), 0),
  sd_emp_312 = round(sd(sp312$Emp), 0),
  sd_log_emp = round(sd(sp312$log_emp), 3),
  twfe_coef = round(coef(m1_emp)["treated"], 4),
  twfe_se = round(se(m1_emp)["treated"], 4)
)

write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
cat("\nDiagnostics saved.\n")
cat(sprintf("  n_treated: %d states\n", diag$n_treated))
cat(sprintf("  n_pre: %d quarters\n", diag$n_pre))
cat(sprintf("  n_obs: %d\n", diag$n_obs))

# Save all models
saveRDS(list(
  m1_emp = m1_emp,
  m1_hire = m1_hire,
  m1_earn = m1_earn,
  m1_net = m1_net,
  es_emp = es_emp,
  m3_ddd = m3_ddd,
  m4_entry = m4_entry,
  m4_log = m4_log
), "../data/main_models.rds")

cat("\nMain analysis complete.\n")
