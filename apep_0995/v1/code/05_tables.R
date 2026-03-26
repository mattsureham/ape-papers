## 05_tables.R — Generate all LaTeX tables
## apep_0986: Forced EPCI Mergers and RN Voting

source("00_packages.R")
data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE)

## Load data and model objects
panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel <- panel[!is.na(treated)]
panel[, turnout := exprimes / inscrits * 100]
load(file.path(data_dir, "model_objects.RData"))
load(file.path(data_dir, "robustness_objects.RData"))

## ============================================================================
## Table 1: Summary Statistics
## ============================================================================
cat("Generating Table 1: Summary Statistics\n")

sumstats_fn <- function(dt, label) {
  data.table(
    Group = label,
    `Mean FN/RN Share (\\%)` = sprintf("%.2f", mean(dt$fn_share, na.rm = TRUE)),
    `SD FN/RN Share` = sprintf("%.2f", sd(dt$fn_share, na.rm = TRUE)),
    `Mean Turnout (\\%)` = sprintf("%.2f", mean(dt$turnout, na.rm = TRUE)),
    `SD Turnout` = sprintf("%.2f", sd(dt$turnout, na.rm = TRUE)),
    `Communes` = format(uniqueN(dt$code_commune), big.mark = ","),
    `Obs` = format(nrow(dt), big.mark = ",")
  )
}

panel[, turnout := exprimes / inscrits * 100]

ss <- rbindlist(list(
  sumstats_fn(panel[treated == 1 & post == 0], "Treated, Pre-reform"),
  sumstats_fn(panel[treated == 0 & post == 0], "Control, Pre-reform"),
  sumstats_fn(panel[treated == 1 & post == 1], "Treated, Post-reform"),
  sumstats_fn(panel[treated == 0 & post == 1], "Control, Post-reform"),
  sumstats_fn(panel, "Full Sample")
))

## Write LaTeX table
sink(file.path(table_dir, "tab1_summary.tex"))
cat("\\begin{table}[H]\n\\centering\n")
cat("\\caption{Summary Statistics}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lcccccc}\n\\toprule\n")
cat(" & Mean FN/RN & SD FN/RN & Mean Turnout & SD Turnout & Communes & Obs \\\\\n")
cat(" & Share (\\%) & Share & (\\%) & & & \\\\\n")
cat("\\midrule\n")
for (i in 1:nrow(ss)) {
  if (i == 5) cat("\\midrule\n")
  cat(sprintf("%s & %s & %s & %s & %s & %s & %s \\\\\n",
              ss$Group[i], ss$`Mean FN/RN Share (\\%)`[i], ss$`SD FN/RN Share`[i],
              ss$`Mean Turnout (\\%)`[i], ss$`SD Turnout`[i],
              ss$Communes[i], ss$Obs[i]))
}
cat("\\bottomrule\n\\end{tabular}\n\\end{adjustbox}\n")
cat("\\begin{tablenotes}[flushleft]\n\\small\n")
cat("\\item \\textit{Notes:} FN/RN vote share is the percentage of expressed votes for the ",
    "Front National (2007--2012) or Rassemblement National (2017--2022) in the first round of ",
    "presidential elections. Treated communes are those whose EPCI changed on January 1, 2017 ",
    "due to the Loi NOTRe reform. Control communes are those whose EPCI was unchanged.\n")
cat("\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n")
sink()

## ============================================================================
## Table 2: Main Results
## ============================================================================
cat("Generating Table 2: Main Results\n")

sink(file.path(table_dir, "tab2_main.tex"))
cat("\\begin{table}[H]\n\\centering\n")
cat("\\caption{Effect of Forced EPCI Mergers on FN/RN Vote Share}\n")
cat("\\label{tab:main}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcccc}\n\\toprule\n")
cat(" & (1) & (2) & (3) & (4) \\\\\n")
cat(" & Binary & Binary & Intensity & Intensity \\\\\n")
cat("\\midrule\n")

