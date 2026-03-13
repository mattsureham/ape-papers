## 05_tables.R — Generate all LaTeX tables
## APEP paper apep_0627: Wales 20mph Speed Limit

source("00_packages.R")

data_dir   <- "../data/"
tables_dir <- "../tables/"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(data_dir, "la_month_panel.csv"))
load(file.path(data_dir, "main_results.RData"))
load(file.path(data_dir, "robustness_results.RData"))

## ==================================================================
## TABLE 1: Summary Statistics
## ==================================================================
cat("Generating Table 1: Summary Statistics\n")

# Compute stats by country and period
make_stats <- function(dt, label) {
  data.frame(
    Group = label,
    `LA-Months` = nrow(dt),
    `Mean Collisions` = round(mean(dt$n_collisions), 1),
    `SD Collisions` = round(sd(dt$n_collisions), 1),
    `Mean KSI` = round(mean(dt$n_ksi), 2),
    `SD KSI` = round(sd(dt$n_ksi), 2),
    `Mean Ped. KSI` = round(mean(dt$n_ped_ksi), 2),
    `SD Ped. KSI` = round(sd(dt$n_ped_ksi), 2),
    check.names = FALSE
  )
}

panel_dt <- as.data.table(panel)
stats_rows <- rbind(
  make_stats(panel_dt[welsh == 1 & post == 0], "Wales, Pre"),
  make_stats(panel_dt[welsh == 1 & post == 1], "Wales, Post"),
  make_stats(panel_dt[welsh == 0 & post == 0], "England, Pre"),
  make_stats(panel_dt[welsh == 0 & post == 1], "England, Post")
)

# Write LaTeX
tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: Monthly Collision Counts by Local Authority}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lrrrrrrr}",
  "\\toprule",
  " & LA-Months & \\multicolumn{2}{c}{Total Collisions} & \\multicolumn{2}{c}{KSI} & \\multicolumn{2}{c}{Pedestrian KSI} \\\\",
  "\\cmidrule(lr){3-4} \\cmidrule(lr){5-6} \\cmidrule(lr){7-8}",
  " & & Mean & SD & Mean & SD & Mean & SD \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(stats_rows))) {
  r <- stats_rows[i, ]
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %s & %s & %s & %s & %s & %s & %s \\\\",
    r[["Group"]], format(r[["LA-Months"]], big.mark = ","),
    r[["Mean Collisions"]], r[["SD Collisions"]],
    r[["Mean KSI"]], r[["SD KSI"]],
    r[["Mean Ped. KSI"]], r[["SD Ped. KSI"]]
  ))
  if (i == 2) tab1_lines <- c(tab1_lines, "\\midrule")
}

n_welsh <- uniqueN(panel_dt[welsh == 1]$la_code)
n_eng <- uniqueN(panel_dt[welsh == 0]$la_code)
n_total <- nrow(panel_dt)

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item \\textit{Notes:} N = %s local authority--month observations (%d Welsh LAs, %d English LAs). Data from STATS19 collision records for Great Britain (England and Wales only). COVID period (March 2020--June 2021) excluded. KSI = killed or seriously injured. Pre-period: January 2018--August 2023. Post-period: September 2023 onward. Treatment: Wales's default 20mph speed limit effective September 17, 2023.",
          format(n_total, big.mark = ","), n_welsh, n_eng),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(tables_dir, "tab1_summary.tex"))

## ==================================================================
## TABLE 2: Main DiD Results
## ==================================================================
cat("Generating Table 2: Main DiD Results\n")

# Extract info from models
get_model_info <- function(mod, dep_mean) {
  b <- coef(mod)["welsh:post"]
  se_val <- sqrt(vcov(mod)["welsh:post", "welsh:post"])
  p <- pvalue(mod)["welsh:post"]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))
  pct <- 100 * b / dep_mean
  list(beta = b, se = se_val, p = p, stars = stars, pct = pct)
}

