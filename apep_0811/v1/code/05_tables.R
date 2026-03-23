# 05_tables.R — Generate all LaTeX tables for apep_0811
# Uses England-only panel (excluding Wales from treated group)

source("00_packages.R")

load("../data/england_only_results.RData")
load("../data/robustness_results.RData")
# Also load original for some robustness specs
load("../data/main_results.RData")

tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

# ---------------------------------------------------------------
# Table 1: Summary Statistics (England-only, pre-treatment)
# ---------------------------------------------------------------
cat("Generating Table 1: Summary Statistics...\n")

panel[, inc_month := as.Date(inc_month)]
pre <- panel[post == 0]

ss <- pre[, .(
  Mean = mean(incorporations),
  SD = sd(incorporations),
  Min = min(incorporations),
  Max = max(incorporations)
), by = .(country, sector)]
setorder(ss, sector, country)

sector_labels <- c(
  "FoodService" = "Food Service (SIC 56)",
  "IT" = "IT Services (SIC 62)",
  "MotorTrade" = "Motor Trade (SIC 45)",
  "PersonalServices" = "Personal Services (SIC 96)",
  "RealEstate" = "Real Estate (SIC 68)",
  "Retail" = "Retail Trade (SIC 47)"
)

tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: Monthly New Business Incorporations (Pre-Treatment)}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{llrrrr}",
  "\\toprule",
  "Sector & Country & Mean & Std.\\ Dev. & Min & Max \\\\",
  "\\midrule"
)

for (sec in unique(ss$sector)) {
  for (cty in c("England", "Scotland")) {
    row <- ss[sector == sec & country == cty]
    sec_label <- ifelse(cty == "England", sector_labels[sec], "")
    tab1_lines <- c(tab1_lines, sprintf(
      "%s & %s & %s & %s & %d & %d \\\\",
      sec_label, cty,
      format(round(row$Mean, 1), nsmall = 1),
      format(round(row$SD, 1), nsmall = 1),
      row$Min, row$Max
    ))
  }
  if (sec != tail(unique(ss$sector), 1)) {
    tab1_lines <- c(tab1_lines, "\\addlinespace")
  }
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each row reports the distribution of monthly new company incorporations during the pre-treatment period (January 2019--March 2022, $T = 39$ months). Data from Companies House bulk snapshot (March 2026). England excludes Wales (classified via company number prefix, registered office address, and postcode area). Scotland identified by SC prefix. Sector defined by primary SIC code.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(tables_dir, "tab1_summary.tex"))

# ---------------------------------------------------------------
# Table 2: Main Results (England-only)
# ---------------------------------------------------------------
cat("Generating Table 2: Main Results...\n")

get_stars <- function(p) {
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

extract_row <- function(mod, varname = "treat_ddd") {
  b <- coef(mod)[varname]
  s <- se(mod)[varname]
  p <- pvalue(mod)[varname]
  n <- nobs(mod)
  list(b = b, s = s, p = p, n = n, stars = get_stars(p))
}

# Re-run variants on England-only panel
panel_fr <- panel[sector %in% c("FoodService", "Retail")]
panel_fi <- panel[sector %in% c("FoodService", "IT")]

m_eng2 <- fepois(incorporations ~ treat_ddd | cs + ct + st,
                 data = panel, vcov = "hetero")

panel[, time_index := as.integer(inc_month - min(inc_month))]
m_eng3 <- feols(log_inc ~ treat_ddd + i(sector, time_index) | cs + ct,
                data = panel, vcov = "hetero")

panel_no_ret <- panel[sector != "Retail"]
m_eng4 <- feols(log_inc ~ treat_ddd | cs + ct + st,
                data = panel_no_ret, vcov = "hetero")

panel_no_re <- panel[sector != "RealEstate"]
m_eng5 <- feols(log_inc ~ treat_ddd | cs + ct + st,
                data = panel_no_re, vcov = "hetero")

r1 <- extract_row(m_eng)
r2 <- extract_row(m_eng2)
r3 <- extract_row(m_eng3)
r4 <- extract_row(m_eng4)
r5 <- extract_row(m_eng5)

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Main Results: Triple-Difference Estimates}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  "& (1) & (2) & (3) & (4) & (5) \\\\",
  "& OLS & Poisson & Sector Trends & Drop Retail & Drop RE \\\\",
  "\\midrule",
  sprintf("England $\\times$ Food $\\times$ Post & %s%s & %s%s & %s%s & %s%s & %s%s \\\\",
          format(round(r1$b, 4), nsmall = 4), r1$stars,
          format(round(r2$b, 4), nsmall = 4), r2$stars,
          format(round(r3$b, 4), nsmall = 4), r3$stars,
          format(round(r4$b, 4), nsmall = 4), r4$stars,
          format(round(r5$b, 4), nsmall = 4), r5$stars),
  sprintf("& (%s) & (%s) & (%s) & (%s) & (%s) \\\\",
          format(round(r1$s, 4), nsmall = 4),
          format(round(r2$s, 4), nsmall = 4),
          format(round(r3$s, 4), nsmall = 4),
          format(round(r4$s, 4), nsmall = 4),
          format(round(r5$s, 4), nsmall = 4)),
  "\\addlinespace",
  "Country $\\times$ Sector FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Country $\\times$ Month FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Sector $\\times$ Month FE & Yes & Yes & No & Yes & Yes \\\\",
  "Sector-specific trends & No & No & Yes & No & No \\\\",
  "\\addlinespace",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
          format(r1$n, big.mark = ","),
          format(r2$n, big.mark = ","),
          format(r3$n, big.mark = ","),
          format(r4$n, big.mark = ","),
          format(r5$n, big.mark = ",")),
  sprintf("Permutation $p$-value & \\multicolumn{5}{c}{%.3f (999 draws, sector reassignment)} \\\\",
          perm_p),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Heteroskedasticity-robust standard errors in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. The dependent variable is log(monthly incorporations $+$ 1) in columns (1), (3)--(5) and the count of monthly incorporations in column (2). The unit of observation is country $\\times$ sector $\\times$ month. England excludes Wales (which did not adopt the mandate). The permutation $p$-value reports the fraction of 999 random sector-label reassignments that produce a triple-difference coefficient at least as large in absolute value as the actual estimate.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(tables_dir, "tab2_main.tex"))

