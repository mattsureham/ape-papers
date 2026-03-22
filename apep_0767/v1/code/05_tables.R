## 05_tables.R — Generate all LaTeX tables
source("00_packages.R")

cat("=== Generating Tables ===\n")

results <- readRDS("../data/main_results.rds")
rob <- readRDS("../data/robustness_results.rds")
panel_low_agg <- results$panel_low_agg
panel_annual <- results$panel_annual

## ---- Table 1: Summary Statistics ----
cat("Table 1: Summary Statistics\n")

## Use the analysis panel for consistent summary stats
## Panel_low_agg already computes TurnOvrS = (HirA+Sep)/(2*Emp)
panel_low_agg_stats <- panel_low_agg
panel_high_stats <- results$panel_high
panel_high_stats[, hire_rate := HirA / Emp]
panel_high_stats[, sep_rate := Sep / Emp]
panel_high_stats[, TurnOvrS_computed := (HirA + Sep) / (2 * Emp)]

## Low-education from aggregated panel
pre_low <- panel_low_agg_stats[treated == 0]
post_low <- panel_low_agg_stats[treated == 1]

## High-education
pre_high <- panel_high_stats[treated == 0]
post_high <- panel_high_stats[treated == 1]

make_stats <- function(dt, label, turn_var = "TurnOvrS") {
  data.table(
    Panel = label,
    `Turnover Rate` = sprintf("%.4f (%.4f)", mean(dt[[turn_var]], na.rm = TRUE),
                              sd(dt[[turn_var]], na.rm = TRUE)),
    `Hire Rate` = sprintf("%.4f (%.4f)", mean(dt$hire_rate, na.rm = TRUE),
                          sd(dt$hire_rate, na.rm = TRUE)),
    `Separation Rate` = sprintf("%.4f (%.4f)", mean(dt$sep_rate, na.rm = TRUE),
                                sd(dt$sep_rate, na.rm = TRUE)),
    `Monthly Earnings (\\$)` = sprintf("%.0f (%.0f)", mean(dt$EarnS, na.rm = TRUE),
                                       sd(dt$EarnS, na.rm = TRUE)),
    N = nrow(dt)
  )
}

tab1 <- rbind(
  make_stats(pre_low, "Low-Ed, Pre-Treatment"),
  make_stats(post_low, "Low-Ed, Post-Treatment"),
  make_stats(pre_high, "High-Ed, Pre-Treatment", "TurnOvrS_computed"),
  make_stats(post_high, "High-Ed, Post-Treatment", "TurnOvrS_computed")
)

## Write LaTeX
sink("../tables/tab1_summary.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{tabular}{lccccc}\n")
cat("\\toprule\n")
cat(" & Turnover & Hire & Separation & Monthly & \\\\\n")
cat("Panel & Rate & Rate & Rate & Earnings (\\$) & N \\\\\n")
cat("\\midrule\n")

for (i in 1:nrow(tab1)) {
  cat(sprintf("%s & %s & %s & %s & %s & %s \\\\\n",
              tab1$Panel[i],
              tab1$`Turnover Rate`[i],
              tab1$`Hire Rate`[i],
              tab1$`Separation Rate`[i],
              tab1$`Monthly Earnings (\\$)`[i],
              format(as.integer(tab1$N[i]), big.mark = ",")))
}

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Standard deviations in parentheses. ")
cat("Low-education = less than high school + high school/GED (QWI education levels E1--E2). ")
cat("High-education = bachelor's degree or higher (E4). ")
cat("Pre-treatment is defined relative to each state's simplified reporting adoption date. ")
cat("Turnover rate = (hires + separations)/(2 $\\times$ employment). ")
cat("Source: Census Quarterly Workforce Indicators (QWI), 2000--2019, all private sector. ")
cat("Earnings are average monthly earnings for stable employment.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("  Saved tab1_summary.tex\n")

## ---- Table 2: Main Results ----
cat("Table 2: Main Results\n")

twfe <- results$twfe_turn
twfe_h <- results$twfe_hire
twfe_s <- results$twfe_sep
twfe_e <- results$twfe_earn
sa <- results$sa_turn
sa_h <- results$sa_hire
sa_s <- results$sa_sep
sa_e <- results$sa_earn
ph_t <- results$twfe_ph_turn
ph_h <- results$twfe_ph_hire

## Extract Sun-Abraham ATT
sa_att <- function(model) {
  s <- summary(model, agg = "ATT")
  coeftable <- s$coeftable
  list(est = coeftable[1, 1], se = coeftable[1, 2], pval = coeftable[1, 4])
}

sa_t <- sa_att(sa)
sa_hr <- sa_att(sa_h)
sa_sr <- sa_att(sa_s)
sa_er <- sa_att(sa_e)

stars <- function(p) {
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.1) return("*")
  return("")
}

