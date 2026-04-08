# 05_tables.R — Generate all tables for ASAN paper
# Paper: apep_1413

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE)

panel <- read.csv(file.path(data_dir, "analysis_panel.csv"), stringsAsFactors = FALSE)
es_panel <- read.csv(file.path(data_dir, "es_bribery_panel.csv"), stringsAsFactors = FALSE)
main_results <- readRDS(file.path(data_dir, "main_results.rds"))
robustness <- readRDS(file.path(data_dir, "robustness_results.rds"))

# Balance panel same as main analysis
balanced <- panel %>%
  filter(year >= 2008, year <= 2020, !is.na(new_registrations)) %>%
  group_by(iso3) %>%
  filter(n() == 13) %>%
  ungroup() %>%
  mutate(
    aze = as.integer(iso3 == "AZE"),
    post2013 = as.integer(year >= 2013),
    aze_post = aze * post2013,
    group = ifelse(iso3 == "AZE", "Azerbaijan", "Donor Pool"),
    period = ifelse(year < 2013, "Pre-ASAN", "Post-ASAN")
  )

country_names <- c(
  AZE = "Azerbaijan", GEO = "Georgia", ARM = "Armenia", KAZ = "Kazakhstan",
  UZB = "Uzbekistan", KGZ = "Kyrgyz Republic", TJK = "Tajikistan",
  TUR = "Turkey", UKR = "Ukraine", MDA = "Moldova", BLR = "Belarus",
  RUS = "Russia", MNG = "Mongolia"
)

# ============================================================
# Table 1: Summary Statistics
# ============================================================

cat("=== Table 1: Summary Statistics ===\n")

vars <- c("new_registrations", "gdp_pc", "unemployment", "inflation",
          "corruption_control", "govt_effectiveness")
var_labels <- c(
  "New business registrations",
  "GDP per capita (PPP, 2017 \\$)",
  "Unemployment (\\%)",
  "Inflation (\\%)",
  "Control of corruption (WGI)",
  "Government effectiveness (WGI)"
)

tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Azerbaijan vs.\\ Donor Pool}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{Pre-ASAN (2008--2012)} & \\multicolumn{2}{c}{Post-ASAN (2013--2020)} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Azerbaijan & Donor Pool & Azerbaijan & Donor Pool \\\\",
  "\\hline"
)

for (i in seq_along(vars)) {
  v <- vars[i]
  label <- var_labels[i]

  stats <- balanced %>%
    group_by(group, period) %>%
    summarize(m = mean(!!sym(v), na.rm = TRUE),
              s = sd(!!sym(v), na.rm = TRUE), .groups = "drop")

  fmt <- function(grp, per) {
    row <- stats %>% filter(group == grp, period == per)
    if (nrow(row) == 0 || is.na(row$m)) return(c("---", ""))
    if (abs(row$m) >= 1000) {
      return(c(formatC(row$m, format = "f", digits = 0, big.mark = ","),
               sprintf("(%s)", formatC(row$s, format = "f", digits = 0, big.mark = ","))))
    }
    return(c(formatC(row$m, format = "f", digits = 2),
             sprintf("(%.2f)", row$s)))
  }

  ap <- fmt("Azerbaijan", "Pre-ASAN")
  dp <- fmt("Donor Pool", "Pre-ASAN")
  apo <- fmt("Azerbaijan", "Post-ASAN")
  dpo <- fmt("Donor Pool", "Post-ASAN")

  tab1_lines <- c(tab1_lines,
    sprintf("%s & %s & %s & %s & %s \\\\", label, ap[1], dp[1], apo[1], dpo[1]),
    sprintf(" & %s & %s & %s & %s \\\\", ap[2], dp[2], apo[2], dpo[2])
  )
}

n_pre_aze <- nrow(filter(balanced, group == "Azerbaijan", period == "Pre-ASAN"))
n_pre_don <- nrow(filter(balanced, group == "Donor Pool", period == "Pre-ASAN"))
n_post_aze <- nrow(filter(balanced, group == "Azerbaijan", period == "Post-ASAN"))
n_post_don <- nrow(filter(balanced, group == "Donor Pool", period == "Post-ASAN"))

tab1_lines <- c(tab1_lines,
  "\\hline",
  sprintf("Country-years & %d & %d & %d & %d \\\\",
    n_pre_aze, n_pre_don, n_post_aze, n_post_don),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Standard deviations in parentheses. The donor pool consists of nine Former Soviet and regional comparator countries: Armenia, Belarus, Georgia, Kazakhstan, Moldova, Mongolia, Russia, Turkey, and Uzbekistan. ASAN began operations in December 2012. All data from World Development Indicators and Worldwide Governance Indicators.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(table_dir, "tab1_summary.tex"))
