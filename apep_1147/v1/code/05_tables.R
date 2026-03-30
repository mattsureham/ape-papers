## ── 05_tables.R ───────────────────────────────────────────────────────────
## Generate all tables for the paper
## ───────────────────────────────────────────────────────────────────────────

source("00_packages.R")

panel <- readRDS("../data/panel_all.rds")
results <- readRDS("../data/main_results.rds")
rob <- readRDS("../data/robustness_results.rds")

## ══════════════════════════════════════════════════════════════════════════
## Table 1: Summary Statistics
## ══════════════════════════════════════════════════════════════════════════

cat("=== Table 1: Summary Statistics ===\n")

# Pre-period summary (before earliest treatment = 2012)
pre_panel <- panel %>% filter(year < 2012)

sumstats <- pre_panel %>%
  group_by(treated_state, race_label) %>%
  summarise(
    `Mean Earnings` = sprintf("%.0f", mean(EarnS, na.rm = TRUE)),
    `SD Earnings` = sprintf("%.0f", sd(EarnS, na.rm = TRUE)),
    `Mean Employment` = sprintf("%.0f", mean(Emp, na.rm = TRUE)),
    `Sep.~Rate` = sprintf("%.3f", mean(sep_rate, na.rm = TRUE)),
    `Counties` = as.character(n_distinct(county_fips)),
    `Obs.` = formatC(n(), format = "d", big.mark = ","),
    .groups = "drop"
  ) %>%
  mutate(Group = paste0(
    ifelse(treated_state, "RTW States", "Comparison States"),
    " -- ", race_label
  )) %>%
  select(Group, everything(), -treated_state, -race_label)

# Write LaTeX table
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Pre-Treatment Period (2005--2011)}",
  "\\label{tab:sumstats}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & Mean & SD & Mean & Sep. & & \\\\",
  "Group & Earnings & Earnings & Employment & Rate & Counties & Obs. \\\\",
  "\\midrule"
)

for (i in 1:nrow(sumstats)) {
  row_vals <- paste(sumstats[i, -1], collapse = " & ")
  tab1_lines <- c(tab1_lines, sprintf("%s & %s \\\\", sumstats$Group[i], row_vals))
  if (i == 2) tab1_lines <- c(tab1_lines, "\\midrule")
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Unit of observation is county $\\times$ race $\\times$ quarter. RTW states: Indiana, Michigan, Wisconsin, West Virginia. Comparison states: Illinois, Ohio, Minnesota, Pennsylvania, New York. Earnings are quarterly (EarnS from QWI). Separation rate = quarterly separations / employment. Sample restricted to counties with both Black and White observations for $\\geq$20 pre-treatment quarters.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_sumstats.tex")
cat("  Written tab1_sumstats.tex\n")

## ══════════════════════════════════════════════════════════════════════════
## Table 2: Main DDD Results
## ══════════════════════════════════════════════════════════════════════════

cat("=== Table 2: Main DDD Results ===\n")

m1 <- results$m1_ddd
m4 <- results$m4_mfg_ddd
m5 <- results$m5_emp
m6 <- results$m6_sep

# Extract DDD coefficients
extract_ddd <- function(model, coef_pattern = "ddd") {
  ct <- coeftable(model)
  idx <- grep(coef_pattern, rownames(ct))
  if (length(idx) == 0) return(list(coef = NA, se = NA, p = NA))
  list(coef = ct[idx, 1], se = ct[idx, 2], p = ct[idx, 4])
}

ddd1 <- extract_ddd(m1)
ddd4 <- extract_ddd(m4)
ddd5 <- extract_ddd(m5)
ddd6 <- extract_ddd(m6)

# Also extract RTW × Post (average RTW effect)
dd1 <- list(coef = NA, se = NA)  # DD absorbed by state × time FE

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  return("")
}

