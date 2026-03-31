# 05_tables.R — Generate all LaTeX tables for apep_1215
# Tables: Summary Stats, Main Results, Event Study, Robustness, SDE

source("00_packages.R")

cat("=== Generating tables ===\n")

# --- Load all data and models ---
unemp_panel <- readRDS("../data/unemp_panel.rds")
emp_panel <- readRDS("../data/emp_panel.rds")
vv_prices <- readRDS("../data/vv_prices.rds")
m1 <- readRDS("../data/m1_level.rds")
m2 <- readRDS("../data/m2_per10eur.rds")
m3_binary <- readRDS("../data/m3_binary.rds")
m4 <- readRDS("../data/m4_employment.rds")
m_event <- readRDS("../data/m_event.rds")
m_nuts2 <- readRDS("../data/m_nuts2_cluster.rds")
robustness <- readRDS("../data/robustness.rds")
m_west <- readRDS("../data/m_west.rds")
m_east <- readRDS("../data/m_east.rds")
m_nocovid <- readRDS("../data/m_nocovid.rds")

# Helper: significance stars
get_stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("^{***}")
  if (p < 0.05) return("^{**}")
  if (p < 0.10) return("^{*}")
  return("")
}

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================
cat("--- Table 1: Summary Statistics ---\n")

pre_u <- filter(unemp_panel, post_dt == 0)
post_u <- filter(unemp_panel, post_dt == 1)
pre_e <- filter(emp_panel, post_dt == 0)
post_e <- filter(emp_panel, post_dt == 1)

tab1 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lrrrrr}",
  "\\toprule",
  " & N & Mean & SD & Min & Max \\\\",
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel A: Unemployment Rate (\\%)}} \\\\",
  sprintf("\\quad Full sample & %d & %.2f & %.2f & %.1f & %.1f \\\\",
          sum(!is.na(unemp_panel$unemp_rate)),
          mean(unemp_panel$unemp_rate, na.rm = TRUE),
          sd(unemp_panel$unemp_rate, na.rm = TRUE),
          min(unemp_panel$unemp_rate, na.rm = TRUE),
          max(unemp_panel$unemp_rate, na.rm = TRUE)),
  sprintf("\\quad Pre-reform (2010--2022) & %d & %.2f & %.2f & & \\\\",
          sum(!is.na(pre_u$unemp_rate)),
          mean(pre_u$unemp_rate, na.rm = TRUE),
          sd(pre_u$unemp_rate, na.rm = TRUE)),
  sprintf("\\quad Post-reform (2023--2024) & %d & %.2f & %.2f & & \\\\",
          sum(!is.na(post_u$unemp_rate)),
          mean(post_u$unemp_rate, na.rm = TRUE),
          sd(post_u$unemp_rate, na.rm = TRUE)),
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel B: Employment Rate (\\%, ages 15--64)}} \\\\",
  sprintf("\\quad Full sample & %d & %.2f & %.2f & %.1f & %.1f \\\\",
          sum(!is.na(emp_panel$emp_rate)),
          mean(emp_panel$emp_rate, na.rm = TRUE),
          sd(emp_panel$emp_rate, na.rm = TRUE),
          min(emp_panel$emp_rate, na.rm = TRUE),
          max(emp_panel$emp_rate, na.rm = TRUE)),
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel C: Treatment Intensity}} \\\\",
  sprintf("\\quad Pre-reform pass price (EUR/month) & %d & %.1f & %.1f & %.1f & %.1f \\\\",
          nrow(vv_prices), mean(vv_prices$pre_price), sd(vv_prices$pre_price),
          min(vv_prices$pre_price), max(vv_prices$pre_price)),
  sprintf("\\quad Effective subsidy (EUR/month) & %d & %.1f & %.1f & %.1f & %.1f \\\\",
          nrow(vv_prices), mean(vv_prices$subsidy), sd(vv_prices$subsidy),
          min(vv_prices$subsidy), max(vv_prices$subsidy)),
  sprintf("\\quad Subsidy as \\%% of pre-price & %d & %.1f & %.1f & %.1f & %.1f \\\\",
          nrow(vv_prices), mean(vv_prices$subsidy_pct), sd(vv_prices$subsidy_pct),
          min(vv_prices$subsidy_pct), max(vv_prices$subsidy_pct)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item \\textit{Notes:} Panel A reports annual unemployment rates for %d German NUTS2 regions, ages 15--74, from Eurostat (lfst\\_r\\_lfu3rt). Panel B reports annual employment rates, ages 15--64 (lfst\\_r\\_lfe2emprt). Panel C reports the cross-sectional distribution of treatment intensity: the pre-reform Verkehrsverbund monthly pass price and the effective subsidy from the Deutschlandticket ($\\max(0, \\text{pre-price} - 49)$). Regions with higher pre-reform prices received larger effective subsidies.",
          n_distinct(unemp_panel$geo)),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1, "../tables/tab1_summary.tex")
