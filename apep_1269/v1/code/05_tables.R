## 05_tables.R — Generate all LaTeX tables
## APEP Paper: Mexico's Sorteo Militar and Youth Crime

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

df <- fread(file.path(data_dir, "analysis_panel.csv"))
df[, EDAD := as.numeric(EDAD)]
df[, age_f := factor(EDAD)]
df[, state := as.integer(CVE_ENT)]
df[, male_18_19 := as.integer(male == 1 & EDAD >= 18 & EDAD <= 19)]
df[, age_18_19 := as.integer(EDAD >= 18 & EDAD <= 19)]
df[, victim_fraud := as.integer(n_fraud > 0)]
df[, age_group_f := factor(age_group, levels = c("26-35", "18-19", "20-21", "22-25", "36-50"))]

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("=== Generating Table 1: Summary Statistics ===\n")

# Panel A: Full sample
summ_full <- df[, .(
  N = .N,
  pct_male = round(mean(male) * 100, 1),
  mean_age = round(mean(EDAD), 1),
  victim_any = round(mean(victim) * 100, 1),
  victim_violent = round(mean(victim_violent) * 100, 1),
  victim_property = round(mean(victim_property) * 100, 1),
  victim_fraud = round(mean(victim_fraud) * 100, 1)
)]

# Panel B: By sex and age group
summ_by <- df[age_group %in% c("18-19","20-21","22-25","26-35"), .(
  N = .N,
  victim_any = round(mean(victim) * 100, 1),
  victim_violent = round(mean(victim_violent) * 100, 1),
  victim_property = round(mean(victim_property) * 100, 1)
), by = .(male, age_group)][order(age_group, male)]

tab1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: ENVIPE Victimization Survey, 2021--2024}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{Males} & \\multicolumn{2}{c}{Females} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  " & Ages 18--19 & Ages 22--25 & Ages 18--19 & Ages 22--25 \\\\\n",
  "\\hline\n",
  "\\addlinespace\n",
  "\\textit{Panel A: Victimization rates (\\%)} \\\\\n",
  "\\addlinespace\n"
)

# Get specific values
m18 <- summ_by[male == 1 & age_group == "18-19"]
m22 <- summ_by[male == 1 & age_group == "22-25"]
f18 <- summ_by[male == 0 & age_group == "18-19"]
f22 <- summ_by[male == 0 & age_group == "22-25"]

