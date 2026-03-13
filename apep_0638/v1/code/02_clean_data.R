## 02_clean_data.R — Construct analysis variables
## Input: data/enoe_combined.csv
## Output: data/enoe_analysis.csv

source("code/00_packages.R")

enoe <- fread("data/enoe_combined.csv")
cat(sprintf("Loaded %s observations\n", format(nrow(enoe), big.mark = ",")))

# ── Construct variables ──────────────────────────────────────────

# Gender
enoe[, male := as.integer(sex == 1)]

# Employment: clase1 == 1 means "employed" in ENOE coding
enoe[, employed := as.integer(clase1 == 1)]

# Monthly earnings (ingocup): set non-employed to 0 for unconditional measure
enoe[, earnings := fifelse(is.na(ingocup) | ingocup <= 0, 0, ingocup)]
# Conditional earnings (employed only)
enoe[, earnings_cond := fifelse(employed == 1 & !is.na(ingocup) & ingocup > 0, ingocup, NA_real_)]

# Log conditional earnings
enoe[, ln_earnings := fifelse(!is.na(earnings_cond) & earnings_cond > 0,
                              log(earnings_cond), NA_real_)]

# Weekly hours worked
enoe[, hours := fifelse(is.na(hrsocup) | hrsocup < 0, 0, hrsocup)]
enoe[, hours_cond := fifelse(employed == 1 & !is.na(hrsocup) & hrsocup > 0,
                             hrsocup, NA_real_)]

# Formal employment: seg_soc indicates social security access
# seg_soc == 1: has social security; seg_soc == 2: does not
enoe[, formal := as.integer(seg_soc == 1)]
enoe[is.na(seg_soc) | employed == 0, formal := 0L]

# Years of education
enoe[, educ_years := fifelse(is.na(anios_esc) | anios_esc < 0, NA_real_, anios_esc)]

# Currently in school: cs_p13_1 indicates school enrollment status
# cs_p13_1 == 1: currently enrolled; varies by quarter
enoe[, in_school := as.integer(cs_p13_1 == 1)]
enoe[is.na(cs_p13_1), in_school := NA_integer_]

# Occupational position (pos_ocu)
# 1=employer, 2=self-employed, 3=salaried, 4=no pay, 5=other
enoe[, salaried := as.integer(pos_ocu == 3)]
enoe[is.na(pos_ocu) | employed == 0, salaried := 0L]

# Post-lottery indicator: age >= 18
enoe[, post18 := as.integer(eda >= 18)]

# Male × Post18 interaction (the key treatment variable)
enoe[, male_post18 := male * post18]

# Age relative to 18 (for event study)
enoe[, age_rel := eda - 18L]

# State factor
enoe[, state := as.factor(ent)]

# Year-quarter factor
enoe[, yq_factor := as.factor(paste0(year, "Q", quarter))]

# Age factor
enoe[, age_factor := as.factor(eda)]

# Birth cohort
enoe[is.na(nac_anio) | nac_anio < 1980 | nac_anio > 2010, nac_anio := NA_integer_]
enoe[, cohort := as.factor(nac_anio)]

# ── Sample restrictions ──────────────────────────────────────────

# Keep ages 15-30 for main analysis
enoe <- enoe[eda >= 15 & eda <= 30]

# Drop observations with missing sex
enoe <- enoe[!is.na(sex)]

cat(sprintf("\n=== Analysis Dataset ===\n"))
cat(sprintf("Observations: %s\n", format(nrow(enoe), big.mark = ",")))
cat(sprintf("Males: %s (%.1f%%)\n",
            format(nrow(enoe[male == 1]), big.mark = ","),
            100 * nrow(enoe[male == 1]) / nrow(enoe)))
cat(sprintf("Females: %s (%.1f%%)\n",
            format(nrow(enoe[male == 0]), big.mark = ","),
            100 * nrow(enoe[male == 0]) / nrow(enoe)))
cat(sprintf("\nAge distribution (males):\n"))
print(enoe[male == 1, .N, by = eda][order(eda)])

# Summary statistics
cat(sprintf("\n=== Key Outcomes by Gender and Age Group ===\n"))
summ <- enoe[, .(
  N = .N,
  emp_rate = mean(employed, na.rm = TRUE),
  formal_rate = mean(formal, na.rm = TRUE),
  mean_earnings = mean(earnings_cond, na.rm = TRUE),
  mean_hours = mean(hours_cond, na.rm = TRUE),
  mean_educ = mean(educ_years, na.rm = TRUE)
), by = .(male, age_group = fifelse(eda < 18, "15-17", fifelse(eda <= 20, "18-20", "21-30")))]
print(summ[order(male, age_group)])

# Save
fwrite(enoe, "data/enoe_analysis.csv")
cat(sprintf("\nSaved: data/enoe_analysis.csv (%s obs, %.0f MB)\n",
            format(nrow(enoe), big.mark = ","),
            file.info("data/enoe_analysis.csv")$size / 1e6))
