## gen_tables.R — Generate LaTeX tables from saved results
suppressPackageStartupMessages({
  library(tidyverse)
  library(fixest)
})

# Working directory assumed to be code/ subdirectory
results <- readRDS("data/main_results.rds")
rob <- readRDS("data/robustness_results.rds")
did_panel <- read_csv("data/analysis_panel.csv", show_col_types = FALSE)

# Exclude pre-2019
did_panel <- did_panel |> filter(cc_wave != "Pre-2019")
n_treated <- n_distinct(did_panel$state_fips[did_panel$gname > 0])
n_control <- n_distinct(did_panel$state_fips[did_panel$gname == 0])

pval_fn <- function(est, se) {
  ifelse(is.na(est) | is.na(se) | se == 0, NA_real_, 2 * pnorm(-abs(est / se)))
}
stars_fn <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

agg_hom <- results$agg_hom
agg_sui <- results$agg_sui
agg_total <- results$agg_total
es_hom <- results$es_hom
es_sui <- results$es_sui
grp_hom <- results$grp_hom
grp_sui <- results$grp_sui
twfe_hom <- results$twfe_hom
twfe_sui <- results$twfe_sui
twfe_total <- results$twfe_total

# ---- Table 1: Summary Stats ----
summ_t <- did_panel |> filter(gname > 0, year < gname) |>
  summarise(across(c(fa_homicide_rate, fa_suicide_rate, total_fa_rate, population),
                   list(m=~mean(.,na.rm=T), s=~sd(.,na.rm=T))))
summ_c <- did_panel |> filter(gname == 0) |>
  summarise(across(c(fa_homicide_rate, fa_suicide_rate, total_fa_rate, population),
                   list(m=~mean(.,na.rm=T), s=~sd(.,na.rm=T))))

tab1 <- sprintf("\\begin{table}[H]
\\centering
\\caption{Summary Statistics}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
& \\multicolumn{2}{c}{CC States (Pre-Treat)} & \\multicolumn{2}{c}{Never-CC States} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
Variable & Mean & SD & Mean & SD \\\\
\\midrule
Firearm homicide rate & %.2f & %.2f & %.2f & %.2f \\\\
Firearm suicide rate & %.2f & %.2f & %.2f & %.2f \\\\
Total firearm death rate & %.2f & %.2f & %.2f & %.2f \\\\
Population (millions) & %.2f & %.2f & %.2f & %.2f \\\\
\\midrule
States & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\
State-year observations & \\multicolumn{4}{c}{%s} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Rates per 100,000 population. CC states: states adopting constitutional carry 2019--2024; pre-treatment means computed using only years prior to each state's adoption. Never-CC states: states without constitutional carry as of 2024. Data: CDC Mapping Injury (2019--2024), Census Bureau population estimates.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:summary}
\\end{table}",
  summ_t$fa_homicide_rate_m, summ_t$fa_homicide_rate_s, summ_c$fa_homicide_rate_m, summ_c$fa_homicide_rate_s,
  summ_t$fa_suicide_rate_m, summ_t$fa_suicide_rate_s, summ_c$fa_suicide_rate_m, summ_c$fa_suicide_rate_s,
  summ_t$total_fa_rate_m, summ_t$total_fa_rate_s, summ_c$total_fa_rate_m, summ_c$total_fa_rate_s,
  summ_t$population_m/1e6, summ_t$population_s/1e6, summ_c$population_m/1e6, summ_c$population_s/1e6,
  n_treated, n_control, format(nrow(did_panel), big.mark=","))
writeLines(tab1, "tables/tab1_summary.tex")
cat("Table 1 done\n")

# ---- Table 2: Main Results ----
ctrl_hom <- mean(did_panel$fa_homicide_rate[did_panel$gname==0], na.rm=T)
ctrl_sui <- mean(did_panel$fa_suicide_rate[did_panel$gname==0], na.rm=T)
ctrl_tot <- mean(did_panel$total_fa_rate[did_panel$gname==0], na.rm=T)
p_h <- pval_fn(agg_hom$overall.att, agg_hom$overall.se)
p_s <- pval_fn(agg_sui$overall.att, agg_sui$overall.se)
p_t <- pval_fn(agg_total$overall.att, agg_total$overall.se)