format_coef <- function(x, digits = 4) {
  if (is.na(x)) return("--")
  sprintf("%.*f", digits, x)
}

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Right-to-Work Laws and the Racial Earnings Gap: DDD Estimates}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Log Earnings & Log Earnings & Log Employment & Sep.~Rate \\\\",
  " & All Industries & Manufacturing & All Industries & All Industries \\\\",
  "\\midrule",
  sprintf("RTW $\\times$ Post $\\times$ Black & %s%s & %s%s & %s%s & %s%s \\\\",
          format_coef(ddd1$coef), stars(ddd1$p),
          format_coef(ddd4$coef), stars(ddd4$p),
          format_coef(ddd5$coef), stars(ddd5$p),
          format_coef(ddd6$coef), stars(ddd6$p)),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\",
          format_coef(ddd1$se), format_coef(ddd4$se),
          format_coef(ddd5$se), format_coef(ddd6$se)),
  sprintf("RTW $\\times$ Post & %s & -- & -- & -- \\\\",
          format_coef(dd1$coef)),
  sprintf(" & (%s) & & & \\\\", format_coef(dd1$se)),
  "\\midrule",
  "County $\\times$ Race FE & Yes & Yes & Yes & Yes \\\\",
  "Quarter $\\times$ Race FE & Yes & Yes & Yes & Yes \\\\",
  "State $\\times$ Quarter FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          formatC(nobs(m1), format = "d", big.mark = ","),
          formatC(nobs(m4), format = "d", big.mark = ","),
          formatC(nobs(m5), format = "d", big.mark = ","),
          formatC(nobs(m6), format = "d", big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Each column reports the triple-difference coefficient from a regression of the outcome on RTW $\\times$ Post $\\times$ Black, with county $\\times$ race, quarter $\\times$ race, and state $\\times$ quarter fixed effects. RTW states: IN (2012), MI (2013), WI (2015), WV (2016). Comparison states: IL, OH, MN, PA, NY. Standard errors clustered at state level in parentheses. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")
cat("  Written tab2_main.tex\n")

## ══════════════════════════════════════════════════════════════════════════
## Table 3: CS DiD and Sun-Abraham ATTs by Race
## ══════════════════════════════════════════════════════════════════════════

cat("=== Table 3: Heterogeneity-robust ATTs ===\n")

cs_b <- if (!is.null(results$cs_black)) aggte(results$cs_black, type = "simple") else NULL
cs_w <- if (!is.null(results$cs_white)) aggte(results$cs_white, type = "simple") else NULL

# Sun-Abraham ATTs
sa_b_ct <- coeftable(summary(results$m3_black, agg = "ATT"))
sa_w_ct <- coeftable(summary(results$m3_white, agg = "ATT"))

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Heterogeneity-Robust ATT Estimates by Race}",
  "\\label{tab:att_race}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Callaway-Sant'Anna} & \\multicolumn{2}{c}{Sun-Abraham} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Black & White & Black & White \\\\",
  "\\midrule"
)

# CS ATTs
if (!is.null(cs_b) && !is.null(cs_w)) {
  tab3_lines <- c(tab3_lines,
    sprintf("ATT & %s%s & %s%s & %s%s & %s%s \\\\",
            format_coef(cs_b$overall.att), "",
            format_coef(cs_w$overall.att), "",
            format_coef(sa_b_ct[1,1]), stars(sa_b_ct[1,4]),
            format_coef(sa_w_ct[1,1]), stars(sa_w_ct[1,4])),
    sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\",
            format_coef(cs_b$overall.se),
            format_coef(cs_w$overall.se),
            format_coef(sa_b_ct[1,2]),
            format_coef(sa_w_ct[1,2]))
  )
} else {
  tab3_lines <- c(tab3_lines,
    sprintf("ATT & -- & -- & %s%s & %s%s \\\\",
            format_coef(sa_b_ct[1,1]), stars(sa_b_ct[1,4]),
            format_coef(sa_w_ct[1,1]), stars(sa_w_ct[1,4])),
    sprintf(" & & & (%s) & (%s) \\\\",
            format_coef(sa_b_ct[1,2]),
            format_coef(sa_w_ct[1,2]))
  )
}

# Difference (Black - White)
if (!is.null(cs_b) && !is.null(cs_w)) {
  diff_cs <- cs_b$overall.att - cs_w$overall.att
  diff_sa <- sa_b_ct[1,1] - sa_w_ct[1,1]
  tab3_lines <- c(tab3_lines,
    "\\midrule",
    sprintf("Black $-$ White & %s & & %s & \\\\",
            format_coef(diff_cs), format_coef(diff_sa))
  )
} else {
  diff_sa <- sa_b_ct[1,1] - sa_w_ct[1,1]
  tab3_lines <- c(tab3_lines,
    "\\midrule",
    sprintf("Black $-$ White & -- & & %s & \\\\",
            format_coef(diff_sa))
  )
}

