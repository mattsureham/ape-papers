source("00_packages.R")

cat("=== Generating tables ===\n")

panel <- readRDS("../data/analysis_panel.rds")
results <- readRDS("../data/main_results.rds")
robustness <- readRDS("../data/robustness_results.rds")

# ---------------------------------------------------------------
# Table 1: Summary Statistics
# ---------------------------------------------------------------
cat("\n--- Table 1: Summary Statistics ---\n")

sum_data <- panel %>%
  filter(year <= 2015) %>%
  select(emp_ths, gdp_mio, pop, unemp_rate, foreign_share, emp_per_capita, gdp_per_capita) %>%
  drop_na()

make_row <- function(x, label) {
  sprintf("%s & %.2f & %.2f & %.2f & %.2f \\\\",
          label,
          mean(x, na.rm = TRUE), sd(x, na.rm = TRUE),
          min(x, na.rm = TRUE), max(x, na.rm = TRUE))
}

# Pre-treatment balance by treatment group
balance_data <- panel %>%
  filter(year == 2015) %>%
  group_by(suspended) %>%
  summarise(
    n = n(),
    emp = mean(emp_ths, na.rm = TRUE),
    gdp = mean(gdp_mio, na.rm = TRUE),
    pop = mean(pop, na.rm = TRUE),
    unemp = mean(unemp_rate, na.rm = TRUE),
    foreign_sh = mean(foreign_share, na.rm = TRUE),
    .groups = "drop"
  )

n_total <- nrow(panel %>% filter(year == 2015))
n_treated <- balance_data$n[balance_data$suspended == 1]
n_control <- balance_data$n[balance_data$suspended == 0]

tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: Pre-Treatment Characteristics (2012--2015)}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\footnotesize",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Suspended} & \\multicolumn{2}{c}{Maintained} & \\multicolumn{2}{c}{Difference} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}",
  " & Mean & SD & Mean & SD & Diff & $p$-value \\\\",
  "\\midrule"
)

vars <- list(
  list(var = "emp_ths", label = "Employment (000s)"),
  list(var = "gdp_mio", label = "GDP (mn EUR)"),
  list(var = "pop", label = "Population"),
  list(var = "unemp_rate", label = "Unemp.\\ rate (\\%)"),
  list(var = "emp_per_capita", label = "Emp./capita")
)

pre_data <- panel %>% filter(year >= 2012, year <= 2015)

for (v in vars) {
  treated_vals <- pre_data %>% filter(suspended == 1) %>% pull(!!sym(v$var))
  control_vals <- pre_data %>% filter(suspended == 0) %>% pull(!!sym(v$var))
  treated_vals <- treated_vals[!is.na(treated_vals)]
  control_vals <- control_vals[!is.na(control_vals)]

  if (length(treated_vals) > 1 & length(control_vals) > 1) {
    tt <- t.test(treated_vals, control_vals)
    diff_val <- mean(treated_vals) - mean(control_vals)
    p_val <- tt$p.value
  } else {
    diff_val <- NA
    p_val <- NA
  }

  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %.2f & %.2f & %.2f & %.2f & %.2f & %.3f \\\\",
    v$label,
    mean(treated_vals), sd(treated_vals),
    mean(control_vals), sd(control_vals),
    diff_val, p_val
  ))
}

tab1_lines <- c(tab1_lines,
  "\\midrule",
  sprintf("Observations & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} & & \\\\",
          n_treated, n_control),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  sprintf("\\item \\textit{Notes:} Pre-treatment averages (2012--2015). Unit: NUTS-3 region (\\textit{Kreis}). Suspended = Vorrangpr\\\"ufung suspended (N~=~%d); Maintained = retained (N~=~%d). $p$-values from two-sample $t$-tests.", n_treated, n_control),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("  Table 1 written\n")

# ---------------------------------------------------------------
# Table 2: Main DiD Results
# ---------------------------------------------------------------
cat("\n--- Table 2: Main DiD Results ---\n")

m1 <- results$m1
m2 <- results$m2
m3 <- results$m3
m4 <- results$m4
m5 <- results$m5

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of Vorrangpr\\\"ufung Suspension on Regional Outcomes}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & Log Emp & Log Emp & Log GDP & Emp/Cap & GDP/Cap \\\\",
  "\\midrule"
)

