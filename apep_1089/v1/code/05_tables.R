## 05_tables.R — Generate all LaTeX tables
## apep_1089: NIS2 Cybersecurity Regulation and Firm Security Investment

source("code/00_packages.R")

cat("=== Generating Tables ===\n")

# ----------------------------------------------------------------
# Load data and results
# ----------------------------------------------------------------

indices <- readRDS("data/indices.rds")
results <- readRDS("data/main_results.rds")
rob_results <- readRDS("data/robustness_results.rds")
summary_stats <- readRDS("data/summary_stats.rds")
indicator_panel <- readRDS("data/indicator_panel.rds")

did_data <- indices %>% filter(size_class %in% c("10-49", "50-249"))

# ----------------------------------------------------------------
# Table 1: Summary Statistics
# ----------------------------------------------------------------

cat("Generating Table 1: Summary Statistics...\n")

# Compute summary stats for indices
sum_tab <- indices %>%
  group_by(size_class) %>%
  summarize(
    mean_tech = mean(index_technical, na.rm = TRUE),
    sd_tech = sd(index_technical, na.rm = TRUE),
    mean_formal = mean(index_formal, na.rm = TRUE),
    sd_formal = sd(index_formal, na.rm = TRUE),
    mean_gap = mean(compliance_gap, na.rm = TRUE),
    sd_gap = sd(compliance_gap, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  )

# Also compute pre-post changes by size class
changes <- indices %>%
  mutate(period = ifelse(year == 2024, "Post", "Pre")) %>%
  group_by(size_class, period) %>%
  summarize(
    tech = mean(index_technical, na.rm = TRUE),
    formal = mean(index_formal, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  pivot_wider(names_from = period, values_from = c(tech, formal)) %>%
  mutate(
    delta_tech = tech_Post - tech_Pre,
    delta_formal = formal_Post - formal_Pre
  )

tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: ICT Security Measures by Firm Size}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Technical Index} & \\multicolumn{2}{c}{Formal Index} & \\multicolumn{2}{c}{Compliance Gap} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}",
  "Size Class & Mean & SD & Mean & SD & Mean & SD \\\\",
  "\\midrule",
  sprintf("10--49 (Control) & %.1f & %.1f & %.1f & %.1f & %.1f & %.1f \\\\",
          sum_tab$mean_tech[sum_tab$size_class == "10-49"],
          sum_tab$sd_tech[sum_tab$size_class == "10-49"],
          sum_tab$mean_formal[sum_tab$size_class == "10-49"],
          sum_tab$sd_formal[sum_tab$size_class == "10-49"],
          sum_tab$mean_gap[sum_tab$size_class == "10-49"],
          sum_tab$sd_gap[sum_tab$size_class == "10-49"]),
  sprintf("50--249 (Treated) & %.1f & %.1f & %.1f & %.1f & %.1f & %.1f \\\\",
          sum_tab$mean_tech[sum_tab$size_class == "50-249"],
          sum_tab$sd_tech[sum_tab$size_class == "50-249"],
          sum_tab$mean_formal[sum_tab$size_class == "50-249"],
          sum_tab$sd_formal[sum_tab$size_class == "50-249"],
          sum_tab$mean_gap[sum_tab$size_class == "50-249"],
          sum_tab$sd_gap[sum_tab$size_class == "50-249"]),
  sprintf("250+ (NIS1 legacy) & %.1f & %.1f & %.1f & %.1f & %.1f & %.1f \\\\",
          sum_tab$mean_tech[sum_tab$size_class == "GE250"],
          sum_tab$sd_tech[sum_tab$size_class == "GE250"],
          sum_tab$mean_formal[sum_tab$size_class == "GE250"],
          sum_tab$sd_formal[sum_tab$size_class == "GE250"],
          sum_tab$mean_gap[sum_tab$size_class == "GE250"],
          sum_tab$sd_gap[sum_tab$size_class == "GE250"]),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Pre--Post Changes (2019/2022 vs.\\ 2024)}} \\\\",
  sprintf("$\\Delta$ 10--49 & \\multicolumn{2}{c}{%.1f} & \\multicolumn{2}{c}{%.1f} & & \\\\",
          changes$delta_tech[changes$size_class == "10-49"],
          changes$delta_formal[changes$size_class == "10-49"]),
  sprintf("$\\Delta$ 50--249 & \\multicolumn{2}{c}{%.1f} & \\multicolumn{2}{c}{%.1f} & & \\\\",
          changes$delta_tech[changes$size_class == "50-249"],
          changes$delta_formal[changes$size_class == "50-249"]),
  sprintf("$\\Delta\\Delta$ (DiD) & \\multicolumn{2}{c}{%.1f} & \\multicolumn{2}{c}{%.1f} & & \\\\",
          changes$delta_tech[changes$size_class == "50-249"] - changes$delta_tech[changes$size_class == "10-49"],
          changes$delta_formal[changes$size_class == "50-249"] - changes$delta_formal[changes$size_class == "10-49"]),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} N = 243 country $\\times$ size-class $\\times$ year observations (27 EU member states, 3 size classes, 3 survey years: 2019, 2022, 2024). Technical Index is the mean adoption rate (\\%) across 8 technical security measures (encryption, VPN, network access control, log maintenance, backup, password policy, security testing, biometric authentication). Formal Index averages 6 formal compliance measures (security policy, risk assessment, awareness activities, compulsory training, voluntary training, contractual obligations). Compliance Gap = Formal $-$ Technical. Source: Eurostat \\texttt{isoc\\_cisce\\_ra}.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, "tables/tab1_summary.tex")