tab3_lines <- c(tab3_lines,
  "\\midrule",
  "County FE & Yes & Yes & Yes & Yes \\\\",
  "Quarter FE & Yes & Yes & Yes & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Callaway-Sant'Anna (2021) and Sun-Abraham (2021) estimates of the average treatment effect on the treated (ATT) of RTW adoption on log quarterly earnings, estimated separately for Black and White workers. Never-treated states serve as the comparison group. Standard errors clustered at state level. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_att_race.tex")
cat("  Written tab3_att_race.tex\n")

## ══════════════════════════════════════════════════════════════════════════
## Table 4: Robustness (Placebo + Leave-one-out)
## ══════════════════════════════════════════════════════════════════════════

cat("=== Table 4: Robustness ===\n")

placebo_ct <- coeftable(rob$placebo)
placebo_idx <- grep("placebo_ddd", rownames(placebo_ct))
placebo_coef <- if (length(placebo_idx) > 0) placebo_ct[placebo_idx, 1] else NA
placebo_se <- if (length(placebo_idx) > 0) placebo_ct[placebo_idx, 2] else NA
placebo_p <- if (length(placebo_idx) > 0) placebo_ct[placebo_idx, 4] else NA

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness: Placebo and Leave-One-Out Tests}",
  "\\label{tab:robustness}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & DDD Coefficient & SE \\\\",
  "\\midrule",
  "\\textit{Panel A: Placebo test} & & \\\\",
  sprintf("\\quad False RTW at $t-12$ quarters & %s%s & (%s) \\\\",
          format_coef(placebo_coef), stars(placebo_p), format_coef(placebo_se)),
  "\\midrule",
  "\\textit{Panel B: Leave-one-out} & & \\\\"
)

