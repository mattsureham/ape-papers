## 05_tables.R — Generate all tables including SDE appendix
## Denmark Parallel Society Designation and Displacement (apep_0940)

library(data.table)
library(fixest)
library(kableExtra)

cat("=== Generating tables for apep_0940 ===\n")

panel <- fread("data/panel.csv")
panel[, mun_code_num := as.integer(mun_code)]

# Load saved models
m1 <- readRDS("data/m1_nw_share.rds")
m2 <- readRDS("data/m2_log_nw.rds")
m3 <- readRDS("data/m3_emp.rds")
m4 <- readRDS("data/m4_log_total.rds")
m5 <- readRDS("data/m5_intensity_nw.rds")
m6 <- readRDS("data/m6_intensity_log_nw.rds")
m_placebo <- readRDS("data/m_placebo.rds")
m_urban <- readRDS("data/m_urban.rds")
rob <- readRDS("data/robustness_results.rds")

# -------------------------------------------------------------------
# TABLE 1: Summary Statistics
# -------------------------------------------------------------------
cat("\nGenerating Table 1: Summary Statistics...\n")

pre <- panel[year <= 2018]
post <- panel[year >= 2019]

sumstat <- function(dt, varname) {
  x <- dt[[varname]]
  x <- x[!is.na(x)]
  c(mean = mean(x), sd = sd(x), min = min(x), max = max(x), n = length(x))
}

vars_list <- c("total", "nw_total", "nw_share", "emp_nw_imm", "emp_total", "danish")
var_labels <- c("Total Population", "Non-Western Pop.", "Non-Western Share",
                "NW Imm. Employment Rate", "Total Employment Rate", "Danish-Origin Pop.")

# Build summary table
rows <- list()
for (i in seq_along(vars_list)) {
  v <- vars_list[i]
  s_treat <- sumstat(pre[treated == 1], v)
  s_ctrl <- sumstat(pre[treated == 0], v)
  rows[[i]] <- data.table(
    Variable = var_labels[i],
    Treated_Mean = sprintf("%.3f", s_treat["mean"]),
    Treated_SD = sprintf("(%.3f)", s_treat["sd"]),
    Control_Mean = sprintf("%.3f", s_ctrl["mean"]),
    Control_SD = sprintf("(%.3f)", s_ctrl["sd"])
  )
}
sumstats_dt <- rbindlist(rows)

# Write LaTeX table 1
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Pre-Treatment Municipality Characteristics (2008--2018)}",
  "\\label{tab:sumstats}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{Designated} & \\multicolumn{2}{c}{Non-Designated} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Mean & SD & Mean & SD \\\\",
  "\\hline"
)

for (i in 1:nrow(sumstats_dt)) {
  r <- sumstats_dt[i]
  tab1_lines <- c(tab1_lines, sprintf("%s & %s & %s & %s & %s \\\\",
                                       r$Variable, r$Treated_Mean, r$Treated_SD,
                                       r$Control_Mean, r$Control_SD))
}

n_treat <- uniqueN(panel$mun_code[panel$treated == 1])
n_ctrl <- uniqueN(panel$mun_code[panel$treated == 0])