# ----------------------------------------------------------------
# Table 2: Main DiD Results
# ----------------------------------------------------------------

cat("Generating Table 2: Main DiD Results...\n")

# Extract coefficients and standard errors
extract_did <- function(model, varname = "treat_post") {
  beta <- coef(model)[varname]
  se_val <- se(model)[varname]
  pval <- pvalue(model)[varname]
  stars <- ifelse(pval < 0.01, "***", ifelse(pval < 0.05, "**", ifelse(pval < 0.1, "*", "")))
  n <- model$nobs
  r2w <- fitstat(model, "wr2")$wr2
  list(beta = beta, se = se_val, pval = pval, stars = stars, n = n, r2w = r2w)
}

d1 <- extract_did(results$m2_tech)
d2 <- extract_did(results$m3_tech)
d3 <- extract_did(results$m2_formal)
d4 <- extract_did(results$m3_formal)
d5 <- extract_did(results$m2_gap)
d6 <- extract_did(results$m3_gap)

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of NIS2 on Cybersecurity Investment: Difference-in-Differences}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Technical Index} & \\multicolumn{2}{c}{Formal Index} & \\multicolumn{2}{c}{Compliance Gap} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\",
  "\\midrule",
  sprintf("Treated $\\times$ Post & %.3f%s & %.3f%s & %.3f%s & %.3f%s & %.3f%s & %.3f%s \\\\",
          d1$beta, d1$stars, d2$beta, d2$stars,
          d3$beta, d3$stars, d4$beta, d4$stars,
          d5$beta, d5$stars, d6$beta, d6$stars),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\",
          d1$se, d2$se, d3$se, d4$se, d5$se, d6$se),
  sprintf(" & [%.3f] & [%.3f] & [%.3f] & [%.3f] & & \\\\",
          results$ri_p_tech, results$ri_p_tech, results$ri_p_formal, results$ri_p_formal),
  "\\midrule",
  "Country FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\",
  "Size FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & No & Yes & No & Yes & No \\\\",
  "Country $\\times$ Year FE & No & Yes & No & Yes & No & Yes \\\\",
  sprintf("Observations & %d & %d & %d & %d & %d & %d \\\\",
          d1$n, d2$n, d3$n, d4$n, d5$n, d6$n),
  sprintf("Within $R^2$ & %.4f & %.4f & %.4f & %.4f & %.4f & %.4f \\\\",
          d1$r2w, d2$r2w, d3$r2w, d4$r2w, d5$r2w, d6$r2w),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each column reports the coefficient on Treated $\\times$ Post from a difference-in-differences regression. Treated = firms with 50--249 employees (newly covered by NIS2); Control = firms with 10--49 employees (exempt). Pre-periods: 2019, 2022; Post: 2024. Standard errors clustered by country in parentheses. Randomization inference p-values (1,000 permutations) in brackets. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, "tables/tab2_main_did.tex")

# ----------------------------------------------------------------
# Table 3: Individual Indicator Effects
# ----------------------------------------------------------------