models <- list(m1, m2, m3, m4, m5)
coef_name <- "treat_post"

for (i in seq_along(models)) {
  m <- models[[i]]
  b <- coef(m)[coef_name]
  se <- sqrt(vcov(m)[coef_name, coef_name])
  pv <- 2 * pnorm(-abs(b / se))
  stars <- ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.1, "*", "")))

  if (i == 1) {
    tab2_lines <- c(tab2_lines, sprintf(
      "Suspended $\\times$ Post & %.4f%s", b, stars))
  } else {
    tab2_lines[length(tab2_lines)] <- paste0(
      tab2_lines[length(tab2_lines)], sprintf(" & %.4f%s", b, stars))
  }
}
tab2_lines[length(tab2_lines)] <- paste0(tab2_lines[length(tab2_lines)], " \\\\")

# SE row
se_line <- "                       "
for (i in seq_along(models)) {
  m <- models[[i]]
  se <- sqrt(vcov(m)[coef_name, coef_name])
  sep <- if (i == 1) "" else " & "
  se_line <- paste0(se_line, sprintf("%s(%.4f)", sep, se))
}
tab2_lines <- c(tab2_lines, paste0(se_line, " \\\\"), "\\\\")

# Fixed effects rows
tab2_lines <- c(tab2_lines,
  "Region FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & --- & Yes & Yes & Yes \\\\",
  "State $\\times$ Year FE & --- & Yes & --- & --- & --- \\\\"
)

# N and R2
n_line <- "Observations"
r2_line <- "$R^2$"
for (i in seq_along(models)) {
  m <- models[[i]]
  n_line <- paste0(n_line, sprintf(" & %s", format(m$nobs, big.mark = ",")))
  r2_line <- paste0(r2_line, sprintf(" & %.3f", r2(m, "ar2")))
}
tab2_lines <- c(tab2_lines, "\\midrule",
                paste0(n_line, " \\\\"),
                paste0(r2_line, " \\\\"))

tab2_lines <- c(tab2_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  "\\item \\textit{Notes:} Standard errors clustered at the NUTS-2 level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. Treatment is binary: 1 if the Vorrangpr\\\"ufung was suspended in the region's employment agency district (August 2016), 0 if maintained. Post = 2017--2021. Columns (1)--(2): log total employment (thousands). Column (3): log GDP (million EUR). Column (4): employment per capita. Column (5): GDP per capita (EUR).",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")
cat("  Table 2 written\n")

# ---------------------------------------------------------------
# Table 3: Event Study Coefficients
# ---------------------------------------------------------------
cat("\n--- Table 3: Event Study ---\n")

es <- results$es_m1
es_coefs <- coeftable(es)

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Event Study: Log Employment Response to Vorrangpr\\\"ufung Suspension}",
  "\\label{tab:eventstudy}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Event Time & Coefficient & SE \\\\",
  "\\midrule"
)

es_names <- rownames(es_coefs)
for (j in seq_along(es_names)) {
  nm <- es_names[j]
  b <- es_coefs[j, "Estimate"]
  se <- es_coefs[j, "Std. Error"]
  pv <- es_coefs[j, "Pr(>|t|)"]
  stars <- ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.1, "*", "")))

  event_t <- str_extract(nm, "-?\\d+")
  if (is.na(event_t)) event_t <- nm

  tab3_lines <- c(tab3_lines, sprintf(
    "$t = %s$ & %.4f%s & (%.4f) \\\\", event_t, b, stars, se))
}

