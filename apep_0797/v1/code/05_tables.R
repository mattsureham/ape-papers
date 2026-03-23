# 05_tables.R — Generate all tables (including SDE appendix)
# APEP paper apep_0797: ECOWAS Sanctions and Food Market Fragmentation in Niger

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# Load model objects
load(file.path(data_dir, "models.RData"))
load(file.path(data_dir, "robustness.RData"))
load(file.path(data_dir, "pre_stats.RData"))

# ======================================================================
# TABLE 1: Summary Statistics
# ======================================================================
message("=== Table 1: Summary Statistics ===")

dt <- fread(file.path(data_dir, "analysis_panel.csv"))
dt[, date_parsed := as.Date(date_parsed)]

# Focus on rice and millet
dt_summ <- dt[commodity_clean %in% c("Rice (imported)", "Millet")]
dt_summ[, sanctions_period := factor(
  fcase(
    date_parsed < "2023-08-01", "Pre-sanctions",
    date_parsed >= "2023-08-01" & date_parsed < "2024-02-01", "Full sanctions",
    date_parsed >= "2024-02-01", "Post-partial-lift"
  ),
  levels = c("Pre-sanctions", "Full sanctions", "Post-partial-lift")
)]

summ_stats <- dt_summ[, .(
  Mean = round(mean(price, na.rm = TRUE), 1),
  SD = round(sd(price, na.rm = TRUE), 1),
  Min = round(min(price, na.rm = TRUE), 1),
  Max = round(max(price, na.rm = TRUE), 1),
  N = .N,
  Markets = length(unique(market))
), by = .(Country = country, Commodity = commodity_clean, Period = sanctions_period)]

summ_stats <- summ_stats[order(Country, Commodity, Period)]

# Generate LaTeX
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Food Prices by Country, Commodity, and Sanctions Period}",
  "\\label{tab:summary}",
  "\\small",
  "\\begin{tabular}{llcrrrrrr}",
  "\\toprule",
  "Country & Commodity & Period & Mean & SD & Min & Max & N & Markets \\\\",
  "\\midrule"
)

prev_country <- ""
prev_commodity <- ""
for (i in seq_len(nrow(summ_stats))) {
  row <- summ_stats[i]
  c_disp <- ifelse(row$Country != prev_country, row$Country, "")
  cm_disp <- ifelse(row$Commodity != prev_commodity, row$Commodity, "")
  if (row$Country != prev_country && i > 1) {
    tab1_lines <- c(tab1_lines, "\\midrule")
  }
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %s & %s & %s & %s & %s & %s & %s & %s \\\\",
    c_disp, cm_disp, row$Period,
    format(row$Mean, big.mark = ","),
    format(row$SD, big.mark = ","),
    format(row$Min, big.mark = ","),
    format(row$Max, big.mark = ","),
    format(row$N, big.mark = ","),
    row$Markets
  ))
  prev_country <- row$Country
  prev_commodity <- row$Commodity
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Prices in XOF (West African CFA franc) per kilogram from WFP VAM market monitoring. Pre-sanctions: January 2021--July 2023. Full sanctions: August 2023--January 2024. Post-partial-lift: February 2024--December 2024. ECOWAS imposed trade sanctions on Niger on August 6, 2023, following the July 26 military coup.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab1_lines, file.path(tables_dir, "tab1_summary.tex"))
message("Table 1 saved.")

# ======================================================================
# TABLE 2: Main Results (Triple-Difference)
# ======================================================================
message("=== Table 2: Main Results ===")

tab2_models <- list(
  "(1)" = m1,
  "(2)" = m2,
  "(3)" = m3,
  "(4)" = m5
)

# Custom coefficient names
options("modelsummary_format_numeric_latex" = "plain")

cm2 <- c(
  "tradable" = "Tradable",
  "tradable:post_sanctions" = "Tradable $\\times$ Post",
  "niger:post_sanctions" = "Niger $\\times$ Post",
  "niger:tradable:post_sanctions" = "Niger $\\times$ Tradable $\\times$ Post",
  "niger:tradable:full_sanctions" = "Niger $\\times$ Tradable $\\times$ Full Sanctions",
  "niger:tradable:post_lift" = "Niger $\\times$ Tradable $\\times$ Post-Lift"
)