cat("Table 1 saved.\n")

# ============================================================
# Table 2: Bribery Trends Across Former Soviet States
# ============================================================

cat("\n=== Table 2: Bribery Trends ===\n")

brib_summary <- es_panel %>%
  filter(!is.na(bribery_pct)) %>%
  mutate(period = ifelse(year < 2013, "Pre", "Post")) %>%
  group_by(iso3, period) %>%
  summarize(brib = mean(bribery_pct), .groups = "drop") %>%
  pivot_wider(names_from = period, values_from = brib) %>%
  mutate(change = Post - Pre,
         has_asan = ifelse(iso3 == "AZE", "Yes", "No")) %>%
  filter(!is.na(change)) %>%
  arrange(change)

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Bribery Incidence Before and After 2013 (\\% of Firms)}",
  "\\label{tab:bribery}",
  "\\begin{tabular}{lcccl}",
  "\\hline\\hline",
  "Country & Pre-2013 & Post-2013 & Change & One-Stop-Shop \\\\",
  "\\hline"
)

for (i in seq_len(nrow(brib_summary))) {
  row <- brib_summary[i, ]
  cname <- ifelse(row$iso3 %in% names(country_names), country_names[row$iso3], row$iso3)
  bold <- ifelse(row$iso3 == "AZE", "\\textbf{", "")
  bold_end <- ifelse(row$iso3 == "AZE", "}", "")
  tab2_lines <- c(tab2_lines,
    sprintf("%s%s%s & %.1f & %.1f & %+.1f & %s \\\\",
      bold, cname, bold_end,
      ifelse(is.na(row$Pre), NA, row$Pre),
      ifelse(is.na(row$Post), NA, row$Post),
      row$change, row$has_asan
    )
  )
}

tab2_lines <- c(tab2_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Bribery incidence is the percentage of firms reporting at least one bribe request in dealings with government officials. Data from World Bank Enterprise Surveys (BEEPS). Pre-2013 and post-2013 columns report averages across available survey waves within each period. ASAN = Azerbaijan Service and Assessment Network, launched December 2012.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(table_dir, "tab2_bribery.tex"))
cat("Table 2 saved.\n")

# ============================================================
# Table 3: Main DiD Results
# ============================================================

cat("\n=== Table 3: Main DiD Results ===\n")

# Extract coefficients
reg_level <- main_results$did_reg_level
reg_log <- main_results$did_reg_log
goveff <- main_results$did_goveff
corr <- main_results$did_corr

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of ASAN on Business Environment: Cross-Country Difference-in-Differences}",
  "\\label{tab:did_results}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Registrations & Log Reg. & Govt.\\ Eff. & Corruption \\\\",
  "\\hline",
  sprintf("ASAN $\\times$ Post & %s & %s & %s & %s \\\\",
    formatC(coef(reg_level)["aze_post"], format = "f", digits = 0, big.mark = ","),
    formatC(coef(reg_log)["aze_post"], format = "f", digits = 3),
    formatC(coef(goveff)["aze_post"], format = "f", digits = 3),
    formatC(coef(corr)["aze_post"], format = "f", digits = 3)
  ),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\",
    formatC(sqrt(diag(vcov(reg_level)))["aze_post"], format = "f", digits = 0, big.mark = ","),
    formatC(sqrt(diag(vcov(reg_log)))["aze_post"], format = "f", digits = 3),
    formatC(sqrt(diag(vcov(goveff)))["aze_post"], format = "f", digits = 3),
    formatC(sqrt(diag(vcov(corr)))["aze_post"], format = "f", digits = 3)
  )
)

# Stars
stars <- function(p) {
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.1) return("*")
  return("")
}

# Add implied % and permutation p-value
pct <- main_results$pct_effect
perm_p <- main_results$perm_pvalue

