## 05_tables.R — Generate all LaTeX tables (manual formatting)
## apep_0812: Pump Prices and Le Pen

source("00_packages.R")
options("modelsummary_format_numeric_latex" = "plain")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

df <- readRDS(file.path(data_dir, "analysis_panel.rds"))
models <- readRDS(file.path(data_dir, "models.rds"))
rob_models <- readRDS(file.path(data_dir, "robustness_models.rds"))

fmt <- function(x, d = 3) sprintf(paste0("%.", d, "f"), x)
star <- function(p) ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.10, "^{*}", "")))

# Helper: extract coef row for a variable from a model
coef_row <- function(mod, var, d = 4) {
  b <- coef(mod)[var]
  s <- se(mod)[var]
  p <- pnorm(-abs(b/s)) * 2
  list(b = b, se = s, p = p,
       b_str = paste0(fmt(b, d), "$", star(p), "$"),
       se_str = paste0("(", fmt(s, d), ")"))
}

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================
cat("=== Table 1: Summary Statistics ===\n")

sv <- function(var, label, d = 2) {
  x <- df[[var]]
  x <- x[!is.na(x)]
  sprintf("%s & %s & %s \\\\", label, fmt(mean(x), d), fmt(sd(x), d))
}

tab1_tex <- paste0(
  "\\begin{table}[t]\n\\centering\n",
  "\\caption{Summary Statistics}\n\\label{tab:summary}\n",
  "\\begin{tabular}{lcc}\n\\hline\\hline\n",
  " & Mean & SD \\\\\n\\hline\n",
  "\\multicolumn{3}{l}{\\textit{Panel A: Treatment}} \\\\\n",
  sv("car_share_11", "Car-commuting share, 2011 (\\%)"), "\n",
  sv("transit_share_11", "Transit share, 2011 (\\%)"), "\n",
  "\\multicolumn{3}{l}{\\textit{Panel B: Outcomes}} \\\\\n",
  sv("lepen_pct_07", "RN vote share, 2007 (\\%)"), "\n",
  sv("lepen_pct_12", "RN vote share, 2012 (\\%)"), "\n",
  sv("lepen_pct_17", "RN vote share, 2017 (\\%)"), "\n",
  sv("lepen_pct_22", "RN vote share, 2022 (\\%)"), "\n",
  sv("delta_lepen_17_12", "$\\Delta$RN 2017--2012 (pp)"), "\n",
  sv("delta_lepen_22_12", "$\\Delta$RN 2022--2012 (pp)"), "\n",
  "\\multicolumn{3}{l}{\\textit{Panel C: Controls}} \\\\\n",
  sprintf("Median income, 2019 (EUR) & %s & %s \\\\\n",
          format(round(mean(df$median_income, na.rm=TRUE)), big.mark=","),
          format(round(sd(df$median_income, na.rm=TRUE)), big.mark=",")),
  sprintf("Population & %s & %s \\\\\n",
          format(round(mean(df$pop, na.rm=TRUE)), big.mark=","),
          format(round(sd(df$pop, na.rm=TRUE)), big.mark=",")),
  "\\hline\n",
  sprintf("Communes & \\multicolumn{2}{c}{%s} \\\\\n",
          format(nrow(df), big.mark=",")),
  sprintf("D\\'{e}partements & \\multicolumn{2}{c}{%d} \\\\\n",
          n_distinct(df$dept)),
  "\\hline\\hline\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Unit of observation is the commune. ",
  "Car-commuting share is the fraction of employed residents who commute by car, ",
  "from the 2011 census (pre-treatment). ",
  "RN vote shares are first-round presidential election results. ",
  "Income from Filosofi 2019.\n",
  "\\end{tablenotes}\n\\end{table}\n"
)
writeLines(tab1_tex, file.path(tables_dir, "tab1_summary.tex"))
cat("  Saved.\n")

# ============================================================
# TABLE 2: Main Results
# ============================================================
cat("=== Table 2: Main Results ===\n")

mods <- list(models$m1, models$m2, models$m3_cl, models$m4, models$m5)
betas <- sapply(mods, function(m) coef_row(m, "car_share_11")$b_str)
ses <- sapply(mods, function(m) coef_row(m, "car_share_11")$se_str)