gm2 <- list(
  list("raw" = "nobs", "clean" = "Observations", "fmt" = function(x) format(round(x), big.mark = ",")),
  list("raw" = "r.squared.within", "clean" = "Within $R^2$", "fmt" = 3),
  list("raw" = "FE: market_commodity", "clean" = "Market-Commodity FE", "fmt" = function(x) ifelse(x > 0, "\\checkmark", "")),
  list("raw" = "FE: ym", "clean" = "Month FE", "fmt" = function(x) ifelse(x > 0, "\\checkmark", "")),
  list("raw" = "FE: market", "clean" = "Market FE", "fmt" = function(x) ifelse(x > 0, "\\checkmark", "")),
  list("raw" = "FE: market_ym", "clean" = "Market-Month FE", "fmt" = function(x) ifelse(x > 0, "\\checkmark", "")),
  list("raw" = "FE: commodity_ym", "clean" = "Commodity-Month FE", "fmt" = function(x) ifelse(x > 0, "\\checkmark", ""))
)

message("Generating Table 2 manually...")

# Extract coefficients and SEs
get_coef_se <- function(model, coef_name) {
  idx <- grep(coef_name, names(coef(model)), fixed = TRUE)
  if (length(idx) == 0) return(c(NA, NA, NA))
  c(coef(model)[idx[1]], se(model)[idx[1]], pvalue(model)[idx[1]])
}

stars_fn <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.1) return("$^{*}$")
  return("")
}

fmt_coef <- function(vals) {
  if (is.na(vals[1])) return(c("", ""))
  c(
    paste0(formatC(vals[1], format = "f", digits = 3), stars_fn(vals[3])),
    paste0("(", formatC(vals[2], format = "f", digits = 3), ")")
  )
}

# Model 1: tradable:post_sanctions
m1_tp <- get_coef_se(m1, "tradable:post_sanctions")
# Model 2: niger:tradable:post_sanctions, niger:post_sanctions, tradable:post_sanctions
m2_ntp <- get_coef_se(m2, "niger:tradable:post_sanctions")
m2_np <- get_coef_se(m2, "niger:post_sanctions")
m2_tp <- get_coef_se(m2, "tradable:post_sanctions")
# Model 3: niger:tradable:post_sanctions
m3_ntp <- get_coef_se(m3, "niger:tradable:post_sanctions")
# Model 5: full_sanctions and post_lift
m5_fs <- get_coef_se(m5, "niger:tradable:full_sanctions")
m5_pl <- get_coef_se(m5, "niger:tradable:post_lift")

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{The Tradability Tax: Effect of ECOWAS Sanctions on Food Prices}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Niger DiD & Triple-Diff & Saturated & Intensity \\\\",
  "\\midrule",
  sprintf("Tradable $\\times$ Post & %s & & & \\\\", fmt_coef(m1_tp)[1]),
  sprintf(" & %s & & & \\\\", fmt_coef(m1_tp)[2]),
  sprintf("Niger $\\times$ Post & & %s & & \\\\", fmt_coef(m2_np)[1]),
  sprintf(" & & %s & & \\\\", fmt_coef(m2_np)[2]),
  sprintf("Tradable $\\times$ Post & & %s & & \\\\", fmt_coef(m2_tp)[1]),
  sprintf(" & & %s & & \\\\", fmt_coef(m2_tp)[2]),
  sprintf("Niger $\\times$ Tradable $\\times$ Post & & %s & %s & \\\\",
    fmt_coef(m2_ntp)[1], fmt_coef(m3_ntp)[1]),
  sprintf(" & & %s & %s & \\\\",
    fmt_coef(m2_ntp)[2], fmt_coef(m3_ntp)[2]),
  sprintf("Niger $\\times$ Trad. $\\times$ Full Sanctions & & & & %s \\\\", fmt_coef(m5_fs)[1]),
  sprintf(" & & & & %s \\\\", fmt_coef(m5_fs)[2]),
  sprintf("Niger $\\times$ Trad. $\\times$ Post-Lift & & & & %s \\\\", fmt_coef(m5_pl)[1]),
  sprintf(" & & & & %s \\\\", fmt_coef(m5_pl)[2]),
  "\\midrule",
  sprintf("Observations & %s & %s & %s & %s \\\\",
    format(nobs(m1), big.mark = ","),
    format(nobs(m2), big.mark = ","),
    format(nobs(m3), big.mark = ","),
    format(nobs(m5), big.mark = ",")),
  sprintf("Within $R^2$ & %s & %s & %s & %s \\\\",
    formatC(fitstat(m1, "wr2")[[1]], format = "f", digits = 3),
    formatC(fitstat(m2, "wr2")[[1]], format = "f", digits = 3),
    formatC(fitstat(m3, "wr2")[[1]], format = "f", digits = 3),
    formatC(fitstat(m5, "wr2")[[1]], format = "f", digits = 3)),
  "Market FE & \\checkmark & & & \\\\",
  "Market-Commodity FE & & \\checkmark & \\checkmark & \\checkmark \\\\",
  "Month FE & \\checkmark & \\checkmark & & \\\\",
  "Market-Month FE & & & \\checkmark & \\checkmark \\\\",
  "Commodity-Month FE & & & \\checkmark & \\checkmark \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Dependent variable: log price (XOF/kg). Standard errors clustered at the market level in parentheses. Column (1): Niger-only DiD comparing rice (imported) to millet. Column (2): triple-difference with market-commodity and month fixed effects. Column (3): saturated triple-difference. Column (4): saturated model distinguishing full sanctions (August 2023--January 2024) from partial-lift period (February 2024 onward). $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab2_lines, file.path(tables_dir, "tab2_main.tex"))
