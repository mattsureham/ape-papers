## 05_tables.R — Generate all LaTeX tables
## apep_0759: Simplified to Compete

source("00_packages.R")

data_dir <- "../data"
tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

contracts <- readRDS(file.path(data_dir, "contracts_clean.rds"))
contracts_analysis <- contracts[band %in% c("treated", "below_control")]

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

extract <- function(model, var = "did") {
  beta <- coef(model)[var]
  se_val <- se(model)[var]
  pval <- fixest::pvalue(model)[var]
  list(beta = beta, se = se_val, pval = pval, stars = star(pval), n = model$nobs)
}

## ========================================================================
## TABLE 1: Summary Statistics
## ========================================================================
cat("Generating Table 1...\n")

summ <- contracts_analysis[, .(
  N = .N,
  mean_offers = mean(n_offers_w, na.rm = TRUE),
  sd_offers = sd(n_offers_w, na.rm = TRUE),
  pct_competed = mean(fully_competed, na.rm = TRUE),
  sd_competed = sd(fully_competed, na.rm = TRUE),
  pct_sb = mean(small_business, na.rm = TRUE),
  sd_sb = sd(small_business, na.rm = TRUE),
  pct_sole = mean(not_competed, na.rm = TRUE),
  sd_sole = sd(not_competed, na.rm = TRUE)
), by = .(band, post)]

g <- function(b, p, v) {
  row <- summ[band == b & post == p]
  if (nrow(row) == 0) return("--")
  fmt(row[[v]], ifelse(grepl("pct|sd_comp|sd_sb|sd_sole", v), 3, 2))
}
gn <- function(b, p) {
  row <- summ[band == b & post == p]
  if (nrow(row) == 0) return("--")
  fmtN(row$N)
}

tab1 <- c(
  "\\begin{table}[H]", "\\centering",
  "\\caption{Summary Statistics by Dollar Band and Period}", "\\label{tab:summary}",
  "\\begin{threeparttable}", "\\begin{tabular}{lcccc}", "\\toprule",
  " & \\multicolumn{2}{c}{Control (\\$50K--\\$150K)} & \\multicolumn{2}{c}{Treated (\\$150K--\\$250K)} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Pre & Post & Pre & Post \\\\", "\\midrule",
  sprintf("Offers received & %s & %s & %s & %s \\\\", g("below_control",0,"mean_offers"), g("below_control",1,"mean_offers"), g("treated",0,"mean_offers"), g("treated",1,"mean_offers")),
  sprintf(" & [%s] & [%s] & [%s] & [%s] \\\\", g("below_control",0,"sd_offers"), g("below_control",1,"sd_offers"), g("treated",0,"sd_offers"), g("treated",1,"sd_offers")),
  sprintf("Fully competed & %s & %s & %s & %s \\\\", g("below_control",0,"pct_competed"), g("below_control",1,"pct_competed"), g("treated",0,"pct_competed"), g("treated",1,"pct_competed")),
  sprintf("Small business & %s & %s & %s & %s \\\\", g("below_control",0,"pct_sb"), g("below_control",1,"pct_sb"), g("treated",0,"pct_sb"), g("treated",1,"pct_sb")),
  sprintf("Not competed & %s & %s & %s & %s \\\\", g("below_control",0,"pct_sole"), g("below_control",1,"pct_sole"), g("treated",0,"pct_sole"), g("treated",1,"pct_sole")),
  "\\midrule",
  sprintf("Contracts & %s & %s & %s & %s \\\\", gn("below_control",0), gn("below_control",1), gn("treated",0), gn("treated",1)),
  "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]", "\\small",
  "\\item \\textit{Notes:} Standard deviations in brackets. Pre-period: FY2018--FY2020. Post-period: FY2021--FY2023. Treated band contracts (\\$150K--\\$250K) shifted from full-and-open to Simplified Acquisition Procedures after August 2020. Control band (\\$50K--\\$150K) was already simplified. Offers received winsorized at the 99th percentile.",
  "\\end{tablenotes}", "\\end{threeparttable}", "\\end{table}")
