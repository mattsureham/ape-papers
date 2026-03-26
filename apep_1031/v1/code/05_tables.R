# =============================================================================
# 05_tables.R — Generate all tables for the paper
# apep_1031: Kitchen Table Capitalism
# =============================================================================

source("00_packages.R")

results <- readRDS("../data/main_results.rds")
robustness <- readRDS("../data/robustness_results.rds")
pre_sds <- readRDS("../data/pre_treatment_sds.rds")
df <- readRDS("../data/analysis_panel.rds")
treatment <- readRDS("../data/treatment_coding.rds")

dir.create("../tables", showWarnings = FALSE)

# Helper to extract fixest results
get_res <- function(fit) {
  b <- coef(fit)["post"]
  s <- se(fit)["post"]
  p <- pvalue(fit)["post"]
  list(att = b, se = s, p = p)
}

# =============================================================================
# TABLE 1: Summary Statistics
# =============================================================================
cat("Generating Table 1: Summary Statistics\n")

df_722 <- df %>% filter(industry == "722")
df_311 <- df %>% filter(industry == "311")

pre_722 <- df_722 %>% filter(time_q < 2010)
pre_311 <- df_311 %>% filter(time_q < 2010)

n_treated <- n_distinct(treatment$state_fips)
n_control <- n_distinct(df_722$state_fips) - n_treated

tab1_latex <- paste0(
  "\\begin{table}[t]\n\\centering\n",
  "\\caption{Pre-Treatment Summary Statistics}\n\\label{tab:summary}\n",
  "\\begin{tabular}{lcccc}\n\\toprule\n",
  " & \\multicolumn{2}{c}{Treated (", n_treated, " states)} & \\multicolumn{2}{c}{Control (", n_control, " states)} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  " & Mean & SD & Mean & SD \\\\\n\\midrule\n"
)

# Employment stats
for (ind_label in c("722", "311")) {
  pre_data <- if(ind_label == "722") pre_722 else pre_311
  tr <- pre_data %>% filter(first_treat > 0)
  ct <- pre_data %>% filter(first_treat == 0)
  lab <- ifelse(ind_label == "722", "Food Services (722)", "Food Mfg (311)")
  tab1_latex <- paste0(tab1_latex, sprintf(
    "%s: Employment & %s & (%s) & %s & (%s) \\\\\n",
    lab,
    formatC(mean(tr$Emp, na.rm=T), format="f", digits=0, big.mark=","),
    formatC(sd(tr$Emp, na.rm=T), format="f", digits=0, big.mark=","),
    formatC(mean(ct$Emp, na.rm=T), format="f", digits=0, big.mark=","),
    formatC(sd(ct$Emp, na.rm=T), format="f", digits=0, big.mark=",")))
}

tab1_latex <- paste0(tab1_latex,
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\footnotesize Years: 2005--2009 (pre first treatment).} \\\\\n",
  "\\multicolumn{5}{l}{\\footnotesize Source: QWI/LEHD. Employment = annual average of quarterly counts.} \\\\\n",
  "\\bottomrule\n\\end{tabular}\n\\end{table}\n")

writeLines(tab1_latex, "../tables/tab1_summary.tex")

# =============================================================================
# TABLE 2: Main Results
# =============================================================================
cat("Generating Table 2: Main Results\n")

specs <- list(
  list("log(Employment)", results$twfe_722_emp, "722"),
  list("Entry Rate", results$twfe_722_entry, "722"),
  list("log(Avg Earnings)", results$twfe_722_earn, "722"),
  list("log(Employment)", results$twfe_311_emp, "311"),
  list("Entry Rate", results$twfe_311_entry, "311"),
  list("log(Employment)", results$twfe_mfg, "mfg")
)

tab2_latex <- paste0(
  "\\begin{table}[t]\n\\centering\n",
  "\\caption{Effect of Food Deregulation on Formal Food-Sector Labor Markets}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lcccc}\n\\toprule\n",
  " & Coef & SE & $p$-value & $N$ \\\\\n\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Food Services (NAICS 722)}} \\\\\n")

for (s in specs) {
  r <- get_res(s[[2]])
  stars <- ifelse(r$p < 0.01, "***", ifelse(r$p < 0.05, "**", ifelse(r$p < 0.10, "*", "")))
  panel_label <- ""
  if (s[[3]] == "311" && s[[1]] == "log(Employment)") {
    panel_label <- "\\midrule\n\\multicolumn{5}{l}{\\textit{Panel B: Food Manufacturing (NAICS 311)}} \\\\\n"
  }
  if (s[[3]] == "mfg") {
    panel_label <- "\\midrule\n\\multicolumn{5}{l}{\\textit{Panel C: Placebo --- All Manufacturing (NAICS 31--33)}} \\\\\n"
  }
  tab2_latex <- paste0(tab2_latex, panel_label,
    sprintf("%s & %.4f%s & (%.4f) & %.3f & %s \\\\\n",
            s[[1]], r$att, stars, r$se, r$p,
            formatC(nobs(s[[2]]), big.mark=",")))
}

