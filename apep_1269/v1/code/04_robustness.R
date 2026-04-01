## 04_robustness.R — Robustness checks and placebo tests
## APEP Paper: Mexico's Sorteo Militar and Youth Crime

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"

df <- fread(file.path(data_dir, "analysis_panel.csv"))
df[, EDAD := as.numeric(EDAD)]
df[, age_f := factor(EDAD)]
df[, state := as.integer(CVE_ENT)]

cat("=== ROBUSTNESS CHECKS ===\n\n")

# ============================================================
# 1. Placebo test: Female × Age 18-19 (should be zero)
# ============================================================
cat("--- Placebo: Female × Age 18-19 ---\n")
df[, female_18_19 := as.integer(male == 0 & EDAD >= 18 & EDAD <= 19)]

m_placebo <- feols(victim ~ female_18_19 | male + age_f + state^survey_year,
                    data = df, cluster = ~state)
cat("Female × Age 18-19 coefficient:", round(coef(m_placebo)["female_18_19"], 4),
    "(SE:", round(se(m_placebo)["female_18_19"], 4), ")\n")

m_placebo_v <- feols(victim_violent ~ female_18_19 | male + age_f + state^survey_year,
                      data = df, cluster = ~state)
cat("Female × Age 18-19 (violent):", round(coef(m_placebo_v)["female_18_19"], 4),
    "(SE:", round(se(m_placebo_v)["female_18_19"], 4), ")\n")

# ============================================================
# 2. Alternative age windows
# ============================================================
cat("\n--- Alternative treatment windows ---\n")

# Narrow: only age 18 (just entered lottery)
df[, male_18 := as.integer(male == 1 & EDAD == 18)]
m_18 <- feols(victim ~ male_18 | male + age_f + state^survey_year,
              data = df, cluster = ~state)

# Broader: ages 18-20 (including recent finishers)
df[, male_18_20 := as.integer(male == 1 & EDAD >= 18 & EDAD <= 20)]
m_18_20 <- feols(victim ~ male_18_20 | male + age_f + state^survey_year,
                  data = df, cluster = ~state)

cat("Male × Age 18 only:", round(coef(m_18)["male_18"], 4),
    "(SE:", round(se(m_18)["male_18"], 4), ")\n")
cat("Male × Age 18-20:", round(coef(m_18_20)["male_18_20"], 4),
    "(SE:", round(se(m_18_20)["male_18_20"], 4), ")\n")

# ============================================================
# 3. Weighted analysis (survey weights)
# ============================================================
cat("\n--- Survey-weighted analysis ---\n")

# Using FAC_ELE (person-level expansion factor) as weight
df[, wt := as.numeric(FAC_ELE)]
df[is.na(wt) | wt <= 0, wt := 1]

m_wt <- feols(victim ~ male_18_19 | male + age_f + state^survey_year,
              data = df, weights = ~wt, cluster = ~state)
cat("Weighted Male × Age 18-19:", round(coef(m_wt)["male_18_19"], 4),
    "(SE:", round(se(m_wt)["male_18_19"], 4), ")\n")

m_wt_v <- feols(victim_violent ~ male_18_19 | male + age_f + state^survey_year,
                data = df, weights = ~wt, cluster = ~state)
cat("Weighted (violent):", round(coef(m_wt_v)["male_18_19"], 4),
    "(SE:", round(se(m_wt_v)["male_18_19"], 4), ")\n")

# ============================================================
# 4. Placebo crime types (fraud — should NOT be affected by Saturday service)
# ============================================================
cat("\n--- Placebo outcome: Fraud ---\n")

df[, victim_fraud := as.integer(n_fraud > 0)]
m_fraud <- feols(victim_fraud ~ male_18_19 | male + age_f + state^survey_year,
                  data = df, cluster = ~state)
cat("Male × Age 18-19 on fraud:", round(coef(m_fraud)["male_18_19"], 4),
    "(SE:", round(se(m_fraud)["male_18_19"], 4), ")\n")

# ============================================================
# 5. Wald test: male_18_19 = male_22_25?
# ============================================================
cat("\n--- Wald test: 18-19 vs 22-25 ---\n")

df[, male_22_25 := as.integer(male == 1 & EDAD >= 22 & EDAD <= 25)]

m_wald_v <- feols(victim_violent ~ male_18_19 + male_22_25 | male + age_f + state^survey_year,
                   data = df, cluster = ~state)

# Test if coefficients are equal
tryCatch({
  wald_result <- wald(m_wald_v, "male_18_19 = male_22_25")
  cat("Wald test p-value:", round(wald_result$p, 3), "\n")
}, error = function(e) {
  cat("Wald test: coefficients are",
      round(coef(m_wald_v)["male_18_19"], 4), "vs",
      round(coef(m_wald_v)["male_22_25"], 4), "\n")
})

# ============================================================
# 6. By year (stability check)
# ============================================================
cat("\n--- Year-by-year estimates ---\n")

for (yr in 2021:2024) {
  m_yr <- feols(victim ~ male_18_19 | male + age_f + state,
                data = df[survey_year == yr], cluster = ~state)
  cat("Year", yr, ":", round(coef(m_yr)["male_18_19"], 4),
      "(SE:", round(se(m_yr)["male_18_19"], 4), ")\n")
}

cat("\n=== Power calculation ===\n")
# What effect could we detect?
n_treated <- nrow(df[male_18_19 == 1])
n_control <- nrow(df[male_18_19 == 0])
se_main <- 0.0177  # from main spec
mde <- 2.8 * se_main  # MDE at 80% power, 5% level
cat("Treatment group (Male 18-19):", n_treated, "\n")
cat("SE of main estimate:", se_main, "\n")
cat("MDE at 80% power:", round(mde, 3), "\n")
cat("MDE as % of mean victimization:", round(mde / mean(df$victim) * 100, 1), "%\n")
cat("MDE for ITT implies LATE of:", round(mde / 0.4, 3),
    "(assuming 40% compliance)\n")

cat("\nRobustness checks complete.\n")