writeLines(tab1, file.path(tab_dir, "tab1_summary.tex"))

## ========================================================================
## TABLE 2: Main DiD Results
## ========================================================================
cat("Generating Table 2...\n")

r_b <- lapply(list(m1_basic, m2_basic, m3_basic, m4_basic), extract)
r_f <- lapply(list(m1_full, m2_full, m3_full, m4_full), extract)

pre_means <- contracts_analysis[post == 0, .(
  offers = mean(n_offers_w, na.rm = TRUE),
  competed = mean(fully_competed, na.rm = TRUE),
  sb = mean(small_business, na.rm = TRUE),
  sole = mean(not_competed, na.rm = TRUE)
)]

tab2 <- c(
  "\\begin{table}[H]", "\\centering",
  "\\caption{Effect of SAT Increase on Contract Outcomes}", "\\label{tab:main}",
  "\\begin{threeparttable}", "\\begin{tabular}{lcccc}", "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Offers & Competed & Small Bus. & Sole Source \\\\", "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel A: Baseline (FY + NAICS FE)}} \\\\",
  sprintf("Treated $\\times$ Post & $%s%s$ & $%s%s$ & $%s%s$ & $%s%s$ \\\\",
    fmt(r_b[[1]]$beta), r_b[[1]]$stars, fmt(r_b[[2]]$beta), r_b[[2]]$stars,
    fmt(r_b[[3]]$beta), r_b[[3]]$stars, fmt(r_b[[4]]$beta), r_b[[4]]$stars),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\",
    fmt(r_b[[1]]$se), fmt(r_b[[2]]$se), fmt(r_b[[3]]$se), fmt(r_b[[4]]$se)),
  sprintf("$N$ & %s & %s & %s & %s \\\\",
    fmtN(r_b[[1]]$n), fmtN(r_b[[2]]$n), fmtN(r_b[[3]]$n), fmtN(r_b[[4]]$n)),
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel B: Full (FY + NAICS + Agency FE)}} \\\\",
  sprintf("Treated $\\times$ Post & $%s%s$ & $%s%s$ & $%s%s$ & $%s%s$ \\\\",
    fmt(r_f[[1]]$beta), r_f[[1]]$stars, fmt(r_f[[2]]$beta), r_f[[2]]$stars,
    fmt(r_f[[3]]$beta), r_f[[3]]$stars, fmt(r_f[[4]]$beta), r_f[[4]]$stars),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\",
    fmt(r_f[[1]]$se), fmt(r_f[[2]]$se), fmt(r_f[[3]]$se), fmt(r_f[[4]]$se)),
  sprintf("$N$ & %s & %s & %s & %s \\\\",
    fmtN(r_f[[1]]$n), fmtN(r_f[[2]]$n), fmtN(r_f[[3]]$n), fmtN(r_f[[4]]$n)),
  sprintf("Pre-treatment mean & %s & %s & %s & %s \\\\",
    fmt(pre_means$offers, 2), fmt(pre_means$competed), fmt(pre_means$sb), fmt(pre_means$sole)),
  "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]", "\\small",
  "\\item \\textit{Notes:} $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$. Each column reports the DiD coefficient. Treated = contracts in the \\$150K--\\$250K band; Post = FY2021+. Control group: \\$50K--\\$150K contracts (already simplified). Standard errors in parentheses, two-way clustered by NAICS sector and fiscal year.",
  "\\end{tablenotes}", "\\end{threeparttable}", "\\end{table}")
writeLines(tab2, file.path(tab_dir, "tab2_main.tex"))

## ========================================================================
## TABLE 3: Robustness
## ========================================================================
cat("Generating Table 3...\n")

r_alt <- lapply(list(alt_offers, alt_competed, alt_sole), extract)
r_sim <- lapply(list(simple_offers, simple_competed, simple_sole), extract)
r_plac <- list(extract(placebo_offers, "placebo_did"), extract(placebo_competed, "placebo_did"))

