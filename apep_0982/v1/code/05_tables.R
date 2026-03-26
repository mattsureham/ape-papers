# 05_tables.R — Generate all LaTeX tables
source("00_packages.R")

annual <- readRDS("../data/annual_panel.rds")
cs_ba <- readRDS("../data/cs_black_accom.rds")
cs_wa <- readRDS("../data/cs_white_accom.rds")
cs_bm <- readRDS("../data/cs_black_mfg.rds")
ddd <- readRDS("../data/ddd_results.rds")
diag <- jsonlite::fromJSON("../data/diagnostics.json")

fmt <- function(x, d = 0) formatC(x, format = "f", digits = d, big.mark = ",")
fmtd <- function(x, d = 4) formatC(x, format = "f", digits = d)

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("Table 1: Summary Statistics\n")

summ <- annual %>%
  group_by(race_label, sector) %>%
  summarise(
    mean_emp = mean(Emp, na.rm = TRUE),
    sd_emp = sd(Emp, na.rm = TRUE),
    mean_hires = mean(HirA, na.rm = TRUE),
    sd_hires = sd(HirA, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  ) %>%
  mutate(label = case_when(
    race_label == "black" & sector == "accommodation" ~ "Black, Accommodation",
    race_label == "white" & sector == "accommodation" ~ "White, Accommodation",
    race_label == "black" & sector == "manufacturing" ~ "Black, Manufacturing",
    race_label == "white" & sector == "manufacturing" ~ "White, Manufacturing"
  ))

tab1 <- paste0(
  "\\begin{table}[t]\n\\centering\n",
  "\\caption{Summary Statistics: State-Level Employment by Race and Sector}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcccccc}\n\\hline\\hline\n",
  " & \\multicolumn{2}{c}{Employment} & \\multicolumn{2}{c}{Hires} & \\\\\n",
  "\\cmidrule(lr){2-3}\\cmidrule(lr){4-5}\n",
  " & Mean & SD & Mean & SD & $N$ \\\\\n\\hline\n"
)

for (i in 1:nrow(summ)) {
  tab1 <- paste0(tab1,
    summ$label[i], " & ",
    fmt(summ$mean_emp[i]), " & ",
    fmt(summ$sd_emp[i]), " & ",
    fmt(summ$mean_hires[i]), " & ",
    fmt(summ$sd_hires[i]), " & ",
    fmt(summ$n[i]), " \\\\\n"
  )
}

tab1 <- paste0(tab1,
  "\\hline\n",
  "\\multicolumn{6}{l}{\\footnotesize \\textit{Notes:} Quarterly Workforce Indicators (QWI), 2005--2024. Employment and hires are annual} \\\\\n",
  "\\multicolumn{6}{l}{\\footnotesize averages of quarterly state-level counts. Accommodation = NAICS 72. Manufacturing = NAICS 31--33.} \\\\\n",
  "\\multicolumn{6}{l}{\\footnotesize 41 states: 30 treated (permitless carry adopters) + 11 never-treated controls.} \\\\\n",
  "\\hline\\hline\n\\end{tabular}\n\\end{table}\n"
)
writeLines(tab1, "../tables/tab1_summary.tex")

# ============================================================
# Table 2: CS-DiD Main Results
# ============================================================
cat("Table 2: CS-DiD\n")

n_ba <- nrow(annual %>% filter(race_label == "black", sector == "accommodation"))
n_wa <- nrow(annual %>% filter(race_label == "white", sector == "accommodation"))
n_bm <- nrow(annual %>% filter(race_label == "black", sector == "manufacturing"))

tab2 <- paste0(
  "\\begin{table}[t]\n\\centering\n",
  "\\caption{Effect of Permitless Carry on Log Employment: Callaway-Sant'Anna}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lccc}\n\\hline\\hline\n",
  " & (1) & (2) & (3) \\\\\n",
  " & Black, Accom. & White, Accom. & Black, Mfg. \\\\\n\\hline\n",
  sprintf("ATT & %s & %s & %s \\\\\n",
    fmtd(cs_ba$overall$overall.att), fmtd(cs_wa$overall$overall.att), fmtd(cs_bm$overall$overall.att)),
  sprintf(" & (%s) & (%s) & (%s) \\\\\n",
    fmtd(cs_ba$overall$overall.se), fmtd(cs_wa$overall$overall.se), fmtd(cs_bm$overall$overall.se)),
  "\\hline\n",
  "Estimator & CS & CS & CS \\\\\n",
  "Control group & Never-treated & Never-treated & Never-treated \\\\\n",
  sprintf("State-years & %s & %s & %s \\\\\n", fmt(n_ba), fmt(n_wa), fmt(n_bm)),
  "\\hline\n",
  "\\multicolumn{4}{l}{\\footnotesize \\textit{Notes:} Callaway and Sant'Anna (2021) group-time ATT estimates aggregated to} \\\\\n",
  "\\multicolumn{4}{l}{\\footnotesize an overall ATT. Standard errors (analytical) in parentheses. Outcome: log quarterly} \\\\\n",
  "\\multicolumn{4}{l}{\\footnotesize employment at state level. Treatment: permitless carry adoption. Control: 11 never-adopted states.} \\\\\n",
  "\\hline\\hline\n\\end{tabular}\n\\end{table}\n"
)
writeLines(tab2, "../tables/tab2_main.tex")

# ============================================================
# Table 3: DDD Results
# ============================================================
cat("Table 3: DDD\n")

de <- ddd$emp
dh <- ddd$hires

tab3 <- paste0(
  "\\begin{table}[t]\n\\centering\n",
  "\\caption{Triple-Difference: Permitless Carry $\\times$ Black $\\times$ Accommodation}\n",
  "\\label{tab:ddd}\n",
  "\\begin{tabular}{lcc}\n\\hline\\hline\n",
  " & (1) & (2) \\\\\n",
  " & Log Employment & Log Hires \\\\\n\\hline\n",
  sprintf("Post $\\times$ Black $\\times$ Accom. & %s & %s \\\\\n",
    fmtd(coef(de)["post:is_black:is_accom"]), fmtd(coef(dh)["post:is_black:is_accom"])),
  sprintf(" & (%s) & (%s) \\\\\n",
    fmtd(se(de)["post:is_black:is_accom"]), fmtd(se(dh)["post:is_black:is_accom"])),
  sprintf("Post $\\times$ Black & %s & %s \\\\\n",
    fmtd(coef(de)["post:is_black"]), fmtd(coef(dh)["post:is_black"])),
  sprintf(" & (%s) & (%s) \\\\\n",
    fmtd(se(de)["post:is_black"]), fmtd(se(dh)["post:is_black"])),
  sprintf("Post $\\times$ Accom. & %s & %s \\\\\n",
    fmtd(coef(de)["post:is_accom"]), fmtd(coef(dh)["post:is_accom"])),
  sprintf(" & (%s) & (%s) \\\\\n",
    fmtd(se(de)["post:is_accom"]), fmtd(se(dh)["post:is_accom"])),
  "\\hline\n",
  "State $\\times$ Race $\\times$ Sector FE & Yes & Yes \\\\\n",
  "Year $\\times$ Race $\\times$ Sector FE & Yes & Yes \\\\\n",
  sprintf("Observations & %s & %s \\\\\n", fmt(nobs(de)), fmt(nobs(dh))),
  "Clustering & State & State \\\\\n",
  "\\hline\n",
  "\\multicolumn{3}{l}{\\footnotesize \\textit{Notes:} OLS with high-dimensional fixed effects (fixest). Standard errors} \\\\\n",
  "\\multicolumn{3}{l}{\\footnotesize clustered at state level in parentheses. Accommodation = NAICS 72.} \\\\\n",
  "\\multicolumn{3}{l}{\\footnotesize Manufacturing = NAICS 31--33 (reference sector). 41 states, 2005--2024.} \\\\\n",
  "\\hline\\hline\n\\end{tabular}\n\\end{table}\n"
)
writeLines(tab3, "../tables/tab3_ddd.tex")

# ============================================================
# Table 4: Robustness
# ============================================================
cat("Table 4: Robustness\n")

rob_pre <- readRDS("../data/rob_precovid.rds")
rob_nyt <- readRDS("../data/rob_nyt.rds")
rob_twfe <- readRDS("../data/rob_twfe.rds")
rob_ddd_pre <- readRDS("../data/rob_ddd_precovid.rds")
rob_ddd_no21 <- readRDS("../data/rob_ddd_no2021.rds")

tab4 <- paste0(
  "\\begin{table}[t]\n\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robust}\n",
  "\\begin{tabular}{lp{1.6cm}p{1.6cm}p{1.6cm}p{1.6cm}p{1.6cm}}\n\\hline\\hline\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & Baseline DDD & Pre-COVID DDD & Drop 2021 DDD & CS not-yet-treated & TWFE \\\\\n\\hline\n",
  "\\multicolumn{6}{l}{\\textit{Panel A: Triple-difference (Post $\\times$ Black $\\times$ Accom.)}} \\\\\n",
  sprintf("Estimate & %s & %s & %s & --- & --- \\\\\n",
    fmtd(coef(de)["post:is_black:is_accom"]),
    fmtd(coef(rob_ddd_pre)["post:is_black:is_accom"]),
    fmtd(coef(rob_ddd_no21)["post:is_black:is_accom"])),
  sprintf(" & (%s) & (%s) & (%s) & & \\\\\n",
    fmtd(se(de)["post:is_black:is_accom"]),
    fmtd(se(rob_ddd_pre)["post:is_black:is_accom"]),
    fmtd(se(rob_ddd_no21)["post:is_black:is_accom"])),
  "\\multicolumn{6}{l}{\\textit{Panel B: CS-DiD / TWFE (Black Accom. only)}} \\\\\n",
  sprintf("Estimate & --- & --- & --- & %s & %s \\\\\n",
    fmtd(rob_nyt$overall$overall.att),
    fmtd(coef(rob_twfe)["post"])),
  sprintf(" & & & & (%s) & (%s) \\\\\n",
    fmtd(rob_nyt$overall$overall.se),
    fmtd(se(rob_twfe)["post"])),
  "\\hline\n",
  "\\multicolumn{6}{l}{\\footnotesize \\textit{Notes:} Column 1 reproduces baseline DDD from Table~\\ref{tab:ddd}.} \\\\\n",
  "\\multicolumn{6}{l}{\\footnotesize Column 2 restricts to 2005--2019. Column 3 drops the 2021 adoption wave.} \\\\\n",
  "\\multicolumn{6}{l}{\\footnotesize Column 4 uses CS with not-yet-treated controls. Column 5 shows TWFE for comparison.} \\\\\n",
  "\\hline\\hline\n\\end{tabular}\n\\end{table}\n"
)
writeLines(tab4, "../tables/tab4_robust.tex")

# ============================================================
# Table F1: SDE Appendix
# ============================================================
cat("Table F1: SDE\n")

pre_ba <- annual %>%
  filter(race_label == "black", sector == "accommodation",
         first_treat_year == 0 | year < first_treat_year)
sd_log_emp <- sd(pre_ba$log_emp, na.rm = TRUE)
sd_log_hires <- sd(pre_ba$log_hires, na.rm = TRUE)

# Row 1: DDD employment
b1 <- coef(de)["post:is_black:is_accom"]
s1 <- se(de)["post:is_black:is_accom"]
sde1 <- b1 / sd_log_emp; se_sde1 <- s1 / sd_log_emp

# Row 2: DDD hires
b2 <- coef(dh)["post:is_black:is_accom"]
s2 <- se(dh)["post:is_black:is_accom"]
sde2 <- b2 / sd_log_hires; se_sde2 <- s2 / sd_log_hires

# Row 3: CS Black accom
b3 <- cs_ba$overall$overall.att
s3 <- cs_ba$overall$overall.se
sde3 <- b3 / sd_log_emp; se_sde3 <- s3 / sd_log_emp

classify <- function(s) {
  if (is.na(s)) return("---")
  if (s < -0.15) return("Large neg.")
  if (s < -0.05) return("Mod. neg.")
  if (s < -0.005) return("Small neg.")
  if (s <= 0.005) return("Null")
  if (s <= 0.05) return("Small pos.")
  if (s <= 0.15) return("Mod. pos.")
  "Large pos."
}

# Panel B: pre-COVID DDD
b4 <- coef(rob_ddd_pre)["post:is_black:is_accom"]
s4 <- se(rob_ddd_pre)["post:is_black:is_accom"]
sde4 <- b4 / sd_log_emp; se_sde4 <- s4 / sd_log_emp

# Panel B: White accommodation CS
pre_wa <- annual %>%
  filter(race_label == "white", sector == "accommodation",
         first_treat_year == 0 | year < first_treat_year)
sd_white <- sd(pre_wa$log_emp, na.rm = TRUE)
b5 <- cs_wa$overall$overall.att; s5 <- cs_wa$overall$overall.se
sde5 <- b5 / sd_white; se_sde5 <- s5 / sd_white

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do permitless concealed carry laws differentially reduce Black employment in customer-facing industries relative to White workers and non-customer-facing sectors? ",
  "\\textbf{Policy mechanism:} Permitless carry removes the government permit requirement for concealed firearm carrying in public spaces including restaurants, hotels, and retail establishments, expanding armed patronage in customer-facing workplaces. ",
  "\\textbf{Outcome definition:} Log average quarterly employment from QWI (LEHD) measuring jobs held by workers of a given race in accommodation and food services (NAICS 72) at the state level. ",
  "\\textbf{Treatment:} Binary state-level adoption of permitless concealed carry. ",
  sprintf("\\textbf{Data:} Census QWI (LEHD), 2005--2024, state-year-race-sector, %d states, %s state-year observations. ",
    diag$n_states, fmt(diag$n_obs)),
  "\\textbf{Method:} Triple-difference (state $\\times$ race $\\times$ sector FE, year $\\times$ race $\\times$ sector FE) for DDD rows; Callaway-Sant'Anna (2021) ATT with never-treated controls for CS rows; SEs clustered at state level. ",
  "\\textbf{Sample:} 30 states adopting permitless carry (2003--2024) plus 11 never-adopted controls; accommodation (NAICS 72) vs.\\ manufacturing (NAICS 31--33). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[t]\n\\centering\n",
  "\\caption{Standardized Effect Sizes}\n\\label{tab:sde}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lcccccc}\n\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sprintf("Log emp. (DDD) & %s & %s & %s & %s & %s & %s \\\\\n",
    fmtd(b1), fmtd(s1), fmtd(sd_log_emp,3), fmtd(sde1), fmtd(se_sde1), classify(sde1)),
  sprintf("Log hires (DDD) & %s & %s & %s & %s & %s & %s \\\\\n",
    fmtd(b2), fmtd(s2), fmtd(sd_log_hires,3), fmtd(sde2), fmtd(se_sde2), classify(sde2)),
  sprintf("Log emp. (CS, Black Accom.) & %s & %s & %s & %s & %s & %s \\\\\n",
    fmtd(b3), fmtd(s3), fmtd(sd_log_emp,3), fmtd(sde3), fmtd(se_sde3), classify(sde3)),
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample splits)}} \\\\\n",
  sprintf("Log emp. (pre-2020 sample) & %s & %s & %s & %s & %s & %s \\\\\n",
    fmtd(b4), fmtd(s4), fmtd(sd_log_emp,3), fmtd(sde4), fmtd(se_sde4), classify(sde4)),
  sprintf("Log emp. (White workers) & %s & %s & %s & %s & %s & %s \\\\\n",
    fmtd(b5), fmtd(s5), fmtd(sd_white,3), fmtd(sde5), fmtd(se_sde5), classify(sde5)),
  "\\hline\\hline\n\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\par\\vspace{0.3em}\n",
  "{\\footnotesize\n",
  "\\begin{itemize}[leftmargin=*,nosep]\n",
  sde_notes, "\n",
  "\\end{itemize}\n",
  "}\n",
  "\\end{table}\n"
)
writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("All tables generated.\n")