tab2_latex <- paste0(tab2_latex,
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\footnotesize TWFE with state and year FE. Clustered at state level.} \\\\\n",
  "\\multicolumn{5}{l}{\\footnotesize 23 treated states (7 food freedom + 16 major cottage food expansion).} \\\\\n",
  "\\multicolumn{5}{l}{\\footnotesize Sun--Abraham ATT shown in robustness. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.} \\\\\n",
  "\\bottomrule\n\\end{tabular}\n\\end{table}\n")

writeLines(tab2_latex, "../tables/tab2_main.tex")

# =============================================================================
# TABLE 3: Robustness
# =============================================================================
cat("Generating Table 3: Robustness\n")

r_main <- get_res(results$twfe_722_emp)
# Re-run SA to get ATT (aggregate needs data in scope)
df_722_sa <- readRDS("../data/analysis_panel.rds") %>%
  filter(industry == "722", !is.na(log_emp)) %>%
  mutate(post = as.numeric(first_treat > 0 & time_q >= first_treat),
         cohort = ifelse(first_treat > 0, first_treat, 10000))

sa_fresh <- feols(log_emp ~ sunab(cohort, time_q) | state_fips + time_q,
                  data = df_722_sa, cluster = ~state_fips)
r_sa <- tryCatch(summary(aggregate(sa_fresh, agg = "ATT")), error = function(e) NULL)
r_t1 <- get_res(robustness$tier1)
r_pre <- get_res(robustness$precovid)

tab3_latex <- paste0(
  "\\begin{table}[t]\n\\centering\n",
  "\\caption{Robustness: log(Employment) in NAICS 722}\n\\label{tab:robustness}\n",
  "\\begin{tabular}{lccc}\n\\toprule\n",
  " & Coef & SE & $p$-value \\\\\n\\midrule\n",
  sprintf("Main (TWFE, all 23 states) & %.4f & (%.4f) & %.3f \\\\\n", r_main$att, r_main$se, r_main$p),
  if (!is.null(r_sa)) sprintf("Sun--Abraham ATT & %.4f & (%.4f) & %.3f \\\\\n", as.numeric(r_sa[1,1]), as.numeric(r_sa[1,2]), as.numeric(r_sa[1,4])) else "Sun--Abraham ATT & --- & --- & --- \\\\\n",
  sprintf("Food Freedom Acts only (7 states) & %.4f & (%.4f) & %.3f \\\\\n", r_t1$att, r_t1$se, r_t1$p),
  sprintf("Pre-COVID cohorts only & %.4f & (%.4f) & %.3f \\\\\n", r_pre$att, r_pre$se, r_pre$p))

if (!is.null(robustness$wcb)) {
  tab3_latex <- paste0(tab3_latex,
    sprintf("Wild cluster bootstrap $p$-value & & & %.3f \\\\\n", robustness$wcb$p_val))
}

tab3_latex <- paste0(tab3_latex,
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\footnotesize All: outcome is log(employment) in NAICS 722.} \\\\\n",
  "\\multicolumn{4}{l}{\\footnotesize Pre-COVID drops cohorts treated 2020 or later.} \\\\\n",
  "\\bottomrule\n\\end{tabular}\n\\end{table}\n")

writeLines(tab3_latex, "../tables/tab3_robustness.tex")

# =============================================================================
# TABLE 4: Heterogeneity
# =============================================================================
cat("Generating Table 4: Heterogeneity\n")

r_f <- get_res(robustness$het_female)
r_m <- get_res(robustness$het_male)

tab4_latex <- paste0(
  "\\begin{table}[t]\n\\centering\n",
  "\\caption{Heterogeneity by Worker Sex: log(Employment) in NAICS 722}\n",
  "\\label{tab:heterogeneity}\n",
  "\\begin{tabular}{lccc}\n\\toprule\n",
  " & Coef & SE & $p$-value \\\\\n\\midrule\n",
  sprintf("Pooled & %.4f & (%.4f) & %.3f \\\\\n", r_main$att, r_main$se, r_main$p),
  sprintf("Female workers & %.4f & (%.4f) & %.3f \\\\\n", r_f$att, r_f$se, r_f$p),
  sprintf("Male workers & %.4f & (%.4f) & %.3f \\\\\n", r_m$att, r_m$se, r_m$p),
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\footnotesize TWFE with state and year FE. NAICS 722 (Food Services).} \\\\\n",
  "\\bottomrule\n\\end{tabular}\n\\end{table}\n")

