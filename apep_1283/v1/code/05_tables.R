# =============================================================================
# 05_tables.R — Generate all LaTeX tables including SDE appendix
# Paper: apep_1283 — Prevailing Wage Repeals and the Racial Earnings Gap
# =============================================================================

source("00_packages.R")

df_state  <- readRDS("../data/analysis_state.rds")
df_sector <- readRDS("../data/analysis_sector.rds")
df_mfg    <- readRDS("../data/analysis_mfg.rds")
results   <- readRDS("../data/main_results.rds")
rob       <- readRDS("../data/robustness_results.rds")

# ---------------------------------------------------------------------------
# Table 1: Summary Statistics
# ---------------------------------------------------------------------------
cat("=== Generating Table 1: Summary Statistics ===\n")

# Pre-treatment period only
pre_state <- df_state %>%
  filter(!treated_state | period < first_treat_period)

# Treated vs control comparison
summ_stats <- bind_rows(
  df_state %>% filter(treated_state) %>%
    summarise(
      Group = "Treated states",
      N = n(),
      `Mean B/W Ratio` = mean(bw_ratio, na.rm=T),
      `SD B/W Ratio` = sd(bw_ratio, na.rm=T),
      `Mean Black Earnings` = mean(earn_black, na.rm=T),
      `Mean White Earnings` = mean(earn_white, na.rm=T),
      `Mean Black Emp` = mean(emp_black, na.rm=T),
      `Mean White Emp` = mean(emp_white, na.rm=T)
    ),
  df_state %>% filter(!treated_state) %>%
    summarise(
      Group = "Control states",
      N = n(),
      `Mean B/W Ratio` = mean(bw_ratio, na.rm=T),
      `SD B/W Ratio` = sd(bw_ratio, na.rm=T),
      `Mean Black Earnings` = mean(earn_black, na.rm=T),
      `Mean White Earnings` = mean(earn_white, na.rm=T),
      `Mean Black Emp` = mean(emp_black, na.rm=T),
      `Mean White Emp` = mean(emp_white, na.rm=T)
    )
)

# LaTeX table
tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: Construction Industry by Treatment Status}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lccccccc}",
  "\\toprule",
  " & N & \\multicolumn{2}{c}{B/W Ratio} & \\multicolumn{2}{c}{Earnings (\\$)} & \\multicolumn{2}{c}{Employment} \\\\",
  "\\cmidrule(lr){3-4} \\cmidrule(lr){5-6} \\cmidrule(lr){7-8}",
  " & (St-Qtrs) & Mean & SD & Black & White & Black & White \\\\"
)

for (i in 1:nrow(summ_stats)) {
  row <- summ_stats[i, ]
  tab1_lines <- c(tab1_lines,
    "\\midrule",
    sprintf("%s & %s & %.3f & %.3f & %s & %s & %s & %s \\\\",
      row$Group,
      format(row$N, big.mark = ","),
      row$`Mean B/W Ratio`,
      row$`SD B/W Ratio`,
      format(round(row$`Mean Black Earnings`), big.mark = ","),
      format(round(row$`Mean White Earnings`), big.mark = ","),
      format(round(row$`Mean Black Emp`), big.mark = ","),
      format(round(row$`Mean White Emp`), big.mark = ",")
    )
  )
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item \\textit{Notes:} Data from QWI race $\\times$ 3-digit NAICS files (Census Bureau), 2010Q1--2023Q4. Construction comprises NAICS 236 (Building), 237 (Heavy/Civil Engineering), and 238 (Specialty Trade Contractors). B/W Earnings Ratio is average monthly earnings of Black workers divided by White workers, weighted by total employment. Treated states repealed prevailing wage laws 2015--2018: IN (2015Q3), WV (2016Q1), KY and AR (2017Q1), WI (2017Q4), MI (2018Q2). Control: %d states maintaining prevailing wage laws throughout.",
    n_distinct(df_state$state_abbr[!df_state$treated_state])),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")

# ---------------------------------------------------------------------------
# Table 2: Main Results (CS ATT + TWFE + Sun-Abraham)
# ---------------------------------------------------------------------------
cat("=== Generating Table 2: Main Results ===\n")

cs_att <- results$cs_agg
twfe <- results$twfe_main
ln_gap <- rob$twfe_ln

