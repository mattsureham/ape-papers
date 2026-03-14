## 05_tables.R — Generate tables
## apep_0666: EU smoking bans

source("code/00_packages.R")
panel <- readRDS("data/panel.rds")
results <- readRDS("data/results_main.rds")
robustness <- readRDS("data/results_robustness.rds")

cat("=== Generating tables ===\n")

fmt <- function(x, d=3) formatC(x, format="f", digits=d)
make_stars <- function(b, s) {
  t <- abs(b/s)
  if(t>2.576) "***" else if(t>1.96) "**" else if(t>1.645) "*" else ""
}

## ---- Table 1: Summary ----
hosp <- panel %>% filter(sector == "G-I")
tab1 <- c(
  "\\begin{table}[H]", "\\centering",
  "\\caption{Summary Statistics: Hospitality Sector Employment}", "\\label{tab:summary}",
  "\\small", "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}", "\\toprule",
  "& Mean & SD & Min & Max \\\\", "\\midrule",
  sprintf("Employment (thsd) & %s & %s & %s & %s \\\\",
    formatC(mean(hosp$employment, na.rm=T), format="f", digits=0, big.mark=","),
    formatC(sd(hosp$employment, na.rm=T), format="f", digits=0, big.mark=","),
    formatC(min(hosp$employment, na.rm=T), format="f", digits=0, big.mark=","),
    formatC(max(hosp$employment, na.rm=T), format="f", digits=0, big.mark=",")),
  sprintf("Log Employment & %s & %s & %s & %s \\\\",
    fmt(mean(hosp$ln_emp, na.rm=T), 2), fmt(sd(hosp$ln_emp, na.rm=T), 2),
    fmt(min(hosp$ln_emp, na.rm=T), 2), fmt(max(hosp$ln_emp, na.rm=T), 2)),
  sprintf("Emp Share (of total) & %s & %s & %s & %s \\\\",
    fmt(mean(hosp$emp_share, na.rm=T), 3), fmt(sd(hosp$emp_share, na.rm=T), 3),
    fmt(min(hosp$emp_share, na.rm=T), 3), fmt(max(hosp$emp_share, na.rm=T), 3)),
  "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]", "\\footnotesize",
  sprintf("\\item \\textit{Notes:} N = %d country-year observations. 29 European countries, 1995--2023. Hospitality = NACE G--I (trade, transport, accommodation, food services).", nrow(hosp)),
  "\\end{tablenotes}", "\\end{threeparttable}", "\\end{table}"
)
writeLines(tab1, "tables/tab1_summary.tex")

## ---- Table 2: Main Results ----
m1 <- results$m1
b1 <- coef(m1)["treat_post"]; s1 <- se(m1)["treat_post"]
# CS-DiD overall
cs_att <- results$cs_overall$overall.att
cs_se <- results$cs_overall$overall.se
# Share
ms <- results$m_share
bs <- coef(ms)["treat_post"]; ss <- se(ms)["treat_post"]
# Hours
mh <- results$m_hours
bh <- coef(mh)["treat_post"]; sh <- se(mh)["treat_post"]

tab2 <- c(
  "\\begin{table}[H]", "\\centering",
  "\\caption{Effect of Smoking Bans on Hospitality Employment}", "\\label{tab:main}",
  "\\small", "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}", "\\toprule",
  "& (1) TWFE & (2) CS-DiD & (3) Emp Share & (4) Hours/Worker \\\\",
  "\\midrule",
  sprintf("Smoking Ban & %s%s & %s%s & %s%s & %s%s \\\\",
    fmt(b1), make_stars(b1,s1), fmt(cs_att), make_stars(cs_att,cs_se),
    fmt(bs), make_stars(bs,ss), fmt(bh), make_stars(bh,sh)),
  sprintf("& (%s) & (%s) & (%s) & (%s) \\\\",
    fmt(s1), fmt(cs_se), fmt(ss), fmt(sh)),
  "\\midrule",
  sprintf("Observations & %d & %d & %d & %d \\\\",
    nobs(m1), nrow(panel %>% filter(sector=="G-I")), nobs(ms), nobs(mh)),
  "Estimator & TWFE & CS-DiD & TWFE & TWFE \\\\",
  "Country + Year FE & Yes & Yes & Yes & Yes \\\\",
  "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]", "\\footnotesize",
  "\\item \\textit{Notes:} SEs clustered at country level (TWFE) or from CS-DiD analytical formulas. * p$<$0.10, ** p$<$0.05, *** p$<$0.01. Sample: 29 European countries, 18 treated (ban 2004--2019), 11 never-treated. DV: log hospitality employment (cols 1--2), hospitality share of total employment (col 3), log hours per worker (col 4).",
  "\\end{tablenotes}", "\\end{threeparttable}", "\\end{table}"
)
writeLines(tab2, "tables/tab2_main.tex")

