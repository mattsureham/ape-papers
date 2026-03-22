## 05_tables.R — Generate all LaTeX tables including SDE appendix
## APEP Working Paper apep_0754

source("00_packages.R")

## ---- 1. Load everything ----
panel_conv <- readRDS("../data/panel_conv.rds")
panel_ddd  <- readRDS("../data/panel_ddd.rds")
panel_full <- readRDS("../data/panel_full.rds")
results    <- readRDS("../data/main_results.rds")
robust     <- readRDS("../data/robustness_results.rds")
diag       <- jsonlite::fromJSON("../data/diagnostics.json")

## ---- Table 1: Summary Statistics ----
cat("Generating Table 1: Summary Statistics\n")

# Pre-treatment summary (before 2020Q1)
pre <- panel_full[yq_num < 21]  # before 2020Q1

summ_by_type <- pre[, .(
  n_states = uniqueN(State),
  mean_active = mean(n_active, na.rm = TRUE),
  mean_exits = mean(n_exits, na.rm = TRUE),
  mean_exit_rate = mean(exit_rate, na.rm = TRUE),
  sd_exit_rate = sd(exit_rate, na.rm = TRUE),
  mean_entries = mean(n_entries, na.rm = TRUE),
  mean_entry_rate = mean(entry_rate, na.rm = TRUE)
), by = store_group]

tab1_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Summary Statistics by Store Type (Pre-Treatment: 2015--2019)}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lrrrrrr}\n",
  "\\toprule\n",
  "Store Type & States & Mean Active & Mean Exits/Q & Exit Rate & SD(Exit Rate) & Entry Rate \\\\\n",
  "\\midrule\n"
)

for (i in 1:nrow(summ_by_type)) {
  row <- summ_by_type[i]
  tab1_tex <- paste0(tab1_tex, sprintf(
    "%s & %d & %.0f & %.1f & %.4f & %.4f & %.4f \\\\\n",
    tools::toTitleCase(gsub("_", " ", row$store_group)),
    row$n_states, row$mean_active, row$mean_exits,
    row$mean_exit_rate, row$sd_exit_rate, row$mean_entry_rate
  ))
}

tab1_tex <- paste0(tab1_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Unit of observation is state $\\times$ store type $\\times$ quarter. ",
  "Exit rate = quarterly deauthorizations / active authorized stores at quarter start. ",
  "Active stores are those authorized by USDA to accept SNAP benefits. ",
  "Data source: USDA SNAP Retailer Historical Database (2005--2025). ",
  "Pre-treatment period covers 2015Q1--2019Q4 (20 quarters).\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, "../tables/tab1_summary.tex")

## ---- Table 2: Main DiD and DDD Results ----
cat("Generating Table 2: Main Results\n")

# Extract CS-DiD overall ATT
cs_att <- results$cs_agg$overall.att
cs_se  <- results$cs_agg$overall.se
cs_p   <- 2 * pnorm(-abs(cs_att / cs_se))

# DDD coefficient (with state×quarter FE, only interaction term remains)
ddd_names <- names(coef(results$ddd_main))
ddd_idx <- grep("treated.*is_conv|is_conv.*treated", ddd_names)[1]
ddd_coef <- coef(results$ddd_main)[ddd_idx]
ddd_se   <- sqrt(diag(vcov(results$ddd_main)))[ddd_idx]
ddd_p    <- 2 * pnorm(-abs(ddd_coef / ddd_se))

# TWFE convenience
twfe_coef <- coef(robust$twfe_conv)["treated"]
twfe_se   <- sqrt(vcov(robust$twfe_conv)["treated", "treated"])
twfe_p    <- 2 * pnorm(-abs(twfe_coef / twfe_se))

# Net change DDD (with state×quarter FE)
net_names <- names(coef(robust$net_ddd))
net_idx <- grep("treated.*is_conv|is_conv.*treated", net_names)[1]
net_coef <- coef(robust$net_ddd)[net_idx]
net_se   <- sqrt(diag(vcov(robust$net_ddd)))[net_idx]
net_p    <- 2 * pnorm(-abs(net_coef / net_se))

stars <- function(p) {
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.1)  return("$^{*}$")
  return("")
}