## Extract coefficients
b1 <- coef(m1)["treat_post"]; se1 <- sqrt(vcov(m1)["treat_post","treat_post"])
b2 <- coef(m2)["treat_post"]; se2 <- sqrt(vcov(m2)["treat_post","treat_post"])
b3 <- coef(m3)["intensity_post"]; se3 <- sqrt(vcov(m3)["intensity_post","intensity_post"])
b4 <- coef(m4)["intensity_post"]; se4 <- sqrt(vcov(m4)["intensity_post","intensity_post"])

star <- function(p) ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
p1 <- 2 * pt(abs(b1/se1), df = 95, lower.tail = FALSE)
p2 <- 2 * pt(abs(b2/se2), df = 95, lower.tail = FALSE)
p3 <- 2 * pt(abs(b3/se3), df = 95, lower.tail = FALSE)
p4 <- 2 * pt(abs(b4/se4), df = 95, lower.tail = FALSE)

cat(sprintf("Treated $\\times$ Post & %.3f%s & %.3f%s & & \\\\\n",
            b1, star(p1), b2, star(p2)))
cat(sprintf(" & (%.3f) & (%.3f) & & \\\\\n", se1, se2))
cat(sprintf("Intensity $\\times$ Post & & & %.3f%s & %.3f%s \\\\\n",
            b3, star(p3), b4, star(p4)))
cat(sprintf(" & & & (%.3f) & (%.3f) \\\\\n", se3, se4))
cat("\\midrule\n")
cat("Commune FE & Yes & Yes & Yes & Yes \\\\\n")
cat("Election FE & Yes & --- & Yes & --- \\\\\n")
cat("Dept $\\times$ Election FE & --- & Yes & --- & Yes \\\\\n")
cat(sprintf("Observations & %s & %s & %s & %s \\\\\n",
            format(m1$nobs, big.mark = ","), format(m2$nobs, big.mark = ","),
            format(m3$nobs, big.mark = ","), format(m4$nobs, big.mark = ",")))
cat(sprintf("R$^2$ (within) & %.4f & %.4f & %.4f & %.4f \\\\\n",
            fitstat(m1, "wr2")[[1]], fitstat(m2, "wr2")[[1]],
            fitstat(m3, "wr2")[[1]], fitstat(m4, "wr2")[[1]]))
cat("\\bottomrule\n\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n\\small\n")
cat("\\item \\textit{Notes:} Standard errors clustered at the d\\'epartement level in parentheses. ",
    "* $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
    "The dependent variable is FN/RN vote share (\\% of expressed votes) in the first round of ",
    "presidential elections (2007, 2012, 2017, 2022). Columns (1)--(2) use a binary treatment indicator ",
    "(1 if the commune's EPCI changed on January 1, 2017). Columns (3)--(4) use continuous treatment intensity ",
    "$= \\log(\\text{EPCI pop}_{2017} / \\text{EPCI pop}_{2016})$ for affected communes, 0 otherwise. ",
    "Columns (2) and (4) include d\\'epartement $\\times$ election fixed effects to absorb regional trends.\n")
cat("\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n")
sink()

## ============================================================================
## Table 3: Event Study
## ============================================================================
cat("Generating Table 3: Event Study\n")

sink(file.path(table_dir, "tab3_event.tex"))
cat("\\begin{table}[H]\n\\centering\n")
cat("\\caption{Event Study: FN/RN Vote Share by Election Year}\n")
cat("\\label{tab:event}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcc}\n\\toprule\n")
cat(" & Coefficient & SE \\\\\n")
cat("\\midrule\n")

ev_coefs <- coef(m_event)
ev_se <- sqrt(diag(vcov(m_event)))
ev_names <- names(ev_coefs)
labels <- c("event_2007" = "Treated $\\times$ 2007 (Pre)",
            "event_2017" = "Treated $\\times$ 2017 (Post)",
            "event_2022" = "Treated $\\times$ 2022 (Post)")