cat("Generating Table 3: Individual Indicator Effects...\n")

ind_res <- results$indicator_results

# Indicator labels
ind_labels <- c(
  "E_SECAWCTP" = "Compulsory security training",
  "E_SECPOL2" = "Formal security policy",
  "E_SECMUIBM" = "Biometric authentication",
  "E_SECMTST" = "Security testing/auditing",
  "E_SECMRASS" = "Risk assessment",
  "E_SECMDENC" = "Data encryption",
  "E_SECMSPSW" = "Strong password policy",
  "E_SECMLOG" = "Log file maintenance",
  "E_SECMVPN" = "VPN usage",
  "E_SECMNAC" = "Network access control",
  "E_SECMOSBU" = "Off-site backup",
  "E_SECAWANY" = "Any awareness activity",
  "E_SECAWVTGI" = "Voluntary training/guides",
  "E_SECAWCONT" = "Contractual obligations"
)

ind_res <- ind_res %>%
  mutate(
    label = ind_labels[indicator],
    stars = case_when(pval < 0.01 ~ "***", pval < 0.05 ~ "**", pval < 0.1 ~ "*", TRUE ~ "")
  )

# Sort: formal first (by abs beta), then technical
ind_formal <- ind_res %>% filter(measure_type == "formal") %>% arrange(desc(beta))
ind_tech <- ind_res %>% filter(measure_type == "technical") %>% arrange(desc(beta))

tab3_rows <- c()

# Formal measures
tab3_rows <- c(tab3_rows, "\\multicolumn{5}{l}{\\textit{Panel A: Formal Compliance Measures}} \\\\")
for (i in 1:nrow(ind_formal)) {
  r <- ind_formal[i, ]
  tab3_rows <- c(tab3_rows, sprintf("%s & %.2f%s & (%.2f) & %.3f & %d \\\\",
                                     r$label, r$beta, r$stars, r$se, r$pval, r$n))
}

# Technical measures
tab3_rows <- c(tab3_rows, "\\midrule",
               "\\multicolumn{5}{l}{\\textit{Panel B: Technical Security Measures}} \\\\")
for (i in 1:nrow(ind_tech)) {
  r <- ind_tech[i, ]
  tab3_rows <- c(tab3_rows, sprintf("%s & %.2f%s & (%.2f) & %.3f & %d \\\\",
                                     r$label, r$beta, r$stars, r$se, r$pval, r$n))
}

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Individual Security Measure Effects: Formal vs.\\ Technical}",
  "\\label{tab:indicators}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Measure & $\\hat{\\beta}$ & SE & $p$-value & $N$ \\\\",
  "\\midrule",
  tab3_rows,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each row reports the coefficient on Treated $\\times$ Post from a separate DiD regression with country, size-class, and country $\\times$ year fixed effects. Outcome is the percentage of enterprises adopting each measure. Standard errors clustered by country. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, "tables/tab3_indicators.tex")

# ----------------------------------------------------------------
# Table 4: Robustness and Extensions
# ----------------------------------------------------------------

cat("Generating Table 4: Robustness...\n")

# DDD results
ddd_tech <- extract_did(results$m_ddd_tech, "treat_post_trans")
ddd_formal <- extract_did(results$m_ddd_formal, "treat_post_trans")

# Dosage results
dose_tech_new <- extract_did(results$m_dose_tech, "newly_post")
dose_tech_int <- extract_did(results$m_dose_tech, "intensified_post")
dose_formal_new <- extract_did(results$m_dose_formal, "newly_post")
dose_formal_int <- extract_did(results$m_dose_formal, "intensified_post")

# Placebo
plac_tech <- extract_did(rob_results$placebo_tech, "placebo_treat_post")
plac_formal <- extract_did(rob_results$placebo_formal, "placebo_treat_post")

# Incidents
if (!is.null(rob_results$incidents)) {
  inc <- extract_did(rob_results$incidents, "treat_post")
} else {
  inc <- list(beta = NA, se = NA, stars = "", n = 0, r2w = NA)
}

# Mandate interaction
mand_base <- extract_did(rob_results$mandate, "treat_post")
mand_int <- extract_did(rob_results$mandate, "mandate_treat_post")