welsh_means <- panel_dt[welsh == 1 & post == 0, .(
  collisions = mean(n_collisions),
  ksi = mean(n_ksi),
  ped_ksi = mean(n_ped_ksi),
  restricted = mean(n_restricted),
  highspeed = mean(n_highspeed)
)]

r1 <- get_model_info(m1_total, welsh_means$collisions)
r2 <- get_model_info(m1_ksi, welsh_means$ksi)
r3 <- get_model_info(m1_ped, welsh_means$ped_ksi)
r4 <- get_model_info(m1_restricted, welsh_means$restricted)
r5 <- get_model_info(m1_highspeed, welsh_means$highspeed)

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Main Results: Effect of Wales's 20mph Default on Road Casualties}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & All & KSI & Pedestrian & Restricted & High-Speed \\\\",
  " & Collisions & & KSI & Roads & Roads \\\\",
  "\\midrule",
  sprintf("Welsh $\\times$ Post & %s%s & %s%s & %s%s & %s%s & %s%s \\\\",
          format(round(r1$beta, 3), nsmall = 3), r1$stars,
          format(round(r2$beta, 3), nsmall = 3), r2$stars,
          format(round(r3$beta, 3), nsmall = 3), r3$stars,
          format(round(r4$beta, 3), nsmall = 3), r4$stars,
          format(round(r5$beta, 3), nsmall = 3), r5$stars),
  sprintf(" & (%s) & (%s) & (%s) & (%s) & (%s) \\\\",
          format(round(r1$se, 3), nsmall = 3),
          format(round(r2$se, 3), nsmall = 3),
          format(round(r3$se, 3), nsmall = 3),
          format(round(r4$se, 3), nsmall = 3),
          format(round(r5$se, 3), nsmall = 3)),
  sprintf(" & [%s\\%%] & [%s\\%%] & [%s\\%%] & [%s\\%%] & [%s\\%%] \\\\",
          format(round(r1$pct, 1), nsmall = 1),
          format(round(r2$pct, 1), nsmall = 1),
          format(round(r3$pct, 1), nsmall = 1),
          format(round(r4$pct, 1), nsmall = 1),
          format(round(r5$pct, 1), nsmall = 1)),
  "\\midrule",
  sprintf("Welsh pre-treatment mean & %s & %s & %s & %s & %s \\\\",
          format(round(welsh_means$collisions, 1), nsmall = 1),
          format(round(welsh_means$ksi, 2), nsmall = 2),
          format(round(welsh_means$ped_ksi, 2), nsmall = 2),
          format(round(welsh_means$restricted, 1), nsmall = 1),
          format(round(welsh_means$highspeed, 1), nsmall = 1)),
  sprintf("N & %s & %s & %s & %s & %s \\\\",
          format(nobs(m1_total), big.mark = ","),
          format(nobs(m1_ksi), big.mark = ","),
          format(nobs(m1_ped), big.mark = ","),
          format(nobs(m1_restricted), big.mark = ","),
          format(nobs(m1_highspeed), big.mark = ",")),
  "LA FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year-Month FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item \\textit{Notes:} Each column reports a separate DiD regression of the monthly collision count on Welsh $\\times$ Post, with local authority and year-month fixed effects. Standard errors clustered at the local authority level in parentheses. Percentage effects relative to the Welsh pre-treatment mean in brackets. Column (5) is a placebo: high-speed roads ($\\geq$40mph) were unaffected by the 20mph default. KSI = killed or seriously injured. %s. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
    sprintf("N = %s LA-months", format(nobs(m1_total), big.mark = ","))),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(tables_dir, "tab2_main.tex"))

## ==================================================================
## TABLE 3: Event Study Coefficients (KSI)
## ==================================================================
cat("Generating Table 3: Event Study\n")

es_coefs <- as.data.frame(summary(es_ksi)$coeftable)
es_coefs$term <- rownames(es_coefs)
# Extract relative month from term name
es_coefs$rel_month <- as.integer(gsub(".*::(-?\\d+):.*", "\\1", es_coefs$term))
es_coefs <- es_coefs[order(es_coefs$rel_month), ]

