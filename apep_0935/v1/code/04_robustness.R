## 04_robustness.R — Robustness checks
## APEP-0935: First Step Act Safety Valve and Judge Leniency

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"

df <- readRDS(file.path(data_dir, "analysis_df.rds"))
# Restrict to CH 1-4 for clean DiD (matching 03_main_analysis.R)
df <- df %>% filter(crim_hist >= 1, crim_hist <= 4)
results <- readRDS(file.path(data_dir, "results.rds"))

cat("=== Robustness Checks ===\n")

# ============================================================
# 1. Placebo test: Already-eligible (CH I) should not respond
# ============================================================
cat("\n--- Placebo: CH I defendants (always eligible) ---\n")

# Create a "fake treatment" for CH I defendants
# If FSA only expanded eligibility, CH I defendants should show no effect
ch1_df <- df %>% filter(crim_hist == 1)

# Compare pre (FY2016-18) vs post (FY2019-24) for CH I only
# Use district FE only (not fiscal_year, which absorbs post_fsa)
placebo_m <- feols(sentence_months ~ post_fsa + black + hispanic + female +
                     age + us_citizen + offense_level |
                     district,
                   data = ch1_df, cluster = ~district)

cat(sprintf("  Placebo (CH I only): coef=%.2f, SE=%.2f, p=%.3f\n",
            coef(placebo_m)["post_fsa"],
            se(placebo_m)["post_fsa"],
            pvalue(placebo_m)["post_fsa"]))

# ============================================================
# 2. Excluding COVID period (FY2020-21)
# ============================================================
cat("\n--- Excluding COVID period ---\n")

no_covid <- df %>% filter(!fiscal_year %in% c(2020, 2021))

m_nocovid <- feols(sentence_months ~ newly_eligible + treated + black + hispanic +
                     female + age + us_citizen + offense_level |
                     district^fiscal_year,
                   data = no_covid, cluster = ~district)

cat(sprintf("  No-COVID: coef=%.2f, SE=%.2f\n",
            coef(m_nocovid)["treated"], se(m_nocovid)["treated"]))

# ============================================================
# 3. Alternative outcome: log(sentence + 1)
# ============================================================
cat("\n--- Log sentence ---\n")

df <- df %>% mutate(log_sentence = log(sentence_months + 1))

m_log <- feols(log_sentence ~ newly_eligible + treated + black + hispanic +
                 female + age + us_citizen + offense_level |
                 district^fiscal_year,
               data = df, cluster = ~district)

cat(sprintf("  Log spec: coef=%.3f, SE=%.3f\n",
            coef(m_log)["treated"], se(m_log)["treated"]))

# ============================================================
# 4. Pulsifer narrowing (FY2024 partial reversal)
# ============================================================
cat("\n--- Pulsifer reversal check ---\n")

# Pulsifer (March 2024) narrowed FSA safety valve eligibility
# FY2024 should show partial reversal of sentence reductions
if (2024 %in% df$fiscal_year) {
  post_df <- df %>% filter(fiscal_year >= 2019)

  post_df <- post_df %>%
    mutate(pulsifer = as.integer(fiscal_year >= 2024))

  m_puls <- feols(sentence_months ~ newly_eligible * pulsifer + black +
                    hispanic + female + age + us_citizen + offense_level |
                    district^fiscal_year,
                  data = post_df, cluster = ~district)

  cat(sprintf("  Pulsifer interaction: coef=%.2f, SE=%.2f\n",
              coef(m_puls)["newly_eligible:pulsifer"],
              se(m_puls)["newly_eligible:pulsifer"]))
} else {
  cat("  FY2024 data not available — skipping Pulsifer check\n")
}

# ============================================================
# 5. Drug type heterogeneity
# ============================================================
cat("\n--- Drug type heterogeneity ---\n")

drug_types <- df %>%
  filter(!is.na(DRUGTYP)) %>%
  count(DRUGTYP, sort = TRUE) %>%
  head(5)

cat("  Top drug types:\n")
print(drug_types)

for (dt in drug_types$DRUGTYP) {
  dt_df <- df %>% filter(DRUGTYP == dt)
  if (nrow(dt_df) < 200) next

  m_dt <- feols(sentence_months ~ treated + black + hispanic + female +
                  age + us_citizen + offense_level |
                  district + fiscal_year,
                data = dt_df, cluster = ~district)

  cat(sprintf("  Drug type %s (n=%d): coef=%.2f, SE=%.2f\n",
              as.character(dt), nrow(dt_df),
              coef(m_dt)["treated"], se(m_dt)["treated"]))
}

# ============================================================
# 6. Separate by gender
# ============================================================
cat("\n--- Gender heterogeneity ---\n")

for (g in c(0, 1)) {
  g_df <- df %>% filter(MONSEX == g)
  m_g <- feols(sentence_months ~ treated + black + hispanic +
                 age + us_citizen + offense_level |
                 district^fiscal_year,
               data = g_df, cluster = ~district)

  cat(sprintf("  %s (n=%d): coef=%.2f, SE=%.2f\n",
              ifelse(g == 0, "Male", "Female"), nrow(g_df),
              coef(m_g)["treated"], se(m_g)["treated"]))
}

# ============================================================
# 7. Save robustness results
# ============================================================
cat("\n=== Saving robustness results ===\n")

rob_results <- list(
  placebo_m = placebo_m,
  m_nocovid = m_nocovid,
  m_log = m_log,
  m_puls = if (exists("m_puls")) m_puls else NULL
)

saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))

cat("=== Robustness complete ===\n")
