## 03_main_analysis.R — Main regressions
## APEP-0935: First Step Act Safety Valve and Judge Leniency

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

df <- readRDS(file.path(data_dir, "analysis_df.rds"))
stopifnot(nrow(df) > 0)

cat(sprintf("Analysis sample: %d observations\n", nrow(df)))

# ============================================================
# 1. Summary statistics
# ============================================================
cat("\n=== Summary Statistics ===\n")

summ_all <- df %>%
  summarise(
    n = n(),
    mean_sentence = mean(sentence_months, na.rm = TRUE),
    sd_sentence = sd(sentence_months, na.rm = TRUE),
    median_sentence = median(sentence_months, na.rm = TRUE),
    pct_black = mean(black, na.rm = TRUE),
    pct_hispanic = mean(hispanic, na.rm = TRUE),
    pct_female = mean(female, na.rm = TRUE),
    mean_age = mean(age, na.rm = TRUE),
    pct_safety_valve = mean(safety_valve, na.rm = TRUE),
    pct_has_mandmin = mean(has_mandatory_min, na.rm = TRUE),
    mean_crim_hist = mean(crim_hist, na.rm = TRUE)
  )
print(summ_all)

# Pre vs post comparison
summ_by_period <- df %>%
  group_by(post_fsa) %>%
  summarise(
    n = n(),
    mean_sentence = mean(sentence_months, na.rm = TRUE),
    sd_sentence = sd(sentence_months, na.rm = TRUE),
    pct_black = mean(black, na.rm = TRUE),
    pct_safety_valve = mean(safety_valve, na.rm = TRUE),
    .groups = "drop"
  )
cat("\nPre vs Post FSA:\n")
print(summ_by_period)

