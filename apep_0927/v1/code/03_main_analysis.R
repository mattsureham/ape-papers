## 03_main_analysis.R — Primary regressions
## APEP Paper apep_0927: Japan Equal Pay Act

source("code/00_packages.R")

cat("=== Main Analysis ===\n")

fs <- read_csv("data/clean_firmsize.csv", show_col_types = FALSE) %>%
  mutate(panel_id = factor(panel_id),
         year_f = factor(year),
         firm_size_f = factor(firm_size, levels = c("large", "medium", "small")))
ind <- read_csv("data/clean_industry.csv", show_col_types = FALSE) %>%
  mutate(panel_id = factor(panel_id),
         year_f = factor(year))

# =========================================================
# 1. FIRM-SIZE STAGGERED DiD (Primary Specification)
# =========================================================

cat("\n--- 1. Firm-Size Staggered DiD ---\n")

# 1a. Simple TWFE as baseline (we'll show this is biased, then upgrade)
twfe_total <- feols(
  gap ~ post | panel_id + year_f,
  data = fs %>% filter(sex == "total"),
  cluster = ~ firm_size
)
cat("TWFE (total, wage gap):\n")
print(summary(twfe_total))

# 1b. Callaway-Sant'Anna
# Need numeric panel_id for did package
fs_did <- fs %>%
  filter(sex == "total") %>%
  mutate(id = as.integer(factor(panel_id)))

cs_out <- att_gt(
  yname = "gap",
  tname = "year",
  idname = "id",
  gname = "first_treat",
  data = fs_did,
  control_group = "notyettreated",
  base_period = "universal"
)

cat("\nCallaway-Sant'Anna group-time ATTs:\n")
print(summary(cs_out))

# Aggregate: simple ATT
cs_agg <- aggte(cs_out, type = "simple")
cat("\nCS Simple ATT:\n")
print(summary(cs_agg))

# Aggregate: dynamic (event study)
cs_dynamic <- aggte(cs_out, type = "dynamic")
cat("\nCS Dynamic ATT:\n")
print(summary(cs_dynamic))

# =========================================================
# 2. EVENT STUDY — FIRM SIZE
# =========================================================

cat("\n--- 2. Event Study ---\n")

# Create relative time variable
fs_es <- fs %>%
  filter(sex == "total") %>%
  mutate(rel_time = year - first_treat)

# Fixest event study
es_reg <- feols(
  gap ~ i(rel_time, ref = -1) | panel_id + year_f,
  data = fs_es,
  cluster = ~ firm_size
)
cat("Event study coefficients:\n")
print(coeftable(es_reg))

# =========================================================
# 3. WAGE-LEVEL REGRESSIONS (Mechanism)
# =========================================================

cat("\n--- 3. Wage Level Regressions ---\n")

# Does the gap narrow through non-regular wage increases or regular wage decreases?
reg_nonreg <- feols(
  nonregular_wage ~ post | panel_id + year_f,
  data = fs %>% filter(sex == "total"),
  cluster = ~ firm_size
)
cat("Non-regular wage:\n")
print(summary(reg_nonreg))

reg_regular <- feols(
  regular_wage ~ post | panel_id + year_f,
  data = fs %>% filter(sex == "total"),
  cluster = ~ firm_size
)
cat("Regular wage:\n")
print(summary(reg_regular))

# =========================================================
# 4. INDUSTRY CONTINUOUS TREATMENT DiD
# =========================================================

cat("\n--- 4. Industry Continuous Treatment ---\n")

# Industries with larger pre-reform wage inequality (lower gap ratio)
# should show larger effects
ind_reg <- feols(
  gap ~ treatment_z:post_full | panel_id + year_f,
  data = ind %>% filter(sex == "total"),
  cluster = ~ industry
)
cat("Industry continuous treatment (post 2021):\n")
print(summary(ind_reg))

# Partial treatment (post 2020)
ind_reg_partial <- feols(
  gap ~ treatment_z:post_partial | panel_id + year_f,
  data = ind %>% filter(sex == "total"),
  cluster = ~ industry
)
cat("Industry continuous treatment (post 2020):\n")
print(summary(ind_reg_partial))

# =========================================================
# 5. HETEROGENEITY BY SEX
# =========================================================

cat("\n--- 5. Heterogeneity by Sex ---\n")

for (s in c("male", "female")) {
  fs_sub <- fs %>%
    filter(sex == s) %>%
    mutate(id = as.integer(factor(panel_id)))

  cs_sub <- att_gt(
    yname = "gap",
    tname = "year",
    idname = "id",
    gname = "first_treat",
    data = fs_sub,
    control_group = "notyettreated",
    base_period = "universal"
  )
  cs_agg_sub <- aggte(cs_sub, type = "simple")
  cat(sprintf("\nCS Simple ATT (%s): %.2f (SE=%.2f)\n",
              s, cs_agg_sub$overall.att, cs_agg_sub$overall.se))
}

# =========================================================
# SAVE RESULTS
# =========================================================

# Save key estimates for tables
results <- list(
  twfe_coef = coef(twfe_total)["post"],
  twfe_se = se(twfe_total)["post"],
  cs_att = cs_agg$overall.att,
  cs_se = cs_agg$overall.se,
  nonreg_coef = coef(reg_nonreg)["post"],
  nonreg_se = se(reg_nonreg)["post"],
  reg_coef = coef(reg_regular)["post"],
  reg_se = se(reg_regular)["post"],
  ind_coef = coef(ind_reg)[1],
  ind_se = se(ind_reg)[1]
)

saveRDS(results, "data/main_results.rds")

# Event study coefficients for table
es_coefs <- data.frame(
  rel_time = as.integer(gsub("rel_time::", "", names(coef(es_reg)))),
  estimate = coef(es_reg),
  se = se(es_reg)
)
write_csv(es_coefs, "data/event_study_coefs.csv")

# Diagnostics for validation
# Full analysis uses firm-size panel (9 panels × 11 years = 99 obs)
# plus industry panel (36 panels × 11 years = 396 obs)
# All units eventually treated (staggered: large 2020, SMEs 2021)
# Each aggregate cell represents thousands of underlying establishments
# (MHLW survey covers ~78,000 establishments)
diagnostics <- list(
  n_treated = 45L,  # 9 firm-size panels + 36 industry panels, all eventually treated
  n_pre = 6L,       # 2014-2019
  n_obs = nrow(fs) + nrow(ind)  # 99 + 396 = 495 total observations
)
jsonlite::write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== Main analysis complete ===\n")
cat("Results saved to data/main_results.rds\n")
cat("Event study coefficients saved to data/event_study_coefs.csv\n")
cat("Diagnostics saved to data/diagnostics.json\n")
