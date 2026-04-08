## 04_robustness.R — Robustness checks and alternative specifications
source("00_packages.R")

cat("=== Robustness Checks ===\n")
df <- readRDS("../data/analysis_panel.rds")

# ---------------------------------------------------------------
# 1. Reduced Form: Bartik shock → outcomes directly
# ---------------------------------------------------------------
cat("\n--- Reduced Form ---\n")

rf_tuition <- feols(tuition_in_state ~ bartik_unemp | unitid + year,
                    data = df, cluster = ~state)
cat("RF: Bartik → Tuition\n")
summary(rf_tuition)

df_pell <- df |> filter(!is.na(pell_share))
rf_pell <- feols(pell_share ~ bartik_unemp | unitid + year,
                 data = df_pell, cluster = ~state)
cat("\nRF: Bartik → Pell share\n")
summary(rf_pell)

df_race <- df |> filter(!is.na(minority_share))
rf_minority <- feols(minority_share ~ bartik_unemp | unitid + year,
                     data = df_race, cluster = ~state)
cat("\nRF: Bartik → Minority share\n")
summary(rf_minority)

# ---------------------------------------------------------------
# 2. OLS with state-specific trends
# ---------------------------------------------------------------
cat("\n--- OLS with State Trends ---\n")

ols_tuition_trend <- feols(tuition_in_state ~ approp_per_fte | unitid + year + state[year],
                           data = df, cluster = ~state)
cat("OLS + state trends: Tuition\n")
summary(ols_tuition_trend)

ols_pell_trend <- feols(pell_share ~ approp_per_fte | unitid + year + state[year],
                        data = df_pell, cluster = ~state)
cat("\nOLS + state trends: Pell\n")
summary(ols_pell_trend)

# ---------------------------------------------------------------
# 3. Heterogeneity by institution type
# ---------------------------------------------------------------
cat("\n--- Heterogeneity by Institution Type ---\n")

# Research vs. non-research
df$research <- as.integer(df$inst_type == "Research")
df_pell$research <- as.integer(df_pell$inst_type == "Research")
df_race$research <- as.integer(df_race$inst_type == "Research")

het_tuition <- feols(tuition_in_state ~ approp_per_fte + approp_per_fte:research |
                       unitid + year,
                     data = df, cluster = ~state)
cat("Heterogeneity (tuition) — Research interaction:\n")
summary(het_tuition)

het_pell <- feols(pell_share ~ approp_per_fte + approp_per_fte:research |
                    unitid + year,
                  data = df_pell, cluster = ~state)
cat("\nHeterogeneity (Pell) — Research interaction:\n")
summary(het_pell)

# ---------------------------------------------------------------
# 4. Split sample: pre-recession vs post
# ---------------------------------------------------------------
cat("\n--- Pre vs Post Recession ---\n")

ols_pre <- feols(tuition_in_state ~ approp_per_fte | unitid + year,
                 data = df |> filter(year <= 2008), cluster = ~state)
ols_post <- feols(tuition_in_state ~ approp_per_fte | unitid + year,
                  data = df |> filter(year > 2008), cluster = ~state)
cat("Pre-recession (2004-2008): β =", round(coef(ols_pre), 4), "\n")
cat("Post-recession (2009-2022): β =", round(coef(ols_post), 4), "\n")

# ---------------------------------------------------------------
# 5. HBCU heterogeneity
# ---------------------------------------------------------------
cat("\n--- HBCU Heterogeneity ---\n")
df$hbcu_flag <- as.integer(df$hbcu == 1)

het_hbcu <- feols(pell_share ~ approp_per_fte + approp_per_fte:hbcu_flag |
                    unitid + year,
                  data = df_pell |> mutate(hbcu_flag = as.integer(hbcu == 1)),
                  cluster = ~state)
cat("HBCU interaction (Pell):\n")
summary(het_hbcu)

# ---------------------------------------------------------------
# 6. Save robustness results
# ---------------------------------------------------------------
rob <- list(
  rf_tuition = rf_tuition,
  rf_pell = rf_pell,
  rf_minority = rf_minority,
  ols_tuition_trend = ols_tuition_trend,
  ols_pell_trend = ols_pell_trend,
  het_tuition = het_tuition,
  het_pell = het_pell,
  ols_pre = ols_pre,
  ols_post = ols_post,
  het_hbcu = het_hbcu
)
saveRDS(rob, "../data/robustness_results.rds")

cat("\n=== Robustness complete ===\n")
