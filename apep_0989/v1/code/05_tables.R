# 05_tables.R — Generate all tables for the paper
# Czech EET and Business Dynamics (apep_0989)

source("00_packages.R")

# Load results
main_results <- readRDS("../data/main_results.rds")
robust_results <- readRDS("../data/robust_results.rds")

# Reload panel for summary stats
sbs_ind <- readRDS("../data/eurostat_sbs_na_ind_r2.rds")
sbs_svc <- readRDS("../data/eurostat_sbs_na_1a_se_r2.rds")
sbs_con <- readRDS("../data/eurostat_sbs_na_con_r2.rds")
sbs_trd <- readRDS("../data/eurostat_sbs_na_dt_r2.rds")
sbs_all <- bind_rows(sbs_ind, sbs_svc, sbs_con, sbs_trd)

eet_section_map <- c("I" = 2017, "G" = 2017, "H" = 2018, "M" = 2018, "C" = 2018)

enterprises_2d <- sbs_all %>%
  filter(indic_sb == "V11110", !is.na(values),
         grepl("^[A-Z][0-9]{2}$", nace_r2)) %>%
  mutate(section = substr(nace_r2, 1, 1), year = time) %>%
  select(geo, nace_r2, section, year, n_enterprises = values) %>%
  filter(year >= 2008, year <= 2020)

panel_full <- enterprises_2d %>%
  mutate(
    treatment_year = ifelse(geo == "CZ", eet_section_map[section], NA_real_),
    treated = ifelse(!is.na(treatment_year) & year >= treatment_year, 1, 0),
    unit_id = paste(geo, nace_r2, sep = "_"),
    ln_enterprises = log(n_enterprises)
  )
unit_counts <- panel_full %>% group_by(unit_id) %>% summarize(n = n())
panel_bal <- panel_full %>% filter(unit_id %in% unit_counts$unit_id[unit_counts$n == 13])

# ===================================================================
# TABLE 1: Summary Statistics
# ===================================================================
cat("=== Table 1: Summary Statistics ===\n")

# By country and treatment status
summ_stats <- panel_bal %>%
  mutate(group = case_when(
    geo == "CZ" & !is.na(treatment_year) ~ "CZ EET Sectors",
    geo == "CZ" & is.na(treatment_year) ~ "CZ Non-EET Sectors",
    TRUE ~ paste0(geo, " (Control)")
  )) %>%
  group_by(group) %>%
  summarize(
    N = n(),
    `Divisions` = n_distinct(nace_r2),
    `Mean Enterprises` = round(mean(n_enterprises)),
    `SD Enterprises` = round(sd(n_enterprises)),
    `Mean ln(Enterprises)` = round(mean(ln_enterprises, na.rm = TRUE), 2),
    `SD ln(Enterprises)` = round(sd(ln_enterprises, na.rm = TRUE), 2),
    .groups = "drop"
  )

# Write LaTeX
tab1_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lrrrrrr}\n",
  "\\toprule\n",
  " & N & Divisions & Mean & SD & Mean & SD \\\\\n",
  " & & & Enterprises & Enterprises & ln(Ent.) & ln(Ent.) \\\\\n",
  "\\midrule\n"
)

for (i in 1:nrow(summ_stats)) {
  row <- summ_stats[i, ]
  tab1_tex <- paste0(tab1_tex,
    row$group, " & ",
    format(row$N, big.mark = ","), " & ",
    row$Divisions, " & ",
    format(row$`Mean Enterprises`, big.mark = ","), " & ",
    format(row$`SD Enterprises`, big.mark = ","), " & ",
    row$`Mean ln(Enterprises)`, " & ",
    row$`SD ln(Enterprises)`, " \\\\\n"
  )
}

tab1_tex <- paste0(tab1_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Panel of 2-digit NACE divisions $\\times$ countries, 2008--2020. ",
  "Enterprise counts from Eurostat Structural Business Statistics (SBS). ",
  "CZ EET sectors are NACE sections C, G, H, I, M, phased into electronic reporting ",
  "between December 2016 and June 2018. Non-EET sectors are NACE sections B, D, E, F, J, K, L, N, S. ",
  "Control countries are Austria, Hungary, Poland, and Slovakia.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:summary}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, "../tables/tab1_summary.tex")
cat("Written tables/tab1_summary.tex\n")

# ===================================================================
# TABLE 2: Main Results
# ===================================================================
cat("\n=== Table 2: Main Results ===\n")

# Extract estimates from main specifications
est_twfe <- main_results$twfe
est_sunab <- main_results$sunab
est_trends <- robust_results$trends
est_short <- robust_results$short
est_czsk <- robust_results$czsk

# Function to format coefficient
fmt_coef <- function(est, var_name = "treated") {
  if (is.null(est)) return(c("", "", ""))
  b <- coef(est)[var_name]
  se <- sqrt(diag(vcov(est)))[var_name]
  pv <- 2 * pnorm(-abs(b / se))
  stars <- ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.1, "*", "")))
  c(
    paste0(formatC(b, format = "f", digits = 3), stars),
    paste0("(", formatC(se, format = "f", digits = 3), ")"),
    as.character(est$nobs)
  )
}

