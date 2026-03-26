## 03_main_analysis.R — Main DiD estimation
## apep_0976: Yakuza Exclusion Ordinances and Real Estate Markets

source("00_packages.R")
load("../data/analysis_panel.RData")

cat("Panel: ", nrow(analysis), " obs, ", n_distinct(analysis$pref_code),
    " prefectures, ", min(analysis$fy), "-", max(analysis$fy), "\n")

# ══════════════════════════════════════════════════════════════════════
# 1. TWFE Estimates (baseline)
# ══════════════════════════════════════════════════════════════════════
cat("\n=== TWFE Estimates ===\n")

# Primary outcome: log land prices
twfe_land <- feols(log_land_price ~ treated | pref_id + fy,
                   data = analysis, cluster = ~pref_id)
cat("\nLog residential land price:\n")
print(summary(twfe_land))

# Secondary: crime rate
twfe_crime <- feols(crime_rate ~ treated | pref_id + fy,
                    data = analysis, cluster = ~pref_id)
cat("\nCrime rate (per 1000):\n")
print(summary(twfe_crime))

# Violent crime
twfe_violent <- feols(violent_crime_rate ~ treated | pref_id + fy,
                      data = analysis, cluster = ~pref_id)
cat("\nViolent crime rate (per 1000):\n")
print(summary(twfe_violent))

# Rough/assault crime
twfe_rough <- feols(rough_crime_rate ~ treated | pref_id + fy,
                    data = analysis, cluster = ~pref_id)
cat("\nRough crime rate (per 1000):\n")
print(summary(twfe_rough))

# Building starts
twfe_build <- feols(log_building_starts ~ treated | pref_id + fy,
                    data = analysis, cluster = ~pref_id)
cat("\nLog building starts:\n")
print(summary(twfe_build))

# Land price change rate
twfe_chg <- feols(land_price_change_pct ~ treated | pref_id + fy,
                  data = analysis, cluster = ~pref_id)
cat("\nLand price change (%):\n")
print(summary(twfe_chg))

# ══════════════════════════════════════════════════════════════════════
# 2. Sun-Abraham Event Study (heterogeneity-robust)
# ══════════════════════════════════════════════════════════════════════
cat("\n=== Sun-Abraham Event Study ===\n")

# Need event time indicators. Using fixest::sunab()
# Reference period: event_time == -1
sa_land <- feols(log_land_price ~ sunab(cohort, fy) | pref_id + fy,
                 data = analysis, cluster = ~pref_id)
cat("\nSun-Abraham: Log land price\n")
print(summary(sa_land))

sa_crime <- feols(crime_rate ~ sunab(cohort, fy) | pref_id + fy,
                  data = analysis, cluster = ~pref_id)
cat("\nSun-Abraham: Crime rate\n")
print(summary(sa_crime))

sa_rough <- feols(rough_crime_rate ~ sunab(cohort, fy) | pref_id + fy,
                  data = analysis, cluster = ~pref_id)
cat("\nSun-Abraham: Rough crime rate\n")
print(summary(sa_rough))

# ══════════════════════════════════════════════════════════════════════
# 3. Callaway-Sant'Anna DiD
# ══════════════════════════════════════════════════════════════════════
cat("\n=== Callaway-Sant'Anna DiD ===\n")

# CS DiD requires: yname, tname, idname, gname
# Since all units are eventually treated, use not-yet-treated as control
cs_land <- att_gt(
  yname = "log_land_price",
  tname = "fy",
  idname = "pref_id",
  gname = "first_treat",
  data = analysis,
  control_group = "notyettreated",
  base_period = "varying"
)
cat("\nCS ATT(g,t) for log land price:\n")
print(summary(cs_land))

# Aggregate to event study
cs_land_es <- aggte(cs_land, type = "dynamic", min_e = -5, max_e = 8)
cat("\nCS Event Study (land price):\n")
print(summary(cs_land_es))

# Overall ATT
cs_land_att <- aggte(cs_land, type = "simple")
cat("\nCS Overall ATT (land price):\n")
print(summary(cs_land_att))

# Crime rate
cs_crime <- att_gt(
  yname = "crime_rate",
  tname = "fy",
  idname = "pref_id",
  gname = "first_treat",
  data = analysis,
  control_group = "notyettreated",
  base_period = "varying"
)
cs_crime_att <- aggte(cs_crime, type = "simple")
cat("\nCS Overall ATT (crime rate):\n")
print(summary(cs_crime_att))

cs_crime_es <- aggte(cs_crime, type = "dynamic", min_e = -5, max_e = 8)