tab3 <- c(
  "\\begin{table}[H]", "\\centering",
  "\\caption{Robustness Checks}", "\\label{tab:robust}",
  "\\begin{threeparttable}", "\\begin{tabular}{lccc}", "\\toprule",
  " & (1) & (2) & (3) \\\\",
  " & Offers & Competed & Sole Source \\\\", "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel A: Alternative clustering (agency)}} \\\\",
  sprintf("Treated $\\times$ Post & $%s%s$ & $%s%s$ & $%s%s$ \\\\",
    fmt(r_alt[[1]]$beta), r_alt[[1]]$stars, fmt(r_alt[[2]]$beta), r_alt[[2]]$stars,
    fmt(r_alt[[3]]$beta), r_alt[[3]]$stars),
  sprintf(" & (%s) & (%s) & (%s) \\\\", fmt(r_alt[[1]]$se), fmt(r_alt[[2]]$se), fmt(r_alt[[3]]$se)),
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel B: No agency FE}} \\\\",
  sprintf("Treated $\\times$ Post & $%s%s$ & $%s%s$ & $%s%s$ \\\\",
    fmt(r_sim[[1]]$beta), r_sim[[1]]$stars, fmt(r_sim[[2]]$beta), r_sim[[2]]$stars,
    fmt(r_sim[[3]]$beta), r_sim[[3]]$stars),
  sprintf(" & (%s) & (%s) & (%s) \\\\", fmt(r_sim[[1]]$se), fmt(r_sim[[2]]$se), fmt(r_sim[[3]]$se)),
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel C: Placebo (within control band)}} \\\\",
  sprintf("Placebo $\\times$ Post & $%s%s$ & $%s%s$ & \\\\",
    fmt(r_plac[[1]]$beta), r_plac[[1]]$stars, fmt(r_plac[[2]]$beta), r_plac[[2]]$stars),
  sprintf(" & (%s) & (%s) & \\\\", fmt(r_plac[[1]]$se), fmt(r_plac[[2]]$se)),
  "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]", "\\small",
  "\\item \\textit{Notes:} $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$. Panel A clusters standard errors by agency only. Panel B omits agency fixed effects. Panel C tests a placebo threshold at the median of the control band (\\$50K--\\$150K) where no procedural change occurred.",
  "\\end{tablenotes}", "\\end{threeparttable}", "\\end{table}")
writeLines(tab3, file.path(tab_dir, "tab3_robust.tex"))

## ========================================================================
## TABLE 4: Heterogeneity
## ========================================================================
cat("Generating Table 4...\n")

r_def_base <- extract(het_offers, "did")
r_def_int <- extract(het_offers, "did:defense")
r_comp_base <- extract(het_competed, "did")
r_comp_int <- extract(het_competed, "did:defense")

tab4 <- c(
  "\\begin{table}[H]", "\\centering",
  "\\caption{Heterogeneity: Defense vs.\\ Civilian Agencies}", "\\label{tab:het}",
  "\\begin{threeparttable}", "\\begin{tabular}{lcc}", "\\toprule",
  " & (1) & (2) \\\\",
  " & Offers & Competed \\\\", "\\midrule",
  sprintf("Treated $\\times$ Post & $%s%s$ & $%s%s$ \\\\",
    fmt(r_def_base$beta), r_def_base$stars, fmt(r_comp_base$beta), r_comp_base$stars),
  sprintf(" & (%s) & (%s) \\\\", fmt(r_def_base$se), fmt(r_comp_base$se)),
  sprintf("$\\times$ Defense & $%s%s$ & $%s%s$ \\\\",
    fmt(r_def_int$beta), r_def_int$stars, fmt(r_comp_int$beta), r_comp_int$stars),
  sprintf(" & (%s) & (%s) \\\\", fmt(r_def_int$se), fmt(r_comp_int$se)),
  sprintf("$N$ & %s & %s \\\\", fmtN(het_offers$nobs), fmtN(het_competed$nobs)),
  "\\bottomrule", "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]", "\\small",
  "\\item \\textit{Notes:} $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$. Defense agencies include DoD, Army, Navy, Air Force, and DLA. All specifications include fiscal year and NAICS FE; two-way clustered SEs.",
  "\\end{tablenotes}", "\\end{threeparttable}", "\\end{table}")