# Log pop and median income (only in cols 3 and 5)
lp3 <- coef_row(models$m3_cl, "log_pop")
inc3 <- coef_row(models$m3_cl, "median_income", d = 7)

tab2_tex <- paste0(
  "\\begin{table}[t]\n\\centering\n",
  "\\caption{Car-Commuting Exposure and Change in RN Vote Share}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lccccc}\n\\hline\\hline\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & \\multicolumn{3}{c}{$\\Delta$RN 2017--2012} & \\multicolumn{2}{c}{$\\Delta$RN 2022--2012} \\\\\n",
  "\\cmidrule(lr){2-4}\\cmidrule(lr){5-6}\n",
  "\\hline\n",
  sprintf("Car-commuting share (\\%%) & %s & %s & %s & %s & %s \\\\\n",
          betas[1], betas[2], betas[3], betas[4], betas[5]),
  sprintf(" & %s & %s & %s & %s & %s \\\\\n",
          ses[1], ses[2], ses[3], ses[4], ses[5]),
  sprintf("Log population & & & %s & & %s \\\\\n",
          lp3$b_str,
          coef_row(models$m5, "log_pop")$b_str),
  sprintf(" & & & %s & & %s \\\\\n",
          lp3$se_str,
          coef_row(models$m5, "log_pop")$se_str),
  "\\hline\n",
  sprintf("D\\'{e}partement FE & No & Yes & Yes & Yes & Yes \\\\\n"),
  sprintf("Controls & No & No & Yes & No & Yes \\\\\n"),
  sprintf("$N$ & %s & %s & %s & %s & %s \\\\\n",
          format(nobs(models$m1), big.mark=","),
          format(nobs(models$m2), big.mark=","),
          format(nobs(models$m3_cl), big.mark=","),
          format(nobs(models$m4), big.mark=","),
          format(nobs(models$m5), big.mark=",")),
  sprintf("$R^2$ & %s & %s & %s & %s & %s \\\\\n",
          fmt(r2(models$m1)["r2"], 3),
          fmt(r2(models$m2)["r2"], 3),
          fmt(r2(models$m3_cl)["r2"], 3),
          fmt(r2(models$m4)["r2"], 3),
          fmt(r2(models$m5)["r2"], 3)),
  "\\hline\\hline\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Dependent variable is the change in RN (National Rally) ",
  "first-round vote share (percentage points). ",
  "Car-commuting share measured from the 2011 census (pre-treatment). ",
  "Controls include log population and median income. ",
  "Standard errors clustered at the d\\'{e}partement level in columns (2)--(5). ",
  "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "\\end{tablenotes}\n\\end{table}\n"
)
writeLines(tab2_tex, file.path(tables_dir, "tab2_main.tex"))
cat("  Saved.\n")

# ============================================================
# TABLE 3: Pre-Trend and Placebo
# ============================================================
cat("=== Table 3: Pre-Trend and Placebo ===\n")

# Re-estimate pre-trend models here (avoids stale environment issue)
df_pre <- df[!is.na(df$delta_lepen_12_07), ]
m_pre1_local <- feols(delta_lepen_12_07 ~ car_share_11, data = df_pre)
m_pre2_local <- feols(delta_lepen_12_07 ~ car_share_11 | dept, data = df_pre)
pt_mods <- list(m_pre1_local, m_pre2_local, rob_models$m_turnout, rob_models$m_melenchon)
pt_betas <- sapply(pt_mods, function(m) coef_row(m, "car_share_11")$b_str)
pt_ses <- sapply(pt_mods, function(m) coef_row(m, "car_share_11")$se_str)

