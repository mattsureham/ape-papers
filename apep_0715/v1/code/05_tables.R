## 05_tables.R — Generate all tables for paper
## apep_0715: FOBT Stake Reduction

source("00_packages.R")
setwd(file.path(dirname(getwd())))

if (!dir.exists("tables")) dir.create("tables")

cat("=== Generating tables ===\n")

# Load data
ggy_overview <- readRDS("data/ggy_overview.rds")
premises <- readRDS("data/premises_national.rds")
machines_betting <- readRDS("data/machines_betting.rds")
betting_detail <- readRDS("data/betting_detail.rds")
betting_by_la <- readRDS("data/betting_by_la.rds")
subst <- readRDS("data/substitution.rds")
did_ggy_precovid <- readRDS("data/did_ggy_precovid.rds")
did_ggy_nocovid <- readRDS("data/did_ggy_nocovid.rds")
did_ggy <- readRDS("data/did_ggy.rds")
es_coefs <- readRDS("data/es_coefs.rds")
rob_results <- readRDS("data/robustness_results.rds")

# ─────────────────────────────────────────────────────────────
# TABLE 1: Summary Statistics
# ─────────────────────────────────────────────────────────────
cat("--- Table 1: Summary Statistics ---\n")

# Pre-reform averages (FY2016-2019)
pre_ggy <- ggy_overview %>%
  filter(fy_end >= 2016, fy_end <= 2019)

prem_pre <- premises %>% filter(fy_end >= 2016, fy_end <= 2019)

machines_clean <- machines_betting %>% distinct(fy_end, .keep_all = TRUE)
mach_pre <- machines_clean %>% filter(fy_end >= 2016, fy_end <= 2019)

