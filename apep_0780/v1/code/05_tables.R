## 05_tables.R — Generate all LaTeX tables
## apep_0780: Last Orders for Crime?

source("00_packages.R")

data_dir <- "../data"
tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
load(file.path(data_dir, "main_models.rda"))
load(file.path(data_dir, "robustness_models.rda"))

fmt <- function(x, d = 3) formatC(x, format = "f", digits = d, big.mark = ",")
fmtN <- function(x) format(x, big.mark = ",")

star <- function(pval) {
  if (is.na(pval)) return("")
  if (pval < 0.01) return("^{***}")
  if (pval < 0.05) return("^{**}")
  if (pval < 0.10) return("^{*}")
  ""
}

ex <- function(model, var = "did") {
  beta <- coef(model)[var]; se_val <- se(model)[var]
  pval <- fixest::pvalue(model)[var]
  list(beta = beta, se = se_val, pval = pval, stars = star(pval), n = model$nobs)
}

## ========================================================================
## TABLE 1: Summary Statistics
## ========================================================================
cat("Generating Table 1...\n")

summ <- panel[, .(
  N = .N,
  mean_violent = mean(violent_crime),
  sd_violent = sd(violent_crime),
  mean_damage = mean(criminal_damage),
  sd_damage = sd(criminal_damage),
  mean_total = mean(total_crime),
  sd_total = sd(total_crime),
  mean_bike = mean(bike_theft),
  sd_bike = sd(bike_theft)
), by = .(treated, post)]

g <- function(tr, p, v) fmt(summ[treated == tr & post == p][[v]], 0)
gn <- function(tr, p) fmtN(summ[treated == tr & post == p]$N)

tab1 <- c(
  "\\begin{table}[H]", "\\centering",
  "\\caption{Summary Statistics by Treatment Status and Period}", "\\label{tab:summary}",
  "\\begin{threeparttable}", "\\begin{tabular}{lcccc}", "\\toprule",
  " & \\multicolumn{2}{c}{CIA Forces} & \\multicolumn{2}{c}{Non-CIA Forces} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Pre & Post & Pre & Post \\\\", "\\midrule",
  sprintf("Violent crime & %s & %s & %s & %s \\\\", g(1,0,"mean_violent"), g(1,1,"mean_violent"), g(0,0,"mean_violent"), g(0,1,"mean_violent")),
  sprintf(" & [%s] & [%s] & [%s] & [%s] \\\\", g(1,0,"sd_violent"), g(1,1,"sd_violent"), g(0,0,"sd_violent"), g(0,1,"sd_violent")),
  sprintf("Anti-social behaviour & %s & %s & %s & %s \\\\", g(1,0,"mean_damage"), g(1,1,"mean_damage"), g(0,0,"mean_damage"), g(0,1,"mean_damage")),
  sprintf(" & [%s] & [%s] & [%s] & [%s] \\\\", g(1,0,"sd_damage"), g(1,1,"sd_damage"), g(0,0,"sd_damage"), g(0,1,"sd_damage")),
  sprintf("Total crime & %s & %s & %s & %s \\\\", g(1,0,"mean_total"), g(1,1,"mean_total"), g(0,0,"mean_total"), g(0,1,"mean_total")),
  sprintf("Bicycle theft & %s & %s & %s & %s \\\\", g(1,0,"mean_bike"), g(1,1,"mean_bike"), g(0,0,"mean_bike"), g(0,1,"mean_bike")),
  "\\midrule",
  sprintf("Force $\\times$ year obs. & %s & %s & %s & %s \\\\", gn(1,0), gn(1,1), gn(0,0), gn(0,1)),
  "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]", "\\footnotesize",
  "\\item \\textit{Notes:} Standard deviations in brackets. Crime counts are based on June monthly snapshots from the Police API. Pre-period: 2014--2017. Post-period: 2018--2023. CIA forces are those serving areas with Cumulative Impact Assessments that received statutory backing in April 2018.",
  "\\end{tablenotes}", "\\end{threeparttable}", "\\end{table}")
writeLines(tab1, file.path(tab_dir, "tab1_summary.tex"))

## ========================================================================
## TABLE 2: Main Results
## ========================================================================
cat("Generating Table 2...\n")

r <- lapply(list(m1_full, m2, m3, m4), ex)