tab3_tex <- paste0(
  "\\begin{table}[t]\n\\centering\n",
  "\\caption{Pre-Trend and Placebo Tests}\n\\label{tab:pretrend}\n",
  "\\begin{tabular}{lcccc}\n\\hline\\hline\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & \\multicolumn{2}{c}{$\\Delta$RN 2012--2007} & $\\Delta$Turnout & $\\Delta$M\\'{e}lenchon \\\\\n",
  "\\cmidrule(lr){2-3}\\cmidrule(lr){4-4}\\cmidrule(lr){5-5}\n",
  "\\hline\n",
  sprintf("Car-commuting share (\\%%) & %s & %s & %s & %s \\\\\n",
          pt_betas[1], pt_betas[2], pt_betas[3], pt_betas[4]),
  sprintf(" & %s & %s & %s & %s \\\\\n",
          pt_ses[1], pt_ses[2], pt_ses[3], pt_ses[4]),
  "\\hline\n",
  "D\\'{e}partement FE & No & Yes & Yes & Yes \\\\\n",
  sprintf("$N$ & %s & %s & %s & %s \\\\\n",
          format(nobs(models$m_pre1), big.mark=","),
          format(nobs(models$m_pre2), big.mark=","),
          format(nobs(rob_models$m_turnout), big.mark=","),
          format(nobs(rob_models$m_melenchon), big.mark=",")),
  "\\hline\\hline\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Columns (1)--(2): Pre-trend test. ",
  "Dependent variable is the change in RN vote share from 2007 to 2012 (pre-carbon-tax period). ",
  "A zero coefficient validates the parallel-trends assumption. ",
  "Column (3): Turnout change 2017--2012 (placebo). ",
  "Column (4): M\\'{e}lenchon vote share change 2017--2012. ",
  "Standard errors clustered at the d\\'{e}partement level where FE included. ",
  "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "\\end{tablenotes}\n\\end{table}\n"
)
writeLines(tab3_tex, file.path(tables_dir, "tab3_pretrend.tex"))
cat("  Saved.\n")

# ============================================================
# TABLE 4: Robustness
# ============================================================
cat("=== Table 4: Robustness ===\n")

rob_mods <- list(models$m3_cl, rob_models$m_q,
                 rob_models$m_no_idf, rob_models$m_low_income,
                 rob_models$m_high_income)

r4_car <- sapply(rob_mods[c(1,3,4,5)], function(m) coef_row(m, "car_share_11")$b_str)
r4_car_se <- sapply(rob_mods[c(1,3,4,5)], function(m) coef_row(m, "car_share_11")$se_str)
q2 <- coef_row(rob_models$m_q, "car_q_f2")
q3 <- coef_row(rob_models$m_q, "car_q_f3")
q4 <- coef_row(rob_models$m_q, "car_q_f4")

tab4_tex <- paste0(
  "\\begin{table}[t]\n\\centering\n",
  "\\caption{Robustness Checks}\n\\label{tab:robust}\n",
  "\\begin{tabular}{lccccc}\n\\hline\\hline\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & Baseline & Quartile & No IDF & Low Inc. & High Inc. \\\\\n",
  "\\hline\n",
  sprintf("Car-commuting share (\\%%) & %s & & %s & %s & %s \\\\\n",
          r4_car[1], r4_car[2], r4_car[3], r4_car[4]),
  sprintf(" & %s & & %s & %s & %s \\\\\n",
          r4_car_se[1], r4_car_se[2], r4_car_se[3], r4_car_se[4]),
  sprintf("Quartile 2 & & %s & & & \\\\\n", q2$b_str),
  sprintf(" & & %s & & & \\\\\n", q2$se_str),
  sprintf("Quartile 3 & & %s & & & \\\\\n", q3$b_str),
  sprintf(" & & %s & & & \\\\\n", q3$se_str),
  sprintf("Quartile 4 & & %s & & & \\\\\n", q4$b_str),
  sprintf(" & & %s & & & \\\\\n", q4$se_str),
  "\\hline\n",
  "D\\'{e}partement FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  sprintf("$N$ & %s & %s & %s & %s & %s \\\\\n",
          format(nobs(rob_mods[[1]]), big.mark=","),
          format(nobs(rob_mods[[2]]), big.mark=","),
          format(nobs(rob_mods[[3]]), big.mark=","),
          format(nobs(rob_mods[[4]]), big.mark=","),
          format(nobs(rob_mods[[5]]), big.mark=",")),
  "\\hline\\hline\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Dependent variable: $\\Delta$RN 2017--2012 (pp). ",
  "All models include d\\'{e}partement fixed effects. ",
  "Column (1): baseline specification with controls. ",
  "Column (2): quartile treatment (Q1 omitted). ",
  "Column (3): excluding \\^{I}le-de-France. ",
  "Columns (4)--(5): split by commune median income. ",
  "Standard errors clustered at the d\\'{e}partement level. ",
  "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "\\end{tablenotes}\n\\end{table}\n"
)
writeLines(tab4_tex, file.path(tables_dir, "tab4_robustness.tex"))
cat("  Saved.\n")