# ---------------------------------------------------------------
# Table 3: Robustness (re-run on England-only panel)
# ---------------------------------------------------------------
cat("Generating Table 3: Robustness...\n")

covid_start <- as.Date("2020-03-01")
covid_end   <- as.Date("2021-06-01")
panel_nocov <- panel[inc_month < covid_start | inc_month > covid_end]
m_nocov_eng <- feols(log_inc ~ treat_ddd | cs + ct + st,
                     data = panel_nocov, vcov = "hetero")

panel_post21 <- panel[inc_month >= as.Date("2021-07-01")]
m_post21_eng <- feols(log_inc ~ treat_ddd | cs + ct + st,
                      data = panel_post21, vcov = "hetero")

panel[, qtr := floor_date(inc_month, "quarter")]
panel_q <- panel[, .(
  incorporations = sum(incorporations),
  log_inc = log(sum(incorporations) + 1),
  england = first(england),
  food = first(food),
  post = max(post),
  treat_ddd = first(england) * first(food) * max(post)
), by = .(country, sector, qtr)]
panel_q[, cs := paste0(country, "_", sector)]
panel_q[, ct := paste0(country, "_", qtr)]
panel_q[, st := paste0(sector, "_", qtr)]
m_qtr_eng <- feols(log_inc ~ treat_ddd | cs + ct + st,
                   data = panel_q, vcov = "hetero")

panel_pre <- panel[inc_month < as.Date("2022-04-01")]
panel_pre[, post_placebo := as.integer(inc_month >= as.Date("2020-04-01"))]
panel_pre[, treat_placebo := england * food * post_placebo]
m_placebo_eng <- feols(log_inc ~ treat_placebo | cs + ct + st,
                       data = panel_pre, vcov = "hetero")

panel[, re := as.integer(sector == "RealEstate")]
panel[, treat_re := england * re * post]
m_re_eng <- feols(log_inc ~ treat_re | cs + ct + st,
                  data = panel, vcov = "hetero")

rob_specs <- list(
  list(name = "Main (all sectors)", mod = m_eng, var = "treat_ddd"),
  list(name = "Exclude COVID months", mod = m_nocov_eng, var = "treat_ddd"),
  list(name = "Post-2021 sample only", mod = m_post21_eng, var = "treat_ddd"),
  list(name = "Quarterly aggregation", mod = m_qtr_eng, var = "treat_ddd"),
  list(name = "Placebo date (Apr 2020)", mod = m_placebo_eng, var = "treat_placebo"),
  list(name = "Placebo sector (Real Estate)", mod = m_re_eng, var = "treat_re")
)

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robust}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Specification & $\\hat{\\beta}$ & SE & $N$ & 95\\% CI \\\\",
  "\\midrule"
)

for (spec in rob_specs) {
  r <- extract_row(spec$mod, spec$var)
  ci_lo <- r$b - 1.96 * r$s
  ci_hi <- r$b + 1.96 * r$s
  tab3_lines <- c(tab3_lines, sprintf(
    "%s & %s%s & (%s) & %s & [%s, %s] \\\\",
    spec$name,
    format(round(r$b, 4), nsmall = 4), r$stars,
    format(round(r$s, 4), nsmall = 4),
    format(r$n, big.mark = ","),
    format(round(ci_lo, 3), nsmall = 3),
    format(round(ci_hi, 3), nsmall = 3)
  ))
}