tab1 <- paste0(tab1,
  "Any crime & ", m18$victim_any, " & ", m22$victim_any,
  " & ", f18$victim_any, " & ", f22$victim_any, " \\\\\n",
  "Violent crime & ", m18$victim_violent, " & ", m22$victim_violent,
  " & ", f18$victim_violent, " & ", f22$victim_violent, " \\\\\n",
  "Property crime & ", m18$victim_property, " & ", m22$victim_property,
  " & ", f18$victim_property, " & ", f22$victim_property, " \\\\\n",
  "\\addlinespace\n",
  "Observations & ", format(m18$N, big.mark=","), " & ", format(m22$N, big.mark=","),
  " & ", format(f18$N, big.mark=","), " & ", format(f22$N, big.mark=","), " \\\\\n",
  "\\addlinespace\n",
  "\\textit{Panel B: Full sample} \\\\\n",
  "\\addlinespace\n",
  "Total observations & \\multicolumn{4}{c}{", format(summ_full$N, big.mark=","), "} \\\\\n",
  "Survey years & \\multicolumn{4}{c}{2021--2024} \\\\\n",
  "States & \\multicolumn{4}{c}{32} \\\\\n",
  "Mean age & \\multicolumn{4}{c}{", summ_full$mean_age, "} \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Data from ENVIPE (Encuesta Nacional de Victimizaci\\'on y Percepci\\'on sobre Seguridad P\\'ublica), 2021--2024. ",
  "Each observation is a selected individual aged 18--50. Victimization rates are the percentage of individuals experiencing at least one crime incident ",
  "in the survey reference year. Violent crime includes robbery/assault on the street, physical assault, kidnapping, and sexual crimes (BPCOD 5, 11--14). ",
  "Property crime includes vehicle theft, vandalism, and burglary (BPCOD 1--4, 6). ",
  "Males aged 18--19 are the cohort eligible for Mexico's \\textit{Sorteo Militar} lottery, in which approximately 40\\% of males are randomly assigned to Saturday morning military training.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1, file.path(tables_dir, "tab1_summary.tex"))
cat("Table 1 saved.\n")

# ============================================================
# Table 2: Main DiD Results
# ============================================================
cat("=== Generating Table 2: Main Results ===\n")

# Run all specifications
m1 <- feols(victim ~ male_18_19 + male + age_18_19 | survey_year,
            data = df, cluster = ~state)
m2 <- feols(victim ~ male_18_19 | male + age_f + state^survey_year,
            data = df, cluster = ~state)
m3 <- feols(victim_violent ~ male_18_19 | male + age_f + state^survey_year,
            data = df, cluster = ~state)
m4 <- feols(victim_property ~ male_18_19 | male + age_f + state^survey_year,
            data = df, cluster = ~state)
m5 <- feols(victim_fraud ~ male_18_19 | male + age_f + state^survey_year,
            data = df, cluster = ~state)

# Mean of dependent variable for each
means <- c(round(mean(df$victim)*100, 1),
           round(mean(df$victim)*100, 1),
           round(mean(df$victim_violent)*100, 1),
           round(mean(df$victim_property)*100, 1),
           round(mean(df$victim_fraud)*100, 1))

tab2 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Effect of Lottery Eligibility on Crime Victimization}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & Any Crime & Any Crime & Violent & Property & Fraud \\\\\n",
  "\\hline\n",
  "\\addlinespace\n",
  sprintf("Male $\\times$ Age 18--19 & %.4f & %.4f & %.4f & %.4f & %.4f \\\\\n",
          coef(m1)["male_18_19"], coef(m2)["male_18_19"],
          coef(m3)["male_18_19"], coef(m4)["male_18_19"],
          coef(m5)["male_18_19"]),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n",
          se(m1)["male_18_19"], se(m2)["male_18_19"],
          se(m3)["male_18_19"], se(m4)["male_18_19"],
          se(m5)["male_18_19"]),
  "\\addlinespace\n",
  "Year FE & Yes & -- & -- & -- & -- \\\\\n",
  "State $\\times$ Year FE & -- & Yes & Yes & Yes & Yes \\\\\n",
  "Age FE & -- & Yes & Yes & Yes & Yes \\\\\n",
  "Sex FE & -- & Yes & Yes & Yes & Yes \\\\\n",
  "\\addlinespace\n",
  sprintf("Dep.~var.~mean (\\%%) & %.1f & %.1f & %.1f & %.1f & %.1f \\\\\n",
          means[1], means[2], means[3], means[4], means[5]),
  "Observations & ", format(nrow(df), big.mark=","),
  " & ", format(nrow(df), big.mark=","),
  " & ", format(nrow(df), big.mark=","),
  " & ", format(nrow(df), big.mark=","),
  " & ", format(nrow(df), big.mark=","), " \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Each column reports the coefficient on Male $\\times$ Age 18--19 from a linear probability model. ",
  "The dependent variable is an indicator for experiencing at least one crime of the specified type. ",
  "Standard errors clustered at the state level (32 clusters) are in parentheses. ",
  "Column (5) uses fraud as a placebo outcome: Saturday military training should not affect fraud victimization. ",
  "The sample includes all ENVIPE respondents aged 18--50 over survey years 2021--2024. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2, file.path(tables_dir, "tab2_main.tex"))
cat("Table 2 saved.\n")

# ============================================================
# Table 3: Age Profile (Male excess by age group)
# ============================================================
cat("=== Generating Table 3: Age Profile ===\n")