sink("../tables/tab2_main_results.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Effect of SNAP Simplified Reporting on Low-Education Labor Market Outcomes}\n")
cat("\\label{tab:main}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\toprule\n")
cat(" & Turnover & Hire & Separation & Log \\\\\n")
cat(" & Rate & Rate & Rate & Earnings \\\\\n")
cat(" & (1) & (2) & (3) & (4) \\\\\n")
cat("\\midrule\n")
cat("\\multicolumn{5}{l}{\\textit{Panel A: TWFE}} \\\\\n")
cat(sprintf("Simplified Reporting & %.4f%s & %.4f%s & %.4f%s & %.4f%s \\\\\n",
            coef(twfe), stars(fixest::pvalue(twfe)),
            coef(twfe_h), stars(fixest::pvalue(twfe_h)),
            coef(twfe_s), stars(fixest::pvalue(twfe_s)),
            coef(twfe_e), stars(fixest::pvalue(twfe_e))))
cat(sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n",
            se(twfe), se(twfe_h), se(twfe_s), se(twfe_e)))
cat("\\addlinespace\n")
cat("\\multicolumn{5}{l}{\\textit{Panel B: Sun-Abraham (2021)}} \\\\\n")
cat(sprintf("ATT & %.4f%s & %.4f%s & %.4f%s & %.4f%s \\\\\n",
            sa_t$est, stars(sa_t$pval),
            sa_hr$est, stars(sa_hr$pval),
            sa_sr$est, stars(sa_sr$pval),
            sa_er$est, stars(sa_er$pval)))
cat(sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n",
            sa_t$se, sa_hr$se, sa_sr$se, sa_er$se))
cat("\\addlinespace\n")
cat("\\multicolumn{5}{l}{\\textit{Panel C: Placebo (Bachelor's+)}} \\\\\n")
cat(sprintf("Simplified Reporting & %.4f%s & %.4f%s & & \\\\\n",
            coef(ph_t), stars(fixest::pvalue(ph_t)),
            coef(ph_h), stars(fixest::pvalue(ph_h))))
cat(sprintf(" & (%.4f) & (%.4f) & & \\\\\n",
            se(ph_t), se(ph_h)))
cat("\\midrule\n")
cat(sprintf("Pre-treatment mean & %.4f & %.4f & %.4f & %.2f \\\\\n",
            mean(panel_low_agg[treated == 0]$TurnOvrS, na.rm = TRUE),
            mean(panel_low_agg[treated == 0]$hire_rate, na.rm = TRUE),
            mean(panel_low_agg[treated == 0]$sep_rate, na.rm = TRUE),
            mean(panel_low_agg[treated == 0]$log_earn, na.rm = TRUE)))
cat("State, quarter FE & Yes & Yes & Yes & Yes \\\\\n")
cat(sprintf("States & %d & %d & %d & %d \\\\\n",
            uniqueN(panel_low_agg$state_id),
            uniqueN(panel_low_agg$state_id),
            uniqueN(panel_low_agg$state_id),
            uniqueN(panel_low_agg[!is.na(log_earn)]$state_id)))
