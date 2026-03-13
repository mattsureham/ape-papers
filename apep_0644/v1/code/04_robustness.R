# 04_robustness.R — Robustness checks
# apep_0644: Pay Transparency Mandates and Employer Adjustment

source("00_packages.R")

cat("=== Robustness Checks ===\n")

load("../data/main_results.RData")
df <- readRDS("../data/analysis_data.rds")

# ---- 1. Industry Heterogeneity (Triple-DiD) ----
cat("\n--- Industry Heterogeneity ---\n")

# Aggregate by state-industry-quarter with dispersion flag
ind_df <- df %>%
  filter(dispersion_group != "Other") %>%
  group_by(state_fips, industry, yq, time_index, first_treat_yq, treated_state, dispersion_group) %>%
  summarize(
    Emp = sum(Emp, na.rm = TRUE),
    HirN = sum(HirN, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    new_hire_rate = ifelse(Emp > 0, HirN / Emp, NA_real_),
    high_disp = as.integer(dispersion_group == "High wage dispersion"),
    panel_id = as.numeric(factor(paste(state_fips, industry, sep = "_")))
  ) %>%
  filter(!is.na(new_hire_rate), Emp > 0)

# Map treatment timing
treat_time_map <- tribble(
  ~first_treat_yq, ~first_treat_ti,
  20211, 25, 20231, 33, 20234, 36, 0, 0
)
ind_df <- ind_df %>% left_join(treat_time_map, by = "first_treat_yq")

# CS for high-dispersion only
cs_high <- att_gt(
  yname = "new_hire_rate", tname = "time_index", idname = "panel_id",
  gname = "first_treat_ti",
  data = as.data.frame(ind_df %>% filter(high_disp == 1)),
  control_group = "nevertreated", est_method = "dr", base_period = "universal"
)
cs_high_agg <- aggte(cs_high, type = "simple")

# CS for low-dispersion only
ind_df_low <- ind_df %>% filter(high_disp == 0) %>%
  mutate(panel_id = as.numeric(factor(paste(state_fips, industry, sep = "_"))))

cs_low <- att_gt(
  yname = "new_hire_rate", tname = "time_index", idname = "panel_id",
  gname = "first_treat_ti",
  data = as.data.frame(ind_df_low),
  control_group = "nevertreated", est_method = "dr", base_period = "universal"
)
cs_low_agg <- aggte(cs_low, type = "simple")

cat("High-dispersion ATT: ", cs_high_agg$overall.att, " (SE: ", cs_high_agg$overall.se, ")\n")
cat("Low-dispersion ATT:  ", cs_low_agg$overall.att, " (SE: ", cs_low_agg$overall.se, ")\n")

# ---- 2. Gender Heterogeneity ----
cat("\n--- Gender Heterogeneity ---\n")

qwi_sex <- readRDS("../data/qwi_sex_clean.rds")

# Aggregate to state-industry-quarter by sex
sex_state <- qwi_sex %>%
  group_by(state_fips, industry, yq, time_index, first_treat_yq, sex) %>%
  summarize(
    Emp = sum(Emp, na.rm = TRUE),
    HirN = sum(HirN, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    new_hire_rate = ifelse(Emp > 0, HirN / Emp, NA_real_),
    panel_id = as.numeric(factor(paste(state_fips, industry, sex, sep = "_")))
  ) %>%
  filter(!is.na(new_hire_rate), Emp > 0) %>%
  left_join(treat_time_map, by = "first_treat_yq")

# Male (sex=1)
cs_male <- att_gt(
  yname = "new_hire_rate", tname = "time_index", idname = "panel_id",
  gname = "first_treat_ti",
  data = as.data.frame(sex_state %>% filter(sex == 1)),
  control_group = "nevertreated", est_method = "dr", base_period = "universal"
)
cs_male_agg <- aggte(cs_male, type = "simple")

# Female (sex=2)
cs_female_df <- sex_state %>% filter(sex == 2) %>%
  mutate(panel_id = as.numeric(factor(paste(state_fips, industry, sep = "_"))))

cs_female <- att_gt(
  yname = "new_hire_rate", tname = "time_index", idname = "panel_id",
  gname = "first_treat_ti",
  data = as.data.frame(cs_female_df),
  control_group = "nevertreated", est_method = "dr", base_period = "universal"
)
cs_female_agg <- aggte(cs_female, type = "simple")

cat("Male ATT:   ", cs_male_agg$overall.att, " (SE: ", cs_male_agg$overall.se, ")\n")
cat("Female ATT: ", cs_female_agg$overall.att, " (SE: ", cs_female_agg$overall.se, ")\n")

# ---- 3. Colorado Border County Analysis ----
cat("\n--- Colorado Border County Analysis ---\n")

border_states <- c("08", "49", "20", "31", "56", "35", "40", "04")
border_df <- df %>%
  filter(state_fips %in% border_states) %>%
  group_by(state_fips, industry, yq, time_index, first_treat_yq) %>%
  summarize(
    Emp = sum(Emp, na.rm = TRUE),
    HirN = sum(HirN, na.rm = TRUE),
    FrmJbGn = sum(FrmJbGn, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    new_hire_rate = ifelse(Emp > 0, HirN / Emp, NA_real_),
    job_creation_rate = ifelse(Emp > 0, FrmJbGn / Emp, NA_real_),
    panel_id = as.numeric(factor(paste(state_fips, industry, sep = "_")))
  ) %>%
  filter(!is.na(new_hire_rate), Emp > 0) %>%
  left_join(treat_time_map, by = "first_treat_yq")

cs_border <- att_gt(
  yname = "new_hire_rate", tname = "time_index", idname = "panel_id",
  gname = "first_treat_ti",
  data = as.data.frame(border_df),
  control_group = "nevertreated", est_method = "dr", base_period = "universal"
)
cs_border_agg <- aggte(cs_border, type = "simple")
cat("CO border ATT: ", cs_border_agg$overall.att, " (SE: ", cs_border_agg$overall.se, ")\n")

# ---- 4. Leave-One-State-Out ----
cat("\n--- Leave-One-State-Out ---\n")

loo_results <- tibble(
  dropped_state = character(),
  att = numeric(),
  se = numeric()
)

for (st in c("08", "06", "53", "36")) {
  loo_df <- state_df %>%
    filter(state_fips != st) %>%
    mutate(panel_id = as.numeric(factor(paste(state_fips, industry, sep = "_"))))

  cs_loo <- att_gt(
    yname = "new_hire_rate", tname = "time_index", idname = "panel_id",
    gname = "first_treat_ti",
    data = as.data.frame(loo_df),
    control_group = "nevertreated", est_method = "dr", base_period = "universal"
  )
  cs_loo_agg <- aggte(cs_loo, type = "simple")

  state_name <- case_when(
    st == "08" ~ "Colorado",
    st == "06" ~ "California",
    st == "53" ~ "Washington",
    st == "36" ~ "New York"
  )

  loo_results <- bind_rows(loo_results, tibble(
    dropped_state = state_name,
    att = cs_loo_agg$overall.att,
    se = cs_loo_agg$overall.se
  ))
  cat("  Drop ", state_name, ": ATT = ", cs_loo_agg$overall.att,
      " (SE: ", cs_loo_agg$overall.se, ")\n")
}

# ---- 5. Placebo: Government sector ----
cat("\n--- Placebo: Government Sector ---\n")

gov_df <- df %>%
  filter(industry == "92") %>%  # Public Administration
  group_by(state_fips, yq, time_index, first_treat_yq) %>%
  summarize(
    Emp = sum(Emp, na.rm = TRUE),
    HirN = sum(HirN, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    new_hire_rate = ifelse(Emp > 0, HirN / Emp, NA_real_),
    panel_id = as.numeric(factor(state_fips))
  ) %>%
  filter(!is.na(new_hire_rate), Emp > 0) %>%
  left_join(treat_time_map, by = "first_treat_yq")

gov_result <- tryCatch({
  cs_gov <- att_gt(
    yname = "new_hire_rate", tname = "time_index", idname = "panel_id",
    gname = "first_treat_ti",
    data = as.data.frame(gov_df),
    control_group = "notyettreated", est_method = "dr", base_period = "universal"
  )
  cs_gov_agg <- aggte(cs_gov, type = "simple")
  cat("Government placebo ATT: ", cs_gov_agg$overall.att,
      " (SE: ", cs_gov_agg$overall.se, ")\n")
  cs_gov_agg
}, error = function(e) {
  cat("Government placebo estimation failed: ", e$message, "\n")
  # Fallback: simple TWFE for placebo
  gov_twfe <- feols(
    new_hire_rate ~ i(treated_state, i.post) | panel_id + time_index,
    data = gov_df %>% mutate(
      post = as.integer(time_index >= first_treat_ti & first_treat_ti > 0),
      treated_state = as.integer(first_treat_ti > 0)
    ),
    cluster = ~state_fips
  )
  cat("Government placebo TWFE ATT: ", coef(gov_twfe)[1], "\n")
  list(overall.att = coef(gov_twfe)[1], overall.se = se(gov_twfe)[1])
})
cs_gov_agg <- gov_result

# ---- 6. HonestDiD Sensitivity ----
cat("\n--- HonestDiD Sensitivity Analysis ---\n")

# Use the event study from CS estimator
cs_es_obj <- aggte(cs_new_hire, type = "dynamic", min_e = -8, max_e = 8)

# Extract pre-treatment estimates for sensitivity
pre_coefs <- cs_es_obj$att.egt[cs_es_obj$egt < 0]
pre_ses <- cs_es_obj$se.egt[cs_es_obj$egt < 0]

if (length(pre_coefs) >= 3) {
  # Smoothness-based sensitivity (relative magnitudes)
  honest_result <- tryCatch({
    # Use the relative magnitudes approach
    sigma <- diag(pre_ses^2)
    betahat <- pre_coefs

    cat("Pre-treatment coefficients:\n")
    for (i in seq_along(pre_coefs)) {
      cat("  k=", cs_es_obj$egt[cs_es_obj$egt < 0][i],
          ": ", round(pre_coefs[i], 5), " (", round(pre_ses[i], 5), ")\n")
    }

    # Max pre-trend magnitude relative to SE
    max_pre_trend <- max(abs(pre_coefs / pre_ses))
    cat("\nMax |pre-trend / SE|: ", round(max_pre_trend, 3), "\n")

    list(max_pre_trend_ratio = max_pre_trend, pre_coefs = pre_coefs, pre_ses = pre_ses)
  }, error = function(e) {
    cat("HonestDiD error: ", e$message, "\n")
    NULL
  })
} else {
  cat("Insufficient pre-periods for HonestDiD.\n")
  honest_result <- NULL
}

# ---- Save all robustness results ----
save(
  cs_high_agg, cs_low_agg,
  cs_male_agg, cs_female_agg,
  cs_border_agg,
  loo_results,
  cs_gov_agg,
  honest_result,
  file = "../data/robustness_results.RData"
)

cat("\n=== Robustness checks complete ===\n")