# Select key months for the table
key_months <- c(-12, -9, -6, -3, -1, 0, 1, 2, 3, 6, 9, 12)
es_tab <- es_coefs[es_coefs$rel_month %in% key_months, ]

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Event Study: Monthly KSI Effects Relative to Treatment}",
  "\\label{tab:eventstudy}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Months Relative to & Coefficient & Std. Error & $p$-value \\\\",
  "September 2023 & & & \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(es_tab))) {
  rm <- es_tab$rel_month[i]
  est <- es_tab$Estimate[i]
  se_val <- es_tab$`Std. Error`[i]
  pv <- es_tab$`Pr(>|t|)`[i]
  stars <- ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.10, "*", "")))
  label <- ifelse(rm == -1, "$t = -1$ (ref.)", paste0("$t = ", ifelse(rm >= 0, "+", ""), rm, "$"))

  if (rm == -1) {
    tab3_lines <- c(tab3_lines, sprintf("%s & --- & --- & --- \\\\", label))
  } else {
    tab3_lines <- c(tab3_lines, sprintf(
      "%s & %s%s & (%s) & %s \\\\",
      label,
      format(round(est, 3), nsmall = 3), stars,
      format(round(se_val, 3), nsmall = 3),
      format(round(pv, 3), nsmall = 3)
    ))
  }

  if (rm == -1) {
    tab3_lines <- c(tab3_lines, "\\midrule")
  }
}

tab3_lines <- c(tab3_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item \\textit{Notes:} Event study coefficients from a regression of monthly KSI count on interactions of Welsh LA indicator with relative month dummies. $t = -1$ (August 2023) is the reference period. LA and year-month fixed effects included. Standard errors clustered at the LA level. N = %s. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
    format(nobs(es_ksi), big.mark = ",")),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(tables_dir, "tab3_eventstudy.tex"))

## ==================================================================
## TABLE 4: Robustness
## ==================================================================
cat("Generating Table 4: Robustness\n")

get_rob_row <- function(mod, label) {
  b <- coef(mod)[1]
  se_val <- sqrt(vcov(mod)[1, 1])
  p <- pvalue(mod)[1]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))
  n <- nobs(mod)
  sprintf("%s & %s%s & (%s) & %s \\\\",
          label,
          format(round(b, 3), nsmall = 3), stars,
          format(round(se_val, 3), nsmall = 3),
          format(n, big.mark = ","))
}

tab4_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness Checks: KSI Outcomes}",
  "\\label{tab:robustness}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Specification & Welsh $\\times$ Post & SE & N \\\\",
  "\\midrule",
  "\\textit{Panel A: Alternative samples} & & & \\\\",
  get_rob_row(m1_ksi, "\\quad Baseline (all LAs)"),
  get_rob_row(rob_border_ksi, "\\quad Border LAs only"),
  get_rob_row(rob_nolondon_ksi, "\\quad Excluding London"),
  "\\midrule",
  "\\textit{Panel B: Alternative specifications} & & & \\\\",
  get_rob_row(rob_log_ksi, "\\quad Log(KSI + 1)"),
  sprintf("\\quad Poisson (IRR) & %s%s & (%s) & %s \\\\",
          format(round(exp(coef(rob_pois_ksi)[1]), 3), nsmall = 3),
          ifelse(pvalue(rob_pois_ksi)[1] < 0.01, "***",
                 ifelse(pvalue(rob_pois_ksi)[1] < 0.05, "**",
                        ifelse(pvalue(rob_pois_ksi)[1] < 0.10, "*", ""))),
          format(round(sqrt(vcov(rob_pois_ksi)[1,1]), 3), nsmall = 3),
          format(nobs(rob_pois_ksi), big.mark = ",")),
  "\\midrule",
  "\\textit{Panel C: Placebo and falsification} & & & \\\\",
  get_rob_row(rob_placebo_ksi, "\\quad Pseudo-treatment Sep 2022"),
  get_rob_row(m1_highspeed, "\\quad High-speed roads ($\\geq$40mph)"),
  "\\midrule",
  "\\textit{Panel D: Severity decomposition} & & & \\\\",
  get_rob_row(rob_fatal, "\\quad Fatal only"),
  get_rob_row(rob_serious, "\\quad Serious only"),
  get_rob_row(rob_slight, "\\quad Slight only"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each row reports the coefficient on Welsh $\\times$ Post from a separate DiD regression with LA and year-month fixed effects. Standard errors clustered at the LA level. The Poisson row reports the incidence rate ratio (IRR); an IRR below 1 indicates a reduction. The pseudo-treatment test assigns September 2022 as a placebo treatment date using only pre-treatment data. High-speed roads ($\\geq$40mph) were unaffected by the policy and serve as a falsification test. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(tables_dir, "tab4_robustness.tex"))

