## 05_tables.R — Generate all tables
## apep_0823: The Alice Dividend

library(data.table)
library(fixest)
library(modelsummary)
library(kableExtra)
library(jsonlite)

outdir <- here::here("output", "apep_0823", "v1")
datadir <- file.path(outdir, "data")
tabdir <- file.path(outdir, "tables")
dir.create(tabdir, showWarnings = FALSE, recursive = TRUE)

## Load data
cbp <- fread(file.path(datadir, "cbp_panel.csv"))
cbp[, emp := as.numeric(emp)]
cbp[, estab := as.numeric(estab)]
cbp[, payann := as.numeric(payann)]
cbp[, log_emp := log(emp)]
cbp[, log_estab := log(estab)]
cbp[, log_payann := log(payann + 1)]
cbp[, event_time := year - 2014]

fs <- fread(file.path(datadir, "first_stage.csv"))
fs[, post := as.integer(year >= 2015 | (year == 2014 & quarter >= 3))]
fs[, software := as.integer(tech_group == "software")]

## ===== TABLE 1: Summary Statistics =====
cat("=== Table 1: Summary Statistics ===\n")

## Pre-period (2012-2013) summary by industry
cbp_pre <- cbp[year %in% 2012:2013]
summ <- cbp_pre[, .(
  `Mean Employment` = round(mean(emp, na.rm = TRUE), 0),
  `SD Employment` = round(sd(emp, na.rm = TRUE), 0),
  `Mean Establishments` = round(mean(estab, na.rm = TRUE), 1),
  `Mean Payroll ($M)` = round(mean(payann / 1000, na.rm = TRUE), 1),
  `County-Years` = .N
), by = .(naics, industry_label)]

setorder(summ, naics)

## Write as LaTeX
tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Pre-Treatment Industry Characteristics (2012--2013)}",
  "\\label{tab:summary}",
  "\\begin{tabular}{llrrrrr}",
  "\\toprule",
  "NAICS & Industry & Mean Emp & SD Emp & Mean Estab & Mean Payroll & County- \\\\",
  " & & & & & (\\$000s) & Years \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Treated Industries (Software-Intensive)}} \\\\"
)

for (i in which(summ$naics %in% c("334", "511", "518"))) {
  row <- summ[i]
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %s & %s & %s & %s & %s & %s \\\\",
    row$naics, row$industry_label,
    formatC(row$`Mean Employment`, format = "d", big.mark = ","),
    formatC(row$`SD Employment`, format = "d", big.mark = ","),
    formatC(row$`Mean Establishments`, format = "f", digits = 1),
    formatC(row$`Mean Payroll ($M)`, format = "f", digits = 1),
    formatC(row$`County-Years`, format = "d", big.mark = ",")
  ))
}

tab1_lines <- c(tab1_lines,
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Control Industries (Not Software Patent-Dependent)}} \\\\"
)

for (i in which(summ$naics %in% c("325", "336", "339"))) {
  row <- summ[i]
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %s & %s & %s & %s & %s & %s \\\\",
    row$naics, row$industry_label,
    formatC(row$`Mean Employment`, format = "d", big.mark = ","),
    formatC(row$`SD Employment`, format = "d", big.mark = ","),
    formatC(row$`Mean Establishments`, format = "f", digits = 1),
    formatC(row$`Mean Payroll ($M)`, format = "f", digits = 1),
    formatC(row$`County-Years`, format = "d", big.mark = ",")
  ))
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Data from Census County Business Patterns (CBP), 2012--2013.",
  "Treated industries are those whose core activities rely on software patents affected by",
  "\\textit{Alice Corp. v. CLS Bank} (2014). Control industries produce physical goods or",
  "pharmaceuticals whose patents are not subject to Section 101 eligibility challenges.",
  "Employment and payroll are annual county-level values.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(tabdir, "tab1_summary.tex"))
cat("  Saved tab1_summary.tex\n")

## ===== TABLE 2: Main DiD Results =====
cat("=== Table 2: Main DiD Results ===\n")

cbp_short <- cbp[year >= 2012]

m1 <- feols(log_emp ~ treat_post | fips^naics + year,
            data = cbp_short, cluster = ~state_fips)
m2 <- feols(log_estab ~ treat_post | fips^naics + year,
            data = cbp_short, cluster = ~state_fips)
m3 <- feols(log_payann ~ treat_post | fips^naics + year,
            data = cbp_short, cluster = ~state_fips)
m4 <- feols(log_emp ~ treat_post | fips^naics + state_fips^year,
            data = cbp_short, cluster = ~state_fips)