tab3_lines <- c(tab3_lines,
  "\\midrule",
  sprintf("Observations & \\multicolumn{2}{c}{%s} \\\\",
          format(es$nobs, big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  "\\item \\textit{Notes:} Event study coefficients from the interaction of Suspended $\\times$ event-time dummies, with $t = -1$ (2015) as the reference period. Region and year fixed effects included. Standard errors clustered at the NUTS-2 level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_eventstudy.tex")
cat("  Table 3 written\n")

# ---------------------------------------------------------------
# Table 4: Robustness
# ---------------------------------------------------------------
cat("\n--- Table 4: Robustness ---\n")

rob_models <- list(
  results$m1,
  robustness$m_state_cl,
  robustness$m_matched,
  robustness$m_no_mv,
  robustness$m_placebo,
  robustness$m_bavaria
)
rob_labels <- c("Baseline", "State cl.", "Matched",
                "No MV", "Placebo", "Bavaria")
rob_coefs <- c("treat_post", "treat_post", "treat_post",
               "treat_post", "fake_treat", "treat_post")

tab4_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness: Alternative Specifications for Log Employment}",
  "\\label{tab:robustness}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  paste0(" & ", paste(sprintf("(%d)", 1:6), collapse = " & "), " \\\\"),
  paste0(" & ", paste(rob_labels, collapse = " & "), " \\\\"),
  "\\midrule"
)

coef_line <- "Treatment"
se_line <- "         "
n_line <- "Observations"
for (i in seq_along(rob_models)) {
  m <- rob_models[[i]]
  cn <- rob_coefs[i]
  b <- coef(m)[cn]
  se <- sqrt(vcov(m)[cn, cn])
  pv <- 2 * pnorm(-abs(b / se))
  stars <- ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.1, "*", "")))
  sep <- if (i == 1) " & " else " & "
  coef_line <- paste0(coef_line, sprintf("%s%.4f%s", sep, b, stars))
  se_line <- paste0(se_line, sprintf("%s(%.4f)", sep, se))
  n_line <- paste0(n_line, sprintf(" & %s", format(m$nobs, big.mark = ",")))
}