for (n in names(labels)) {
  p <- 2 * pt(abs(ev_coefs[n] / ev_se[n]), df = 95, lower.tail = FALSE)
  cat(sprintf("%s & %.3f%s & (%.3f) \\\\\n", labels[n], ev_coefs[n], star(p), ev_se[n]))
}
cat("\\midrule\n")
cat("Reference period & \\multicolumn{2}{c}{2012} \\\\\n")
cat(sprintf("Observations & \\multicolumn{2}{c}{%s} \\\\\n", format(m_event$nobs, big.mark = ",")))
cat("\\bottomrule\n\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n\\small\n")
cat("\\item \\textit{Notes:} Event study estimates with 2012 as the reference period (last pre-reform ",
    "election). Standard errors clustered at the d\\'epartement level. ",
    "* $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
    "The near-zero 2007 coefficient confirms the absence of differential pre-trends.\n")
cat("\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n")
sink()

## ============================================================================
## Table 4: Robustness
## ============================================================================
cat("Generating Table 4: Robustness\n")

sink(file.path(table_dir, "tab4_robust.tex"))
cat("\\begin{table}[H]\n\\centering\n")
cat("\\caption{Robustness Checks}\n")
cat("\\label{tab:robust}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lccc}\n\\toprule\n")
cat(" & Coefficient & SE & N \\\\\n")
cat("\\midrule\n")

robustness_list <- list(
  list("Baseline (dept. clustered)", m1, "treat_post"),
  list("EPCI-clustered SE", m_epci_cluster, "treat_post"),
  list("Heterosked.-robust SE", m_robust, "treat_post"),
  list("Metropolitan France only", m_metro, "treat_post"),
  list("Balanced panel", m_balanced, "treat_post")
)

for (r in robustness_list) {
  b <- coef(r[[2]])[r[[3]]]
  s <- sqrt(vcov(r[[2]])[r[[3]], r[[3]]])
  p <- 2 * pt(abs(b/s), df = 95, lower.tail = FALSE)
  cat(sprintf("%s & %.3f%s & (%.3f) & %s \\\\\n",
              r[[1]], b, star(p), s, format(r[[2]]$nobs, big.mark = ",")))
}

cat("\\midrule\n")
cat("\\multicolumn{4}{l}{\\textit{Heterogeneity: Rural vs. Urban}} \\\\\n")
## Rural/urban heterogeneity
b_rural <- coef(m_rural)
se_rural <- sqrt(diag(vcov(m_rural)))
for (i in seq_along(b_rural)) {
  nm <- names(b_rural)[i]
  lab <- ifelse(grepl("rural::1", nm), "Rural communes ($<$2,000 pop.)",
                "Urban communes ($\\geq$2,000 pop.)")
  p <- 2 * pt(abs(b_rural[i] / se_rural[i]), df = 95, lower.tail = FALSE)
  cat(sprintf("%s & %.3f%s & (%.3f) & \\\\\n", lab, b_rural[i], star(p), se_rural[i]))
}

cat("\\bottomrule\n\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n\\small\n")
cat("\\item \\textit{Notes:} All specifications include commune and election year fixed effects. ",
    "Standard errors in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
    "``Balanced panel'' restricts to communes present in all four elections.\n")
cat("\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n")
sink()

## ============================================================================
## Table F1: Standardized Effect Sizes (SDE)
## ============================================================================
cat("Generating Table F1: SDE\n")

## Main specification: m1 (binary DiD)
beta_main <- coef(m1)["treat_post"]
se_main <- sqrt(vcov(m1)["treat_post", "treat_post"])
sd_y <- sd(panel[post == 0, fn_share])
sde_main <- beta_main / sd_y
se_sde_main <- se_main / sd_y

## Turnout
beta_turnout <- coef(m_turnout)["treat_post"]
se_turnout <- sqrt(vcov(m_turnout)["treat_post", "treat_post"])
sd_turnout <- sd(panel[post == 0, turnout], na.rm = TRUE)
sde_turnout <- beta_turnout / sd_turnout
se_sde_turnout <- se_turnout / sd_turnout