tab2 <- sprintf("\\begin{table}[H]
\\centering
\\caption{Effect of Constitutional Carry Laws on Firearm Mortality}
\\begin{threeparttable}
\\begin{tabular}{lccc}
\\toprule
& \\multicolumn{3}{c}{Outcome (rate per 100,000)} \\\\
\\cmidrule(lr){2-4}
& FA Homicide & FA Suicide & Total FA Deaths \\\\
& (1) & (2) & (3) \\\\
\\midrule
\\multicolumn{4}{l}{\\textit{Panel A: Callaway--Sant'Anna}} \\\\[3pt]
ATT & %.3f%s & %.3f%s & %.3f%s \\\\
& (%.3f) & (%.3f) & (%.3f) \\\\
95%%%% CI & [%.3f, %.3f] & [%.3f, %.3f] & [%.3f, %.3f] \\\\[6pt]
\\multicolumn{4}{l}{\\textit{Panel B: TWFE}} \\\\[3pt]
Treated & %.3f%s & %.3f%s & %.3f%s \\\\
& (%.3f) & (%.3f) & (%.3f) \\\\
\\midrule
Control mean & %.2f & %.2f & %.2f \\\\
Effect as %%%% of mean & %.1f%%%% & %.1f%%%% & %.1f%%%% \\\\
Treated states & %d & %d & %d \\\\
Control states & %d & %d & %d \\\\
Observations & %s & %s & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Panel A: overall ATT from \\citet{callaway2021} with never-treated states as controls. Panel B: TWFE with state and year FE. Standard errors clustered at the state level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:main}
\\end{table}",
  agg_hom$overall.att, stars_fn(p_h), agg_sui$overall.att, stars_fn(p_s), agg_total$overall.att, stars_fn(p_t),
  agg_hom$overall.se, agg_sui$overall.se, agg_total$overall.se,
  agg_hom$overall.att-1.96*agg_hom$overall.se, agg_hom$overall.att+1.96*agg_hom$overall.se,
  agg_sui$overall.att-1.96*agg_sui$overall.se, agg_sui$overall.att+1.96*agg_sui$overall.se,
  agg_total$overall.att-1.96*agg_total$overall.se, agg_total$overall.att+1.96*agg_total$overall.se,
  coef(twfe_hom)["treated"], stars_fn(pvalue(twfe_hom)["treated"]),
  coef(twfe_sui)["treated"], stars_fn(pvalue(twfe_sui)["treated"]),
  coef(twfe_total)["treated"], stars_fn(pvalue(twfe_total)["treated"]),
  se(twfe_hom)["treated"], se(twfe_sui)["treated"], se(twfe_total)["treated"],
  ctrl_hom, ctrl_sui, ctrl_tot,
  agg_hom$overall.att/ctrl_hom*100, agg_sui$overall.att/ctrl_sui*100, agg_total$overall.att/ctrl_tot*100,
  n_treated, n_treated, n_treated, n_control, n_control, n_control,
  format(nrow(did_panel),big.mark=","), format(nrow(did_panel),big.mark=","), format(nrow(did_panel),big.mark=","))
writeLines(tab2, "tables/tab2_main.tex")
cat("Table 2 done\n")

# ---- Table 3: Event Study ----
es_df <- tibble(et=es_hom$egt, ah=es_hom$att.egt, sh=es_hom$se.egt,
                as_=es_sui$att.egt, ss=es_sui$se.egt) |>
  filter(!is.na(ah), !is.na(as_))

es_rows <- es_df |>
  mutate(r = sprintf("$k = %+d$ & %.3f%s & (%.3f) & %.3f%s & (%.3f) \\\\",
    et, ah, sapply(pval_fn(ah,sh), stars_fn), sh,
    as_, sapply(pval_fn(as_,ss), stars_fn), ss)) |> pull(r)

tab3 <- paste0("\\begin{table}[H]\n\\centering\n\\caption{Event Study: Dynamic Treatment Effects}\n",
  "\\begin{threeparttable}\n\\begin{tabular}{lcccc}\n\\toprule\n",
  "& \\multicolumn{2}{c}{FA Homicide Rate} & \\multicolumn{2}{c}{FA Suicide Rate} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  "Event Time & ATT & SE & ATT & SE \\\\\n\\midrule\n",
  paste(es_rows, collapse="\n"), "\n\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n\\small\n",
  "\\item \\textit{Notes:} Event study from \\citet{callaway2021}, dynamic aggregation. $k=0$ is adoption year. Negative $k$ test parallel trends. Never-treated controls. State-clustered SEs. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\label{tab:eventstudy}\n\\end{table}")
writeLines(tab3, "tables/tab3_eventstudy.tex")
cat("Table 3 done\n")

# ---- Table 4: Robustness ----
agg_nfa_hom <- rob$agg_nfa_hom
agg_nfa_sui <- rob$agg_nfa_sui
agg_hom_nyt <- rob$agg_hom_nyt
agg_sui_nyt <- rob$agg_sui_nyt
loo <- rob$loo_results

tab4 <- sprintf("\\begin{table}[H]
\\centering
\\caption{Robustness Checks}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
& \\multicolumn{2}{c}{FA Homicide} & \\multicolumn{2}{c}{FA Suicide} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
Specification & ATT & SE & ATT & SE \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Panel A: Baseline}} \\\\[3pt]
CS-DiD (never-treated) & %.3f%s & (%.3f) & %.3f%s & (%.3f) \\\\[6pt]
\\multicolumn{5}{l}{\\textit{Panel B: Alternative Control}} \\\\[3pt]
CS-DiD (not-yet-treated) & %.3f%s & (%.3f) & %.3f%s & (%.3f) \\\\[6pt]
\\multicolumn{5}{l}{\\textit{Panel C: Placebo Outcomes}} \\\\[3pt]
Non-firearm homicide & %.3f%s & (%.3f) & & \\\\
Non-firearm suicide & & & %.3f%s & (%.3f) \\\\[6pt]
\\multicolumn{5}{l}{\\textit{Panel D: Leave-One-Out}} \\\\[3pt]
Min ATT (homicide) & %.3f & & & \\\\
Max ATT (homicide) & %.3f & & & \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Panel A: baseline from \\Cref{tab:main}. Panel B: not-yet-treated control group. Panel C: placebo outcomes that should not respond to gun carry laws. Panel D: range of FA homicide ATT when each treated state is dropped. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:robustness}
\\end{table}",
  agg_hom$overall.att, stars_fn(p_h), agg_hom$overall.se,
  agg_sui$overall.att, stars_fn(p_s), agg_sui$overall.se,
  agg_hom_nyt$overall.att, stars_fn(pval_fn(agg_hom_nyt$overall.att, agg_hom_nyt$overall.se)), agg_hom_nyt$overall.se,
  agg_sui_nyt$overall.att, stars_fn(pval_fn(agg_sui_nyt$overall.att, agg_sui_nyt$overall.se)), agg_sui_nyt$overall.se,
  agg_nfa_hom$overall.att, stars_fn(pval_fn(agg_nfa_hom$overall.att, agg_nfa_hom$overall.se)), agg_nfa_hom$overall.se,
  agg_nfa_sui$overall.att, stars_fn(pval_fn(agg_nfa_sui$overall.att, agg_nfa_sui$overall.se)), agg_nfa_sui$overall.se,
  min(loo$att, na.rm=T), max(loo$att, na.rm=T))