c1 <- fmt_coef(est_twfe)
c2 <- fmt_coef(est_trends)
c3 <- fmt_coef(est_short)
c4 <- fmt_coef(est_czsk)

# CZ-only
est_cz <- main_results$cz_only
c5 <- fmt_coef(est_cz)

tab2_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Effect of Electronic Records of Sales on Enterprise Counts}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & TWFE & Unit & Short & CZ vs & CZ \\\\\n",
  " & & Trends & Window & SK & Only \\\\\n",
  "\\midrule\n",
  "EET Treatment & ", c1[1], " & ", c2[1], " & ", c3[1], " & ", c4[1], " & ", c5[1], " \\\\\n",
  " & ", c1[2], " & ", c2[2], " & ", c3[2], " & ", c4[2], " & ", c5[2], " \\\\\n",
  " & & & & & \\\\\n",
  "Unit FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Unit Trends & No & Yes & No & No & No \\\\\n",
  "Pre-period & 2008--16 & 2008--16 & 2013--16 & 2008--16 & 2008--16 \\\\\n",
  "Countries & 5 & 5 & 5 & CZ, SK & CZ \\\\\n",
  "N & ", c1[3], " & ", c2[3], " & ", c3[3], " & ", c4[3], " & ", c5[3], " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Dependent variable is ln(number of enterprises) at the 2-digit NACE division ",
  "$\\times$ country $\\times$ year level. Treatment is 1 for Czech divisions in EET-covered sectors ",
  "(NACE C, G, H, I, M) after their respective phase-in date. Standard errors clustered at the ",
  "division $\\times$ country level in parentheses. Column (2) includes division-specific linear time trends. ",
  "Column (3) restricts the pre-period to 2013--2016. Column (4) uses only Czech Republic and Slovakia. ",
  "Column (5) uses only Czech divisions, comparing EET to non-EET sectors. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:main}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, "../tables/tab2_main.tex")
cat("Written tables/tab2_main.tex\n")

# ===================================================================
# TABLE 3: Heterogeneous Effects by Sector
# ===================================================================
cat("\n=== Table 3: Heterogeneous Effects ===\n")

est_h <- main_results$hetero
sector_names <- c(
  "C" = "Manufacturing (Phase 4, Jun 2018)",
  "G" = "Wholesale \\& Retail (Phase 2, Mar 2017)",
  "H" = "Transport (Phase 3, Mar 2018)",
  "I" = "Accommodation \\& Food (Phase 1, Dec 2016)",
  "M" = "Professional Services (Phase 3, Mar 2018)"
)

# Extract heterogeneous coefficients
h_coefs <- coef(est_h)
h_ses <- sqrt(diag(vcov(est_h)))
h_pvs <- 2 * pnorm(-abs(h_coefs / h_ses))

tab3_lines <- character()
for (sec in c("I", "G", "H", "M", "C")) {
  vn <- paste0("eet_section::", sec, ":treated")
  b <- h_coefs[vn]
  se <- h_ses[vn]
  pv <- h_pvs[vn]
  stars <- ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.1, "*", "")))
  tab3_lines <- c(tab3_lines,
    paste0(sector_names[sec], " & ", formatC(b, format = "f", digits = 3), stars, " \\\\"),
    paste0(" & (", formatC(se, format = "f", digits = 3), ") \\\\")
  )
}

tab3_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Heterogeneous Effects by EET Phase}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lc}\n",
  "\\toprule\n",
  "Sector (Phase, Date) & ln(Enterprises) \\\\\n",
  "\\midrule\n",
  paste(tab3_lines, collapse = "\n"), "\n",
  " & \\\\\n",
  "Unit \\& Year FE & Yes \\\\\n",
  "N & ", est_h$nobs, " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Dependent variable is ln(number of enterprises). Each row shows the ",
  "interaction of the sector indicator with the post-treatment indicator for Czech divisions only. ",
  "Reference group: all non-EET sectors across all countries. Standard errors clustered at the ",
  "division $\\times$ country level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:hetero}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, "../tables/tab3_hetero.tex")
cat("Written tables/tab3_hetero.tex\n")