cat("  Written: tables/tab1_summary.tex\n")

# ============================================================
# TABLE 2: Main Results
# ============================================================
cat("--- Table 2: Main Results ---\n")

# Columns: (1) Subsidy level, (2) Per EUR 10, (3) Binary, (4) Employment, (5) NUTS2 cluster
models <- list(m1, m2, m3_binary, m4, m_nuts2)
coef_names <- c("treat_dt", "treat_dt_10", "treat_binary", "treat_dt_10", "treat_dt_10")
dep_labels <- c("Unemp.", "Unemp.", "Unemp.", "Empl.", "Unemp.")
treat_note <- c("EUR", "EUR 10", "Binary", "EUR 10", "EUR 10")

tab2 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of the Deutschlandticket on Regional Labor Markets}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  paste0(" & ", paste(dep_labels, collapse = " & "), " \\\\"),
  "\\midrule"
)

# Main coefficient row
coef_row <- "Subsidy $\\times$ Post"
se_row <- ""
for (i in 1:5) {
  b <- as.numeric(coef(models[[i]])[coef_names[i]])
  s <- as.numeric(se(models[[i]])[coef_names[i]])
  p <- as.numeric(pvalue(models[[i]])[coef_names[i]])
  coef_row <- paste0(coef_row, sprintf(" & $%.4f%s$", b, get_stars(p)))
  se_row <- paste0(se_row, sprintf(" & (%.4f)", s))
}

tab2 <- c(tab2,
  paste0(coef_row, " \\\\"),
  paste0(se_row, " \\\\"),
  " \\\\",
  "\\midrule",
  "Treatment unit & EUR & EUR 10 & High/Low & EUR 10 & EUR 10 \\\\",
  "Dep. variable & Unemp. & Unemp. & Unemp. & Empl. & Unemp. \\\\",
  "Region FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Clustering & NUTS1 & NUTS1 & NUTS1 & NUTS1 & NUTS2 \\\\",
  sprintf("Observations & %d & %d & %d & %d & %d \\\\",
          nobs(m1), nobs(m2), nobs(m3_binary), nobs(m4), nobs(m_nuts2)),
  sprintf("Regions & %d & %d & %d & %d & %d \\\\",
          n_distinct(unemp_panel$geo), n_distinct(unemp_panel$geo),
          n_distinct(unemp_panel$geo), n_distinct(emp_panel$geo),
          n_distinct(unemp_panel$geo)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Standard errors clustered at the NUTS1 level (16 states) in parentheses, except column~(5) which clusters at NUTS2 (38 regions). * $p<0.10$, ** $p<0.05$, *** $p<0.01$. The dependent variable is the annual regional unemployment rate (\\%, columns 1--3, 5) or employment rate (\\%, column 4). ``Subsidy'' is $\\max(0, \\text{pre-reform pass price} - 49)$. Column~(1) uses the raw EUR subsidy; (2) normalizes per EUR~10; (3) uses a binary indicator for above-median subsidy (EUR~23.5); (4) uses the employment rate as outcome; (5) uses NUTS2-level clustering. Data: Eurostat lfst\\_r\\_lfu3rt and lfst\\_r\\_lfe2emprt, 2010--2024.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2, "../tables/tab2_main.tex")
cat("  Written: tables/tab2_main.tex\n")

# ============================================================
# TABLE 3: Event Study
# ============================================================
cat("--- Table 3: Event Study ---\n")

cf <- coef(m_event)
ses <- se(m_event)
pvs <- pvalue(m_event)

# Parse event time from coefficient names
event_df <- data.frame(
  name = names(cf),
  coef = as.numeric(cf),
  se = as.numeric(ses),
  pval = as.numeric(pvs),
  stringsAsFactors = FALSE
)

# Extract the event year from names like "event_year::X:subsidy"
event_df$eq <- as.numeric(gsub(".*::(-?[0-9]+):.*", "\\1", event_df$name))
event_df <- event_df %>% arrange(eq)

tab3 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Event Study: Subsidy $\\times$ Year Interactions}",
  "\\label{tab:event}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Year relative to reform & Coefficient & SE & Calendar year \\\\",
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Pre-treatment}} \\\\"
)

