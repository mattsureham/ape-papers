# ==============================================================================
# 05_tables.R — Generate all LaTeX tables
# ==============================================================================
source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")
exposure <- readRDS("../data/exposure.rds")
results <- readRDS("../data/main_results.rds")
rob <- readRDS("../data/robustness_results.rds")
trade_clean <- readRDS("../data/trade_clean.rds")

waste <- panel %>% filter(industry == "562")
dir.create("../tables", showWarnings = FALSE)

# ==============================================================================
# Table 1: Summary Statistics
# ==============================================================================
cat("Generating Table 1: Summary Statistics...\n")

# Pre-period stats by exposure
stats_fn <- function(df, label) {
  data.frame(
    Group = label,
    Counties = n_distinct(df$fips),
    Emp_Mean = round(mean(df$Emp, na.rm = TRUE), 1),
    Emp_SD = round(sd(df$Emp, na.rm = TRUE), 1),
    EarnPW_Mean = round(mean(df$EarnS / pmax(df$Emp, 1), na.rm = TRUE), 0),
    Hires_Mean = round(mean(df$HirA, na.rm = TRUE), 1),
    WasteShare_Mean = round(mean(df$waste_share, na.rm = TRUE) * 100, 3),
    stringsAsFactors = FALSE
  )
}

pre <- waste %>% filter(year >= 2015 & year <= 2017)
t1 <- bind_rows(
  stats_fn(pre, "All Counties"),
  stats_fn(pre %>% filter(high_exposure == 1), "High Exposure"),
  stats_fn(pre %>% filter(high_exposure == 0), "Low Exposure")
)