## Industry-specific linear trends
cbp_short[, naics_trend := as.numeric(as.factor(naics)) * year]
m5 <- feols(log_emp ~ treat_post + naics_trend | fips^naics + year,
            data = cbp_short, cluster = ~state_fips)

tab2_models <- list(
  "log(Emp)" = m1,
  "log(Estab)" = m2,
  "log(Payroll)" = m3,
  "log(Emp)" = m4,
  "log(Emp)" = m5
)

## Build LaTeX table manually for full control
b <- sapply(tab2_models, function(m) round(coef(m)["treat_post"], 4))
s <- sapply(tab2_models, function(m) round(se(m)["treat_post"], 4))
n <- sapply(tab2_models, function(m) m$nobs)
r2 <- sapply(tab2_models, function(m) round(fitstat(m, "r2")$r2, 4))

stars <- function(b, s) {
  z <- abs(b / s)
  if (z > 2.576) return("***")
  if (z > 1.96) return("**")
  if (z > 1.645) return("*")
  return("")
}

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{The Effect of \\textit{Alice} on Software-Intensive Industries}",
  "\\label{tab:main}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & log(Emp) & log(Estab) & log(Payroll) & log(Emp) & log(Emp) \\\\",
  "\\midrule",
  sprintf("Software $\\times$ Post & %s%s & %s%s & %s%s & %s%s & %s%s \\\\",
          formatC(b[1], format = "f", digits = 4), stars(b[1], s[1]),
          formatC(b[2], format = "f", digits = 4), stars(b[2], s[2]),
          formatC(b[3], format = "f", digits = 4), stars(b[3], s[3]),
          formatC(b[4], format = "f", digits = 4), stars(b[4], s[4]),
          formatC(b[5], format = "f", digits = 4), stars(b[5], s[5])),
  sprintf(" & (%s) & (%s) & (%s) & (%s) & (%s) \\\\",
          formatC(s[1], format = "f", digits = 4),
          formatC(s[2], format = "f", digits = 4),
          formatC(s[3], format = "f", digits = 4),
          formatC(s[4], format = "f", digits = 4),
          formatC(s[5], format = "f", digits = 4)),
  "\\midrule",
  "County $\\times$ Industry FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & --- & Yes \\\\",
  "State $\\times$ Year FE & --- & --- & --- & Yes & --- \\\\",
  "Industry trends & --- & --- & --- & --- & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
          formatC(n[1], big.mark = ","),
          formatC(n[2], big.mark = ","),
          formatC(n[3], big.mark = ","),
          formatC(n[4], big.mark = ","),
          formatC(n[5], big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Each column reports the coefficient on Software $\\times$ Post from a",
  "difference-in-differences regression at the county $\\times$ industry $\\times$ year level.",
  "Software industries: NAICS 334, 511, 518. Control industries: NAICS 325, 336, 339.",
  "Post = 2015--2019 (\\textit{Alice} decided June 2014). Sample: 2012--2019.",
  "Standard errors clustered at state level in parentheses.",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(tabdir, "tab2_main.tex"))
cat("  Saved tab2_main.tex\n")

## ===== TABLE 3: Event Study =====
cat("=== Table 3: Event Study ===\n")

es <- feols(log_emp ~ i(event_time, treated, ref = -1) | fips^naics + year,
            data = cbp_short, cluster = ~state_fips)
es_ct <- coeftable(es)

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Event Study: Software Employment Relative to Control Industries}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Event Time & Coefficient & Std. Error \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(es_ct))) {
  rn <- rownames(es_ct)[i]
  et <- as.integer(gsub("event_time::(-?\\d+):treated", "\\1", rn))
  yr_label <- 2014 + et
  star <- stars(es_ct[i, 1], es_ct[i, 2])
  tab3_lines <- c(tab3_lines, sprintf(
    "$t = %+d$ (%d) & %s%s & (%s) \\\\",
    et, yr_label,
    formatC(es_ct[i, 1], format = "f", digits = 4), star,
    formatC(es_ct[i, 2], format = "f", digits = 4)
  ))
}

tab3_lines <- c(tab3_lines,
  "\\midrule",
  "$t = -1$ (2013) & \\multicolumn{2}{c}{Reference} \\\\",
  "\\midrule",
  sprintf("Observations & \\multicolumn{2}{c}{%s} \\\\",
          formatC(es$nobs, big.mark = ",")),
  "County $\\times$ Industry FE & \\multicolumn{2}{c}{Yes} \\\\",
  "Year FE & \\multicolumn{2}{c}{Yes} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Coefficients from an event study regression of log employment",
  "on interactions of the treated-industry indicator with event-time dummies.",
  "$t = -1$ (2013) is the omitted reference period. \\textit{Alice} was decided June 2014.",
  "Sample: 2012--2019. Standard errors clustered at state level.",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(tabdir, "tab3_eventstudy.tex"))