tab4_lines <- c(tab4_lines,
  paste0(coef_line, " \\\\"),
  paste0(se_line, " \\\\"),
  "\\midrule",
  paste0(n_line, " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  "\\item \\textit{Notes:} Dependent variable: log total employment (thousands) in all columns except~(5). Column~(1): baseline with NUTS-2 clustered SEs. Column~(2): state-level clustering. Column~(3): restricted to control regions in NRW/MV and treated regions with similar pre-treatment unemployment ($\\geq$~5\\%). Column~(4): drops Mecklenburg-Vorpommern. Column~(5): placebo test using 2014 as fake treatment year (pre-period only). Column~(6): within-Bavaria comparison. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_robustness.tex")
cat("  Table 4 written\n")

# ---------------------------------------------------------------
# Table F1: Standardized Effect Sizes (MANDATORY)
# ---------------------------------------------------------------
cat("\n--- Table F1: Standardized Effect Sizes ---\n")

# Panel A: Pooled
m1 <- results$m1
m3 <- results$m3

pre_panel <- panel %>% filter(year <= 2015)

beta_emp <- coef(m1)["treat_post"]
se_emp <- sqrt(vcov(m1)["treat_post", "treat_post"])
sd_y_emp <- sd(pre_panel$log_emp, na.rm = TRUE)
sde_emp <- beta_emp / sd_y_emp
se_sde_emp <- se_emp / sd_y_emp

beta_gdp <- coef(m3)["treat_post"]
se_gdp <- sqrt(vcov(m3)["treat_post", "treat_post"])
sd_y_gdp <- sd(pre_panel$log_gdp, na.rm = TRUE)
sde_gdp <- beta_gdp / sd_y_gdp
se_sde_gdp <- se_gdp / sd_y_gdp

classify_sde <- function(s) {
  case_when(
    s < -0.15  ~ "Large negative",
    s < -0.05  ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s <  0.005 ~ "Null",
    s <  0.05  ~ "Small positive",
    s <  0.15  ~ "Moderate positive",
    TRUE       ~ "Large positive"
  )
}

# Panel B: Heterogeneous (Bavaria vs rest)
panel_bav_treated <- panel %>% filter(state == "DE2", suspended == 1)
panel_nonbav_treated <- panel %>% filter(state != "DE2", suspended == 1)

m_bav <- feols(log_emp ~ treat_post | geo + year,
               data = panel %>% filter(state == "DE2"), cluster = ~nuts2)
m_nonbav <- feols(log_emp ~ treat_post | geo + year,
                  data = panel %>% filter(state != "DE2"), cluster = ~nuts2)

beta_bav <- coef(m_bav)["treat_post"]
se_bav <- sqrt(vcov(m_bav)["treat_post", "treat_post"])
sd_y_bav <- sd(pre_panel$log_emp[pre_panel$state == "DE2"], na.rm = TRUE)
sde_bav <- beta_bav / sd_y_bav
se_sde_bav <- se_bav / sd_y_bav

beta_nonbav <- coef(m_nonbav)["treat_post"]
se_nonbav <- sqrt(vcov(m_nonbav)["treat_post", "treat_post"])
sd_y_nonbav <- sd(pre_panel$log_emp[pre_panel$state != "DE2"], na.rm = TRUE)
sde_nonbav <- beta_nonbav / sd_y_nonbav
se_sde_nonbav <- se_nonbav / sd_y_nonbav

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Germany. ",
  "\\textbf{Research question:} Does removing the labor market priority check ",
  "(Vorrangpr\\\"ufung) for refugee hiring affect regional employment and GDP? ",
  "\\textbf{Policy mechanism:} The Vorrangpr\\\"ufung required the Federal Employment Agency ",
  "to verify no German or EU citizen was available before a refugee could be hired, ",
  "imposing compliance costs; its suspension removed this barrier in 133 of 156 districts. ",
  "\\textbf{Outcome definition:} Log total employment in thousands from Eurostat NUTS-3 ",
  "regional accounts, counting all employed persons regardless of nationality. ",
  "\\textbf{Treatment:} Binary: 1 if suspended (August 2016), 0 if maintained. ",
  "\\textbf{Data:} Eurostat NUTS-3 regional accounts, 2012--2021, unit is Kreis (county), ",
  sprintf("N~=~%s. ", format(nrow(panel), big.mark = ",")),
  "\\textbf{Method:} TWFE DiD with region and year fixed effects, SEs clustered at NUTS-2. ",
  "\\textbf{Sample:} All German NUTS-3 regions; control~=~23 Agenturbezirke that retained ",
  "the check (11 Bavaria, 7 NRW Ruhr, 5 Mecklenburg-Vorpommern). ",
  "SDE~$= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\scriptsize",
  "\\begin{tabular}{llcccccl}",
  "\\toprule",
  "Outcome & Spec. & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Class. \\\\",
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("Log employment & Baseline DiD & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          beta_emp, se_emp, sd_y_emp, sde_emp, se_sde_emp, classify_sde(sde_emp)),
  sprintf("Log GDP & Baseline DiD & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          beta_gdp, se_gdp, sd_y_gdp, sde_gdp, se_sde_gdp, classify_sde(sde_gdp)),
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous}} \\\\",
  sprintf("Log employment & Bavaria only & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          beta_bav, se_bav, sd_y_bav, sde_bav, se_sde_bav, classify_sde(sde_bav)),
  sprintf("Log employment & Non-Bavaria & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          beta_nonbav, se_nonbav, sd_y_nonbav, sde_nonbav, se_sde_nonbav, classify_sde(sde_nonbav)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")
cat("  Table F1 written\n")

cat("\n=== All tables generated ===\n")