tab2 <- c(
  "\\begin{table}[H]", "\\centering",
  "\\caption{Effect of CIA Statutory Strengthening on Crime}", "\\label{tab:main}",
  "\\begin{threeparttable}", "\\begin{tabular}{lcccc}", "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Violent & ASB & Public Order & Total \\\\", "\\midrule",
  sprintf("CIA $\\times$ Post & $%s%s$ & $%s%s$ & $%s%s$ & $%s%s$ \\\\",
    fmt(r[[1]]$beta), r[[1]]$stars, fmt(r[[2]]$beta), r[[2]]$stars,
    fmt(r[[3]]$beta), r[[3]]$stars, fmt(r[[4]]$beta), r[[4]]$stars),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\",
    fmt(r[[1]]$se), fmt(r[[2]]$se), fmt(r[[3]]$se), fmt(r[[4]]$se)),
  "Force FE & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("$N$ & %s & %s & %s & %s \\\\", fmtN(r[[1]]$n), fmtN(r[[2]]$n), fmtN(r[[3]]$n), fmtN(r[[4]]$n)),
  "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]", "\\footnotesize",
  "\\item \\textit{Notes:} $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$. Dependent variables are in logs. CIA = 1 for police forces serving areas with Cumulative Impact Assessments. Post = 1 for 2018 onward (after statutory strengthening via Policing and Crime Act 2017). Standard errors clustered by police force.",
  "\\end{tablenotes}", "\\end{threeparttable}", "\\end{table}")
writeLines(tab2, file.path(tab_dir, "tab2_main.tex"))

## ========================================================================
## TABLE 3: Placebos
## ========================================================================
cat("Generating Table 3...\n")

r_bike <- ex(m_bike)
r_vehicle <- ex(m_vehicle)

tab3 <- c(
  "\\begin{table}[H]", "\\centering",
  "\\caption{Placebo Outcomes: Non-Alcohol Crime}", "\\label{tab:placebo}",
  "\\begin{threeparttable}", "\\begin{tabular}{lcc}", "\\toprule",
  " & (1) & (2) \\\\",
  " & Bicycle Theft & Vehicle Crime \\\\", "\\midrule",
  sprintf("CIA $\\times$ Post & $%s%s$ & $%s%s$ \\\\",
    fmt(r_bike$beta), r_bike$stars, fmt(r_vehicle$beta), r_vehicle$stars),
  sprintf(" & (%s) & (%s) \\\\", fmt(r_bike$se), fmt(r_vehicle$se)),
  sprintf("$N$ & %s & %s \\\\", fmtN(r_bike$n), fmtN(r_vehicle$n)),
  "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]", "\\footnotesize",
  "\\item \\textit{Notes:} $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$. Log outcomes. Bicycle theft and vehicle crime should not respond to alcohol licensing restrictions. A null coefficient supports the parallel trends assumption.",
  "\\end{tablenotes}", "\\end{threeparttable}", "\\end{table}")
writeLines(tab3, file.path(tab_dir, "tab3_placebo.tex"))

## ========================================================================
## TABLE 4: Robustness
## ========================================================================
cat("Generating Table 4...\n")

r_lev <- ex(level_violent)
r_lev_a <- ex(level_damage)
r_cov <- ex(covid_violent)
r_plac <- ex(placebo_violent, "placebo_did")

tab4 <- c(
  "\\begin{table}[H]", "\\centering",
  "\\caption{Robustness Checks}", "\\label{tab:robust}",
  "\\begin{threeparttable}", "\\begin{tabular}{lcc}", "\\toprule",
  " & (1) & (2) \\\\",
  " & Violent & ASB \\\\", "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Panel A: Levels (not logs)}} \\\\",
  sprintf("CIA $\\times$ Post & $%s%s$ & $%s%s$ \\\\",
    fmt(r_lev$beta, 0), r_lev$stars, fmt(r_lev_a$beta, 0), r_lev_a$stars),
  sprintf(" & (%s) & (%s) \\\\", fmt(r_lev$se, 0), fmt(r_lev_a$se, 0)),
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Panel B: Excluding 2020--2021}} \\\\",
  sprintf("CIA $\\times$ Post & $%s%s$ & $%s%s$ \\\\",
    fmt(ex(covid_violent)$beta), ex(covid_violent)$stars, fmt(ex(covid_damage)$beta), ex(covid_damage)$stars),
  sprintf(" & (%s) & (%s) \\\\", fmt(ex(covid_violent)$se), fmt(ex(covid_damage)$se)),
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Panel C: Placebo treatment (2016)}} \\\\",
  sprintf("CIA $\\times$ Post$_{2016}$ & $%s%s$ & \\\\",
    fmt(r_plac$beta), r_plac$stars),
  sprintf(" & (%s) & \\\\", fmt(r_plac$se)),
  "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]", "\\footnotesize",
  "\\item \\textit{Notes:} $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$. Panel A uses crime counts in levels. Panel B drops 2020 and 2021 (COVID). Panel C uses a placebo treatment date of 2016 on pre-period data only.",
  "\\end{tablenotes}", "\\end{threeparttable}", "\\end{table}")