tab4_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness and Extensions}",
  "\\label{tab:robustness}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  "Specification & Technical & Formal & Other & $N$ \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel A: Triple-Difference (Transposition)}} \\\\",
  sprintf("Treated $\\times$ Post $\\times$ Transposed & %.2f%s & %.2f%s & & %d \\\\",
          ddd_tech$beta, ddd_tech$stars, ddd_formal$beta, ddd_formal$stars, ddd_tech$n),
  sprintf(" & (%.2f) & (%.2f) & & \\\\", ddd_tech$se, ddd_formal$se),
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel B: Dosage (all three size classes)}} \\\\",
  sprintf("Newly covered (50--249) $\\times$ Post & %.2f%s & %.2f%s & & %d \\\\",
          dose_tech_new$beta, dose_tech_new$stars, dose_formal_new$beta, dose_formal_new$stars, dose_tech_new$n),
  sprintf(" & (%.2f) & (%.2f) & & \\\\", dose_tech_new$se, dose_formal_new$se),
  sprintf("Intensified (250+) $\\times$ Post & %.2f%s & %.2f%s & & \\\\",
          dose_tech_int$beta, dose_tech_int$stars, dose_formal_int$beta, dose_formal_int$stars),
  sprintf(" & (%.2f) & (%.2f) & & \\\\", dose_tech_int$se, dose_formal_int$se),
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel C: Placebo (250+ vs.\\ 50--249, both regulated)}} \\\\",
  sprintf("Placebo Treated $\\times$ Post & %.2f%s & %.2f%s & & %d \\\\",
          plac_tech$beta, plac_tech$stars, plac_formal$beta, plac_formal$stars, plac_tech$n),
  sprintf(" & (%.2f) & (%.2f) & & \\\\", plac_tech$se, plac_formal$se),
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel D: Security Incidents}} \\\\",
  sprintf("Treated $\\times$ Post & & & %.2f%s & %d \\\\",
          inc$beta, inc$stars, inc$n),
  sprintf(" & & & (%.2f) & \\\\", inc$se),
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel E: Mandated vs.\\ Non-Mandated Measures}} \\\\",
  sprintf("Treated $\\times$ Post & \\multicolumn{2}{c}{%.2f%s} & & %d \\\\",
          mand_base$beta, mand_base$stars, mand_base$n),
  sprintf(" & \\multicolumn{2}{c}{(%.2f)} & & \\\\", mand_base$se),
  sprintf("$\\times$ NIS2 Mandated & \\multicolumn{2}{c}{%.2f%s} & & \\\\",
          mand_int$beta, mand_int$stars),
  sprintf(" & \\multicolumn{2}{c}{(%.2f)} & & \\\\", mand_int$se),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} All specifications include country and size-class fixed effects. Panels A--C use country $\\times$ year FE where possible. Panel D outcome is the mean percentage of enterprises reporting security incidents. Panel E pools all 14 indicators with indicator FE and interacts treatment with a dummy for NIS2-specifically-mandated measures (risk assessment, encryption, training, formal policy). Standard errors clustered by country. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, "tables/tab4_robustness.tex")

# ----------------------------------------------------------------
# Table 5: Event Study / Pre-Trends
# ----------------------------------------------------------------

cat("Generating Table 5: Event Study...\n")

es_t19 <- extract_did(results$es_tech, "treat_2019")
es_t24 <- extract_did(results$es_tech, "treat_2024")
es_f19 <- extract_did(results$es_formal, "treat_2019")
es_f24 <- extract_did(results$es_formal, "treat_2024")

tab5_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Event Study: Pre-Trends and Treatment Effects}",
  "\\label{tab:event_study}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & Technical Index & Formal Index \\\\",
  "\\midrule",
  sprintf("Treated $\\times$ 2019 & %.3f%s & %.3f%s \\\\",
          es_t19$beta, es_t19$stars, es_f19$beta, es_f19$stars),
  sprintf(" & (%.3f) & (%.3f) \\\\", es_t19$se, es_f19$se),
  "Treated $\\times$ 2022 & \\multicolumn{2}{c}{(reference period)} \\\\",
  sprintf("Treated $\\times$ 2024 & %.3f%s & %.3f%s \\\\",
          es_t24$beta, es_t24$stars, es_f24$beta, es_f24$stars),
  sprintf(" & (%.3f) & (%.3f) \\\\", es_t24$se, es_f24$se),
  "\\midrule",
  "Country FE & Yes & Yes \\\\",
  "Size FE & Yes & Yes \\\\",
  "Year FE & Yes & Yes \\\\",
  sprintf("Observations & %d & %d \\\\", es_t19$n, es_f19$n),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Event study with 2022 as the reference period. Treated = 50--249 employee firms. The coefficient on Treated $\\times$ 2019 tests the parallel trends assumption: a near-zero, insignificant coefficient indicates parallel pre-trends between treated and control size classes. Standard errors clustered by country. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab5_lines, "tables/tab5_event_study.tex")