# ============================================================
# TABLE F1: SDE
# ============================================================
cat("=== Table F1: SDE ===\n")

outcomes <- list(
  list(name = "$\\Delta$RN 2017--2012", model = models$m3_cl,
       var = "car_share_11", y = "delta_lepen_17_12"),
  list(name = "$\\Delta$RN 2022--2012", model = models$m5,
       var = "car_share_11", y = "delta_lepen_22_12"),
  list(name = "$\\Delta$Turnout 2017--2012", model = rob_models$m_turnout,
       var = "car_share_11", y = "delta_turnout_17_12"),
  list(name = "$\\Delta$M\\'{e}lenchon 2017--2012", model = rob_models$m_melenchon,
       var = "car_share_11", y = "delta_melenchon_17_12")
)

sde_rows <- c()
for (o in outcomes) {
  b <- coef(o$model)[o$var]
  s <- se(o$model)[o$var]
  sd_x <- sd(df$car_share_11, na.rm = TRUE)
  sd_y <- sd(df[[o$y]], na.rm = TRUE)
  sde <- b * sd_x / sd_y
  se_sde <- s * sd_x / sd_y
  bucket <- case_when(
    sde < -0.15 ~ "Large neg.",
    sde < -0.05 ~ "Mod. neg.",
    sde < -0.005 ~ "Small neg.",
    sde < 0.005 ~ "Null",
    sde < 0.05 ~ "Small pos.",
    sde < 0.15 ~ "Mod. pos.",
    TRUE ~ "Large pos."
  )
  sde_rows <- c(sde_rows,
    sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
            o$name, fmt(b, 4), fmt(s, 4), fmt(sd_y, 2),
            fmt(sde, 3), fmt(se_sde, 3), bucket))
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} France. ",
  "\\textbf{Research question:} Does the 2014--2018 carbon tax escalation (TICPE composante carbone) ",
  "cause differential increases in National Rally (RN) vote share in car-dependent communes? ",
  "\\textbf{Policy mechanism:} France's carbon component of the domestic fuel tax (TICPE) rose from ",
  "7 to 44.60 EUR/tCO\\textsubscript{2} over 2014--2018, adding approximately 12 cents per liter to diesel; ",
  "communes with higher car-commuting shares face a larger effective fuel-cost burden per household. ",
  "\\textbf{Outcome definition:} Change in first-round presidential RN vote share (percentage points), ",
  "2017 minus 2012 (primary) and 2022 minus 2012 (long-run). ",
  "\\textbf{Treatment:} Continuous; commune-level car-commuting share from the 2011 census ",
  "(fraction of employed residents age 15+ commuting by car). ",
  "\\textbf{Data:} Minist\\`{e}re de l'Int\\'{e}rieur election results (data.gouv.fr), ",
  "INSEE RP 2011 census (transport mode), Filosofi 2019 (income); 33,390 communes, 2007--2022. ",
  "\\textbf{Method:} Cross-sectional first-difference with d\\'{e}partement fixed effects and controls; ",
  "standard errors clustered at d\\'{e}partement level (96 clusters). ",
  "\\textbf{Sample:} Metropolitan France communes with $\\geq$50 registered voters and $\\geq$10 employed residents in 2011. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the cross-commune ",
  "standard deviation of car-commuting share and SD($Y$) is the outcome standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- paste0(
  "\\begin{table}[t]\n\\centering\n",
  "\\caption{Standardized Effect Sizes}\n\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  paste(sde_rows, collapse = "\n"), "\n",
  "\\hline\\hline\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n\\end{table}\n"
)
writeLines(sde_tex, file.path(tables_dir, "tabF1_sde.tex"))
cat("  Saved.\n")

cat("\nAll tables generated.\n")