for (i in 1:nrow(event_df)) {
  q <- event_df$eq[i]
  cal_year <- 2023 + q
  label <- ifelse(q < 0, sprintf("$t%d$", q), sprintf("$t+%d$", q))
  stars <- get_stars(event_df$pval[i])

  if (q == 0 && i > 1 && event_df$eq[i-1] < 0) {
    tab3 <- c(tab3, "\\midrule", "\\multicolumn{4}{l}{\\textit{Post-treatment}} \\\\")
  }

  tab3 <- c(tab3,
    sprintf("%s & $%.5f%s$ & (%.5f) & %d \\\\", label, event_df$coef[i], stars, event_df$se[i], cal_year)
  )
}

tab3 <- c(tab3,
  "\\midrule",
  "Reference period & \\multicolumn{3}{c}{$t-1$ (2022)} \\\\",
  sprintf("Region \\& year FE & \\multicolumn{3}{c}{Yes} \\\\"),
  sprintf("Clusters (NUTS1) & \\multicolumn{3}{c}{%d} \\\\", n_distinct(unemp_panel$nuts1)),
  sprintf("Observations & \\multicolumn{3}{c}{%d} \\\\", nobs(m_event)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each coefficient is the interaction of subsidy intensity (EUR/month) with a year-relative-to-reform dummy. The reference period is $t-1$ (2022), the year before the Deutschlandticket launched. Pre-treatment coefficients test for differential trends between high- and low-subsidy regions. Standard errors clustered at NUTS1 (16 states). * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3, "../tables/tab3_event.tex")
cat("  Written: tables/tab3_event.tex\n")

# ============================================================
# TABLE 4: Robustness
# ============================================================
cat("--- Table 4: Robustness ---\n")

b_main <- as.numeric(coef(m2)["treat_dt_10"])
se_main <- as.numeric(se(m2)["treat_dt_10"])
p_main <- as.numeric(pvalue(m2)["treat_dt_10"])

b_nuts2 <- as.numeric(coef(m_nuts2)["treat_dt_10"])
se_nuts2 <- as.numeric(se(m_nuts2)["treat_dt_10"])
p_nuts2 <- as.numeric(pvalue(m_nuts2)["treat_dt_10"])

tab4 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robust}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Specification & Coefficient & SE & $p$-value \\\\",
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel A: Inference}} \\\\",
  sprintf("\\quad NUTS1 clustering (baseline) & $%.4f%s$ & (%.4f) & %.3f \\\\",
          b_main, get_stars(p_main), se_main, p_main),
  sprintf("\\quad NUTS2 clustering & $%.4f%s$ & (%.4f) & %.3f \\\\",
          b_nuts2, get_stars(p_nuts2), se_nuts2, p_nuts2),
  sprintf("\\quad Randomization inference & $%.4f$ & --- & %.3f \\\\",
          robustness$ri$observed, robustness$ri$p_value),
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel B: Sample}} \\\\",
  sprintf("\\quad Excluding COVID (2020--2021) & $%.4f%s$ & (%.4f) & %.3f \\\\",
          robustness$no_covid$coef,
          get_stars(robustness$no_covid$pval),
          robustness$no_covid$se,
          robustness$no_covid$pval),
  sprintf("\\quad Jackknife range & \\multicolumn{3}{c}{$[%.4f, %.4f]$} \\\\",
          min(robustness$jackknife$coefs), max(robustness$jackknife$coefs)),
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel C: Pre-trends}} \\\\",
  sprintf("\\quad Subsidy/10 $\\times$ trend (pre-period) & $%.5f$ & (%.5f) & %.3f \\\\",
          robustness$pretrend$coef, robustness$pretrend$se, robustness$pretrend$pval),
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel D: Heterogeneity}} \\\\",
  sprintf("\\quad West Germany only & $%.4f%s$ & (%.4f) & \\\\",
          robustness$west$coef, get_stars(2 * pnorm(-abs(robustness$west$coef / robustness$west$se))),
          robustness$west$se),
  sprintf("\\quad East Germany only & $%.4f%s$ & (%.4f) & \\\\",
          robustness$east$coef, get_stars(2 * pnorm(-abs(robustness$east$coef / robustness$east$se))),
          robustness$east$se),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} All specifications include region and year fixed effects. The dependent variable is the annual unemployment rate (\\%). The treatment variable is Subsidy/10 $\\times$ Post unless noted. Panel A compares inference: NUTS1 clustering (16 states), NUTS2 clustering (38 regions), and randomization inference (1,000 permutations of subsidy across regions). Panel B tests sample sensitivity: excluding COVID years and leave-one-NUTS1-out jackknife range. Panel C tests differential pre-trends: subsidy $\\times$ linear trend in the pre-treatment period (2010--2022). Panel D splits the sample into West (30 regions) and East Germany (8 regions, including Berlin). * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4, "../tables/tab4_robustness.tex")