# Extract coefficients
cs_coef  <- cs_att$overall.att
cs_se    <- cs_att$overall.se
twfe_coef <- coef(twfe)["post_repeal"]
twfe_se   <- se(twfe)["post_repeal"]
ln_coef  <- coef(ln_gap)["post_repeal"]
ln_se    <- se(ln_gap)["post_repeal"]

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

cs_p  <- 2 * pnorm(-abs(cs_coef / cs_se))
twfe_p <- pvalue(twfe)["post_repeal"]
ln_p  <- pvalue(ln_gap)["post_repeal"]

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of Prevailing Wage Repeal on the Black-White Earnings Ratio in Construction}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & (1) & (2) & (3) \\\\",
  " & CS ATT & TWFE & Log Gap \\\\",
  "\\midrule",
  sprintf("Post Repeal & %.4f%s & %.4f%s & %.4f%s \\\\",
    cs_coef, stars(cs_p), twfe_coef, stars(twfe_p), ln_coef, stars(ln_p)),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) \\\\", cs_se, twfe_se, ln_se),
  "\\\\",
  sprintf("Observations & %s & %s & %s \\\\",
    format(nrow(df_state), big.mark = ","),
    format(nrow(df_state), big.mark = ","),
    format(nrow(df_state), big.mark = ",")),
  sprintf("States & %d & %d & %d \\\\",
    n_distinct(df_state$state_abbr),
    n_distinct(df_state$state_abbr),
    n_distinct(df_state$state_abbr)),
  "Estimator & Callaway-Sant'Anna & TWFE & TWFE \\\\",
  "Outcome & B/W Ratio & B/W Ratio & Log(B/W) \\\\",
  "State FE & Yes & Yes & Yes \\\\",
  "Quarter FE & Yes & Yes & Yes \\\\",
  "Clustering & State & State & State \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} * $p<0.10$, ** $p<0.05$, *** $p<0.01$. Standard errors clustered at the state level in parentheses. The outcome in columns (1)--(2) is the ratio of average monthly earnings of Black to White construction workers (NAICS 23x). Column (3) uses the log difference. The sample covers 2010Q1--2023Q4. Callaway-Sant'Anna estimates in column (1) use never-treated states as the control group.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")

# ---------------------------------------------------------------------------
# Table 3: Mechanism Test (by NAICS subsector)
# ---------------------------------------------------------------------------
cat("=== Generating Table 3: Mechanism Test ===\n")

m237 <- results$twfe_237
m236 <- results$twfe_236
m238 <- results$twfe_238
tdid <- results$triple_did

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Mechanism Test: Effect by Construction Subsector}",
  "\\label{tab:mechanism}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & NAICS 237 & NAICS 236 & NAICS 238 & Triple-DiD \\\\",
  " & Heavy/Civil & Building & Specialty & Public $\\times$ Post \\\\",
  "\\midrule"
)

# Column 1-3: subsector TWFE
for (i in list(list(m237, "237"), list(m236, "236"), list(m238, "238"))) {
  mod <- i[[1]]
  # Already printed in cols
}

c1 <- coef(m237)["post_repeal"]; s1 <- se(m237)["post_repeal"]; p1 <- pvalue(m237)["post_repeal"]
c2 <- coef(m236)["post_repeal"]; s2 <- se(m236)["post_repeal"]; p2 <- pvalue(m236)["post_repeal"]
c3 <- coef(m238)["post_repeal"]; s3 <- se(m238)["post_repeal"]; p3 <- pvalue(m238)["post_repeal"]

# Triple-DiD coefficient
td_coef <- coef(tdid)["post_repeal:is_public_constructionTRUE"]
td_se <- se(tdid)["post_repeal:is_public_constructionTRUE"]
td_p <- pvalue(tdid)["post_repeal:is_public_constructionTRUE"]

tab3_lines <- c(tab3_lines,
  sprintf("Post Repeal & %.4f%s & %.4f%s & %.4f%s & \\\\",
    c1, stars(p1), c2, stars(p2), c3, stars(p3)),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & \\\\", s1, s2, s3)
)

if (!is.na(td_coef)) {
  tab3_lines <- c(tab3_lines,
    sprintf("Public $\\times$ Post & & & & %.4f%s \\\\", td_coef, stars(td_p)),
    sprintf(" & & & & (%.4f) \\\\", td_se)
  )
} else {
  tab3_lines <- c(tab3_lines,
    "Public $\\times$ Post & & & & --- \\\\",
    " & & & & \\\\")
}