tab1_lines <- c(tab1_lines,
  "\\hline",
  sprintf("Municipalities & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\", n_treat, n_ctrl),
  sprintf("Municipality-years & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\",
          nrow(pre[treated == 1]), nrow(pre[treated == 0])),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Pre-treatment period: 2008--2018. ``Designated'' municipalities contain at least one public housing estate on the 2018 ghetto/parallel society list. Non-Western share is the fraction of residents who are immigrants or descendants from non-Western countries. Employment rate is from DST StatBank RAS200 for ages 16--64.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "tables/tab1_sumstats.tex")
cat("  Table 1 saved.\n")

# -------------------------------------------------------------------
# TABLE 2: Main DiD Results
# -------------------------------------------------------------------
cat("\nGenerating Table 2: Main DiD Results...\n")

extract_row <- function(model, varname, label) {
  ct <- summary(model)$coeftable
  coef_val <- ct[varname, "Estimate"]
  se_val <- ct[varname, "Std. Error"]
  pval <- ct[varname, "Pr(>|t|)"]
  stars <- ifelse(pval < 0.01, "***", ifelse(pval < 0.05, "**", ifelse(pval < 0.1, "*", "")))
  n <- nobs(model)
  list(label = label, coef = coef_val, se = se_val, stars = stars, n = n, pval = pval)
}

r1 <- extract_row(m1, "treat_post", "NW Share")
r2 <- extract_row(m2, "treat_post", "Log NW Pop.")
r3 <- extract_row(m3, "treat_post", "NW Emp. Rate")
r4 <- extract_row(m4, "treat_post", "Log Total Pop.")

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of Parallel Society Designation on Municipality Outcomes}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) \\\\",
  " & NW Share & Log NW Pop. & NW Emp. Rate & Log Total Pop. \\\\",
  "\\hline",
  sprintf("Designated $\\times$ Post & %s%s & %s%s & %s%s & %s%s \\\\",
          sprintf("%.4f", r1$coef), r1$stars,
          sprintf("%.4f", r2$coef), r2$stars,
          sprintf("%.4f", r3$coef), r3$stars,
          sprintf("%.4f", r4$coef), r4$stars),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\",
          sprintf("%.4f", r1$se), sprintf("%.4f", r2$se),
          sprintf("%.4f", r3$se), sprintf("%.4f", r4$se)),
  "\\hline",
  "Municipality FE & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          format(r1$n, big.mark = ","), format(r2$n, big.mark = ","),
          format(r3$n, big.mark = ","), format(r4$n, big.mark = ",")),
  sprintf("Municipalities & %d & %d & %d & %d \\\\",
          n_treat + n_ctrl, n_treat + n_ctrl,
          uniqueN(panel$mun_code[!is.na(panel$emp_nw_imm)]),
          n_treat + n_ctrl),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each column reports a separate two-way fixed effects regression of the outcome on the interaction of designation status with a post-2018 indicator. Standard errors clustered at the municipality level in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$. ``Designated'' equals one for municipalities containing at least one estate on the 2018 parallel society list. ``Post'' equals one for years 2019 and later. NW Share is the non-Western immigrant and descendant share of total population. NW Emp.~Rate is the employment rate of non-Western immigrants aged 16--64.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, "tables/tab2_main.tex")
cat("  Table 2 saved.\n")

# -------------------------------------------------------------------
# TABLE 3: Treatment Intensity and Robustness
# -------------------------------------------------------------------
cat("\nGenerating Table 3: Treatment Intensity and Robustness...\n")

r5 <- extract_row(m5, "intensity_post", "Intensity: NW Share")
r6 <- extract_row(m6, "intensity_post", "Intensity: Log NW")
r_plac <- extract_row(m_placebo, "treat_post", "Placebo: Danish Share")
r_urb <- extract_row(m_urban, "treat_post", "Urban Only: NW Share")

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Treatment Intensity and Robustness}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) \\\\",
  " & NW Share & Log NW Pop. & Danish Share & NW Share \\\\",
  " & Intensity & Intensity & Placebo & Urban \\\\",
  "\\hline",
  sprintf("Estates $\\times$ Post & %s%s & %s%s & & \\\\",
          sprintf("%.5f", r5$coef), r5$stars,
          sprintf("%.5f", r6$coef), r6$stars),
  sprintf(" & (%s) & (%s) & & \\\\",
          sprintf("%.5f", r5$se), sprintf("%.5f", r6$se)),
  sprintf("Designated $\\times$ Post & & & %s%s & %s%s \\\\",
          sprintf("%.4f", r_plac$coef), r_plac$stars,
          sprintf("%.4f", r_urb$coef), r_urb$stars),
  sprintf(" & & & (%s) & (%s) \\\\",
          sprintf("%.4f", r_plac$se), sprintf("%.4f", r_urb$se)),
  "\\hline",
  "Municipality FE & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          format(r5$n, big.mark = ","), format(r6$n, big.mark = ","),
          format(r_plac$n, big.mark = ","), format(r_urb$n, big.mark = ",")),
  sprintf("RI $p$-value & & & & \\\\"),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item \\textit{Notes:} Columns (1)--(2) use treatment intensity (number of designated estates per municipality) interacted with the post-2018 indicator. Column (3) is a placebo test using Danish-origin population share as the outcome. Column (4) restricts to urban municipalities (population $>$ 20,000 in 2018). Standard errors clustered at the municipality level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$. Randomization inference $p$-value for the main NW share specification: %.3f (500 permutations).", rob$ri_pval),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "tables/tab3_robust.tex")