for (i in 1:nrow(rob$loo)) {
  tab4_lines <- c(tab4_lines,
    sprintf("\\quad Excluding %s & %s & (%s) \\\\",
            rob$loo$excluded[i],
            format_coef(rob$loo$coef[i]),
            format_coef(rob$loo$se[i]))
  )
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Panel A applies a placebo RTW adoption 12 quarters (3 years) before actual adoption, estimated on pre-treatment data only. Panel B re-estimates the main DDD specification excluding one treated state at a time. All specifications include county $\\times$ race, quarter $\\times$ race, and state $\\times$ quarter fixed effects. Standard errors clustered at state level. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_robustness.tex")
cat("  Written tab4_robustness.tex\n")

## ══════════════════════════════════════════════════════════════════════════
## Table F1: SDE Appendix (MANDATORY)
## ══════════════════════════════════════════════════════════════════════════

cat("=== Table F1: Standardized Effect Sizes ===\n")

# Compute SDE for main outcomes
pre_panel <- panel %>% filter(year < 2012)

compute_sde <- function(beta, outcome_var, data, label, treatment_type = "Binary") {
  sd_y <- sd(data[[outcome_var]], na.rm = TRUE)
  sde <- beta / sd_y
  se_sde <- NA  # Will be filled from model SE
  bucket <- case_when(
    sde < -0.15 ~ "Large negative",
    sde < -0.05 ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde < 0.005 ~ "Null",
    sde < 0.05 ~ "Small positive",
    sde < 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
  data.frame(
    Outcome = label,
    beta = beta,
    sd_y = sd_y,
    sde = sde,
    bucket = bucket,
    stringsAsFactors = FALSE
  )
}

# Extract coefficients
ct1 <- coeftable(results$m1_ddd)
ct4 <- coeftable(results$m4_mfg_ddd)
ct5 <- coeftable(results$m5_emp)
ct6 <- coeftable(results$m6_sep)

get_ddd_coef <- function(ct) {
  idx <- grep("^ddd$", rownames(ct))
  if (length(idx) > 0) return(list(coef = ct[idx, 1], se = ct[idx, 2]))
  list(coef = NA, se = NA)
}

d1 <- get_ddd_coef(ct1)
d4 <- get_ddd_coef(ct4)
d5 <- get_ddd_coef(ct5)
d6 <- get_ddd_coef(ct6)

panel_mfg <- readRDS("../data/panel_mfg.rds")
pre_mfg <- panel_mfg %>% filter(year < 2012)

sde_rows <- bind_rows(
  compute_sde(d1$coef, "log_earn", pre_panel, "Log earnings (all)"),
  compute_sde(d4$coef, "log_earn", pre_mfg, "Log earnings (mfg)"),
  compute_sde(d5$coef, "log_earn", pre_panel, "Log employment"),
  compute_sde(d6$coef, "sep_rate", pre_panel %>% filter(!is.na(sep_rate)), "Separation rate")
)

# Add SE for SDE
sde_rows$se_sde <- c(d1$se, d4$se, d5$se, d6$se) / sde_rows$sd_y

# ── Heterogeneity panel (sample splits) ──────────────────────────────────
# Split: Urban vs Rural counties (population proxy via employment)
median_emp <- median(pre_panel$Emp[pre_panel$race == "A1"], na.rm = TRUE)

panel_urban <- panel %>% filter(Emp >= median_emp)
panel_rural <- panel %>% filter(Emp < median_emp)

panel_urban$ddd <- as.integer(panel_urban$treated_state & panel_urban$post == 1 & panel_urban$black == 1)
panel_rural$ddd <- as.integer(panel_rural$treated_state & panel_rural$post == 1 & panel_rural$black == 1)

m_urban <- feols(
  log_earn ~ ddd |
    county_fips^race + time^race + state_fips^time,
  data = panel_urban, cluster = ~state_fips
)

m_rural <- feols(
  log_earn ~ ddd |
    county_fips^race + time^race + state_fips^time,
  data = panel_rural, cluster = ~state_fips
)

d_urban <- get_ddd_coef(coeftable(m_urban))
d_rural <- get_ddd_coef(coeftable(m_rural))

pre_urban <- panel_urban %>% filter(year < 2012)
pre_rural <- panel_rural %>% filter(year < 2012)

het_rows <- bind_rows(
  compute_sde(d_urban$coef, "log_earn", pre_urban, "Log earnings (urban)"),
  compute_sde(d_rural$coef, "log_earn", pre_rural, "Log earnings (rural)")
)
het_rows$se_sde <- c(d_urban$se, d_rural$se) / het_rows$sd_y

# ── Build LaTeX table ────────────────────────────────────────────────────
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do Right-to-Work laws differentially affect Black workers' quarterly earnings relative to White workers? ",
  "\\textbf{Policy mechanism:} RTW laws prohibit mandatory union membership or agency-fee agreements, weakening collective bargaining power that historically compressed the wage distribution and benefited Black workers in unionized sectors. ",
  "\\textbf{Outcome definition:} Log quarterly earnings (EarnS) from the QWI, measuring average stable full-quarter worker earnings at the county-race-quarter level. ",
  "\\textbf{Treatment:} Binary state-level adoption of RTW legislation (IN 2012, MI 2013, WI 2015, WV 2016). ",
  "\\textbf{Data:} Quarterly Workforce Indicators (QWI) race panel, 2005--2023, county $\\times$ race $\\times$ quarter; 9 states (4 treated, 5 comparison). ",
  "\\textbf{Method:} Triple-difference (state $\\times$ race $\\times$ post) with county-race, quarter-race, and state-quarter fixed effects; standard errors clustered at state level. ",
  "\\textbf{Sample:} Counties with continuous Black and White earnings data for $\\geq$20 pre-treatment quarters; balanced across both races. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\textit{Panel A: Pooled} & & & & & & \\\\"
)

for (i in 1:nrow(sde_rows)) {
  tabF1_lines <- c(tabF1_lines,
    sprintf("\\quad %s & %s & %s & %s & %s & %s & %s \\\\",
            sde_rows$Outcome[i],
            format_coef(sde_rows$beta[i]),
            format_coef(sde_rows$se_sde[i] * sde_rows$sd_y[i]),
            format_coef(sde_rows$sd_y[i], 3),
            format_coef(sde_rows$sde[i]),
            format_coef(sde_rows$se_sde[i]),
            sde_rows$bucket[i])
  )
}

tabF1_lines <- c(tabF1_lines,
  "\\midrule",
  "\\textit{Panel B: Heterogeneous (sample splits)} & & & & & & \\\\"
)

for (i in 1:nrow(het_rows)) {
  tabF1_lines <- c(tabF1_lines,
    sprintf("\\quad %s & %s & %s & %s & %s & %s & %s \\\\",
            het_rows$Outcome[i],
            format_coef(het_rows$beta[i]),
            format_coef(het_rows$se_sde[i] * het_rows$sd_y[i]),
            format_coef(het_rows$sd_y[i], 3),
            format_coef(het_rows$sde[i]),
            format_coef(het_rows$se_sde[i]),
            het_rows$bucket[i])
  )
}

tabF1_lines <- c(tabF1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")
cat("  Written tabF1_sde.tex\n")

cat("\nAll tables generated.\n")