# Rough crime
cs_rough <- att_gt(
  yname = "rough_crime_rate",
  tname = "fy",
  idname = "pref_id",
  gname = "first_treat",
  data = analysis,
  control_group = "notyettreated",
  base_period = "varying"
)
cs_rough_att <- aggte(cs_rough, type = "simple")
cat("\nCS Overall ATT (rough crime rate):\n")
print(summary(cs_rough_att))

# Building starts
cs_build <- att_gt(
  yname = "log_building_starts",
  tname = "fy",
  idname = "pref_id",
  gname = "first_treat",
  data = analysis,
  control_group = "notyettreated",
  base_period = "varying"
)
cs_build_att <- aggte(cs_build, type = "simple")
cat("\nCS Overall ATT (log building starts):\n")
print(summary(cs_build_att))

# ══════════════════════════════════════════════════════════════════════
# 4. Heterogeneity: High vs Low yakuza presence
# ══════════════════════════════════════════════════════════════════════
cat("\n=== Heterogeneity by Baseline Crime ===\n")

# Split prefectures by pre-treatment (2005-2009) rough crime rate
# Rough crime (粗暴犯) includes assault, intimidation — most yakuza-related
pre_crime <- analysis %>%
  filter(fy >= 2005, fy <= 2009) %>%
  group_by(pref_code) %>%
  summarise(pre_rough = mean(rough_crime_rate, na.rm = TRUE), .groups = "drop")

median_rough <- median(pre_crime$pre_rough)
high_crime_prefs <- pre_crime$pref_code[pre_crime$pre_rough >= median_rough]

analysis <- analysis %>%
  mutate(high_crime = as.integer(pref_code %in% high_crime_prefs))

# TWFE with interaction
het_land <- feols(log_land_price ~ treated * high_crime | pref_id + fy,
                  data = analysis, cluster = ~pref_id)
cat("\nLand price heterogeneity (high vs low baseline crime):\n")
print(summary(het_land))

het_crime <- feols(crime_rate ~ treated * high_crime | pref_id + fy,
                   data = analysis, cluster = ~pref_id)
cat("\nCrime rate heterogeneity:\n")
print(summary(het_crime))

# Sample splits for SDE table
land_high <- feols(log_land_price ~ treated | pref_id + fy,
                   data = filter(analysis, high_crime == 1),
                   cluster = ~pref_id)
land_low <- feols(log_land_price ~ treated | pref_id + fy,
                  data = filter(analysis, high_crime == 0),
                  cluster = ~pref_id)

crime_high <- feols(crime_rate ~ treated | pref_id + fy,
                    data = filter(analysis, high_crime == 1),
                    cluster = ~pref_id)
crime_low <- feols(crime_rate ~ treated | pref_id + fy,
                   data = filter(analysis, high_crime == 0),
                   cluster = ~pref_id)

cat("\nLand price effect, high-crime prefectures:", coef(land_high)["treated"], "\n")
cat("Land price effect, low-crime prefectures:", coef(land_low)["treated"], "\n")
cat("Crime effect, high-crime prefectures:", coef(crime_high)["treated"], "\n")
cat("Crime effect, low-crime prefectures:", coef(crime_low)["treated"], "\n")

# ══════════════════════════════════════════════════════════════════════
# 5. Write diagnostics.json
# ══════════════════════════════════════════════════════════════════════
diagnostics <- list(
  n_treated = n_distinct(analysis$pref_code[analysis$treated == 1]),
  n_pre = length(unique(analysis$fy[analysis$fy < 2010])),
  n_obs = nrow(analysis),
  n_prefectures = n_distinct(analysis$pref_code),
  cohorts = as.list(table(yeo_dates$first_treat)),
  twfe_land_coef = as.numeric(coef(twfe_land)["treated"]),
  twfe_land_se = as.numeric(se(twfe_land)["treated"]),
  cs_land_att = cs_land_att$overall.att,
  cs_land_se = cs_land_att$overall.se
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\n✓ diagnostics.json written\n")

# Save all model objects
save(twfe_land, twfe_crime, twfe_violent, twfe_rough, twfe_build, twfe_chg,
     sa_land, sa_crime, sa_rough,
     cs_land, cs_crime, cs_rough, cs_build,
     cs_land_es, cs_crime_es,
     cs_land_att, cs_crime_att, cs_rough_att, cs_build_att,
     het_land, het_crime,
     land_high, land_low, crime_high, crime_low,
     analysis, summ, yeo_dates,
     file = "../data/models.RData")
cat("✓ All model objects saved to data/models.RData\n")