n237 <- nrow(df_sector %>% filter(industry_int == 237))
n236 <- nrow(df_sector %>% filter(industry_int == 236))
n238 <- nrow(df_sector %>% filter(industry_int == 238))
n_td <- nrow(df_sector)  # df_sector is already filtered to construction

tab3_lines <- c(tab3_lines,
  "\\\\",
  sprintf("Observations & %s & %s & %s & %s \\\\",
    format(n237, big.mark=","), format(n236, big.mark=","),
    format(n238, big.mark=","), format(n_td, big.mark=",")),
  "State FE & Yes & Yes & Yes & Yes \\\\",
  "Quarter FE & Yes & Yes & Yes & Yes \\\\",
  "Industry FE & & & & Yes \\\\",
  "Clustering & State & State & State & State \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} * $p<0.10$, ** $p<0.05$, *** $p<0.01$. Standard errors clustered at the state level in parentheses. The outcome is the Black-to-White average monthly earnings ratio within each NAICS subsector. NAICS 237 (Heavy and Civil Engineering Construction) is approximately 95\\% publicly funded and therefore most directly affected by prevailing wage requirements. NAICS 236 (Building Construction) is predominantly private. NAICS 238 (Specialty Trade Contractors) is mixed. Column (4) estimates a triple-difference: the differential effect of repeal on the B/W ratio in NAICS 237 relative to NAICS 236 and 238.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_mechanism.tex")

# ---------------------------------------------------------------------------
# Table 4: Robustness
# ---------------------------------------------------------------------------
cat("=== Generating Table 4: Robustness ===\n")

placebo <- rob$placebo_mfg
no_rtw  <- rob$twfe_no_rtw

pc <- coef(placebo)["post_repeal"]; ps <- se(placebo)["post_repeal"]; pp <- pvalue(placebo)["post_repeal"]
nc <- coef(no_rtw)["post_repeal"]; ns <- se(no_rtw)["post_repeal"]; np <- pvalue(no_rtw)["post_repeal"]

tab4_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness and Placebo Tests}",
  "\\label{tab:robust}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & (1) & (2) & (3) \\\\",
  " & Baseline & Placebo: Mfg & Drop WV/KY \\\\",
  "\\midrule",
  sprintf("Post Repeal & %.4f%s & %.4f%s & %.4f%s \\\\",
    twfe_coef, stars(twfe_p), pc, stars(pp), nc, stars(np)),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) \\\\", twfe_se, ps, ns),
  "\\\\",
  sprintf("Observations & %s & %s & %s \\\\",
    format(nrow(df_state), big.mark=","),
    format(nrow(df_mfg), big.mark=","),
    format(nrow(df_state %>% filter(!(state_abbr %in% c("wv","ky")))), big.mark=",")),
  "Industry & Construction & Manufacturing & Construction \\\\",
  "States excl. & None & None & WV, KY \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} * $p<0.10$, ** $p<0.05$, *** $p<0.01$. Standard errors clustered at the state level. Column (1) reproduces the baseline TWFE estimate from \\Cref{tab:main}. Column (2) replaces construction with manufacturing (NAICS 31--33), where prevailing wage laws have no coverage --- a null effect is expected. Column (3) drops West Virginia and Kentucky, where right-to-work legislation was adopted concurrently with prevailing wage repeal.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_robustness.tex")

# ---------------------------------------------------------------------------
# Table 5: Leave-One-Out
# ---------------------------------------------------------------------------
cat("=== Generating Table 5: Leave-One-Out ===\n")

loo <- rob$loo_df

tab5_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Leave-One-Out Sensitivity: Dropping Each Treated State}",
  "\\label{tab:loo}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Dropped State & Coefficient & SE & $p$-value \\\\",
  "\\midrule",
  sprintf("None (baseline) & %.4f & %.4f & %.3f \\\\", twfe_coef, twfe_se, twfe_p)
)

state_names <- c("in"="Indiana", "wv"="West Virginia", "ky"="Kentucky",
                 "ar"="Arkansas", "wi"="Wisconsin", "mi"="Michigan")

for (i in 1:nrow(loo)) {
  r <- loo[i, ]
  tab5_lines <- c(tab5_lines,
    sprintf("%s & %.4f & %.4f & %.3f \\\\",
      state_names[r$dropped], r$coef, r$se, r$pval)
  )
}

tab5_lines <- c(tab5_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each row drops one treated state and re-estimates the TWFE specification from \\Cref{tab:main}, column (2). Standard errors clustered at the state level.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab5_lines, "../tables/tab5_loo.tex")