message("Table 2 saved.")

# ======================================================================
# TABLE 3: Robustness — Alternative Control Commodities
# ======================================================================
message("=== Table 3: Robustness ===")

tab3_models <- list(
  "(1) Millet" = m2,
  "(2) Sorghum" = r2a,
  "(3) Maize" = r2b,
  "(4) Excl. Niamey" = r5
)

cm3 <- c(
  "niger:tradable:post_sanctions" = "Niger $\\times$ Tradable $\\times$ Post"
)

gm3 <- list(
  list("raw" = "nobs", "clean" = "Observations", "fmt" = function(x) format(round(x), big.mark = ",")),
  list("raw" = "r.squared.within", "clean" = "Within $R^2$", "fmt" = 3)
)

message("Generating Table 3 manually...")

r_m2 <- get_coef_se(m2, "niger:tradable:post_sanctions")
r_r2a <- get_coef_se(r2a, "niger:tradable:post_sanctions")
r_r2b <- get_coef_se(r2b, "niger:tradable:post_sanctions")
r_r5 <- get_coef_se(r5, "niger:tradable:post_sanctions")

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness: Alternative Control Commodities and Sample Restrictions}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Millet & Sorghum & Maize & Excl.\\ Niamey \\\\",
  "\\midrule",
  sprintf("Niger $\\times$ Tradable $\\times$ Post & %s & %s & %s & %s \\\\",
    fmt_coef(r_m2)[1], fmt_coef(r_r2a)[1], fmt_coef(r_r2b)[1], fmt_coef(r_r5)[1]),
  sprintf(" & %s & %s & %s & %s \\\\",
    fmt_coef(r_m2)[2], fmt_coef(r_r2a)[2], fmt_coef(r_r2b)[2], fmt_coef(r_r5)[2]),
  "\\midrule",
  sprintf("Observations & %s & %s & %s & %s \\\\",
    format(nobs(m2), big.mark = ","),
    format(nobs(r2a), big.mark = ","),
    format(nobs(r2b), big.mark = ","),
    format(nobs(r5), big.mark = ",")),
  sprintf("Within $R^2$ & %s & %s & %s & %s \\\\",
    formatC(fitstat(m2, "wr2")[[1]], format = "f", digits = 3),
    formatC(fitstat(r2a, "wr2")[[1]], format = "f", digits = 3),
    formatC(fitstat(r2b, "wr2")[[1]], format = "f", digits = 3),
    formatC(fitstat(r5, "wr2")[[1]], format = "f", digits = 3)),
  "Market-Commodity FE & \\checkmark & \\checkmark & \\checkmark & \\checkmark \\\\",
  "Month FE & \\checkmark & \\checkmark & \\checkmark & \\checkmark \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Dependent variable: log price (XOF/kg). Standard errors clustered at the market level. The control commodity varies: (1) millet (baseline), (2) sorghum, (3) maize, (4) millet excluding Niamey. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab3_lines, file.path(tables_dir, "tab3_robustness.tex"))
message("Table 3 saved.")