tab3_lines <- c(tab3_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each row reports the triple-difference coefficient from a separate regression. Heteroskedasticity-robust standard errors. England excludes Wales throughout. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(tables_dir, "tab3_robust.tex"))

# ---------------------------------------------------------------
# Table 4: Event Study
# ---------------------------------------------------------------
cat("Generating Table 4: Event Study...\n")

ct_es <- coeftable(m_es_eng)
es_df <- data.table(
  quarter = as.integer(str_extract(rownames(ct_es), "-?\\d+")),
  coef = ct_es[, 1],
  se = ct_es[, 2],
  pval = ct_es[, 4]
)
setorder(es_df, quarter)

tab4_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Event Study: Quarterly Triple-Difference Coefficients}",
  "\\label{tab:eventstudy}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Quarter Relative to Treatment & Coefficient & Std.\\ Error \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(es_df))) {
  q <- es_df$quarter[i]
  label <- ifelse(q < 0, sprintf("$q = %d$", q), sprintf("$q = +%d$", q))
  stars <- get_stars(es_df$pval[i])

  if (i > 1 && es_df$quarter[i - 1] < 0 && q >= 0) {
    tab4_lines <- c(tab4_lines,
                    "\\midrule",
                    "\\multicolumn{3}{l}{\\textit{Post-treatment}} \\\\",
                    "\\midrule")
  }

  tab4_lines <- c(tab4_lines, sprintf(
    "%s & %s%s & (%s) \\\\",
    label,
    format(round(es_df$coef[i], 4), nsmall = 4), stars,
    format(round(es_df$se[i], 4), nsmall = 4)
  ))
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Coefficients from a dynamic triple-difference specification interacting quarterly relative time dummies with England $\\times$ Food Service. Quarter $q = -1$ (Jan--Mar 2022) is the reference period. Heteroskedasticity-robust standard errors. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(tables_dir, "tab4_eventstudy.tex"))

# ---------------------------------------------------------------
# Table F1: SDE
# ---------------------------------------------------------------
cat("Generating Table F1: SDE...\n")

beta_main <- coef(m_eng)["treat_ddd"]
se_main <- se(m_eng)["treat_ddd"]
sd_y <- sd(panel$log_inc)

sde_main <- beta_main / sd_y
se_sde_main <- se_main / sd_y

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

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} England (treated) vs Scotland (control); Wales excluded from the treated group as it did not adopt the mandate. ",
  "\\textbf{Research question:} Does mandatory calorie labeling for large food businesses create spillover entry deterrence for new (exempt) food service companies? ",
  "\\textbf{Policy mechanism:} The Calorie Labelling (Out of Home Sector) (England) Regulations 2022 require food businesses with 250 or more employees to display calorie information on menus, online ordering platforms, and food delivery apps; businesses below 250 employees are exempt; Scotland did not adopt the regulation, creating a cross-border natural experiment. ",
  "\\textbf{Outcome definition:} Log of monthly count of new company incorporations with SIC code 56 (food and beverage service activities), constructed from Companies House registration records. ",
  "\\textbf{Treatment:} Binary (England post-April 2022 vs all other country-time-sector cells). ",
  "\\textbf{Data:} Companies House bulk company data snapshot (March 2026), monthly panel January 2019--December 2025, unit of observation is country $\\times$ sector $\\times$ month, $N = 1{,}008$. ",
  "\\textbf{Method:} Triple-difference (country $\\times$ sector $\\times$ time) with country-sector, country-month, and sector-month fixed effects; heteroskedasticity-robust standard errors; permutation inference (sector reassignment, 999 draws, $p = 1.000$). ",
  "\\textbf{Sample:} All companies in SIC divisions 56 (food service), 47 (retail), 62 (IT), 45 (motor trade), 68 (real estate), and 96 (personal services) in England and Scotland; six placebo sectors chosen as SME-heavy service industries unaffected by calorie labeling. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation of log(monthly incorporations $+$ 1). ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  sprintf("Log incorporations & %s & %s & %s & %s & %s & %s \\\\",
          format(round(beta_main, 4), nsmall = 4),
          format(round(se_main, 4), nsmall = 4),
          format(round(sd_y, 4), nsmall = 4),
          format(round(sde_main, 4), nsmall = 4),
          format(round(se_sde_main, 4), nsmall = 4),
          classify(sde_main)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tabF1_lines, file.path(tables_dir, "tabF1_sde.tex"))

cat("\nAll tables generated successfully.\n")