tab2_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Effect of SNAP Online Purchasing on Convenience Store Exit Rates}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & TWFE & CS-DiD & DDD & Net DDD \\\\\n",
  " & Exit Rate & Exit Rate & Exit Rate & Net Change \\\\\n",
  "\\midrule\n",
  sprintf("Online SNAP $\\times$ Conv. Store & & & %.5f%s & %.5f%s \\\\\n",
          ddd_coef, stars(ddd_p), net_coef, stars(net_p)),
  sprintf(" & & & (%.5f) & (%.5f) \\\\\n", ddd_se, net_se),
  sprintf("Online SNAP (treated) & %.5f%s & %.5f%s & & \\\\\n",
          twfe_coef, stars(twfe_p), cs_att, stars(cs_p)),
  sprintf(" & (%.5f) & (%.5f) & & \\\\\n", twfe_se, cs_se),
  "\\midrule\n",
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          format(nrow(panel_conv), big.mark = ","),
          format(nrow(panel_conv), big.mark = ","),
          format(nrow(panel_ddd), big.mark = ","),
          format(nrow(panel_ddd), big.mark = ",")),
  "State FE & Yes & --- & Yes & Yes \\\\\n",
  "Quarter FE & Yes & --- & Yes & Yes \\\\\n",
  "State $\\times$ Type FE & & & Yes & Yes \\\\\n",
  "Estimator & TWFE & CS-DiD & TWFE & TWFE \\\\\n",
  "Clustering & State & State & State & State \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Dependent variable is quarterly SNAP deauthorization rate (exits / active stores). ",
  "Column (1): two-way fixed effects. ",
  "Column (2): Callaway and Sant'Anna (2021) with never-treated states as control group and doubly-robust estimation. ",
  "Column (3): triple-difference comparing convenience stores vs supermarkets across treated/untreated states and pre/post periods. ",
  "Column (4): net change rate (entries $-$ exits / active stores). ",
  "Standard errors clustered at state level in parentheses. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, "../tables/tab2_main.tex")

## ---- Table 3: Placebo and Robustness ----
cat("Generating Table 3: Placebo and Robustness\n")

# Placebo coefficients
p_super_coef <- coef(robust$placebo_super)["treated"]
p_super_se   <- sqrt(vcov(robust$placebo_super)["treated", "treated"])
p_super_p    <- 2 * pnorm(-abs(p_super_coef / p_super_se))

p_spec_coef <- coef(robust$placebo_spec)["treated"]
p_spec_se   <- sqrt(vcov(robust$placebo_spec)["treated", "treated"])
p_spec_p    <- 2 * pnorm(-abs(p_spec_coef / p_spec_se))

p_other_coef <- coef(robust$placebo_other)["treated"]
p_other_se   <- sqrt(vcov(robust$placebo_other)["treated", "treated"])
p_other_p    <- 2 * pnorm(-abs(p_other_coef / p_other_se))

# No-COVID
nc_coef <- coef(robust$no_covid)["treated"]
nc_se   <- sqrt(vcov(robust$no_covid)["treated", "treated"])
nc_p    <- 2 * pnorm(-abs(nc_coef / nc_se))

# Entry rate
en_coef <- coef(robust$entry_conv)["treated"]
en_se   <- sqrt(vcov(robust$entry_conv)["treated", "treated"])
en_p    <- 2 * pnorm(-abs(en_coef / en_se))

tab3_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Placebo Tests and Robustness Checks}\n",
  "\\label{tab:robust}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & Supermarket & Specialty & Other Grocery & Excl. COVID & Entry Rate \\\\\n",
  " & Placebo & Placebo & Placebo & Peak & Conv. Only \\\\\n",
  "\\midrule\n",
  sprintf("Online SNAP & %.5f%s & %.5f%s & %.5f%s & %.5f%s & %.5f%s \\\\\n",
          p_super_coef, stars(p_super_p),
          p_spec_coef, stars(p_spec_p),
          p_other_coef, stars(p_other_p),
          nc_coef, stars(nc_p),
          en_coef, stars(en_p)),
  sprintf(" & (%.5f) & (%.5f) & (%.5f) & (%.5f) & (%.5f) \\\\\n",
          p_super_se, p_spec_se, p_other_se, nc_se, en_se),
  "\\midrule\n",
  "State FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Quarter FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Clustering & State & State & State & State & State \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Columns (1)--(3): placebo tests using store types that should not be differentially affected by SNAP online purchasing. ",
  "Supermarkets are the comparison group for the DDD; specialty and other grocery stores serve as additional placebos. ",
  "Column (4): excludes 2020Q2--Q3 (acute COVID lockdown period). ",
  "Column (5): entry rate for convenience stores (new authorizations / active stores). ",
  "All specifications include state and quarter fixed effects with state-clustered standard errors. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, "../tables/tab3_robust.tex")

## ---- Table 4: Heterogeneity (Pre-COVID vs COVID-era) ----
cat("Generating Table 4: Heterogeneity\n")

het_pre <- coef(results$het_covid)["pre_covid_treat"]
het_pre_se <- sqrt(vcov(results$het_covid)["pre_covid_treat", "pre_covid_treat"])
het_pre_p <- 2 * pnorm(-abs(het_pre / het_pre_se))

het_covid <- coef(results$het_covid)["covid_treat"]
het_covid_se <- sqrt(vcov(results$het_covid)["covid_treat", "covid_treat"])
het_covid_p <- 2 * pnorm(-abs(het_covid / het_covid_se))