writeLines(tab4_latex, "../tables/tab4_heterogeneity.tex")

# =============================================================================
# TABLE F1: Standardized Effect Sizes (SDE)
# =============================================================================
cat("Generating Table F1: SDE\n")

classify_sde <- function(s) {
  case_when(s < -0.15 ~ "Large negative", s < -0.05 ~ "Moderate negative",
            s < -0.005 ~ "Small negative", s <= 0.005 ~ "Null",
            s <= 0.05 ~ "Small positive", s <= 0.15 ~ "Moderate positive",
            TRUE ~ "Large positive")
}

make_sde <- function(fit, sd_y) {
  b <- coef(fit)["post"]; s <- se(fit)["post"]
  sde <- b / sd_y; se_sde <- s / sd_y
  list(beta = b, se = s, sd_y = sd_y, sde = sde, se_sde = se_sde,
       cls = classify_sde(sde))
}

sde_rows <- list(
  list("NAICS 722: log(Emp)", results$twfe_722_emp, pre_sds$sd_log_emp_722),
  list("NAICS 722: Entry Rate", results$twfe_722_entry, pre_sds$sd_entry_722),
  list("NAICS 722: log(Earn)", results$twfe_722_earn, pre_sds$sd_log_earn_722),
  list("NAICS 311: log(Emp)", results$twfe_311_emp, pre_sds$sd_log_emp_311),
  list("NAICS 311: Entry Rate", results$twfe_311_entry, pre_sds$sd_entry_311)
)

# Heterogeneity panel
pre_sex <- readRDS("../data/sex_panel.rds") %>% filter(time_q < 2010)
sd_f <- sd(pre_sex$log_emp[pre_sex$sex_label == "Female"], na.rm = TRUE)
sd_m <- sd(pre_sex$log_emp[pre_sex$sex_label == "Male"], na.rm = TRUE)

sde_het <- list(
  list("Female: log(Emp)", robustness$het_female, sd_f),
  list("Male: log(Emp)", robustness$het_male, sd_m)
)

fmt4 <- function(x) formatC(x, format = "f", digits = 4)

sde_notes <- paste0(
  "\\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state food deregulation laws---food freedom acts and major cottage food expansions---affect formal food-sector employment, firm entry, and earnings? ",
  "\\textbf{Policy mechanism:} Food freedom acts and major cottage food expansions remove or substantially reduce licensing, permitting, labeling, and inspection requirements for home-based food production, allowing residents to sell homemade food products directly to consumers with fewer regulatory barriers. ",
  "\\textbf{Outcome definition:} Employment is annual average of quarterly beginning-of-quarter counts from QWI; entry rate is firm job gains divided by employment; earnings is total quarterly earnings divided by employment. ",
  "\\textbf{Treatment:} Binary; state enacted a food freedom act or major cottage food expansion (23 treated states, staggered 2010--2022). ",
  "\\textbf{Data:} Quarterly Workforce Indicators (QWI/LEHD), 2005--2025, state-level annual panels for NAICS 311 and 722, approximately 2,100 state-year observations. ",
  "\\textbf{Method:} Two-way fixed effects (state + year); Sun--Abraham for heterogeneity robustness; standard errors clustered at state level. ",
  "\\textbf{Sample:} All 52 states (including DC and territories); 23 deregulation states as treated, 29 as never-treated controls; private-sector employment only. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[t]\n\\centering\n\\caption{Standardized Effect Sizes}\n\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n")

for (r in sde_rows) {
  s <- make_sde(r[[2]], r[[3]])
  tabF1 <- paste0(tabF1, sprintf(
    "%s & %s & %s & %s & %s & %s & %s \\\\\n",
    r[[1]], fmt4(s$beta), fmt4(s$se), fmt4(s$sd_y), fmt4(s$sde), fmt4(s$se_sde), s$cls))
}

tabF1 <- paste0(tabF1, "\\midrule\n\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by worker sex, NAICS 722)}} \\\\\n")

for (r in sde_het) {
  s <- make_sde(r[[2]], r[[3]])
  tabF1 <- paste0(tabF1, sprintf(
    "%s & %s & %s & %s & %s & %s & %s \\\\\n",
    r[[1]], fmt4(s$beta), fmt4(s$se), fmt4(s$sd_y), fmt4(s$sde), fmt4(s$se_sde), s$cls))
}

tabF1 <- paste0(tabF1,
  "\\bottomrule\n\\end{tabular}\n\n",
  "\\vspace{0.5em}\n\\begin{minipage}{0.95\\textwidth}\n\\footnotesize\n",
  sde_notes, "\n\\end{minipage}\n\\end{table}\n")

writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("All tables generated.\n")