cat("  Written: tables/tab4_robustness.tex\n")

# ============================================================
# TABLE F1: Standardized Effect Sizes (SDE)
# ============================================================
cat("--- Table F1: SDE ---\n")

# Pooled unemployment
beta_u <- as.numeric(coef(m2)["treat_dt_10"])
se_u <- as.numeric(se(m2)["treat_dt_10"])
sd_y_u <- sd(unemp_panel$unemp_rate, na.rm = TRUE)
# SD of treatment among post-treatment obs
sd_x_u <- sd(unemp_panel$treat_dt_10[unemp_panel$post_dt == 1], na.rm = TRUE)
sde_u <- beta_u * sd_x_u / sd_y_u
se_sde_u <- se_u * sd_x_u / sd_y_u

# Pooled employment
beta_e <- as.numeric(coef(m4)["treat_dt_10"])
se_e <- as.numeric(se(m4)["treat_dt_10"])
sd_y_e <- sd(emp_panel$emp_rate, na.rm = TRUE)
sd_x_e <- sd(emp_panel$treat_dt_10[emp_panel$post_dt == 1], na.rm = TRUE)
sde_e <- beta_e * sd_x_e / sd_y_e
se_sde_e <- se_e * sd_x_e / sd_y_e

# West heterogeneity
west_data <- filter(unemp_panel, !east)
sd_y_w <- sd(west_data$unemp_rate, na.rm = TRUE)
sd_x_w <- sd(west_data$treat_dt_10[west_data$post_dt == 1], na.rm = TRUE)
beta_w <- robustness$west$coef
se_w <- robustness$west$se
sde_w <- beta_w * sd_x_w / sd_y_w
se_sde_w <- se_w * sd_x_w / sd_y_w