# ======================================================================
# TABLE 4: Placebo and Permutation Tests
# ======================================================================
message("=== Table 4: Placebo and Permutation ===")

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Placebo and Permutation Tests}",
  "\\label{tab:placebo}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & Placebo (Aug 2022) & Permutation Inference \\\\",
  "\\midrule",
  sprintf("Coefficient & %s & %s \\\\",
    formatC(coef(r1)[[1]], format = "f", digits = 3),
    formatC(actual_coef, format = "f", digits = 3)),
  sprintf("Standard error & (%s) & --- \\\\",
    formatC(se(r1)[[1]], format = "f", digits = 3)),
  sprintf("$p$-value (conventional) & %s & --- \\\\",
    formatC(pvalue(r1)[[1]], format = "f", digits = 3)),
  sprintf("$p$-value (permutation) & --- & %s \\\\",
    formatC(perm_pval, format = "f", digits = 3)),
  sprintf("Number of permutations & --- & %d \\\\", sum(!is.na(perm_coefs))),
  sprintf("Observations & %s & %s \\\\",
    format(nobs(r1), big.mark = ","),
    format(nobs(m2), big.mark = ",")),
  "\\midrule",
  "Market-commodity FE & \\checkmark & \\checkmark \\\\",
  "Month FE & \\checkmark & \\checkmark \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Left column: placebo test using August 2022 as a false treatment date on data restricted to January 2022--July 2023. The null coefficient confirms no pre-existing differential trend. Right column: permutation inference randomizing the Niger/Burkina Faso country assignment across markets (500 permutations). The two-sided permutation $p$-value is the share of permuted coefficients exceeding the actual estimate in absolute value.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab4_lines, file.path(tables_dir, "tab4_placebo.tex"))
message("Table 4 saved.")

# ======================================================================
# TABLE 5: Event Study Coefficients (selected months)
# ======================================================================
message("=== Table 5: Event Study ===")

es_coefs <- data.table(
  event_month = as.integer(gsub("event_month::(-?\\d+):niger_tradable", "\\1",
    names(coef(m4)))),
  coef = coef(m4),
  se = se(m4),
  pval = pvalue(m4)
)
es_coefs <- es_coefs[order(event_month)]
# Select key months: -12, -9, -6, -3, -2, 0, 1, 3, 6, 9, 12, 16
es_select <- es_coefs[event_month %in% c(-12, -9, -6, -3, -2, 0, 1, 3, 6, 9, 12, 16)]
es_select[, stars := fcase(
  pval < 0.01, "***",
  pval < 0.05, "**",
  pval < 0.1, "*",
  default = ""
)]

tab5_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study: Selected Monthly Coefficients}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Months Relative to Sanctions & Coefficient & SE & Calendar Month \\\\",
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Pre-sanctions (reference: $t = -1$, July 2023)}} \\\\"
)

month_labels <- c(
  "-12" = "Aug 2022", "-9" = "Nov 2022", "-6" = "Feb 2023",
  "-3" = "May 2023", "-2" = "Jun 2023",
  "0" = "Aug 2023", "1" = "Sep 2023", "3" = "Nov 2023",
  "6" = "Feb 2024", "9" = "May 2024", "12" = "Aug 2024", "16" = "Dec 2024"
)

for (i in seq_len(nrow(es_select))) {
  row <- es_select[i]
  if (row$event_month == 0 && i > 1) {
    tab5_lines <- c(tab5_lines,
      "\\midrule",
      "\\multicolumn{4}{l}{\\textit{Post-sanctions}} \\\\"
    )
  }
  tab5_lines <- c(tab5_lines, sprintf(
    "$t = %+d$ & %s%s & (%s) & %s \\\\",
    row$event_month,
    formatC(row$coef, format = "f", digits = 3),
    row$stars,
    formatC(row$se, format = "f", digits = 3),
    month_labels[as.character(row$event_month)]
  ))
}

tab5_lines <- c(tab5_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Coefficients from the event study specification interacting monthly dummies with Niger $\\times$ Tradable. The omitted period is $t = -1$ (July 2023). Market-commodity and commodity-month fixed effects included. Standard errors clustered at the market level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab5_lines, file.path(tables_dir, "tab5_eventstudy.tex"))
message("Table 5 saved.")