# ===================================================================
# TABLE 4: Robustness (Placebo, Permutation, Mechanisms)
# ===================================================================
cat("\n=== Table 4: Robustness ===\n")

# Placebo
est_placebo <- robust_results$placebo
c_placebo <- fmt_coef(est_placebo, "placebo_treated")

# VAT
est_vat <- main_results$vat
c_vat <- fmt_coef(est_vat, "cz_post")

# Abolition
est_abol <- robust_results$abolition
c_abol <- fmt_coef(est_abol, "reversal")

tab4_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Robustness and Mechanism Tests}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) \\\\\n",
  " & Placebo & VAT & Abolition \\\\\n",
  " & (Non-EET CZ) & Revenue & Reversal \\\\\n",
  "\\midrule\n",
  "Treatment & ", c_placebo[1], " & ", c_vat[1], " & ", c_abol[1], " \\\\\n",
  " & ", c_placebo[2], " & ", c_vat[2], " & ", c_abol[2], " \\\\\n",
  " & & & \\\\\n",
  "Permutation $p$-value & \\multicolumn{3}{c}{", formatC(robust_results$perm_p, format = "f", digits = 3), " (1,000 permutations)} \\\\\n",
  "Unit FE & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes \\\\\n",
  "N & ", c_placebo[3], " & ", c_vat[3], " & ", c_abol[3], " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Column (1): placebo test assigning ``treatment'' to non-EET Czech sectors ",
  "at 2017, comparing to other countries' non-EET sectors. A significant coefficient here indicates ",
  "that Czech-specific trends contaminate the cross-country comparison. ",
  "Column (2): effect of post-EET Czech status on ln(VAT revenue), country-year panel 2008--2022, ",
  "standard errors clustered by country. ",
  "Column (3): reversal test using Czech Statistical Office data (2022--2025), testing whether ",
  "former EET sectors diverge from non-EET sectors after the January 2023 abolition. ",
  "Permutation $p$-value from 1,000 random reassignments of EET treatment to Czech divisions. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:robust}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, "../tables/tab4_robust.tex")
cat("Written tables/tab4_robust.tex\n")

# ===================================================================
# TABLE F1: Standardized Effect Sizes (SDE)
# ===================================================================
cat("\n=== Table F1: Standardized Effect Sizes ===\n")

# Main specification: TWFE with unit trends (preferred)
est_pref <- robust_results$trends
beta_pref <- coef(est_pref)["treated"]
se_pref <- sqrt(diag(vcov(est_pref)))["treated"]
# Exclude infinite values (from log of zero) when computing SD(Y)
sd_y <- sd(panel_bal$ln_enterprises[is.finite(panel_bal$ln_enterprises)], na.rm = TRUE)

sde_pref <- beta_pref / sd_y
se_sde_pref <- se_pref / sd_y

# Naive TWFE
beta_naive <- coef(main_results$twfe)["treated"]
se_naive <- sqrt(diag(vcov(main_results$twfe)))["treated"]
sde_naive <- beta_naive / sd_y
se_sde_naive <- se_naive / sd_y

# CZ-only
beta_cz <- coef(main_results$cz_only)["treated"]
se_cz <- sqrt(diag(vcov(main_results$cz_only)))["treated"]
sd_y_cz <- sd(panel_bal$ln_enterprises[panel_bal$geo == "CZ" & is.finite(panel_bal$ln_enterprises)], na.rm = TRUE)
sde_cz <- beta_cz / sd_y_cz
se_sde_cz <- se_cz / sd_y_cz

# Short window
beta_short <- coef(robust_results$short)["treated"]
se_short <- sqrt(diag(vcov(robust_results$short)))["treated"]
sde_short <- beta_short / sd_y
se_sde_short <- se_short / sd_y

