## 04_robustness.R — Robustness checks
## apep_0812: Pump Prices and Le Pen

source("00_packages.R")

data_dir <- "../data"
df <- readRDS(file.path(data_dir, "analysis_panel.rds"))

cat(sprintf("Analysis sample: %d communes\n", nrow(df)))

# ============================================================
# 1) PLACEBO OUTCOMES
# ============================================================
cat("\n=== Placebo Outcomes ===\n")

# Turnout change (should not respond to car commuting)
m_turnout <- feols(delta_turnout_17_12 ~ car_share_11 | dept,
                   cluster = ~dept, data = df)
cat(sprintf("  Turnout: β = %.4f (se = %.4f), t = %.2f\n",
            coef(m_turnout)["car_share_11"], se(m_turnout)["car_share_11"],
            coef(m_turnout)["car_share_11"] / se(m_turnout)["car_share_11"]))

# Mélenchon change (left-populist — might also respond)
m_melenchon <- feols(delta_melenchon_17_12 ~ car_share_11 | dept,
                     cluster = ~dept, data = df)
cat(sprintf("  Mélenchon: β = %.4f (se = %.4f), t = %.2f\n",
            coef(m_melenchon)["car_share_11"], se(m_melenchon)["car_share_11"],
            coef(m_melenchon)["car_share_11"] / se(m_melenchon)["car_share_11"]))

# ============================================================
# 2) QUARTILE TREATMENT
# ============================================================
cat("\n=== Quartile Treatment ===\n")

df$car_q_f <- factor(df$car_q)
m_q <- feols(delta_lepen_17_12 ~ car_q_f | dept, cluster = ~dept, data = df)
cat("  Quartile effects (vs Q1):\n")
for (q in 2:4) {
  nm <- paste0("car_q_f", q)
  cat(sprintf("    Q%d: β = %.3f (se = %.3f)\n", q, coef(m_q)[nm], se(m_q)[nm]))
}

# ============================================================
# 3) DROP ÎLE-DE-FRANCE
# ============================================================
cat("\n=== Drop Île-de-France ===\n")

df_no_idf <- df %>% filter(!ile_de_france)
m_no_idf <- feols(delta_lepen_17_12 ~ car_share_11 + log_pop + median_income |
                    dept, cluster = ~dept, data = df_no_idf)
cat(sprintf("  Without IDF (%d communes): β = %.4f (se = %.4f)\n",
            nrow(df_no_idf), coef(m_no_idf)["car_share_11"],
            se(m_no_idf)["car_share_11"]))

# ============================================================
# 4) INCOME HETEROGENEITY
# ============================================================
cat("\n=== Income Heterogeneity ===\n")

df$low_income <- df$median_income < median(df$median_income, na.rm = TRUE)
m_low <- feols(delta_lepen_17_12 ~ car_share_11 | dept,
               cluster = ~dept, data = df %>% filter(low_income))
m_high <- feols(delta_lepen_17_12 ~ car_share_11 | dept,
                cluster = ~dept, data = df %>% filter(!low_income))

cat(sprintf("  Low income: β = %.4f (se = %.4f)\n",
            coef(m_low)["car_share_11"], se(m_low)["car_share_11"]))
cat(sprintf("  High income: β = %.4f (se = %.4f)\n",
            coef(m_high)["car_share_11"], se(m_high)["car_share_11"]))

# ============================================================
# 5) CONLEY SPATIAL HAC
# ============================================================
cat("\n=== Conley Spatial HAC ===\n")

# Need commune centroids — use département-level approximation
# (Full commune coordinates would require separate shapefile)
# For now, cluster at département as primary inference
cat("  Primary inference: département-clustered SEs (96 clusters)\n")
cat("  Conley spatial HAC deferred (requires commune centroids)\n")

# ============================================================
# Save robustness models
# ============================================================
rob_models <- list(
  m_turnout = m_turnout,
  m_melenchon = m_melenchon,
  m_q = m_q,
  m_no_idf = m_no_idf,
  m_low_income = m_low,
  m_high_income = m_high
)
saveRDS(rob_models, file.path(data_dir, "robustness_models.rds"))
cat("\nRobustness models saved.\n")