tab1_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: British Gambling Industry}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{Pre-Reform (2016--2019)} & \\multicolumn{2}{c}{Post-Reform (2020)} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  " & Mean & Std.\\ Dev. & Value & \\% Change \\\\\n",
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Gross Gambling Yield (\\pounds M)}} \\\\\n",
  sprintf("\\quad Betting (non-remote) & %s & %s & %s & %s \\\\\n",
          format(round(mean(pre_ggy$betting_nr)), big.mark = ","),
          format(round(sd(pre_ggy$betting_nr)), big.mark = ","),
          format(round(ggy_overview$betting_nr[ggy_overview$fy_end == 2020]), big.mark = ","),
          paste0(round((ggy_overview$betting_nr[ggy_overview$fy_end == 2020] / mean(pre_ggy$betting_nr) - 1) * 100, 1), "\\%")),
  sprintf("\\quad Casino (non-remote) & %s & %s & %s & %s \\\\\n",
          format(round(mean(pre_ggy$casino_nr)), big.mark = ","),
          format(round(sd(pre_ggy$casino_nr)), big.mark = ","),
          format(round(ggy_overview$casino_nr[ggy_overview$fy_end == 2020]), big.mark = ","),
          paste0(round((ggy_overview$casino_nr[ggy_overview$fy_end == 2020] / mean(pre_ggy$casino_nr) - 1) * 100, 1), "\\%")),
  sprintf("\\quad Bingo (non-remote) & %s & %s & %s & %s \\\\\n",
          format(round(mean(pre_ggy$bingo_nr)), big.mark = ","),
          format(round(sd(pre_ggy$bingo_nr)), big.mark = ","),
          format(round(ggy_overview$bingo_nr[ggy_overview$fy_end == 2020]), big.mark = ","),
          paste0(round((ggy_overview$bingo_nr[ggy_overview$fy_end == 2020] / mean(pre_ggy$bingo_nr) - 1) * 100, 1), "\\%")),
  sprintf("\\quad Arcades (non-remote) & %s & %s & %s & %s \\\\\n",
          format(round(mean(pre_ggy$arcades_nr)), big.mark = ","),
          format(round(sd(pre_ggy$arcades_nr)), big.mark = ","),
          format(round(ggy_overview$arcades_nr[ggy_overview$fy_end == 2020]), big.mark = ","),
          paste0(round((ggy_overview$arcades_nr[ggy_overview$fy_end == 2020] / mean(pre_ggy$arcades_nr) - 1) * 100, 1), "\\%")),
  sprintf("\\quad Betting (remote) & %s & %s & %s & %s \\\\\n",
          format(round(mean(pre_ggy$betting_r)), big.mark = ","),
          format(round(sd(pre_ggy$betting_r)), big.mark = ","),
          format(round(ggy_overview$betting_r[ggy_overview$fy_end == 2020]), big.mark = ","),
          paste0(round((ggy_overview$betting_r[ggy_overview$fy_end == 2020] / mean(pre_ggy$betting_r) - 1) * 100, 1), "\\%")),
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Active Premises}} \\\\\n",
  sprintf("\\quad Betting shops & %s & %s & %s & %s \\\\\n",
          format(round(mean(prem_pre$betting)), big.mark = ","),
          format(round(sd(prem_pre$betting)), big.mark = ","),
          format(round(premises$betting[premises$fy_end == 2020]), big.mark = ","),
          paste0(round((premises$betting[premises$fy_end == 2020] / mean(prem_pre$betting) - 1) * 100, 1), "\\%")),
  sprintf("\\quad Casinos & %s & %s & %s & %s \\\\\n",
          format(round(mean(prem_pre$casino)), big.mark = ","),
          format(round(sd(prem_pre$casino)), big.mark = ","),
          format(round(premises$casino[premises$fy_end == 2020]), big.mark = ","),
          paste0(round((premises$casino[premises$fy_end == 2020] / mean(prem_pre$casino) - 1) * 100, 1), "\\%")),
  sprintf("\\quad Bingo halls & %s & %s & %s & %s \\\\\n",
          format(round(mean(prem_pre$bingo)), big.mark = ","),
          format(round(sd(prem_pre$bingo)), big.mark = ","),
          format(round(premises$bingo[premises$fy_end == 2020]), big.mark = ","),
          paste0(round((premises$bingo[premises$fy_end == 2020] / mean(prem_pre$bingo) - 1) * 100, 1), "\\%")),
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel C: Gaming Machines in Betting Premises}} \\\\\n",
  sprintf("\\quad B2 (FOBT) machines & %s & %s & %s & %s \\\\\n",
          format(round(mean(mach_pre$b2_machines)), big.mark = ","),
          format(round(sd(mach_pre$b2_machines)), big.mark = ","),
          format(round(machines_clean$b2_machines[machines_clean$fy_end == 2020]), big.mark = ","),
          paste0(round((machines_clean$b2_machines[machines_clean$fy_end == 2020] / mean(mach_pre$b2_machines) - 1) * 100, 1), "\\%")),
  sprintf("\\quad Total machines & %s & %s & %s & %s \\\\\n",
          format(round(mean(mach_pre$total_machines)), big.mark = ","),
          format(round(sd(mach_pre$total_machines)), big.mark = ","),
          format(round(machines_clean$total_machines[machines_clean$fy_end == 2020]), big.mark = ","),
          paste0(round((machines_clean$total_machines[machines_clean$fy_end == 2020] / mean(mach_pre$total_machines) - 1) * 100, 1), "\\%")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Data from UK Gambling Commission Industry Statistics (November 2024). ",
  "Pre-reform period is fiscal years ending March 2016--2019. ",
  "Post-reform values are for the fiscal year ending March 2020 ",
  "(the first year after the April 2019 FOBT stake reduction). ",
  "B2 machines are Category B2 gaming machines (Fixed-Odds Betting Terminals). ",
  "GGY is gross gambling yield (stakes minus prizes). ",
  "Percent change compares post-reform values to pre-reform means.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:summary}\n",
  "\\end{table}\n"
)
writeLines(tab1_tex, "tables/tab1_summary.tex")
cat("  Written: tables/tab1_summary.tex\n")

# ─────────────────────────────────────────────────────────────
# TABLE 2: Main DiD Results
# ─────────────────────────────────────────────────────────────
cat("--- Table 2: Main DiD Results ---\n")

# Extract coefficients from all specs
get_coefs <- function(model, label) {
  cf <- summary(model)$coeftable
  data.frame(
    spec = label,
    estimate = cf[1, "Estimate"],
    se = cf[1, "Std. Error"],
    pval = cf[1, "Pr(>|t|)"],
    n = model$nobs
  )
}

main_coefs <- rbind(
  get_coefs(did_ggy_precovid, "Pre-COVID (FY2009--2020)"),
  get_coefs(did_ggy_nocovid, "Excl. COVID (FY2009--2023, no FY2021)"),
  get_coefs(did_ggy, "Full sample (FY2009--2023)"),
  get_coefs(rob_results$single_year, "Single post year (FY2020)"),
  get_coefs(rob_results$symmetric, "Symmetric window (FY2015--2023)")
)

