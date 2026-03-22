# 04_robustness.R — Robustness checks and heterogeneity
# apep_0756: Fair Workweek, Unfair Turnover?

source("00_packages.R")

df <- readRDS("../data/panel_main.rds")
results <- readRDS("../data/main_results.rds")

# ══════════════════════════════════════════════════════════════════════════════
# 1. Exclude COVID-era cohorts (Philadelphia 2020Q1, Chicago 2020Q3)
# ══════════════════════════════════════════════════════════════════════════════
cat("=== Robustness 1: Exclude COVID-era cohorts ===\n")

df_pre_covid <- df %>%
  filter(!(fips %in% c("42101", "17031")))  # Drop Philly and Cook County

rob_sep_nocovid <- feols(
  sep_rate ~ ddd | fips^industry + industry^t_int + fips^t_int,
  data = df_pre_covid,
  cluster = ~fips
)

rob_hire_nocovid <- feols(
  hire_rate ~ ddd | fips^industry + industry^t_int + fips^t_int,
  data = df_pre_covid,
  cluster = ~fips
)

cat("Separation rate (no COVID cohorts):", coef(rob_sep_nocovid)["ddd"], "\n")
cat("Hire rate (no COVID cohorts):", coef(rob_hire_nocovid)["ddd"], "\n")

# ══════════════════════════════════════════════════════════════════════════════
# 2. Alternative control industries
# ══════════════════════════════════════════════════════════════════════════════
cat("\n=== Robustness 2: Alternative control industries ===\n")

# Manufacturing only as control
df_mfg <- df %>% filter(industry %in% c("72", "44-45", "31-33"))
rob_sep_mfg <- feols(
  sep_rate ~ ddd | fips^industry + industry^t_int + fips^t_int,
  data = df_mfg,
  cluster = ~fips
)

# Professional services only as control
df_prof <- df %>% filter(industry %in% c("72", "44-45", "54"))
rob_sep_prof <- feols(
  sep_rate ~ ddd | fips^industry + industry^t_int + fips^t_int,
  data = df_prof,
  cluster = ~fips
)

cat("Sep rate (Manufacturing control):", coef(rob_sep_mfg)["ddd"], "\n")
cat("Sep rate (Professional control):", coef(rob_sep_prof)["ddd"], "\n")

# ══════════════════════════════════════════════════════════════════════════════
# 3. Pure DD (treated industries only, treated vs untreated counties)
# ══════════════════════════════════════════════════════════════════════════════
cat("\n=== Robustness 3: Pure DD (treated industries only) ===\n")

df_dd <- df %>%
  filter(treated_industry == 1)

# TWFE DD with county + quarter FE
dd_sep <- feols(
  sep_rate ~ dd_county_post | fips + t_int,
  data = df_dd,
  cluster = ~fips
)

dd_hire <- feols(
  hire_rate ~ dd_county_post | fips + t_int,
  data = df_dd,
  cluster = ~fips
)

cat("DD Separation rate:", coef(dd_sep)["dd_county_post"], "\n")
cat("DD Hire rate:", coef(dd_hire)["dd_county_post"], "\n")

# ══════════════════════════════════════════════════════════════════════════════
# 4. Callaway-Sant'Anna on treated industries (heterogeneity-robust)
# ══════════════════════════════════════════════════════════════════════════════
cat("\n=== Robustness 4: Callaway-Sant'Anna ===\n")

# Prepare CS data
df_cs <- df_dd %>%
  mutate(county_id = as.integer(factor(fips))) %>%
  group_by(fips) %>%
  filter(n() >= 20) %>%
  ungroup()

cs_sep <- tryCatch({
  att_gt(
    yname = "sep_rate",
    tname = "t_int",
    idname = "county_id",
    gname = "first_treat_int",
    data = as.data.frame(df_cs),
    control_group = "nevertreated",
    anticipation = 0,
    base_period = "varying"
  )
}, error = function(e) {
  cat("CS estimation error:", e$message, "\n")
  NULL
})

if (!is.null(cs_sep)) {
  cs_agg_sep <- aggte(cs_sep, type = "simple")
  cat("CS ATT (separation rate):", cs_agg_sep$overall.att,
      " SE:", cs_agg_sep$overall.se, "\n")
  cs_es_sep <- aggte(cs_sep, type = "dynamic", min_e = -8, max_e = 8)
  cat("CS event study computed.\n")
} else {
  cs_agg_sep <- NULL
  cs_es_sep <- NULL
}

cs_hire <- tryCatch({
  att_gt(
    yname = "hire_rate",
    tname = "t_int",
    idname = "county_id",
    gname = "first_treat_int",
    data = as.data.frame(df_cs),
    control_group = "nevertreated",
    anticipation = 0,
    base_period = "varying"
  )
}, error = function(e) {
  cat("CS estimation error:", e$message, "\n")
  NULL
})

cs_agg_hire <- NULL
if (!is.null(cs_hire)) {
  cs_agg_hire <- aggte(cs_hire, type = "simple")
  cat("CS ATT (hire rate):", cs_agg_hire$overall.att,
      " SE:", cs_agg_hire$overall.se, "\n")
}

# ══════════════════════════════════════════════════════════════════════════════
# 5. Placebo: control industries only (should show null DDD)
# ══════════════════════════════════════════════════════════════════════════════
cat("\n=== Robustness 5: Placebo (control industries as 'treated') ===\n")

df_placebo <- df %>%
  mutate(
    treated_industry_placebo = as.integer(industry %in% c("31-33")),
    ddd_placebo = treated_county * treated_industry_placebo * post
  )

placebo_sep <- feols(
  sep_rate ~ ddd_placebo | fips^industry + industry^t_int + fips^t_int,
  data = df_placebo,
  cluster = ~fips
)

cat("Placebo DDD (manufacturing as 'treated'):", coef(placebo_sep)["ddd_placebo"], "\n")
cat("Placebo p-value:", fixest::pvalue(placebo_sep)["ddd_placebo"], "\n")

# ══════════════════════════════════════════════════════════════════════════════
# Save all robustness results
# ══════════════════════════════════════════════════════════════════════════════
rob_results <- list(
  nocovid_sep = rob_sep_nocovid,
  nocovid_hire = rob_hire_nocovid,
  mfg_control = rob_sep_mfg,
  prof_control = rob_sep_prof,
  dd_sep = dd_sep,
  dd_hire = dd_hire,
  cs_sep = cs_sep,
  cs_agg_sep = cs_agg_sep,
  cs_es_sep = cs_es_sep,
  cs_hire = cs_hire,
  cs_agg_hire = cs_agg_hire,
  placebo_sep = placebo_sep
)

saveRDS(rob_results, "../data/robustness_results.rds")
cat("\nAll robustness results saved.\n")