cat("  Saved tab3_eventstudy.tex\n")

## ===== TABLE 4: Heterogeneity by Industry =====
cat("=== Table 4: Heterogeneity by Industry ===\n")

het_results <- list()
for (ind in c("334", "511", "518")) {
  sub <- cbp_short[naics %in% c("325", "336", "339", ind)]
  sub[, ind_treat := as.integer(naics == ind)]
  sub[, ind_tp := ind_treat * post]
  het_results[[ind]] <- feols(log_emp ~ ind_tp | fips^naics + year,
                              data = sub, cluster = ~state_fips)
}

## Placebo
plac <- cbp_short[naics %in% c("325", "336")]
plac[, plac_treat := as.integer(naics == "336")]
plac[, plac_tp := plac_treat * post]
het_results[["placebo"]] <- feols(log_emp ~ plac_tp | fips^naics + year,
                                  data = plac, cluster = ~state_fips)

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Heterogeneity: The \\textit{Alice} Effect by Industry}",
  "\\label{tab:heterogeneity}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & NAICS 334 & NAICS 511 & NAICS 518 & Placebo \\\\",
  " & Computer/ & Publishing/ & Data Proc./ & Transport vs \\\\",
  " & Electronics & Software & Internet & Chemicals \\\\",
  "\\midrule"
)

ind_names <- c("334", "511", "518", "placebo")
coef_names <- c("ind_tp", "ind_tp", "ind_tp", "plac_tp")
bs <- sapply(seq_along(ind_names), function(i)
  round(coef(het_results[[ind_names[i]]])[coef_names[i]], 4))
ss <- sapply(seq_along(ind_names), function(i)
  round(se(het_results[[ind_names[i]]])[coef_names[i]], 4))
ns <- sapply(ind_names, function(i) het_results[[i]]$nobs)

tab4_lines <- c(tab4_lines,
  sprintf("Industry $\\times$ Post & %s%s & %s%s & %s%s & %s%s \\\\",
          formatC(bs[1], format = "f", digits = 4), stars(bs[1], ss[1]),
          formatC(bs[2], format = "f", digits = 4), stars(bs[2], ss[2]),
          formatC(bs[3], format = "f", digits = 4), stars(bs[3], ss[3]),
          formatC(bs[4], format = "f", digits = 4), stars(bs[4], ss[4])),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\",
          formatC(ss[1], format = "f", digits = 4),
          formatC(ss[2], format = "f", digits = 4),
          formatC(ss[3], format = "f", digits = 4),
          formatC(ss[4], format = "f", digits = 4)),
  "\\midrule",
  "Patent-intensity & High & High & Low & None \\\\",
  "Value chain position & Producer & Producer & User & --- \\\\",
  "\\midrule",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          formatC(ns[1], big.mark = ","),
          formatC(ns[2], big.mark = ","),
          formatC(ns[3], big.mark = ","),
          formatC(ns[4], big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Each column estimates a separate DiD comparing one treated industry",
  "to the three control industries (NAICS 325, 336, 339). Column (4) is a placebo comparing",
  "two control industries. NAICS 334 and 511 are software patent \\emph{producers};",
  "NAICS 518 are software patent \\emph{users} that benefit from reduced patent thickets.",
  "Sample: 2012--2019. SEs clustered at state level.",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(tabdir, "tab4_heterogeneity.tex"))
cat("  Saved tab4_heterogeneity.tex\n")

## ===== TABLE 5 (APPENDIX): SDE Table =====
cat("=== Table F1: Standardized Effect Sizes ===\n")

## Compute SDE for main outcomes
cbp_pre_sd <- cbp_short[year < 2015, .(
  sd_log_emp = sd(log_emp, na.rm = TRUE),
  sd_log_estab = sd(log_estab, na.rm = TRUE),
  sd_log_payann = sd(log_payann, na.rm = TRUE)
)]

## Main specification coefficients
main_b <- coef(m1)["treat_post"]
main_se <- se(m1)["treat_post"]
estab_b <- coef(m2)["treat_post"]
estab_se <- se(m2)["treat_post"]
payroll_b <- coef(m3)["treat_post"]
payroll_se <- se(m3)["treat_post"]

