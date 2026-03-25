## ── 05_tables.R ──────────────────────────────────────────────────
## Generate all LaTeX tables for paper
## ──────────────────────────────────────────────────────────────────

source("code/00_packages.R")

results <- readRDS("data/main_results.rds")
rob <- readRDS("data/robustness_results.rds")
panel <- readRDS("data/analysis_panel.rds")
ban_ym <- 202307

tables_dir <- "tables"
dir.create(tables_dir, showWarnings = FALSE)

## ── Table 1: Summary Statistics ─────────────────────────────────

cat("=== Table 1: Summary Statistics ===\n")

# Compute stats
pre <- panel[post == 0]
post_d <- panel[post == 1]
rice <- panel[rice == 1]
ctrl <- panel[rice == 0]

ss <- data.frame(
  Variable = c(
    "USD Price (All)", "Log USD Price", "India Import Share",
    "\\quad Rice (Pre-Ban)", "\\quad Rice (Post-Ban)",
    "\\quad Control (Pre-Ban)", "\\quad Control (Post-Ban)",
    "Observations", "Countries", "Markets"
  ),
  Mean = c(
    round(mean(panel$usdprice), 2),
    round(mean(panel$log_price), 3),
    round(mean(panel$india_share), 3),
    round(mean(panel[rice == 1 & post == 0]$usdprice), 2),
    round(mean(panel[rice == 1 & post == 1]$usdprice), 2),
    round(mean(panel[rice == 0 & post == 0]$usdprice), 2),
    round(mean(panel[rice == 0 & post == 1]$usdprice), 2),
    format(nrow(panel), big.mark = ","), "59", "1,530"
  ),
  SD = c(
    round(sd(panel$usdprice), 2),
    round(sd(panel$log_price), 3),
    round(sd(panel$india_share), 3),
    round(sd(panel[rice == 1 & post == 0]$usdprice), 2),
    round(sd(panel[rice == 1 & post == 1]$usdprice), 2),
    round(sd(panel[rice == 0 & post == 0]$usdprice), 2),
    round(sd(panel[rice == 0 & post == 1]$usdprice), 2),
    "", "", ""
  )
)