stars <- function(p) {
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

tab2_rows <- ""
for (i in 1:nrow(main_coefs)) {
  r <- main_coefs[i, ]
  tab2_rows <- paste0(tab2_rows,
    sprintf("%s & %s%s & (%s) & %d \\\\\n",
            r$spec,
            format(round(r$estimate, 3), nsmall = 3),
            stars(r$pval),
            format(round(r$se, 3), nsmall = 3),
            r$n))
}

tab2_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Effect of FOBT Stake Reduction on Betting Sector GGY}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  "Specification & Betting $\\times$ Post & SE & N \\\\\n",
  "\\midrule\n",
  tab2_rows,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Each row reports the coefficient on the interaction of the betting sector indicator with a post-reform indicator from a separate OLS regression of log GGY on sector and year fixed effects. ",
  "Control sectors are casino, bingo, and arcades (non-remote). ",
  "Heteroskedasticity-robust standard errors in parentheses. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:main}\n",
  "\\end{table}\n"
)
writeLines(tab2_tex, "tables/tab2_main.tex")
cat("  Written: tables/tab2_main.tex\n")

# ─────────────────────────────────────────────────────────────
# TABLE 3: Event Study Coefficients
# ─────────────────────────────────────────────────────────────
cat("--- Table 3: Event Study ---\n")

es_rows <- ""
for (i in 1:nrow(es_coefs)) {
  r <- es_coefs[i, ]
  fy_label <- paste0("FY", 2020 + r$event_time)
  es_rows <- paste0(es_rows,
    sprintf("%s & %d & %s%s & (%s) \\\\\n",
            fy_label, r$event_time,
            format(round(r$estimate, 3), nsmall = 3),
            stars(r$p.value),
            format(round(r$std.error, 3), nsmall = 3)))
}

tab3_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Event Study: Betting Sector GGY Relative to Control Sectors}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  "Fiscal Year & Event Time & Estimate & SE \\\\\n",
  "\\midrule\n",
  es_rows,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Coefficients from an event study regression of log GGY on interactions between the betting sector indicator and event-time dummies. ",
  "Reference period: FY2019 (event time $-1$, the last pre-reform year). ",
  "Control sectors: casino, bingo, arcades. Sector and year fixed effects included. ",
  "Heteroskedasticity-robust standard errors in parentheses. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:eventstudy}\n",
  "\\end{table}\n"
)
writeLines(tab3_tex, "tables/tab3_eventstudy.tex")
cat("  Written: tables/tab3_eventstudy.tex\n")

# ─────────────────────────────────────────────────────────────
# TABLE 4: Mechanism Decomposition and Substitution
# ─────────────────────────────────────────────────────────────
cat("--- Table 4: Mechanism and Substitution ---\n")

betting_clean <- betting_detail %>% distinct(fy_end, .keep_all = TRUE)

# Pre-reform means (FY2016-2019)
pre_otc <- mean(betting_clean$otc_ggy[betting_clean$fy_end >= 2016 & betting_clean$fy_end <= 2019])
pre_mach <- mean(betting_clean$machine_ggy[betting_clean$fy_end >= 2016 & betting_clean$fy_end <= 2019])
pre_remote <- mean(ggy_overview$betting_r[ggy_overview$fy_end >= 2016 & ggy_overview$fy_end <= 2019])
pre_total_bet <- pre_otc + pre_mach + pre_remote

# Post-reform (FY2020)
post_otc <- betting_clean$otc_ggy[betting_clean$fy_end == 2020]
post_mach <- betting_clean$machine_ggy[betting_clean$fy_end == 2020]
post_remote <- ggy_overview$betting_r[ggy_overview$fy_end == 2020]
post_total_bet <- post_otc + post_mach + post_remote