writeLines(tab4, "tables/tab4_robustness.tex")
cat("Table 4 done\n")

# ---- Table 5: Cohort Heterogeneity ----
gd <- tibble(cohort=grp_hom$egt, ah=grp_hom$att.egt, sh=grp_hom$se.egt,
             as_=grp_sui$att.egt, ss=grp_sui$se.egt,
             ns=sapply(grp_hom$egt, function(g) n_distinct(did_panel$state_fips[did_panel$gname==g]))) |>
  filter(!is.na(ah))

grp_rows <- gd |> mutate(
  r=sprintf("%d & %d & %.3f%s & (%.3f) & %.3f%s & (%.3f) \\\\",
    cohort, ns, ah, sapply(pval_fn(ah,sh), stars_fn), sh,
    as_, sapply(pval_fn(as_,ss), stars_fn), ss)) |> pull(r)

tab5 <- paste0("\\begin{table}[H]\n\\centering\n\\caption{Treatment Effects by Adoption Cohort}\n",
  "\\begin{threeparttable}\n\\begin{tabular}{cccccc}\n\\toprule\n",
  "& & \\multicolumn{2}{c}{FA Homicide} & \\multicolumn{2}{c}{FA Suicide} \\\\\n",
  "\\cmidrule(lr){3-4} \\cmidrule(lr){5-6}\n",
  "Cohort & States & ATT & SE & ATT & SE \\\\\n\\midrule\n",
  paste(grp_rows, collapse="\n"), "\n\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n\\small\n",
  "\\item \\textit{Notes:} Group-specific ATTs from \\citet{callaway2021}. Each row: ATT for states adopting in indicated year. State-clustered SEs. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\label{tab:heterogeneity}\n\\end{table}")
