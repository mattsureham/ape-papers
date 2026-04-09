# 03_main_analysis.R — Primary regressions
# APEP 1456: DPA Enforcement Intensity and Startup Survival

source("00_packages.R")
library(fixest)  # Fast fixed effects
library(did)     # Callaway-Sant'Anna

cat("=== Main analysis for APEP 1456 ===\n")

ict_panel <- readRDS("../data/ict_panel.rds")
first_enforcement <- readRDS("../data/first_enforcement.rds")

# ---------------------------------------------------------------
# Summary statistics
# ---------------------------------------------------------------
cat("\n--- Summary Statistics ---\n")

# Pre-enforcement period (2014-2017)
pre_stats <- ict_panel %>%
  filter(year >= 2014, year <= 2017) %>%
  summarise(
    n_countries = n_distinct(geo),
    mean_birth_rate = mean(birth_rate, na.rm = TRUE),
    sd_birth_rate = sd(birth_rate, na.rm = TRUE),
    mean_surv_1yr = mean(surv_1yr, na.rm = TRUE),
    sd_surv_1yr = sd(surv_1yr, na.rm = TRUE),
    mean_surv_3yr = mean(surv_3yr, na.rm = TRUE),
    sd_surv_3yr = sd(surv_3yr, na.rm = TRUE),
    mean_avg_size = mean(avg_size_births, na.rm = TRUE),
    sd_avg_size = sd(avg_size_births, na.rm = TRUE)
  )

cat("Pre-enforcement (2014-2017) ICT sector:\n")
print(pre_stats)

# ---------------------------------------------------------------
# A. Callaway-Sant'Anna DiD
# ---------------------------------------------------------------
cat("\n--- Callaway-Sant'Anna DiD ---\n")

# Prepare data: need numeric id, time, first_treat (0 = never treated)
cs_data <- ict_panel %>%
  filter(!is.na(surv_1yr), !is.na(cohort)) %>%
  mutate(
    id = as.integer(factor(geo)),
    first_treat = cohort
  ) %>%
  # Need balanced-ish panel: keep years where most countries have data
  filter(year >= 2013, year <= 2021)

cat(sprintf("CS-DiD sample: %d obs, %d countries, %d years\n",
            nrow(cs_data), n_distinct(cs_data$geo), n_distinct(cs_data$year)))

# Check: do we have never-treated countries?
never_treated <- cs_data %>% filter(first_treat == 0) %>% pull(geo) %>% unique()
cat(sprintf("Never-treated countries: %s\n", paste(never_treated, collapse = ", ")))

# Need sufficient never-treated for inference; otherwise use not-yet-treated
control_type <- ifelse(length(never_treated) >= 5, "nevertreated", "notyettreated")
cat(sprintf("Control group: %s\n", control_type))

# 1-year survival rate
cs_surv1 <- att_gt(
  yname = "surv_1yr",
  tname = "year",
  idname = "id",
  gname = "first_treat",
  data = cs_data,
  control_group = control_type,
  base_period = "universal"
)

cat("\nGroup-time ATTs (1-year survival):\n")
summary(cs_surv1)

# Aggregate to event-study
es_surv1 <- aggte(cs_surv1, type = "dynamic")
cat("\nEvent study (1-year survival):\n")
summary(es_surv1)

# Overall ATT
agg_surv1 <- aggte(cs_surv1, type = "simple")
cat("\nOverall ATT (1-year survival):\n")
summary(agg_surv1)

# Birth rate
cs_birth <- att_gt(
  yname = "birth_rate",
  tname = "year",
  idname = "id",
  gname = "first_treat",
  data = cs_data %>% filter(!is.na(birth_rate)),
  control_group = control_type,
  base_period = "universal"
)

es_birth <- aggte(cs_birth, type = "dynamic")
agg_birth <- aggte(cs_birth, type = "simple")

cat("\nOverall ATT (birth rate):\n")
summary(agg_birth)

# Average firm size at birth
cs_size <- att_gt(
  yname = "avg_size_births",
  tname = "year",
  idname = "id",
  gname = "first_treat",
  data = cs_data %>% filter(!is.na(avg_size_births)),
  control_group = control_type,
  base_period = "universal"
)

agg_size <- aggte(cs_size, type = "simple")
cat("\nOverall ATT (average firm size at birth):\n")
summary(agg_size)

# ---------------------------------------------------------------
# B. TWFE with fixest (comparison specification)
# ---------------------------------------------------------------
cat("\n--- TWFE Specifications ---\n")

twfe_data <- ict_panel %>%
  filter(year >= 2014, year <= 2021, !is.na(surv_1yr))

# Baseline: survival ~ post_enforcement + country FE + year FE
m1 <- feols(surv_1yr ~ post_enforcement | geo + year,
            data = twfe_data, cluster = ~geo)

# With controls
m2 <- feols(surv_1yr ~ post_enforcement + log_gdp + unemp_rate | geo + year,
            data = twfe_data, cluster = ~geo)

# Continuous treatment: cumulative fines per GDP
m3 <- feols(surv_1yr ~ cum_fines_per_gdp | geo + year,
            data = twfe_data, cluster = ~geo)

# Birth rate
m4 <- feols(birth_rate ~ post_enforcement | geo + year,
            data = twfe_data %>% filter(!is.na(birth_rate)), cluster = ~geo)

m5 <- feols(birth_rate ~ post_enforcement + log_gdp + unemp_rate | geo + year,
            data = twfe_data %>% filter(!is.na(birth_rate)), cluster = ~geo)

# Average size at birth
m6 <- feols(avg_size_births ~ post_enforcement | geo + year,
            data = twfe_data %>% filter(!is.na(avg_size_births)), cluster = ~geo)

cat("\nTWFE Results:\n")
etable(m1, m2, m3, m4, m5, m6,
       headers = c("Surv1yr", "Surv1yr+X", "Surv1yr(cont)",
                    "Birth", "Birth+X", "AvgSize"))

# ---------------------------------------------------------------
# C. Save results for table generation
# ---------------------------------------------------------------
results <- list(
  cs_surv1 = cs_surv1,
  es_surv1 = es_surv1,
  agg_surv1 = agg_surv1,
  cs_birth = cs_birth,
  es_birth = es_birth,
  agg_birth = agg_birth,
  cs_size = cs_size,
  agg_size = agg_size,
  twfe = list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5, m6 = m6),
  pre_stats = pre_stats
)

saveRDS(results, "../data/main_results.rds")

# ---------------------------------------------------------------
# D. Diagnostics for validate_v1.py
# ---------------------------------------------------------------
n_treated <- cs_data %>% filter(first_treat > 0) %>% pull(geo) %>% n_distinct()
n_pre <- cs_data %>% filter(year < 2018) %>% pull(year) %>% n_distinct()

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = nrow(cs_data)
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            n_treated, n_pre, nrow(cs_data)))

cat("=== Main analysis complete ===\n")
