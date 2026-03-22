# 05_tables.R — Generate all LaTeX tables for apep_0744
# Wales 20mph Speed Limit and Road Safety

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

# Load data and models
panel <- fread(file.path(data_dir, "panel_la_quarter_speedcat.csv"))
panel_total <- fread(file.path(data_dir, "panel_la_quarter_total.csv"))
load(file.path(data_dir, "models.RData"))
load(file.path(data_dir, "robustness_models.RData"))

low <- panel[speed_cat == "low_speed"]
high <- panel[speed_cat == "high_speed"]

# ============================================================================
# TABLE 1: Summary Statistics
# ============================================================================

cat("Generating Table 1: Summary Statistics\n")

# Welsh LAs — low speed
welsh_low <- low[welsh == 1]
english_low <- low[welsh == 0]

# Pre-period stats
welsh_pre <- welsh_low[post == 0]
english_pre <- english_low[post == 0]

# Summary stats function
sumstat <- function(x) {
  c(Mean = mean(x, na.rm = TRUE),
    SD = sd(x, na.rm = TRUE),
    Min = min(x, na.rm = TRUE),
    Max = max(x, na.rm = TRUE))
}

# Build summary table
vars <- c("n_collisions", "n_ksi", "n_fatal", "n_serious", "n_slight")
var_labels <- c("Total collisions", "Killed or seriously injured",
                "Fatal collisions", "Serious collisions", "Slight collisions")

welsh_stats <- sapply(vars, function(v) sumstat(welsh_pre[[v]]))
english_stats <- sapply(vars, function(v) sumstat(english_pre[[v]]))

n_welsh_la <- uniqueN(welsh_pre$la_code)
n_english_la <- uniqueN(english_pre$la_code)
n_welsh_obs <- nrow(welsh_pre)
n_english_obs <- nrow(english_pre)

tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: Low-Speed Road Collisions by LA-Quarter (Pre-Treatment)}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{l rrrr rrrr}",
  "\\toprule",
  "& \\multicolumn{4}{c}{Welsh LAs} & \\multicolumn{4}{c}{English LAs} \\\\",
  "\\cmidrule(lr){2-5} \\cmidrule(lr){6-9}",
  "& Mean & SD & Min & Max & Mean & SD & Min & Max \\\\",
  "\\midrule"
)

for (i in seq_along(vars)) {
  ws <- welsh_stats[, i]
  es <- english_stats[, i]
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %.1f & %.1f & %d & %d & %.1f & %.1f & %d & %d \\\\",
    var_labels[i],
    ws["Mean"], ws["SD"], as.integer(ws["Min"]), as.integer(ws["Max"]),
    es["Mean"], es["SD"], as.integer(es["Min"]), as.integer(es["Max"])
  ))
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item \\textit{Notes:} Pre-treatment period (2020Q1--2023Q3). Welsh LAs: N = %s observations (%d LAs $\\times$ %d quarters). English LAs: N = %s observations (%d LAs $\\times$ %d quarters). Unit of observation is LA-quarter. Low-speed roads include 20mph and 30mph zones. Collision counts from DfT STATS19.",
          format(n_welsh_obs, big.mark = ","), n_welsh_la, uniqueN(welsh_pre$year_quarter),
          format(n_english_obs, big.mark = ","), n_english_la, uniqueN(english_pre$year_quarter)),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(table_dir, "tab1_summary.tex"))

# ============================================================================
# TABLE 2: Main DiD Results
# ============================================================================

cat("Generating Table 2: Main Results\n")

# Extract key stats from models
extract_row <- function(mod, ri_p = NULL) {
  b <- coef(mod)["treat"]
  se <- se(mod)["treat"]
  pv <- pvalue(mod)["treat"]
  n <- mod$nobs
  stars <- ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.1, "*", "")))
  ri_str <- if (!is.null(ri_p)) sprintf("%.3f", ri_p) else ""
  list(b = b, se = se, pv = pv, n = n, stars = stars, ri_str = ri_str)
}