# ----------------------------------------------------------------
# SDE Table (Appendix F1 — MANDATORY)
# ----------------------------------------------------------------

cat("Generating SDE Table...\n")

# Main estimand: effect of NIS2 on formal compliance index
# Use preferred spec (m3_formal with country × year FE)
beta_formal <- coef(results$m3_formal)["treat_post"]
se_formal <- se(results$m3_formal)["treat_post"]
sd_y_formal <- sd(did_data$index_formal, na.rm = TRUE)
sde_formal <- beta_formal / sd_y_formal
se_sde_formal <- se_formal / sd_y_formal

# Technical index
beta_tech <- coef(results$m3_tech)["treat_post"]
se_tech <- se(results$m3_tech)["treat_post"]
sd_y_tech <- sd(did_data$index_technical, na.rm = TRUE)
sde_tech <- beta_tech / sd_y_tech
se_sde_tech <- se_tech / sd_y_tech

# Compulsory training (individual indicator)
ind_panel_did <- indicator_panel %>% filter(size_class %in% c("10-49", "50-249"))
m_training <- feols(value ~ treat_post | country + size_factor + country^factor(year),
                    data = ind_panel_did %>% filter(indicator == "E_SECAWCTP"),
                    cluster = ~country)
beta_train <- coef(m_training)["treat_post"]
se_train <- se(m_training)["treat_post"]
sd_y_train <- sd(ind_panel_did$value[ind_panel_did$indicator == "E_SECAWCTP"], na.rm = TRUE)
sde_train <- beta_train / sd_y_train
se_sde_train <- se_train / sd_y_train

# Security incidents
inc_raw <- readRDS("data/ict_incidents_raw.rds")
eu27 <- c("AT","BE","BG","CY","CZ","DE","DK","EE","EL","ES","FI","FR",
          "HR","HU","IE","IT","LT","LU","LV","MT","NL","PL","PT","RO","SE","SI","SK")
inc_did <- inc_raw %>%
  filter(size_emp %in% c("10-49","50-249"), geo %in% eu27,
         unit == "PC_ENT", TIME_PERIOD %in% c(2019,2022,2024)) %>%
  rename(country=geo, year=TIME_PERIOD, value=values, size_class=size_emp) %>%
  filter(!is.na(value)) %>%
  group_by(country, year, size_class) %>%
  summarize(incident_rate = mean(value, na.rm=TRUE), .groups="drop") %>%
  mutate(treated = as.integer(size_class=="50-249"),
         post = as.integer(year==2024),
         treat_post = treated*post,
         size_factor = factor(size_class))
m_inc <- feols(incident_rate ~ treat_post | country + size_factor + factor(year),
               data = inc_did, cluster = ~country)
beta_inc <- coef(m_inc)["treat_post"]
se_inc <- se(m_inc)["treat_post"]
sd_y_inc <- sd(inc_did$incident_rate, na.rm = TRUE)
sde_inc <- beta_inc / sd_y_inc
se_sde_inc <- se_inc / sd_y_inc

# Classification function
classify <- function(s) dplyr::case_when(
  s < -0.15 ~ "Large negative",
  s < -0.05 ~ "Moderate negative",
  s < -0.005 ~ "Small negative",
  s < 0.005 ~ "Null",
  s < 0.05 ~ "Small positive",
  s < 0.15 ~ "Moderate positive",
  TRUE ~ "Large positive"
)

# Heterogeneity: early vs late transposers for formal index
# Heterogeneity: high vs low baseline formal adoption
# Split at median country-level 2019 formal adoption for 50-249 firms
baseline <- did_data %>%
  filter(year == 2019, size_class == "50-249") %>%
  select(country, index_formal) %>%
  rename(baseline_formal = index_formal)