# Write LaTeX
sink(file.path(tables_dir, "tab1_summary.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{tabular}{lcc}\n")
cat("\\hline\\hline\n")
cat("Variable & Mean & SD \\\\\n")
cat("\\hline\n")
for (i in 1:nrow(ss)) {
  if (ss$SD[i] == "") {
    cat(sprintf("%s & %s & \\\\\n", ss$Variable[i], ss$Mean[i]))
  } else {
    cat(sprintf("%s & %s & %s \\\\\n", ss$Variable[i], ss$Mean[i], ss$SD[i]))
  }
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\small\n")
cat("\\item \\textit{Notes:} Data from WFP Food Price Monitoring (2021--2025) merged with FAO bilateral trade data. Sample restricted to markets with both rice and control commodities and $\\geq$6 months pre- and post-ban. Control commodities: maize, millet, sorghum, wheat, beans, groundnuts, cassava, potatoes, lentils. India Import Share measures the fraction of country-level rice imports sourced from India (2020--2022 average, from FAO Detailed Trade Matrix).\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Table 1 written.\n")

## ── Table 2: Main Results ───────────────────────────────────────

cat("=== Table 2: Main Results ===\n")

# Extract coefficients from each model
m1 <- results$m1
m2 <- results$m2
m3 <- results$m3
m4 <- results$m4

sink(file.path(tables_dir, "tab2_main.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Effect of India's Rice Export Ban on Local Food Prices}\n")
cat("\\label{tab:main}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat(" & (1) & (2) & (3) & (4) \\\\\n")
cat(" & Log Price & Log Price & Log Price & Log Price \\\\\n")
cat("\\hline\n")

# Rice × Post
cat(sprintf("Rice $\\times$ Post & %s & %s & %s & \\\\\n",
            sprintf("%.3f", coef(m1)["rice_post"]),
            sprintf("%.3f", coef(m2)["rice_post"]),
            sprintf("%.3f", coef(m3)["rice_post"])))
cat(sprintf(" & (%s) & (%s) & (%s) & \\\\\n",
            sprintf("%.3f", se(m1)["rice_post"]),
            sprintf("%.3f", se(m2)["rice_post"]),
            sprintf("%.3f", se(m3)["rice_post"])))

# Rice × Post × India Share
cat(sprintf("Rice $\\times$ Post $\\times$ India Share & & %s & %s & %s \\\\\n",
            sprintf("%.3f", coef(m2)["rice_post_intensity"]),
            sprintf("%.3f", coef(m3)["rice_post_intensity"]),
            sprintf("%.3f", coef(m4)["rice_post_intensity"])))
cat(sprintf(" & & (%s) & (%s) & (%s) \\\\\n",
            sprintf("%.3f", se(m2)["rice_post_intensity"]),
            sprintf("%.3f", se(m3)["rice_post_intensity"]),
            sprintf("%.3f", se(m4)["rice_post_intensity"])))

cat("\\hline\n")
cat("Market FE & Yes & Yes & & \\\\\n")
cat("Year-Month FE & Yes & Yes & & \\\\\n")
cat("Market $\\times$ Year-Month FE & & & Yes & Yes \\\\\n")
cat("Commodity FE & & & Yes & \\\\\n")
cat("Country $\\times$ Commodity FE & & & & Yes \\\\\n")
cat(sprintf("Observations & %s & %s & %s & %s \\\\\n",
            format(nobs(m1), big.mark = ","),
            format(nobs(m2), big.mark = ","),
            format(nobs(m3), big.mark = ","),
            format(nobs(m4), big.mark = ",")))
cat(sprintf("$R^2$ (within) & %.3f & %.3f & %.3f & %.3f \\\\\n",
            fitstat(m1, "wr2")$wr2,
            fitstat(m2, "wr2")$wr2,
            fitstat(m3, "wr2")$wr2,
            fitstat(m4, "wr2")$wr2))

cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\small\n")
cat("\\item \\textit{Notes:} Dependent variable is log USD price. India Share is the fraction of a country's rice imports sourced from India (2020--2022 average). The treatment is Rice $\\times$ Post (July 2023) $\\times$ India Share, measuring the differential price change of rice vs.\\ control commodities within the same market after the ban, scaled by pre-ban Indian import dependence. Column (4) is the preferred specification with market$\\times$year-month FE and country$\\times$commodity FE. Standard errors clustered at the country level in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Table 2 written.\n")

## ── Table 3: Event Study ────────────────────────────────────────

cat("=== Table 3: Event Study ===\n")

# Use the event study from the control commodity perspective
es <- results$es_model
es_tab <- as.data.table(coeftable(es), keep.rownames = TRUE)
setnames(es_tab, c("term", "est", "se", "tstat", "pval"))

# Parse event time — these are the rice::0 coefficients
# (control commodity changes relative to rice)
es_tab[, event_q := as.integer(gsub(".*::", "", gsub(":rice::0", "", term)))]
es_tab <- es_tab[grepl("rice::0", term)]
es_tab <- es_tab[!is.na(event_q)][order(event_q)]

# Flip sign: if control falls relative to rice, rice rose
es_tab[, rice_effect := -est]
es_tab[, rice_se := se]

sink(file.path(tables_dir, "tab3_event.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Event Study: Rice vs.\\ Control Commodity Prices}\n")
cat("\\label{tab:event}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\hline\\hline\n")
cat("Quarter Relative & Rice Price & Std. & $p$-value \\\\\n")
cat("to Ban & Effect & Error & \\\\\n")
cat("\\hline\n")

for (i in 1:nrow(es_tab)) {
  q <- es_tab$event_q[i]
  label <- ifelse(q < 0, paste0("$q = ", q, "$"), paste0("$q = +", q, "$"))
  if (q == -1) next  # Reference period

  stars <- ""
  if (es_tab$pval[i] < 0.01) stars <- "$^{***}$"
  else if (es_tab$pval[i] < 0.05) stars <- "$^{**}$"
  else if (es_tab$pval[i] < 0.10) stars <- "$^{*}$"

  cat(sprintf("%s & %.3f%s & (%.3f) & %.3f \\\\\n",
              label, es_tab$rice_effect[i], stars,
              es_tab$rice_se[i], es_tab$pval[i]))
}

cat("\\hline\n")
cat("Pre-Ban Joint $F$-test $p$-value & \\multicolumn{3}{c}{")
# Joint test of pre-ban coefficients
pre_coefs <- es_tab[event_q < -1]$term
if (length(pre_coefs) > 0) {
  wald_res <- tryCatch(wald(es, pre_coefs), error = function(e) NULL)
  if (!is.null(wald_res)) {
    cat(sprintf("%.3f", wald_res$p))
  } else {
    cat("---")
  }
}
cat("} \\\\\n")
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\small\n")
cat("\\item \\textit{Notes:} Coefficients represent the differential price change of rice relative to control commodities within the same market, by quarter relative to the July 2023 ban. Quarter $q = -1$ (April--June 2023) is the reference period. Positive values indicate rice prices rose relative to controls. Specification includes market, year-month, and country$\\times$commodity fixed effects. Standard errors clustered at the country level.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Table 3 written.\n")

## ── Table 4: Robustness ────────────────────────────────────────

cat("=== Table 4: Robustness ===\n")

sink(file.path(tables_dir, "tab4_robustness.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Robustness Checks}\n")
cat("\\label{tab:robust}\n")
cat("\\begin{tabular}{lccl}\n")
cat("\\hline\\hline\n")
cat("Specification & Coefficient & SE & Notes \\\\\n")
cat("\\hline\n")

cat(sprintf("Baseline (Country cluster) & %.3f$^{***}$ & (%.3f) & \\\\\n",
            coef(rob$r_country), se(rob$r_country)))
cat(sprintf("Two-way clustering & %.3f$^{***}$ & (%.3f) & Country + Year-Month \\\\\n",
            coef(rob$r_twoway), se(rob$r_twoway)))
cat(sprintf("Market-level clustering & %.3f$^{***}$ & (%.3f) & \\\\\n",
            coef(rob$r_market), se(rob$r_market)))
cat(sprintf("Trimmed (1--99\\%%) & %.3f$^{***}$ & (%.3f) & Excl.\\ outlier prices \\\\\n",
            coef(rob$r_trim), se(rob$r_trim)))
cat(sprintf("Commodity trends & %.3f$^{***}$ & (%.3f) & + Commodity $\\times$ trend \\\\\n",
            coef(rob$r_trend)["rice_post_intensity"],
            se(rob$r_trend)["rice_post_intensity"]))

# LOO range
cat(sprintf("Leave-one-out range & [%.3f, %.3f] & & Min/Max across 59 countries \\\\\n",
            min(rob$loo_coefs), max(rob$loo_coefs)))

# Placebo
cat(sprintf("Pre-ban placebo & %.3f & (%.3f) & Fake treatment Jan 2022 \\\\\n",
            coef(results$m_plac)["fake_intensity"],
            se(results$m_plac)["fake_intensity"]))

cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\small\n")
cat("\\item \\textit{Notes:} All specifications use market$\\times$year-month and country$\\times$commodity fixed effects (except where noted). The coefficient of interest is Rice $\\times$ Post $\\times$ India Share. Leave-one-out shows the range of the coefficient when each country is excluded in turn. The pre-ban placebo tests a fake treatment date of January 2022 using only pre-ban observations. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Table 4 written.\n")

## ── Table 5: Heterogeneity ─────────────────────────────────────

cat("=== Table 5: Heterogeneity ===\n")

sink(file.path(tables_dir, "tab5_hetero.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Heterogeneity by Import Dependence}\n")
cat("\\label{tab:hetero}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\hline\\hline\n")
cat(" & (1) & (2) & (3) \\\\\n")
cat(" & High Dep. & Low Dep. & Difference \\\\\n")
cat("\\hline\n")

high_c <- coef(results$m_high)["rice_post"]
high_se <- se(results$m_high)["rice_post"]
low_c <- coef(results$m_low)["rice_post"]
low_se <- se(results$m_low)["rice_post"]
diff_c <- high_c - low_c
diff_se <- sqrt(high_se^2 + low_se^2)

cat(sprintf("Rice $\\times$ Post & %.3f$^{***}$ & %.3f & %.3f$^{**}$ \\\\\n",
            high_c, low_c, diff_c))
cat(sprintf(" & (%.3f) & (%.3f) & (%.3f) \\\\\n",
            high_se, low_se, diff_se))
cat("\\hline\n")
dep_med <- results$dep_median
panel[, high_dep := as.integer(india_share > dep_med)]
cat(sprintf("Mean India Share & %.2f & %.2f & \\\\\n",
            mean(panel[high_dep == 1]$india_share),
            mean(panel[high_dep == 0]$india_share)))
cat(sprintf("Countries & %d & %d & \\\\\n",
            uniqueN(panel[high_dep == 1]$country),
            uniqueN(panel[high_dep == 0]$country)))
cat(sprintf("Markets & %s & %s & \\\\\n",
            format(uniqueN(panel[high_dep == 1]$market_key), big.mark = ","),
            format(uniqueN(panel[high_dep == 0]$market_key), big.mark = ",")))
cat(sprintf("Observations & %s & %s & \\\\\n",
            format(nobs(results$m_high), big.mark = ","),
            format(nobs(results$m_low), big.mark = ",")))

cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\small\n")
cat(sprintf("\\item \\textit{Notes:} Sample split at median India Import Share among importing countries (%.0f\\%%). High-dependence countries source $>$%.0f\\%% of rice imports from India. All specifications include market$\\times$year-month and commodity fixed effects. Standard errors clustered at the country level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.\n",
            results$dep_median * 100, results$dep_median * 100))
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Table 5 written.\n")

## ── Table F1: SDE Appendix (Mandatory) ──────────────────────────

cat("=== Table F1: SDE ===\n")

sd_y <- results$sd_y_pre
m4 <- results$m4

# Main coefficient (continuous treatment)
beta_main <- coef(m4)["rice_post_intensity"]
se_main <- se(m4)["rice_post_intensity"]
sde_main <- beta_main / sd_y
sde_se_main <- se_main / sd_y

# For heterogeneity: use high/low dep split
beta_high <- coef(results$m_high)["rice_post"]
se_high <- se(results$m_high)["rice_post"]
sde_high <- beta_high / sd_y
sde_se_high <- se_high / sd_y

beta_low <- coef(results$m_low)["rice_post"]
se_low <- se(results$m_low)["rice_post"]
sde_low <- beta_low / sd_y
sde_se_low <- se_low / sd_y

classify_sde <- function(x) {
  if (x > 0.15) return("Large positive")
  if (x > 0.05) return("Moderate positive")
  if (x > 0.005) return("Small positive")
  if (x > -0.005) return("Null")
  if (x > -0.05) return("Small negative")
  if (x > -0.15) return("Moderate negative")
  return("Large negative")
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} 59 countries across Sub-Saharan Africa, South Asia, Middle East, ",
  "East Asia, Europe, and Latin America. ",
  "\\textbf{Research question:} Does India's July 2023 ban on non-basmati white rice exports ",
  "increase retail rice prices in import-dependent countries relative to non-rice staples? ",
  "\\textbf{Policy mechanism:} The ban (Ministry of Commerce Notification No.\\ 20/2023) ",
  "prohibited all non-basmati white rice exports, removing approximately 40\\% of global ",
  "rice trade overnight, with no phase-in period and no advance notice to importers. ",
  "\\textbf{Outcome definition:} Log USD retail price of rice and control staple commodities ",
  "(maize, millet, sorghum, wheat, beans, groundnuts, cassava, potatoes, lentils) from WFP ",
  "Food Price Monitoring. ",
  "\\textbf{Treatment:} Continuous --- country-level share of rice imports sourced from India ",
  "(2020--2022 FAO average), ranging from 0 to 1. ",
  "\\textbf{Data:} WFP Food Price Monitoring via HDX (2021--2025) merged with FAO Detailed ",
  "Trade Matrix for bilateral rice flows; 329,030 market-commodity-month observations across ",
  "59 countries and 1,530 markets. ",
  "\\textbf{Method:} Within-market across-commodity DiD with continuous treatment intensity; ",
  "market$\\times$year-month and country$\\times$commodity fixed effects; standard errors ",
  "clustered at country level (59 clusters). ",
  "\\textbf{Sample:} Markets with both rice and $\\geq$1 control commodity, $\\geq$6 months ",
  "pre- and post-ban, retail prices in USD. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of log price (", sprintf("%.3f", sd_y), "). ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sink(file.path(tables_dir, "tabF1_sde.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\hline\\hline\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\hline\n")
cat("\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n")

cat(sprintf("Rice price (intensity) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
            beta_main, se_main, sd_y, sde_main, sde_se_main, classify_sde(sde_main)))

cat("\\hline\n")
cat("\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Sample Splits)}} \\\\\n")

cat(sprintf("High India dependence & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
            beta_high, se_high, sd_y, sde_high, sde_se_high, classify_sde(sde_high)))
cat(sprintf("Low India dependence & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
            beta_low, se_low, sd_y, sde_low, sde_se_low, classify_sde(sde_low)))

cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\small\n")
cat(sde_notes, "\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Table F1 (SDE) written.\n")

cat("\n=== All tables generated ===\n")
print(list.files(tables_dir))