r1 <- extract_row(m1, ri_pval_m1)
r3 <- extract_row(m3, ri_pval_m3)
r4 <- extract_row(m4)
rp <- extract_row(m_placebo)

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of Wales 20mph Default on Road Collisions}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{l cccc}",
  "\\toprule",
  "& (1) & (2) & (3) & (4) \\\\",
  "& All collisions & KSI & Fatal & Placebo ($>$40mph) \\\\",
  "\\midrule",
  sprintf("Welsh $\\times$ Post & %.3f%s & %.3f%s & %.3f%s & %.3f%s \\\\",
          r1$b, r1$stars, r3$b, r3$stars, r4$b, r4$stars, rp$b, rp$stars),
  sprintf("& (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\",
          r1$se, r3$se, r4$se, rp$se),
  sprintf("RI $p$-value & %s & %s & & \\\\", r1$ri_str, r3$ri_str),
  "\\\\",
  "LA FE & Yes & Yes & Yes & Yes \\\\",
  "Quarter FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          format(r1$n, big.mark = ","), format(r3$n, big.mark = ","),
          format(r4$n, big.mark = ","), format(rp$n, big.mark = ",")),
  sprintf("LAs & %d & %d & %d & %d \\\\",
          uniqueN(low$la_code), uniqueN(low$la_code),
          uniqueN(low$la_code), uniqueN(high$la_code)),
  sprintf("Welsh LAs & %d & %d & %d & %d \\\\",
          uniqueN(low[welsh==1, la_code]), uniqueN(low[welsh==1, la_code]),
          uniqueN(low[welsh==1, la_code]), uniqueN(high[welsh==1, la_code])),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Difference-in-differences estimates. Dependent variable is the quarterly collision count at the LA level. Columns (1)--(3) use low-speed (20 and 30mph) road collisions; Column (4) uses high-speed ($>$40mph) road collisions as a placebo. ``Post'' denotes 2023Q4 onwards (the first full quarter after the 17 September 2023 reform). Standard errors clustered at the LA level in parentheses. RI $p$-values from randomization inference (2,000 permutations of Welsh status). * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(table_dir, "tab2_main.tex"))

# ============================================================================
# TABLE 3: Event Study Coefficients
# ============================================================================

cat("Generating Table 3: Event Study\n")

es_coefs <- coeftable(m_es)
# Extract event-time coefficients
es_rows <- rownames(es_coefs)
es_idx <- grep("event_time::", es_rows)

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Event Study: Quarterly Treatment Effects on Low-Speed Collisions}",
  "\\label{tab:eventstudy}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{l cc}",
  "\\toprule",
  "Event time & Coefficient & SE \\\\",
  "\\midrule"
)

for (idx in es_idx) {
  et <- gsub("event_time::", "", es_rows[idx])
  et <- gsub(":welsh", "", et)
  b <- es_coefs[idx, "Estimate"]
  s <- es_coefs[idx, "Std. Error"]
  pv <- es_coefs[idx, "Pr(>|t|)"]
  stars <- ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.1, "*", "")))
  ref_marker <- ""
  tab3_lines <- c(tab3_lines, sprintf("$t %s %s$ & %.3f%s & (%.3f) \\\\",
                                       ifelse(as.numeric(et) >= 0, "+", ""),
                                       ifelse(as.numeric(et) >= 0, et, gsub("-", "- ", et)),
                                       b, stars, s))
}

# Add reference period note
tab3_lines <- c(tab3_lines,
  "$t - 1$ & \\multicolumn{2}{c}{[Reference period]} \\\\",
  "\\midrule",
  sprintf("Observations & \\multicolumn{2}{c}{%s} \\\\", format(m_es$nobs, big.mark = ",")),
  "LA FE & \\multicolumn{2}{c}{Yes} \\\\",
  "Quarter FE & \\multicolumn{2}{c}{Yes} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Event study estimates of the interaction between Welsh LA indicator and event-time dummies, with $t-1$ (2023Q3) as the reference period. Dependent variable is quarterly low-speed collision count. Standard errors clustered at the LA level. Treatment begins at $t=0$ (2023Q4). * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(table_dir, "tab3_eventstudy.tex"))

# ============================================================================
# TABLE 4: Robustness
# ============================================================================

cat("Generating Table 4: Robustness\n")

r_pois <- extract_row(m_pois)
r_notrans <- extract_row(m_notrans)
r_border <- extract_row(m_border)
r_urban <- extract_row(m_urban)
r_no2020 <- extract_row(m_no2020)

tab4_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{l cccccc}",
  "\\toprule",
  "& (1) & (2) & (3) & (4) & (5) & (6) \\\\",
  "& Baseline & Poisson & Excl.\\ 2023Q3 & Border LAs & Urban only & Excl.\\ 2020 \\\\",
  "\\midrule",
  sprintf("Welsh $\\times$ Post & %.3f%s & %.3f%s & %.3f%s & %.3f%s & %.3f%s & %.3f%s \\\\",
          r1$b, r1$stars,
          r_pois$b, r_pois$stars,
          r_notrans$b, r_notrans$stars,
          r_border$b, r_border$stars,
          r_urban$b, r_urban$stars,
          r_no2020$b, r_no2020$stars),
  sprintf("& (%.3f) & (%.3f) & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\",
          r1$se, r_pois$se, r_notrans$se, r_border$se, r_urban$se, r_no2020$se),
  "\\\\",
  "LA FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\",
  "Quarter FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s & %s & %s \\\\",
          format(r1$n, big.mark = ","), format(r_pois$n, big.mark = ","),
          format(r_notrans$n, big.mark = ","), format(r_border$n, big.mark = ","),
          format(r_urban$n, big.mark = ","), format(r_no2020$n, big.mark = ",")),
  sprintf("RI $p$-value & \\multicolumn{6}{c}{%.3f (1,000 permutations)} \\\\", ri_pval),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\end{threeparttable}",
  "\\par\\vspace{0.3em}",
  "{\\footnotesize\\sloppy \\textit{Notes:} Column (1) reproduces the baseline TWFE estimate. Column (2) uses Poisson QMLE (semi-elasticity reported). Column (3) excludes the transition quarter (2023Q3, partially treated). Column (4) restricts to border LAs (Welsh and English LAs adjacent to the Wales-England boundary). Column (5) restricts to collisions classified as urban. Column (6) excludes 2020 to address COVID-lockdown noise in the pre-period. The randomization inference (RI) $p$-value is from 1,000 permutations of Welsh status across all LAs. Standard errors clustered at the LA level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(table_dir, "tab4_robustness.tex"))