m_age_any <- feols(victim ~ male:age_group_f | male + age_group_f + state^survey_year,
                    data = df[!is.na(age_group)], cluster = ~state)
m_age_viol <- feols(victim_violent ~ male:age_group_f | male + age_group_f + state^survey_year,
                     data = df[!is.na(age_group)], cluster = ~state)
m_age_prop <- feols(victim_property ~ male:age_group_f | male + age_group_f + state^survey_year,
                     data = df[!is.na(age_group)], cluster = ~state)

# Extract coefficients for key age groups
age_groups <- c("18-19", "20-21", "22-25", "36-50")
coef_names <- paste0("male:age_group_f", age_groups)

tab3 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Male Excess Victimization by Age Group}\n",
  "\\label{tab:age_profile}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) \\\\\n",
  " & Any Crime & Violent & Property \\\\\n",
  "\\hline\n",
  "\\addlinespace\n"
)

for (ag in age_groups) {
  cn <- paste0("male:age_group_f", ag)
  b1 <- if (cn %in% names(coef(m_age_any))) sprintf("%.4f", coef(m_age_any)[cn]) else "--"
  s1 <- if (cn %in% names(se(m_age_any))) sprintf("(%.4f)", se(m_age_any)[cn]) else ""
  b2 <- if (cn %in% names(coef(m_age_viol))) sprintf("%.4f", coef(m_age_viol)[cn]) else "--"
  s2 <- if (cn %in% names(se(m_age_viol))) sprintf("(%.4f)", se(m_age_viol)[cn]) else ""
  b3 <- if (cn %in% names(coef(m_age_prop))) sprintf("%.4f", coef(m_age_prop)[cn]) else "--"
  s3 <- if (cn %in% names(se(m_age_prop))) sprintf("(%.4f)", se(m_age_prop)[cn]) else ""

  tab3 <- paste0(tab3,
    "Male $\\times$ Age ", ag, " & ", b1, " & ", b2, " & ", b3, " \\\\\n",
    " & ", s1, " & ", s2, " & ", s3, " \\\\\n",
    "\\addlinespace\n")
}

