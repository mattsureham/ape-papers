## 04_robustness.R — Robustness checks and mechanism tests
## Input: data/enoe_analysis.csv, data/main_models.RData
## Output: robustness estimates saved for tables

source("code/00_packages.R")

enoe <- fread("data/enoe_analysis.csv")
load("data/main_models.RData")

# ── Robustness 1: Narrower age window (16-20) ────────────────────
# Tighter window reduces confounding from lifecycle patterns
narrow <- enoe[eda >= 16 & eda <= 20]

r1_emp <- feols(employed ~ male_post18 + male + post18 |
                  age_factor + yq_factor + state,
                data = narrow, cluster = ~state)

r1_formal <- feols(formal ~ male_post18 + male + post18 |
                     age_factor + yq_factor + state,
                   data = narrow, cluster = ~state)

cat("Robustness 1 (narrow window 16-20):\n")
cat(sprintf("  Employment: β = %.4f (SE = %.4f)\n",
            coef(r1_emp)["male_post18"], se(r1_emp)["male_post18"]))
cat(sprintf("  Formal:     β = %.4f (SE = %.4f)\n",
            coef(r1_formal)["male_post18"], se(r1_formal)["male_post18"]))

# ── Robustness 2: Cohort fixed effects instead of age FEs ────────
r2_emp <- feols(employed ~ male_post18 + male + post18 |
                  cohort + yq_factor + state,
                data = enoe[!is.na(cohort)], cluster = ~state)

cat("\nRobustness 2 (cohort FE):\n")
cat(sprintf("  Employment: β = %.4f (SE = %.4f)\n",
            coef(r2_emp)["male_post18"], se(r2_emp)["male_post18"]))

# ── Robustness 3: Urban vs. Rural heterogeneity ──────────────────
# ENOE cd_a codes: 1-4 indicate different urbanization levels
# cd_a == 1: cities >= 100K, cd_a == 4: rural
enoe[, urban := as.integer(as.numeric(cd_a) <= 2)]

r3_urban <- feols(employed ~ male_post18 + male + post18 |
                    age_factor + yq_factor + state,
                  data = enoe[urban == 1], cluster = ~state)

r3_rural <- feols(employed ~ male_post18 + male + post18 |
                    age_factor + yq_factor + state,
                  data = enoe[urban == 0], cluster = ~state)

cat("\nRobustness 3 (urban/rural):\n")
cat(sprintf("  Urban employment: β = %.4f (SE = %.4f)\n",
            coef(r3_urban)["male_post18"], se(r3_urban)["male_post18"]))
cat(sprintf("  Rural employment: β = %.4f (SE = %.4f)\n",
            coef(r3_rural)["male_post18"], se(r3_rural)["male_post18"]))

# ── Robustness 4: Education controls ─────────────────────────────
# Adding education could absorb part of the treatment effect (bad control)
# but shows sensitivity
r4_emp <- feols(employed ~ male_post18 + male + post18 + educ_years |
                  age_factor + yq_factor + state,
                data = enoe[!is.na(educ_years)], cluster = ~state)

cat("\nRobustness 4 (controlling for education):\n")
cat(sprintf("  Employment: β = %.4f (SE = %.4f)\n",
            coef(r4_emp)["male_post18"], se(r4_emp)["male_post18"]))

# ── Mechanism: Salaried vs. Self-Employed Decomposition ──────────
# The cartilla militar channel predicts: service → more formal/salaried jobs
m_salaried <- feols(salaried ~ male_post18 + male + post18 |
                      age_factor + yq_factor + state,
                    data = enoe, cluster = ~state)

# Self-employed (informal pathway)
enoe[, self_employed := as.integer(pos_ocu == 2)]
enoe[is.na(pos_ocu) | employed == 0, self_employed := 0L]

m_selfemp <- feols(self_employed ~ male_post18 + male + post18 |
                     age_factor + yq_factor + state,
                   data = enoe, cluster = ~state)

cat("\nMechanism — Employment decomposition:\n")
cat(sprintf("  Salaried:      β = %.4f (SE = %.4f)\n",
            coef(m_salaried)["male_post18"], se(m_salaried)["male_post18"]))
cat(sprintf("  Self-employed: β = %.4f (SE = %.4f)\n",
            coef(m_selfemp)["male_post18"], se(m_selfemp)["male_post18"]))

# ── Placebo: Female-Only Age-18 Discontinuity ────────────────────
# If the jump at 18 is specific to males (lottery), there should be
# NO discontinuity for females beyond normal age trends
# Compare the age-17 to age-18 jump for each gender
f17 <- mean(enoe[male == 0 & eda == 17]$employed, na.rm = TRUE)
f18 <- mean(enoe[male == 0 & eda == 18]$employed, na.rm = TRUE)
m17 <- mean(enoe[male == 1 & eda == 17]$employed, na.rm = TRUE)
m18 <- mean(enoe[male == 1 & eda == 18]$employed, na.rm = TRUE)

# Also compute average year-on-year change for ages 15-17 (pre-treatment trend)
m_pre_trend <- (mean(enoe[male == 1 & eda == 17]$employed, na.rm = TRUE) -
                mean(enoe[male == 1 & eda == 15]$employed, na.rm = TRUE)) / 2
f_pre_trend <- (mean(enoe[male == 0 & eda == 17]$employed, na.rm = TRUE) -
                mean(enoe[male == 0 & eda == 15]$employed, na.rm = TRUE)) / 2

cat("\nPlacebo — Raw age 17→18 jumps:\n")
cat(sprintf("  Males:   %.4f → %.4f (Δ = %.4f, pre-trend = %.4f/yr)\n",
            m17, m18, m18 - m17, m_pre_trend))
cat(sprintf("  Females: %.4f → %.4f (Δ = %.4f, pre-trend = %.4f/yr)\n",
            f17, f18, f18 - f17, f_pre_trend))
cat(sprintf("  DiD at 18: %.4f\n", (m18 - m17) - (f18 - f17)))
cat(sprintf("  Male excess jump (vs own pre-trend): %.4f\n",
            (m18 - m17) - m_pre_trend))

# ── Save all robustness models ───────────────────────────────────
save(r1_emp, r1_formal, r2_emp, r3_urban, r3_rural, r4_emp,
     m_salaried, m_selfemp,
     file = "data/robustness_models.RData")

cat("\nAll robustness checks complete.\n")
