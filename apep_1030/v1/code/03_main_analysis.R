## 03_main_analysis.R — Primary regressions
## apep_1030: EU Deposit Return Schemes and Packaging Waste Recycling

source("00_packages.R")

df <- readRDS("../data/analysis_panel.rds")

# ---------------------------------------------------------------
# 0. Balance the panel for CS
# ---------------------------------------------------------------
cat("=== Preparing balanced panel ===\n")

# For CS: use Total recycling rate, exclude always-treated
# Use 2005-2022 window (drops early sparse years, captures most adopters)
# Drop countries without full coverage in this window

cs_data_all <- df %>%
  filter(material == "Total", !is.na(first_treat), !is.na(recycle_rate)) %>%
  filter(year >= 2005 & year <= 2022)

# Check which countries have full 2005-2022 coverage
yr_range <- 2005:2022
needed_n <- length(yr_range)

coverage <- cs_data_all %>%
  group_by(geo) %>%
  summarise(n_yrs = n(), .groups = "drop") %>%
  filter(n_yrs == needed_n)

cs_data <- cs_data_all %>%
  filter(geo %in% coverage$geo) %>%
  arrange(geo_id, year)

# For countries with first_treat <= 2005, they're "always treated" in this window
# Recode first_treat: if first_treat < 2005, set to NA (exclude from CS)
cs_data <- cs_data %>%
  mutate(first_treat_cs = case_when(
    first_treat == 0  ~ 0L,
    first_treat < 2005 ~ NA_integer_,   # always treated in 2005-2022 window
    first_treat > 2022 ~ 0L,            # not yet treated
    TRUE              ~ first_treat
  )) %>%
  filter(!is.na(first_treat_cs))

cat(sprintf("  Balanced CS panel: %d obs, %d countries, %d years (2005-2022)\n",
            nrow(cs_data), n_distinct(cs_data$geo), n_distinct(cs_data$year)))
cat("  Treated cohorts:",
    paste(sort(unique(cs_data$first_treat_cs[cs_data$first_treat_cs > 0])), collapse = ", "), "\n")
cat("  Never/not-yet-treated:", n_distinct(cs_data$geo[cs_data$first_treat_cs == 0]), "countries\n")

# ---------------------------------------------------------------
# 1. Callaway-Sant'Anna Staggered DiD
# ---------------------------------------------------------------
cat("\n=== CS Staggered DiD ===\n")

cs_out <- att_gt(
  yname     = "recycle_rate",
  tname     = "year",
  idname    = "geo_id",
  gname     = "first_treat_cs",
  data      = cs_data,
  control_group = "nevertreated",
  base_period   = "universal"
)

cat("\n  Group-time ATTs:\n")
print(summary(cs_out))

cs_es <- aggte(cs_out, type = "dynamic")
cat("\n  Event study (dynamic):\n")
print(summary(cs_es))

cs_att <- aggte(cs_out, type = "simple")
cat("\n  Simple ATT:\n")
print(summary(cs_att))

saveRDS(cs_out, "../data/cs_out.rds")
saveRDS(cs_es,  "../data/cs_es.rds")
saveRDS(cs_att, "../data/cs_att.rds")

# ---------------------------------------------------------------
# 2. Material-level DDD (fixest)
# ---------------------------------------------------------------
cat("\n=== Material-level DDD ===\n")

# Use all countries except always-treated, all years, targeted materials only
ddd_data <- df %>%
  filter(!is.na(targeted)) %>%
  filter(!is.na(first_treat)) %>%
  filter(!is.na(recycle_rate)) %>%
  mutate(targeted_num = as.numeric(targeted))

cat(sprintf("  DDD sample: %d obs, %d countries, %d materials, years %d-%d\n",
            nrow(ddd_data), n_distinct(ddd_data$geo), n_distinct(ddd_data$material),
            min(ddd_data$year), max(ddd_data$year)))

# DDD: interaction of drs_adopted (binary, absorbed by geo^year as main effect)
# with targeted_num (0/1, absorbed by geo^material and material^year)
# The interaction term varies in all 3 dimensions → identified

ddd_fit <- feols(
  recycle_rate ~ drs_adopted:targeted_num |
    geo^year + material^year + geo^material,
  data = ddd_data,
  cluster = ~geo
)

cat("\n  DDD results:\n")
print(summary(ddd_fit))

saveRDS(ddd_fit, "../data/ddd_fit.rds")
saveRDS(ddd_data, "../data/ddd_data.rds")

# ---------------------------------------------------------------
# 3. TWFE (for comparison)
# ---------------------------------------------------------------
cat("\n=== TWFE specification ===\n")

twfe_data <- df %>%
  filter(material == "Total", !is.na(first_treat), !is.na(recycle_rate))

twfe_fit <- feols(
  recycle_rate ~ drs_adopted | geo + year,
  data = twfe_data,
  cluster = ~geo
)

cat("  TWFE:\n")
print(summary(twfe_fit))

saveRDS(twfe_fit, "../data/twfe_fit.rds")

# ---------------------------------------------------------------
# 4. Sun-Abraham event study (fixest::sunab)
# ---------------------------------------------------------------
cat("\n=== Sun-Abraham event study ===\n")

sa_data <- cs_data %>%
  mutate(cohort = ifelse(first_treat_cs == 0, 10000L, first_treat_cs))

sa_fit <- feols(
  recycle_rate ~ sunab(cohort, year) | geo + year,
  data = sa_data,
  cluster = ~geo
)

cat("  Sun-Abraham:\n")
print(summary(sa_fit))

saveRDS(sa_fit, "../data/sa_fit.rds")

# ---------------------------------------------------------------
# 5. Material-specific DiD (TWFE by material)
# ---------------------------------------------------------------
cat("\n=== Material-specific DiD ===\n")

for (mat in c("Plastic", "Metal", "Paper", "Wood")) {
  mat_data <- df %>%
    filter(material == mat, !is.na(first_treat), !is.na(recycle_rate))

  mat_fit <- feols(
    recycle_rate ~ drs_adopted | geo + year,
    data = mat_data,
    cluster = ~geo
  )
  cat(sprintf("\n  %s (N=%d):\n", mat, nrow(mat_data)))
  print(summary(mat_fit))
  saveRDS(mat_fit, paste0("../data/twfe_", tolower(mat), ".rds"))
}

# ---------------------------------------------------------------
# 6. Diagnostics
# ---------------------------------------------------------------
cat("\n=== Writing diagnostics ===\n")

n_treated <- n_distinct(cs_data$geo[cs_data$first_treat_cs > 0])
n_pre <- cs_data %>%
  filter(first_treat_cs > 0) %>%
  group_by(geo) %>%
  summarise(n_pre = sum(year < first_treat_cs), .groups = "drop") %>%
  pull(n_pre) %>%
  min()
n_obs <- nrow(ddd_data)

jsonlite::write_json(
  list(n_treated = n_treated, n_pre = n_pre, n_obs = n_obs),
  "../data/diagnostics.json", auto_unbox = TRUE
)
cat(sprintf("  n_treated=%d, n_pre=%d, n_obs=%d\n", n_treated, n_pre, n_obs))

cat("\n=== Main analysis complete ===\n")