median_baseline <- median(baseline$baseline_formal, na.rm = TRUE)

high_countries <- baseline$country[baseline$baseline_formal >= median_baseline]
low_countries <- baseline$country[baseline$baseline_formal < median_baseline]

did_high <- did_data %>% filter(country %in% high_countries)
did_low <- did_data %>% filter(country %in% low_countries)

m_high <- feols(index_formal ~ treat_post | country + size_factor + factor(year),
                data = did_high, cluster = ~country)
m_low <- feols(index_formal ~ treat_post | country + size_factor + factor(year),
               data = did_low, cluster = ~country)

beta_early <- coef(m_high)["treat_post"]
se_early <- se(m_high)["treat_post"]
sd_y_early <- sd(did_high$index_formal, na.rm = TRUE)
sde_early <- beta_early / sd_y_early
se_sde_early <- se_early / sd_y_early

beta_late <- coef(m_low)["treat_post"]
se_late <- se(m_low)["treat_post"]
sd_y_late <- sd(did_low$index_formal, na.rm = TRUE)
sde_late <- beta_late / sd_y_late
se_sde_late <- se_late / sd_y_late

# Build SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} European Union (27 member states). ",
  "\\textbf{Research question:} Whether the EU NIS2 Directive's 50-employee regulatory threshold increases cybersecurity investment among newly regulated medium-sized firms, distinguishing technical security measures from formal compliance documentation. ",
  "\\textbf{Policy mechanism:} NIS2 (Directive 2022/2555) imposes mandatory risk management, incident reporting within 24 hours, supply chain security audits, and staff awareness training on enterprises with 50 or more employees in essential and important sectors, while exempting smaller firms below the threshold. ",
  "\\textbf{Outcome definition:} Technical Index is the mean adoption rate (percentage of enterprises) across eight technical measures (encryption, VPN, network access control, log maintenance, backup, password policy, security testing, biometric authentication); Formal Index averages six formal compliance measures (security policy, risk assessment, awareness activities, compulsory training, voluntary training, contractual obligations); Compulsory Training is the share of enterprises providing mandatory ICT security courses; Security Incidents is the mean share reporting incidents. ",
  "\\textbf{Treatment:} Binary; firms with 50--249 employees (newly NIS2-covered) versus 10--49 employees (exempt). ",
  "\\textbf{Data:} Eurostat ICT Security Survey (isoc\\_cisce\\_ra and isoc\\_cisce\\_ic), triennial waves 2019, 2022, 2024, at country $\\times$ size-class level, 162 observations for the main specification. ",
  "\\textbf{Method:} Two-period difference-in-differences with country, size-class, and country $\\times$ year fixed effects; standard errors clustered by country (27 clusters); randomization inference with 1,000 permutations. ",
  "\\textbf{Sample:} All EU27 member states with non-missing data in the Eurostat ICT security survey across all three waves; firms in NACE sectors C10--S951 excluding financial services. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("Technical Index & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\",
          beta_tech, se_tech, sd_y_tech, sde_tech, se_sde_tech, classify(sde_tech)),
  sprintf("Formal Index & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\",
          beta_formal, se_formal, sd_y_formal, sde_formal, se_sde_formal, classify(sde_formal)),
  sprintf("Compulsory Training & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\",
          beta_train, se_train, sd_y_train, sde_train, se_sde_train, classify(sde_train)),
  sprintf("Security Incidents & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\",
          beta_inc, se_inc, sd_y_inc, sde_inc, se_sde_inc, classify(sde_inc)),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Formal Index by Baseline Adoption)}} \\\\",
  sprintf("High-baseline countries & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\",
          beta_early, se_early, sd_y_early, sde_early, se_sde_early, classify(sde_early)),
  sprintf("Low-baseline countries & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\",
          beta_late, se_late, sd_y_late, sde_late, se_sde_late, classify(sde_late)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(sde_lines, "tables/tabF1_sde.tex")

cat("=== All tables generated ===\n")
cat("Files written:\n")
cat("  tables/tab1_summary.tex\n")
cat("  tables/tab2_main_did.tex\n")
cat("  tables/tab3_indicators.tex\n")
cat("  tables/tab4_robustness.tex\n")
cat("  tables/tab5_event_study.tex\n")
cat("  tables/tabF1_sde.tex\n")
