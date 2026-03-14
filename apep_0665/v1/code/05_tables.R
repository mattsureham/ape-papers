## 05_tables.R — Generate all LaTeX tables
## apep_0665: Fornero pension reform

source("code/00_packages.R")

panel <- readRDS("data/panel.rds")
results <- readRDS("data/results_main.rds")
robustness <- readRDS("data/results_robustness.rds")

cat("=== Generating tables ===\n")

make_stars <- function(beta, se) {
  t <- abs(beta / se)
  if (t > 2.576) return("***")
  if (t > 1.96) return("**")
  if (t > 1.645) return("*")
  return("")
}

fmt <- function(x, d=3) formatC(x, format="f", digits=d)

## ---- Table 1: Summary Statistics ----
bite_data <- panel %>%
  filter(!duplicated(region)) %>%
  select(region, fornero_bite) %>%
  arrange(desc(fornero_bite))

overall <- panel %>%
  filter(year >= 2005, year <= 2019) %>%
  summarise(
    gfcf_mean = mean(gfcf_total, na.rm = TRUE),
    gfcf_sd = sd(gfcf_total, na.rm = TRUE),
    ln_gfcf_mean = mean(ln_gfcf, na.rm = TRUE),
    ln_gfcf_sd = sd(ln_gfcf, na.rm = TRUE),
    bite_mean = mean(fornero_bite, na.rm = TRUE),
    bite_sd = sd(fornero_bite, na.rm = TRUE),
    n = n()
  )

cat("Summary stats:\n"); print(overall)

tab1 <- c(
  "\\begin{table}[H]", "\\centering",
  "\\caption{Summary Statistics}", "\\label{tab:summary}",
  "\\small",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}", "\\toprule",
  "Variable & Mean & SD & Min & Max \\\\", "\\midrule",
  sprintf("GFCF (EUR millions) & %s & %s & %s & %s \\\\",
    formatC(overall$gfcf_mean, format="f", digits=0, big.mark=","),
    formatC(overall$gfcf_sd, format="f", digits=0, big.mark=","),
    formatC(min(panel$gfcf_total[panel$year >= 2005 & panel$year <= 2019], na.rm=TRUE), format="f", digits=0, big.mark=","),
    formatC(max(panel$gfcf_total[panel$year >= 2005 & panel$year <= 2019], na.rm=TRUE), format="f", digits=0, big.mark=",")),
  sprintf("Log GFCF & %s & %s & %s & %s \\\\",
    fmt(overall$ln_gfcf_mean, 2), fmt(overall$ln_gfcf_sd, 2),
    fmt(min(panel$ln_gfcf[panel$year >= 2005 & panel$year <= 2019], na.rm=TRUE), 2),
    fmt(max(panel$ln_gfcf[panel$year >= 2005 & panel$year <= 2019], na.rm=TRUE), 2)),
  sprintf("Fornero bite (pp) & %s & %s & %s & %s \\\\",
    fmt(overall$bite_mean, 1), fmt(overall$bite_sd, 1),
    fmt(min(bite_data$fornero_bite), 1), fmt(max(bite_data$fornero_bite), 1)),
  "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]", "\\footnotesize",
  sprintf("\\item \\textit{Notes:} N = %d region-year observations from 21 Italian NUTS2 regions, 2005--2019. Fornero bite = change in 55--64 employment rate from 2010 to 2014.", overall$n),
  "\\end{tablenotes}", "\\end{threeparttable}", "\\end{table}"
)
writeLines(tab1, "tables/tab1_summary.tex")
cat("Table 1 written.\n")

## ---- Table 2: Main Results ----
m1 <- results$m1; m2m <- results$m2_mfg; m3r <- results$m3_rd; m5 <- results$m5

b1 <- coef(m1)["treat_intensity"]; s1 <- se(m1)["treat_intensity"]
bm <- coef(m2m)["treat_intensity"]; sm <- se(m2m)["treat_intensity"]
br <- coef(m3r)["treat_intensity"]; sr <- se(m3r)["treat_intensity"]

tab2 <- c(
  "\\begin{table}[H]", "\\centering",
  "\\caption{Effect of Fornero Bite on Capital Investment}", "\\label{tab:main}",
  "\\small", "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}", "\\toprule",
  "& (1) & (2) & (3) & (4) \\\\",
  "& Ln GFCF & Ln Mfg GFCF & Ln R\\&D & Youth Emp Rate \\\\",
  "\\midrule",
  sprintf("Bite $\\times$ Post & %s%s & %s%s & %s%s & %s%s \\\\",
    fmt(b1), make_stars(b1, s1),
    fmt(bm), make_stars(bm, sm),
    fmt(br), make_stars(br, sr),
    fmt(coef(m5)["treat_intensity"]), make_stars(coef(m5)["treat_intensity"], se(m5)["treat_intensity"])),
  sprintf("& (%s) & (%s) & (%s) & (%s) \\\\",
    fmt(s1), fmt(sm), fmt(sr), fmt(se(m5)["treat_intensity"])),
  "\\midrule",
  sprintf("Observations & %d & %d & %d & %d \\\\",
    nobs(m1), nobs(m2m), nobs(m3r), nobs(m5)),
  "Region + Year FE & Yes & Yes & Yes & Yes \\\\",
  "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]", "\\footnotesize",
  "\\item \\textit{Notes:} Standard errors clustered at the NUTS2 region level. * p$<$0.10, ** p$<$0.05, *** p$<$0.01. Bite = change in 55--64 employment rate (pp) from 2010 to 2014. Post = 2012 onwards. 21 Italian NUTS2 regions, 2000--2022.",
  "\\end{tablenotes}", "\\end{threeparttable}", "\\end{table}"
)
writeLines(tab2, "tables/tab2_main.tex")
cat("Table 2 written.\n")