# East heterogeneity
east_data <- filter(unemp_panel, east)
sd_y_east <- sd(east_data$unemp_rate, na.rm = TRUE)
sd_x_east <- sd(east_data$treat_dt_10[east_data$post_dt == 1], na.rm = TRUE)
beta_east <- robustness$east$coef
se_east_val <- robustness$east$se
sde_east <- beta_east * sd_x_east / sd_y_east
se_sde_east <- se_east_val * sd_x_east / sd_y_east

classify <- function(s) {
  if (is.na(s)) return("---")
  if (s < -0.15) return("Large negative")
  if (s < -0.05) return("Moderate negative")
  if (s < -0.005) return("Small negative")
  if (s < 0.005) return("Null")
  if (s < 0.05) return("Small positive")
  if (s < 0.15) return("Moderate positive")
  return("Large positive")
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Germany. ",
  "\\textbf{Research question:} Does a uniform national transit pass that replaced heterogeneous local pricing reduce regional unemployment in regions that received larger effective price reductions? ",
  "\\textbf{Policy mechanism:} The Deutschlandticket (May 2023) replaced fragmented Verkehrsverbund monthly passes (EUR~55--106/month) with a single EUR~49 nationwide pass, ",
  "generating effective commuting cost reductions of EUR~6--57/month that varied across regions based on legacy pricing, thereby differentially lowering the cost of job search and commuting for workers in high-price areas. ",
  "\\textbf{Outcome definition:} Annual unemployment rate (\\%) for ages 15--74 from the Eurostat Labour Force Survey (lfst\\_r\\_lfu3rt), measuring the share of the labor force that is without work and actively seeking employment. ",
  "\\textbf{Treatment:} Continuous --- effective subsidy per EUR~10/month, defined as $\\max(0, \\text{pre-reform pass price} - 49) / 10$. ",
  sprintf("\\textbf{Data:} Eurostat regional labour force statistics, 2010--2024, NUTS2 region $\\times$ year, N~=~%d. ", nobs(m2)),
  "\\textbf{Method:} Two-way fixed effects (region + year), treatment-intensity difference-in-differences, standard errors clustered at NUTS1 (16 German states). ",
  "\\textbf{Sample:} All 38 German NUTS2 regions with matched Verkehrsverbund pricing data, 2010--2024. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($Y$) is the unconditional ",
  "standard deviation and SD($X$) is the standard deviation of the treatment variable among post-treatment observations. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{llcccccl}",
  "\\toprule",
  "Outcome & Spec. & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("Unemp. rate & Sub./10$\\times$Post & $%.4f$ & $%.2f$ & $%.2f$ & $%.4f$ & $%.4f$ & %s \\\\",
          beta_u, sd_x_u, sd_y_u, sde_u, se_sde_u, classify(sde_u)),
  sprintf("Empl. rate & Sub./10$\\times$Post & $%.4f$ & $%.2f$ & $%.2f$ & $%.4f$ & $%.4f$ & %s \\\\",
          beta_e, sd_x_e, sd_y_e, sde_e, se_sde_e, classify(sde_e)),
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous (East vs.\\ West Germany)}} \\\\",
  sprintf("Unemp. (West) & Sub./10$\\times$Post & $%.4f$ & $%.2f$ & $%.2f$ & $%.4f$ & $%.4f$ & %s \\\\",
          beta_w, sd_x_w, sd_y_w, sde_w, se_sde_w, classify(sde_w)),
  sprintf("Unemp. (East) & Sub./10$\\times$Post & $%.4f$ & $%.2f$ & $%.2f$ & $%.4f$ & $%.4f$ & %s \\\\",
          beta_east, sd_x_east, sd_y_east, sde_east, se_sde_east, classify(sde_east)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tabF1, "../tables/tabF1_sde.tex")
cat("  Written: tables/tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