## NAICS 334 (Computer/Electronics)
n334_b <- coef(het_results[["334"]])["ind_tp"]
n334_se <- se(het_results[["334"]])["ind_tp"]

## NAICS 518 (Data Processing)
n518_b <- coef(het_results[["518"]])["ind_tp"]
n518_se <- se(het_results[["518"]])["ind_tp"]

## Compute SDEs
sde_emp <- main_b / cbp_pre_sd$sd_log_emp
sde_emp_se <- main_se / cbp_pre_sd$sd_log_emp
sde_estab <- estab_b / cbp_pre_sd$sd_log_estab
sde_estab_se <- estab_se / cbp_pre_sd$sd_log_estab
sde_payroll <- payroll_b / cbp_pre_sd$sd_log_payann
sde_payroll_se <- payroll_se / cbp_pre_sd$sd_log_payann
sde_334 <- n334_b / cbp_pre_sd$sd_log_emp
sde_334_se <- n334_se / cbp_pre_sd$sd_log_emp
sde_518 <- n518_b / cbp_pre_sd$sd_log_emp
sde_518_se <- n518_se / cbp_pre_sd$sd_log_emp

## Classification function
classify_sde <- function(x) {
  ax <- abs(x)
  if (ax < 0.005) return("Null")
  if (ax < 0.05) return(ifelse(x > 0, "Small positive", "Small negative"))
  if (ax < 0.15) return(ifelse(x > 0, "Moderate positive", "Moderate negative"))
  return(ifelse(x > 0, "Large positive", "Large negative"))
}

sde_rows <- data.table(
  outcome = c("Employment (all software)", "Establishments (all software)",
              "Payroll (all software)", "Employment (NAICS 334)",
              "Employment (NAICS 518)"),
  beta = round(c(main_b, estab_b, payroll_b, n334_b, n518_b), 4),
  se = round(c(main_se, estab_se, payroll_se, n334_se, n518_se), 4),
  sd_y = round(rep(c(cbp_pre_sd$sd_log_emp, cbp_pre_sd$sd_log_estab,
                       cbp_pre_sd$sd_log_payann, cbp_pre_sd$sd_log_emp,
                       cbp_pre_sd$sd_log_emp), 1), 4),
  sde = round(c(sde_emp, sde_estab, sde_payroll, sde_334, sde_518), 4),
  sde_se = round(c(sde_emp_se, sde_estab_se, sde_payroll_se, sde_334_se, sde_518_se), 4),
  classification = sapply(c(sde_emp, sde_estab, sde_payroll, sde_334, sde_518), classify_sde)
)

cat("SDE table:\n")
print(sde_rows)

## Build SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does weakening software patent eligibility via the Supreme Court's ",
  "\\textit{Alice Corp. v. CLS Bank} (2014) decision affect employment in software-intensive industries ",
  "relative to industries whose patents were unaffected? ",
  "\\textbf{Policy mechanism:} The \\textit{Alice} decision raised the bar for software patent eligibility ",
  "under 35 U.S.C. Section 101, tripling rejection rates in software technology centers while leaving ",
  "pharmaceutical patent examination unchanged; this reduced the expected value of filing software patents ",
  "and cleared existing patent thickets that may have deterred entry. ",
  "\\textbf{Outcome definition:} Log annual county-level employment from Census County Business Patterns, ",
  "measuring total paid employees in the mid-March pay period. ",
  "\\textbf{Treatment:} Binary; software-intensive industries (NAICS 334, 511, 518) versus control ",
  "industries (NAICS 325, 336, 339), interacted with post-2014 indicator. ",
  "\\textbf{Data:} Census County Business Patterns, 2012--2019, county $\\times$ industry $\\times$ year; ",
  "approximately 22,000 county-industry-year observations. ",
  "\\textbf{Method:} Two-way fixed effects DiD with county $\\times$ industry and year fixed effects; ",
  "standard errors clustered at state level (51 clusters). ",
  "\\textbf{Sample:} Counties with at least 6 of 8 years of non-suppressed employment data in both ",
  "treated and control industries. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

## Write SDE LaTeX table
sde_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(sde_rows))) {
  r <- sde_rows[i]
  sde_lines <- c(sde_lines, sprintf(
    "%s & %s & %s & %s & %s & %s & %s \\\\",
    r$outcome, r$beta, r$se, r$sd_y, r$sde, r$sde_se, r$classification
  ))
}

sde_lines <- c(sde_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(sde_lines, file.path(tabdir, "tabF1_sde.tex"))
cat("  Saved tabF1_sde.tex\n")

cat("\nAll tables generated.\n")