classify <- function(s) {
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

# --- SDE notes string ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Czech Republic. ",
  "\\textbf{Research question:} Does mandatory real-time electronic reporting of cash transactions ",
  "affect the number of registered business enterprises in targeted economic sectors? ",
  "\\textbf{Policy mechanism:} The Electronic Records of Sales (EET) system required all businesses ",
  "with cash transactions to transmit receipt data to the tax authority in real time, creating a ",
  "technological enforcement tool that increased the cost of operating informally while potentially ",
  "reducing the viability of marginal enterprises dependent on tax evasion. ",
  "\\textbf{Outcome definition:} Number of active enterprises at the 2-digit NACE division level, ",
  "from Eurostat Structural Business Statistics, measured annually. ",
  "\\textbf{Treatment:} Binary indicator equal to one for Czech NACE divisions in EET-covered ",
  "sectors after their respective phase-in date (NACE I and G from 2017; H, M, and C from 2018). ",
  "\\textbf{Data:} Eurostat SBS, 2008--2020, 2-digit NACE division $\\times$ country $\\times$ year ",
  "panel with five Visegrad+ countries (CZ, SK, PL, HU, AT), balanced panel of 324 units. ",
  "\\textbf{Method:} Two-way fixed effects with division$\\times$country and year fixed effects; ",
  "preferred specification adds unit-specific linear trends. Standard errors clustered at ",
  "division$\\times$country level. Sun--Abraham event study as alternative heterogeneity-robust estimator. ",
  "\\textbf{Sample:} 2-digit NACE divisions with complete data 2008--2020; sectors B through S ",
  "excluding agriculture (A, not in SBS) and public administration (O, P, Q excluded as non-market). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation ",
  "of ln(enterprises) in the full panel. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Heterogeneity: cash-intensive vs non-cash-intensive sectors
# Use interaction in the full panel (subsample within CZ only would cause collinearity)
panel_bal_h <- panel_bal %>%
  mutate(
    cash_intensive = ifelse(geo == "CZ" & section %in% c("I", "G") & !is.na(treatment_year), 1, 0),
    noncash_intensive = ifelse(geo == "CZ" & section %in% c("C", "H", "M") & !is.na(treatment_year), 1, 0),
    treated_cash = treated * cash_intensive,
    treated_noncash = treated * noncash_intensive
  )

est_cash_split <- feols(ln_enterprises ~ treated_cash + treated_noncash | unit_id + year,
                        data = panel_bal_h, cluster = ~unit_id)

beta_cash <- coef(est_cash_split)["treated_cash"]
se_cash <- sqrt(diag(vcov(est_cash_split)))["treated_cash"]
beta_noncash <- coef(est_cash_split)["treated_noncash"]
se_noncash <- sqrt(diag(vcov(est_cash_split)))["treated_noncash"]

sd_y_h <- sd(panel_bal_h$ln_enterprises[is.finite(panel_bal_h$ln_enterprises)], na.rm = TRUE)
sde_cash <- beta_cash / sd_y_h
se_sde_cash <- se_cash / sd_y_h
sde_noncash <- beta_noncash / sd_y_h
se_sde_noncash <- se_noncash / sd_y_h

# Build SDE table
sde_rows <- data.frame(
  panel = c("A", "A", "A", "A", "B", "B"),
  outcome = c(
    "ln(Enterprises) --- Preferred (unit trends)",
    "ln(Enterprises) --- Na\\\"ive TWFE",
    "ln(Enterprises) --- Short window (2013+)",
    "ln(Enterprises) --- CZ only",
    "ln(Enterprises) --- Cash-intensive sectors",
    "ln(Enterprises) --- Non-cash-intensive sectors"
  ),
  beta = c(beta_pref, beta_naive, beta_short, beta_cz, beta_cash, beta_noncash),
  se = c(se_pref, se_naive, se_short, se_cz, se_cash, se_noncash),
  sd_y = c(sd_y, sd_y, sd_y, sd_y_cz, sd_y_h, sd_y_h),
  sde = c(sde_pref, sde_naive, sde_short, sde_cz, sde_cash, sde_noncash),
  se_sde = c(se_sde_pref, se_sde_naive, se_sde_short, se_sde_cz, se_sde_cash, se_sde_noncash),
  stringsAsFactors = FALSE
)
sde_rows$classification <- classify(sde_rows$sde)

tabF1_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n"
)

for (i in 1:nrow(sde_rows)) {
  if (i == 5) {
    tabF1_tex <- paste0(tabF1_tex,
      "\\midrule\n",
      "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\\n"
    )
  }
  tabF1_tex <- paste0(tabF1_tex,
    sde_rows$outcome[i], " & ",
    formatC(sde_rows$beta[i], format = "f", digits = 3), " & ",
    formatC(sde_rows$se[i], format = "f", digits = 3), " & ",
    formatC(sde_rows$sd_y[i], format = "f", digits = 2), " & ",
    formatC(sde_rows$sde[i], format = "f", digits = 3), " & ",
    formatC(sde_rows$se_sde[i], format = "f", digits = 3), " & ",
    sde_rows$classification[i], " \\\\\n"
  )
}

tabF1_tex <- paste0(tabF1_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\par\\vspace{0.3em}\n",
  "{\\footnotesize\n",
  "\\begin{itemize}[leftmargin=*]\n",
  sde_notes, "\n",
  "\\end{itemize}\n",
  "}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, "../tables/tabF1_sde.tex")
cat("Written tables/tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
cat("Files:\n")
print(list.files("../tables/"))