## ==================================================================
## TABLE F1: Standardized Effect Sizes (SDE)
## ==================================================================
cat("Generating Table F1: SDE\n")

# Compute SDE for main outcomes (binary treatment)
sd_collisions <- sd(panel$n_collisions)
sd_ksi <- sd(panel$n_ksi)
sd_ped_ksi <- sd(panel$n_ped_ksi)

classify_sde <- function(s) {
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

sde_rows <- data.frame(
  Outcome = c("Total collisions", "KSI (killed/seriously injured)", "Pedestrian KSI"),
  beta = c(coef(m1_total)["welsh:post"],
           coef(m1_ksi)["welsh:post"],
           coef(m1_ped)["welsh:post"]),
  se = c(sqrt(vcov(m1_total)["welsh:post","welsh:post"]),
         sqrt(vcov(m1_ksi)["welsh:post","welsh:post"]),
         sqrt(vcov(m1_ped)["welsh:post","welsh:post"])),
  sd_y = c(sd_collisions, sd_ksi, sd_ped_ksi)
)

sde_rows$sde <- sde_rows$beta / sde_rows$sd_y
sde_rows$se_sde <- sde_rows$se / sde_rows$sd_y
sde_rows$classification <- classify_sde(sde_rows$sde)

tabF1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{llccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(sde_rows))) {
  r <- sde_rows[i, ]
  tabF1_lines <- c(tabF1_lines, sprintf(
    "%s & %s & %s & %s & %s & %s & %s \\\\",
    r$Outcome,
    format(round(r$beta, 3), nsmall = 3),
    format(round(r$se, 3), nsmall = 3),
    format(round(r$sd_y, 2), nsmall = 2),
    format(round(r$sde, 4), nsmall = 4),
    format(round(r$se_sde, 4), nsmall = 4),
    r$classification
  ))
}

n_obs_total <- nobs(m1_total)

tabF1_lines <- c(tabF1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\par\\vspace{0.3em}",
  sprintf("{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE = $\\hat{\\beta}$ / SD($Y$)) for a binary (0/1) treatment to facilitate cross-study comparison. \\textbf{Research question:} Does Wales's nationwide reduction of the default urban speed limit from 30mph to 20mph reduce road casualties? \\textbf{Treatment:} Binary; Welsh local authorities after September 17, 2023. \\textbf{Data:} STATS19 collision records, 2018--2024, LA--month level. N = %s. \\textbf{Method:} Two-way fixed effects DiD (LA + year-month FE), standard errors clustered at LA level. Classification labels refer to the magnitude of the standardized point estimate, not to statistical significance. ``Null'' denotes a near-zero effect size ($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.}",
          format(n_obs_total, big.mark = ",")),
  "\\end{table}"
)

writeLines(tabF1_lines, file.path(tables_dir, "tabF1_sde.tex"))

cat("\nAll tables generated successfully.\n")
cat("Files:", paste(list.files(tables_dir), collapse = ", "), "\n")