cat("  Table 3 saved.\n")

# -------------------------------------------------------------------
# TABLE 4: Event Study Coefficients
# -------------------------------------------------------------------
cat("\nGenerating Table 4: Event Study...\n")

es1 <- readRDS("data/es1_nw_share.rds")
es_ct <- summary(es1)$coeftable
es_names <- rownames(es_ct)

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study: Non-Western Population Share}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  "Event Time & Coefficient & Std. Error \\\\",
  "\\hline"
)

for (nm in es_names) {
  coef_val <- es_ct[nm, "Estimate"]
  se_val <- es_ct[nm, "Std. Error"]
  pval <- es_ct[nm, "Pr(>|t|)"]
  stars <- ifelse(pval < 0.01, "***", ifelse(pval < 0.05, "**", ifelse(pval < 0.1, "*", "")))
  # Extract event time from name
  et <- gsub("event_time::|:treated", "", nm)
  tab4_lines <- c(tab4_lines,
    sprintf("$t %s$ & %s%s & (%s) \\\\",
            ifelse(as.numeric(et) >= 0, paste0("+ ", et), paste0("- ", abs(as.numeric(et)))),
            sprintf("%.4f", coef_val), stars, sprintf("%.4f", se_val)))
}

tab4_lines <- c(tab4_lines,
  "\\hline",
  sprintf("Observations & \\multicolumn{2}{c}{%s} \\\\", format(nobs(es1), big.mark = ",")),
  "Reference period & \\multicolumn{2}{c}{$t - 1$ (2018)} \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Event study coefficients from a regression of non-Western population share on leads and lags of the designation indicator interacted with treated status. Municipality and year fixed effects included. Standard errors clustered at the municipality level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$. Reference period is $t-1$ (2018). Sample restricted to 2010--2026.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, "tables/tab4_eventstudy.tex")
cat("  Table 4 saved.\n")

# -------------------------------------------------------------------
# TABLE F1: Standardized Effect Size (SDE) Appendix — MANDATORY
# -------------------------------------------------------------------
cat("\nGenerating Table F1: Standardized Effect Sizes...\n")

# Compute pre-treatment SD(Y) for each outcome
pre_panel <- panel[year <= 2018]

sd_nw_share <- sd(pre_panel$nw_share, na.rm = TRUE)
sd_log_nw <- sd(pre_panel$log_nw, na.rm = TRUE)
sd_emp_nw <- sd(pre_panel$emp_nw_imm, na.rm = TRUE)
sd_log_total <- sd(pre_panel$log_total, na.rm = TRUE)

# Extract coefficients and SEs
get_sde <- function(model, varname, sd_y, outcome_label) {
  ct <- summary(model)$coeftable
  beta <- ct[varname, "Estimate"]
  se_beta <- ct[varname, "Std. Error"]
  sde <- beta / sd_y
  se_sde <- se_beta / sd_y
  bucket <- ifelse(sde < -0.15, "Large negative",
            ifelse(sde < -0.05, "Moderate negative",
            ifelse(sde < -0.005, "Small negative",
            ifelse(sde < 0.005, "Null",
            ifelse(sde < 0.05, "Small positive",
            ifelse(sde < 0.15, "Moderate positive",
                   "Large positive"))))))
  data.table(
    Outcome = outcome_label,
    Beta = beta,
    SE = se_beta,
    SD_Y = sd_y,
    SDE = sde,
    SE_SDE = se_sde,
    Classification = bucket
  )
}

# Panel A: Pooled (max 4 rows to keep total ≤ 6)
sde_a1 <- get_sde(m1, "treat_post", sd_nw_share, "Non-Western Share")
sde_a2 <- get_sde(m2, "treat_post", sd_log_nw, "Log NW Population")
sde_a3 <- get_sde(m3, "treat_post", sd_emp_nw, "NW Employment Rate")

panel_a <- rbindlist(list(sde_a1, sde_a2, sde_a3))

# Panel B: Heterogeneous — split by treatment intensity (high vs low)
median_estates <- median(panel[treated == 1]$n_estates)
panel[, high_intensity := as.integer(n_estates > median_estates)]

# High-intensity municipalities
panel_hi <- panel[high_intensity == 1 | treated == 0]
m_hi <- feols(nw_share ~ treat_post | mun_code_num + year,
              data = panel_hi, cluster = ~mun_code_num)

# Low-intensity municipalities
panel_lo <- panel[(treated == 1 & high_intensity == 0) | treated == 0]
m_lo <- feols(nw_share ~ treat_post | mun_code_num + year,
              data = panel_lo, cluster = ~mun_code_num)

sde_b1 <- get_sde(m_hi, "treat_post", sd_nw_share, "NW Share (High Intensity)")
sde_b2 <- get_sde(m_lo, "treat_post", sd_nw_share, "NW Share (Low Intensity)")

panel_b <- rbindlist(list(sde_b1, sde_b2))

# Format and write LaTeX
fmt <- function(x, d = 4) sprintf(paste0("%.", d, "f"), x)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Denmark. ",
  "\\textbf{Research question:} Does official designation of public housing estates as ``parallel societies'' under the 2018 Ghetto Package cause displacement of non-Western immigrant-origin residents from designated municipalities? ",
  "\\textbf{Policy mechanism:} The 2018 Ghetto Package (Act No.~1000) mandated that estates designated as parallel societies for five consecutive years must reduce public family housing below 40\\% through demolition or conversion, imposed doubled criminal penalties for residents, and required mandatory integration contracts---creating both stigma and direct displacement pressure. ",
  "\\textbf{Outcome definition:} Non-Western share is the fraction of municipal population who are immigrants or descendants from non-Western countries (DST FOLK1E, ancestry codes 25 and 35); NW Employment Rate is the employment rate of non-Western immigrants aged 16--64 (DST RAS200). ",
  "\\textbf{Treatment:} Binary indicator equal to one if the municipality contains at least one estate on the 2018 parallel society designation list, interacted with a post-2018 indicator. ",
  "\\textbf{Data:} Statistics Denmark StatBank API (FOLK1E, RAS200), 98 municipalities, 2008--2026, annual (Q1 snapshots for population). ",
  "\\textbf{Method:} Two-way fixed effects (municipality + year FE), standard errors clustered at municipality level; Callaway--Sant'Anna for robustness. ",
  "\\textbf{Sample:} All 98 Danish municipalities; 15 treated (containing $\\geq$1 designated estate), 83 control. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lrrrrrrr}",
  "\\hline\\hline",
  " & & & & & & \\\\[-1ex]",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[0.5ex]"
)

for (i in 1:nrow(panel_a)) {
  r <- panel_a[i]
  tabF1_lines <- c(tabF1_lines,
    sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
            r$Outcome, fmt(r$Beta), fmt(r$SE), fmt(r$SD_Y),
            fmt(r$SDE), fmt(r$SE_SDE), r$Classification))
}

tabF1_lines <- c(tabF1_lines,
  "[0.5ex]",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Treatment Intensity Split)}} \\\\[0.5ex]"
)

for (i in 1:nrow(panel_b)) {
  r <- panel_b[i]
  tabF1_lines <- c(tabF1_lines,
    sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
            r$Outcome, fmt(r$Beta), fmt(r$SE), fmt(r$SD_Y),
            fmt(r$SDE), fmt(r$SE_SDE), r$Classification))
}

tabF1_lines <- c(tabF1_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, "tables/tabF1_sde.tex")
cat("  Table F1 (SDE) saved.\n")

cat("\n=== All tables generated ===\n")