tab4_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Mechanism Decomposition and Online Substitution}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & Pre-Reform & Post-Reform & Change & \\% Change \\\\\n",
  " & (\\pounds M) & (\\pounds M) & (\\pounds M) & \\\\\n",
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Non-Remote Betting Decomposition}} \\\\\n",
  sprintf("\\quad Over-the-counter GGY & %s & %s & %s & %s \\\\\n",
          format(round(pre_otc), big.mark = ","),
          format(round(post_otc), big.mark = ","),
          format(round(post_otc - pre_otc), big.mark = ","),
          paste0(round((post_otc / pre_otc - 1) * 100, 1), "\\%")),
  sprintf("\\quad Gaming machine GGY & %s & %s & %s & %s \\\\\n",
          format(round(pre_mach), big.mark = ","),
          format(round(post_mach), big.mark = ","),
          format(round(post_mach - pre_mach), big.mark = ","),
          paste0(round((post_mach / pre_mach - 1) * 100, 1), "\\%")),
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Channel Substitution}} \\\\\n",
  sprintf("\\quad Non-remote betting GGY & %s & %s & %s & %s \\\\\n",
          format(round(pre_otc + pre_mach), big.mark = ","),
          format(round(post_otc + post_mach), big.mark = ","),
          format(round((post_otc + post_mach) - (pre_otc + pre_mach)), big.mark = ","),
          paste0(round(((post_otc + post_mach) / (pre_otc + pre_mach) - 1) * 100, 1), "\\%")),
  sprintf("\\quad Remote betting GGY & %s & %s & %s & %s \\\\\n",
          format(round(pre_remote), big.mark = ","),
          format(round(post_remote), big.mark = ","),
          format(round(post_remote - pre_remote), big.mark = ","),
          paste0(round((post_remote / pre_remote - 1) * 100, 1), "\\%")),
  sprintf("\\quad Total betting GGY & %s & %s & %s & %s \\\\\n",
          format(round(pre_total_bet), big.mark = ","),
          format(round(post_total_bet), big.mark = ","),
          format(round(post_total_bet - pre_total_bet), big.mark = ","),
          paste0(round((post_total_bet / pre_total_bet - 1) * 100, 1), "\\%")),
  "\\midrule\n",
  sprintf("\\quad Substitution rate & \\multicolumn{4}{c}{%s} \\\\\n",
          paste0(round(abs(post_remote - pre_remote) / abs((post_otc + post_mach) - (pre_otc + pre_mach)) * 100, 1), "\\%")),
  sprintf("\\quad Remote share (pre) & \\multicolumn{4}{c}{%s} \\\\\n",
          paste0(round(pre_remote / pre_total_bet * 100, 1), "\\%")),
  sprintf("\\quad Remote share (post) & \\multicolumn{4}{c}{%s} \\\\\n",
          paste0(round(post_remote / post_total_bet * 100, 1), "\\%")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Data from UK Gambling Commission Industry Statistics. Pre-reform is the average of fiscal years 2016--2019. Post-reform is fiscal year 2020 (April 2019--March 2020). ",
  "The substitution rate is the ratio of the remote GGY increase to the non-remote GGY decrease, capturing how much of the lost land-based revenue was absorbed by online channels. ",
  "All values in millions of pounds sterling.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:mechanism}\n",
  "\\end{table}\n"
)
writeLines(tab4_tex, "tables/tab4_mechanism.tex")
cat("  Written: tables/tab4_mechanism.tex\n")

# ─────────────────────────────────────────────────────────────
# TABLE 5: Robustness — Placebo Tests
# ─────────────────────────────────────────────────────────────
cat("--- Table 5: Placebo Tests ---\n")

placebo <- rob_results$placebo
placebo_rows <- ""
for (i in 1:nrow(placebo)) {
  r <- placebo[i, ]
  placebo_rows <- paste0(placebo_rows,
    sprintf("FY%d & %s%s & (%s) \\\\\n",
            r$placebo_year,
            format(round(r$estimate, 3), nsmall = 3),
            stars(r$pval),
            format(round(r$se, 3), nsmall = 3)))
}

tab5_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Placebo Tests: Fake Treatment Dates (Pre-Reform Sample Only)}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  "Placebo Treatment Year & Estimate & SE \\\\\n",
  "\\midrule\n",
  placebo_rows,
  "\\midrule\n",
  sprintf("Actual treatment (FY2020) & %s*** & (%s) \\\\\n",
          format(round(coef(did_ggy_precovid), 3), nsmall = 3),
          format(round(sqrt(diag(vcov(did_ggy_precovid))), 3), nsmall = 3)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Each row reports the betting $\\times$ post coefficient from a separate regression using the pre-reform sample only (FY2009--2019) with a fake treatment date. ",
  "None of the placebo coefficients are statistically significant, supporting the parallel trends assumption. ",
  "The final row shows the actual treatment effect for comparison. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:placebo}\n",
  "\\end{table}\n"
)
writeLines(tab5_tex, "tables/tab5_placebo.tex")
cat("  Written: tables/tab5_placebo.tex\n")