tab3 <- paste0(tab3,
  "Reference group & \\multicolumn{3}{c}{Male $\\times$ Age 26--35} \\\\\n",
  "Observations & ", format(nrow(df[!is.na(age_group)]), big.mark=","),
  " & ", format(nrow(df[!is.na(age_group)]), big.mark=","),
  " & ", format(nrow(df[!is.na(age_group)]), big.mark=","), " \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Each cell reports the coefficient on Male $\\times$ Age Group from a linear probability model ",
  "with sex, age group, and state $\\times$ year fixed effects. The reference category is males aged 26--35. ",
  "If the \\textit{Sorteo Militar} reduces male victimization during service (ages 18--19), the Male $\\times$ Age 18--19 coefficient should be ",
  "smaller than the Male $\\times$ Age 22--25 coefficient. Standard errors clustered at the state level in parentheses. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3, file.path(tables_dir, "tab3_age_profile.tex"))
cat("Table 3 saved.\n")

# ============================================================
# Table 4: Robustness Checks
# ============================================================
cat("=== Generating Table 4: Robustness ===\n")

# Female placebo
df[, female_18_19 := as.integer(male == 0 & EDAD >= 18 & EDAD <= 19)]
m_r1 <- feols(victim ~ female_18_19 | male + age_f + state^survey_year,
               data = df, cluster = ~state)

# Narrow window (age 18 only)
df[, male_18 := as.integer(male == 1 & EDAD == 18)]
m_r2 <- feols(victim ~ male_18 | male + age_f + state^survey_year,
               data = df, cluster = ~state)

# Broader window (18-20)
df[, male_18_20 := as.integer(male == 1 & EDAD >= 18 & EDAD <= 20)]
m_r3 <- feols(victim ~ male_18_20 | male + age_f + state^survey_year,
               data = df, cluster = ~state)

# Weighted
df[, wt := as.numeric(FAC_ELE)]
df[is.na(wt) | wt <= 0, wt := 1]
m_r4 <- feols(victim ~ male_18_19 | male + age_f + state^survey_year,
               data = df, weights = ~wt, cluster = ~state)

tab4 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robustness}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & Female & Male & Male & Weighted \\\\\n",
  " & Placebo & Age 18 only & Ages 18--20 & Main Spec \\\\\n",
  "\\hline\n",
  "\\addlinespace\n",
  sprintf("Treatment & %.4f & %.4f & %.4f & %.4f \\\\\n",
          coef(m_r1)[1], coef(m_r2)[1], coef(m_r3)[1], coef(m_r4)[1]),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n",
          se(m_r1)[1], se(m_r2)[1], se(m_r3)[1], se(m_r4)[1]),
  "\\addlinespace\n",
  "State $\\times$ Year FE & Yes & Yes & Yes & Yes \\\\\n",
  "Age FE & Yes & Yes & Yes & Yes \\\\\n",
  "Sex FE & Yes & Yes & Yes & Yes \\\\\n",
  "Survey weights & No & No & No & Yes \\\\\n",
  "\\addlinespace\n",
  "Observations & ", format(nrow(df), big.mark=","),
  " & ", format(nrow(df), big.mark=","),
  " & ", format(nrow(df), big.mark=","),
  " & ", format(nrow(df), big.mark=","), " \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Column (1) replaces the treatment with Female $\\times$ Age 18--19 as a placebo (women are never eligible for the \\textit{Sorteo}). ",
  "Column (2) narrows the treatment window to age 18 only. Column (3) broadens it to 18--20. ",
  "Column (4) applies ENVIPE survey weights (\\texttt{FAC\\_ELE}). All specifications include sex, age, and state $\\times$ year fixed effects. ",
  "Standard errors clustered at the state level in parentheses. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4, file.path(tables_dir, "tab4_robustness.tex"))
cat("Table 4 saved.\n")

# ============================================================
# Table F1: Standardized Effect Sizes (SDE)
# ============================================================
cat("=== Generating Table F1: SDE ===\n")

# Compute SDE for main outcomes
outcomes <- list(
  list(name = "Any crime", var = "victim", model = m2),
  list(name = "Violent crime", var = "victim_violent", model = m3),
  list(name = "Property crime", var = "victim_property", model = m4)
)

sde_rows <- list()
for (oc in outcomes) {
  beta <- coef(oc$model)["male_18_19"]
  se_beta <- se(oc$model)["male_18_19"]
  sd_y <- sd(df[[oc$var]])
  sde <- beta / sd_y
  se_sde <- se_beta / sd_y

  bucket <- ifelse(sde < -0.15, "Large negative",
            ifelse(sde < -0.05, "Moderate negative",
            ifelse(sde < -0.005, "Small negative",
            ifelse(sde < 0.005, "Null",
            ifelse(sde < 0.05, "Small positive",
            ifelse(sde < 0.15, "Moderate positive", "Large positive"))))))

  sde_rows[[length(sde_rows) + 1]] <- data.frame(
    outcome = oc$name,
    beta = round(beta, 4),
    se = round(se_beta, 4),
    sd_y = round(sd_y, 4),
    sde = round(sde, 4),
    se_sde = round(se_sde, 4),
    classification = bucket
  )
}

sde_df <- do.call(rbind, sde_rows)

# Heterogeneity panel: by high vs low violence states
state_violence <- df[, .(hom_rate = mean(victim_violent)), by = state]
median_violence <- median(state_violence$hom_rate)
high_violence_states <- state_violence[hom_rate >= median_violence, state]
df[, high_violence := as.integer(state %in% high_violence_states)]

m_high <- feols(victim ~ male_18_19 | male + age_f + state^survey_year,
                data = df[high_violence == 1], cluster = ~state)