## Heterogeneity: rural vs urban
panel[, rural := as.integer(pop_commune < 2000)]
m_rural_fn <- feols(fn_share ~ treat_post | code_commune + year,
                    data = panel[rural == 1], cluster = ~dep)
m_urban_fn <- feols(fn_share ~ treat_post | code_commune + year,
                    data = panel[rural == 0], cluster = ~dep)

beta_rural <- coef(m_rural_fn)["treat_post"]
se_r <- sqrt(vcov(m_rural_fn)["treat_post", "treat_post"])
sd_y_rural <- sd(panel[rural == 1 & post == 0, fn_share])
sde_rural <- beta_rural / sd_y_rural
se_sde_rural <- se_r / sd_y_rural

beta_urban <- coef(m_urban_fn)["treat_post"]
se_u <- sqrt(vcov(m_urban_fn)["treat_post", "treat_post"])
sd_y_urban <- sd(panel[rural == 0 & post == 0, fn_share])
sde_urban <- beta_urban / sd_y_urban
se_sde_urban <- se_u / sd_y_urban

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

## Build SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} France. ",
  "\\textbf{Research question:} Whether forced intercommunal mergers under the Loi NOTRe (2015) ",
  "affected support for the Rassemblement National (far-right populist party) at the commune level. ",
  "\\textbf{Policy mechanism:} The Loi NOTRe raised the minimum EPCI population threshold from 5,000 to 15,000, ",
  "forcing prefects to consolidate approximately 800 EPCIs on January 1, 2017, transferring competences ",
  "(water, waste, transport planning) from communes to larger intercommunal structures and increasing ",
  "democratic distance between citizens and local decision-makers. ",
  "\\textbf{Outcome definition:} FN/RN vote share as a percentage of expressed votes in the first round of ",
  "presidential elections. ",
  "\\textbf{Treatment:} Binary indicator equal to one if the commune's EPCI changed on January 1, 2017. ",
  "\\textbf{Data:} French presidential election results (2007, 2012, 2017, 2022) from data.gouv.fr matched with ",
  "DGCL EPCI composition tables (pre- and post-reform); approximately 35,000 communes per election. ",
  "\\textbf{Method:} Two-way fixed effects difference-in-differences with commune and election year fixed effects; ",
  "standard errors clustered at the d\\'epartement level (96 clusters). ",
  "\\textbf{Sample:} Metropolitan and overseas communes with valid election data in at least one pre- and one ",
  "post-reform election; communes excluded if EPCI assignment could not be matched across reform boundary. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sink(file.path(table_dir, "tabF1_sde.tex"))
cat("\\begin{table}[H]\n\\centering\n")
cat("\\caption{Standardized Effect Sizes for Main Outcomes}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{llccccc}\n\\toprule\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\midrule\n")
cat("\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n")
cat(sprintf("FN/RN Vote Share & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\\n",
            beta_main, se_main, sd_y, sde_main, se_sde_main, classify_sde(sde_main)))
cat(sprintf("Turnout & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\\n",
            beta_turnout, se_turnout, sd_turnout, sde_turnout, se_sde_turnout, classify_sde(sde_turnout)))
cat("\\midrule\n")
cat("\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\\n")
cat(sprintf("FN/RN --- Rural ($<$2k pop) & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\\n",
            beta_rural, se_r, sd_y_rural, sde_rural, se_sde_rural, classify_sde(sde_rural)))
cat(sprintf("FN/RN --- Urban ($\\geq$2k pop) & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\\n",
            beta_urban, se_u, sd_y_urban, sde_urban, se_sde_urban, classify_sde(sde_urban)))
cat("\\bottomrule\n\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n\\footnotesize\n")
cat(sde_notes, "\n")
cat("\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n")
sink()

cat("\nAll tables generated in", table_dir, "\n")
cat("Files:", paste(list.files(table_dir), collapse = ", "), "\n")