tab4_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Pre-COVID versus COVID-Era Treatment Effects}\n",
  "\\label{tab:het}\n",
  "\\begin{tabular}{lc}\n",
  "\\toprule\n",
  " & Exit Rate \\\\\n",
  "\\midrule\n",
  sprintf("Pre-COVID Online SNAP (NY, April 2019) & %.5f%s \\\\\n", het_pre, stars(het_pre_p)),
  sprintf(" & (%.5f) \\\\\n", het_pre_se),
  sprintf("COVID-Era Online SNAP (2020 wave) & %.5f%s \\\\\n", het_covid, stars(het_covid_p)),
  sprintf(" & (%.5f) \\\\\n", het_covid_se),
  "\\midrule\n",
  sprintf("Observations & %s \\\\\n", format(nrow(panel_conv), big.mark = ",")),
  "State FE & Yes \\\\\n",
  "Quarter FE & Yes \\\\\n",
  "Clustering & State \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Separate treatment indicators for New York (April 2019, pre-COVID) and the 2020 wave ",
  "(46 states, March--December 2020). If online SNAP rather than COVID drives convenience store exits, ",
  "the pre-COVID NY coefficient should be positive and significant. ",
  "Standard errors clustered at state level. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, "../tables/tab4_het.tex")

## ---- SDE Appendix Table ----
cat("Generating SDE Appendix Table\n")

# Compute SDEs
# Main outcomes: exit_rate, net_change_rate, entry_rate
pre_conv <- panel_conv[yq_num < min(panel_conv[first_treat > 0]$first_treat, na.rm = TRUE)]
sd_exit <- sd(pre_conv$exit_rate, na.rm = TRUE)
sd_net  <- sd(pre_conv$net_change_rate, na.rm = TRUE)
sd_entry <- sd(pre_conv$entry_rate, na.rm = TRUE)

# CS-DiD ATT for exit rate
sde_exit <- cs_att / sd_exit
sde_exit_se <- cs_se / sd_exit

# DDD for exit rate
sde_ddd <- ddd_coef / sd_exit
sde_ddd_se <- ddd_se / sd_exit

# Net change rate
sde_net <- net_coef / sd_net
sde_net_se <- net_se / sd_net

# Entry rate
sde_entry <- en_coef / sd_entry
sde_entry_se <- en_se / sd_entry

classify_sde <- function(sde) {
  if (sde > 0.15) return("Large positive")
  if (sde > 0.05) return("Moderate positive")
  if (sde > 0.005) return("Small positive")
  if (sde > -0.005) return("Null")
  if (sde > -0.05) return("Small negative")
  if (sde > -0.15) return("Moderate negative")
  return("Large negative")
}

sde_rows <- data.frame(
  Outcome = c("Exit Rate (CS-DiD)", "Exit Rate (DDD)", "Net Change Rate (DDD)", "Entry Rate"),
  beta = c(cs_att, ddd_coef, net_coef, en_coef),
  se = c(cs_se, ddd_se, net_se, en_se),
  sd_y = c(sd_exit, sd_exit, sd_net, sd_entry),
  sde = c(sde_exit, sde_ddd, sde_net, sde_entry),
  sde_se = c(sde_exit_se, sde_ddd_se, sde_net_se, sde_entry_se),
  stringsAsFactors = FALSE
)
sde_rows$class <- sapply(sde_rows$sde, classify_sde)

# Build LaTeX
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does allowing SNAP benefits to be redeemed online through Amazon and Walmart ",
  "cause brick-and-mortar convenience stores to lose SNAP authorization and exit the program? ",
  "\\textbf{Policy mechanism:} The SNAP Online Purchasing Pilot enables households to use EBT cards ",
  "at online retailers, shifting food assistance spending from physical stores to e-commerce platforms ",
  "that offer lower prices and greater selection, reducing foot traffic and SNAP revenue for small convenience stores. ",
  "\\textbf{Outcome definition:} Quarterly SNAP deauthorization rate (stores losing USDA authorization / active authorized stores). ",
  "\\textbf{Treatment:} Binary; state gains SNAP online purchasing capability (staggered, 47 states, 2019--2021). ",
  "\\textbf{Data:} USDA SNAP Retailer Historical Database, 2015--2024, state $\\times$ store-type $\\times$ quarter, ",
  sprintf("%s observations. ", format(nrow(panel_ddd), big.mark = ",")),
  "\\textbf{Method:} Callaway-Sant'Anna (2021) staggered DiD and triple-difference (convenience vs supermarket $\\times$ treated vs untreated $\\times$ pre vs post), ",
  "standard errors clustered at state level. ",
  "\\textbf{Sample:} SNAP-authorized convenience stores and supermarkets in all 50 states plus DC; ",
  "47 treated jurisdictions, 4 never-treated (AK, HI, LA, MT). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lrrrrrl}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n"
)

for (i in 1:nrow(sde_rows)) {
  r <- sde_rows[i, ]
  sde_tex <- paste0(sde_tex, sprintf(
    "%s & %.5f & %.5f & %.4f & %.3f & %.3f & %s \\\\\n",
    r$Outcome, r$beta, r$se, r$sd_y, r$sde, r$sde_se, r$class
  ))
}

sde_tex <- paste0(sde_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(sde_tex, "../tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
cat("Tables written to tables/\n")