writeLines(tab4, file.path(tab_dir, "tab4_robust.tex"))

## ========================================================================
## TABLE F1: SDE
## ========================================================================
cat("Generating Table F1 (SDE)...\n")

pre_sds <- panel[post == 0, .(
  sd_violent = sd(log_violent_crime), sd_damage = sd(log_criminal_damage),
  sd_public = sd(log_public_order), sd_total = sd(log_total_crime)
)]

outcomes_sde <- list(
  list(name = "Log violent crime", model = m1_full, sd_y = pre_sds$sd_violent),
  list(name = "Log criminal damage", model = m2, sd_y = pre_sds$sd_damage),
  list(name = "Log public order", model = m3, sd_y = pre_sds$sd_public),
  list(name = "Log total crime", model = m4, sd_y = pre_sds$sd_total)
)

classify_sde <- function(s) dplyr::case_when(
  s < -0.15 ~ "Large negative", s < -0.05 ~ "Moderate negative",
  s < -0.005 ~ "Small negative", s < 0.005 ~ "Null",
  s < 0.05 ~ "Small positive", s < 0.15 ~ "Moderate positive",
  TRUE ~ "Large positive"
)

sde_rows <- sapply(outcomes_sde, function(o) {
  beta <- coef(o$model)["did"]; se_val <- se(o$model)["did"]
  sde <- beta / o$sd_y; se_sde <- se_val / o$sd_y
  sprintf("%s & Full & $%s$ & --- & $%s$ & $%s$ & $%s$ & %s \\\\",
    o$name, fmt(beta, 4), fmt(o$sd_y, 3), fmt(sde, 4), fmt(se_sde, 4), classify_sde(sde))
})

sde_notes <- paste0(
  "\\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom (England). ",
  "\\textbf{Research question:} Does statutory strengthening of Cumulative Impact Assessments (alcohol licensing restrictions) reduce violent crime, anti-social behaviour, and public order offences? ",
  "\\textbf{Policy mechanism:} CIAs allow licensing authorities to designate zones where new alcohol license applications face a rebuttable presumption of refusal, restricting alcohol outlet density. The Policing and Crime Act 2017 (\\S141) gave existing CIAs statutory backing from April 2018, shifting the burden of proof to applicants. ",
  "\\textbf{Outcome definition:} Log police-recorded crime counts by category (violent crime, ASB, public order, total) at the police force level, from monthly Police API snapshots. ",
  "\\textbf{Treatment:} Binary---police forces serving areas with CIAs versus forces without CIAs, around the April 2018 statutory strengthening. ",
  "\\textbf{Data:} UK Police API (data.police.uk), June monthly crime counts by force area, 2014--2023. ",
  "\\textbf{Method:} Two-way fixed effects DiD with force and year fixed effects; standard errors clustered at the police force level. ",
  "\\textbf{Sample:} 39 English police forces observed annually (June snapshots), 2014--2023. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- c(
  "\\begin{table}[H]", "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}", "\\label{tab:sde}",
  "\\begin{threeparttable}", "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{llcccccl}", "\\toprule",
  "Outcome & Spec. & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule", sde_rows, "\\bottomrule",
  "\\end{tabular}", "\\end{adjustbox}",
  "\\par\\vspace{0.3em}",
  "\\begin{minipage}{\\textwidth}", "\\footnotesize",
  sde_notes,
  "\\end{minipage}",
  "\\end{threeparttable}", "\\end{table}")
writeLines(tabF1, file.path(tab_dir, "tabF1_sde.tex"))

cat("\nAll tables generated.\n")