# ============================================================================
# TABLE F1: Standardized Effect Sizes (SDE)
# ============================================================================

cat("Generating Table F1: Standardized Effect Sizes\n")

# Main outcomes: collisions, KSI, fatal
sd_collisions <- sd(low[post == 0, n_collisions])
sd_ksi <- sd(low[post == 0, n_ksi])

b_coll <- coef(m1)["treat"]
se_coll <- se(m1)["treat"]
sde_coll <- b_coll / sd_collisions
se_sde_coll <- se_coll / sd_collisions

b_ksi <- coef(m3)["treat"]
se_ksi <- se(m3)["treat"]
sde_ksi <- b_ksi / sd_ksi
se_sde_ksi <- se_ksi / sd_ksi

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

sde_notes <- paste0(
  "\\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom (Wales vs.\\ England). ",
  "\\textbf{Research question:} Does reducing the default urban speed limit from 30mph to 20mph reduce road traffic collisions and their severity? ",
  "\\textbf{Policy mechanism:} Wales reclassified all restricted roads from a 30mph to a 20mph default speed limit overnight on 17 September 2023, affecting approximately 13,000km of road; this directly constrains permissible driving speeds on urban and village roads, reducing kinetic energy at impact and increasing driver reaction time margins. ",
  "\\textbf{Outcome definition:} Quarterly count of police-reported road traffic collisions on low-speed (20 and 30mph) roads per local authority, from DfT STATS19 records; KSI counts killed or seriously injured casualties per collision record. ",
  "\\textbf{Treatment:} Binary (Welsh LA $\\times$ post-September 2023). ",
  "\\textbf{Data:} DfT STATS19, 2020--2024, LA-quarter panel, approximately ",
  format(nrow(low), big.mark = ","), " observations. ",
  "\\textbf{Method:} Two-way fixed effects difference-in-differences with LA and quarter fixed effects, standard errors clustered at the LA level, randomization inference for few-cluster robustness. ",
  "\\textbf{Sample:} All local authorities in England and Wales with non-zero collision records; restricted to low-speed (20 and 30mph) road collisions to isolate affected road categories. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of the outcome. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{l l cccccc}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  sprintf("Collisions & TWFE DiD & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          b_coll, se_coll, sd_collisions, sde_coll, se_sde_coll, classify_sde(sde_coll)),
  sprintf("KSI & TWFE DiD & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          b_ksi, se_ksi, sd_ksi, sde_ksi, se_sde_ksi, classify_sde(sde_ksi)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\par\\vspace{0.3em}",
  "{\\footnotesize\\sloppy",
  sde_notes,
  "}",
  "\\end{table}"
)

writeLines(tabF1_lines, file.path(table_dir, "tabF1_sde.tex"))

cat("\n=== All tables generated ===\n")
cat(sprintf("Files in %s:\n", table_dir))
cat(paste(list.files(table_dir), collapse = "\n"), "\n")