cat(sprintf("Observations & %s & %s & %s & %s \\\\\n",
            format(nrow(panel_low_agg), big.mark = ","),
            format(nrow(panel_low_agg), big.mark = ","),
            format(nrow(panel_low_agg), big.mark = ","),
            format(sum(!is.na(panel_low_agg$log_earn)), big.mark = ",")))
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Standard errors clustered at the state level in parentheses. ")
cat("$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$. ")
cat("Panel A: TWFE with state and quarter fixed effects. ")
cat("Panel B: Sun and Abraham (2021) interaction-weighted estimator with annual cohorts. ")
cat("Panel C: placebo test on bachelor's degree holders (QWI E4), who are unlikely SNAP recipients. ")
cat("Low-education = less than high school + high school/GED (QWI E1--E2). ")
cat("Sample: all US states, 2000Q1--2019Q4, all private sector.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("  Saved tab2_main_results.tex\n")

## ---- Table 3: Robustness ----
cat("Table 3: Robustness\n")

sink("../tables/tab3_robustness.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Robustness Checks: Turnover Rate}\n")
cat("\\label{tab:robustness}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\toprule\n")
cat(" & Coefficient & SE & $p$-value & $N$ \\\\\n")
cat("\\midrule\n")

## Main specification
cat(sprintf("Baseline TWFE & %.4f & %.4f & %.3f & %s \\\\\n",
            coef(twfe), se(twfe), fixest::pvalue(twfe),
            format(nobs(twfe), big.mark = ",")))

## Robustness
cat(sprintf("Exclude early adopters (2001) & %.4f & %.4f & %.3f & %s \\\\\n",
            coef(rob$fit_no_early), se(rob$fit_no_early),
            fixest::pvalue(rob$fit_no_early),
            format(nobs(rob$fit_no_early), big.mark = ",")))
cat(sprintf("Exclude 2007--2009 & %.4f & %.4f & %.3f & %s \\\\\n",
            coef(rob$fit_no_gr), se(rob$fit_no_gr),
            fixest::pvalue(rob$fit_no_gr),
            format(nobs(rob$fit_no_gr), big.mark = ",")))
cat(sprintf("State-specific trends & %.4f & %.4f & %.3f & %s \\\\\n",
            coef(rob$fit_trends), se(rob$fit_trends),
            fixest::pvalue(rob$fit_trends),
            format(nobs(rob$fit_trends), big.mark = ",")))
cat(sprintf("Annual frequency & %.4f & %.4f & %.3f & %s \\\\\n",
            coef(rob$fit_annual), se(rob$fit_annual),
            fixest::pvalue(rob$fit_annual),
            format(nobs(rob$fit_annual), big.mark = ",")))

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Dependent variable: turnover rate for low-education workers ")
cat("(QWI E1--E2). Standard errors clustered at the state level. ")
cat("Baseline: state + quarter FE, 44 states, 2000--2019. ")
cat("State-specific trends include state-specific linear time trends.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("  Saved tab3_robustness.tex\n")

## ---- Table 4: Education Gradient ----
cat("Table 4: Education Gradient\n")

panel_full <- fread("../data/panel_full.csv")
state_map <- data.table(state = unique(panel_full$state),
                        state_id = seq_along(unique(panel_full$state)))
panel_full <- merge(panel_full, state_map, by = "state")
panel_full <- panel_full[Emp > 0]
panel_full[, hire_rate := HirA / Emp]
panel_full[, treated := as.integer(year >= adopt_year & adopt_year < 9999)]

sink("../tables/tab4_education.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Effects by Education Level}\n")
cat("\\label{tab:education}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\toprule\n")
cat(" & Turnover Rate & Hire Rate & $N$ \\\\\n")
cat("\\midrule\n")

ed_labels <- c(E1 = "Less than HS", E2 = "HS/GED", E3 = "Some College", E4 = "Bachelor's+")
for (ed in c("E1", "E2", "E3", "E4")) {
  sub <- panel_full[education == ed]
  sc <- sub[, .N, by = state_id]
  sub <- sub[state_id %in% sc[N >= floor(max(sc$N) * 0.9)]$state_id]
  fit_t <- feols(TurnOvrS ~ treated | state_id + time_idx, data = sub, cluster = ~state_id)
  fit_h <- feols(hire_rate ~ treated | state_id + time_idx, data = sub, cluster = ~state_id)
  cat(sprintf("%s & %.4f%s & %.4f%s & %s \\\\\n",
              ed_labels[ed],
              coef(fit_t), stars(fixest::pvalue(fit_t)),
              coef(fit_h), stars(fixest::pvalue(fit_h)),
              format(nobs(fit_t), big.mark = ",")))
  cat(sprintf(" & (%.4f) & (%.4f) & \\\\\n", se(fit_t), se(fit_h)))
}

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Each row is a separate regression with state and quarter FE. ")
cat("Standard errors clustered at the state level in parentheses. ")
cat("$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$. ")
cat("If simplified reporting primarily reduces job-switching frictions for SNAP-eligible workers, ")
cat("we expect effects concentrated in E1--E2 (low-education, high SNAP participation) ")
cat("and null effects for E4 (bachelor's+, low SNAP participation). ")
cat("The uniform null across all education levels is inconsistent with a SNAP-specific mechanism.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("  Saved tab4_education.tex\n")

## ---- Table F1: Standardized Effect Sizes ----
cat("Table F1: Standardized Effect Sizes\n")

## Compute SDE for each outcome
sd_pre <- panel_low_agg[treated == 0, .(
  sd_turn = sd(TurnOvrS, na.rm = TRUE),
  sd_hire = sd(hire_rate, na.rm = TRUE),
  sd_sep = sd(sep_rate, na.rm = TRUE),
  sd_earn = sd(log_earn, na.rm = TRUE)
)]

sde_turn <- coef(twfe) / sd_pre$sd_turn
sde_hire <- coef(twfe_h) / sd_pre$sd_hire
sde_sep <- coef(twfe_s) / sd_pre$sd_sep
sde_earn <- coef(twfe_e) / sd_pre$sd_earn

se_sde_turn <- se(twfe) / sd_pre$sd_turn
se_sde_hire <- se(twfe_h) / sd_pre$sd_hire
se_sde_sep <- se(twfe_s) / sd_pre$sd_sep
se_sde_earn <- se(twfe_e) / sd_pre$sd_earn

classify <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does reducing SNAP administrative reporting burdens ",
  "increase labor market fluidity among low-education workers? ",
  "\\textbf{Policy mechanism:} Under pre-reform ``change reporting,'' SNAP households had to report every income ",
  "change within 10 days, creating an implicit tax on earnings volatility that may deter job switching; ",
  "simplified reporting requires reports only when gross income exceeds 130\\% FPL, removing this friction. ",
  "\\textbf{Outcome definition:} QWI quarterly turnover rate (hires + separations divided by twice ",
  "employment), hire rate, separation rate, and log monthly earnings for stable employment. ",
  "\\textbf{Treatment:} Binary --- state adoption of SNAP simplified reporting. ",
  "\\textbf{Data:} Census Quarterly Workforce Indicators (QWI) by education level and USDA ERS SNAP Policy ",
  "Database, 44 states, 2000--2019, state-quarter level, 3,498 observations. ",
  "\\textbf{Method:} TWFE with state and quarter FE, standard errors clustered at state level; ",
  "Sun-Abraham (2021) interaction-weighted estimator as robustness. ",
  "\\textbf{Sample:} Low-education workers (less than high school + high school/GED, QWI E1--E2), ",
  "all US states with balanced panels, all private sector employment. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sink("../tables/tabF1_sde.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\toprule\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\midrule\n")

cat(sprintf("Turnover Rate & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
            coef(twfe), se(twfe), sd_pre$sd_turn,
            sde_turn, se_sde_turn, classify(sde_turn)))
cat(sprintf("Hire Rate & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
            coef(twfe_h), se(twfe_h), sd_pre$sd_hire,
            sde_hire, se_sde_hire, classify(sde_hire)))
cat(sprintf("Separation Rate & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
            coef(twfe_s), se(twfe_s), sd_pre$sd_sep,
            sde_sep, se_sde_sep, classify(sde_sep)))
cat(sprintf("Log Earnings & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
            coef(twfe_e), se(twfe_e), sd_pre$sd_earn,
            sde_earn, se_sde_earn, classify(sde_earn)))

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat(sde_notes, "\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("  Saved tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