## ---- Table 3: Robustness ----
rpc <- robustness$pre_covid; bpc <- coef(rpc)["treat_post"]; spc <- se(rpc)["treat_post"]
rne <- robustness$no_early; bne <- coef(rne)["treat_post"]; sne <- se(rne)["treat_post"]
rtot <- robustness$total; btot <- coef(rtot)["treat_post"]; stot <- se(rtot)["treat_post"]

tab3 <- c(
  "\\begin{table}[H]", "\\centering",
  "\\caption{Robustness Checks}", "\\label{tab:robust}",
  "\\small", "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}", "\\toprule",
  "& (1) Baseline & (2) Pre-COVID & (3) No IE/NO & (4) Total Emp \\\\",
  "\\midrule",
  sprintf("Smoking Ban & %s%s & %s%s & %s%s & %s%s \\\\",
    fmt(b1), make_stars(b1,s1), fmt(bpc), make_stars(bpc,spc),
    fmt(bne), make_stars(bne,sne), fmt(btot), make_stars(btot,stot)),
  sprintf("& (%s) & (%s) & (%s) & (%s) \\\\",
    fmt(s1), fmt(spc), fmt(sne), fmt(stot)),
  "\\midrule",
  sprintf("Observations & %d & %d & %d & %d \\\\",
    nobs(m1), nobs(rpc), nobs(rne), nobs(rtot)),
  "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]", "\\footnotesize",
  "\\item \\textit{Notes:} All TWFE with country + year FE, clustered at country level. * p$<$0.10, ** p$<$0.05, *** p$<$0.01. Col (4): total employment across all NACE sectors (placebo outcome).",
  "\\end{tablenotes}", "\\end{threeparttable}", "\\end{table}"
)
writeLines(tab3, "tables/tab3_robustness.tex")

## ---- Table F1: SDE ----
sd_y <- sd(hosp$ln_emp, na.rm=TRUE)
sde_main <- b1 / sd_y
se_sde <- s1 / sd_y
classify <- function(s) case_when(
  s < -0.15 ~ "Large negative", s < -0.05 ~ "Moderate negative",
  s < -0.005 ~ "Small negative", s < 0.005 ~ "Null",
  s < 0.05 ~ "Small positive", s < 0.15 ~ "Moderate positive",
  TRUE ~ "Large positive"
)

sde_cs <- cs_att / sd_y
se_sde_cs <- cs_se / sd_y

sde_lines <- c(
  "\\begin{table}[H]", "\\centering",
  "\\caption{Standardized Effect Sizes}", "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{llcccccl}", "\\toprule",
  "Outcome & Estimator & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  sprintf("Log Hosp Emp & TWFE & %s & %s & %s & %s & %s & %s \\\\",
    fmt(b1,4), fmt(s1,4), fmt(sd_y,3), fmt(sde_main,4), fmt(se_sde,4), classify(sde_main)),
  sprintf("Log Hosp Emp & CS-DiD & %s & %s & %s & %s & %s & %s \\\\",
    fmt(cs_att,4), fmt(cs_se,4), fmt(sd_y,3), fmt(sde_cs,4), fmt(se_sde_cs,4), classify(sde_cs)),
  "\\bottomrule", "\\end{tabular}",
  "\\par\\vspace{0.3em}",
  sprintf("{\\footnotesize \\emph{Notes:} SDE = $\\hat{\\beta}$ / SD($Y$). Treatment is binary (smoking ban adopted). \\textbf{Research question:} Did comprehensive workplace smoking bans reduce hospitality sector employment? \\textbf{Data:} Eurostat national accounts employment, 29 European countries, 1995--2023 (N = %d). \\textbf{Method:} TWFE DiD and Callaway--Sant'Anna staggered DiD. Classification labels refer to the magnitude of the standardized point estimate, not to statistical significance. ``Null'' denotes a near-zero effect size ($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.}", nrow(hosp)),
  "\\end{table}"
)
writeLines(sde_lines, "tables/tabF1_sde.tex")

cat("All tables written.\n")