tab3_lines <- c(tab3_lines,
  sprintf("Implied \\%% effect & --- & %.1f\\%% & --- & --- \\\\", pct),
  sprintf("Permutation $p$-value & --- & %.3f & --- & --- \\\\", perm_p),
  "\\hline",
  sprintf("Observations & %d & %d & %d & %d \\\\",
    nrow(balanced), nrow(balanced), nrow(balanced), nrow(balanced)),
  sprintf("Countries & %d & %d & %d & %d \\\\",
    n_distinct(balanced$iso3), n_distinct(balanced$iso3),
    n_distinct(balanced$iso3), n_distinct(balanced$iso3)),
  "Country FE & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each column reports a separate TWFE difference-in-differences regression. The treated unit is Azerbaijan; treatment begins in 2013 (ASAN operational). Standard errors clustered at the country level in parentheses. The permutation $p$-value is computed by assigning placebo treatment to each donor country and ranking Azerbaijan's ATT against the placebo distribution (Abadie et al., 2010). Government effectiveness and control of corruption are Worldwide Governance Indicators (range $-$2.5 to $+$2.5). $^{***} p<0.01$, $^{**} p<0.05$, $^{*} p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(table_dir, "tab3_did.tex"))
cat("Table 3 saved.\n")

# ============================================================
# Table 4: Robustness
# ============================================================

cat("\n=== Table 4: Robustness ===\n")

loo <- robustness$loo

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness: Leave-One-Out and Alternative Specifications}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  " & Log Reg. & Govt.\\ Eff. \\\\",
  "\\hline",
  "\\textit{Panel A: Baseline} & & \\\\",
  sprintf("\\quad Main estimate & %.3f & %.3f \\\\",
    coef(main_results$did_reg_log)["aze_post"],
    coef(main_results$did_goveff)["aze_post"]),
  sprintf("\\quad & (%.3f) & (%.3f) \\\\",
    sqrt(diag(vcov(main_results$did_reg_log)))["aze_post"],
    sqrt(diag(vcov(main_results$did_goveff)))["aze_post"]),
  " & & \\\\",
  "\\textit{Panel B: Leave-one-out (log reg.)} & & \\\\",
  sprintf("\\quad Range & [%.3f, %.3f] & --- \\\\",
    min(loo$att), max(loo$att)),
  " & & \\\\",
  "\\textit{Panel C: Alternative specifications} & & \\\\"
)

# Restricted pool
rest_coef <- coef(robustness$restricted)["aze_post"]
rest_se <- sqrt(diag(vcov(robustness$restricted)))["aze_post"]

# Placebo time
plac_coef <- coef(robustness$placebo_time)["placebo_tp"]
plac_se <- sqrt(diag(vcov(robustness$placebo_time)))["placebo_tp"]

# GDP placebo
gdp_coef <- coef(robustness$gdp_placebo)["aze_post"]
gdp_se <- sqrt(diag(vcov(robustness$gdp_placebo)))["aze_post"]