writeLines(tab4, file.path(tab_dir, "tab4_het.tex"))

## ========================================================================
## TABLE F1: Standardized Effect Sizes
## ========================================================================
cat("Generating Table F1 (SDE)...\n")

pre_sds <- contracts_analysis[post == 0, .(
  sd_offers = sd(n_offers_w, na.rm = TRUE),
  sd_competed = sd(fully_competed, na.rm = TRUE),
  sd_sb = sd(small_business, na.rm = TRUE),
  sd_sole = sd(not_competed, na.rm = TRUE)
)]

outcomes_sde <- list(
  list(name = "Offers received", model = m1_full, sd_y = pre_sds$sd_offers),
  list(name = "Fully competed", model = m2_full, sd_y = pre_sds$sd_competed),
  list(name = "Small business", model = m3_full, sd_y = pre_sds$sd_sb),
  list(name = "Not competed", model = m4_full, sd_y = pre_sds$sd_sole)
)

classify_sde <- function(s) dplyr::case_when(
  s < -0.15  ~ "Large negative",
  s < -0.05  ~ "Moderate negative",
  s < -0.005 ~ "Small negative",
  s <  0.005 ~ "Null",
  s <  0.05  ~ "Small positive",
  s <  0.15  ~ "Moderate positive",
  TRUE       ~ "Large positive"
)

sde_rows <- sapply(outcomes_sde, function(o) {
  beta <- coef(o$model)["did"]; se_val <- se(o$model)["did"]
  sde <- beta / o$sd_y; se_sde <- se_val / o$sd_y
  sprintf("%s & Full & $%s$ & --- & $%s$ & $%s$ & $%s$ & %s \\\\",
    o$name, fmt(beta, 4), fmt(o$sd_y, 3), fmt(sde, 4), fmt(se_sde, 4), classify_sde(sde))
})

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does raising the federal Simplified Acquisition Threshold from \\$150,000 to \\$250,000 affect contract competition, small business participation, and sole-source procurement among federal contracts? ",
  "\\textbf{Policy mechanism:} The SAT determines which federal procurement procedures apply; below the threshold, agencies use Simplified Acquisition Procedures with shorter solicitations and streamlined evaluation, while above it, full-and-open competition with detailed justifications is required. The 2020 increase shifted contracts in the \\$150K--\\$250K band from full-and-open to simplified procedures. ",
  "\\textbf{Outcome definition:} (1) Number of offers received per contract (winsorized at 99th pctl), (2) indicator for full-and-open competition, (3) indicator for small business set-aside, (4) indicator for sole-source (not competed). ",
  "\\textbf{Treatment:} Binary---contracts in the \\$150K--\\$250K band shifted from full-and-open to simplified procedures after August 2020. ",
  "\\textbf{Data:} USAspending.gov FPDS-NG, FY2018--FY2023, individual contract level. ",
  "\\textbf{Method:} Difference-in-differences comparing treated \\$150K--\\$250K band to control \\$50K--\\$150K band, with fiscal year, NAICS, and agency fixed effects; two-way clustered standard errors. ",
  "\\textbf{Sample:} Federal contracts with obligations between \\$50,000 and \\$250,000, with non-missing competition status. ",
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
  "\\begin{tablenotes}[flushleft]", "\\small", sde_notes,
  "\\end{tablenotes}", "\\end{threeparttable}", "\\end{table}")
writeLines(tabF1, file.path(tab_dir, "tabF1_sde.tex"))

cat("\nAll tables generated.\n")