m_low <- feols(victim ~ male_18_19 | male + age_f + state^survey_year,
               data = df[high_violence == 0], cluster = ~state)

for (spec in list(
  list(name = "Any crime (high-violence states)", model = m_high),
  list(name = "Any crime (low-violence states)", model = m_low)
)) {
  beta <- coef(spec$model)["male_18_19"]
  se_beta <- se(spec$model)["male_18_19"]
  sd_y_sub <- if (grepl("high", spec$name)) sd(df[high_violence==1]$victim) else sd(df[high_violence==0]$victim)
  sde <- beta / sd_y_sub
  se_sde <- se_beta / sd_y_sub

  bucket <- ifelse(sde < -0.15, "Large negative",
            ifelse(sde < -0.05, "Moderate negative",
            ifelse(sde < -0.005, "Small negative",
            ifelse(sde < 0.005, "Null",
            ifelse(sde < 0.05, "Small positive",
            ifelse(sde < 0.15, "Moderate positive", "Large positive"))))))

  sde_rows[[length(sde_rows) + 1]] <- data.frame(
    outcome = spec$name,
    beta = round(beta, 4),
    se = round(se_beta, 4),
    sd_y = round(sd_y_sub, 4),
    sde = round(sde, 4),
    se_sde = round(se_sde, 4),
    classification = bucket
  )
}

sde_df_full <- do.call(rbind, sde_rows)

# Build SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Mexico. ",
  "\\textbf{Research question:} Does random assignment to part-time Saturday military service via Mexico's \\textit{Sorteo Militar} lottery reduce crime victimization among 18--19 year old males? ",
  "\\textbf{Policy mechanism:} The \\textit{Sorteo Militar} randomly assigns approximately 40\\% of 18-year-old males to 44 Saturday morning training sessions (6 hours each) over 10 months, providing structured weekend occupation during peak gang-recruitment ages. ",
  "\\textbf{Outcome definition:} Binary indicator for experiencing at least one crime victimization episode in the reference year, from ENVIPE survey responses covering reported and unreported crimes. ",
  "\\textbf{Treatment:} Binary (Male $\\times$ Age 18--19 interaction); captures intent-to-treat, as approximately 40\\% of lottery-eligible males are actually assigned to service. ",
  "\\textbf{Data:} ENVIPE victimization survey microdata, 2021--2024, individual respondents aged 18--50, N = ",
  format(nrow(df), big.mark=","), ". ",
  "\\textbf{Method:} Linear probability model with sex, single-year-of-age, and state $\\times$ year fixed effects; standard errors clustered at the state level (32 clusters). ",
  "\\textbf{Sample:} Adults 18--50 selected as ENVIPE informants; one per household. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pooled standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate (0.05--0.15), Small (0.005--0.05), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\addlinespace\n",
  "\\textit{Panel A: Pooled} \\\\\n",
  "\\addlinespace\n"
)

for (i in 1:3) {
  row <- sde_df_full[i, ]
  tabF1 <- paste0(tabF1,
    row$outcome, " & ", row$beta, " & ", row$se, " & ", row$sd_y,
    " & ", row$sde, " & ", row$se_sde, " & ", row$classification, " \\\\\n")
}

tabF1 <- paste0(tabF1,
  "\\addlinespace\n",
  "\\textit{Panel B: Heterogeneous (by state violence level)} \\\\\n",
  "\\addlinespace\n"
)

for (i in 4:5) {
  row <- sde_df_full[i, ]
  tabF1 <- paste0(tabF1,
    row$outcome, " & ", row$beta, " & ", row$se, " & ", row$sd_y,
    " & ", row$sde, " & ", row$se_sde, " & ", row$classification, " \\\\\n")
}

tabF1 <- paste0(tabF1,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tabF1, file.path(tables_dir, "tabF1_sde.tex"))
cat("Table F1 (SDE) saved.\n")

cat("\nAll tables generated.\n")
