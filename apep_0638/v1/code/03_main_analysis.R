## 03_main_analysis.R — Primary regressions
## The Saturday Soldier: Male-female age-profile DiD
## Input: data/enoe_analysis.csv
## Output: estimates saved for tables

source("code/00_packages.R")

enoe <- fread("data/enoe_analysis.csv")
cat(sprintf("Loaded %s observations\n", format(nrow(enoe), big.mark = ",")))

# ── Table 1: Male-Female Gap by Single Age ────────────────────────
# This is the key descriptive evidence: the gap should be stable pre-18
# and shift at age 18

age_gaps <- enoe[, .(
  male_emp   = mean(employed[male == 1], na.rm = TRUE),
  female_emp = mean(employed[male == 0], na.rm = TRUE),
  male_formal   = mean(formal[male == 1], na.rm = TRUE),
  female_formal = mean(formal[male == 0], na.rm = TRUE),
  male_earnings   = mean(earnings_cond[male == 1], na.rm = TRUE),
  female_earnings = mean(earnings_cond[male == 0], na.rm = TRUE),
  n_male   = sum(male == 1),
  n_female = sum(male == 0)
), by = eda]
age_gaps[, emp_gap := male_emp - female_emp]
age_gaps[, formal_gap := male_formal - female_formal]
age_gaps[, earnings_gap := male_earnings - female_earnings]
age_gaps <- age_gaps[order(eda)]

cat("\n=== Male-Female Employment Gap by Age ===\n")
print(age_gaps[, .(age = eda, male_emp, female_emp, gap = round(emp_gap, 4),
                   n_male, n_female)])

# Save for table generation
fwrite(age_gaps, "data/age_gaps.csv")

# ── Main Specification: Event Study ───────────────────────────────
# Y_igt = Σ_a β_a(Male × I(Age=a)) + α_age + δ_yq + γ_state + ε
# Reference age: 17 (last pre-lottery year)

# Create interaction dummies for event study
# age_rel = eda - 18, so reference is age_rel = -1 (age 17)
enoe[, age_rel_f := factor(age_rel)]
# Relevel to make age 17 (age_rel = -1) the reference
enoe[, age_rel_f := relevel(age_rel_f, ref = "-1")]

cat("\n=== Event Study: Employment ===\n")
es_emp <- feols(employed ~ male:age_rel_f + age_rel_f |
                  yq_factor + state,
                data = enoe,
                cluster = ~state)
cat("Event study (employment) estimated.\n")

cat("\n=== Event Study: Formal Employment ===\n")
es_formal <- feols(formal ~ male:age_rel_f + age_rel_f |
                     yq_factor + state,
                   data = enoe,
                   cluster = ~state)
cat("Event study (formal) estimated.\n")

# ── Main DiD: Male × Post18 ──────────────────────────────────────
# Simple specification: does the male-female gap shift at age 18?

cat("\n=== Main DiD: Male × Post18 ===\n")

# (1) Employment, no controls
m1 <- feols(employed ~ male_post18 + male + post18 |
              age_factor + yq_factor + state,
            data = enoe, cluster = ~state)

# (2) Formal employment
m2 <- feols(formal ~ male_post18 + male + post18 |
              age_factor + yq_factor + state,
            data = enoe, cluster = ~state)

# (3) Log earnings (conditional on employment)
m3 <- feols(ln_earnings ~ male_post18 + male + post18 |
              age_factor + yq_factor + state,
            data = enoe[!is.na(ln_earnings)], cluster = ~state)

# (4) Weekly hours (conditional on employment)
m4 <- feols(hours_cond ~ male_post18 + male + post18 |
              age_factor + yq_factor + state,
            data = enoe[!is.na(hours_cond)], cluster = ~state)

# (5) School enrollment
m5 <- feols(in_school ~ male_post18 + male + post18 |
              age_factor + yq_factor + state,
            data = enoe[!is.na(in_school)], cluster = ~state)

# Print main results
cat("\n=== MAIN RESULTS ===\n")
cat(sprintf("Employment (ITT):   β = %.4f, SE = %.4f, p = %.4f\n",
            coef(m1)["male_post18"], se(m1)["male_post18"], pvalue(m1)["male_post18"]))
cat(sprintf("Formal (ITT):       β = %.4f, SE = %.4f, p = %.4f\n",
            coef(m2)["male_post18"], se(m2)["male_post18"], pvalue(m2)["male_post18"]))
cat(sprintf("Ln earnings (ITT):  β = %.4f, SE = %.4f, p = %.4f\n",
            coef(m3)["male_post18"], se(m3)["male_post18"], pvalue(m3)["male_post18"]))
cat(sprintf("Hours (ITT):        β = %.4f, SE = %.4f, p = %.4f\n",
            coef(m4)["male_post18"], se(m4)["male_post18"], pvalue(m4)["male_post18"]))
cat(sprintf("In school (ITT):    β = %.4f, SE = %.4f, p = %.4f\n",
            coef(m5)["male_post18"], se(m5)["male_post18"], pvalue(m5)["male_post18"]))

# LATE scaling: divide ITT by treatment share (~0.40) to get effect of service
cat(sprintf("\nLATE (employment):  %.4f / 0.40 = %.4f\n",
            coef(m1)["male_post18"], coef(m1)["male_post18"] / 0.40))
cat(sprintf("LATE (formal):      %.4f / 0.40 = %.4f\n",
            coef(m2)["male_post18"], coef(m2)["male_post18"] / 0.40))

# ── Save models ──────────────────────────────────────────────────
save(m1, m2, m3, m4, m5, es_emp, es_formal, age_gaps,
     file = "data/main_models.RData")

# ── Diagnostics JSON ─────────────────────────────────────────────
diag <- list(
  n_treated = nrow(enoe[male == 1 & eda >= 18]),
  n_pre = length(unique(enoe[eda < 18]$yq_factor)),  # 8 quarters of pre-treatment data
  n_obs = nrow(enoe),
  n_males_18 = nrow(enoe[male == 1 & eda == 18]),
  n_females_18 = nrow(enoe[male == 0 & eda == 18]),
  n_quarters = length(unique(enoe$yq_factor)),
  n_states = length(unique(enoe$state)),
  emp_rate_male_18 = mean(enoe[male == 1 & eda == 18]$employed, na.rm = TRUE),
  emp_rate_female_18 = mean(enoe[male == 0 & eda == 18]$employed, na.rm = TRUE),
  itt_employment = coef(m1)["male_post18"],
  itt_formal = coef(m2)["male_post18"],
  treatment_share = 0.40
)
jsonlite::write_json(diag, "data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
cat("\nDiagnostics saved to data/diagnostics.json\n")