writeLines(tab5, "tables/tab5_heterogeneity.tex")
cat("Table 5 done\n")

# ---- SDE Table ----
sd_h <- sd(did_panel$fa_homicide_rate, na.rm=T)
sd_s <- sd(did_panel$fa_suicide_rate, na.rm=T)
sd_t <- sd(did_panel$total_fa_rate, na.rm=T)

sde_cls <- function(s) case_when(s < -0.15 ~ "Large negative", s < -0.05 ~ "Moderate negative",
  s < -0.005 ~ "Small negative", s < 0.005 ~ "Null", s < 0.05 ~ "Small positive",
  s < 0.15 ~ "Moderate positive", TRUE ~ "Large positive")

sde <- tibble(
  Outcome=c("Firearm homicide rate","Firearm suicide rate","Total firearm death rate"),
  beta=c(agg_hom$overall.att, agg_sui$overall.att, agg_total$overall.att),
  se_b=c(agg_hom$overall.se, agg_sui$overall.se, agg_total$overall.se),
  sdy=c(sd_h, sd_s, sd_t)
) |> mutate(sde=beta/sdy, se_sde=se_b/sdy, cls=sde_cls(sde))

sde_rows <- sde |> mutate(r=sprintf("%s & %.3f & (%.3f) & %.2f & %.3f & (%.3f) & %s \\\\",
  Outcome, beta, se_b, sdy, sde, se_sde, cls)) |> pull(r)

sde_tex <- paste0("\\begin{table}[H]\n\\centering\n\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n\\begin{tabular}{lcccccc}\n\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n\\midrule\n",
  paste(sde_rows, collapse="\n"), "\n\\bottomrule\n\\end{tabular}\n",
  "\\par\\vspace{0.3em}\n",
  "{\\footnotesize \\emph{Notes:} SDE $= \\hat{\\beta} / \\text{SD}(Y)$. ",
  "\\textbf{Research question:} Effect of constitutional carry laws on firearm mortality. ",
  "\\textbf{Treatment:} Binary---state adopted CC (2019--2024 wave). ",
  "\\textbf{Data:} CDC Mapping Injury (2019--2024), ", format(nrow(did_panel), big.mark=","), " state-year obs. ",
  "\\textbf{Method:} Staggered DiD, Callaway--Sant'Anna, state-clustered SEs. ",
  "Classification labels refer to the magnitude of the standardized point estimate, ",
  "not to statistical significance. ``Null'' denotes $|$SDE$| < 0.005$.}\n",
  "\\end{table}")
writeLines(sde_tex, "tables/tabF1_sde.tex")
cat("SDE table done\n")

cat("\nAll tables generated:", paste(list.files("tables"), collapse=", "), "\n")