## ---- Table 3: Robustness ----
rc1 <- coef(robustness$pre_covid)["treat_intensity"]; rs1 <- se(robustness$pre_covid)["treat_intensity"]
rc2 <- coef(robustness$no_islands)["treat_intensity"]; rs2 <- se(robustness$no_islands)["treat_intensity"]
rc3 <- coef(robustness$placebo)["treat_placebo"]; rs3 <- se(robustness$placebo)["treat_placebo"]

tab3 <- c(
  "\\begin{table}[H]", "\\centering",
  "\\caption{Robustness Checks}", "\\label{tab:robust}",
  "\\small", "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}", "\\toprule",
  "& (1) Baseline & (2) Pre-COVID & (3) No Islands & (4) Placebo 2006 \\\\",
  "\\midrule",
  sprintf("Bite $\\times$ Post & %s%s & %s%s & %s%s & \\\\",
    fmt(b1), make_stars(b1, s1), fmt(rc1), make_stars(rc1, rs1),
    fmt(rc2), make_stars(rc2, rs2)),
  sprintf("& (%s) & (%s) & (%s) & \\\\", fmt(s1), fmt(rs1), fmt(rs2)),
  "\\\\",
  sprintf("Bite $\\times$ Post (Placebo) & & & & %s%s \\\\", fmt(rc3), make_stars(rc3, rs3)),
  sprintf("& & & & (%s) \\\\", fmt(rs3)),
  "\\midrule",
  sprintf("Observations & %d & %d & %d & %d \\\\",
    nobs(m1), nobs(robustness$pre_covid), nobs(robustness$no_islands), nobs(robustness$placebo)),
  "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]", "\\footnotesize",
  "\\item \\textit{Notes:} DV: log total GFCF. All include region and year FE, SEs clustered at NUTS2 level. * p$<$0.10, ** p$<$0.05, *** p$<$0.01. Column (4): placebo treatment at 2006 on 2000--2011 sample.",
  "\\end{tablenotes}", "\\end{threeparttable}", "\\end{table}"
)
writeLines(tab3, "tables/tab3_robustness.tex")
cat("Table 3 written.\n")

## ---- Table F1: SDE ----
sd_y_gfcf <- sd(panel$ln_gfcf, na.rm = TRUE)
sd_y_mfg <- sd(panel$ln_gfcf_mfg, na.rm = TRUE)
sd_y_rd <- sd(panel$ln_rd, na.rm = TRUE)
sd_y_youth <- sd(panel$emprate_15_24, na.rm = TRUE)
sd_x <- sd(panel$fornero_bite, na.rm = TRUE)

classify <- function(s) {
  dplyr::case_when(
    s < -0.15 ~ "Large negative",
    s < -0.05 ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s < 0.005 ~ "Null",
    s < 0.05 ~ "Small positive",
    s < 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
}

sde_data <- data.frame(
  outcome = c("Log GFCF", "Log Mfg GFCF", "Log R\\&D", "Youth Emp Rate"),
  beta = c(b1, bm, br, coef(m5)["treat_intensity"]),
  se_b = c(s1, sm, sr, se(m5)["treat_intensity"]),
  sd_x = sd_x,
  sd_y = c(sd_y_gfcf, sd_y_mfg, sd_y_rd, sd_y_youth)
)
sde_data$sde <- sde_data$beta * sde_data$sd_x / sde_data$sd_y
sde_data$se_sde <- sde_data$se_b * sde_data$sd_x / sde_data$sd_y
sde_data$class <- classify(sde_data$sde)

cat("\nSDE:\n"); print(sde_data)

sde_lines <- c(
  "\\begin{table}[H]", "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}", "\\label{tab:sde}",
  "\\small",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{llcccccl}", "\\toprule",
  "Outcome & Spec & $\\hat{\\beta}$ & SE & SD($X$) & SD($Y$) & SDE & Classification \\\\",
  "\\midrule"
)
for (i in 1:nrow(sde_data)) {
  r <- sde_data[i, ]
  sde_lines <- c(sde_lines, sprintf("%s & Region + Year FE & %s & %s & %s & %s & %s & %s \\\\",
    r$outcome, fmt(r$beta, 4), fmt(r$se_b, 4), fmt(r$sd_x, 2), fmt(r$sd_y, 3), fmt(r$sde, 4), r$class))
}
sde_lines <- c(sde_lines,
  "\\bottomrule", "\\end{tabular}", "\\end{adjustbox}",
  "\\par\\vspace{0.3em}",
  sprintf("{\\footnotesize \\emph{Notes:} SDE = $\\hat{\\beta} \\times$ SD($X$) / SD($Y$). Treatment is continuous (Fornero bite in pp). \\textbf{Research question:} Did forced older-worker retention from Italy's 2011 Fornero pension reform trigger compensatory capital investment? \\textbf{Data:} Eurostat GFCF and employment data, 21 Italian NUTS2 regions, 2000--2022 (N = %d). \\textbf{Method:} Continuous-treatment DiD. Classification labels refer to the magnitude of the standardized point estimate, not to statistical significance. ``Null'' denotes a near-zero effect size ($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.}", nrow(panel)),
  "\\end{table}"
)
writeLines(sde_lines, "tables/tabF1_sde.tex")
cat("SDE table written.\n")