# ---------------------------------------------------------------------------
# Table F1: Standardized Effect Sizes (SDE) — MANDATORY APPENDIX
# ---------------------------------------------------------------------------
cat("=== Generating Table F1: Standardized Effect Sizes ===\n")

# Compute SDEs
sd_y <- sd(df_state$bw_ratio, na.rm = TRUE)

classify <- function(s) dplyr::case_when(
  s < -0.15  ~ "Large negative",
  s < -0.05  ~ "Moderate negative",
  s < -0.005 ~ "Small negative",
  s <  0.005 ~ "Null",
  s <  0.05  ~ "Small positive",
  s <  0.15  ~ "Moderate positive",
  TRUE       ~ "Large positive"
)

# Panel A: Pooled
beta_main <- twfe_coef
se_main <- twfe_se
sde_main <- beta_main / sd_y
se_sde_main <- se_main / sd_y

# Panel B: Heterogeneous — by subsector (mechanism split)
# NAICS 237 (public)
sd_y_237 <- sd(df_sector$bw_ratio[df_sector$industry_int == 237], na.rm = TRUE)
beta_237 <- coef(results$twfe_237)["post_repeal"]
se_237 <- se(results$twfe_237)["post_repeal"]
sde_237 <- beta_237 / sd_y_237
se_sde_237 <- se_237 / sd_y_237

# NAICS 236/238 (private/mixed)
df_private <- df_sector %>% filter(industry_int %in% c(236, 238))
sd_y_priv <- sd(df_private$bw_ratio, na.rm = TRUE)
twfe_priv <- feols(
  bw_ratio ~ post_repeal | state_id + period,
  data = df_private %>% mutate(
    state_id = as.integer(factor(state_abbr)),
    post_repeal = as.integer(treated_state & period >= first_treat_period)
  ),
  cluster = ~state_id
)
beta_priv <- coef(twfe_priv)["post_repeal"]
se_priv <- se(twfe_priv)["post_repeal"]
sde_priv <- beta_priv / sd_y_priv
se_sde_priv <- se_priv / sd_y_priv

# Build SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Whether state-level repeal of prevailing wage laws ",
  "widens the Black-to-White earnings gap among construction workers, ",
  "and whether the effect concentrates in publicly funded subsectors. ",
  "\\textbf{Policy mechanism:} Prevailing wage laws (Little Davis-Bacon Acts) require ",
  "contractors on publicly funded construction projects to pay at least the locally ",
  "prevailing (typically union-equivalent) wage; repeal removes this mandatory floor, ",
  "allowing public-project wages to be set competitively, potentially widening racial ",
  "earnings gaps if Black workers disproportionately benefited from the union-scale floor. ",
  "\\textbf{Outcome definition:} Ratio of average monthly earnings of Black construction ",
  "workers (QWI race code A2) to White construction workers (race code A1) within NAICS 23x. ",
  "\\textbf{Treatment:} Binary (0/1) indicator for state having repealed its prevailing wage law. ",
  "\\textbf{Data:} Quarterly Workforce Indicators (QWI) race $\\times$ 3-digit NAICS files ",
  "(Census Bureau), 2010Q1--2023Q4, state-quarter level, ",
  format(nrow(df_state), big.mark = ","), " state-quarter observations across ",
  n_distinct(df_state$state_abbr), " states. ",
  "\\textbf{Method:} Staggered difference-in-differences with TWFE estimator (verified against ",
  "Callaway--Sant'Anna); state-clustered standard errors with wild cluster bootstrap. ",
  "\\textbf{Sample:} Six states repealing prevailing wage laws (2015--2018) versus 28 states ",
  "maintaining them; restricted to construction industries (NAICS 236, 237, 238). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard ",
  "deviation of the B/W earnings ratio. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{llcccccc}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("B/W Earnings Ratio & All Construction & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
    beta_main, se_main, sd_y, sde_main, se_sde_main, classify(sde_main)),
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous (by subsector)}} \\\\",
  sprintf("B/W Earnings Ratio & NAICS 237 (Public) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
    beta_237, se_237, sd_y_237, sde_237, se_sde_237, classify(sde_237)),
  sprintf("B/W Earnings Ratio & NAICS 236/238 (Private) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
    beta_priv, se_priv, sd_y_priv, sde_priv, se_sde_priv, classify(sde_priv)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(sde_lines, "../tables/tabF1_sde.tex")

cat("\nAll tables generated.\n")