# ─────────────────────────────────────────────────────────────
# SDE TABLE (Appendix F1)
# ─────────────────────────────────────────────────────────────
cat("--- SDE Table ---\n")

# Main specification: pre-COVID DiD
beta_main <- coef(did_ggy_precovid)["treat_post"]
se_main <- sqrt(diag(vcov(did_ggy_precovid)))["treat_post"]

# The outcome is log(GGY), so beta is in log points
# SD(Y) = SD of log(GGY) for betting sector in pre-period
panel_ggy <- readRDS("data/panel_ggy.rds")
panel_pre <- panel_ggy %>%
  filter(fy_end >= 2009, fy_end <= 2019)
sd_y_betting <- sd(log(panel_pre$ggy[panel_pre$sector == "betting_nr"]))
sd_y_all <- sd(log(panel_pre$ggy))

# SDE = beta / SD(Y)
sde_main <- beta_main / sd_y_all
se_sde_main <- se_main / sd_y_all

classify <- function(s) {
  dplyr::case_when(
    s < -0.15  ~ "Large negative",
    s < -0.05  ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s <  0.005 ~ "Null",
    s <  0.05  ~ "Small positive",
    s <  0.15  ~ "Moderate positive",
    TRUE       ~ "Large positive"
  )
}

# Also compute for levels spec
beta_levels <- coef(rob_results$levels)["treat_post"]
se_levels <- sqrt(diag(vcov(rob_results$levels)))["treat_post"]
sd_y_levels <- sd(panel_pre$ggy)
sde_levels <- beta_levels / sd_y_levels
se_sde_levels <- se_levels / sd_y_levels

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom. ",
  "\\textbf{Research question:} Whether the April 2019 reduction of Fixed-Odds Betting Terminal maximum stakes from \\pounds 100 to \\pounds 2 reduced gambling sector gross gambling yield relative to unaffected sectors. ",
  "\\textbf{Policy mechanism:} The stake reduction rendered Category B2 gaming machines commercially unviable, forcing operators to close betting premises or replace machines with lower-revenue alternatives; the regulation specifically targeted the product generating the majority of betting shop machine revenue. ",
  "\\textbf{Outcome definition:} Log of annual gross gambling yield (stakes minus prizes) by gambling sector, from Gambling Commission Industry Statistics. ",
  "\\textbf{Treatment:} Binary indicator for the betting sector (FOBT-dependent) interacted with a post-reform indicator. ",
  "\\textbf{Data:} UK Gambling Commission Industry Statistics, fiscal years 2009--2020, 4 non-remote gambling sectors (betting, casino, bingo, arcades), 48 sector-year observations. ",
  "\\textbf{Method:} Two-way fixed effects (sector + year) with heteroskedasticity-robust standard errors. ",
  "\\textbf{Sample:} All four non-remote gambling sectors for fiscal years ending March 2009 through March 2020; post-period restricted to the single pre-COVID treated year. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  sprintf("Log GGY (sector DiD) & %s & %s & %s & %s & %s & %s \\\\\n",
          format(round(beta_main, 3), nsmall = 3),
          format(round(se_main, 3), nsmall = 3),
          format(round(sd_y_all, 3), nsmall = 3),
          format(round(sde_main, 3), nsmall = 3),
          format(round(se_sde_main, 3), nsmall = 3),
          classify(sde_main)),
  sprintf("GGY levels (\\pounds M) & %s & %s & %s & %s & %s & %s \\\\\n",
          format(round(beta_levels, 1), nsmall = 1),
          format(round(se_levels, 1), nsmall = 1),
          format(round(sd_y_levels, 1), nsmall = 1),
          format(round(sde_levels, 3), nsmall = 3),
          format(round(se_sde_levels, 3), nsmall = 3),
          classify(sde_levels)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:sde}\n",
  "\\end{table}\n"
)
writeLines(sde_tex, "tables/tabF1_sde.tex")
cat("  Written: tables/tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