# ======================================================================
# TABLE F1: Standardized Effect Size (SDE) — MANDATORY APPENDIX
# ======================================================================
message("=== Table F1: SDE Appendix ===")

# Compute SDE for main outcomes
# Main spec (Model 3 saturated): β = 0.142, SE = 0.025
# Alternative control commodities
sde_data <- data.table(
  Outcome = c(
    "Rice (imported), log price",
    "Rice vs Sorghum, log price",
    "Rice vs Maize, log price"
  ),
  beta = c(coef(m3)[[1]], coef(r2a)[[1]], coef(r2b)[[1]]),
  se_beta = c(se(m3)[[1]], se(r2a)[[1]], se(r2b)[[1]])
)

# SD(Y) from pre-treatment period for each specification
# Main: rice + millet in Niger + BFA
sd_y_main <- sd_y_pre  # 0.3155

# For sorghum and maize specs, compute SD(ln_price) pre-treatment
dt_full <- fread(file.path(data_dir, "analysis_panel.csv"))
dt_full[, date_parsed := as.Date(date_parsed)]

sd_y_sorghum <- dt_full[commodity_clean %in% c("Rice (imported)", "Sorghum") &
  date_parsed < "2023-08-01", sd(log(price), na.rm = TRUE)]
sd_y_maize <- dt_full[commodity_clean %in% c("Rice (imported)", "Maize") &
  date_parsed < "2023-08-01", sd(log(price), na.rm = TRUE)]

sde_data[, sd_y := c(sd_y_main, sd_y_sorghum, sd_y_maize)]
sde_data[, sde := beta / sd_y]
sde_data[, se_sde := se_beta / sd_y]
sde_data[, classification := fcase(
  sde < -0.15, "Large negative",
  sde >= -0.15 & sde < -0.05, "Moderate negative",
  sde >= -0.05 & sde < -0.005, "Small negative",
  sde >= -0.005 & sde < 0.005, "Null",
  sde >= 0.005 & sde < 0.05, "Small positive",
  sde >= 0.05 & sde < 0.15, "Moderate positive",
  sde >= 0.15, "Large positive"
)]

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Niger (treated) and Burkina Faso (control). ",
  "\\textbf{Research question:} Do multilateral trade sanctions fragment food markets by differentially inflating prices of imported versus locally produced commodities? ",
  "\\textbf{Policy mechanism:} ECOWAS imposed comprehensive economic sanctions on Niger following the July 2023 military coup, including border closures with Nigeria (Niger's primary trade corridor), a trade embargo, and financial system exclusion, directly restricting the supply of imported staples while leaving locally produced grain markets operationally intact. ",
  "\\textbf{Outcome definition:} Log retail price per kilogram in XOF (West African CFA franc) for food commodities monitored by WFP across market locations. ",
  "\\textbf{Treatment:} Binary; Niger markets post-August 2023 sanctions for imported commodities (rice) relative to locally produced commodities (millet, sorghum, maize). ",
  "\\textbf{Data:} WFP Vulnerability Analysis and Mapping (VAM) food price monitoring, January 2021--December 2024, market-commodity-month level, 6,041 observations (rice-millet specification). ",
  "\\textbf{Method:} Triple-difference (country $\\times$ commodity tradability $\\times$ post-sanctions) with market-commodity and month fixed effects; standard errors clustered at the market level. ",
  "\\textbf{Sample:} Retail food prices in 55 Niger and 62 Burkina Faso markets; restricted to per-kilogram prices with non-missing observations. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Generate SDE table
tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(sde_data))) {
  row <- sde_data[i]
  tabF1_lines <- c(tabF1_lines, sprintf(
    "%s & %s & %s & %s & %s & %s & %s \\\\",
    row$Outcome,
    formatC(row$beta, format = "f", digits = 3),
    formatC(row$se_beta, format = "f", digits = 3),
    formatC(row$sd_y, format = "f", digits = 3),
    formatC(row$sde, format = "f", digits = 3),
    formatC(row$se_sde, format = "f", digits = 3),
    row$classification
  ))
}

tabF1_lines <- c(tabF1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tabF1_lines, file.path(tables_dir, "tabF1_sde.tex"))
message("Table F1 (SDE) saved.")

message("\nAll tables generated successfully.")
message(sprintf("SDE main estimate: %.3f (classification: %s)", sde_data$sde[1], sde_data$classification[1]))