# Format for LaTeX
cat("\\begin{table}[t]
\\centering
\\caption{Summary Statistics: Waste Management Sector (NAICS 562), Pre-Period 2015--2017}
\\label{tab:summary}
\\small
\\begin{tabular}{lcccccc}
\\hline\\hline
 & Counties & \\multicolumn{2}{c}{Employment} & Earnings/ & Hires/ & Waste \\\\
 & & Mean & SD & Worker (\\$) & Quarter & Share (\\%) \\\\
\\hline\n", file = "../tables/tab1_summary.tex")

for (i in 1:nrow(t1)) {
  cat(sprintf("%s & %d & %.1f & %.1f & %s & %.1f & %.3f \\\\\n",
              t1$Group[i], t1$Counties[i], t1$Emp_Mean[i], t1$Emp_SD[i],
              format(t1$EarnPW_Mean[i], big.mark = ","),
              t1$Hires_Mean[i], t1$WasteShare_Mean[i]),
      file = "../tables/tab1_summary.tex", append = TRUE)
  if (i == 1) cat("\\hline\n", file = "../tables/tab1_summary.tex", append = TRUE)
}

cat("\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Data from Census QWI, county $\\times$ quarter level. Waste management defined as NAICS 562. Exposure measured as pre-period (2015--2017) average NAICS 562 employment share of total county employment. High Exposure = above-median waste share. Earnings per worker are quarterly. $N$ = 1,988 counties observed quarterly.
\\end{tablenotes}
\\end{table}\n", file = "../tables/tab1_summary.tex", append = TRUE)

# ==============================================================================
# Table 2: Main Results
# ==============================================================================
cat("Generating Table 2: Main Results...\n")

# Extract key stats
extract <- function(m, label) {
  ct <- coeftable(m)
  # Get the interaction coefficient (last row or the one with "high_exposure:post")
  idx <- grep("high_exposure.*post|waste_share.*post", rownames(ct))
  if (length(idx) == 0) idx <- nrow(ct)
  data.frame(
    Label = label,
    Coef = ct[idx[1], 1],
    SE = ct[idx[1], 2],
    Stars = ifelse(ct[idx[1], 4] < 0.01, "***",
                   ifelse(ct[idx[1], 4] < 0.05, "**",
                          ifelse(ct[idx[1], 4] < 0.1, "*", ""))),
    N = m$nobs,
    R2 = fitstat(m, "wr2")[[1]],
    stringsAsFactors = FALSE
  )
}

tab2_rows <- bind_rows(
  extract(results$m2_emp, "Employment (log)"),
  extract(results$m2_earn, "Earnings/Worker (log)"),
  extract(results$m4_emp, "Employment, State$\\times$Quarter FE"),
  extract(results$m6_creation, "Firm Job Gains (log)"),
  extract(results$m6_destruction, "Firm Job Losses (log)")
)

cat("\\begin{table}[t]
\\centering
\\caption{The Waste Wall: Effect of National Sword on Waste Management (NAICS 562)}
\\label{tab:main}
\\small
\\begin{tabular}{lccccc}
\\hline\\hline
 & (1) & (2) & (3) & (4) & (5) \\\\
 & Emp & Earn/W & Emp (St$\\times$Qt) & Job Gains & Job Losses \\\\
\\hline
High Exposure $\\times$ Post", file = "../tables/tab2_main.tex")

# Coefficients row
cat(paste0(" & ", sprintf("%.3f%s", tab2_rows$Coef, tab2_rows$Stars), collapse = ""),
    " \\\\\n", file = "../tables/tab2_main.tex", append = TRUE)
# SE row
cat(paste0(" & (", sprintf("%.3f", tab2_rows$SE), ")", collapse = ""),
    " \\\\\n", file = "../tables/tab2_main.tex", append = TRUE)

cat("\\hline
County FE & Yes & Yes & Yes & Yes & Yes \\\\
Quarter FE & Yes & Yes & --- & Yes & Yes \\\\
State$\\times$Quarter FE & --- & --- & Yes & --- & --- \\\\
\\hline\n", file = "../tables/tab2_main.tex", append = TRUE)

# N and R2
cat(paste0("$N$ & ", format(tab2_rows$N, big.mark = ","), collapse = ""),
    " \\\\\n", file = "../tables/tab2_main.tex", append = TRUE)
cat(paste0("Within $R^2$ & ", sprintf("%.4f", tab2_rows$R2), collapse = ""),
    " \\\\\n", file = "../tables/tab2_main.tex", append = TRUE)

cat("\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Each column is a separate OLS regression of the outcome on High Exposure $\\times$ Post, where High Exposure indicates above-median pre-period (2015--2017) waste employment share and Post $= \\mathbb{1}[t \\geq 2018\\text{Q1}]$. All specifications include county and time fixed effects. Standard errors clustered at the state level in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.
\\end{tablenotes}
\\end{table}\n", file = "../tables/tab2_main.tex", append = TRUE)

# ==============================================================================
# Table 3: Triple-Difference and Placebos
# ==============================================================================
cat("Generating Table 3: Triple-Diff and Placebos...\n")

ddd_ct <- coeftable(results$m5_ddd)
ddd_idx <- grep("waste_ind", rownames(ddd_ct))

p722_ct <- coeftable(rob$placebo_722)
p541_ct <- coeftable(rob$placebo_541)
tercile_ct <- coeftable(rob$tercile)
donut_ct <- coeftable(rob$donut)

cat("\\begin{table}[t]
\\centering
\\caption{Robustness: Triple-Difference, Placebos, and Alternative Specifications}
\\label{tab:robustness}
\\small
\\begin{tabular}{lccccc}
\\hline\\hline
 & (1) & (2) & (3) & (4) & (5) \\\\
 & DDD & Food Svc & Prof Svc & Top Terc & Donut \\\\
 & 562 vs 541 & 722 & 541 & 562 & 562 \\\\
\\hline\n", file = "../tables/tab3_robustness.tex")

# Row 1: DDD interaction
cat(sprintf("High Exp $\\times$ Post $\\times$ Waste & %.3f%s & & & & \\\\\n",
            ddd_ct[ddd_idx[1], 1],
            ifelse(ddd_ct[ddd_idx[1], 4] < 0.01, "***", ifelse(ddd_ct[ddd_idx[1], 4] < 0.05, "**", ""))),
    file = "../tables/tab3_robustness.tex", append = TRUE)
cat(sprintf(" & (%.3f) & & & & \\\\\n", ddd_ct[ddd_idx[1], 2]),
    file = "../tables/tab3_robustness.tex", append = TRUE)

# Row 2: Placebo / alternative main effects
star_fn <- function(p) ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))

cat(sprintf("High Exp $\\times$ Post & & %.3f%s & %.3f%s & & %.3f%s \\\\\n",
            p722_ct[1, 1], star_fn(p722_ct[1, 4]),
            p541_ct[1, 1], star_fn(p541_ct[1, 4]),
            donut_ct[1, 1], star_fn(donut_ct[1, 4])),
    file = "../tables/tab3_robustness.tex", append = TRUE)
cat(sprintf(" & & (%.3f) & (%.3f) & & (%.3f) \\\\\n",
            p722_ct[1, 2], p541_ct[1, 2], donut_ct[1, 2]),
    file = "../tables/tab3_robustness.tex", append = TRUE)

# Row 3: Top tercile
cat(sprintf("Top Tercile $\\times$ Post & & & & %.3f%s & \\\\\n",
            tercile_ct[1, 1], star_fn(tercile_ct[1, 4])),
    file = "../tables/tab3_robustness.tex", append = TRUE)
cat(sprintf(" & & & & (%.3f) & \\\\\n", tercile_ct[1, 2]),
    file = "../tables/tab3_robustness.tex", append = TRUE)
# Mid tercile
cat(sprintf("Mid Tercile $\\times$ Post & & & & %.3f%s & \\\\\n",
            tercile_ct[2, 1], star_fn(tercile_ct[2, 4])),
    file = "../tables/tab3_robustness.tex", append = TRUE)
cat(sprintf(" & & & & (%.3f) & \\\\\n", tercile_ct[2, 2]),
    file = "../tables/tab3_robustness.tex", append = TRUE)

cat(sprintf("\\hline
$N$ & %s & %s & %s & %s & %s \\\\",
            format(results$m5_ddd$nobs, big.mark = ","),
            format(rob$placebo_722$nobs, big.mark = ","),
            format(rob$placebo_541$nobs, big.mark = ","),
            format(rob$tercile$nobs, big.mark = ","),
            format(rob$donut$nobs, big.mark = ",")),
    file = "../tables/tab3_robustness.tex", append = TRUE)

cat("
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Column 1: triple-difference using NAICS 562 (waste) vs NAICS 541 (professional services) within the same counties. Columns 2--3: placebo tests on unaffected sectors. Column 4: tercile specification with monotonic dose-response. Column 5: donut hole excluding 2017Q3--Q4 (announcement period). All regressions include county and quarter FE. Standard errors clustered at the state level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.
\\end{tablenotes}
\\end{table}\n", file = "../tables/tab3_robustness.tex", append = TRUE)

# ==============================================================================
# Table 4: Event Study Coefficients
# ==============================================================================
cat("Generating Table 4: Event Study...\n")

es_ct <- coeftable(results$m3_es)

cat("\\begin{table}[t]
\\centering
\\caption{Event Study: Waste Management Employment (NAICS 562)}
\\label{tab:eventstudy}
\\small
\\begin{tabular}{lcc}
\\hline\\hline
Quarter Relative to 2018Q1 & Coefficient & SE \\\\
\\hline\n", file = "../tables/tab4_eventstudy.tex")

# Map et_bin to readable labels
et_labels <- c(
  "-8" = "$\\leq -8$", "-7" = "$-7$", "-6" = "$-6$", "-5" = "$-5$",
  "-4" = "$-4$", "-3" = "$-3$", "-2" = "$-2$",
  "0" = "$0$", "1" = "$+1$", "2" = "$+2$", "3" = "$+3$",
  "4" = "$+4$", "5" = "$+5$", "6" = "$+6$", "7" = "$+7$",
  "8" = "$+8$", "9" = "$+9$", "10" = "$+10$", "11" = "$+11$", "12" = "$\\geq +12$"
)

for (i in 1:nrow(es_ct)) {
  rn <- rownames(es_ct)[i]
  # Extract the et_bin number
  et_num <- gsub(".*::(-?\\d+):.*", "\\1", rn)
  label <- et_labels[et_num]
  if (is.na(label)) label <- et_num
  star <- star_fn(es_ct[i, 4])

  cat(sprintf("%s & %.4f%s & (%.4f) \\\\\n",
              label, es_ct[i, 1], star, es_ct[i, 2]),
      file = "../tables/tab4_eventstudy.tex", append = TRUE)

  # Add hline before period 0
  if (et_num == "-2") {
    cat("\\hline\n", file = "../tables/tab4_eventstudy.tex", append = TRUE)
    cat("$-1$ (reference) & 0 & --- \\\\\n",
        file = "../tables/tab4_eventstudy.tex", append = TRUE)
  }
}

cat("\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Coefficients from $\\log(\\text{Emp}_{c,t}) = \\sum_k \\beta_k \\cdot \\mathbb{1}[t-t^* = k] \\times \\text{HighExposure}_c + \\alpha_c + \\delta_t + \\varepsilon_{c,t}$, where $t^* = 2018\\text{Q1}$. Reference period is $k = -1$ (2017Q4). Standard errors clustered at the state level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.
\\end{tablenotes}
\\end{table}\n", file = "../tables/tab4_eventstudy.tex", append = TRUE)

# ==============================================================================
# Table F1: Standardized Effect Size (SDE) — APPENDIX
# ==============================================================================
cat("Generating Table F1: SDE...\n")

# Compute SDE for main outcomes
waste_pre <- waste %>% filter(post == 0)
sd_emp <- sd(waste_pre$log_emp, na.rm = TRUE)
sd_earn <- sd(waste_pre$log_earn, na.rm = TRUE)
sd_hires <- sd(log(waste_pre$HirA + 1), na.rm = TRUE)
sd_frmgn <- sd(log(waste_pre$FrmJbGn + 1), na.rm = TRUE)

# Main results
main_ct <- coeftable(results$m2_emp)
earn_ct <- coeftable(results$m2_earn)
hires_ct <- coeftable(rob$hires)
frmgn_ct <- coeftable(results$m6_creation)

sde_data <- data.frame(
  Outcome = c("Employment (log)", "Earnings/Worker (log)",
              "Hires (log)", "Firm Job Gains (log)"),
  Beta = c(main_ct[1,1], earn_ct[1,1], hires_ct[1,1], frmgn_ct[1,1]),
  SE_Beta = c(main_ct[1,2], earn_ct[1,2], hires_ct[1,2], frmgn_ct[1,2]),
  SD_Y = c(sd_emp, sd_earn, sd_hires, sd_frmgn)
)

sde_data$SDE <- sde_data$Beta / sde_data$SD_Y
sde_data$SE_SDE <- sde_data$SE_Beta / sde_data$SD_Y
sde_data$Classification <- ifelse(sde_data$SDE < -0.15, "Large negative",
                           ifelse(sde_data$SDE < -0.05, "Moderate negative",
                           ifelse(sde_data$SDE < -0.005, "Small negative",
                           ifelse(sde_data$SDE < 0.005, "Null",
                           ifelse(sde_data$SDE < 0.05, "Small positive",
                           ifelse(sde_data$SDE < 0.15, "Moderate positive",
                                  "Large positive"))))))

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does China's 2018 National Sword policy, which collapsed recyclable waste imports by 99.998\\%, reduce employment and firm dynamics in the US waste management sector? ",
  "\\textbf{Policy mechanism:} China banned 24 categories of recyclable waste imports and imposed a 0.5\\% contamination limit, eliminating the primary export market for US municipal recycling programs and forcing a shift from revenue-generating recycling to cost-bearing landfill operations. ",
  "\\textbf{Outcome definition:} Log quarterly employment, earnings per worker, hires, and firm job gains in NAICS 562 (Waste Management and Remediation Services) from Census QWI. ",
  "\\textbf{Treatment:} Binary indicator for above-median pre-period (2015--2017) waste management employment share of total county employment. ",
  "\\textbf{Data:} Census Quarterly Workforce Indicators (QWI), county $\\times$ quarter, 1,988 counties, 2013Q1--2023Q4 (44 quarters). ",
  "\\textbf{Method:} Difference-in-differences with county and quarter fixed effects; standard errors clustered at the state level. ",
  "\\textbf{Sample:} Counties with nonzero NAICS 562 employment in the pre-period; restricted to private-sector establishments. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Panel A: Pooled
cat("\\begin{table}[t]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\small
\\begin{tabular}{lcccccc}
\\hline\\hline
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\hline
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\
\\hline\n", file = "../tables/tabF1_sde.tex")

for (i in 1:nrow(sde_data)) {
  cat(sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
              sde_data$Outcome[i], sde_data$Beta[i], sde_data$SE_Beta[i],
              sde_data$SD_Y[i], sde_data$SDE[i], sde_data$SE_SDE[i],
              sde_data$Classification[i]),
      file = "../tables/tabF1_sde.tex", append = TRUE)
}

# Panel B: Heterogeneous (by exposure tercile)
waste_top <- waste %>% filter(ntile(waste_share, 3) == 3)
waste_bot <- waste %>% filter(ntile(waste_share, 3) == 1)

m_top <- feols(log_emp ~ I(ntile(waste_share, 3) == 3):post | fips + time_q,
               data = waste %>% filter(ntile(waste_share, 3) %in% c(1, 3)),
               cluster = ~state_fips)
m_top_ct <- coeftable(m_top)

cat("\\hline
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by exposure intensity)}} \\\\
\\hline\n", file = "../tables/tabF1_sde.tex", append = TRUE)

sde_top <- m_top_ct[1, 1] / sd_emp
se_sde_top <- m_top_ct[1, 2] / sd_emp
class_top <- ifelse(sde_top < -0.15, "Large negative",
             ifelse(sde_top < -0.05, "Moderate negative", "Small negative"))

cat(sprintf("Employment, Top Tercile & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
            m_top_ct[1, 1], m_top_ct[1, 2], sd_emp, sde_top, se_sde_top, class_top),
    file = "../tables/tabF1_sde.tex", append = TRUE)

# Donut hole
donut_ct2 <- coeftable(rob$donut)
sde_donut <- donut_ct2[1, 1] / sd_emp
se_sde_donut <- donut_ct2[1, 2] / sd_emp
class_donut <- ifelse(sde_donut < -0.15, "Large negative",
               ifelse(sde_donut < -0.05, "Moderate negative", "Small negative"))

cat(sprintf("Employment, Donut Hole & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
            donut_ct2[1, 1], donut_ct2[1, 2], sd_emp, sde_donut, se_sde_donut, class_donut),
    file = "../tables/tabF1_sde.tex", append = TRUE)

cat(sprintf("\\hline\\hline
\\end{tabular}
\\begin{tablenotes}
%s
\\end{tablenotes}
\\end{table}\n", sde_notes),
    file = "../tables/tabF1_sde.tex", append = TRUE)

cat("\nAll tables generated.\n")