tab4_lines <- c(tab4_lines,
  sprintf("\\quad Restricted donors (Caucasus + C.\\ Asia) & %.3f & --- \\\\", rest_coef),
  sprintf("\\quad & (%.3f) & \\\\", rest_se),
  sprintf("\\quad Placebo treatment (2010) & %.3f & --- \\\\", plac_coef),
  sprintf("\\quad & (%.3f) & \\\\", plac_se),
  sprintf("\\quad GDP per capita (placebo outcome) & \\multicolumn{2}{c}{%s} \\\\",
    formatC(gdp_coef, format = "f", digits = 0, big.mark = ",")),
  sprintf("\\quad & \\multicolumn{2}{c}{(%s)} \\\\",
    formatC(gdp_se, format = "f", digits = 0, big.mark = ",")),
  " & & \\\\",
  "\\textit{Panel D: Permutation inference} & & \\\\",
  sprintf("\\quad Rank of Azerbaijan & %d/%d & --- \\\\",
    sum(abs(robustness$space_placebos$att) >= abs(robustness$true_att)) + 1,
    nrow(robustness$space_placebos) + 1),
  sprintf("\\quad Permutation $p$-value & %.3f & --- \\\\", robustness$perm_pvalue),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Panel A reproduces baseline estimates from Table~\\ref{tab:did_results}. Panel B drops one donor country at a time. Panel C tests alternative specifications: restricting to 4 Caucasus and Central Asian donors; assigning placebo treatment to 2010 (pre-ASAN); using GDP per capita as a placebo outcome (the negative coefficient reflects Azerbaijan's 2014--2016 oil price shock). Panel D ranks Azerbaijan's ATT against placebo ATTs from each donor country. Standard errors clustered at the country level.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(table_dir, "tab4_robustness.tex"))
cat("Table 4 saved.\n")

# ============================================================
# Table F1: Standardized Effect Sizes (SDE)
# ============================================================

cat("\n=== Table F1: SDE ===\n")

# Pre-treatment SDs
aze_pre_log <- balanced$log_reg[balanced$iso3 == "AZE" & balanced$year < 2013]
sd_y_logreg <- sd(aze_pre_log)

goveff_pre <- balanced$govt_effectiveness[balanced$year < 2013 & !is.na(balanced$govt_effectiveness)]
sd_y_goveff <- sd(goveff_pre)

corr_pre <- balanced$corruption_control[balanced$year < 2013 & !is.na(balanced$corruption_control)]
sd_y_corr <- sd(corr_pre)

# Coefficients
beta_logreg <- coef(main_results$did_reg_log)["aze_post"]
se_logreg <- sqrt(diag(vcov(main_results$did_reg_log)))["aze_post"]
sde_logreg <- beta_logreg / sd_y_logreg
sde_se_logreg <- se_logreg / sd_y_logreg

beta_goveff <- coef(main_results$did_goveff)["aze_post"]
se_goveff <- sqrt(diag(vcov(main_results$did_goveff)))["aze_post"]
sde_goveff <- beta_goveff / sd_y_goveff
sde_se_goveff <- se_goveff / sd_y_goveff

beta_corr <- coef(main_results$did_corr)["aze_post"]
se_corr <- sqrt(diag(vcov(main_results$did_corr)))["aze_post"]
sde_corr <- beta_corr / sd_y_corr
sde_se_corr <- se_corr / sd_y_corr

classify <- function(sde) {
  if (is.na(sde)) return("---")
  a <- abs(sde)
  if (a < 0.005) return("Null")
  if (a < 0.05) return(ifelse(sde > 0, "Small positive", "Small negative"))
  if (a < 0.15) return(ifelse(sde > 0, "Moderate positive", "Moderate negative"))
  return(ifelse(sde > 0, "Large positive", "Large negative"))
}

# Panel B: restricted donor pool
rest_beta <- coef(robustness$restricted)["aze_post"]
rest_se_val <- sqrt(diag(vcov(robustness$restricted)))["aze_post"]
sde_rest <- rest_beta / sd_y_logreg
sde_se_rest <- rest_se_val / sd_y_logreg

fmt <- function(x, d = 3) formatC(x, format = "f", digits = d)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Azerbaijan. ",
  "\\textbf{Research question:} Does centralizing and digitizing government services through a one-stop-shop network improve governance quality and reduce corruption? ",
  "\\textbf{Policy mechanism:} The ASAN reform bundled approximately 360 government services under electronic one-stop-shop centers with logged electronic transactions and real-time performance dashboards, replacing discretionary face-to-face interactions between citizens and bureaucrats. ",
  "\\textbf{Outcome definition:} Log new business registrations (annual count of formally registered businesses, IC.BUS.NREG from WDI); government effectiveness (composite index from Worldwide Governance Indicators, scale $-$2.5 to $+$2.5); control of corruption (composite WGI index). ",
  "\\textbf{Treatment:} Binary; ASAN became operational in December 2012. ",
  "\\textbf{Data:} World Development Indicators and Worldwide Governance Indicators, 2008--2020, country-year panel. ",
  "\\textbf{Method:} Two-way fixed effects difference-in-differences with country and year fixed effects; standard errors clustered at country level; permutation inference for single-treated-unit p-values. ",
  "\\textbf{Sample:} 10 Former Soviet and regional comparator countries (one treated, nine donors); 5 pre-treatment years, 8 post-treatment years; restricted donors in Panel B limited to 4 Caucasus and Central Asian countries. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\textit{Panel A: Pooled} & & & & & & \\\\",
  sprintf("Log registrations & %s & %s & %s & %s & %s & %s \\\\",
    fmt(beta_logreg), fmt(se_logreg), fmt(sd_y_logreg),
    fmt(sde_logreg), fmt(sde_se_logreg), classify(sde_logreg)),
  sprintf("Government effectiveness & %s & %s & %s & %s & %s & %s \\\\",
    fmt(beta_goveff), fmt(se_goveff), fmt(sd_y_goveff),
    fmt(sde_goveff), fmt(sde_se_goveff), classify(sde_goveff)),
  sprintf("Control of corruption & %s & %s & %s & %s & %s & %s \\\\",
    fmt(beta_corr), fmt(se_corr), fmt(sd_y_corr),
    fmt(sde_corr), fmt(sde_se_corr), classify(sde_corr)),
  " & & & & & & \\\\",
  "\\textit{Panel B: Heterogeneous} & & & & & & \\\\",
  sprintf("Log reg.\\ (restricted donors) & %s & %s & %s & %s & %s & %s \\\\",
    fmt(rest_beta), fmt(rest_se_val), fmt(sd_y_logreg),
    fmt(sde_rest), fmt(sde_se_rest), classify(sde_rest)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, file.path(table_dir, "tabF1_sde.tex"))
cat("Table F1 saved.\n")

cat("\n=== All tables generated ===\n")
cat(sprintf("Tables: %s\n", paste(list.files(table_dir), collapse = ", ")))