# Newly eligible vs already eligible
summ_by_elig <- df %>%
  group_by(newly_eligible, post_fsa) %>%
  summarise(
    n = n(),
    mean_sentence = mean(sentence_months, na.rm = TRUE),
    pct_safety_valve = mean(safety_valve, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(newly_eligible, post_fsa)
cat("\n2x2 DiD means:\n")
print(summ_by_elig)

# ============================================================
# 2. Main DiD specification
# ============================================================
cat("\n=== Main DiD Results ===\n")

# IMPORTANT: Restrict to CH 1-4 for clean DiD comparison
# CH 1 = already eligible (control), CH 2-4 = newly eligible (treatment)
df_did <- df %>% filter(crim_hist >= 1, crim_hist <= 4)
cat(sprintf("DiD sample (CH 1-4): %d observations\n", nrow(df_did)))

# Specification 1: Basic DiD with newly_eligible main effect
m1 <- feols(sentence_months ~ newly_eligible + treated |
              district + fiscal_year,
            data = df_did, cluster = ~district)

# Specification 2: DiD with defendant controls
m2 <- feols(sentence_months ~ newly_eligible + treated + black + hispanic +
              female + age + us_citizen + offense_level |
              district + fiscal_year,
            data = df_did, cluster = ~district)

# Specification 3: DiD with district x year FE
m3 <- feols(sentence_months ~ newly_eligible + treated + black + hispanic +
              female + age + us_citizen + offense_level |
              district^fiscal_year,
            data = df_did, cluster = ~district)

# Specification 4: With criminal history category FE
m4 <- feols(sentence_months ~ treated + black + hispanic + female +
              age + us_citizen + offense_level |
              district^fiscal_year + crim_hist,
            data = df_did, cluster = ~district)

cat("Model 1 (Basic DiD):\n")
summary(m1)
cat("\nModel 2 (+ Controls):\n")
summary(m2)
cat("\nModel 3 (District x Year FE):\n")
summary(m3)
cat("\nModel 4 (+ CH x Year FE):\n")
summary(m4)

# ============================================================
# 3. Safety valve usage (first stage)
# ============================================================
cat("\n=== Safety Valve Usage (First Stage) ===\n")

sv1 <- feols(safety_valve ~ newly_eligible + treated |
               district + fiscal_year,
             data = df_did, cluster = ~district)

sv2 <- feols(safety_valve ~ newly_eligible + treated + black + hispanic +
               female + age + us_citizen + offense_level |
               district^fiscal_year,
             data = df_did, cluster = ~district)

cat("Safety valve DiD:\n")
summary(sv1)
summary(sv2)

# ============================================================
# 4. Racial disparity analysis
# ============================================================
cat("\n=== Racial Disparity Analysis ===\n")

# Test whether FSA differentially reduced sentences for Black defendants
# among newly eligible
race_m1 <- feols(sentence_months ~ newly_eligible + treated * black + hispanic +
                   female + age + us_citizen + offense_level |
                   district^fiscal_year,
                 data = df_did, cluster = ~district)

race_sv <- feols(safety_valve ~ newly_eligible + treated * black + hispanic +
                   female + age + us_citizen + offense_level |
                   district^fiscal_year,
                 data = df_did, cluster = ~district)

cat("Racial interaction - sentences:\n")
summary(race_m1)
cat("\nRacial interaction - safety valve:\n")
summary(race_sv)

# ============================================================
# 5. District leniency heterogeneity
# ============================================================
cat("\n=== District Leniency Heterogeneity ===\n")

# Split by pre-FSA district leniency
# High-leniency districts should show larger sentence reductions
# for newly eligible because their judges were already predisposed
# to use the safety valve

len_m1 <- feols(sentence_months ~ newly_eligible + treated * high_leniency +
                  black + hispanic + female + age + us_citizen + offense_level |
                  district^fiscal_year,
                data = df_did, cluster = ~district)

cat("Leniency interaction:\n")
summary(len_m1)

# By tercile
for (t in 1:3) {
  m_t <- feols(sentence_months ~ newly_eligible + treated + black + hispanic +
                 female + age + us_citizen + offense_level |
                 district^fiscal_year,
               data = filter(df_did, leniency_tercile == t),
               cluster = ~district)
  cat(sprintf("\nLeniency tercile %d (n=%d):\n", t,
              sum(df_did$leniency_tercile == t, na.rm = TRUE)))
  cat(sprintf("  Treated coef: %.2f (SE: %.2f)\n",
              coef(m_t)["treated"], se(m_t)["treated"]))
}

# ============================================================
# 6. Event study (pre-trends test)
# ============================================================
cat("\n=== Event Study ===\n")

# Create event-time indicators
df_did <- df_did %>%
  mutate(
    event_year = fiscal_year - 2019  # FSA effective FY2019
  )

# Event study: newly eligible x year dummies (omit FY2018 = event_year -1)
es_m <- feols(sentence_months ~ i(event_year, newly_eligible, ref = -1) +
                black + hispanic + female + age + us_citizen + offense_level |
                district^fiscal_year + crim_hist,
              data = df_did, cluster = ~district)

cat("Event study coefficients:\n")
print(coeftable(es_m)[grep("event_year", rownames(coeftable(es_m))), ])

# ============================================================
# 7. Save key results for tables
# ============================================================
cat("\n=== Saving results ===\n")

# Store SD(Y) for SDE calculation
sd_sentence <- sd(df_did$sentence_months, na.rm = TRUE)
cat(sprintf("SD(sentence_months) = %.2f\n", sd_sentence))

results <- list(
  m1 = m1, m2 = m2, m3 = m3, m4 = m4,
  sv1 = sv1, sv2 = sv2,
  race_m1 = race_m1, race_sv = race_sv,
  len_m1 = len_m1,
  es_m = es_m,
  sd_sentence = sd_sentence,
  summ_all = summ_all,
  summ_by_period = summ_by_period,
  summ_by_elig = summ_by_elig
)

saveRDS(results, file.path(data_dir, "results.rds"))

# Write diagnostics.json for validator
n_districts <- n_distinct(df_did$district)
n_pre <- length(unique(df_did$fiscal_year[df_did$fiscal_year <= 2018]))
n_treated_units <- n_districts
n_obs <- nrow(df_did)

diagnostics <- list(
  n_treated = n_treated_units,
  n_pre = n_pre,
  n_obs = n_obs
)
jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE)
cat(sprintf("Diagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            n_treated_units, n_pre, n_obs))

cat("\n=== Main analysis complete ===\n")
